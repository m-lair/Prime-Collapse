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
    
    // Worker related stats
    var workerEfficiency: Double = 1.0 // Multiplier for worker output
    var workerMorale: Double = 0.8 // 0.0 to 1.0 scale
    var customerSatisfaction: Double = 0.9 // 0.0 to 1.0 scale
    
    // Package value & automation efficiency
    var packageValue: Double = 1.0 // Base value per package
    var automationEfficiency: Double = 1.0 // Multiplier for automation output
    var automationLevel: Int = 0 // Current automation tech level
    
    // Corporate metrics
    var corporateEthics: Double = 0.5 // 0.0 (unethical) to 1.0 (ethical)
    
    // Game mechanics
    var upgrades: [Upgrade] = []
    var purchasedUpgradeIDs: [UUID] = [] // Track all purchased upgrades by ID
    var ethicsScore: Double = 100.0 // Renamed from moralDecay, starts at 100 (good)
    var isCollapsing: Bool = false
    var lastUpdate: Date = Date()
    
    // New game ending properties
    var ethicalChoicesMade: Int = 0
    var endingType: GameEnding = .collapse
    
    // New Step 13 Metrics
    var publicPerception: Double = 50.0 // Scale 0-100, default starting value
    var environmentalImpact: Double = 0.0 // Scale 0-100, default starting value (lower is better?)
    
    // Ship a package manually (tap action)
    func shipPackage() {
        totalPackagesShipped += 1
        
        // Calculate the actual value based on package value and customer satisfaction
        let actualValue = packageValue * (0.5 + (customerSatisfaction * 0.5))
        earnMoney(actualValue)
    }
    
    // Add money to the player's account
    func earnMoney(_ amount: Double) {
        money += amount
    }
    
    // Process automation (called on timer)
    func processAutomation(currentTime: Date) {
        let timeElapsed = currentTime.timeIntervalSince(lastUpdate)
        
        // Skip if no time has passed
        guard timeElapsed > 0 else {
            lastUpdate = currentTime
            return
        }
        
        // Calculate effective automation rate based on worker efficiency and automation efficiency
        // Factor in worker morale: Morale below 0.5 starts reducing efficiency linearly down to 0 at 0 morale.
        // Morale above 0.7 could provide a small boost (e.g., up to 10% at 1.0 morale).
        let moraleFactor: Double
        if workerMorale < 0.5 {
            moraleFactor = workerMorale * 2.0 // Scales from 0.0 at 0 morale to 1.0 at 0.5 morale
        } else if workerMorale > 0.7 {
            moraleFactor = 1.0 + (workerMorale - 0.7) / 3.0 // Scales from 1.0 at 0.7 morale to 1.1 at 1.0 morale
        } else {
            moraleFactor = 1.0 // Neutral effect between 0.5 and 0.7
        }
        let effectiveAutomationRate = automationRate * workerEfficiency * automationEfficiency * moraleFactor
        
        // Calculate fractional packages shipped
        let fractionalPackages = effectiveAutomationRate * timeElapsed
        
        // Add to our accumulator
        packageAccumulator += fractionalPackages
        
        // Process whole packages
        let packagesShipped = Int(packageAccumulator)
        if packagesShipped > 0 {
            totalPackagesShipped += packagesShipped
            
            // Calculate package value factoring in customer satisfaction
            let valuePerPackage = packageValue * (0.5 + (customerSatisfaction * 0.5))
            earnMoney(Double(packagesShipped) * valuePerPackage)
            
            // Subtract the shipped packages from the accumulator
            packageAccumulator -= Double(packagesShipped)
        }
        
        // Slowly decay morale if very low ethics
        if corporateEthics < 0.3 && workerMorale > 0.2 {
            workerMorale -= timeElapsed * 0.01 * (0.3 - corporateEthics)
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
            
            // Apply new metric impacts
            publicPerception = max(0, min(100, publicPerception + upgrade.publicPerceptionImpact)) // Clamp between 0-100
            environmentalImpact = max(0, min(100, environmentalImpact + upgrade.environmentalImpactImpact)) // Clamp between 0-100
            
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
            
            // Update ethics score based on the upgrade
            // Note: moralImpact values themselves need inversion where defined.
            // Positive impact increases score (ethical), negative decreases it (unethical).
            ethicsScore += upgrade.moralImpact
            ethicsScore = max(0, min(100, ethicsScore)) // Clamp score between 0 and 100

            // Track ethical choices (now based on positive moralImpact)
            if upgrade.moralImpact > 0 {
                ethicalChoicesMade += 1
                checkForReformEnding()
            }
            
            // Check if we've entered collapse phase (score reached 0 or less)
            if ethicsScore <= 0 {
                isCollapsing = true
                endingType = .collapse
            }
            
            // Check for loop ending
            checkForLoopEnding()
            
            // Update automation level for event triggers when appropriate
            if upgrade.name.contains("Automate") || upgrade.name.contains("AI") {
                automationLevel += 1
            }
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
        
        // Calculate base cost accounting for repeatability
        let timesPurchased = purchasedUpgradeIDs.filter { $0 == upgrade.id }.count
        let baseCost = UpgradeManager.calculatePrice(basePrice: upgrade.cost, timesPurchased: timesPurchased, upgradeName: upgrade.name)
        
        // Apply modifier based on public perception (0-100 scale)
        let perceptionModifier: Double
        if publicPerception < 30 {
            // Increase cost significantly for low perception (up to +50% cost at 0 perception)
            perceptionModifier = 1.0 + (30.0 - publicPerception) / 30.0 * 0.5 
        } else if publicPerception > 70 {
            // Decrease cost slightly for high perception (down to -10% cost at 100 perception)
            perceptionModifier = 1.0 - (publicPerception - 70.0) / 30.0 * 0.1
        } else {
            // No modifier for neutral perception (30-70)
            perceptionModifier = 1.0
        }
        
        return baseCost * perceptionModifier
    }
    
    // Check if player qualifies for the Reform ending
    private func checkForReformEnding() {
        // To get the Reform ending:
        // 1. Player must have made at least 5 ethical choices (positive impact)
        // 2. Ethics score must be 50 or higher
        // 3. Must have earned at least $1000
        if ethicalChoicesMade >= 5 && ethicsScore >= 50 && money >= 1000 {
            endingType = .reform
        }
    }
    
    // Check if player qualifies for the Loop ending
    private func checkForLoopEnding() {
        // To get the Loop ending:
        // 1. Ethics score must be low but not collapsed (e.g., 15-25)
        // 2. Must have earned at least $2500
        // 3. Must have shipped at least 1500 packages
        if ethicsScore >= 15 && ethicsScore <= 25 && money >= 2500 && totalPackagesShipped >= 1500 {
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
        ethicsScore = 100.0 // Reset ethics score to 100
        isCollapsing = false
        lastUpdate = Date()
        ethicalChoicesMade = 0
        endingType = .collapse
        
        // Reset worker and business stats
        workerEfficiency = 1.0
        workerMorale = 0.8
        customerSatisfaction = 0.9
        packageValue = 1.0
        automationEfficiency = 1.0
        automationLevel = 0
        corporateEthics = 0.5
        
        // Reset new metrics
        publicPerception = 50.0
        environmentalImpact = 0.0
    }
} 
