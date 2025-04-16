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
            sameDayDelivery,
            removeWorkerBreaks,
            aiOptimization,
            
            // New upgrades
            overnightShifts,
            robotsReplacementProgram,
            algorithmicPricing,
            taxAvoidanceScheme,
            lobbyingCampaign
        ]
    }
    
    // Basic worker upgrade
    static let hireWorker = Upgrade(
        name: "Hire Worker",
        description: "Hire a worker to ship packages automatically.",
        cost: 10.0,
        effect: { gameState in
            gameState.workers += 1
            gameState.automationRate += 0.1 // Each worker ships 0.1 packages per second
        },
        isRepeatable: true,
        moralImpact: 0.0 // Hiring workers is neutral morally
    )
    
    // Improve delivery speed
    static let sameDayDelivery = Upgrade(
        name: "Same Day Delivery",
        description: "Increase value of each package by promising faster delivery.",
        cost: 50.0,
        effect: { gameState in
            // Since we don't have a direct way to increase the value per package,
            // we'll simulate it by increasing the automation rate by 50%
            gameState.automationRate *= 1.5
        },
        isRepeatable: false,
        moralImpact: 2.0 // Slightly unethical due to increased worker pressure
    )
    
    // Remove worker breaks
    static let removeWorkerBreaks = Upgrade(
        name: "Remove Worker Breaks",
        description: "Increase efficiency by 25% but at what cost?",
        cost: 100.0,
        effect: { gameState in
            // Increase all worker efficiency by 25%
            gameState.automationRate *= 1.25
        },
        isRepeatable: false,
        moralImpact: 10.0 // Very unethical
    )
    
    // AI optimization
    static let aiOptimization = Upgrade(
        name: "AI Optimization",
        description: "Use machine learning to optimize worker routes.",
        cost: 200.0,
        effect: { gameState in
            // Double automation rate
            gameState.automationRate *= 2.0
        },
        isRepeatable: false,
        moralImpact: 5.0 // Moderately unethical due to worker surveillance
    )
    
    // Overnight shifts to increase production
    static let overnightShifts = Upgrade(
        name: "Overnight Shifts",
        description: "Keep the warehouse running 24/7.",
        cost: 75.0,
        effect: { gameState in
            // Increase automation rate by 40%
            gameState.automationRate *= 1.4
        },
        isRepeatable: false,
        moralImpact: 6.0 // Quite unethical - impacts worker health
    )
    
    // Replace workers with robots
    static let robotsReplacementProgram = Upgrade(
        name: "Robotic Workforce",
        description: "Replace human workers with tireless robots.",
        cost: 300.0,
        effect: { gameState in
            // Double automation and reduce worker count
            gameState.automationRate *= 2.0
            gameState.workers = max(0, gameState.workers - 5)
        },
        isRepeatable: false,
        moralImpact: 8.0 // Highly unethical - massive layoffs
    )
    
    // Algorithmic pricing to maximize profits
    static let algorithmicPricing = Upgrade(
        name: "Algorithmic Pricing",
        description: "Dynamically price packages for maximum profit.",
        cost: 150.0,
        effect: { gameState in
            // Each package is now worth 50% more
            // Instead of direct per-package value, we'll simulate by
            // giving a one-time cash bonus and small automation boost
            gameState.money += 100.0
            gameState.automationRate *= 1.2
        },
        isRepeatable: false,
        moralImpact: 4.0 // Somewhat unethical - price manipulation
    )
    
    // Tax avoidance scheme
    static let taxAvoidanceScheme = Upgrade(
        name: "Tax Optimization",
        description: "Employ creative accounting to reduce tax burden.",
        cost: 250.0,
        effect: { gameState in
            // Large one-time money bonus
            gameState.money += 500.0
        },
        isRepeatable: false,
        moralImpact: 7.0 // Highly unethical - potential legal issues
    )
    
    // Lobbying campaign to reduce regulations
    static let lobbyingCampaign = Upgrade(
        name: "Lobbying Campaign",
        description: "Influence politicians to remove regulatory constraints.",
        cost: 400.0,
        effect: { gameState in
            // Significant boost to automation efficiency
            gameState.automationRate *= 3.0
            // But also dramatically increases moral decay
            gameState.moralDecay += 15.0
        },
        isRepeatable: false,
        moralImpact: 12.0 // Extremely unethical - corruption
    )
} 