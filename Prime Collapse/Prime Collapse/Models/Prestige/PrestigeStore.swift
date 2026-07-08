//
//  PrestigeStore.swift
//  Prime Collapse
//
//  Persists PrestigeState to its own JSON file, deliberately separate from the game
//  save (GameSnapshot / SaveFile) so prestige survives game resets and the two never
//  interfere. Directory is injectable for tests.
//

import Foundation

enum PrestigeStore {
    static let fileName = "PrimeCollapsePrestige.json"

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

    /// Load the saved prestige, or an empty state if there is none or it is unreadable.
    static func load(in directory: URL? = nil) -> PrestigeState {
        guard let data = try? Data(contentsOf: url(in: directory)) else {
            return PrestigeState()
        }
        do {
            return try JSONDecoder().decode(PrestigeState.self, from: data)
        } catch {
            print("Failed to decode prestige (\(error)); starting fresh.")
            return PrestigeState()
        }
    }

    /// Persist prestige atomically. Failures are logged, not fatal.
    static func save(_ state: PrestigeState, in directory: URL? = nil) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            let fileURL = url(in: directory)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save prestige: \(error)")
        }
    }
}
