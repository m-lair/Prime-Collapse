//
//  GameState.swift
//  Prime Collapse
//
//  Created on 4/15/25.
//

import Foundation
import SwiftUI
import Observation

@Observable final class GameState {
    // Core game metrics
    var totalPackagesShipped: Int = 0
    var money: Double = 0.0
    var workers: Int = 1  // Start with 1 worker
    
    // Automation and efficiency
    var automationRate: Double = 0.0 // Packages per second
    var packageAccumulator: Double = 0.0 // Tracks partial packages between updates
    
    // Game mechanics
    var upgrades: [Upgrade] = []
    var purchasedUpgradeIDs: [UUID] = [] // Track all purchased upgrades by ID
    var moralDecay: Double = 0.0
    var isCollapsing: Bool = false
    var lastUpdate: Date = Date()
    
    // New game ending properties
    var ethicalChoicesMade: Int = 0
    var endingType: GameEnding = .collapse
    
    // Ship a package manually (tap action)
    func shipPackage() {
        totalPackagesShipped += 1
        earnMoney(1.0) // Base money per package
    }
    
    // Add money to the player's account
    func earnMoney(_ amount: Double) {
        money += amount
    }
    
    // Process automation (called on timer)
    func processAutomation(currentTime: Date) {
        let timeElapsed = currentTime.timeIntervalSince(lastUpdate)
        
        // Calculate fractional packages shipped
        let fractionalPackages = automationRate * timeElapsed
        
        // Add to our accumulator
        packageAccumulator += fractionalPackages
        
        // Process whole packages
        let packagesShipped = Int(packageAccumulator)
        if packagesShipped > 0 {
            totalPackagesShipped += packagesShipped
            earnMoney(Double(packagesShipped))
            // Subtract the shipped packages from the accumulator
            packageAccumulator -= Double(packagesShipped)
        }
        
        lastUpdate = currentTime
    }
    
    // Check if the player can afford an upgrade
    func canAfford(_ cost: Double) -> Bool {
        return money >= cost
    }
    
    // Apply an upgrade
    func applyUpgrade(_ upgrade: Upgrade) {
        // Count how many times this upgrade has been purchased if repeatable
        let timesPurchased = purchasedUpgradeIDs.filter { $0 == upgrade.id }.count
        
        // Calculate actual cost based on purchase count for repeatable upgrades
        let actualCost = upgrade.isRepeatable && timesPurchased > 0 
            ? UpgradeManager.calculatePrice(basePrice: upgrade.cost, timesPurchased: timesPurchased, upgradeName: upgrade.name)
            : upgrade.cost
            
        if canAfford(actualCost) {
            money -= actualCost
            upgrade.effect(self)
            
            // Add to purchased upgrades list
            purchasedUpgradeIDs.append(upgrade.id)
            
            // Add to owned upgrades if repeatable, ensuring each instance has a unique ID
            if upgrade.isRepeatable {
                // Create a new instance with a unique ID for repeatable upgrades
                let uniqueUpgrade = Upgrade(
                    id: UUID(), // Generate a new UUID for this instance
                    name: upgrade.name,
                    description: upgrade.description,
                    cost: upgrade.cost,
                    effect: upgrade.effect,
                    isRepeatable: upgrade.isRepeatable,
                    moralImpact: upgrade.moralImpact
                )
                upgrades.append(uniqueUpgrade)
            }
            
            // Update moral decay based on the upgrade
            // For unethical upgrades (positive moral impact), increase decay more aggressively
            if upgrade.moralImpact > 0 {
                moralDecay += upgrade.moralImpact * 1.5 // 50% more moral decay impact for unethical choices
            } else {
                // For ethical upgrades (negative or zero moral impact), apply normally
                moralDecay += upgrade.moralImpact
            }
            
            // Track ethical choices
            if upgrade.moralImpact < 0 {
                ethicalChoicesMade += 1
                checkForReformEnding()
            }
            
            // Check if we've entered collapse phase
            if moralDecay >= 100 {
                isCollapsing = true
                endingType = .collapse
            }
            
            // Check for loop ending
            checkForLoopEnding()
        }
    }
    
    // Check if an upgrade has been purchased
    func hasBeenPurchased(_ upgrade: Upgrade) -> Bool {
        return purchasedUpgradeIDs.contains(upgrade.id)
    }
    
    // Get the current cost of an upgrade accounting for price increases
    func getCurrentUpgradeCost(_ upgrade: Upgrade) -> Double {
        if !upgrade.isRepeatable {
            return upgrade.cost
        }
        
        // Count how many times this upgrade has been purchased
        let timesPurchased = purchasedUpgradeIDs.filter { $0 == upgrade.id }.count
        return UpgradeManager.calculatePrice(basePrice: upgrade.cost, timesPurchased: timesPurchased, upgradeName: upgrade.name)
    }
    
    // Check if player qualifies for the Reform ending
    private func checkForReformEnding() {
        // To get the Reform ending:
        // 1. Player must have made at least 5 ethical choices 
        // 2. Moral decay must be under 50
        // 3. Must have earned at least $1000
        if ethicalChoicesMade >= 5 && moralDecay < 50 && money >= 1000 {
            endingType = .reform
        }
    }
    
    // Check if player qualifies for the Loop ending
    private func checkForLoopEnding() {
        // To get the Loop ending:
        // 1. Moral decay must be between 75-85 (on the edge)
        // 2. Must have earned at least $2500
        // 3. Must have shipped at least 1500 packages
        if moralDecay >= 75 && moralDecay <= 85 && money >= 2500 && totalPackagesShipped >= 1500 {
            endingType = .loop
        }
    }
    
    // Reset game state (used for new games or after collapse)
    func reset() {
        totalPackagesShipped = 0
        money = 0.0
        workers = 1  // Reset to 1 worker instead of 0
        automationRate = 0.0
        packageAccumulator = 0.0
        upgrades = []
        purchasedUpgradeIDs = []
        moralDecay = 0.0
        isCollapsing = false
        lastUpdate = Date()
        ethicalChoicesMade = 0
        endingType = .collapse
    }
} 
