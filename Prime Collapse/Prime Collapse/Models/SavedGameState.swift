//
//  SavedGameState.swift
//  Prime Collapse
//
//  Created on 4/15/25.
//
//  Persistence model. The game keeps a single save "slot", so instead of a
//  relational store we serialize one Codable snapshot to a JSON file (see
//  SaveManager). Upgrades are keyed by their (unique, stable) name rather than
//  by UUID, which removes the fragile UUID round-tripping that previously caused
//  upgrades to silently disappear.
//

import Foundation

/// A flat, Codable snapshot of everything worth persisting about a game in progress.
struct GameSnapshot: Codable {
    // MARK: Metadata
    /// Bumped only when the on-disk format changes in a way that needs handling on load.
    var schemaVersion: Int = 1
    var savedAt: Date = Date()
    var appVersion: String = GameSnapshot.currentAppVersion

    // MARK: Core metrics
    var totalPackagesShipped: Int = 0
    var money: Double = 0.0
    var lifetimeTotalMoneyEarned: Double = 0.0
    var workers: Int = 0

    // MARK: Automation & efficiency
    var baseWorkerRate: Double = 0.1
    var baseSystemRate: Double = 0.0
    var packageAccumulator: Double = 0.0
    var workerEfficiency: Double = 1.0
    var workerMorale: Double = 0.8
    var customerSatisfaction: Double = 0.9
    var packageValue: Double = 1.0
    var automationEfficiency: Double = 1.0
    var automationLevel: Int = 0

    // MARK: Corporate metrics
    var corporateEthics: Double = 0.5
    var ethicsScore: Double = 100.0
    var publicPerception: Double = 50.0
    var environmentalImpact: Double = 0.0

    // MARK: Game progression
    var isCollapsing: Bool = false
    var ethicalChoicesMade: Int = 0
    var endingType: String = "collapse"
    var isInLoopEndingState: Bool = false
    var loopEndingStartTime: Date? = nil

    // MARK: Upgrades (keyed by stable upgrade name)
    /// Names of purchased non-repeatable upgrades.
    var purchasedUpgradeNames: [String] = []
    /// Name -> count for owned repeatable upgrades (e.g. "Hire Worker").
    var repeatableUpgradeCounts: [String: Int] = [:]

    // MARK: - Capture

    /// Build a snapshot from the live game state.
    init(from gameState: GameState) {
        totalPackagesShipped = gameState.totalPackagesShipped
        money = gameState.money
        lifetimeTotalMoneyEarned = gameState.lifetimeTotalMoneyEarned
        workers = gameState.workers

        baseWorkerRate = gameState.baseWorkerRate
        baseSystemRate = gameState.baseSystemRate
        packageAccumulator = gameState.packageAccumulator
        workerEfficiency = gameState.workerEfficiency
        workerMorale = gameState.workerMorale
        customerSatisfaction = gameState.customerSatisfaction
        packageValue = gameState.packageValue
        automationEfficiency = gameState.automationEfficiency
        automationLevel = gameState.automationLevel

        corporateEthics = gameState.corporateEthics
        ethicsScore = gameState.ethicsScore
        publicPerception = gameState.publicPerception
        environmentalImpact = gameState.environmentalImpact

        isCollapsing = gameState.isCollapsing
        ethicalChoicesMade = gameState.ethicalChoicesMade
        endingType = GameSnapshot.string(for: gameState.endingType)
        isInLoopEndingState = gameState.isInLoopEndingState
        loopEndingStartTime = gameState.loopEndingStartTime

        // Non-repeatable purchases: map purchased IDs back to their (unique) names.
        var purchasedNames = Set<String>()
        for id in gameState.purchasedUpgradeIDs {
            if let upgrade = UpgradeManager.availableUpgrades.first(where: { $0.id == id }),
               !upgrade.isRepeatable {
                purchasedNames.insert(upgrade.name)
            }
        }
        purchasedUpgradeNames = Array(purchasedNames).sorted()

        // Repeatable upgrades: count the owned instances by name.
        repeatableUpgradeCounts = Dictionary(grouping: gameState.upgrades, by: { $0.name })
            .mapValues { $0.count }
    }

    // MARK: - Restore

    /// Apply this snapshot to a live game state, rebuilding upgrades from names.
    func apply(to gameState: GameState) {
        gameState.totalPackagesShipped = totalPackagesShipped
        gameState.money = money
        gameState.lifetimeTotalMoneyEarned = lifetimeTotalMoneyEarned
        gameState.workers = workers

        gameState.baseWorkerRate = baseWorkerRate
        gameState.baseSystemRate = baseSystemRate
        gameState.packageAccumulator = packageAccumulator
        gameState.workerEfficiency = workerEfficiency
        gameState.workerMorale = workerMorale
        gameState.customerSatisfaction = customerSatisfaction
        gameState.packageValue = packageValue
        gameState.automationEfficiency = automationEfficiency
        gameState.automationLevel = automationLevel

        gameState.corporateEthics = corporateEthics
        gameState.ethicsScore = ethicsScore
        gameState.publicPerception = publicPerception
        gameState.environmentalImpact = environmentalImpact

        gameState.isCollapsing = isCollapsing
        gameState.ethicalChoicesMade = ethicalChoicesMade
        gameState.endingType = GameSnapshot.ending(for: endingType)
        gameState.isInLoopEndingState = isInLoopEndingState
        gameState.loopEndingStartTime = loopEndingStartTime
        gameState.lastUpdate = Date() // Always resume from "now".

        // Rebuild upgrade tracking from scratch so the restored state is self-consistent.
        gameState.upgrades.removeAll()
        gameState.purchasedUpgradeIDs.removeAll()

        // Non-repeatable purchases: re-add each template's (stable, per-session) ID.
        for name in purchasedUpgradeNames {
            if let template = UpgradeManager.availableUpgrades.first(where: { $0.name == name && !$0.isRepeatable }) {
                gameState.purchasedUpgradeIDs.append(template.id)
            }
            // Unknown names (e.g. an upgrade removed in a later build) are skipped safely.
        }

        // Repeatable upgrades: recreate `count` owned instances per name.
        for (name, count) in repeatableUpgradeCounts where count > 0 {
            guard let template = UpgradeManager.availableUpgrades.first(where: { $0.name == name && $0.isRepeatable }) else {
                continue
            }
            // Mark the repeatable as purchased (deduped) so hasBeenPurchased() reports true.
            gameState.purchasedUpgradeIDs.append(template.id)
            for _ in 0..<count {
                gameState.upgrades.append(GameSnapshot.instance(of: template))
            }
        }

        // Keep worker count aligned with the recreated "Hire Worker" instances.
        if let workerCount = repeatableUpgradeCounts[UpgradeManager.EarlyGame.hireWorker.name] {
            gameState.workers = workerCount
        }

        // Final clamp/consistency pass (caps excessive values, reconciles workers).
        gameState.validateGameState()
    }

    // MARK: - Helpers

    static var currentAppVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private static func string(for ending: GameEnding) -> String {
        switch ending {
        case .collapse: return "collapse"
        case .reform: return "reform"
        case .loop: return "loop"
        }
    }

    private static func ending(for string: String) -> GameEnding {
        switch string {
        case "reform": return .reform
        case "loop": return .loop
        default: return .collapse
        }
    }

    /// Create a fresh owned instance of a repeatable upgrade template (new unique ID).
    private static func instance(of template: Upgrade) -> Upgrade {
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
}
