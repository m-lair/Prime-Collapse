//
//  GameState.swift
//  Prime Collapse
//
//  Created on 4/15/25.
//

import Foundation
import SwiftUI
import Observation

// Define the structure for delayed effects
struct DelayedEffect: Identifiable, Equatable {
    let id = UUID()
    let triggerTime: Date
    let applyEffect: (GameState) -> Void

    // Equatable conformance needed for removal from array
    static func == (lhs: DelayedEffect, rhs: DelayedEffect) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable final class GameState {
    // Core game metrics
    var totalPackagesShipped: Int = 0
    // Clamp money >= 0
    private var _money: Double = 0.0
    var money: Double {
        get { _money }
        set { _money = max(0, newValue) }
    }
    var workers: Int = 0  // Start with 1 worker
    var lifetimeTotalMoneyEarned: Double = 0.0 // Track total money earned throughout the game
    
    // Automation and efficiency
    var baseWorkerRate: Double = 0.0 // Pkgs/sec per worker base
    var baseSystemRate: Double = 0.0 // Pkgs/sec from non-worker automation
    var packageAccumulator: Double = 0.0 // Tracks partial packages between updates
    
    // Worker related stats (Clamp efficiency >= 0, others 0-1)
    private var _workerEfficiency: Double = 1.0
    var workerEfficiency: Double {
        get { _workerEfficiency }
        set { _workerEfficiency = max(0, newValue) }
    }
    private var _workerMorale: Double = 0.8
    var workerMorale: Double {
        get { _workerMorale }
        set { _workerMorale = max(0, min(1, newValue)) }
    }
    private var _customerSatisfaction: Double = 0.9
    var customerSatisfaction: Double {
        get { _customerSatisfaction }
        set { _customerSatisfaction = max(0, min(1, newValue)) }
    }
    
    // Package value & automation efficiency (Clamp efficiency >= 0)
    var packageValue: Double = 1.0 // Base value per package
    private var _automationEfficiency: Double = 1.0
    var automationEfficiency: Double {
        get { _automationEfficiency }
        set { _automationEfficiency = max(0, newValue) }
    }
    var automationLevel: Int = 0 // Current automation tech level
    
    // Corporate metrics (Clamp 0-1 and 0-100)
    private var _corporateEthics: Double = 0.5
    var corporateEthics: Double {
        get { _corporateEthics }
        set { _corporateEthics = max(0, min(1, newValue)) }
    }
    private var _ethicsScore: Double = 100.0
    var ethicsScore: Double {
        get { _ethicsScore }
        set { _ethicsScore = max(0, min(100, newValue)) }
    }
    
    // Game mechanics
    var upgrades: [Upgrade] = []
    var purchasedUpgradeIDs: [UUID] = [] // Track all purchased upgrades by ID
    var isCollapsing: Bool = false
    var lastUpdate: Date = Date()
    
    // New game ending properties
    var ethicalChoicesMade: Int = 0
    var endingType: GameEnding = .collapse
    
    // Track loop ending state
    var isInLoopEndingState: Bool = false
    var loopEndingStartTime: Date? = nil
    
    // New Step 13 Metrics (Clamp 0-100)
    private var _publicPerception: Double = 50.0
    var publicPerception: Double {
        get { _publicPerception }
        set { _publicPerception = max(0, min(100, newValue)) }
    }
    private var _environmentalImpact: Double = 0.0
    var environmentalImpact: Double {
        get { _environmentalImpact }
        set { _environmentalImpact = max(0, min(100, newValue)) }
    }
    
    // Worker quitting notification
    var workersQuit: Int = 0
    var hasWorkersQuit: Bool = false
    
    // List to hold pending delayed effects
    var pendingEffects: [DelayedEffect] = []
    
    // Ship a package manually (tap action)
    func shipPackage() {
        totalPackagesShipped += 1
        
        // Calculate the actual value based on package value, customer satisfaction, and public perception
        let perceptionFactor = 0.8 + (publicPerception / 100.0 * 0.4) // Scales 80% to 120%
        let satisfactionFactor = 0.5 + (customerSatisfaction * 0.5) // Scales 50% to 100%
        let actualValue = packageValue * perceptionFactor * satisfactionFactor
        // let actualValue = packageValue * (0.5 + (customerSatisfaction * 0.5)) // OLD CALC
        earnMoney(actualValue)
    }
    
    // Add money to the player's account
    func earnMoney(_ amount: Double) {
        money += amount
        if amount > 0 {
            lifetimeTotalMoneyEarned += amount
        }
    }
    
    // Process automation (called on timer)
    func processAutomation(currentTime: Date) {
        let timeElapsed = currentTime.timeIntervalSince(lastUpdate)
        
        // Skip if no time has passed
        guard timeElapsed > 0 else {
            lastUpdate = currentTime
            return
        }
        
        // Reset worker quit notification at the start of each cycle
        workersQuit = 0
        hasWorkersQuit = false
        
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
        
        // Calculate raw contribution from workers
        let workerContribution = baseWorkerRate * Double(workers) * workerEfficiency
        
        // Calculate raw contribution from automated systems
        let systemContribution = baseSystemRate * automationEfficiency
        
        // Total raw automation rate
        let totalRawRate = workerContribution + systemContribution
        
        // Apply morale factor (affects combined rate)
        let moraleAdjustedRate = totalRawRate * moraleFactor
        
        // Apply environmental impact penalty: high impact slows automation (max penalty 50% at 100 impact)
        let envPenaltyFactor: Double = max(0, 1.0 - environmentalImpact / 200.0)
        let finalAdjustedRate = moraleAdjustedRate * envPenaltyFactor
        
        // Calculate fractional packages shipped (with environmental penalty)
        let fractionalPackages = finalAdjustedRate * timeElapsed
        
        // Add to our accumulator
        packageAccumulator += fractionalPackages
        
        // Process whole packages
        let packagesShipped = Int(packageAccumulator)
        if packagesShipped > 0 {
            totalPackagesShipped += packagesShipped
            
            // Calculate package value factoring in customer satisfaction and public perception
            let perceptionFactor = 0.8 + (publicPerception / 100.0 * 0.4) // Scales 80% to 120%
            let satisfactionFactor = 0.5 + (customerSatisfaction * 0.5) // Scales 50% to 100%
            let valuePerPackage = packageValue * perceptionFactor * satisfactionFactor
            // let valuePerPackage = packageValue * (0.5 + (customerSatisfaction * 0.5)) // OLD CALC
            earnMoney(Double(packagesShipped) * valuePerPackage)
            
            // Subtract the shipped packages from the accumulator
            packageAccumulator -= Double(packagesShipped)
        }

        // Process pending delayed effects
        let effectsToApply = pendingEffects.filter { currentTime >= $0.triggerTime }
        for effect in effectsToApply {
            effect.applyEffect(self)
        }
        // Remove applied effects
        pendingEffects.removeAll { currentTime >= $0.triggerTime }

        // Slowly decay morale if very low ethics
        if corporateEthics < 0.3 && workerMorale > 0.2 {
            workerMorale -= timeElapsed * 0.01 * (0.3 - corporateEthics)
        }
        
        // Handle Loop Ending Instability
        if isInLoopEndingState {
            if let startTime = loopEndingStartTime {
                let timeInLoop = currentTime.timeIntervalSince(startTime)
                if timeInLoop > 60.0 { // After 60 seconds in loop state
                    // Start decreasing ethics score (rate can be adjusted)
                    let decayRate = 0.1 // Decrease score by 0.1 per second after 60s
                    ethicsScore -= decayRate * timeElapsed
                    ethicsScore = max(0, ethicsScore) // Prevent going below 0 this way
                    
                    // If score drops out of loop range or hits 0, collapse
                    if ethicsScore < 15 {
                        isInLoopEndingState = false
                        loopEndingStartTime = nil
                        isCollapsing = true
                        endingType = .collapse
                    }
                }
            } else {
                // Should not happen if isInLoopEndingState is true, but set start time just in case
                loopEndingStartTime = currentTime
            }
        }
        
        // Chance for workers to quit if morale is critically low
        if workerMorale < 0.1 && workers > 1 { // Ensure morale is very low and we have more than 1 worker
            let quitChanceBase = 0.01 // Base 1% chance per second at 0 morale
            let quitChance = (0.1 - workerMorale) * 10.0 * quitChanceBase // Scale chance up as morale approaches 0
            if Double.random(in: 0...1) < quitChance * timeElapsed {
                let quitCount = min(workers - 1, 1 + Int(Double.random(in: 0...1) * Double(workers) * 0.1))
                workers -= quitCount
                workersQuit = quitCount
                hasWorkersQuit = true
            }
        }
        
        lastUpdate = currentTime
    }
    
    // Check if the player can afford an upgrade
    func canAfford(_ cost: Double) -> Bool {
        return money >= cost
    }
    
    // Apply an upgrade
    func applyUpgrade(_ upgrade: Upgrade) {
        // First verify if upgrade has already been purchased (safer check)
        if !upgrade.isRepeatable && hasBeenPurchased(upgrade) {
            print("Upgrade \(upgrade.name) has already been purchased. Ignoring.")
            return
        }
        
        // Count how many times this upgrade has been purchased if repeatable
        let timesPurchased = purchasedUpgradeIDs.filter { $0 == upgrade.id }.count
        
        // Calculate actual cost based on purchase count for repeatable upgrades
        let actualCost = upgrade.isRepeatable && timesPurchased > 0 
            ? UpgradeManager.calculatePrice(basePrice: upgrade.cost, timesPurchased: timesPurchased, scalingFactor: upgrade.priceScalingFactor)
            : upgrade.cost
            
        if canAfford(actualCost) {
            // Safety check: Ensure the upgrade meets requirements before applying
            guard isUpgradeUnlocked(upgrade) else {
                print("Attempted to purchase locked upgrade: \(upgrade.name)")
                return // Don't proceed if locked
            }

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
                    priceScalingFactor: upgrade.priceScalingFactor,
                    moralImpact: upgrade.moralImpact,
                    publicPerceptionImpact: upgrade.publicPerceptionImpact,
                    environmentalImpactImpact: upgrade.environmentalImpactImpact,
                    requirement: upgrade.requirement,
                    requirementDescription: upgrade.requirementDescription
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
    
    // Check if an upgrade's requirements are met
    func isUpgradeUnlocked(_ upgrade: Upgrade) -> Bool {
        // If no requirement is defined, it's unlocked
        guard let requirement = upgrade.requirement else {
            return true
        }
        // Evaluate the requirement closure against the current game state
        return requirement(self)
    }
    
    // Get a human-readable description of what's needed to unlock an upgrade
    func getUpgradeRequirementDescription(_ upgrade: Upgrade) -> String? {
        // If the upgrade has an explicit requirement description, use that
        if let explicitDescription = upgrade.requirementDescription {
            return explicitDescription
        }
        
        // If upgrade is already unlocked, no need for a description
        if isUpgradeUnlocked(upgrade) {
            return nil
        }
        
        // No explicit description and upgrade is locked, try to generate one
        // Use upgrade requirements to provide a helpful message
        // These are common patterns in the UpgradeManager requirements
        
        // Check for automation level requirements
        if let req = upgrade.requirement, !req(self) {
            if automationLevel < 1 && upgrade.name.contains("AI") {
                return "Requires Automation Level 1"
            }
            
            if workers < 5 && upgrade.name.contains("Worker") {
                return "Requires 5 Workers"
            }
            
            if ethicsScore < 50 && upgrade.name.contains("Break") {
                return "Requires Ethics Score < 50"
            }
            
            if ethicsScore >= 50 && (upgrade.name.contains("Sustainable") || upgrade.name.contains("Community")) {
                return "Requires Ethics Score ≥ 50"
            }
            
            if totalPackagesShipped < 500 && upgrade.name.contains("Sustainable") {
                return "Requires 500+ Packages Shipped"
            }
            
            if money < 500 && upgrade.cost > 500 {
                return "Requires $500+"
            }
            
            if money < 1500 && upgrade.name.contains("Community") {
                return "Requires $1500+"
            }
        }
        
        // Default generic message
        return "Requirements not met"
    }
    
    // Check if an upgrade has been purchased
    func hasBeenPurchased(_ upgrade: Upgrade) -> Bool {
        // Add special debug for problem upgrades
        let trackedUpgrades = ["Improve Packaging", "Basic Training"]
        let isTrackedUpgrade = trackedUpgrades.contains(upgrade.name)
        
        // Log the beginning of check for tracked upgrades
        if isTrackedUpgrade {
            print("TRACKING: Checking if \(upgrade.name) with ID \(upgrade.id) has been purchased")
        }
        
        // For repeatable upgrades, we need to check by specific ID
        if upgrade.isRepeatable {
            let contains = purchasedUpgradeIDs.contains(upgrade.id)
            return contains
        } 
        
        // For non-repeatable upgrades, first try a direct match
        // This is the most efficient path and should work with our stable IDs
        if purchasedUpgradeIDs.contains(upgrade.id) {
            if isTrackedUpgrade {
                print("TRACKING: Direct ID match for \(upgrade.name)")
            }
            return true
        }
        
        // Fallback to name-based matching for backward compatibility
        // Check if ANY upgrade with this name is in the purchased list
        for purchasedID in purchasedUpgradeIDs {
            // Find this ID in available upgrades
            for availableUpgrade in UpgradeManager.availableUpgrades {
                if availableUpgrade.id == purchasedID && 
                   !availableUpgrade.isRepeatable && 
                   availableUpgrade.name == upgrade.name {
                    
                    if isTrackedUpgrade {
                        print("TRACKING: Name match found for \(upgrade.name) through ID lookup")
                    }
                    
                    // Auto-fix: Add this upgrade's ID to the purchased list for future checks
                    if !purchasedUpgradeIDs.contains(upgrade.id) {
                        purchasedUpgradeIDs.append(upgrade.id)
                        if isTrackedUpgrade {
                            print("TRACKING: Added current ID for \(upgrade.name) to purchasedUpgradeIDs")
                        }
                    }
                    
                    return true
                }
            }
        }
        
        // Not found by any method
        if isTrackedUpgrade {
            print("TRACKING: No match found for \(upgrade.name) with ID \(upgrade.id)")
        }
        
        return false
    }
    
    // Get the current cost of an upgrade accounting for price increases
    func getCurrentUpgradeCost(_ upgrade: Upgrade) -> Double {
        // First validate upgraded state
        validateGameState()
        
        if !upgrade.isRepeatable {
            return upgrade.cost
        }
        
        // For worker upgrades, base cost on worker count for safety
        if upgrade.name == "Hire Worker" {
            // Count worker upgrades to validate
            let workerUpgradeCount = upgrades.filter { $0.name == "Hire Worker" }.count
            
            // Count how many worker upgrades we've purchased - with safety cap
            let safeWorkerCount = min(1000, max(workers, workerUpgradeCount)) 
            
            // Use a safer calculation method that avoids Int overflow
            let baseCost = safeCalculateWorkerPrice(basePrice: upgrade.cost, 
                                                  workerCount: safeWorkerCount, 
                                                  scalingFactor: upgrade.priceScalingFactor)
            
            // Apply perception modifier
            let perceptionModifier = calculatePerceptionModifier()
            return baseCost * perceptionModifier
        }
        
        // Standard calculation for other repeatable upgrades
        // Calculate base cost accounting for repeatability
        let safeTimesPurchased = min(1000, purchasedUpgradeIDs.filter { $0 == upgrade.id }.count)
        
        // Use the upgrade's scaling factor directly with safety bounds
        let baseCost = safeCalculatePrice(basePrice: upgrade.cost, 
                                       timesPurchased: safeTimesPurchased, 
                                       scalingFactor: upgrade.priceScalingFactor)
        
        // Apply modifier based on public perception (0-100 scale)
        let perceptionModifier = calculatePerceptionModifier()
        
        return baseCost * perceptionModifier
    }
    
    // Safe calculation function that avoids Int overflow
    private func safeCalculatePrice(basePrice: Double, timesPurchased: Int, scalingFactor: Double) -> Double {
        // Cap to prevent overflow
        let maxFactor = 10000.0
        
        // For 0 purchases, return base price
        if timesPurchased <= 0 {
            return basePrice
        }
        
        // Use a safer calculation that avoids potential overflow
        // Calculate growth factor with safety bounds
        let growthFactor = min(maxFactor, pow(scalingFactor, Double(min(50, timesPurchased))))
        
        // Apply maximum price cap to prevent excessive costs
        let calculatedPrice = basePrice * growthFactor
        let maxPrice = 1000000000.0 // One billion maximum price
        
        return min(maxPrice, calculatedPrice)
    }
    
    // Special calculation just for worker upgrades to handle larger numbers
    private func safeCalculateWorkerPrice(basePrice: Double, workerCount: Int, scalingFactor: Double) -> Double {
        // Apply a more gradual scaling for large worker counts
        let effectiveCount: Double
        if workerCount <= 20 {
            // Normal scaling for first 20 workers
            effectiveCount = Double(workerCount)
        } else if workerCount <= 50 {
            // Slower scaling from 20-50
            effectiveCount = 20.0 + (Double(workerCount - 20) * 0.8)
        } else if workerCount <= 100 {
            // Even slower scaling from 50-100
            effectiveCount = 20.0 + (30.0 * 0.8) + (Double(workerCount - 50) * 0.5)
        } else {
            // Very slow scaling beyond 100
            effectiveCount = 20.0 + (30.0 * 0.8) + (50.0 * 0.5) + (Double(workerCount - 100) * 0.3)
        }
        
        // Use a gentler exponential growth
        let softScalingFactor = 1.0 + ((scalingFactor - 1.0) * 0.7)
        
        // Calculate with safety bounds
        let growthFactor = min(10000.0, pow(softScalingFactor, effectiveCount))
        
        // Apply maximum price cap
        let calculatedPrice = basePrice * growthFactor
        let maxWorkerPrice = 1000000.0 // Cap worker price at 1 million
        
        return min(maxWorkerPrice, calculatedPrice)
    }
    
    // Helper to calculate perception modifier
    private func calculatePerceptionModifier() -> Double {
        if publicPerception < 30 {
            // Increase cost significantly for low perception (up to +50% cost at 0 perception)
            return 1.0 + (30.0 - publicPerception) / 30.0 * 0.5 
        } else if publicPerception > 70 {
            // Decrease cost slightly for high perception (down to -10% cost at 100 perception)
            return 1.0 - (publicPerception - 70.0) / 30.0 * 0.1
        } else {
            // No modifier for neutral perception (30-70)
            return 1.0
        }
    }
    
    // Validate game state integrity
    func validateGameState() {
        // Safety cap for excess values
        let maxWorkers = 150
        
        // 0. Fix excessive worker count first
        if workers > maxWorkers {
            print("DATA INTEGRITY: Excessive worker count (\(workers)). Capping at \(maxWorkers).")
            workers = maxWorkers
        }
        
        // 1. Check and fix worker counts
        let workerUpgradeCount = upgrades.filter { $0.name == "Hire Worker" }.count
        
        // Cap worker upgrade count too
        if workerUpgradeCount > maxWorkers {
            print("DATA INTEGRITY: Excessive worker upgrade count (\(workerUpgradeCount)). Capping at \(maxWorkers).")
            
            // Remove excess worker upgrades
            let excess = workerUpgradeCount - maxWorkers
            var removed = 0
            
            // Remove upgrades from the end of the list
            upgrades.removeAll { upgrade in
                if upgrade.name == "Hire Worker" && removed < excess {
                    removed += 1
                    return true
                }
                return false
            }
        }
        
        // Now balance worker count and upgrade count
        let safeWorkerUpgradeCount = upgrades.filter { $0.name == "Hire Worker" }.count
        if safeWorkerUpgradeCount != workers {
            print("DATA INTEGRITY: Worker count (\(workers)) doesn't match worker upgrade count (\(safeWorkerUpgradeCount)). Fixing...")
            
            // Use the smaller value to avoid issues
            let targetCount = min(workers, safeWorkerUpgradeCount)
            
            // Reset the worker upgrades
            let workerUpgrade = UpgradeManager.EarlyGame.hireWorker
            upgrades.removeAll { $0.name == "Hire Worker" }
            
            // Recreate the correct number of worker upgrades
            for _ in 0..<targetCount {
                let uniqueUpgrade = Upgrade(
                    id: UUID(),
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
                upgrades.append(uniqueUpgrade)
            }
            
            // Update worker count
            workers = targetCount
            print("DATA INTEGRITY: Fixed - worker count now \(workers), upgrade count now \(upgrades.count)")
        }
        
        // 2. Check for duplicate upgrade IDs in purchasedUpgradeIDs
        var uniqueIDs = Set<UUID>()
        var duplicates = 0
        
        var newPurchasedUpgradeIDs: [UUID] = []
        for id in purchasedUpgradeIDs {
            if uniqueIDs.contains(id) {
                duplicates += 1
            } else {
                uniqueIDs.insert(id)
                newPurchasedUpgradeIDs.append(id)
            }
        }
        
        if duplicates > 0 {
            print("DATA INTEGRITY: Found \(duplicates) duplicate IDs in purchasedUpgradeIDs. Fixing...")
            purchasedUpgradeIDs = newPurchasedUpgradeIDs
        }
        
        // 3. Cap total purchasedUpgradeIDs to a reasonable number if needed
        let maxPurchasedIDs = 500
        if purchasedUpgradeIDs.count > maxPurchasedIDs {
            print("DATA INTEGRITY: Excessive purchased upgrade IDs (\(purchasedUpgradeIDs.count)). Capping at \(maxPurchasedIDs).")
            purchasedUpgradeIDs = Array(purchasedUpgradeIDs.prefix(maxPurchasedIDs))
        }
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
        // 4. Must have hired at least 3 workers
        let meetsCriteria = ethicsScore >= 15 && ethicsScore <= 25 && money >= 2500 && totalPackagesShipped >= 1500 && workers >= 3
        
        if meetsCriteria && !isInLoopEndingState {
            // Enter loop state
            endingType = .loop
            isInLoopEndingState = true
            loopEndingStartTime = Date() // Record start time
        } else if !meetsCriteria && isInLoopEndingState {
            // Exit loop state if criteria are no longer met (before collapse)
            isInLoopEndingState = false
            loopEndingStartTime = nil
            // Re-evaluate ending type if not collapsing
            if !isCollapsing {
                 checkForReformEnding() // Check if reform is met now
                 // If neither reform nor collapse, perhaps revert to a default/ongoing state?
                 // For now, it will stay as .loop until collapse or reform conditions are met elsewhere.
            }
        }
    }
    
    // Fix for upgrades after loading - this should be called right after loading saved game
    func verifyUpgradeIntegrity() {
        print("Verifying upgrade integrity after load...")
        
        // Get all non-repeatable upgrades from UpgradeManager
        let nonRepeatableUpgrades = UpgradeManager.availableUpgrades.filter { !$0.isRepeatable }
        
        // Collect all upgrade names that should be considered purchased
        var shouldBePurchasedNames = Set<String>()
        var shouldBePurchasedIDs = Set<UUID>()
        
        // Examine purchased upgrade IDs to extract names
        for id in purchasedUpgradeIDs {
            for upgrade in UpgradeManager.availableUpgrades {
                if upgrade.id == id || upgrade.id.uuidString == id.uuidString {
                    shouldBePurchasedNames.insert(upgrade.name)
                    shouldBePurchasedIDs.insert(upgrade.id)
                    break
                }
            }
        }
        
        print("Found \(shouldBePurchasedNames.count) purchased upgrade names")
        print("Current unique purchased IDs: \(shouldBePurchasedIDs.count)")
        
        // Ensure we have all current IDs for these names
        var fixedCount = 0
        var currentIDs = purchasedUpgradeIDs
        
        // For each purchased name, ensure we have the current ID in our list
        for name in shouldBePurchasedNames {
            if let upgrade = UpgradeManager.availableUpgrades.first(where: { $0.name == name && !$0.isRepeatable }) {
                if !currentIDs.contains(upgrade.id) {
                    currentIDs.append(upgrade.id)
                    fixedCount += 1
                    print("INTEGRITY: Added missing current ID for \(name)")
                }
            }
        }
        
        // Update the list with our fixed version if changes were made
        if fixedCount > 0 {
            print("INTEGRITY: Fixed \(fixedCount) missing upgrade IDs")
            purchasedUpgradeIDs = currentIDs
        }
        
        // ENHANCED INTEGRITY CHECK: Verify critical upgrades are correctly applied
        let criticalUpgradeNames = [
            "Improve Packaging", 
            "Basic Training", 
            "Automation Level 1",
            "Efficiency Training",
            "Better Morale",
            "Quality Control"
        ]
        
        // Track which critical upgrades are in purchased list vs in visual upgrades list
        var missingVisualCriticalUpgrades = Set<String>()
        var missingPurchasedCriticalUpgrades = Set<String>()
        
        // Find critical upgrades that should be purchased but aren't in the visual list
        for name in shouldBePurchasedNames.filter({ criticalUpgradeNames.contains($0) }) {
            let hasVisualUpgrade = upgrades.contains(where: { $0.name == name })
            if !hasVisualUpgrade {
                missingVisualCriticalUpgrades.insert(name)
            }
        }
        
        // Find critical upgrades in the visual list but not in purchased IDs
        for upgrade in upgrades.filter({ criticalUpgradeNames.contains($0.name) }) {
            let isPurchased = purchasedUpgradeIDs.contains(upgrade.id)
            if !isPurchased {
                missingPurchasedCriticalUpgrades.insert(upgrade.name)
            }
        }
        
        // Fix missing visual upgrades (upgrades that are purchased but don't show up)
        if !missingVisualCriticalUpgrades.isEmpty {
            print("CRITICAL INTEGRITY: Found \(missingVisualCriticalUpgrades.count) critical upgrades missing from visual list")
            
            for name in missingVisualCriticalUpgrades {
                if let template = UpgradeManager.availableUpgrades.first(where: { $0.name == name }) {
                    // Create new visual upgrade with proper ID
                    let visualUpgrade = Upgrade(
                        id: template.id, // Use the stable ID
                        name: template.name,
                        description: template.description,
                        cost: template.cost,
                        effect: template.effect,
                        isRepeatable: template.isRepeatable,
                        priceScalingFactor: template.priceScalingFactor,
                        moralImpact: template.moralImpact,
                        publicPerceptionImpact: template.publicPerceptionImpact,
                        environmentalImpactImpact: template.environmentalImpactImpact
                    )
                    upgrades.append(visualUpgrade)
                    print("CRITICAL INTEGRITY: Added missing visual upgrade: \(name)")
                }
            }
        }
        
        // Fix missing purchased IDs (visual upgrades that aren't in purchased list)
        if !missingPurchasedCriticalUpgrades.isEmpty {
            print("CRITICAL INTEGRITY: Found \(missingPurchasedCriticalUpgrades.count) critical upgrades missing from purchased list")
            
            for name in missingPurchasedCriticalUpgrades {
                for upgrade in upgrades.filter({ $0.name == name }) {
                    if !purchasedUpgradeIDs.contains(upgrade.id) {
                        purchasedUpgradeIDs.append(upgrade.id)
                        print("CRITICAL INTEGRITY: Added missing purchased ID for: \(name)")
                    }
                }
            }
        }
        
        print("Upgrade integrity verification complete")
        print("Final state: \(upgrades.count) visual upgrades, \(purchasedUpgradeIDs.count) purchased IDs")
    }
    
    // Reset game state (used for new games or after collapse)
    func reset() {
        print("Performing complete game reset...")
        
        // Basic stats reset
        totalPackagesShipped = 0
        money = 0.0
        workers = 1  // Reset to 1 worker instead of 0
        baseWorkerRate = 0.1 // Reset base worker rate
        baseSystemRate = 0.0 // Reset base system rate
        packageAccumulator = 0.0
        ethicsScore = 100.0 // Reset ethics score to 100
        isCollapsing = false
        lastUpdate = Date()
        ethicalChoicesMade = 0
        endingType = .collapse
        isInLoopEndingState = false // Reset loop state tracking
        loopEndingStartTime = nil   // Reset loop start time
        workersQuit = 0
        hasWorkersQuit = false
        
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
        
        // CRITICAL: Complete reset of all upgrades tracking
        print("Clearing all upgrade tracking data...")
        upgrades.removeAll()
        purchasedUpgradeIDs.removeAll()
        
        // Create the initial worker upgrade
        let workerUpgrade = UpgradeManager.EarlyGame.hireWorker
        let initialWorker = Upgrade(
            id: UUID(),  // New unique ID for this worker
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
        upgrades.append(initialWorker)
        
        print("Game has been completely reset with 1 worker and 0 purchased upgrades")
    }
} 
