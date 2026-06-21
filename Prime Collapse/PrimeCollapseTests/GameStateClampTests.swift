//
//  GameStateClampTests.swift
//  PrimeCollapseTests
//
//  Property clamps, data-integrity validation, and ending-threshold logic.
//

import XCTest
@testable import Prime_Collapse

final class GameStateClampTests: XCTestCase {

    func testMoneyClampsAndRejectsNonFinite() {
        let gs = GameState()

        gs.money = -100
        XCTAssertEqual(gs.money, 0)

        gs.money = 100
        gs.money = .infinity        // rejected, keeps previous
        XCTAssertEqual(gs.money, 100)

        gs.money = .nan             // rejected, keeps previous
        XCTAssertEqual(gs.money, 100)
    }

    func testBoundedMetricsClamp() {
        let gs = GameState()

        gs.ethicsScore = 999
        XCTAssertEqual(gs.ethicsScore, 100)
        gs.ethicsScore = -5
        XCTAssertEqual(gs.ethicsScore, 0)

        gs.workerMorale = 5
        XCTAssertEqual(gs.workerMorale, 1)
        gs.workerMorale = -1
        XCTAssertEqual(gs.workerMorale, 0)

        gs.publicPerception = 250
        XCTAssertEqual(gs.publicPerception, 100)
    }

    func testValidateCapsExcessiveWorkers() {
        let gs = GameState()
        for _ in 0..<200 {
            gs.upgrades.append(TestHelpers.instance(of: UpgradeManager.EarlyGame.hireWorker))
        }
        gs.workers = 200

        gs.validateGameState()

        XCTAssertEqual(gs.workers, 150)
        XCTAssertEqual(gs.upgrades.filter { $0.name == "Hire Worker" }.count, 150)
    }

    func testValidateDeduplicatesPurchasedIDs() {
        let gs = GameState()
        let id = UUID()
        gs.purchasedUpgradeIDs = [id, id, id]

        gs.validateGameState()

        XCTAssertEqual(gs.purchasedUpgradeIDs.filter { $0 == id }.count, 1)
    }

    func testReformEndingThreshold() {
        let gs = GameState()
        gs.ethicalChoicesMade = 5
        gs.ethicsScore = 60
        gs.money = 1500

        gs.checkForReformEnding()

        XCTAssertEqual(gs.endingType, .reform)
    }

    func testLoopEndingEntersAndExits() {
        let gs = GameState()
        gs.ethicsScore = 20
        gs.money = 3000
        gs.totalPackagesShipped = 2000
        gs.workers = 3

        gs.checkForLoopEnding()
        XCTAssertTrue(gs.isInLoopEndingState)
        XCTAssertEqual(gs.endingType, .loop)

        // Ethics recovers out of the loop band -> loop state clears.
        gs.ethicsScore = 80
        gs.checkForLoopEnding()
        XCTAssertFalse(gs.isInLoopEndingState)
    }
}
