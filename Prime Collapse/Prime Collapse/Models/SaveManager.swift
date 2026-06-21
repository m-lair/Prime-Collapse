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

    // Save-health state, surfaced on the settings screen so failures aren't silent.
    /// Non-nil when the most recent write failed; describes what went wrong.
    private(set) var lastSaveError: String?
    /// Human-readable result of the most recent load (e.g. recovered from backup).
    private(set) var lastLoadMessage: String?

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
    /// Falls back to the rotating backup if the primary file is missing or corrupt.
    func loadGameState() {
        let result = SaveFile.load()
        if let snapshot = result.snapshot {
            snapshot.apply(to: gameState)
            lastSnapshot = snapshot
            print("Loaded save from \(snapshot.savedAt): $\(gameState.money), \(gameState.totalPackagesShipped) packages, \(gameState.workers) workers")
        } else {
            print("No saved game found. Starting new game.")
        }
        lastLoadMessage = result.outcome.message
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
        writeTask = Task.detached(priority: .utility) { [weak self] in
            await previous?.value
            do {
                try SaveFile.write(snapshot)
                await self?.recordSaveResult(error: nil)
            } catch {
                print("Save write failed: \(error)")
                await self?.recordSaveResult(error: error.localizedDescription)
            }
        }
    }

    /// Records the outcome of a background write on the main actor (observable state).
    @MainActor
    private func recordSaveResult(error: String?) {
        lastSaveError = error
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

    /// Human-readable summary of the current save plus live save health, for the settings screen.
    var saveInfoText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var lines: [String] = []

        if let snapshot = lastSnapshot {
            lines.append("Save Date: \(formatter.string(from: snapshot.savedAt))")
            lines.append("Schema Version: \(snapshot.schemaVersion)")
            lines.append("App Version: \(snapshot.appVersion)")
            lines.append("")
            lines.append("Game Stats:")
            lines.append("Money: \(String(format: "%.2f", snapshot.money))")
            lines.append("Packages: \(snapshot.totalPackagesShipped)")
            lines.append("Workers: \(snapshot.workers)")
            lines.append("Ethics Score: \(String(format: "%.1f", snapshot.ethicsScore))")
        } else {
            lines.append("No save data found.")
        }

        // Save health.
        lines.append("")
        if let error = lastSaveError {
            lines.append("⚠️ Last save failed: \(error)")
        } else if lastSaveTime != .distantPast {
            lines.append("Last saved: \(formatter.string(from: lastSaveTime))")
        } else {
            lines.append("No save written this session yet.")
        }
        if let loadMessage = lastLoadMessage {
            lines.append("⚠️ \(loadMessage)")
        }

        return lines.joined(separator: "\n")
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

/// How a load attempt resolved. Used to surface save health to the player.
enum LoadOutcome {
    case empty               // No save on disk; a fresh game.
    case loaded              // Primary save loaded cleanly.
    case recoveredFromBackup // Primary was missing/corrupt; backup restored progress.
    case corruptedNoBackup   // Primary was corrupt and no usable backup existed.

    var message: String? {
        switch self {
        case .empty, .loaded: return nil
        case .recoveredFromBackup: return "Your latest save was unreadable, so progress was restored from a backup."
        case .corruptedNoBackup: return "Your save data was corrupted and could not be recovered. A new game was started."
        }
    }
}

/// Result of a load attempt: the decoded snapshot (if any) and how it was obtained.
struct LoadResult {
    let snapshot: GameSnapshot?
    let outcome: LoadOutcome
}

/// Reads/writes the single JSON save file. Writes are atomic; callers serialize them.
/// The directory is injectable (defaulting to Application Support) so tests can round-trip
/// against a temporary directory without touching the real save.
///
/// Durability: each write first rotates the current good file to a `.bak` copy, so a bad
/// write can never destroy the only copy. Reads that hit a corrupt primary file quarantine
/// it as `.corrupt` and fall back to the backup.
enum SaveFile {
    static let fileName = "PrimeCollapseSave.json"
    static let backupFileName = "PrimeCollapseSave.bak"
    static let corruptFileName = "PrimeCollapseSave.corrupt"

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

    static func backupURL(in directory: URL? = nil) -> URL {
        (directory ?? defaultDirectory).appendingPathComponent(backupFileName)
    }

    static func corruptURL(in directory: URL? = nil) -> URL {
        (directory ?? defaultDirectory).appendingPathComponent(corruptFileName)
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
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)

        // Rotate the current good file to a backup before overwriting, so a failed or
        // truncated write never leaves us with no recoverable copy.
        if fileManager.fileExists(atPath: fileURL.path) {
            let backup = backupURL(in: directory)
            try? fileManager.removeItem(at: backup)
            try? fileManager.copyItem(at: fileURL, to: backup)
        }

        try data.write(to: fileURL, options: .atomic)
    }

    /// Back-compat convenience: just the snapshot, recovering from backup if needed.
    static func read(in directory: URL? = nil) -> GameSnapshot? {
        load(in: directory).snapshot
    }

    /// Loads the save, recovering from the rotating backup if the primary is missing/corrupt.
    static func load(in directory: URL? = nil) -> LoadResult {
        let fileManager = FileManager.default
        let primaryURL = url(in: directory)

        if let snapshot = decode(at: primaryURL) {
            return LoadResult(snapshot: snapshot, outcome: .loaded)
        }

        // Primary failed to decode. If it actually exists, it's corrupt — quarantine it
        // so it can't keep tripping us up (and so it's available for debugging).
        let primaryExisted = fileManager.fileExists(atPath: primaryURL.path)
        if primaryExisted {
            let corrupt = corruptURL(in: directory)
            try? fileManager.removeItem(at: corrupt)
            try? fileManager.moveItem(at: primaryURL, to: corrupt)
            print("Quarantined corrupt save to \(corrupt.lastPathComponent)")
        }

        // Try the backup.
        if let snapshot = decode(at: backupURL(in: directory)) {
            print("Recovered save from backup.")
            return LoadResult(snapshot: snapshot, outcome: .recoveredFromBackup)
        }

        return LoadResult(snapshot: nil, outcome: primaryExisted ? .corruptedNoBackup : .empty)
    }

    private static func decode(at fileURL: URL) -> GameSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try makeDecoder().decode(GameSnapshot.self, from: data)
        } catch {
            print("Failed to decode \(fileURL.lastPathComponent): \(error)")
            return nil
        }
    }

    static func delete(in directory: URL? = nil) {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: url(in: directory))
        try? fileManager.removeItem(at: backupURL(in: directory))
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
