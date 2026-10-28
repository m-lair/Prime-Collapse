import XCTest
@testable import Prime_Collapse

@MainActor final class HolidayRushInsightsTests: XCTestCase {
    private func session() -> HolidayRushSession {
        let run = HolidayRushSession(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        run.start()
        return run
    }

    func testDisplayedRatesMatchActualProductionAndIncome() {
        let game = session().game
        game.workers = 4
        game.baseWorkerRate = 0.1
        game.workerEfficiency = 1.2
        game.baseSystemRate = 0.3
        game.automationEfficiency = 1.4
        game.workerMorale = 1
        game.environmentalImpact = 40
        game.packageValue = 1.5
        game.customerSatisfaction = 0.6
        game.publicPerception = 80
        XCTAssertEqual(game.automaticPackagesPerSecond, 0.792, accuracy: 0.000001)
        XCTAssertEqual(game.effectivePackageValue, 1.344, accuracy: 0.000001)
        let money = game.money
        game.processAutomation(currentTime: Date(timeIntervalSince1970: 4))
        XCTAssertEqual(game.totalPackagesShipped, 3)
        XCTAssertEqual(game.packageAccumulator, 0.168, accuracy: 0.000001)
        XCTAssertEqual(game.money - money, 3 * 1.344, accuracy: 0.000001)
    }

    func testLowMoraleAndEnvironmentAreIncludedInRate() {
        let game = session().game
        game.workerMorale = 0.2
        game.environmentalImpact = 100
        XCTAssertEqual(game.automaticPackagesPerSecond, 0.06, accuracy: 0.000001)
    }

    func testForecastIncludesFractionsButNoHypotheticalTaps() {
        let game = session().game
        game.totalPackagesShipped = 100
        game.packageAccumulator = 0.9
        game.workerMorale = 0.7
        XCTAssertEqual(HolidayRushInsights.projectedPackages(game: game, remaining: 4), 102)
        XCTAssertEqual(HolidayRushInsights.projectedPackages(game: game, remaining: 0), 100)
        XCTAssertEqual(HolidayRushInsights.projectedPackages(game: game, remaining: .infinity), 100)
        XCTAssertEqual(game.totalPackagesShipped, 100)
    }

    func testPreviewMatchesRealPurchaseAndNeverChangesLiveRun() throws {
        let run = session()
        run.game.totalPackagesShipped = 200
        run.game.money = 1000
        let before = normalizedSnapshot(run.game)
        let upgrades = [UpgradeManager.EarlyGame.hireWorker, UpgradeManager.EarlyGame.basicTraining,
                        UpgradeManager.MidGame.automateSorting]
        for upgrade in upgrades {
            let preview = try XCTUnwrap(run.preview(for: upgrade))
            XCTAssertEqual(normalizedSnapshot(run.game), before)
            let copy = GameState()
            copy.baseEndingsEnabled = false
            GameSnapshot(from: run.game).apply(to: copy)
            copy.applyUpgrade(upgrade)
            XCTAssertEqual(preview.automaticRateAfter, copy.automaticPackagesPerSecond, accuracy: 0.000001)
            XCTAssertEqual(preview.packageValueAfter, copy.effectivePackageValue, accuracy: 0.000001)
        }
    }

    func testUnaffordablePreviewAndLockedOrCapRestrictions() throws {
        let run = session()
        run.game.money = 0
        XCTAssertNotNil(run.preview(for: UpgradeManager.EarlyGame.hireWorker))
        XCTAssertEqual(run.game.money, 0)
        XCTAssertNil(run.preview(for: UpgradeManager.MidGame.automateSorting))
        run.game.workers = GameState.maxWorkers
        XCTAssertNil(run.preview(for: UpgradeManager.EarlyGame.hireWorker))
    }

    func testPaybackAccountsForCashBackAndIncomeChanges() throws {
        let run = session()
        let preview = try XCTUnwrap(run.preview(for: UpgradeManager.EarlyGame.bulkMaterialPurchase))
        let incomeDelta = preview.automaticRateAfter * preview.packageValueAfter
            - preview.automaticRateBefore * preview.packageValueBefore
        XCTAssertEqual(preview.netCost, 60, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(preview.paybackSeconds), 60 / incomeDelta, accuracy: 0.000001)
    }

    func testPreviewWithNoIncomeGainHasNoFinitePayback() {
        let preview = HolidayRushUpgradePreview(automaticRateBefore: 1, automaticRateAfter: 1,
                                               packageValueBefore: 1, packageValueAfter: 1, netCost: 200)
        XCTAssertNil(preview.paybackSeconds)
    }

    func testCachedPreviewUpdatesAfterPurchaseAndMoraleChanges() throws {
        let run = session()
        let worker = UpgradeManager.EarlyGame.hireWorker
        let initial = try XCTUnwrap(run.preview(for: worker))
        run.purchase(worker)
        let purchased = try XCTUnwrap(run.preview(for: worker))
        XCTAssertGreaterThan(purchased.automaticRateAfter, initial.automaticRateAfter)
        run.game.workerMorale = 0.2
        let lowMorale = try XCTUnwrap(run.preview(for: worker))
        XCTAssertLessThan(lowMorale.automaticRateAfter, purchased.automaticRateAfter)
    }

    func testCashDependentPreviewRefreshesAfterIncome() throws {
        let run = session()
        run.game.ethicsScore = 40
        run.game.money = 3000
        let upgrade = try XCTUnwrap(UpgradeManager.availableUpgrades.first { $0.name == "Offshore Tax Havens" })
        let before = try XCTUnwrap(run.preview(for: upgrade))
        run.game.earnMoney(1000)
        let after = try XCTUnwrap(run.preview(for: upgrade))
        let fresh = try XCTUnwrap(HolidayRushInsights.preview(upgrade, game: run.game))
        XCTAssertNotEqual(before.netCost, after.netCost)
        XCTAssertEqual(after.netCost, fresh.netCost, accuracy: 0.000001)
    }

    func testLossFeedbackListsEveryUnmetRequirementAndHandlesZeroTime() {
        let result = HolidayRushResult(id: UUID(), outcome: .deadline, packages: 778, elapsed: 720,
                                       ethics: 53, morale: 0.57, completedAt: Date(), earnedEventBadge: false)
        XCTAssertEqual(result.unmetRequirements.count, 1)
        XCTAssertTrue(result.unmetRequirements[0].contains("722"))
        XCTAssertTrue(result.retryAdvice.contains("production"))
        XCTAssertEqual(result.averagePackagesPerSecond, 778.0 / 720, accuracy: 0.000001)
        let combined = HolidayRushResult(id: UUID(), outcome: .deadline, packages: 100, elapsed: 0,
                                         ethics: 20, morale: 0.1, completedAt: Date(), earnedEventBadge: false)
        XCTAssertEqual(combined.unmetRequirements.count, 3)
        XCTAssertEqual(combined.averagePackagesPerSecond, 0)
    }

    func testVolumeReachedButWorkforceMissedIsExplainedWithoutProductionAdvice() {
        let result = HolidayRushResult(id: UUID(), outcome: .deadline, packages: 1600, elapsed: 720,
                                       ethics: 23, morale: 0.25, completedAt: Date(), earnedEventBadge: false)
        XCTAssertEqual(result.unmetRequirements.count, 2)
        XCTAssertTrue(result.retryAdvice.contains("workforce"))
        let success = HolidayRushResult(id: UUID(), outcome: .success, packages: 1500, elapsed: 600,
                                        ethics: 40, morale: 0.4, completedAt: Date(), earnedEventBadge: false)
        XCTAssertTrue(success.unmetRequirements.isEmpty)
    }

    private func normalizedSnapshot(_ game: GameState) -> Data {
        var snapshot = GameSnapshot(from: game)
        snapshot.savedAt = .distantPast
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try! encoder.encode(snapshot)
    }
}
