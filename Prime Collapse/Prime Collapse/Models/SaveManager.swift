//
//  SaveManager.swift
//  Prime Collapse
//
//  Created on 8/29/24.
//
//  Persists the game as a single Codable JSON snapshot on disk. The save is
//  loaded synchronously at construction (before the first frame), so the game
//  can never overwrite a real save with fresh/default state on launch. Writes
//  are serialized and performed off the main thread with atomic file writes.
//

import Foundation
import SwiftUI
import Observation

@Observable class SaveManager {
    // Public state observed by the UI.
    var lastSaveTime: Date = .distantPast
    var isSaving: Bool = false
    var hasCompletedInitialLoad: Bool = false
    var shouldShowSaveIndicator: Bool = false

    // Metadata from the most recently loaded or written snapshot (for the settings screen).
    private(set) var lastSnapshot: GameSnapshot?

    // Dependencies.
    private let gameState: GameState
    private let gameCenterManager: GameCenterManager?

    // Debounce + write serialization.
    private var debounceTask: Task<Void, Never>?
    private var writeTask: Task<Void, Never>?
    private let debounceDelay: Duration = .seconds(2)

    init(gameState: GameState, gameCenterManager: GameCenterManager? = nil) {
        self.gameState = gameState
        self.gameCenterManager = gameCenterManager
        // Load synchronously so state is ready before any view renders.
        loadGameState()
    }

    // MARK: - Loading

    /// Reads the save file (if any) and applies it. Runs synchronously; the file is tiny.
    func loadGameState() {
        if let snapshot = SaveFile.read() {
            snapshot.apply(to: gameState)
            lastSnapshot = snapshot
            print("Loaded save from \(snapshot.savedAt): $\(gameState.money), \(gameState.totalPackagesShipped) packages, \(gameState.workers) workers")
        } else {
            print("No saved game found. Starting new game.")
        }
        hasCompletedInitialLoad = true
        updateGameCenter()
    }

    // MARK: - Saving

    /// Immediate save. No-ops until the initial load has completed and there is progress to save.
    func saveGameState() {
        guard hasCompletedInitialLoad else { return }
        guard gameState.totalPackagesShipped > 0 else { return }
        persist()
    }

    /// Trailing-edge debounce: coalesces bursts of events into a single save a short time later.
    /// Unlike the previous implementation, this never silently drops a save.
    func saveGameStateDebounced() {
        guard hasCompletedInitialLoad else { return }
        guard gameState.totalPackagesShipped > 0 else { return }

        let delay = debounceDelay
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.persist()
        }
    }

    /// Routes gameplay events to the appropriate save cadence.
    func saveOnEvent(_ event: SaveEvent) {
        switch event {
        case .upgrade:
            saveGameStateDebounced()
        case .milestone(let value):
            if value % 100 == 0 { saveGameStateDebounced() }
        case .moneyGain(let amount):
            if amount >= 100 { saveGameStateDebounced() }
        case .backgrounding:
            saveGameState() // Immediate when leaving the app.
        }
    }

    /// Captures a snapshot and enqueues an atomic background write. Call on the main thread.
    private func persist() {
        isSaving = true
        let snapshot = GameSnapshot(from: gameState)
        lastSnapshot = snapshot
        enqueueWrite(snapshot)

        lastSaveTime = Date()
        showSaveIndicator()
        updateGameCenter()
        isSaving = false
    }

    /// Serializes writes so an older write can never land after a newer one.
    private func enqueueWrite(_ snapshot: GameSnapshot) {
        let previous = writeTask
        writeTask = Task.detached(priority: .utility) {
            await previous?.value
            do {
                try SaveFile.write(snapshot)
            } catch {
                print("Save write failed: \(error)")
            }
        }
    }

    // MARK: - Reset / endings

    /// Clears the on-disk save and resets the in-memory game to a fresh state.
    func resetDatabase() {
        gameState.reset()
        lastSnapshot = nil

        let previous = writeTask
        writeTask = Task.detached(priority: .utility) {
            await previous?.value
            SaveFile.delete()
        }

        lastSaveTime = Date()
        showSaveIndicator()
        updateGameCenter()
        print("Save data cleared and game reset.")
    }

    /// Handles win/lose/restart: records final scores where relevant, then starts fresh.
    func handleGameEnding(type: GameEndingType) {
        if type == .win || type == .lose {
            gameCenterManager?.forceRefreshScores(gameState)
        }
        resetDatabase()
    }

    // MARK: - Settings display

    /// Human-readable summary of the current save for the settings screen.
    var saveInfoText: String {
        guard let snapshot = lastSnapshot else { return "No save data found." }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return """
        Save Date: \(formatter.string(from: snapshot.savedAt))
        Schema Version: \(snapshot.schemaVersion)
        App Version: \(snapshot.appVersion)

        Game Stats:
        Money: \(String(format: "%.2f", snapshot.money))
        Packages: \(snapshot.totalPackagesShipped)
        Workers: \(snapshot.workers)
        Ethics Score: \(String(format: "%.1f", snapshot.ethicsScore))
        """
    }

    // MARK: - Helpers

    private func showSaveIndicator() {
        Task { @MainActor in
            withAnimation { shouldShowSaveIndicator = true }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { shouldShowSaveIndicator = false }
        }
    }

    private func updateGameCenter() {
        guard let gcManager = gameCenterManager else { return }
        gcManager.updateFromGameState(gameState)
        if gameState.totalPackagesShipped > 0 || gameState.lifetimeTotalMoneyEarned > 0 {
            gcManager.forceRefreshScores(gameState)
        }
    }

    // Event types that can trigger a save.
    enum SaveEvent {
        case upgrade
        case milestone(Int)
        case moneyGain(Double)
        case backgrounding
    }
}

// Enum to track different game ending types
enum GameEndingType {
    case win
    case lose
    case restart
}

// MARK: - On-disk save file

/// Reads/writes the single JSON save file. Writes are atomic; callers serialize them.
/// The directory is injectable (defaulting to Application Support) so tests can round-trip
/// against a temporary directory without touching the real save.
enum SaveFile {
    static let fileName = "PrimeCollapseSave.json"

    /// Default on-device location for the save file.
    static var defaultDirectory: URL {
        let fileManager = FileManager.default
        return (try? fileManager.url(for: .applicationSupportDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: true))
            ?? fileManager.temporaryDirectory
    }

    static func url(in directory: URL? = nil) -> URL {
        (directory ?? defaultDirectory).appendingPathComponent(fileName)
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func write(_ snapshot: GameSnapshot, in directory: URL? = nil) throws {
        let fileURL = url(in: directory)
        let data = try makeEncoder().encode(snapshot)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    static func read(in directory: URL? = nil) -> GameSnapshot? {
        let fileURL = url(in: directory)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try makeDecoder().decode(GameSnapshot.self, from: data)
        } catch {
            print("Failed to decode save file (ignoring): \(error)")
            return nil
        }
    }

    static func delete(in directory: URL? = nil) {
        try? FileManager.default.removeItem(at: url(in: directory))
    }
}

// SwiftUI extension for easily showing the save indicator
struct SaveIndicatorView: View {
    @Environment(SaveManager.self) var saveManager

    var body: some View {
        if saveManager.shouldShowSaveIndicator {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Game saved")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.6))
            )
            .transition(.opacity.combined(with: .scale))
        }
    }
}
