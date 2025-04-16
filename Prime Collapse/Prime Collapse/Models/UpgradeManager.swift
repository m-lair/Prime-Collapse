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
            gameState.automationRate += 0.1 // Each worker ships 0.1 packages per second
        },
        isRepeatable: true,
        moralImpact: 0.0 // Hiring workers is neutral morally
    )
    
    // Improve packaging efficiency
    static let improvePackaging = Upgrade(
        name: "Improve Packaging",
        description: "Streamline package handling for better efficiency.",
        cost: 75.0,
        effect: { gameState in
            gameState.automationRate *= 1.2 // 20% efficiency improvement
        },
        isRepeatable: false,
        moralImpact: 0.0 // Neutral ethical impact
    )
    
    // Basic training for workers
    static let basicTraining = Upgrade(
        name: "Basic Training",
        description: "Train workers for better performance and safety.",
        cost: 100.0,
        effect: { gameState in
            gameState.automationRate *= 1.15 // 15% efficiency boost
            gameState.moralDecay -= 2.0 // Small decrease in moral decay
        },
        isRepeatable: false,
        moralImpact: -3.0 // Positive ethical impact (negative moral decay)
    )
    
    // MID GAME UPGRADES
    // Rush delivery service
    static let rushDelivery = Upgrade(
        name: "Rush Delivery",
        description: "Promise faster delivery for premium prices.",
        cost: 250.0,
        effect: { gameState in
            gameState.automationRate *= 1.4 // 40% automation boost
        },
        isRepeatable: false,
        moralImpact: 3.0 // Slightly unethical - pressures workers
    )
    
    // Extended shifts for workers
    static let extendedShifts = Upgrade(
        name: "Extended Shifts",
        description: "Longer working hours for all employees.",
        cost: 300.0,
        effect: { gameState in
            gameState.automationRate *= 1.6 // 60% automation boost
        },
        isRepeatable: false,
        moralImpact: 8.0 // Highly unethical - work-life balance destruction
    )
    
    // Automate sorting process
    static let automateSorting = Upgrade(
        name: "Automate Sorting",
        description: "Install conveyor systems for package sorting.",
        cost: 350.0,
        effect: { gameState in
            gameState.automationRate *= 1.3 // 30% efficiency boost
        },
        isRepeatable: false,
        moralImpact: 1.0 // Nearly neutral - technology improvement
    )
    
    // Child labor loopholes (new unethical upgrade)
    static let childLaborLoopholes = Upgrade(
        name: "Child Labor Loopholes",
        description: "Exploit legal loopholes to hire underage workers for lower wages.",
        cost: 400.0,
        effect: { gameState in
            gameState.automationRate *= 2.0 // 100% automation boost
            gameState.money += 200 // Immediate profit from wage savings
        },
        isRepeatable: false,
        moralImpact: 20.0 // Severely unethical - exploiting children
    )
    
    // Employee surveillance (new unethical upgrade)
    static let employeeSurveillance = Upgrade(
        name: "Employee Surveillance",
        description: "Install monitoring systems to track worker productivity.",
        cost: 275.0,
        effect: { gameState in
            gameState.automationRate *= 1.5 // 50% automation boost
        },
        isRepeatable: false,
        moralImpact: 10.0 // Highly unethical - privacy violation
    )
    
    // LATE GAME UPGRADES
    // AI optimization
    static let aiOptimization = Upgrade(
        name: "AI Optimization",
        description: "Use machine learning to optimize worker routes.",
        cost: 750.0, // Increased from 200
        effect: { gameState in
            // Double automation rate
            gameState.automationRate *= 2.0
        },
        isRepeatable: false,
        moralImpact: 5.0 // Moderately unethical due to worker surveillance
    )
    
    // Remove worker breaks
    static let removeWorkerBreaks = Upgrade(
        name: "Remove Worker Breaks",
        description: "Increase efficiency by 80% but at what cost?",
        cost: 800.0, // Increased from 100
        effect: { gameState in
            // Increase all worker efficiency by 25%
            gameState.automationRate *= 1.8 // Increased from 1.25
        },
        isRepeatable: false,
        moralImpact: 15.0 // Very unethical (increased from 10)
    )
    
    // Sustainable practices (ethical option)
    static let sustainablePractices = Upgrade(
        name: "Sustainable Practices",
        description: "Implement eco-friendly packaging and worker wellness programs.",
        cost: 900.0,
        effect: { gameState in
            gameState.automationRate *= 1.3 // 30% automation boost
            gameState.moralDecay -= 5.0 // Reduces moral decay
        },
        isRepeatable: false,
        moralImpact: -8.0 // Highly ethical (negative moral impact)
    )
    
    // Community investment program (new ethical upgrade)
    static let communityInvestment = Upgrade(
        name: "Community Investment Program",
        description: "Invest in local communities and worker development programs.",
        cost: 1000.0,
        effect: { gameState in
            gameState.automationRate *= 1.4 // 40% automation boost
            gameState.moralDecay -= 10.0 // Significant reduction in moral decay
        },
        isRepeatable: false,
        moralImpact: -12.0 // Extremely ethical (large negative moral impact)
    )
    
    // Worker replacement system (new unethical upgrade)
    static let workerReplacementSystem = Upgrade(
        name: "Worker Replacement System",
        description: "Completely automate warehousing and eliminate human roles.",
        cost: 1200.0,
        effect: { gameState in
            gameState.automationRate *= 3.0 // 200% automation boost
            // Reduces worker count but maintains automation
            let workersLaidOff = max(0, gameState.workers - 2)
            gameState.workers = 2
            gameState.money += Double(workersLaidOff) * 50 // One-time profit from layoffs
        },
        isRepeatable: false,
        moralImpact: 25.0 // Extreme moral decay - mass unemployment
    )
    
    // Algorithmic wage suppression (new unethical upgrade)
    static let algorithmicWageSuppression = Upgrade(
        name: "Algorithmic Wage Suppression",
        description: "Use data analytics to minimize worker compensation.",
        cost: 1500.0,
        effect: { gameState in
            gameState.automationRate *= 1.7 // 70% automation boost
            gameState.money += 500 // Immediate profit from wage reduction
        },
        isRepeatable: false,
        moralImpact: 18.0 // Very unethical - manipulating wages
    )
} 