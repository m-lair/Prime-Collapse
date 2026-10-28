import Foundation

enum HolidayRushInsights {
    static func projectedPackages(game: GameState, remaining: Double) -> Int {
        guard remaining.isFinite, remaining > 0, game.automaticPackagesPerSecond.isFinite,
              game.packageAccumulator.isFinite else { return game.totalPackagesShipped }
        let estimate = Double(game.totalPackagesShipped)
            + floor(max(0, game.packageAccumulator + game.automaticPackagesPerSecond * remaining))
        return estimate >= Double(Int.max) ? Int.max : max(0, Int(estimate))
    }

    static func preview(_ upgrade: Upgrade, game: GameState) -> HolidayRushUpgradePreview? {
        guard game.isUpgradeUnlocked(upgrade), !game.isRunTerminal,
              upgrade.isRepeatable || !game.hasBeenPurchased(upgrade),
              upgrade.name != "Hire Worker" || game.workers < GameState.maxWorkers else { return nil }
        let cost = game.getCurrentUpgradeCost(upgrade)
        guard cost.isFinite, game.automaticPackagesPerSecond.isFinite, game.effectivePackageValue.isFinite else { return nil }
        let copy = GameState()
        copy.baseEndingsEnabled = false
        GameSnapshot(from: game).apply(to: copy)
        copy.lastUpdate = game.lastUpdate
        copy.money = max(game.money, cost)
        let fundedBalance = copy.money
        copy.applyUpgrade(upgrade)
        guard copy.automaticPackagesPerSecond.isFinite, copy.effectivePackageValue.isFinite else { return nil }
        return .init(automaticRateBefore: game.automaticPackagesPerSecond,
                     automaticRateAfter: copy.automaticPackagesPerSecond,
                     packageValueBefore: game.effectivePackageValue,
                     packageValueAfter: copy.effectivePackageValue,
                     netCost: fundedBalance - copy.money)
    }
}

extension HolidayRushResult {
    var averagePackagesPerSecond: Double {
        elapsed.isFinite && elapsed > 0 ? Double(packages) / elapsed : 0
    }

    var unmetRequirements: [String] {
        guard outcome != .success else { return [] }
        var requirements: [String] = []
        if packages < HolidayRushSession.packageGoal {
            requirements.append("\((HolidayRushSession.packageGoal - packages).formatted()) more packages needed.")
        }
        if ethics < HolidayRushSession.minimumEthics {
            requirements.append("Ethics needed to reach 40; finished at \(ethics.formatted(.number.precision(.fractionLength(0...1)))).")
        }
        if morale < HolidayRushSession.minimumMorale {
            requirements.append("Morale needed to reach 40%; finished at \((morale * 100).formatted(.number.precision(.fractionLength(0...1))))%.")
        }
        return requirements
    }

    var retryAdvice: String {
        if outcome == .success { return "Try another investment plan and compare your completion time." }
        let missedVolume = packages < HolidayRushSession.packageGoal
        let missedWorkforce = ethics < HolidayRushSession.minimumEthics || morale < HolidayRushSession.minimumMorale
        if missedVolume && missedWorkforce {
            return "Compare production gains early, and leave room to protect your workforce at each decision."
        }
        if missedWorkforce {
            return "The volume goal was reached. Protect your workforce with choices that keep ethics and morale at least 40."
        }
        return "Workforce goals met. Compare production gains before buying, and reserve cash for upcoming decisions."
    }
}
