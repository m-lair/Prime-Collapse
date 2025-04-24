//
//  SaveManager.swift
//  Prime Collapse
//
//  Created on 8/29/24.
//

import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable class SaveManager {
    // Public properties
    var lastSaveTime: Date = Date.distantPast
    var isSaving: Bool = false
    var hasCompletedInitialLoad: Bool = false
    var shouldShowSaveIndicator: Bool = false
    
    // Configuration
    let saveThrottleInterval: TimeInterval = 30 // At most one save per 30 seconds
    
    // References to dependencies
    private let modelContext: ModelContext
    private let gameState: GameState
    private let gameCenterManager: GameCenterManager?
    
    // Private properties
    private var saveTask: Task<Void, Error>?
    
    init(modelContext: ModelContext, gameState: GameState, gameCenterManager: GameCenterManager? = nil) {
        self.modelContext = modelContext
        self.gameState = gameState
        self.gameCenterManager = gameCenterManager
    }
    
    // Loads the game from the saved state
    func loadGameState() {
        Task {
            // Perform database operations on a background thread
            await performBackgroundLoad()
        }
    }
    
    // Background loading function
    private func performBackgroundLoad() async {
        // Fetch all saved games
        let descriptor = FetchDescriptor<SavedGameState>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        
        do {
            // Perform database fetch on background thread
            let savedGames = try await Task.detached(priority: .userInitiated) {
                return try self.modelContext.fetch(descriptor)
            }.value
            
            // If we have a save, apply it
            if let savedGame = savedGames.first {
                do {
                    print("Found save game from \(savedGame.savedAt)")
                    print("Save contains \(savedGame.purchasedUpgradeIDs.count) purchased upgrades")
                    print("Save contains \(savedGame.repeatableUpgradeIDs.count) repeatable upgrades")
                    
                    // Back on main thread to update game state
                    await MainActor.run {
                        savedGame.apply(to: gameState)
                        print("Game loaded successfully. Last saved at \(savedGame.savedAt)")
                        
                        // Call upgrade verification after applying saved state
                        gameState.verifyUpgradeIntegrity()
                        
                        // Verify upgrade restoration
                        print("Game state now has \(gameState.upgrades.count) upgrades and \(gameState.purchasedUpgradeIDs.count) purchased upgrade IDs")
                        
                        // Verify key stats were restored
                        print("Loaded: $\(gameState.money), \(gameState.totalPackagesShipped) packages shipped, ethics: \(gameState.ethicsScore)")
                    }
                } catch {
                    print("Error applying saved game: \(error)")
                    
                    // If we can't apply the saved game, reset to a fresh state
                    await MainActor.run {
                        gameState.reset()
                    }
                    
                    // And delete the corrupted save
                    print("Deleting corrupted save data")
                    await resetDatabaseAsync()
                }
            } else {
                print("No saved game found. Starting new game.")
            }
            
            // Update Game Center regardless
            await MainActor.run {
                updateGameCenter()
                // Mark as loaded
                hasCompletedInitialLoad = true
            }
        } catch {
            print("Error loading game: \(error)")
            print("Error details: \(error)")
            
            // Reset game state to default since we couldn't load
            await MainActor.run {
                gameState.reset()
                hasCompletedInitialLoad = true // Still mark as loaded to avoid blocking
            }
        }
    }
    
    // Saves the current game state if it has progressed
    func saveGameState() {
        // Only save if we've made some progress
        guard gameState.totalPackagesShipped > 0 else { return }
        
        // Indicate saving has started
        isSaving = true
        
        // Launch a task to perform the save on a background thread
        Task {
            await performBackgroundSave()
        }
    }
    
    // Background saving function
    private func performBackgroundSave() async {
        do {
            // Validate game state before saving (fixing any issues)
            await MainActor.run {
                gameState.validateGameState()
                // Verify purchased upgrade tracking before saving
                validatePurchasedUpgrades()
                // Enhanced pre-save validation
                ensureNonRepeatablePurchasesTracked()
            }
            
            // Fetch existing saves on background thread
            let savedGames = try await Task.detached(priority: .userInitiated) {
                let descriptor = FetchDescriptor<SavedGameState>()
                return try self.modelContext.fetch(descriptor)
            }.value
            
            // Delete existing saved games on background thread
            try await Task.detached(priority: .userInitiated) {
                // Delete any existing saved games
                for game in savedGames {
                    self.modelContext.delete(game)
                }
            }.value
            
            // Create a new saved game state (capture game state on main thread)
            let gameStateCopy = await MainActor.run {
                return gameState
            }
            
            // Create the saved state
            let savedState = SavedGameState.from(gameState: gameStateCopy)
            
            // Enhanced logging for debugging
            print("Saving game with \(gameStateCopy.purchasedUpgradeIDs.count) purchased upgrade IDs")
            print("Current active upgrades: \(gameStateCopy.upgrades.count)")
            
            // Double check that repeatable upgrades are properly counted
            // This should match the number of worker upgrades
            let repeatableCount = gameStateCopy.upgrades.count
            print("Saving \(repeatableCount) repeatable upgrades")
            
            // Verify the purchased IDs were properly copied
            if savedState.purchasedUpgradeIDs.count != gameStateCopy.purchasedUpgradeIDs.count {
                print("Warning: Purchased upgrade count mismatch between game state (\(gameStateCopy.purchasedUpgradeIDs.count)) and saved state (\(savedState.purchasedUpgradeIDs.count))")
            }
            
            // Insert the saved state on background thread
            try await Task.detached(priority: .userInitiated) {
                self.modelContext.insert(savedState)
                // Commit the changes
                try self.modelContext.save()
            }.value
            
            // Update UI state on main thread after successful save
            await MainActor.run {
                // Update last save time and show indicator
                lastSaveTime = Date()
                showSaveIndicator()
                
                // Update Game Center with the latest stats
                updateGameCenter()
                
                // Mark saving as complete
                isSaving = false
            }
            
            print("Game saved successfully at \(savedState.savedAt)")
        } catch {
            print("Error saving game: \(error)")
            print("Error details: \(error)")
            
            // Mark saving as complete on main thread
            await MainActor.run {
                isSaving = false
            }
        }
    }
    
    // Debounced save to avoid excessive saves
    func saveGameStateDebounced() {
        // Cancel any existing save task
        saveTask?.cancel()
        
        // Check if enough time has passed since the last save
        let now = Date()
        let timeSinceLastSave = now.timeIntervalSince(lastSaveTime)
        
        // Don't schedule a new save if it's too soon
        guard timeSinceLastSave >= saveThrottleInterval else { return }
        
        // Schedule a new save after a short delay
        saveTask = Task {
            do {
                try await Task.sleep(for: .seconds(2))
                
                // Only proceed if task wasn't cancelled during sleep
                if !Task.isCancelled {
                    // Call the async save method
                    await performBackgroundSave()
                }
            } catch {
                // Task was cancelled or other error
                print("Save task cancelled or error: \(error)")
            }
        }
    }
    
    // Use for event-based saves (milestone achievements, purchases, etc.)
    func saveOnEvent(_ event: SaveEvent) {
        switch event {
        case .upgrade:
            saveGameStateDebounced()
        case .milestone(let value):
            if value % 100 == 0 {
                saveGameStateDebounced()
            }
        case .moneyGain(let amount):
            if amount >= 100 {
                saveGameStateDebounced()
            }
        case .backgrounding:
            // Immediate save when app goes to background
            saveGameState()
        }
    }
    
    // Shows the save indicator briefly
    private func showSaveIndicator() {
        Task { @MainActor in
            // Ensure UI updates happen on the main thread
            withAnimation {
                shouldShowSaveIndicator = true
            }
            
            // Hide indicator after delay
            do {
                try await Task.sleep(for: .seconds(1.5))
                // Still on main thread due to @MainActor
                withAnimation {
                    shouldShowSaveIndicator = false
                }
            } catch {
                // Handle potential cancellation
                print("Save indicator animation interrupted: \(error)")
            }
        }
    }
    
    // Updates Game Center with latest stats
    private func updateGameCenter() {
        // Only update Game Center if the manager is available
        if let gcManager = gameCenterManager {
            // First update from game state (throttled)
            gcManager.updateFromGameState(gameState)
            
            // For key events like saving, force refresh scores to ensure UI shows latest
            if gameState.totalPackagesShipped > 0 || gameState.lifetimeTotalMoneyEarned > 0 {
                gcManager.forceRefreshScores(gameState)
            }
        }
    }
    
    // Reset the database asynchronously
    private func resetDatabaseAsync() async {
        do {
            // Explicitly reset the game state first
            await MainActor.run {
                print("Resetting game state before clearing database...")
                gameState.reset()
            }
            
            // Delete all saved games on background thread
            try await Task.detached(priority: .userInitiated) {
                let descriptor = FetchDescriptor<SavedGameState>()
                let savedGames = try self.modelContext.fetch(descriptor)
                
                if savedGames.isEmpty {
                    print("No saved games to delete")
                } else {
                    // Count before deletion
                    print("Deleting \(savedGames.count) saved games")
                    
                    // Delete each saved game
                    for game in savedGames {
                        self.modelContext.delete(game)
                    }
                    
                    // Save changes
                    try self.modelContext.save()
                    
                    print("Successfully reset the database")
                }
            }.value
            
            // Force update the UI state on main thread
            await MainActor.run {
                // Update flags and show indicator
                lastSaveTime = Date()
                showSaveIndicator()
                
                // Update Game Center with the reset stats
                updateGameCenter()
                
                print("Game has been fully reset")
            }
            
        } catch {
            print("Error resetting database: \(error)")
            print("Error details: \(error)")
            
            // Force reset game state even if database reset fails
            await MainActor.run {
                gameState.reset()
            }
        }
    }
    
    // Keep this version for backwards compatibility and UI button actions
    func resetDatabase() {
        Task {
            await resetDatabaseAsync()
        }
    }
    
    // New validation method to ensure all purchased upgrades are correctly tracked
    private func validatePurchasedUpgrades() {
        // Get all non-repeatable upgrades
        let allNonRepeatableUpgrades = UpgradeManager.availableUpgrades.filter { !$0.isRepeatable }
        
        // Track which upgrades might need fixing
        var upgradesNeedingFix = 0
        
        // Check each upgrade to see if it's visually hidden but not in purchasedUpgradeIDs
        for upgrade in allNonRepeatableUpgrades {
            // For each non-repeatable upgrade, check if it SHOULD be considered purchased
            let visiblyPurchased = gameState.hasBeenPurchased(upgrade)
            let idInList = gameState.purchasedUpgradeIDs.contains(upgrade.id)
            
            // If there's a mismatch, we need to fix it
            if visiblyPurchased && !idInList {
                // The upgrade appears purchased but its ID isn't in the list
                gameState.purchasedUpgradeIDs.append(upgrade.id)
                upgradesNeedingFix += 1
                print("Fixed missing upgrade ID: \(upgrade.name)")
            }
        }
        
        if upgradesNeedingFix > 0 {
            print("Fixed \(upgradesNeedingFix) missing upgrade IDs before saving")
        }
    }
    
    // Added method to ensure all non-repeatable upgrades are tracked
    private func ensureNonRepeatablePurchasesTracked() {
        // This ensures all non-repeatable upgrades are properly tracked
        // by their current IDs in the UpgradeManager
        
        // 1. Get all non-repeatable upgrade names
        let upgradeManagerNames = UpgradeManager.availableUpgrades
            .filter { !$0.isRepeatable }
            .map { $0.name }
        
        // 2. Get currently tracked purchased upgrade names 
        let currentlyTrackedNames = gameState.purchasedUpgradeIDs.compactMap { id -> String? in
            for upgrade in UpgradeManager.availableUpgrades {
                if upgrade.id == id {
                    return upgrade.name
                }
            }
            return nil
        }
        
        // 3. For each upgrade in UpgradeManager, check if we should have purchased it
        for upgradeName in Set(currentlyTrackedNames) {
            // Find the current version's UUID in UpgradeManager
            if let currentID = UpgradeManager.availableUpgrades
                .first(where: { $0.name == upgradeName && !$0.isRepeatable })?.id {
                
                // If we don't have this ID in our purchased list, add it
                if !gameState.purchasedUpgradeIDs.contains(currentID) {
                    gameState.purchasedUpgradeIDs.append(currentID)
                    print("CRITICAL: Added missing current ID for purchased upgrade: \(upgradeName)")
                }
            }
        }
    }
    
    // New method for handling game endings (win, lose, restart)
    func handleGameEnding(type: GameEndingType) {
        Task {
            print("Handling game ending of type: \(type)")
            
            // If it's a restart, clear everything
            if type == .restart {
                await resetDatabaseAsync()
            } else {
                // For win/lose scenarios, reset the game state but optionally save high scores first
                
                // Optionally record high scores or achievements before resetting
                if type == .win || type == .lose {
                    // Update Game Center with final stats
                    await MainActor.run {
                        gameCenterManager?.forceRefreshScores(gameState)
                    }
                }
                
                // Reset the game
                await MainActor.run {
                    gameState.reset()
                }
                
                // Save the reset state to database
                await performBackgroundSave()
                
                print("Game ended (\(type)) and state has been reset")
            }
        }
    }
    
    // Event types that can trigger a save
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