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
        // Fetch all saved games
        let descriptor = FetchDescriptor<SavedGameState>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        
        do {
            let savedGames = try modelContext.fetch(descriptor)
            
            // If we have a save, apply it
            if let savedGame = savedGames.first {
                do {
                    savedGame.apply(to: gameState)
                    print("Game loaded successfully. Last saved at \(savedGame.savedAt)")
                } catch {
                    print("Error applying saved game: \(error)")
                    
                    // If we can't apply the saved game, reset to a fresh state
                    gameState.reset()
                    
                    // And delete the corrupted save
                    print("Deleting corrupted save data")
                    resetDatabase()
                }
            } else {
                print("No saved game found. Starting new game.")
            }
            
            // Update Game Center regardless
            updateGameCenter()
            
            // Mark as loaded
            hasCompletedInitialLoad = true
        } catch {
            print("Error loading game: \(error)")
            print("Error details: \(error)")
            
            // Reset game state to default since we couldn't load
            gameState.reset()
            
            hasCompletedInitialLoad = true // Still mark as loaded to avoid blocking
        }
    }
    
    // Saves the current game state if it has progressed
    func saveGameState() {
        // Only save if we've made some progress
        guard gameState.totalPackagesShipped > 0 else { return }
        
        // Indicate saving has started
        isSaving = true
        
        do {
            // Fetch existing saves
            let descriptor = FetchDescriptor<SavedGameState>()
            let savedGames = try modelContext.fetch(descriptor)
            
            // Delete any existing saved games
            for game in savedGames {
                modelContext.delete(game)
            }
            
            // Create a new saved game state
            let savedState = SavedGameState.from(gameState: gameState)
            modelContext.insert(savedState)
            
            // Commit the changes
            try modelContext.save()
            
            // Update last save time and show indicator
            lastSaveTime = Date()
            showSaveIndicator()
            
            // Update Game Center with the latest stats
            updateGameCenter()
            
            print("Game saved successfully at \(savedState.savedAt)")
        } catch {
            print("Error saving game: \(error)")
        }
        
        // Mark saving as complete
        isSaving = false
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
                    await MainActor.run {
                        saveGameState()
                    }
                }
            } catch {
                // Task was cancelled or other error
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
        withAnimation {
            shouldShowSaveIndicator = true
        }
        
        // Hide indicator after delay
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                withAnimation {
                    shouldShowSaveIndicator = false
                }
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
    
    // Reset the database completely - use in emergency recovery scenarios
    func resetDatabase() {
        do {
            // Delete all saved games
            let descriptor = FetchDescriptor<SavedGameState>()
            let savedGames = try modelContext.fetch(descriptor)
            
            if savedGames.isEmpty {
                print("No saved games to delete")
            } else {
                // Count before deletion
                print("Deleting \(savedGames.count) saved games")
                
                // Delete each saved game
                for game in savedGames {
                    modelContext.delete(game)
                }
                
                // Save changes
                try modelContext.save()
                
                print("Successfully reset the database")
            }
            
            // Reset the game state to defaults
            gameState.reset()
            
        } catch {
            print("Error resetting database: \(error)")
            print("Error details: \(error)")
            
            // Force reset game state even if database reset fails
            gameState.reset()
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