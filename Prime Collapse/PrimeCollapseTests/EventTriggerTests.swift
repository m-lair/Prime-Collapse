//
//  EventTriggerTests.swift
//  PrimeCollapseTests
//
//  Guards the event-trigger probability, including the regression where integer division
//  disabled all random events for players under 1000 packages shipped.
//

import XCTest
@testable import Prime_Collapse

final class EventTriggerTests: XCTestCase {

    private let base = 0.02
    private let interval: TimeInterval = 120

    func testNoChanceBeforeMinimumInterval() {
        let chance = EventManager.eventTriggerChance(
            packagesShipped: 5000, timeSinceLastEvent: 60, baseChance: base, minInterval: interval
        )
        XCTAssertEqual(chance, 0)
    }

    func testEarlyGameStillTriggers() {
        // Regression: with the old `packages / 1000` integer division this was 0 below
        // 1000 packages, silently disabling events for new players.
        let chance = EventManager.eventTriggerChance(
            packagesShipped: 0, timeSinceLastEvent: interval, baseChance: base, minInterval: interval
        )
        XCTAssertGreaterThan(chance, 0)
        XCTAssertEqual(chance, 0.02, accuracy: 0.0001)
    }

    func testLateGameIncreasesChance() {
        let early = EventManager.eventTriggerChance(
            packagesShipped: 0, timeSinceLastEvent: interval, baseChance: base, minInterval: interval
        )
        let late = EventManager.eventTriggerChance(
            packagesShipped: 1500, timeSinceLastEvent: interval, baseChance: base, minInterval: interval
        )
        XCTAssertGreaterThan(late, early)
        XCTAssertEqual(late, 0.03, accuracy: 0.0001) // factor capped at 1.5
    }

    func testLateGameFactorIsCapped() {
        let late = EventManager.eventTriggerChance(
            packagesShipped: 9_999_999, timeSinceLastEvent: interval, baseChance: base, minInterval: interval
        )
        XCTAssertEqual(late, 0.03, accuracy: 0.0001) // still capped at 1.5x
    }

    func testChanceIsCappedAt15Percent() {
        let chance = EventManager.eventTriggerChance(
            packagesShipped: 0, timeSinceLastEvent: interval * 100, baseChance: base, minInterval: interval
        )
        XCTAssertEqual(chance, 0.15, accuracy: 0.0001)
    }
}
