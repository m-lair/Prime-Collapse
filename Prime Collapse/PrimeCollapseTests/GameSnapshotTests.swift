//
//  GameSnapshotTests.swift
//  PrimeCollapseTests
//
//  Verifies the capture/restore round-trip of the JSON persistence model, including the
//  fields that the old SwiftData layer used to silently drop.
//

import XCTest
@testable import Prime_Collapse

final class GameSnapshotTests: XCTestCase {

    /// Build a populated game state with mixed repeatable + non-repeatable upgrades.
    private func makePopulatedState() -> GameState {
        let gs = GameState()
        gs.totalPackagesShipped = 2000
        gs.money = 5678.9
        gs.lifetimeTotalMoneyEarned = 99999.0
        gs.ethicsScore = 20.0
        gs.publicPerception = 73.0
        gs.environmentalImpact = 21.0
        gs.ethicalChoicesMade = 4
        gs.workers = 3

        // A purchased non-repeatable upgrade is tracked by template ID.
        gs.purchasedUpgradeIDs.append(UpgradeManager.EarlyGame.improvePackaging.id)

        // Three owned instances of a repeatable upgrade.
        for _ in 0..<3 {
            gs.upgrades.append(TestHelpers.instance(of: UpgradeManager.EarlyGame.hireWorker))
        }
        let start = Date(timeIntervalSince1970: 1_000_000)
        gs.lastUpdate = start
        gs.checkForLoopEnding()
        for second in 1...12 { gs.processAutomation(currentTime: start.addingTimeInterval(Double(second))) }
        return gs
    }

    func testRoundTripPreservesAllFields() {
        let source = makePopulatedState()
        let snapshot = GameSnapshot(from: source)

        let restored = GameState()
        snapshot.apply(to: restored)

        XCTAssertEqual(restored.totalPackagesShipped, 2000)
        XCTAssertEqual(restored.money, 5678.9, accuracy: 0.0001)
        XCTAssertEqual(restored.lifetimeTotalMoneyEarned, 99999.0, accuracy: 0.0001)
        XCTAssertEqual(restored.ethicsScore, 20.0, accuracy: 0.0001)
        XCTAssertEqual(restored.publicPerception, 73.0, accuracy: 0.0001)
        XCTAssertEqual(restored.environmentalImpact, 21.0, accuracy: 0.0001)
        XCTAssertEqual(restored.ethicalChoicesMade, 4)
        XCTAssertFalse(restored.endingReached)
        XCTAssertTrue(restored.isInLoopEndingState)
        XCTAssertNil(restored.loopEndingStartTime, "Wall-clock origin is not resumed across launches")
        XCTAssertEqual(restored.loopStabilitySeconds, 12)
        XCTAssertEqual(restored.workers, 3)
    }

    func testRoundTripRebuildsUpgrades() {
        let source = makePopulatedState()
        let snapshot = GameSnapshot(from: source)

        let restored = GameState()
        snapshot.apply(to: restored)

        // Repeatable instances are recreated by count.
        let workerCount = restored.upgrades.filter { $0.name == "Hire Worker" }.count
        XCTAssertEqual(workerCount, 3)

        // The purchased non-repeatable upgrade is reported as purchased.
        XCTAssertTrue(restored.hasBeenPurchased(UpgradeManager.EarlyGame.improvePackaging))
    }

    func testUnknownUpgradeNameIsSkippedSafely() {
        var snapshot = GameSnapshot(from: GameState())
        snapshot.purchasedUpgradeNames = ["A Nonexistent Upgrade"]
        snapshot.repeatableUpgradeCounts = ["Also Not Real": 5]

        let restored = GameState()
        // Should not crash; unknown names are simply ignored.
        snapshot.apply(to: restored)

        XCTAssertFalse(restored.upgrades.contains { $0.name == "Also Not Real" })
    }
}
