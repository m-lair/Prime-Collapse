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
        guard let data = try? JSONSerialization.data(withJSONObject: array),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "[]" // Empty array as fallback
        }
        return jsonString
    }
    
    // Helper to deserialize JSON string to array
    static func deserializeArray(_ jsonString: String) -> [String] {
        guard let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return [] // Empty array as fallback
        }
        return array
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
        
        return savedGame
    }
    
    // Apply saved state to a game state
    func apply(to gameState: GameState) {
        gameState.totalPackagesShipped = totalPackagesShipped
        gameState.money = money
        gameState.workers = workers
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
        
        // Restore purchased upgrade IDs
        gameState.purchasedUpgradeIDs = []
        for idString in purchasedUpgradeIDs {
            if let uuid = UUID(uuidString: idString) {
                gameState.purchasedUpgradeIDs.append(uuid)
            }
        }
        
        // Restore repeatable upgrades (based on 'Hire Worker' upgrade)
        gameState.upgrades = []
        
        // Find the "Hire Worker" upgrade using the correct nested path
        let hireWorkerUpgrade = UpgradeManager.EarlyGame.hireWorker
        
        // Count how many workers were hired (to recreate the correct number of worker upgrades)
        let totalWorkerUpgrades = repeatableUpgradeIDs.count
        
        // Recreate each worker upgrade with a unique ID
        for _ in 0..<totalWorkerUpgrades {
            let uniqueUpgrade = Upgrade(
                id: UUID(), // New unique ID
                name: hireWorkerUpgrade.name,
                description: hireWorkerUpgrade.description,
                cost: hireWorkerUpgrade.cost,
                effect: hireWorkerUpgrade.effect,
                isRepeatable: hireWorkerUpgrade.isRepeatable,
                moralImpact: hireWorkerUpgrade.moralImpact
            )
            gameState.upgrades.append(uniqueUpgrade)
        }
        
        // Automation and efficiency - Use new base rates
        gameState.baseWorkerRate = baseWorkerRate
        gameState.baseSystemRate = baseSystemRate
    }
} 
