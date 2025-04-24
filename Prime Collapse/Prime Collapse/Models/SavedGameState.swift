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
        
        print("Restoring saved game. Saved purchased IDs count: \(self.purchasedUpgradeIDs.count)")
        
        // IMPORTANT: First ensure we start with completely clean arrays
        gameState.purchasedUpgradeIDs.removeAll()
        gameState.upgrades.removeAll() // Assuming this holds active repeatable upgrades like workers
        
        // Restore all purchased upgrade IDs (both repeatable and non-repeatable)
        var restoredPurchasedIDs = Set<UUID>()
        for idString in self.purchasedUpgradeIDs.prefix(maxPurchasedIDs) { // Use the saved IDs
            if let uuid = UUID(uuidString: idString) {
                // Check if this ID corresponds to a known upgrade in the current game version
                if UpgradeManager.availableUpgrades.contains(where: { $0.id == uuid }) {
                     if restoredPurchasedIDs.insert(uuid).inserted {
                         //print("Restored purchased ID: \(uuid)") // Verbose logging
                     } else {
                         //print("Warning: Duplicate purchased ID found in save data: \(uuid)")
                     }
                } else {
                    print("Warning: Saved purchased ID \(uuid) not found in current UpgradeManager. Ignoring.")
                }
            } else {
                print("Warning: Invalid UUID string found in saved purchasedUpgradeIDs: \(idString)")
            }
        }
        gameState.purchasedUpgradeIDs = Array(restoredPurchasedIDs)
        print("Loaded \(gameState.purchasedUpgradeIDs.count) unique purchased upgrade IDs into GameState.")


        // Restore active *repeatable* upgrades (like workers) into the 'upgrades' array
        // This assumes 'gameState.upgrades' holds instances of active repeatable upgrades.
        var restoredRepeatableInstances = [Upgrade]()
        var workerCountFromUpgrades = 0
        let workerUpgradeTemplate = UpgradeManager.EarlyGame.hireWorker // Assuming this is the template

        // We potentially stored specific instances in repeatableUpgradeIDsString, but let's reconstruct based on purchased count for now.
        // Find all purchased "Hire Worker" upgrades
        let purchasedWorkerIDs = gameState.purchasedUpgradeIDs.filter { id in
            UpgradeManager.availableUpgrades.first { $0.id == id }?.name == workerUpgradeTemplate.name
        }

        workerCountFromUpgrades = purchasedWorkerIDs.count
        print("Found \(workerCountFromUpgrades) 'Hire Worker' upgrades among purchased IDs.")

        // Ensure worker count matches the number of worker upgrades found
        // Use the MINIMUM of saved worker count and calculated count to prevent exploits? Or trust saved count? Let's trust saved count for now.
        let finalWorkerCount = min(self.workers, maxWorkers) // Use saved worker count, capped
        gameState.workers = finalWorkerCount
        print("Setting worker count to \(finalWorkerCount) (from saved data, capped).")

        // Recreate worker upgrade instances up to the finalWorkerCount
         if finalWorkerCount > 0 {
            for i in 0..<finalWorkerCount {
                // Find a corresponding purchased ID if available (though it might not matter which specific one)
                // Or just create new instances
                let workerInstance = Upgrade(
                    id: purchasedWorkerIDs.indices.contains(i) ? purchasedWorkerIDs[i] : UUID(), // Reuse ID if possible, else new
                    name: workerUpgradeTemplate.name,
                    description: workerUpgradeTemplate.description,
                    cost: workerUpgradeTemplate.cost, // Cost might need recalculation based on count
                    effect: workerUpgradeTemplate.effect,
                    isRepeatable: workerUpgradeTemplate.isRepeatable,
                    priceScalingFactor: workerUpgradeTemplate.priceScalingFactor,
                    moralImpact: workerUpgradeTemplate.moralImpact,
                    publicPerceptionImpact: workerUpgradeTemplate.publicPerceptionImpact,
                    environmentalImpactImpact: workerUpgradeTemplate.environmentalImpactImpact
                )
                restoredRepeatableInstances.append(workerInstance)
            }
        }

        gameState.upgrades = restoredRepeatableInstances // Assign the restored workers
        print("Restored \(gameState.upgrades.count) active worker upgrades.")

        // Restore other repeatable upgrades like "Performance Bonuses" and "Carbon Offset Program"
        let otherRepeatableUpgradeNames = ["Performance Bonuses", "Carbon Offset Program"]
        
        for upgradeName in otherRepeatableUpgradeNames {
            // Find the template for this upgrade
            if let upgradeTemplate = UpgradeManager.availableUpgrades.first(where: { $0.name == upgradeName && $0.isRepeatable }) {
                // Find how many of these upgrades have been purchased
                let purchasedIDs = gameState.purchasedUpgradeIDs.filter { id in
                    UpgradeManager.availableUpgrades.first { $0.id == id }?.name == upgradeName
                }
                
                let purchasedCount = purchasedIDs.count
                print("Found \(purchasedCount) '\(upgradeName)' upgrades among purchased IDs.")
                
                // Create instances for each purchased upgrade
                for i in 0..<purchasedCount {
                    let upgradeInstance = Upgrade(
                        id: purchasedIDs.indices.contains(i) ? purchasedIDs[i] : UUID(), // Reuse ID if possible, else new
                        name: upgradeTemplate.name,
                        description: upgradeTemplate.description,
                        cost: upgradeTemplate.cost,
                        effect: upgradeTemplate.effect,
                        isRepeatable: upgradeTemplate.isRepeatable,
                        priceScalingFactor: upgradeTemplate.priceScalingFactor,
                        moralImpact: upgradeTemplate.moralImpact,
                        publicPerceptionImpact: upgradeTemplate.publicPerceptionImpact,
                        environmentalImpactImpact: upgradeTemplate.environmentalImpactImpact
                    )
                    gameState.upgrades.append(upgradeInstance)
                }
                
                print("Restored \(purchasedCount) active '\(upgradeName)' upgrades.")
            }
        }

        // Original worker restoration logic is now replaced by the above.

        // Automation and efficiency - Use new base rates with safe defaults
        gameState.baseWorkerRate = max(0.1, baseWorkerRate) // Ensure minimum value
        gameState.baseSystemRate = max(0, baseSystemRate)   // Ensure minimum value
        
        // Final validation to fix any remaining issues
        gameState.validateGameState()
        
        // Additional verification to make sure upgrade integrity is maintained
        gameState.verifyUpgradeIntegrity()
    }
} 
