import XCTest
@testable import Prime_Collapse

@MainActor final class HolidayRushTests: XCTestCase {
    private func session(configuration: HolidayRushConfiguration = .init()) -> HolidayRushSession {
        HolidayRushSession(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), configuration: configuration)
    }

    func testExplicitStartAndOwnedWorkers() {
        let run = session()
        run.advance(seconds: 100)
        XCTAssertFalse(run.hasRun)
        run.start()
        run.game.validateGameState()
        XCTAssertEqual(run.game.workers, 3)
        XCTAssertEqual(run.game.upgrades.filter { $0.name == "Hire Worker" }.count, 3)
        XCTAssertEqual(run.game.money, 150)
        XCTAssertFalse(run.game.baseEndingsEnabled)
    }

    func testTicksStopAtDecisionAndChoiceCannotRepeat() {
        let run = session()
        run.start()
        run.advance(seconds: 200)
        XCTAssertEqual(run.elapsed, 120)
        XCTAssertEqual(run.pendingDecision?.id, "staffing")
        let packages = run.game.totalPackagesShipped
        run.advance(seconds: 100)
        XCTAssertEqual(run.game.totalPackagesShipped, packages)
        run.choose("staffing-care")
        let ethics = run.game.ethicsScore
        run.choose("staffing-care")
        XCTAssertEqual(run.game.ethicsScore, ethics)
        XCTAssertNil(run.pendingDecision)
        XCTAssertTrue(run.isRunning)
    }

    func testDeadlineProductionSucceedsBeforeFailureAndFreezes() {
        let run = session()
        run.start()
        for choice in ["staffing-care", "backlog-care", "priority-care"] {
            run.advance(seconds: 720)
            run.choose(choice)
        }
        run.game.baseSystemRate = 100
        run.advance(seconds: 900)
        XCTAssertEqual(run.elapsed, 720)
        XCTAssertEqual(run.result?.outcome, .success)
        let result = run.result
        let packages = run.game.totalPackagesShipped
        run.advance(seconds: 20)
        run.shipPackage()
        run.start()
        XCTAssertEqual(run.result, result)
        XCTAssertEqual(run.game.totalPackagesShipped, packages)
        XCTAssertEqual(run.activity.filter { $0.kind == "completion" }.count, 1)
    }

    func testDeadlineFailureAndCollapsePriority() {
        let run = session()
        run.start()
        for choice in ["staffing-care", "backlog-care", "priority-care"] {
            run.advance(seconds: 720)
            run.choose(choice)
        }
        run.advance(seconds: 900)
        XCTAssertEqual(run.result?.outcome, .deadline)
        let collapse = session()
        collapse.start()
        collapse.game.totalPackagesShipped = 1500
        collapse.game.ethicsScore = 0
        collapse.shipPackage()
        XCTAssertEqual(collapse.result?.outcome, .collapse)
    }

    func testReloadPausesAndPreservesPendingDecisionWithoutOfflineIncome() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let run = HolidayRushSession(directory: directory)
        run.start()
        run.advance(seconds: 120)
        let restored = HolidayRushSession(directory: directory, now: { Date.distantFuture })
        XCTAssertEqual(restored.elapsed, 120)
        XCTAssertEqual(restored.pendingDecision?.id, "staffing")
        XCTAssertFalse(restored.isRunning)
        restored.advance(seconds: 10000)
        XCTAssertEqual(restored.game.totalPackagesShipped, run.game.totalPackagesShipped)
        restored.choose("staffing-care")
        XCTAssertFalse(restored.isRunning)
        restored.resume()
        XCTAssertTrue(restored.isRunning)
    }

    func testReplayPreservesResultsFeedbackAndMainEconomy() {
        let company = GameState()
        company.money = 4321
        let run = session()
        run.start()
        run.game.totalPackagesShipped = 1499
        run.shipPackage()
        XCTAssertEqual(run.result?.outcome, .success)
        run.recordFeedback(.maybe)
        run.replay()
        XCTAssertEqual(run.game.money, 150)
        XCTAssertNil(run.result)
        XCTAssertNotNil(run.lastResult)
        XCTAssertNotNil(run.bestResult)
        XCTAssertEqual(run.feedback, .maybe)
        XCTAssertEqual(company.money, 4321)
        XCTAssertEqual(run.game.prestige, PrestigeState())
    }

    func testCorruptSaveRecoveryAndVisibleWriteError() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("broken".utf8).write(to: directory.appendingPathComponent("holiday-rush.json"))
        let run = HolidayRushSession(directory: directory)
        XCTAssertNotNil(run.recoveryNotice)
        run.start()
        XCTAssertNil(run.saveError)
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(contentsOf: directory.appendingPathComponent("holiday-rush.json"))))
        let file = directory.appendingPathComponent("file")
        try Data().write(to: file)
        let blocked = HolidayRushSession(directory: file)
        blocked.start()
        XCTAssertNotNil(blocked.saveError)
        XCTAssertTrue(blocked.hasRun)
    }

    func testWindowBadgeUsesCompletionDateAndLogIsCapped() {
        let date = Date(timeIntervalSince1970: 1000)
        let config = HolidayRushConfiguration(start: date.addingTimeInterval(-1), end: date.addingTimeInterval(1))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let run = HolidayRushSession(directory: directory, now: { date }, configuration: config)
        run.start()
        run.game.totalPackagesShipped = 1499
        run.shipPackage()
        XCTAssertTrue(run.result?.earnedEventBadge == true)
        for _ in 0..<150 { run.recordShare() }
        XCTAssertLessThanOrEqual(run.activity.count, 100)
        XCTAssertTrue(run.diagnosticsExport().contains("schemaVersion"))
        let practice = session()
        practice.start()
        practice.game.totalPackagesShipped = 1499
        practice.shipPackage()
        XCTAssertFalse(practice.result?.earnedEventBadge ?? true)
    }
    func testEthicalPublicGameplayCanCompleteWithAllThreeDecisions() {
        let run = session()
        run.start()
        let names = ["Optimize Logistics", "Improve Packaging", "Basic Training", "Automate Sorting"]
        var decisions: [String] = []
        for _ in 0..<720 {
            if let decision = run.pendingDecision {
                decisions.append(decision.id)
                run.choose(decision.id + "-care")
            }
            if run.result != nil { break }
            run.shipPackage()
            for name in names {
                if let upgrade = UpgradeManager.availableUpgrades.first(where: { $0.name == name }),
                   !run.game.hasBeenPurchased(upgrade), run.game.isUpgradeUnlocked(upgrade),
                   run.game.money >= run.game.getCurrentUpgradeCost(upgrade) + 100 {
                    run.purchase(upgrade)
                }
            }
            let worker = UpgradeManager.EarlyGame.hireWorker
            if run.game.workers < 10, run.game.money >= run.game.getCurrentUpgradeCost(worker) + 100 {
                run.purchase(worker)
            }
            run.advance(seconds: 1)
        }
        print("HOLIDAY_PACING elapsed=\(run.elapsed) packages=\(run.game.totalPackagesShipped) ethics=\(run.game.ethicsScore) morale=\(run.game.workerMorale) workers=\(run.game.workers) decisions=\(decisions)")
        XCTAssertEqual(decisions, ["staffing", "backlog", "priority"])
        XCTAssertEqual(run.result?.outcome, .success)
        XCTAssertEqual(run.game.prestige, PrestigeState())
    }

    func testWindowEndIsExclusiveAndCompletionNotStartDeterminesBadge() {
        var date = Date(timeIntervalSince1970: 1000)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let config = HolidayRushConfiguration(start: date, end: date.addingTimeInterval(60))
        let run = HolidayRushSession(directory: directory, now: { date }, configuration: config)
        run.start()
        date = date.addingTimeInterval(60)
        run.game.totalPackagesShipped = 1499
        run.shipPackage()
        XCTAssertEqual(run.result?.outcome, .success)
        XCTAssertFalse(run.result?.earnedEventBadge ?? true)
        XCTAssertFalse(HolidayRushConfiguration(start: date, end: date.addingTimeInterval(32 * 86400)).hasEventWindow)
    }

    func testFailedEncodingPreservesLastAtomicSaveAndCanRetry() throws {
        let run = session()
        run.start()
        let data = try Data(contentsOf: run.saveURL)
        run.game.workerEfficiency = .infinity
        run.save()
        XCTAssertNotNil(run.saveError)
        XCTAssertEqual(try Data(contentsOf: run.saveURL), data)
        run.game.workerEfficiency = 1
        run.save()
        XCTAssertNil(run.saveError)
    }

    func testTerminalReloadAndReplayRemainIsolated() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let run = HolidayRushSession(directory: directory)
        run.start()
        run.game.totalPackagesShipped = 1499
        run.shipPackage()
        run.recordFeedback(.yes)
        let loaded = HolidayRushSession(directory: directory)
        XCTAssertEqual(loaded.result, run.result)
        loaded.resume()
        loaded.shipPackage()
        XCTAssertFalse(loaded.isRunning)
        XCTAssertEqual(loaded.result, run.result)
        loaded.replay()
        let replayed = HolidayRushSession(directory: directory)
        XCTAssertNil(replayed.result)
        XCTAssertEqual(replayed.lastResult, run.result)
        XCTAssertEqual(replayed.bestResult, run.bestResult)
        XCTAssertEqual(replayed.feedback, .yes)
        XCTAssertEqual(replayed.elapsed, 0)
        XCTAssertFalse(replayed.isRunning)
        XCTAssertEqual(replayed.game.money, 150)
    }

    func testPausedAndInvalidTicksCannotProduceIncomeOrBuy() {
        let run = session()
        run.start()
        run.pause()
        run.advance(seconds: 100)
        run.shipPackage()
        run.purchase(UpgradeManager.EarlyGame.hireWorker)
        XCTAssertEqual(run.game.money, 150)
        XCTAssertEqual(run.game.workers, 3)
        XCTAssertEqual(run.elapsed, 0)
        run.resume()
        for seconds in [Double.nan, .infinity, -1, 0] { run.advance(seconds: seconds) }
        XCTAssertEqual(run.elapsed, 0)
        run.advance(seconds: 120)
        run.pause()
        run.choose("staffing-balanced")
        XCTAssertFalse(run.isRunning)
        run.resume()
        XCTAssertTrue(run.isRunning)
    }

}
