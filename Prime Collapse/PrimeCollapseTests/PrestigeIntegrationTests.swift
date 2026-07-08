//
//  PrestigeIntegrationTests.swift
//  PrimeCollapseTests
//
//  Prestige perks apply as permanent starting-condition bonuses when a new run begins
//  (GameState.reset), and a completed run banks points into the carried prestige.
//

import XCTest
@testable import Prime_Collapse

final class PrestigeIntegrationTests: XCTestCase {

    private func stateWithPerks() -> PrestigeState {
        var p = PrestigeState()
        p.points = 100_000
        _ = p.purchase(.efficientOperations) // +10% rate
        _ = p.purchase(.efficientOperations) // +10% rate  → x1.2
        _ = p.purchase(.seedCapital)          // +$50
        _ = p.purchase(.foundingTeam)         // +1 worker
        _ = p.purchase(.foundingTeam)         // +1 worker  → +2
        _ = p.purchase(.ethicalReputation)    // +5 perception
        return p
    }

    func testResetAppliesPrestigeStartingBonuses() {
        let gs = GameState()
        gs.prestige = stateWithPerks()

        gs.reset()

        XCTAssertEqual(gs.money, 50, accuracy: 0.01)                 // seed capital
        XCTAssertEqual(gs.workers, 3)                                 // 1 base + 2 founding team
        XCTAssertEqual(gs.baseWorkerRate, 0.1 * 1.2, accuracy: 0.0001) // efficient operations
        XCTAssertEqual(gs.publicPerception, 55, accuracy: 0.01)      // 50 base + 5 reputation
    }

    func testResetKeepsWorkerUpgradeInstancesConsistentWithBonus() {
        let gs = GameState()
        gs.prestige = stateWithPerks() // +2 founding-team workers

        gs.reset()

        // validateGameState reconciles workers to the number of owned Hire Worker
        // instances — so the bonus workers must each have a matching upgrade instance.
        gs.validateGameState()
        XCTAssertEqual(gs.workers, 3)
        XCTAssertEqual(gs.upgrades.filter { $0.name == "Hire Worker" }.count, 3)
    }

    func testResetWithNoPrestigeIsUnchanged() {
        let gs = GameState()
        gs.reset()

        XCTAssertEqual(gs.money, 0, accuracy: 0.01)
        XCTAssertEqual(gs.workers, 1)
        XCTAssertEqual(gs.baseWorkerRate, 0.1, accuracy: 0.0001)
        XCTAssertEqual(gs.publicPerception, 50, accuracy: 0.01)
    }

    func testConcludeRunBanksPointsFromLifetimeEarnings() {
        let gs = GameState()
        gs.lifetimeTotalMoneyEarned = 100_000
        gs.endingType = .reform

        let awarded = gs.concludeRun()

        XCTAssertEqual(awarded, 15)               // 10 * 1.5 reform
        XCTAssertEqual(gs.prestige.points, 15)
    }

    func testConcludeRunIsIdempotentPerRun() {
        let gs = GameState()
        gs.lifetimeTotalMoneyEarned = 100_000
        gs.endingType = .collapse

        let first = gs.concludeRun()
        let second = gs.concludeRun()

        XCTAssertEqual(first, 10)
        XCTAssertEqual(second, 0, "a run's prestige must only be banked once")
        XCTAssertEqual(gs.prestige.points, 10)
    }

    func testResetClearsRunConcludedFlag() {
        let gs = GameState()
        gs.lifetimeTotalMoneyEarned = 100_000
        gs.endingType = .collapse
        _ = gs.concludeRun()

        gs.reset()
        gs.lifetimeTotalMoneyEarned = 100_000
        gs.endingType = .collapse
        let awarded = gs.concludeRun()

        XCTAssertEqual(awarded, 10, "a fresh run can bank prestige again")
    }
}
