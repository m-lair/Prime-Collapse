//
//  P0RegressionTests.swift
//  PrimeCollapseTests
//
//  Regression tests for the P0 findings from the headless loop-sim validation
//  (docs/simulation/loop-analysis.md): package-counter overflow, the repeatable
//  pricing exploit, displayed-vs-charged price mismatch, and the worker-cap
//  money sink.
//

import XCTest
@testable import Prime_Collapse

final class P0RegressionTests: XCTestCase {

    // MARK: Finding #4 — package counter must saturate, not trap

    func testProcessAutomationSaturatesPackageCounter() {
        let gs = GameState()
        gs.totalPackagesShipped = Int.max - 5
        gs.packageAccumulator = 10.0
        gs.lastUpdate = Date(timeIntervalSinceNow: -1)

        gs.processAutomation(currentTime: Date())

        XCTAssertEqual(gs.totalPackagesShipped, Int.max)
    }

    func testShipPackageSaturatesAtIntMax() {
        let gs = GameState()
        gs.totalPackagesShipped = Int.max

        gs.shipPackage()

        XCTAssertEqual(gs.totalPackagesShipped, Int.max)
    }

    // MARK: Finding #3 — repeatable purchases must survive validateGameState

    func testValidateGameStatePreservesRepeatablePurchaseCounts() {
        let gs = GameState()
        let template = UpgradeManager.MidGame.performanceBonuses
        gs.purchasedUpgradeIDs = [template.id, template.id, template.id]

        gs.validateGameState()

        XCTAssertEqual(gs.purchasedUpgradeIDs.filter { $0 == template.id }.count, 3,
                       "repeatable purchase history must not be de-duplicated")
    }

    func testValidateGameStateStillDedupesNonRepeatables() {
        let gs = GameState()
        let template = UpgradeManager.EarlyGame.improvePackaging
        gs.purchasedUpgradeIDs = [template.id, template.id, template.id]

        gs.validateGameState()

        XCTAssertEqual(gs.purchasedUpgradeIDs.filter { $0 == template.id }.count, 1,
                       "non-repeatable duplicates are corruption and must be removed")
    }

    func testRepeatablePriceKeepsScalingAfterValidation() {
        let gs = GameState()
        let template = UpgradeManager.MidGame.performanceBonuses
        gs.purchasedUpgradeIDs = [template.id, template.id, template.id]

        gs.validateGameState()
        let price = gs.getCurrentUpgradeCost(template)

        // publicPerception defaults to 50 → neutral modifier, so the price must be
        // base * scalingFactor^3, matching three recorded purchases.
        let expected = gs.safeCalculatePrice(basePrice: template.cost,
                                             timesPurchased: 3,
                                             scalingFactor: template.priceScalingFactor)
        XCTAssertEqual(price, expected, accuracy: 0.01)
    }

    // MARK: Finding #6 — the charged price must equal the displayed price

    func testApplyUpgradeChargesDisplayedPrice() {
        let gs = GameState()
        // Two workers, consistent with two owned hire-worker upgrade instances,
        // to satisfy performanceBonuses' unlock requirement.
        for _ in 0..<2 {
            gs.upgrades.append(TestHelpers.instance(of: UpgradeManager.EarlyGame.hireWorker))
        }
        gs.workers = 2
        gs.money = 1000
        gs.publicPerception = 0 // worst perception → +50% price modifier in the UI

        let template = UpgradeManager.MidGame.performanceBonuses
        let displayed = gs.getCurrentUpgradeCost(template)
        gs.applyUpgrade(template)

        XCTAssertEqual(gs.money, 1000 - displayed, accuracy: 0.01,
                       "player must be charged exactly the price shown on the buy button")
    }

    // MARK: Finding #7 — worker purchases at the cap must be blocked, not charged

    func testWorkerPurchaseBlockedAtCap() {
        let gs = GameState()
        for _ in 0..<150 {
            gs.upgrades.append(TestHelpers.instance(of: UpgradeManager.EarlyGame.hireWorker))
        }
        gs.workers = 150
        gs.money = 2_000_000

        let before = gs.money
        gs.applyUpgrade(UpgradeManager.EarlyGame.hireWorker)

        XCTAssertEqual(gs.workers, 150, "worker count must not exceed the cap")
        XCTAssertEqual(gs.money, before, accuracy: 0.01,
                       "a blocked purchase must not deduct money")
    }

    // MARK: Finding #1 — Reform/Loop endings must actually end the game

    func testReformEndingFiresWhenCriteriaMet() {
        let gs = GameState()
        gs.ethicalChoicesMade = GameState.reformEthicalChoices
        gs.ethicsScore = GameState.reformEthicsScore
        gs.lifetimeTotalMoneyEarned = GameState.reformLifetimeEarnings

        gs.checkForReformEnding()

        XCTAssertEqual(gs.endingType, .reform)
        XCTAssertTrue(gs.endingReached, "meeting Reform criteria must end the game")
    }

    func testReformEndingFiresFromAutomationTick() {
        // Reform criteria can be completed by passive income (crossing the lifetime bar), so the
        // game loop itself must notice — not just upgrade purchases.
        let gs = GameState()
        gs.ethicalChoicesMade = GameState.reformEthicalChoices
        gs.ethicsScore = GameState.reformEthicsScore
        gs.lifetimeTotalMoneyEarned = GameState.reformLifetimeEarnings
        gs.lastUpdate = Date(timeIntervalSinceNow: -1)

        gs.processAutomation(currentTime: Date())

        XCTAssertTrue(gs.endingReached)
        XCTAssertEqual(gs.endingType, .reform)
    }

    func testReformEndingDoesNotFireDuringCollapse() {
        let gs = GameState()
        gs.isCollapsing = true
        gs.ethicalChoicesMade = GameState.reformEthicalChoices
        gs.ethicsScore = GameState.reformEthicsScore
        gs.lifetimeTotalMoneyEarned = GameState.reformLifetimeEarnings

        gs.checkForReformEnding()

        XCTAssertFalse(gs.endingReached)
        XCTAssertEqual(gs.endingType, .collapse)
    }

    // MARK: Finding #2 — surviving the Loop instability window completes the ending

    func testLoopEndingFiresAfterInstabilityWindow() {
        let gs = GameState()
        gs.isInLoopEndingState = true
        gs.loopEndingStartTime = Date(timeIntervalSinceNow: -61)
        gs.endingType = .loop
        gs.lastUpdate = Date(timeIntervalSinceNow: -1)

        gs.processAutomation(currentTime: Date())

        XCTAssertTrue(gs.endingReached, "surviving 60s of loop instability must end the game")
        XCTAssertEqual(gs.endingType, .loop)
    }

    func testResetClearsEndingReached() {
        let gs = GameState()
        gs.ethicalChoicesMade = GameState.reformEthicalChoices
        gs.ethicsScore = GameState.reformEthicsScore
        gs.lifetimeTotalMoneyEarned = GameState.reformLifetimeEarnings
        gs.checkForReformEnding()
        XCTAssertTrue(gs.endingReached)

        gs.reset()

        XCTAssertFalse(gs.endingReached)
    }

    // MARK: Finding #5 — fresh installs must start with a working idle economy

    func testFreshInstallSeedsStarterEconomy() {
        let dir = TestHelpers.makeTempDirectory()
        let gs = GameState()

        let saveManager = SaveManager(gameState: gs, directory: dir)

        XCTAssertTrue(saveManager.hasCompletedInitialLoad)
        XCTAssertEqual(gs.workers, 1, "a new game must start with the initial worker")
        XCTAssertEqual(gs.baseWorkerRate, 0.1, accuracy: 0.0001,
                       "a new game must have a non-zero worker rate so hiring pays off")
    }

    func testExistingSaveIsNotReseeded() throws {
        let dir = TestHelpers.makeTempDirectory()
        let original = GameState()
        // Workers are restored from the owned hire-worker instances, so the
        // fixture must be self-consistent.
        for _ in 0..<7 {
            original.upgrades.append(TestHelpers.instance(of: UpgradeManager.EarlyGame.hireWorker))
        }
        original.workers = 7
        original.money = 555
        original.totalPackagesShipped = 42
        try SaveFile.write(GameSnapshot(from: original), in: dir)

        let gs = GameState()
        _ = SaveManager(gameState: gs, directory: dir)

        XCTAssertEqual(gs.workers, 7, "loading a real save must not be overwritten by seeding")
        XCTAssertEqual(gs.totalPackagesShipped, 42)
    }

    func testRepeatablePriceScalingSurvivesSaveLoad() throws {
        let dir = TestHelpers.makeTempDirectory()
        let template = UpgradeManager.MidGame.performanceBonuses
        let original = GameState()
        original.totalPackagesShipped = 10
        original.purchasedUpgradeIDs = [template.id, template.id, template.id]
        for _ in 0..<3 {
            original.upgrades.append(TestHelpers.instance(of: template))
        }
        try SaveFile.write(GameSnapshot(from: original), in: dir)

        let restored = GameState()
        _ = SaveManager(gameState: restored, directory: dir)

        let expected = restored.safeCalculatePrice(basePrice: template.cost,
                                                   timesPurchased: 3,
                                                   scalingFactor: template.priceScalingFactor)
        XCTAssertEqual(restored.getCurrentUpgradeCost(template), expected, accuracy: 0.01,
                       "repeatable price ladder must not reset across save/load")
    }
}
