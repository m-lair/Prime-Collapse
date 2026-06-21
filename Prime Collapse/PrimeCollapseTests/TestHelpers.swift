//
//  TestHelpers.swift
//  PrimeCollapseTests
//
//  Shared fixtures for the unit tests.
//

import Foundation
@testable import Prime_Collapse

enum TestHelpers {
    /// Create a fresh owned instance (new unique ID) of an upgrade template, mirroring how
    /// the game spawns repeatable-upgrade instances.
    static func instance(of template: Upgrade) -> Upgrade {
        Upgrade(
            id: UUID(),
            name: template.name,
            description: template.description,
            cost: template.cost,
            effect: template.effect,
            isRepeatable: template.isRepeatable,
            priceScalingFactor: template.priceScalingFactor,
            moralImpact: template.moralImpact,
            publicPerceptionImpact: template.publicPerceptionImpact,
            environmentalImpactImpact: template.environmentalImpactImpact,
            requirement: template.requirement,
            requirementDescription: template.requirementDescription
        )
    }

    /// A unique temp directory for save-file round-trip tests.
    static func makeTempDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrimeCollapseTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
