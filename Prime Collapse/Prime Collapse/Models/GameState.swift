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
    var workers: Int = 0
    
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
        if canAfford(upgrade.cost) {
            money -= upgrade.cost
            upgrade.effect(self)
            
            // Add to purchased upgrades list
            purchasedUpgradeIDs.append(upgrade.id)
            
            // Add to owned upgrades if repeatable
            if upgrade.isRepeatable {
                upgrades.append(upgrade)
            }
            
            // Update moral decay based on the upgrade
            moralDecay += upgrade.moralImpact
            
            // Track ethical choices
            if upgrade.moralImpact < 3.0 {
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
        // 1. Moral decay must be between 70-90 (on the edge)
        // 2. Must have earned at least $2000 
        // 3. Must have shipped at least 1000 packages
        if moralDecay >= 70 && moralDecay <= 90 && money >= 2000 && totalPackagesShipped >= 1000 {
            endingType = .loop
        }
    }
    
    // Reset game state (used for new games or after collapse)
    func reset() {
        totalPackagesShipped = 0
        money = 0.0
        workers = 0
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
