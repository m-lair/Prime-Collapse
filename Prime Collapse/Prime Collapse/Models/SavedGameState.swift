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
    var automationRate: Double
    var moralDecay: Double
    var isCollapsing: Bool
    var lastUpdate: Date
    var packageAccumulator: Double
    var ethicalChoicesMade: Int
    var endingType: String // Store as string since we can't store enums directly
    
    // We store upgrade IDs since we can't directly store the upgrades
    var purchasedUpgradeIDs: [String] // All purchased upgrades
    var repeatableUpgradeIDs: [String] // Only repeatable upgrades
    
    init(
        totalPackagesShipped: Int = 0,
        money: Double = 0.0,
        workers: Int = 0,
        automationRate: Double = 0.0,
        moralDecay: Double = 0.0,
        isCollapsing: Bool = false,
        purchasedUpgradeIDs: [String] = [],
        repeatableUpgradeIDs: [String] = [],
        packageAccumulator: Double = 0.0,
        ethicalChoicesMade: Int = 0,
        endingType: String = "collapse"
    ) {
        self.totalPackagesShipped = totalPackagesShipped
        self.money = money
        self.workers = workers
        self.automationRate = automationRate
        self.moralDecay = moralDecay
        self.isCollapsing = isCollapsing
        self.lastUpdate = Date()
        self.purchasedUpgradeIDs = purchasedUpgradeIDs
        self.repeatableUpgradeIDs = repeatableUpgradeIDs
        self.packageAccumulator = packageAccumulator
        self.ethicalChoicesMade = ethicalChoicesMade
        self.endingType = endingType
    }
    
    // Convert a GameState to a SavedGameState
    static func from(gameState: GameState) -> SavedGameState {
        // Extract purchased upgrade IDs
        let allPurchasedIDs = gameState.purchasedUpgradeIDs.map { $0.uuidString }
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
        
        return SavedGameState(
            totalPackagesShipped: gameState.totalPackagesShipped,
            money: gameState.money,
            workers: gameState.workers,
            automationRate: gameState.automationRate,
            moralDecay: gameState.moralDecay,
            isCollapsing: gameState.isCollapsing,
            purchasedUpgradeIDs: allPurchasedIDs,
            repeatableUpgradeIDs: repeatableIDs,
            packageAccumulator: gameState.packageAccumulator,
            ethicalChoicesMade: gameState.ethicalChoicesMade,
            endingType: endingTypeString
        )
    }
    
    // Apply saved state to a game state
    func apply(to gameState: GameState) {
        gameState.totalPackagesShipped = totalPackagesShipped
        gameState.money = money
        gameState.workers = workers
        gameState.automationRate = automationRate
        gameState.moralDecay = moralDecay
        gameState.isCollapsing = isCollapsing
        gameState.lastUpdate = Date() // Always use current date
        gameState.packageAccumulator = packageAccumulator
        gameState.ethicalChoicesMade = ethicalChoicesMade
        
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
        
        // Restore all purchased upgrade IDs
        gameState.purchasedUpgradeIDs = []
        for idString in purchasedUpgradeIDs {
            if let uuid = UUID(uuidString: idString) {
                gameState.purchasedUpgradeIDs.append(uuid)
            }
        }
        
        // Restore repeatable upgrades
        gameState.upgrades = []
        for idString in repeatableUpgradeIDs {
            if let uuid = UUID(uuidString: idString),
               let upgrade = UpgradeManager.availableUpgrades.first(where: { $0.id == uuid }) {
                gameState.upgrades.append(upgrade)
            }
        }
    }
} 