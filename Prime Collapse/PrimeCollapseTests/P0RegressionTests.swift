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
        gs.ethicalChoicesMade = 5
        gs.ethicsScore = 60
        gs.money = 1500
        gs.lifetimeTotalMoneyEarned = 1500

        gs.checkForReformEnding()

        XCTAssertEqual(gs.endingType, .reform)
        XCTAssertTrue(gs.endingReached, "meeting Reform criteria must end the game")
    }

    func testReformEndingFiresFromAutomationTick() {
        // Reform criteria can be completed by passive income (crossing $1000), so the
        // game loop itself must notice — not just upgrade purchases.
        let gs = GameState()
        gs.ethicalChoicesMade = 5
        gs.ethicsScore = 60
        gs.money = 1500
        gs.lifetimeTotalMoneyEarned = 1500
        gs.lastUpdate = Date(timeIntervalSinceNow: -1)

        gs.processAutomation(currentTime: Date())

        XCTAssertTrue(gs.endingReached)
        XCTAssertEqual(gs.endingType, .reform)
    }

    func testReformEndingDoesNotFireDuringCollapse() {
        let gs = GameState()
        gs.isCollapsing = true
        gs.ethicalChoicesMade = 5
        gs.ethicsScore = 60
        gs.money = 1500
        gs.lifetimeTotalMoneyEarned = 1500

        gs.checkForReformEnding()

        XCTAssertFalse(gs.endingReached)
        XCTAssertEqual(gs.endingType, .collapse)
    }

    // MARK: Finding #2 — surviving the Loop instability window completes the ending

    func testLoopEndingFiresAfterInstabilityWindow() {
        let gs = GameState()
        gs.lifetimeTotalMoneyEarned = 2500
        gs.totalPackagesShipped = 1500
        gs.workers = 3
        gs.ethicsScore = 20
        let start = Date()
        gs.lastUpdate = start
        gs.checkForLoopEnding()
        for second in 1...60 {
            gs.processAutomation(currentTime: start.addingTimeInterval(Double(second)))
        }

        XCTAssertTrue(gs.endingReached, "surviving 60s of loop instability must end the game")
        XCTAssertEqual(gs.endingType, .loop)
    }

    func testReformUsesEarningsAfterSpending() {
        let gs = GameState()
        gs.lifetimeTotalMoneyEarned = 1000
        gs.money = 1
        gs.ethicalChoicesMade = 5
        gs.shipPackage()
        XCTAssertTrue(gs.endingReached)
    }

    func testLoopCannotCompleteAfterLeavingEthicsBand() {
        let gs = GameState()
        gs.lifetimeTotalMoneyEarned = 2500
        gs.money = 2500
        gs.totalPackagesShipped = 1500
        gs.workers = 3
        gs.ethicsScore = 20
        gs.checkForLoopEnding()
        gs.loopEndingStartTime = Date(timeIntervalSinceNow: -61)
        gs.ethicsScore = 80
        gs.lastUpdate = Date(timeIntervalSinceNow: -1)
        gs.processAutomation(currentTime: Date())
        XCTAssertFalse(gs.endingReached)
    }

    func testLoopProgressPersistsAndExcludesBackgroundCatchUp() throws {
        let gs = GameState()
        gs.reset()
        gs.applyUpgrade(UpgradeManager.EarlyGame.hireWorker)
        gs.workers = 3
        gs.upgrades = (0..<3).map { _ in TestHelpers.instance(of: UpgradeManager.EarlyGame.hireWorker) }
        gs.lifetimeTotalMoneyEarned = 2500
        gs.totalPackagesShipped = 1500
        gs.ethicsScore = 20
        let start = Date()
        gs.lastUpdate = start
        gs.checkForLoopEnding()
        for second in 1...30 { gs.processAutomation(currentTime: start.addingTimeInterval(Double(second))) }
        XCTAssertEqual(gs.loopStabilitySeconds, 30)
        let restored = GameState()
        let data = try JSONEncoder().encode(GameSnapshot(from: gs))
        try JSONDecoder().decode(GameSnapshot.self, from: data).apply(to: restored)
        XCTAssertEqual(restored.loopStabilitySeconds, 30)
        let resume = start.addingTimeInterval(3600)
        restored.resetForegroundTiming(currentTime: resume)
        restored.processAutomation(currentTime: resume)
        XCTAssertEqual(restored.loopStabilitySeconds, 30)
        XCTAssertFalse(restored.endingReached)
        restored.workers = 2
        restored.evaluateEndings()
        XCTAssertEqual(restored.loopStabilitySeconds, 0)
    }

    func testTerminalSavePreservesEndingAndBankingGuard() throws {
        let gs = GameState()
        gs.lifetimeTotalMoneyEarned = 1000
        gs.ethicalChoicesMade = 5
        gs.shipPackage()
        _ = gs.concludeRun()
        let restored = GameState()
        let data = try JSONEncoder().encode(GameSnapshot(from: gs))
        try JSONDecoder().decode(GameSnapshot.self, from: data).apply(to: restored)
        XCTAssertTrue(restored.endingReached)
        XCTAssertEqual(restored.endingType, .reform)
        XCTAssertEqual(restored.concludeRun(), 0)
        let packages = restored.totalPackagesShipped
        let cash = restored.money
        restored.shipPackage()
        restored.processAutomation(currentTime: Date().addingTimeInterval(30))
        restored.applyUpgrade(UpgradeManager.EarlyGame.hireWorker)
        XCTAssertEqual(restored.totalPackagesShipped, packages)
        XCTAssertEqual(restored.money, cash)
    }

    func testChallengeCanSuppressBaseEndings() {
        let gs = GameState()
        gs.baseEndingsEnabled = false
        gs.ethicalChoicesMade = 5
        gs.lifetimeTotalMoneyEarned = 5000
        gs.shipPackage()
        XCTAssertFalse(gs.isRunTerminal)
        gs.ethicsScore = 0
        gs.evaluateEndings()
        XCTAssertFalse(gs.isRunTerminal)
    }

    func testEventRejectsUnaffordableChoiceAndOffersConstructiveTradeoff() {
        let gs = GameState()
        gs.workers = 5
        gs.workerMorale = 0.5
        let manager = EventManager()
        let unrest = manager.allEventsForTesting.first { $0.title == "Worker Unrest" }!
        manager.currentEvent = unrest
        manager.processChoice(choice: unrest.choices[0], gameState: gs)
        XCTAssertEqual(gs.ethicalChoicesMade, 0)
        XCTAssertNotNil(manager.currentEvent)
        let listening = unrest.choices.first { $0.text.contains("listening") }!
        let efficiency = gs.workerEfficiency
        manager.processChoice(choice: listening, gameState: gs)
        XCTAssertEqual(gs.ethicalChoicesMade, 1)
        XCTAssertGreaterThan(gs.workerMorale, 0.5)
        XCTAssertLessThan(gs.workerEfficiency, efficiency)
    }

    func testLegacySnapshotWithoutEndingFieldsLoads() throws {
        let gs = GameState()
        let data = try JSONEncoder().encode(GameSnapshot(from: gs))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for key in ["endingReached", "hasBankedPrestigeThisRun", "loopStabilitySeconds"] { json.removeValue(forKey: key) }
        let oldData = try JSONSerialization.data(withJSONObject: json)
        let restored = GameState()
        try JSONDecoder().decode(GameSnapshot.self, from: oldData).apply(to: restored)
        XCTAssertFalse(restored.endingReached)
        XCTAssertEqual(restored.loopStabilitySeconds, 0)
    }

    func testAllEndingsReachableThroughCatalogGameplay() throws {
        for ending in [GameEnding.reform, .loop, .collapse] {
            let state = playEndingRoute(ending)
            XCTAssertTrue(state.isRunTerminal)
            XCTAssertEqual(state.endingType, ending)
            let firstAward = state.concludeRun()
            XCTAssertGreaterThan(firstAward, 0)
            XCTAssertEqual(state.concludeRun(), 0)
            let restored = GameState()
            let data = try JSONEncoder().encode(GameSnapshot(from: state))
            try JSONDecoder().decode(GameSnapshot.self, from: data).apply(to: restored)
            XCTAssertTrue(restored.isRunTerminal)
            XCTAssertEqual(restored.endingType, ending)
            XCTAssertEqual(restored.concludeRun(), 0)
        }
    }

    func testResetClearsEndingReached() {
        let gs = GameState()
        gs.ethicalChoicesMade = 5
        gs.ethicsScore = 60
        gs.money = 1500
        gs.lifetimeTotalMoneyEarned = 1500
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



/// Scripted catalog choices and taps; only the clock is injected, never outcome metrics.
func playEndingRoute(_ ending: GameEnding) -> GameState {
    let state = GameState()
    state.reset()
    let start = Date(timeIntervalSince1970: 1800000000)
    state.lastUpdate = start
    for _ in 0..<4000 { state.shipPackage() }
    state.applyUpgrade(UpgradeManager.EarlyGame.hireWorker)
    state.applyUpgrade(UpgradeManager.EarlyGame.hireWorker)
    if ending == .reform {
        state.applyUpgrade(UpgradeManager.EarlyGame.optimizeLogistics)
        state.applyUpgrade(UpgradeManager.EarlyGame.basicTraining)
        state.applyUpgrade(UpgradeManager.EarlyGame.safetyPlacards)
        state.applyUpgrade(UpgradeManager.MidGame.performanceBonuses)
        state.applyUpgrade(UpgradeManager.MidGame.performanceBonuses)
    } else {
        let events = EventManager()
        let boom = events.allEventsForTesting.first { $0.title == "Market Boom" }!
        let raisePrices = boom.choices.first { $0.moralImpact < 0 }!
        while !state.isRunTerminal && (ending != .loop || !(15...25).contains(state.ethicsScore)) {
            precondition(boom.triggerCondition(state))
            events.currentEvent = boom
            let choice = ending == .loop && state.ethicsScore < 15 ? boom.choices.first { $0.moralImpact > 0 }! : raisePrices
            events.processChoice(choice: choice, gameState: state, currentTime: start)
        }
        for second in 1...60 {
            state.processAutomation(currentTime: start.addingTimeInterval(Double(second)))
        }
    }
    return state
}
