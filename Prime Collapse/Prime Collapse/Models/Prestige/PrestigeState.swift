//
//  PrestigeState.swift
//  Prime Collapse
//
//  "New Game+" meta-progression. Finishing a run (any ending) banks prestige points
//  based on lifetime earnings; points buy permanent perks that give the next run a
//  head start. Prestige persists across game resets (see PrestigeStore) and is applied
//  as starting-condition bonuses in GameState.reset() — it never touches the per-tick
//  income math.
//

import Foundation

/// A permanent, repeatable upgrade bought with prestige points.
enum PrestigePerk: String, CaseIterable, Codable {
    case efficientOperations   // faster starting automation
    case seedCapital           // starting cash
    case foundingTeam          // extra starting workers
    case ethicalReputation     // higher starting public perception

    var displayName: String {
        switch self {
        case .efficientOperations: return "Efficient Operations"
        case .seedCapital:         return "Seed Capital"
        case .foundingTeam:        return "Founding Team"
        case .ethicalReputation:   return "Ethical Reputation"
        }
    }

    var detail: String {
        switch self {
        case .efficientOperations: return "+10% starting automation rate per level."
        case .seedCapital:         return "+$50 starting cash per level."
        case .foundingTeam:        return "+1 starting worker per level."
        case .ethicalReputation:   return "+5 starting public perception per level."
        }
    }

    var icon: String {
        switch self {
        case .efficientOperations: return "gearshape.2.fill"
        case .seedCapital:         return "dollarsign.circle.fill"
        case .foundingTeam:        return "person.3.fill"
        case .ethicalReputation:   return "hand.thumbsup.fill"
        }
    }

    /// Cost of the first level; each subsequent level doubles (see `PrestigeState.cost`).
    var baseCost: Int {
        switch self {
        case .efficientOperations: return 3
        case .seedCapital:         return 2
        case .foundingTeam:        return 5
        case .ethicalReputation:   return 4
        }
    }
}

/// Banked prestige points plus the levels bought in each perk. Value type; pure logic.
struct PrestigeState: Codable, Equatable {
    var points: Int = 0
    private var perkLevels: [PrestigePerk: Int] = [:]

    // MARK: Points earned from a completed run

    /// Points banked when a run ends. Scales with lifetime earnings (diminishing
    /// returns via sqrt) and rewards the harder-to-reach endings.
    static func pointsAwarded(lifetimeMoney: Double, ending: GameEnding) -> Int {
        guard lifetimeMoney.isFinite, lifetimeMoney > 0 else { return 0 }
        let base = (lifetimeMoney / 1000).squareRoot()
        guard base.isFinite else { return 0 }
        let multiplier: Double
        switch ending {
        case .collapse: multiplier = 1.0
        case .reform:   multiplier = 1.5
        case .loop:     multiplier = 2.0
        }
        return Int((base * multiplier).rounded(.down))
    }

    mutating func award(_ earned: Int) {
        guard earned > 0 else { return }
        points += earned
    }

    // MARK: Perk queries & purchasing

    func level(of perk: PrestigePerk) -> Int {
        perkLevels[perk] ?? 0
    }

    /// Cost of the *next* level of `perk`: baseCost × 2^currentLevel.
    func cost(of perk: PrestigePerk) -> Int {
        let level = level(of: perk)
        // Guard against overflow at absurd levels; the practical ceiling is far lower.
        let factor = level >= 30 ? Int.max : (1 << level)
        let (product, overflow) = perk.baseCost.multipliedReportingOverflow(by: factor)
        return overflow ? Int.max : product
    }

    func canAfford(_ perk: PrestigePerk) -> Bool {
        points >= cost(of: perk)
    }

    /// Buy one level of `perk` if affordable. Returns whether the purchase happened.
    @discardableResult
    mutating func purchase(_ perk: PrestigePerk) -> Bool {
        let price = cost(of: perk)
        guard points >= price else { return false }
        points -= price
        perkLevels[perk, default: 0] += 1
        return true
    }

    // MARK: Perk effects — permanent starting bonuses

    /// Multiplier applied to the starting automation rate (1.0 = no bonus).
    var productionMultiplier: Double {
        1.0 + 0.10 * Double(level(of: .efficientOperations))
    }

    /// Extra cash a new run starts with.
    var startingCash: Double {
        50.0 * Double(level(of: .seedCapital))
    }

    /// Extra workers a new run starts with (on top of the default).
    var startingWorkerBonus: Int {
        level(of: .foundingTeam)
    }

    /// Extra starting public perception (0–100 scale).
    var startingPerceptionBonus: Double {
        5.0 * Double(level(of: .ethicalReputation))
    }
}
