//
//  PrestigeStateTests.swift
//  PrimeCollapseTests
//
//  Prestige ("New Game+") core model: points earned from a completed run, a perk
//  catalog with escalating costs, and the permanent starting-condition bonuses the
//  perks grant. All pure logic — no game/engine coupling.
//

import XCTest
@testable import Prime_Collapse

final class PrestigeStateTests: XCTestCase {

    // MARK: Points awarded from a run

    func testPointsScaleWithLifetimeMoneyWithDiminishingReturns() {
        // base = floor(sqrt(lifetimeMoney / 1000)); collapse multiplier is 1.0.
        // sqrt(100_000/1000) = sqrt(100) = 10.
        let points = PrestigeState.pointsAwarded(lifetimeMoney: 100_000, ending: .collapse)
        XCTAssertEqual(points, 10)
    }

    func testGoodEndingsAwardMorePoints() {
        let collapse = PrestigeState.pointsAwarded(lifetimeMoney: 100_000, ending: .collapse)
        let reform = PrestigeState.pointsAwarded(lifetimeMoney: 100_000, ending: .reform)
        let loop = PrestigeState.pointsAwarded(lifetimeMoney: 100_000, ending: .loop)

        XCTAssertEqual(reform, 15)  // 10 * 1.5
        XCTAssertEqual(loop, 20)    // 10 * 2.0
        XCTAssertGreaterThan(reform, collapse)
        XCTAssertGreaterThan(loop, reform)
    }

    func testTinyRunAwardsZeroPoints() {
        XCTAssertEqual(PrestigeState.pointsAwarded(lifetimeMoney: 500, ending: .collapse), 0)
    }

    func testNonFiniteMoneyAwardsZeroPoints() {
        XCTAssertEqual(PrestigeState.pointsAwarded(lifetimeMoney: .nan, ending: .reform), 0)
        XCTAssertEqual(PrestigeState.pointsAwarded(lifetimeMoney: .infinity, ending: .reform), 0)
        XCTAssertEqual(PrestigeState.pointsAwarded(lifetimeMoney: -1000, ending: .reform), 0)
    }

    // MARK: Perk purchasing

    func testPerkCostEscalatesGeometrically() {
        // cost(level) = baseCost * 2^level
        var state = PrestigeState()
        let base = PrestigePerk.efficientOperations.baseCost
        XCTAssertEqual(state.cost(of: .efficientOperations), base)          // level 0
        state.points = 1000
        _ = state.purchase(.efficientOperations)
        XCTAssertEqual(state.cost(of: .efficientOperations), base * 2)      // level 1
        _ = state.purchase(.efficientOperations)
        XCTAssertEqual(state.cost(of: .efficientOperations), base * 4)      // level 2
    }

    func testPurchaseDeductsPointsAndRaisesLevel() {
        var state = PrestigeState()
        state.points = 100
        let cost = state.cost(of: .seedCapital)

        let ok = state.purchase(.seedCapital)

        XCTAssertTrue(ok)
        XCTAssertEqual(state.points, 100 - cost)
        XCTAssertEqual(state.level(of: .seedCapital), 1)
    }

    func testPurchaseFailsWhenUnaffordable() {
        var state = PrestigeState()
        state.points = 0

        let ok = state.purchase(.efficientOperations)

        XCTAssertFalse(ok)
        XCTAssertEqual(state.level(of: .efficientOperations), 0)
        XCTAssertEqual(state.points, 0)
    }

    func testAwardAddsToBankedPoints() {
        var state = PrestigeState()
        state.points = 5
        state.award(10)
        XCTAssertEqual(state.points, 15)
    }

    // MARK: Perk effects (permanent starting bonuses)

    func testDefaultStateGrantsNoBonuses() {
        let state = PrestigeState()
        XCTAssertEqual(state.productionMultiplier, 1.0, accuracy: 0.0001)
        XCTAssertEqual(state.startingCash, 0, accuracy: 0.0001)
        XCTAssertEqual(state.startingWorkerBonus, 0)
        XCTAssertEqual(state.startingPerceptionBonus, 0, accuracy: 0.0001)
    }

    func testPerkEffectsScaleWithLevel() {
        var state = PrestigeState()
        state.points = 100_000
        _ = state.purchase(.efficientOperations) // +10% production per level
        _ = state.purchase(.efficientOperations)
        _ = state.purchase(.seedCapital)          // +$50 per level
        _ = state.purchase(.foundingTeam)         // +1 worker per level
        _ = state.purchase(.ethicalReputation)    // +5 perception per level

        XCTAssertEqual(state.productionMultiplier, 1.20, accuracy: 0.0001)
        XCTAssertEqual(state.startingCash, 50, accuracy: 0.0001)
        XCTAssertEqual(state.startingWorkerBonus, 1)
        XCTAssertEqual(state.startingPerceptionBonus, 5, accuracy: 0.0001)
    }
}
