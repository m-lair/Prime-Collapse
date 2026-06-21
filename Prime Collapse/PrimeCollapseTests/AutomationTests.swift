//
//  AutomationTests.swift
//  PrimeCollapseTests
//
//  Deterministic checks on the automation accumulation and the catch-up cap.
//

import XCTest
@testable import Prime_Collapse

final class AutomationTests: XCTestCase {

    /// Configure a state whose multipliers all resolve to 1.0 so the package math is exact.
    private func makeNeutralState() -> GameState {
        let gs = GameState()
        gs.baseWorkerRate = 1.0
        gs.workers = 2
        gs.workerEfficiency = 1.0
        gs.workerMorale = 0.6           // between 0.5 and 0.7 -> moraleFactor 1.0
        gs.baseSystemRate = 0.0
        gs.automationEfficiency = 1.0
        gs.environmentalImpact = 0.0    // envPenaltyFactor 1.0
        gs.packageValue = 1.0
        gs.customerSatisfaction = 1.0   // satisfactionFactor 1.0
        gs.publicPerception = 50.0      // perceptionFactor 1.0
        gs.corporateEthics = 0.5        // no morale decay
        return gs
    }

    func testAccumulatesExpectedWholePackages() {
        let gs = makeNeutralState()
        let start = Date()
        gs.lastUpdate = start

        // rate = baseWorkerRate * workers = 1.0 * 2 = 2 pkg/s over 10s -> 20 packages.
        gs.processAutomation(currentTime: start.addingTimeInterval(10))

        XCTAssertEqual(gs.totalPackagesShipped, 20)
        XCTAssertEqual(gs.money, 20.0, accuracy: 0.0001)
        XCTAssertEqual(gs.packageAccumulator, 0.0, accuracy: 0.0001)
    }

    func testFractionalRemainderIsCarried() {
        let gs = makeNeutralState()
        let start = Date()
        gs.lastUpdate = start

        // 2 pkg/s over 10.25s -> 20.5 -> 20 shipped, 0.5 carried.
        gs.processAutomation(currentTime: start.addingTimeInterval(10.25))

        XCTAssertEqual(gs.totalPackagesShipped, 20)
        XCTAssertEqual(gs.packageAccumulator, 0.5, accuracy: 0.0001)
    }

    func testLongGapIsCappedAtCatchUpLimit() {
        let gs = makeNeutralState()
        gs.workers = 1                  // 1 pkg/s for an easy expected value
        let start = Date()
        gs.lastUpdate = start

        // A ~11-day gap should be capped at maxAutomationCatchUp (8h = 28800s).
        gs.processAutomation(currentTime: start.addingTimeInterval(1_000_000))

        XCTAssertEqual(gs.totalPackagesShipped, Int(GameState.maxAutomationCatchUp))
    }

    func testNonPositiveElapsedIsIgnored() {
        let gs = makeNeutralState()
        let start = Date()
        gs.lastUpdate = start

        // currentTime before lastUpdate -> no work done.
        gs.processAutomation(currentTime: start.addingTimeInterval(-100))

        XCTAssertEqual(gs.totalPackagesShipped, 0)
        XCTAssertEqual(gs.money, 0.0, accuracy: 0.0001)
    }
}
