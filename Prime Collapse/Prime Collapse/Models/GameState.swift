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
    /// Upper bound on a single automation step's elapsed time. The game loop only ticks
    /// while the app is foregrounded, so returning from a long background produces one tick
    /// with a huge gap. Capping it both prevents numeric overflow in the package/money math
    /// and keeps offline catch-up to a sane amount (8 hours).
    static let maxAutomationCatchUp: TimeInterval = 8 * 60 * 60

    /// Hard cap on hired workers. Purchases at the cap are blocked up front so the
    /// player is never charged for a worker that data-integrity validation would strip.
    static let maxWorkers = 150

    /// Reform is the capstone of a clean run, reachable only after the late-game events and
    /// ethical upgrades — not by holding $1K after a few cheap good deeds. Lifetime earnings,
    /// not the balance, because ethical event choices now cost cash.
    static let reformEthicalChoices = 10
    static let reformEthicsScore = 70.0
    static let reformLifetimeEarnings = 25_000.0

    // Core game metrics
    var totalPackagesShipped: Int = 0
    // Clamp money >= 0 and reject non-finite values (NaN/inf) so a bad calculation
    // can never poison the balance.
    private var _money: Double = 0.0
    var money: Double {
        get { _money }
        set { _money = newValue.isFinite ? max(0, newValue) : _money }
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
    
    // Prestige / New Game+ meta-progression. Kept in sync with the persisted
    // PrestigeState by PrestigeManager; reset() reads it to seed starting bonuses.
    var prestige: PrestigeState = PrestigeState()
    /// Guards `concludeRun()` so a single run banks its prestige only once.
    private var hasBankedPrestigeThisRun: Bool = false

    // New game ending properties
    var ethicalChoicesMade: Int = 0
    var endingType: GameEnding = .collapse
    /// True once a win-state ending (Reform or Loop) has been earned. The UI observes
    /// this to stop the game loop and present the ending screen; collapse keeps its own
    /// flow via `isCollapsing`.
    var endingReached: Bool = false
    
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

    /// Temporary income changes from event choices. Not persisted — they last a minute or two.
    struct IncomeModifier: Equatable {
        let bonus: Double
        let start: Date
        let end: Date
    }
    var incomeModifiers: [IncomeModifier] = []

    /// Fraction (0–0.5) by which the current environmental impact is slowing automation.
    /// Mirrors the `envPenaltyFactor` used in `processAutomation` (max 50% at 100 impact),
    /// so the UI can explain *why* automation slowed.
    var environmentalSlowdownFraction: Double {
        max(0, min(0.5, environmentalImpact / 200.0))
    }

    // Saturating add: the lifetime counter clamps at Int.max instead of trapping,
    // since runaway efficiency multipliers can push per-tick shipments arbitrarily high.
    private func addPackagesShipped(_ count: Int) {
        let (sum, didOverflow) = totalPackagesShipped.addingReportingOverflow(count)
        totalPackagesShipped = didOverflow ? Int.max : sum
    }

    // Ship a package manually (tap action)
    func shipPackage() {
        addPackagesShipped(1)
        let now = Date()
        earnMoney(valuePerPackage * incomeMultiplier(from: now, to: now))
    }

    /// Money per package: package value scaled by public perception (80–120%) and
    /// customer satisfaction (50–100%).
    var valuePerPackage: Double {
        let perceptionFactor = 0.8 + (publicPerception / 100.0 * 0.4)
        let satisfactionFactor = 0.5 + (customerSatisfaction * 0.5)
        return packageValue * perceptionFactor * satisfactionFactor
    }

    /// Automated packages per second after morale and environmental penalties.
    var automationRate: Double {
        // Morale below 0.5 reduces output linearly to 0; above 0.7 boosts it up to +10% at 1.0.
        let moraleFactor: Double
        if workerMorale < 0.5 {
            moraleFactor = workerMorale * 2.0
        } else if workerMorale > 0.7 {
            moraleFactor = 1.0 + (workerMorale - 0.7) / 3.0
        } else {
            moraleFactor = 1.0
        }
        let workerContribution = baseWorkerRate * Double(workers) * workerEfficiency
        let systemContribution = baseSystemRate * automationEfficiency
        // High environmental impact slows automation (max penalty 50% at 100 impact)
        let envPenaltyFactor = max(0, 1.0 - environmentalImpact / 200.0)
        return (workerContribution + systemContribution) * moraleFactor * envPenaltyFactor
    }

    /// Automated income per second at current stats, before temporary event modifiers.
    var baseIncomePerSecond: Double {
        let income = automationRate * valuePerPackage
        return income.isFinite ? max(0, income) : 0
    }

    /// Yardstick for event stakes: a minute of automated income, or 2% of lifetime earnings —
    /// whichever is larger, so tap-heavy early play and idle late play both register.
    var earningsPerMinute: Double {
        max(baseIncomePerSecond * 60, lifetimeTotalMoneyEarned * 0.02)
    }

    /// Average income multiplier from event modifiers over `[from, to]`. Prorated so a single
    /// long catch-up tick only pays a 60-second boost for 60 seconds. A zero-length window
    /// returns the multiplier at that instant.
    func incomeMultiplier(from: Date, to: Date) -> Double {
        let window = to.timeIntervalSince(from)
        var bonus = 0.0
        for modifier in incomeModifiers {
            if window > 0 {
                let overlap = min(to, modifier.end).timeIntervalSince(max(from, modifier.start))
                if overlap > 0 { bonus += modifier.bonus * overlap / window }
            } else if modifier.start <= to && to < modifier.end {
                bonus += modifier.bonus
            }
        }
        return max(0.1, 1.0 + bonus)
    }

    func applyIncomeShift(_ shift: IncomeShift, at now: Date = Date()) {
        incomeModifiers.append(IncomeModifier(bonus: shift.bonus, start: now,
                                              end: now.addingTimeInterval(shift.duration)))
    }

    func scheduleEffect(after delay: TimeInterval, from now: Date = Date(),
                        _ apply: @escaping (GameState) -> Void) {
        pendingEffects.append(DelayedEffect(triggerTime: now.addingTimeInterval(delay), applyEffect: apply))
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
        let rawElapsed = currentTime.timeIntervalSince(lastUpdate)

        // Skip if no time has passed (or the clock moved backwards / produced a bad value).
        guard rawElapsed > 0, rawElapsed.isFinite else {
            lastUpdate = currentTime
            return
        }

        // Cap catch-up time so a long background gap can't overflow the math or dump an
        // absurd burst of packages/money in a single tick.
        let timeElapsed = min(rawElapsed, GameState.maxAutomationCatchUp)
        
        // Reset worker quit notification at the start of each cycle
        workersQuit = 0
        hasWorkersQuit = false
        
        // Calculate fractional packages shipped (morale and environmental penalties included)
        let fractionalPackages = automationRate * timeElapsed

        // Add to our accumulator, guarding against non-finite values poisoning it.
        if fractionalPackages.isFinite && fractionalPackages > 0 {
            packageAccumulator += fractionalPackages
        }
        if !packageAccumulator.isFinite { packageAccumulator = 0 }

        // Process whole packages. Guard against an accumulator so large that Int(...)
        // would overflow/trap.
        let packagesShipped = packageAccumulator >= Double(Int.max)
            ? 0
            : Int(packageAccumulator)
        if packagesShipped > 0 {
            addPackagesShipped(packagesShipped)
            let multiplier = incomeMultiplier(from: currentTime.addingTimeInterval(-timeElapsed), to: currentTime)
            earnMoney(Double(packagesShipped) * valuePerPackage * multiplier)

            // Subtract the shipped packages from the accumulator
            packageAccumulator -= Double(packagesShipped)
        }
        incomeModifiers.removeAll { $0.end <= currentTime }

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
        
        // Handle Loop Ending Instability: surviving the full 60-second window while the
        // loop criteria hold completes the hidden Loop ending. (Previously this decayed
        // ethics until collapse, which made the Loop ending impossible to finish.)
        if isInLoopEndingState && !endingReached {
            if let startTime = loopEndingStartTime {
                let timeInLoop = currentTime.timeIntervalSince(startTime)
                if timeInLoop > 60.0 {
                    endingType = .loop
                    endingReached = true
                    isInLoopEndingState = false
                    loopEndingStartTime = nil
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
        
        // Reform criteria can be completed by passive income crossing the money
        // threshold, so re-check every tick — not only on upgrade purchases.
        checkForReformEnding()

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
        
        // Block worker purchases at the cap up front — otherwise the player is charged
        // and validateGameState() strips the extra worker on the next tick.
        if upgrade.name == "Hire Worker" && workers >= GameState.maxWorkers {
            print("Worker cap (\(GameState.maxWorkers)) reached. Purchase blocked.")
            return
        }

        // Charge exactly what the buy button displays (same calculation, including
        // the public-perception modifier and worker-count curve).
        let actualCost = getCurrentUpgradeCost(upgrade)

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
    
    // Check if an upgrade has been purchased.
    // Upgrade templates come from UpgradeManager.availableUpgrades, whose IDs are
    // stable for the lifetime of the app (they are `static let`s), and the save
    // system restores purchases against those same IDs — so a direct ID match is
    // both correct and sufficient for repeatable and non-repeatable upgrades.
    func hasBeenPurchased(_ upgrade: Upgrade) -> Bool {
        return purchasedUpgradeIDs.contains(upgrade.id)
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
    
    // Safe calculation function that avoids Int overflow.
    // Internal (not private) so the test target can exercise the bounds directly.
    func safeCalculatePrice(basePrice: Double, timesPurchased: Int, scalingFactor: Double) -> Double {
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
    
    // Special calculation just for worker upgrades to handle larger numbers.
    // Internal (not private) so the test target can exercise the bounds directly.
    func safeCalculateWorkerPrice(basePrice: Double, workerCount: Int, scalingFactor: Double) -> Double {
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
        let maxWorkers = GameState.maxWorkers

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
        
        // 2. Check for duplicate upgrade IDs in purchasedUpgradeIDs.
        // Repeatable upgrades legitimately append the same template ID once per
        // purchase — that history drives price scaling and must be preserved.
        // Only duplicates of non-repeatable IDs are corruption.
        let repeatableTemplateIDs = Set(
            UpgradeManager.availableUpgrades.filter(\.isRepeatable).map(\.id)
        )
        var uniqueIDs = Set<UUID>()
        var duplicates = 0

        var newPurchasedUpgradeIDs: [UUID] = []
        for id in purchasedUpgradeIDs {
            if uniqueIDs.contains(id) && !repeatableTemplateIDs.contains(id) {
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
    
    // Check if player qualifies for the Reform ending.
    // Internal (not private) so tests can verify the threshold logic directly.
    func checkForReformEnding() {
        // Collapse takes precedence, and an earned ending only fires once.
        guard !isCollapsing && !endingReached else { return }

        if ethicalChoicesMade >= GameState.reformEthicalChoices
            && ethicsScore >= GameState.reformEthicsScore
            && lifetimeTotalMoneyEarned >= GameState.reformLifetimeEarnings {
            endingType = .reform
            endingReached = true
        }
    }
    
    // Check if player qualifies for the Loop ending.
    // Internal (not private) so tests can verify the threshold logic directly.
    func checkForLoopEnding() {
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
    
    /// Bank prestige points earned by the run that just ended. Idempotent within a
    /// run (guarded), so calling it from multiple ending code paths is safe. Returns
    /// the points awarded (0 if already banked or the run earned none). The caller is
    /// responsible for persisting `prestige` afterwards.
    @discardableResult
    func concludeRun() -> Int {
        guard !hasBankedPrestigeThisRun else { return 0 }
        hasBankedPrestigeThisRun = true
        let earned = PrestigeState.pointsAwarded(lifetimeMoney: lifetimeTotalMoneyEarned,
                                                 ending: endingType)
        prestige.award(earned)
        return earned
    }

    /// Apply prestige perks as one-time starting bonuses. Called at the end of reset()
    /// so a New Game+ begins with its earned head start. Deliberately confined here — it
    /// never touches the per-tick income math.
    private func applyPrestigeStartingBonuses() {
        money += prestige.startingCash
        baseWorkerRate *= prestige.productionMultiplier
        publicPerception += prestige.startingPerceptionBonus // clamped by the setter

        // Add the founding-team workers, each with a matching Hire Worker instance so
        // validateGameState() doesn't reconcile them away.
        let bonusWorkers = min(prestige.startingWorkerBonus,
                               GameState.maxWorkers - workers)
        if bonusWorkers > 0 {
            let template = UpgradeManager.EarlyGame.hireWorker
            for _ in 0..<bonusWorkers {
                let instance = Upgrade(
                    id: UUID(),
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
                upgrades.append(instance)
            }
            workers += bonusWorkers
        }
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
        endingReached = false
        isInLoopEndingState = false // Reset loop state tracking
        loopEndingStartTime = nil   // Reset loop start time
        workersQuit = 0
        hasWorkersQuit = false
        // Don't let a previous run's scandals or boosts land in this one.
        pendingEffects.removeAll()
        incomeModifiers.removeAll()

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

        // A fresh run can bank prestige again.
        hasBankedPrestigeThisRun = false

        // Seed permanent prestige head-start bonuses (no-op when there's no prestige).
        applyPrestigeStartingBonuses()

        print("Game has been completely reset with \(workers) worker(s) and 0 purchased upgrades")
    }
} 
