//
//  SavedGameState.swift
//  Prime Collapse
//
//  Created on 4/15/25.
//

import Foundation
import SwiftData

@Model
final class SavedGameState {
    var totalPackagesShipped: Int
    var money: Double
    var workers: Int
    var ethicsScore: Double
    var isCollapsing: Bool
    var lastUpdate: Date
    var packageAccumulator: Double
    var ethicalChoicesMade: Int
    var endingType: String // Store as string since we can't store enums directly
    
    // Worker-related stats
    var workerEfficiency: Double
    var workerMorale: Double
    var customerSatisfaction: Double
    
    // Package and automation stats
    var packageValue: Double
    var automationEfficiency: Double
    var automationLevel: Int
    
    // Corporate metrics
    var corporateEthics: Double
    
    // New Step 13 Metrics
    var publicPerception: Double // Scale 0-100
    var environmentalImpact: Double // Scale 0-100
    
    // Replace arrays with string storage to prevent materialization issues
    var purchasedUpgradeIDsString: String // Serialized JSON array of UUIDs
    var repeatableUpgradeIDsString: String // Serialized JSON array of UUIDs
    
    // Automation and efficiency - Use new base rates
    @Attribute var baseWorkerRate: Double
    @Attribute var baseSystemRate: Double
    
    // Metadata for save game
    @Attribute var saveVersion: Int = 4
    @Attribute var savedAt: Date = Date()
    @Attribute var appVersionString: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }()
    
    init(
        totalPackagesShipped: Int = 0,
        money: Double = 0.0,
        workers: Int = 0,
        ethicsScore: Double = 100.0,
        isCollapsing: Bool = false,
        purchasedUpgradeIDs: [String] = [],
        repeatableUpgradeIDs: [String] = [],
        packageAccumulator: Double = 0.0,
        ethicalChoicesMade: Int = 0,
        endingType: String = "collapse",
        workerEfficiency: Double = 1.0,
        workerMorale: Double = 0.8,
        customerSatisfaction: Double = 0.9,
        packageValue: Double = 1.0,
        automationEfficiency: Double = 1.0,
        automationLevel: Int = 0,
        corporateEthics: Double = 0.5
    ) {
        self.totalPackagesShipped = totalPackagesShipped
        self.money = money
        self.workers = workers
        self.ethicsScore = ethicsScore
        self.isCollapsing = isCollapsing
        self.lastUpdate = Date()
        
        // Worker & business stats
        self.workerEfficiency = workerEfficiency
        self.workerMorale = workerMorale
        self.customerSatisfaction = customerSatisfaction
        self.packageValue = packageValue
        self.automationEfficiency = automationEfficiency
        self.automationLevel = automationLevel
        self.corporateEthics = corporateEthics
        
        // Initialize new metrics with defaults
        self.publicPerception = 50.0 // Default starting value
        self.environmentalImpact = 0.0 // Default starting value (lower is better?)
        
        // Serialize arrays to JSON strings
        self.purchasedUpgradeIDsString = SavedGameState.serializeArray(purchasedUpgradeIDs)
        self.repeatableUpgradeIDsString = SavedGameState.serializeArray(repeatableUpgradeIDs)
        
        self.packageAccumulator = packageAccumulator
        self.ethicalChoicesMade = ethicalChoicesMade
        self.endingType = endingType
        
        // Initialize base rates (were missed before)
        self.baseWorkerRate = 0.1 // Default starting value
        self.baseSystemRate = 0.0 // Default starting value
    }
    
    // Static helper to serialize array to JSON string
    static func serializeArray(_ array: [String]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: array)
            if let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("Error serializing array: \(error)")
        }
            return "[]" // Empty array as fallback
    }
    
    // Helper to deserialize JSON string to array
    static func deserializeArray(_ jsonString: String) -> [String] {
        do {
            guard !jsonString.isEmpty, jsonString != "[]",
                  let data = jsonString.data(using: .utf8) else {
                return []
            }
            
            if let array = try JSONSerialization.jsonObject(with: data) as? [String] {
                return array
            }
        } catch {
            print("Error deserializing array from string '\(jsonString)': \(error)")
        }
            return [] // Empty array as fallback
    }
    
    // Computed property to access purchasedUpgradeIDs safely
    var purchasedUpgradeIDs: [String] {
        get {
            return Self.deserializeArray(purchasedUpgradeIDsString)
        }
        set {
            purchasedUpgradeIDsString = Self.serializeArray(newValue)
        }
    }
    
    // Computed property to access repeatableUpgradeIDs safely
    var repeatableUpgradeIDs: [String] {
        get {
            return Self.deserializeArray(repeatableUpgradeIDsString)
        }
        set {
            repeatableUpgradeIDsString = Self.serializeArray(newValue)
        }
    }
    
    // Convert a GameState to a SavedGameState
    static func from(gameState: GameState) -> SavedGameState {
        // Extract purchased upgrade IDs
        let allPurchasedIDs = gameState.purchasedUpgradeIDs.map { $0.uuidString }
        
        // Only save the upgrades that are repeatable (currently owned)
        let repeatableIDs = gameState.upgrades.map { $0.id.uuidString }
        
        // Log the details for improved debugging
        print("Capturing \(allPurchasedIDs.count) purchased upgrade IDs for save")
        for (index, id) in allPurchasedIDs.enumerated() {
            // Try to find the name for this ID
            let name = gameState.purchasedUpgradeIDs.count > index ? 
                       UpgradeManager.availableUpgrades.first(where: { 
                           $0.id == gameState.purchasedUpgradeIDs[index] 
                       })?.name ?? "Unknown" : "Unknown"
            print("  - ID \(index): \(id) (\(name))")
        }
        
        // Log repeatable upgrades for debugging
        print("Capturing \(repeatableIDs.count) repeatable upgrade IDs for save (representing workers and other repeatable upgrades)")
        for (index, id) in repeatableIDs.enumerated() {
            // Try to find the name for this ID
            let name = gameState.upgrades.count > index ? gameState.upgrades[index].name : "Unknown"
            print("  - Repeatable \(index): \(id) (\(name))")
        }
        
        // Count worker upgrades specifically to validate
        let workerUpgradeCount = gameState.upgrades.filter { $0.name == "Hire Worker" }.count
        if workerUpgradeCount != gameState.workers {
            print("WARNING: Worker count (\(gameState.workers)) doesn't match worker upgrade count (\(workerUpgradeCount))")
        }
        
        // Convert enum to string
        let endingTypeString: String
        switch gameState.endingType {
        case .collapse:
            endingTypeString = "collapse"
        case .reform:
            endingTypeString = "reform"
        case .loop:
            endingTypeString = "loop"
        }
        
        let savedGame = SavedGameState(
            totalPackagesShipped: gameState.totalPackagesShipped,
            money: gameState.money,
            workers: gameState.workers,
            ethicsScore: gameState.ethicsScore,
            isCollapsing: gameState.isCollapsing,
            purchasedUpgradeIDs: allPurchasedIDs,
            repeatableUpgradeIDs: repeatableIDs,
            packageAccumulator: gameState.packageAccumulator,
            ethicalChoicesMade: gameState.ethicalChoicesMade,
            endingType: endingTypeString,
            workerEfficiency: gameState.workerEfficiency,
            workerMorale: gameState.workerMorale,
            customerSatisfaction: gameState.customerSatisfaction,
            packageValue: gameState.packageValue,
            automationEfficiency: gameState.automationEfficiency,
            automationLevel: gameState.automationLevel,
            corporateEthics: gameState.corporateEthics
        )
        
        // Add new metrics when converting
        savedGame.publicPerception = gameState.publicPerception
        savedGame.environmentalImpact = gameState.environmentalImpact
        
        // Automation and efficiency - Use new base rates
        savedGame.baseWorkerRate = gameState.baseWorkerRate
        savedGame.baseSystemRate = gameState.baseSystemRate
        
        // Set metadata
        savedGame.savedAt = Date()
        savedGame.saveVersion = 4 // Current schema version
        savedGame.appVersionString = {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
            return "\(version) (\(build))"
        }()
        
        // Verify the data consistency 
        if savedGame.repeatableUpgradeIDs.count != repeatableIDs.count {
            print("Warning: Repeatable upgrade ID count mismatch. Expected \(repeatableIDs.count), got \(savedGame.repeatableUpgradeIDs.count)")
        }
        
        if savedGame.purchasedUpgradeIDs.count != allPurchasedIDs.count {
            print("Warning: Purchased upgrade ID count mismatch. Expected \(allPurchasedIDs.count), got \(savedGame.purchasedUpgradeIDs.count)")
        }
        
        // Verify saving of new metrics
        if savedGame.publicPerception != gameState.publicPerception {
            print("Warning: Public perception value mismatch. Expected \(gameState.publicPerception), got \(savedGame.publicPerception)")
        }
        
        if savedGame.environmentalImpact != gameState.environmentalImpact {
            print("Warning: Environmental impact value mismatch. Expected \(gameState.environmentalImpact), got \(savedGame.environmentalImpact)")
        }
        
        return savedGame
    }
    
    // Apply saved state to a game state
    func apply(to gameState: GameState) {
        // Set up safety limits
        let maxWorkers = 150 
        let maxPurchasedIDs = 500
        
        // Basic properties with safety limits
        gameState.totalPackagesShipped = totalPackagesShipped
        gameState.money = money
        gameState.workers = min(workers, maxWorkers) // Cap worker count
        gameState.ethicsScore = ethicsScore
        gameState.isCollapsing = isCollapsing
        gameState.lastUpdate = Date() // Always use current date
        gameState.packageAccumulator = packageAccumulator
        gameState.ethicalChoicesMade = ethicalChoicesMade
        
        // Restore worker and business stats
        gameState.workerEfficiency = workerEfficiency
        gameState.workerMorale = workerMorale
        gameState.customerSatisfaction = customerSatisfaction
        gameState.packageValue = packageValue
        gameState.automationEfficiency = automationEfficiency
        gameState.automationLevel = automationLevel
        gameState.corporateEthics = corporateEthics
        
        // Apply new metrics
        gameState.publicPerception = publicPerception
        gameState.environmentalImpact = environmentalImpact
        
        // Convert string back to enum
        switch endingType {
        case "collapse":
            gameState.endingType = .collapse
        case "reform":
            gameState.endingType = .reform
        case "loop":
            gameState.endingType = .loop
        default:
            gameState.endingType = .collapse
        }
        
        // ENHANCED UPGRADE RESTORATION WITH SAFETY LIMITS
        
        print("Restoring saved game with \(purchasedUpgradeIDs.count) purchased upgrades")
        
        // Clear existing arrays
        gameState.purchasedUpgradeIDs = []
        gameState.upgrades = []
        
        // Create a mapping of upgrade names to UUIDs - critical for persistence
        var upgradeNameToUUID: [String: UUID] = [:]
        for upgrade in UpgradeManager.availableUpgrades {
            upgradeNameToUUID[upgrade.name] = upgrade.id
        }
        
        // Restore purchased upgrade IDs with error handling and deduplication
        // Extract names from saved IDs for verification
        var purchasedNames = Set<String>()
        var uniqueIDsAdded = Set<UUID>() // Track which IDs we've already added
        
        // First, process up to maxPurchasedIDs from the saved data
        let cappedPurchasedIDs = purchasedUpgradeIDs.prefix(maxPurchasedIDs)
        for idString in cappedPurchasedIDs {
            if let uuid = UUID(uuidString: idString), !uniqueIDsAdded.contains(uuid) {
                gameState.purchasedUpgradeIDs.append(uuid)
                uniqueIDsAdded.insert(uuid)
                
                // Try to find the name of this upgrade
                for upgrade in UpgradeManager.availableUpgrades {
                    if upgrade.id.uuidString == idString {
                        purchasedNames.insert(upgrade.name)
                        print("Added known upgrade: \(upgrade.name)")
                        break
                    }
                }
            } else {
                print("Warning: Invalid or duplicate upgrade ID in saved data: \(idString)")
            }
        }
        
        // Restore repeatable upgrades with robust error handling
        do {
            // First, find all available base upgrades from the upgrade manager
            let workerUpgrade = UpgradeManager.EarlyGame.hireWorker
            
            // Get worker count with safety cap
            let safeWorkerCount = min(gameState.workers, maxWorkers)
            
            // Check repeatableUpgradeIDs for worker upgrades, but respect our cap
            let workerUpgradeCount: Int
            if !repeatableUpgradeIDs.isEmpty {
                // If we have data, use it (with safety cap)
                workerUpgradeCount = min(repeatableUpgradeIDs.count, maxWorkers)
                print("Restoring \(workerUpgradeCount) worker upgrades from save data (capped from \(repeatableUpgradeIDs.count))")
            } else {
                // Fallback to using the worker count directly if no repeatable IDs
                workerUpgradeCount = safeWorkerCount
                print("No repeatable upgrade IDs found, using capped worker count (\(workerUpgradeCount)) instead")
            }
            
            // Update game state worker count to match
            gameState.workers = workerUpgradeCount
            
            // Recreate each worker upgrade with a unique ID
            for _ in 0..<workerUpgradeCount {
                let uniqueUpgrade = Upgrade(
                    id: UUID(), // New unique ID
                    name: workerUpgrade.name,
                    description: workerUpgrade.description,
                    cost: workerUpgrade.cost,
                    effect: workerUpgrade.effect,
                    isRepeatable: workerUpgrade.isRepeatable,
                    priceScalingFactor: workerUpgrade.priceScalingFactor,
                    moralImpact: workerUpgrade.moralImpact,
                    publicPerceptionImpact: workerUpgrade.publicPerceptionImpact,
                    environmentalImpactImpact: workerUpgrade.environmentalImpactImpact
                )
                gameState.upgrades.append(uniqueUpgrade)
            }
            
            // CRITICAL FIX: Ensure all purchasedUpgradeIDs contain the current version's IDs
            for upgrade in UpgradeManager.availableUpgrades {
                // For any upgrade that should be considered purchased
                if purchasedNames.contains(upgrade.name) || (!upgrade.isRepeatable && gameState.hasBeenPurchased(upgrade)) {
                    // Ensure it's added to purchasedUpgradeIDs if not already there
                    if !uniqueIDsAdded.contains(upgrade.id) {
                        gameState.purchasedUpgradeIDs.append(upgrade.id)
                        uniqueIDsAdded.insert(upgrade.id)
                        print("CRITICAL FIX: Added current version ID for: \(upgrade.name)")
                    }
                }
            }
            
            print("Game state successfully restored with \(gameState.workers) workers and \(gameState.upgrades.count) active upgrades")
            print("Tracking \(gameState.purchasedUpgradeIDs.count) unique purchased upgrade IDs")
            
        } catch {
            print("Error restoring upgrades: \(error)")
            // Fallback to a sane default if upgrade restoration fails
            gameState.upgrades = []
            gameState.workers = min(1, gameState.workers) // Ensure we don't have more workers than upgrades
        }
        
        // Automation and efficiency - Use new base rates with safe defaults
        gameState.baseWorkerRate = max(0.1, baseWorkerRate) // Ensure minimum value
        gameState.baseSystemRate = max(0, baseSystemRate)   // Ensure minimum value
        
        // Final validation to fix any remaining issues
        gameState.validateGameState()
    }
} 
