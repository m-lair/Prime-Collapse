//
//  Upgrade.swift
//  Prime Collapse
//
//  Created on 4/15/25.
//

import Foundation

struct Upgrade: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let cost: Double // Base cost for repeatable upgrades
    
    // Note: Since GameState is a class with @Observable, we can
    // mutate it even without using 'inout'
    let effect: (GameState) -> Void
    
    let isRepeatable: Bool
    let priceScalingFactor: Double // Factor for price increase on repeatable upgrades
    let moralImpact: Double // Negative for unethical, positive for ethical
    let requirement: ((GameState) -> Bool)? // Condition to unlock the upgrade
    
    // New Step 13 Impacts
    let publicPerceptionImpact: Double
    let environmentalImpactImpact: Double
    
    // Constructor with default values
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        cost: Double,
        effect: @escaping (GameState) -> Void,
        isRepeatable: Bool = false,
        priceScalingFactor: Double = 1.6, // Default scaling factor
        moralImpact: Double = 0.0,
        publicPerceptionImpact: Double = 0.0, // Default impact
        environmentalImpactImpact: Double = 0.0, // Default impact
        requirement: ((GameState) -> Bool)? = nil // Default: no requirement
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.cost = cost
        self.effect = effect
        self.isRepeatable = isRepeatable
        self.priceScalingFactor = isRepeatable ? priceScalingFactor : 1.0 // Ensure non-repeatable don't scale
        self.moralImpact = moralImpact
        self.publicPerceptionImpact = publicPerceptionImpact
        self.environmentalImpactImpact = environmentalImpactImpact
        self.requirement = requirement
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Upgrade, rhs: Upgrade) -> Bool {
        lhs.id == rhs.id
    }
} 