//
//  Upgrade.swift
//  Prime Collapse
//
//  Created on 4/15/25.
//

import Foundation
import CryptoKit

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
    let requirementDescription: String? // Human-readable description of the requirement
    
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
        requirement: ((GameState) -> Bool)? = nil, // Default: no requirement
        requirementDescription: String? = nil // Default: no description
    ) {
        // For non-repeatable upgrades, generate a deterministic UUID based on the name
        // This ensures the same upgrade always has the same ID across app restarts
        if !isRepeatable && id == UUID() {  // Only if default ID was used
            // Create a deterministic UUID from the upgrade name
            let nameData = name.data(using: .utf8) ?? Data()
            let md5 = Insecure.MD5.hash(data: nameData)
            let md5String = md5.map { String(format: "%02hhx", $0) }.joined()
            
            // Convert the first 16 bytes to a UUID
            let uuid = UUID(uuidString: "\(md5String.prefix(8))-\(md5String.prefix(12).suffix(4))-\(md5String.prefix(16).suffix(4))-\(md5String.prefix(20).suffix(4))-\(md5String.suffix(12))") ?? UUID()
            self.id = uuid
            print("Created stable ID for \(name): \(uuid)")
        } else {
            self.id = id
        }
        
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
        self.requirementDescription = requirementDescription
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Upgrade, rhs: Upgrade) -> Bool {
        // For non-repeatable upgrades, compare by name
        if !lhs.isRepeatable && !rhs.isRepeatable {
            return lhs.name == rhs.name
        }
        // Otherwise, compare by ID
        return lhs.id == rhs.id
    }
} 