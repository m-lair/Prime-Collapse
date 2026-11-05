import SwiftUI

// Round-number thresholds worth celebrating.
enum Milestone {
    static let lifetimeEarningsTiers: [Double] = [100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000, 100_000_000, 1_000_000_000]
    static let packageTiers: [Int] = [100, 1_000, 10_000, 100_000, 1_000_000]

    /// The highest tier passed when a value moves from `old` to `new`. Catch-up jumps celebrate only the top one.
    static func highestTierCrossed<T: Comparable>(in tiers: [T], old: T, new: T) -> T? {
        tiers.last { old < $0 && $0 <= new }
    }
}

extension GameNotification {
    static func earningsMilestone(_ amount: Double) -> GameNotification {
        GameNotification(
            title: "Milestone: $\(Int(amount).formatted(.number.notation(.compactName))) Earned",
            message: "Lifetime revenue has passed $\(Int(amount).formatted()). The board is pleased.",
            icon: "trophy.fill",
            color: .green,
            duration: 4.0
        )
    }

    static func packagesMilestone(_ count: Int) -> GameNotification {
        GameNotification(
            title: "Milestone: \(count.formatted(.number.notation(.compactName))) Packages",
            message: "\(count.formatted()) packages shipped this run. Throughput is up.",
            icon: "shippingbox.fill",
            color: .yellow,
            duration: 4.0
        )
    }
}
