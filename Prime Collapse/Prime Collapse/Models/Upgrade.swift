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
    let cost: Double
    
    // Note: Since GameState is a class with @Observable, we can
    // mutate it even without using 'inout'
    let effect: (GameState) -> Void
    
    let isRepeatable: Bool
    let moralImpact: Double // How much this affects moral decay (0-10 scale)
    
    // Constructor with default values
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        cost: Double,
        effect: @escaping (GameState) -> Void,
        isRepeatable: Bool = false,
        moralImpact: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.cost = cost
        self.effect = effect
        self.isRepeatable = isRepeatable
        self.moralImpact = moralImpact
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Upgrade, rhs: Upgrade) -> Bool {
        lhs.id == rhs.id
    }
} 