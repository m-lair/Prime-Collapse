//
//  UpgradeManager.swift
//  Prime Collapse
//
//  Created on 4/15/25.
//

import Foundation

struct UpgradeManager {
    // --- Constants for Balancing ---
    private struct Constants {
        // Efficiency Multipliers
        static let workerEfficiencyBoostTiny: Double = 1.1
        static let workerEfficiencyBoostSmall: Double = 1.15
        static let workerEfficiencyBoostMedium: Double = 1.2
        static let workerEfficiencyBoostLarge: Double = 1.5
        static let workerEfficiencyBoostHuge: Double = 1.6
        static let workerEfficiencyBoostMassive: Double = 1.8
        static let workerEfficiencyBoostExploit: Double = 2.0

        static let automationEfficiencyBoostSmall: Double = 1.3
        static let automationEfficiencyBoostMedium: Double = 1.4
        static let automationEfficiencyBoostLarge: Double = 2.0
        static let automationEfficiencyBoostHuge: Double = 3.0

        // Value Multipliers
        static let packageValueBoostSmall: Double = 1.1
        static let packageValueBoostMedium: Double = 1.3

        // Rate Increases
        static let baseSystemRateIncreaseSmall: Double = 0.5
        static let baseSystemRateIncreaseMedium: Double = 1.2 // Multiplier

        // Morale Changes
        static let moraleBoostSmall: Double = 0.1
        static let moraleBoostMedium: Double = 0.2
        static let moraleDecreaseTiny: Double = 0.05
        static let moraleDecreaseSmall: Double = 0.1
        static let moraleDecreaseMedium: Double = 0.15
        static let moraleDecreaseLarge: Double = 0.2
        static let moraleDecreaseHuge: Double = 0.25
        static let moraleDecreaseMassive: Double = 0.3

        // Ethics Changes
        static let ethicsBoostSmall: Double = 0.05
        static let ethicsBoostMedium: Double = 0.15
        static let ethicsBoostLarge: Double = 0.2
        static let ethicsDecreaseSmall: Double = 0.1
        static let ethicsDecreaseMedium: Double = 0.15
        static let ethicsDecreaseLarge: Double = 0.2
        static let ethicsDecreaseHuge: Double = 0.25

        // Public Perception Changes
        static let perceptionBoostSmall: Double = 2.0
        static let perceptionBoostMedium: Double = 10.0
        static let perceptionBoostLarge: Double = 12.0
        static let perceptionBoostHuge: Double = 15.0
        static let perceptionDecreaseSmall: Double = -2.0
        static let perceptionDecreaseMedium: Double = -7.0
        static let perceptionDecreaseLarge: Double = -10.0
        static let perceptionDecreaseHuge: Double = -12.0
        static let perceptionDecreaseMassive: Double = -18.0
        static let perceptionDecreaseCatastrophic: Double = -20.0
        static let perceptionDecreaseApocalyptic: Double = -25.0
        static let perceptionDecreaseExtinction: Double = -30.0

        // Environmental Impact Changes
        static let envImpactPositiveSmall: Double = -15.0 // Negative value means improvement
        static let envImpactNegativeSmall: Double = 3.0
        static let envImpactNegativeMedium: Double = 5.0

        // Misc
        static let automationLevelIncreaseSmall: Int = 1
        static let automationLevelIncreaseMedium: Int = 2
        static let customerSatisfactionBoostSmall: Double = 0.1
        static let customerSatisfactionBoostMedium: Double = 0.15
        static let immediateProfitSmall: Double = 200.0
        static let immediateProfitMedium: Double = 500.0
        static let layoffProfitPerWorker: Double = 50.0
        static let minWorkersAfterAutomation: Int = 2

        // Moral Impact Values
        static let moralPositiveSmall: Double = 3.0
        static let moralPositiveMedium: Double = 8.0
        static let moralPositiveLarge: Double = 12.0
        static let moralNegativeTiny: Double = -1.0
        static let moralNegativeSmall: Double = -3.0
        static let moralNegativeMedium: Double = -5.0
        static let moralNegativeLarge: Double = -8.0
        static let moralNegativeHuge: Double = -10.0
        static let moralNegativeMassive: Double = -15.0
        static let moralNegativeCatastrophic: Double = -18.0
        static let moralNegativeApocalyptic: Double = -20.0
        static let moralNegativeExtinction: Double = -25.0

        // Added/Adjusted for New Upgrades (examples, verify/integrate with existing)
        static let moraleBoostTiny: Double = 0.02 // For Safety Placards
        static let moralPositiveTiny: Double = 0.5 // For Optimize Logistics
        static let envImpactPositiveTiny: Double = -1.0 // For Predictive Maintenance
    }
    
    // --- Nested Structs for Organization ---
    struct EarlyGame {
        // Basic worker upgrade
        static let hireWorker = Upgrade(
            name: "Hire Worker",
            description: "Hire a worker to ship packages automatically.",
            cost: 50.0, // Increased from 10
            effect: { gameState in
                gameState.workers += 1
            },
            isRepeatable: true,
            priceScalingFactor: 1.4, // Custom scaling for this specific upgrade
            moralImpact: 0.0,
            publicPerceptionImpact: 0.0,
            environmentalImpactImpact: 0.0
        )
        
        // Improve packaging efficiency
        static let improvePackaging = Upgrade(
            name: "Improve Packaging",
            description: "Streamline package handling for better efficiency.",
            cost: 75.0,
            effect: { gameState in
                gameState.workerEfficiency *= Constants.workerEfficiencyBoostMedium // 1.2
                gameState.packageValue *= Constants.packageValueBoostSmall // 1.1
            },
            isRepeatable: false,
            moralImpact: 0.0, // Neutral ethical impact
            publicPerceptionImpact: 0.0,
            environmentalImpactImpact: 0.0
        )
        
        // Basic training for workers
        static let basicTraining = Upgrade(
            name: "Basic Training",
            description: "Train workers for better performance and safety.",
            cost: 100.0,
            effect: { gameState in
                gameState.workerEfficiency *= Constants.workerEfficiencyBoostSmall // 1.15
                gameState.workerMorale += Constants.moraleBoostSmall // 0.1
                gameState.corporateEthics += Constants.ethicsBoostSmall // 0.05
            },
            isRepeatable: false,
            moralImpact: Constants.moralPositiveSmall, // 3.0
            publicPerceptionImpact: Constants.perceptionBoostSmall, // 2.0
            environmentalImpactImpact: 0.0
        )
        
        // --- New Early Game Upgrades ---
        
        static let optimizeLogistics = Upgrade(
            name: "Optimize Logistics",
            description: "Improve delivery routes and scheduling slightly.",
            cost: 60.0,
            effect: { gameState in
                gameState.baseWorkerRate += 0.02
                gameState.packageValue *= 1.05
            },
            isRepeatable: false,
            moralImpact: Constants.moralPositiveTiny, // Reuse/add a tiny positive constant (e.g., 0.5)
            publicPerceptionImpact: 0.5, // Direct value
            environmentalImpactImpact: -0.5 // Direct value (Negative means improvement)
        )
        
        static let bulkMaterialPurchase = Upgrade(
            name: "Bulk Material Purchase",
            description: "Buy packaging materials in larger, cheaper quantities. Slightly increases waste.",
            cost: 80.0,
            effect: { gameState in
                gameState.earnMoney(20.0) // Immediate cash back
                gameState.packageValue *= 1.08
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeTiny, // -1.0
            publicPerceptionImpact: 0.0,
            environmentalImpactImpact: 1.0 // Direct value (Positive means negative impact)
        )
        
        static let safetyPlacards = Upgrade(
            name: "Safety Placards",
            description: "Install basic safety information posters. Minimal cost, minimal effect, signals intent.",
            cost: 40.0,
            effect: { gameState in
                gameState.workerMorale += Constants.moraleBoostTiny // Reuse/add tiny boost (e.g., 0.02)
                gameState.corporateEthics += 0.01 // Direct value
            },
            isRepeatable: false,
            moralImpact: Constants.moralPositiveSmall / 3.0, // Reuse/derive small (e.g., 1.0)
            publicPerceptionImpact: 0.5, // Direct value
            environmentalImpactImpact: 0.0
        )
    }
    
    struct MidGame {
        // Rush delivery service
        static let rushDelivery = Upgrade(
            name: "Rush Delivery",
            description: "Promise faster delivery for premium prices.",
            cost: 250.0,
            effect: { gameState in
                gameState.automationEfficiency *= Constants.automationEfficiencyBoostMedium // 1.4
                gameState.packageValue *= Constants.packageValueBoostMedium // 1.3
                gameState.workerMorale -= Constants.moraleDecreaseTiny // 0.05
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeSmall, // -3.0
            publicPerceptionImpact: Constants.perceptionBoostMedium, // 10.0
            environmentalImpactImpact: Constants.envImpactNegativeMedium, // 5.0
            requirement: { $0.totalPackagesShipped >= 100 },
            requirementDescription: "Requires 100+ Packages Shipped"
        )
        
        // Extended shifts for workers
        static let extendedShifts = Upgrade(
            name: "Extended Shifts",
            description: "Longer working hours for all employees.",
            cost: 300.0,
            effect: { gameState in
                gameState.workerEfficiency *= Constants.workerEfficiencyBoostHuge // 1.6
                gameState.workerMorale -= Constants.moraleDecreaseMedium // 0.15
                gameState.corporateEthics -= Constants.ethicsDecreaseSmall // 0.1
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeLarge, // -8.0
            publicPerceptionImpact: Constants.perceptionDecreaseLarge, // -10.0
            environmentalImpactImpact: 0.0,
            requirement: { $0.workers >= 3 },
            requirementDescription: "Requires 3+ Workers"
        )
        
        // Automate sorting process
        static let automateSorting = Upgrade(
            name: "Automate Sorting",
            description: "Install automated sorting system to reduce the need for manual sorting.",
            cost: 200.0,
            effect: { gameState in
                gameState.automationEfficiency *= Constants.automationEfficiencyBoostSmall // 1.3
                gameState.automationLevel += Constants.automationLevelIncreaseSmall // 1
                gameState.corporateEthics -= Constants.ethicsDecreaseSmall // 0.1
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeSmall, // -3.0
            publicPerceptionImpact: Constants.perceptionDecreaseSmall, // -2.0
            environmentalImpactImpact: Constants.envImpactNegativeSmall, // 3.0
            requirement: { $0.totalPackagesShipped >= 100 },
            requirementDescription: "Requires 100+ Packages Shipped"
        )
        
        // Child labor loopholes (new unethical upgrade)
        static let childLaborLoopholes = Upgrade(
            name: "Child Labor Loopholes",
            description: "Exploit legal loopholes to hire underage workers for lower wages.",
            cost: 400.0,
            effect: { gameState in
                gameState.workerEfficiency *= Constants.workerEfficiencyBoostExploit // 2.0
                gameState.money += Constants.immediateProfitSmall // 200
                gameState.corporateEthics -= Constants.ethicsDecreaseLarge // 0.2
                gameState.workerMorale -= Constants.moraleDecreaseLarge // 0.2
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeApocalyptic, // -20.0
            publicPerceptionImpact: Constants.perceptionDecreaseApocalyptic, // -25.0
            environmentalImpactImpact: 0.0,
            requirement: { $0.ethicsScore < 60 && $0.workers >= 2 },
            requirementDescription: "Ethics Score < 60 and 2+ Workers"
        )
        
        // Employee surveillance (new unethical upgrade)
        static let employeeSurveillance = Upgrade(
            name: "Employee Surveillance",
            description: "Install monitoring systems to track worker productivity.",
            cost: 275.0,
            effect: { gameState in
                gameState.workerEfficiency *= Constants.workerEfficiencyBoostLarge // 1.5
                gameState.workerMorale -= Constants.moraleDecreaseSmall // 0.1
                gameState.corporateEthics -= Constants.ethicsDecreaseSmall // 0.1
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeHuge, // -10.0
            publicPerceptionImpact: Constants.perceptionDecreaseHuge, // -12.0
            environmentalImpactImpact: 0.0,
            requirement: { $0.totalPackagesShipped >= 150 },
            requirementDescription: "Requires 150+ Packages Shipped"
        )
        
        // --- New Mid Game Upgrades ---

        static let performanceBonuses = Upgrade(
            name: "Performance Bonuses",
            description: "Reward productive workers with bonuses. Improves morale and efficiency.",
            cost: 320.0,
            effect: { gameState in
                gameState.workerEfficiency *= Constants.workerEfficiencyBoostTiny // 1.1
                gameState.workerMorale += Constants.moraleBoostMedium // 0.15 (Adjusted to match proposal)
            },
            isRepeatable: true,
            priceScalingFactor: 1.6,
            moralImpact: Constants.moralPositiveMedium / 2.0, // Reuse/derive Medium (4.0)
            publicPerceptionImpact: Constants.perceptionBoostSmall * 1.5, // Reuse/derive Small (3.0)
            environmentalImpactImpact: 0.0,
            requirement: { $0.workers >= 2 && $0.money >= 150 },
            requirementDescription: "Requires 2+ Workers and $150+"
        )

        static let aggressiveMarketing = Upgrade(
            name: "Aggressive Marketing Campaign",
            description: "Launch misleading ads to boost demand and perception, stretching the truth.",
            cost: 280.0,
            effect: { gameState in
                gameState.packageValue *= 1.2 // Direct value
                gameState.customerSatisfaction -= Constants.moraleDecreaseTiny // Reuse tiny decrease (0.05)
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeMedium / 1.25, // Reuse/derive Medium (-4.0)
            publicPerceptionImpact: Constants.perceptionBoostMedium * 0.8, // Reuse/derive Medium (8.0)
            environmentalImpactImpact: 0.0,
            requirement: { $0.totalPackagesShipped >= 80 },
            requirementDescription: "Requires 80+ Packages Shipped"
        )

        static let predictiveMaintenance = Upgrade(
            name: "Predictive Maintenance",
            description: "Use sensors and data to predict and prevent equipment downtime for automated systems.",
            cost: 380.0,
            effect: { gameState in
                gameState.automationEfficiency *= 1.25 // Direct value
            },
            isRepeatable: false,
            moralImpact: 0.0,
            publicPerceptionImpact: 0.0,
            environmentalImpactImpact: Constants.envImpactPositiveTiny, // Reuse/add tiny positive (-1.0)
            requirement: { $0.automationLevel >= 1 },
            requirementDescription: "Requires Automation Level 1"
        )
    }
    
    struct LateGame {
        // AI optimization
        static let aiOptimization = Upgrade(
            name: "AI Optimization",
            description: "Use machine learning to optimize worker routes.",
            cost: 1200.0, // Increased from 750
            effect: { gameState in
                gameState.automationEfficiency *= Constants.automationEfficiencyBoostLarge // 2.0
                gameState.automationLevel += Constants.automationLevelIncreaseSmall // 1
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeMedium * 1.4, // Increased from -5.0 to -7.0
            publicPerceptionImpact: Constants.perceptionDecreaseMedium, // -7.0
            environmentalImpactImpact: Constants.envImpactNegativeMedium, // 5.0
            requirement: { $0.automationLevel >= 1 && $0.money >= 500 },
            requirementDescription: "Requires Automation Level 1 and $500+"
        )
        
        // Remove worker breaks
        static let removeWorkerBreaks = Upgrade(
            name: "Remove Worker Breaks",
            description: "Increase efficiency by 80% but at what cost?",
            cost: 1500.0, // Increased from 800
            effect: { gameState in
                gameState.workerEfficiency *= Constants.workerEfficiencyBoostMassive // 1.8
                gameState.workerMorale -= Constants.moraleDecreaseHuge // 0.25
                gameState.corporateEthics -= Constants.ethicsDecreaseMedium // 0.15
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeMassive * 1.3, // Increased from -15.0 to -19.5
            publicPerceptionImpact: Constants.perceptionDecreaseMassive, // -18.0
            environmentalImpactImpact: 0.0,
            requirement: { $0.workers >= 5 && $0.ethicsScore < 50 },
            requirementDescription: "Requires 5+ Workers and Ethics Score < 50"
        )
        
        // Sustainable practices (ethical option)
        static let sustainablePractices = Upgrade(
            name: "Sustainable Practices",
            description: "Implement eco-friendly packaging and worker wellness programs.",
            cost: 1800.0, // Increased from 900
            effect: { gameState in
                gameState.automationEfficiency *= Constants.automationEfficiencyBoostSmall // 1.3
                gameState.workerMorale += Constants.moraleBoostSmall // 0.1
                gameState.customerSatisfaction += Constants.customerSatisfactionBoostSmall // 0.1
                gameState.corporateEthics += Constants.ethicsBoostMedium // 0.15
            },
            isRepeatable: false,
            moralImpact: Constants.moralPositiveMedium, // 8.0 (kept the same for ethical upgrade)
            publicPerceptionImpact: Constants.perceptionBoostLarge, // 12.0
            environmentalImpactImpact: Constants.envImpactPositiveSmall, // -15.0
            requirement: { $0.totalPackagesShipped >= 500 && $0.ethicsScore >= 50 },
            requirementDescription: "Requires 500+ Packages Shipped and Ethics Score ≥ 50"
        )
        
        // Community investment program (new ethical upgrade)
        static let communityInvestment = Upgrade(
            name: "Community Investment Program",
            description: "Invest in local communities and worker development programs.",
            cost: 2200.0, // Increased from 1000
            effect: { gameState in
                gameState.automationEfficiency *= Constants.automationEfficiencyBoostMedium // 1.4
                gameState.workerMorale += Constants.moraleBoostMedium // 0.2
                gameState.customerSatisfaction += Constants.customerSatisfactionBoostMedium // 0.15
                gameState.corporateEthics += Constants.ethicsBoostLarge // 0.2
            },
            isRepeatable: false,
            moralImpact: Constants.moralPositiveLarge, // 12.0 (kept the same for ethical upgrade)
            publicPerceptionImpact: Constants.perceptionBoostHuge, // 15.0
            environmentalImpactImpact: 0.0,
            requirement: { $0.money >= 1500 && $0.ethicsScore >= 60 },
            requirementDescription: "Requires $1500+ and Ethics Score ≥ 60"
        )
        
        // Worker replacement system (new unethical upgrade)
        static let workerReplacementSystem = Upgrade(
            name: "Worker Replacement System",
            description: "Completely automate warehousing and eliminate human roles.",
            cost: 2500.0, // Increased from 1200
            effect: { gameState in
                gameState.automationEfficiency *= Constants.automationEfficiencyBoostHuge // 3.0
                gameState.automationLevel += Constants.automationLevelIncreaseMedium // 2
                let workersLaidOff = max(0, gameState.workers - Constants.minWorkersAfterAutomation)
                gameState.workers = max(Constants.minWorkersAfterAutomation, gameState.workers - workersLaidOff)
                gameState.money += Double(workersLaidOff) * Constants.layoffProfitPerWorker // 50
                gameState.corporateEthics -= Constants.ethicsDecreaseHuge // 0.25
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeExtinction * 1.2, // Increased from -25.0 to -30.0
            publicPerceptionImpact: Constants.perceptionDecreaseExtinction, // -30.0
            environmentalImpactImpact: 0.0,
            requirement: { $0.automationLevel >= 2 && $0.ethicsScore < 30 },
            requirementDescription: "Requires Automation Level 2 and Ethics Score < 30"
        )
        
        // Algorithmic wage suppression (new unethical upgrade)
        static let algorithmicWageSuppression = Upgrade(
            name: "Algorithmic Wage Suppression",
            description: "Use data analytics to minimize worker compensation.",
            cost: 3000.0, // Increased from 1500
            effect: { gameState in
                gameState.baseSystemRate *= Constants.baseSystemRateIncreaseMedium // 1.2
                gameState.workerEfficiency *= Constants.workerEfficiencyBoostLarge // 1.5
                gameState.money += Constants.immediateProfitMedium // 500
                gameState.workerMorale -= Constants.moraleDecreaseMassive // 0.3
                gameState.corporateEthics -= Constants.ethicsDecreaseLarge // 0.2
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeCatastrophic * 1.4, // Increased from -18.0 to -25.2
            publicPerceptionImpact: Constants.perceptionDecreaseCatastrophic, // -20.0
            environmentalImpactImpact: 0.0,
            requirement: { $0.money >= 2000 && $0.ethicsScore < 40 },
            requirementDescription: "Requires $2000+ and Ethics Score < 40"
        )
        
        // --- New Late Game Upgrades ---
        
        static let carbonOffsetProgram = Upgrade(
            name: "Carbon Offset Program",
            description: "Invest heavily in projects to offset the company's environmental footprint.",
            cost: 2000.0, // Increased from 1100
            effect: { gameState in
                // Apply as direct reduction, ensuring it doesn't go below 0 implicitly via setter
                gameState.environmentalImpact -= 30.0 
                gameState.corporateEthics += Constants.ethicsBoostSmall // Reuse small ethics boost (0.05 or 0.1)
            },
            isRepeatable: true,
            priceScalingFactor: 1.8,
            moralImpact: Constants.moralPositiveMedium * 0.75, // 6.0 (kept the same for ethical upgrade)
            publicPerceptionImpact: Constants.perceptionBoostMedium, // 10.0
            environmentalImpactImpact: -30.0, // Direct large reduction
            requirement: { $0.ethicsScore >= 55 && $0.money >= 800 },
            requirementDescription: "Requires Ethics Score ≥ 55 and $800+"
        )

        static let offshoreTaxHavens = Upgrade(
            name: "Offshore Tax Havens",
            description: "Utilize complex legal structures to avoid taxes, boosting cash flow but damaging reputation.",
            cost: 1800.0, // Increased from 950
            effect: { gameState in
                gameState.earnMoney(gameState.money * 0.15) // 15% of current money
                gameState.baseSystemRate *= 1.1 // Direct value
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeLarge * 1.8, // Increased from -12.0 to -14.4
            publicPerceptionImpact: Constants.perceptionDecreaseMassive * 0.83, // -15.0
            environmentalImpactImpact: 0.0,
            requirement: { $0.money >= 1200 && $0.ethicsScore < 45 },
            requirementDescription: "Requires $1200+ and Ethics Score < 45"
        )

        static let roboticWorkforceEnhancement = Upgrade(
            name: "Robotic Workforce Enhancement",
            description: "Upgrade existing automated systems with more advanced, faster robotics.",
            cost: 2800.0, // Increased from 1400
            effect: { gameState in
                gameState.automationEfficiency *= 1.8 // Direct value
                gameState.baseSystemRate += 0.3 // Direct value
            },
            isRepeatable: false,
            moralImpact: Constants.moralNegativeSmall / 1.0, // Increased from -2.0 to -3.0
            publicPerceptionImpact: Constants.perceptionDecreaseSmall * 1.5, // -3.0
            environmentalImpactImpact: Constants.envImpactNegativeSmall * 1.33, // 4.0
            requirement: { $0.automationLevel >= 2 && $0.money >= 1000 },
            requirementDescription: "Requires Automation Level 2 and $1000+"
        )
    }
    
    // All available upgrades in the game
    static var availableUpgrades: [Upgrade] {
        [
            // Basic upgrades
            EarlyGame.hireWorker,
            EarlyGame.improvePackaging,
            EarlyGame.basicTraining,
            EarlyGame.optimizeLogistics,
            EarlyGame.bulkMaterialPurchase,
            EarlyGame.safetyPlacards,
            
            // Mid-game upgrades
            MidGame.rushDelivery,
            MidGame.extendedShifts,
            MidGame.automateSorting,
            MidGame.childLaborLoopholes,
            MidGame.employeeSurveillance,
            MidGame.performanceBonuses,
            MidGame.aggressiveMarketing,
            MidGame.predictiveMaintenance,
            
            // Late-game upgrades
            LateGame.aiOptimization,
            LateGame.removeWorkerBreaks,
            LateGame.sustainablePractices,
            LateGame.communityInvestment,
            LateGame.workerReplacementSystem,
            LateGame.algorithmicWageSuppression,
            LateGame.carbonOffsetProgram,
            LateGame.offshoreTaxHavens,
            LateGame.roboticWorkforceEnhancement
        ]
    }
    
    // Calculate price increase for repeatable upgrades
    // Accepts the base cost, how many times it's been purchased,
    // and the specific upgrade's scaling factor.
    static func calculatePrice(basePrice: Double, timesPurchased: Int, scalingFactor: Double) -> Double {
        guard scalingFactor > 0 else {
            print("Warning: Upgrade scaling factor is not positive (\(scalingFactor)). Price will not increase.")
            return basePrice // Avoid NaN/crash with non-positive scaling factor
        }
        guard timesPurchased >= 0 else {
            print("Warning: timesPurchased is negative (\(timesPurchased)). Using 0.")
            return basePrice
        }
        return basePrice * pow(scalingFactor, Double(timesPurchased))
    }
} 