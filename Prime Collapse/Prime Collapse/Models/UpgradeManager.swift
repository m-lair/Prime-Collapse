//
//  UpgradeManager.swift
//  Prime Collapse
//
//  Created on 4/15/25.
//

import Foundation

struct UpgradeManager {
    // All available upgrades in the game
    static var availableUpgrades: [Upgrade] {
        [
            // Basic upgrades
            hireWorker,
            improvePackaging,
            basicTraining,
            
            // Mid-game upgrades
            rushDelivery,
            extendedShifts,
            automateSorting,
            childLaborLoopholes,
            employeeSurveillance,
            
            // Late-game upgrades
            aiOptimization,
            removeWorkerBreaks,
            sustainablePractices,
            communityInvestment,
            workerReplacementSystem,
            algorithmicWageSuppression
        ]
    }
    
    // Calculate price increase for repeatable upgrades
    static func calculatePrice(basePrice: Double, timesPurchased: Int, upgradeName: String = "") -> Double {
        // Use a lower multiplier (40% instead of 60%) for the Hire Worker upgrade
        if upgradeName == "Hire Worker" {
            return basePrice * pow(1.4, Double(timesPurchased))
        }
        
        // Default: 60% increase per purchase for other upgrades
        return basePrice * pow(1.6, Double(timesPurchased))
    }
    
    // EARLY GAME UPGRADES
    // Basic worker upgrade
    static let hireWorker = Upgrade(
        name: "Hire Worker",
        description: "Hire a worker to ship packages automatically.",
        cost: 50.0, // Increased from 10
        effect: { gameState in
            gameState.workers += 1
            // gameState.automationRate += 0.1 // REMOVED - Handled by baseWorkerRate
        },
        isRepeatable: true,
        moralImpact: 0.0, // Hiring workers is neutral morally
        publicPerceptionImpact: 0.0,
        environmentalImpactImpact: 0.0
    )
    
    // Improve packaging efficiency
    static let improvePackaging = Upgrade(
        name: "Improve Packaging",
        description: "Streamline package handling for better efficiency.",
        cost: 75.0,
        effect: { gameState in
            gameState.workerEfficiency *= 1.2 // 20% worker efficiency improvement
            gameState.packageValue *= 1.1 // 10% increase in package value
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
            gameState.workerEfficiency *= 1.15 // 15% efficiency boost
            gameState.workerMorale += 0.1 // Improve worker morale
            gameState.corporateEthics += 0.05 // Slight improvement in corporate ethics
        },
        isRepeatable: false,
        moralImpact: 3.0, // Positive ethical impact
        publicPerceptionImpact: 2.0,
        environmentalImpactImpact: 0.0
    )
    
    // MID GAME UPGRADES
    // Rush delivery service
    static let rushDelivery = Upgrade(
        name: "Rush Delivery",
        description: "Promise faster delivery for premium prices.",
        cost: 250.0,
        effect: { gameState in
            gameState.automationEfficiency *= 1.4 // 40% automation boost
            gameState.packageValue *= 1.3 // 30% more value per package
            gameState.workerMorale -= 0.05 // Slight decrease in morale due to pressure
        },
        isRepeatable: false,
        moralImpact: -3.0, // Slightly unethical - pressures workers
        publicPerceptionImpact: 10.0,
        environmentalImpactImpact: 5.0
    )
    
    // Extended shifts for workers
    static let extendedShifts = Upgrade(
        name: "Extended Shifts",
        description: "Longer working hours for all employees.",
        cost: 300.0,
        effect: { gameState in
            // gameState.automationRate *= 1.6 // REMOVED - Affect worker efficiency instead
            gameState.workerEfficiency *= 1.6 // Affects worker output directly
            gameState.workerMorale -= 0.15 // Significant decrease in worker morale
            gameState.corporateEthics -= 0.1 // Decrease in ethics
        },
        isRepeatable: false,
        moralImpact: -8.0, // Highly unethical - work-life balance destruction
        publicPerceptionImpact: -10.0,
        environmentalImpactImpact: 0.0
    )
    
    // Automate sorting process
    static let automateSorting = Upgrade(
        name: "Automate Sorting",
        description: "Install conveyor systems for package sorting.",
        cost: 350.0,
        effect: { gameState in
            // gameState.automationEfficiency *= 1.3 // REMOVED - Increase base system rate instead
            gameState.baseSystemRate += 0.5 // Increase base rate from non-worker systems
            gameState.automationLevel += 1 // Increase automation level
        },
        isRepeatable: false,
        moralImpact: -1.0, // Slightly unethical - potential job displacement later
        publicPerceptionImpact: -2.0,
        environmentalImpactImpact: 3.0
    )
    
    // Child labor loopholes (new unethical upgrade)
    static let childLaborLoopholes = Upgrade(
        name: "Child Labor Loopholes",
        description: "Exploit legal loopholes to hire underage workers for lower wages.",
        cost: 400.0,
        effect: { gameState in
            // gameState.automationRate *= 2.0 // REMOVED - Affect worker efficiency instead
            gameState.workerEfficiency *= 2.0 // Make existing workforce seem more productive (or reflects cheap labor boost)
            gameState.money += 200 // Immediate profit from wage savings
            gameState.corporateEthics -= 0.2 // Major decrease in corporate ethics
            gameState.workerMorale -= 0.2 // Major decrease in worker morale
        },
        isRepeatable: false,
        moralImpact: -20.0, // Severely unethical - exploiting children
        publicPerceptionImpact: -25.0,
        environmentalImpactImpact: 0.0
    )
    
    // Employee surveillance (new unethical upgrade)
    static let employeeSurveillance = Upgrade(
        name: "Employee Surveillance",
        description: "Install monitoring systems to track worker productivity.",
        cost: 275.0,
        effect: { gameState in
            gameState.workerEfficiency *= 1.5 // 50% worker efficiency boost
            gameState.workerMorale -= 0.1 // Decrease in worker morale
            gameState.corporateEthics -= 0.1 // Decrease in ethics
        },
        isRepeatable: false,
        moralImpact: -10.0, // Highly unethical - privacy violation
        publicPerceptionImpact: -12.0,
        environmentalImpactImpact: 0.0
    )
    
    // LATE GAME UPGRADES
    // AI optimization
    static let aiOptimization = Upgrade(
        name: "AI Optimization",
        description: "Use machine learning to optimize worker routes.",
        cost: 750.0, // Increased from 200
        effect: { gameState in
            // Double automation efficiency
            gameState.automationEfficiency *= 2.0
            gameState.automationLevel += 1 // Increase automation level
        },
        isRepeatable: false,
        moralImpact: -5.0, // Moderately unethical due to worker surveillance implications
        publicPerceptionImpact: -7.0,
        environmentalImpactImpact: 5.0
    )
    
    // Remove worker breaks
    static let removeWorkerBreaks = Upgrade(
        name: "Remove Worker Breaks",
        description: "Increase efficiency by 80% but at what cost?",
        cost: 800.0, // Increased from 100
        effect: { gameState in
            // Increase worker efficiency by 80%
            gameState.workerEfficiency *= 1.8 // Increased from 1.25 - This is correct
            gameState.workerMorale -= 0.25 // Significant decrease in morale
            gameState.corporateEthics -= 0.15 // Significant decrease in ethics
        },
        isRepeatable: false,
        moralImpact: -15.0, // Very unethical
        publicPerceptionImpact: -18.0,
        environmentalImpactImpact: 0.0
    )
    
    // Sustainable practices (ethical option)
    static let sustainablePractices = Upgrade(
        name: "Sustainable Practices",
        description: "Implement eco-friendly packaging and worker wellness programs.",
        cost: 900.0,
        effect: { gameState in
            gameState.automationEfficiency *= 1.3 // 30% automation boost
            gameState.workerMorale += 0.1 // Improved worker morale
            gameState.customerSatisfaction += 0.1 // Improved customer satisfaction
            gameState.corporateEthics += 0.15 // Improved corporate ethics
        },
        isRepeatable: false,
        moralImpact: 8.0, // Highly ethical
        publicPerceptionImpact: 12.0,
        environmentalImpactImpact: -15.0
    )
    
    // Community investment program (new ethical upgrade)
    static let communityInvestment = Upgrade(
        name: "Community Investment Program",
        description: "Invest in local communities and worker development programs.",
        cost: 1000.0,
        effect: { gameState in
            gameState.automationEfficiency *= 1.4 // 40% automation boost
            gameState.workerMorale += 0.2 // Major increase in worker morale
            gameState.customerSatisfaction += 0.15 // Significant improvement in customer satisfaction
            gameState.corporateEthics += 0.2 // Major improvement in corporate ethics
        },
        isRepeatable: false,
        moralImpact: 12.0, // Extremely ethical
        publicPerceptionImpact: 15.0,
        environmentalImpactImpact: 0.0
    )
    
    // Worker replacement system (new unethical upgrade)
    static let workerReplacementSystem = Upgrade(
        name: "Worker Replacement System",
        description: "Completely automate warehousing and eliminate human roles.",
        cost: 1200.0,
        effect: { gameState in
            gameState.automationEfficiency *= 3.0 // This correctly boosts system efficiency
            gameState.automationLevel += 2 // Major increase in automation level
            // Reduces worker count but maintains automation
            let workersLaidOff = max(0, gameState.workers - 2)
            gameState.workers = 2
            gameState.money += Double(workersLaidOff) * 50 // One-time profit from layoffs
            gameState.corporateEthics -= 0.25 // Major decrease in ethics
        },
        isRepeatable: false,
        moralImpact: -25.0, // Extreme moral decay - mass unemployment
        publicPerceptionImpact: -30.0,
        environmentalImpactImpact: 0.0
    )
    
    // Algorithmic wage suppression (new unethical upgrade)
    static let algorithmicWageSuppression = Upgrade(
        name: "Algorithmic Wage Suppression",
        description: "Use data analytics to minimize worker compensation.",
        cost: 1500.0,
        effect: { gameState in
            // gameState.automationRate *= 1.2 // REMOVED - Boost base system rate instead
            gameState.baseSystemRate *= 1.2 // Reflects system-level optimization for profit
            gameState.workerEfficiency *= 1.5 // 50% efficiency boost (e.g., squeezing more from remaining workers)
            gameState.money += 500 // Immediate profit from wage reduction
            gameState.workerMorale -= 0.3 // Major decrease in worker morale
            gameState.corporateEthics -= 0.2 // Major decrease in ethics
        },
        isRepeatable: false,
        moralImpact: -18.0, // Very unethical - manipulating wages
        publicPerceptionImpact: -20.0,
        environmentalImpactImpact: 0.0
    )
} 