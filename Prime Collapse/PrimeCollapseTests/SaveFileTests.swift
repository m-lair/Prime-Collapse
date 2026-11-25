//
//  SaveFileTests.swift
//  PrimeCollapseTests
//
//  Durability of the on-disk JSON save, exercised against a temporary directory.
//

import XCTest
@testable import Prime_Collapse

final class SaveFileTests: XCTestCase {

    private var dir: URL!

    override func setUp() {
        super.setUp()
        dir = TestHelpers.makeTempDirectory()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: dir)
        dir = nil
        super.tearDown()
    }

    func testWriteThenReadReturnsEqualSnapshot() throws {
        let gs = GameState()
        gs.totalPackagesShipped = 500
        gs.money = 1234.0
        gs.workers = 2
        for _ in 0..<2 {
            gs.upgrades.append(TestHelpers.instance(of: UpgradeManager.EarlyGame.hireWorker))
        }
        let snapshot = GameSnapshot(from: gs)

        try SaveFile.write(snapshot, in: dir)
        let loaded = SaveFile.read(in: dir)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.totalPackagesShipped, 500)
        XCTAssertEqual(loaded?.money, 1234.0)
        XCTAssertEqual(loaded?.workers, 2)
        XCTAssertEqual(loaded?.repeatableUpgradeCounts["Hire Worker"], 2)
    }

    func testCorruptFileReturnsNil() throws {
        let fileURL = SaveFile.url(in: dir)
        try Data("not valid json {{{".utf8).write(to: fileURL)

        XCTAssertNil(SaveFile.read(in: dir))
    }

    func testRumorsFalloutSurvivesRelaunchAndLandsOnce() throws {
        let state = GameState()
        let saves = SaveManager(gameState: state, directory: dir)
        state.totalPackagesShipped = 300
        saves.saveGameState() // An older autosave may still be writing when the player chooses.
        let manager = EventManager()
        manager.presentForTesting(titled: "Competitor Undercuts Prices")
        let rumors = try XCTUnwrap(manager.currentEvent?.choices.first { $0.text.contains("rumors") })
        let start = Date()
        manager.processChoice(choice: rumors, gameState: state, now: start)
        let payout = state.money
        XCTAssertGreaterThan(payout, 0)
        XCTAssertEqual(state.publicPerception, 47)
        saves.saveOnEvent(.eventChoice)

        let restarted = GameState()
        _ = SaveManager(gameState: restarted, directory: dir)
        XCTAssertEqual(restarted.money, payout)
        restarted.processAutomation(currentTime: start.addingTimeInterval(44.99))
        XCTAssertEqual(restarted.publicPerception, 47)
        restarted.processAutomation(currentTime: start.addingTimeInterval(45))
        XCTAssertEqual(restarted.publicPerception, 37)
        try SaveFile.write(GameSnapshot(from: restarted), in: dir)

        let relaunchedAgain = GameState()
        _ = SaveManager(gameState: relaunchedAgain, directory: dir)
        relaunchedAgain.processAutomation(currentTime: start.addingTimeInterval(90))
        XCTAssertEqual(relaunchedAgain.publicPerception, 37)
        XCTAssertTrue(relaunchedAgain.pendingEffects.isEmpty)
    }

    func testOverdueFineUsesOriginalAmountAndIncomeShiftKeepsItsDeadline() throws {
        let state = GameState()
        state.money = 1_000
        let start = Date(timeIntervalSinceReferenceDate: 1_000.75)
        let choice = EventChoice(text: "Shortcut", cash: EventStakes.jackpot,
                                 incomeShift: IncomeShift(bonus: -0.25, duration: 60),
                                 fallout: Fallout(delay: 30, fine: EventStakes.fine,
                                                  consequences: [.workerMorale(-0.1), .customerSatisfaction(-0.2)]))
        EventManager().processChoice(choice: choice, gameState: state, now: start)
        let fine = EventStakes.fine.sizedAmount(in: state)
        state.money = 2_000
        try SaveFile.write(GameSnapshot(from: state), in: dir)

        let restored = GameState()
        let resume = start.addingTimeInterval(45)
        try XCTUnwrap(SaveFile.read(in: dir)).apply(to: restored, at: resume)
        XCTAssertTrue(restored.pendingEffects.isEmpty)
        XCTAssertEqual(restored.money, 2_000 - fine, accuracy: 0.001)
        XCTAssertEqual(restored.workerMorale, 0.7, accuracy: 0.001)
        XCTAssertEqual(restored.customerSatisfaction, 0.7, accuracy: 0.001)
        XCTAssertEqual(restored.incomeMultiplier(from: resume, to: resume), 0.75)
        try SaveFile.write(GameSnapshot(from: restored), in: dir)

        let expired = GameState()
        let end = start.addingTimeInterval(60)
        try XCTUnwrap(SaveFile.read(in: dir)).apply(to: expired, at: end)
        XCTAssertTrue(expired.incomeModifiers.isEmpty)
        XCTAssertEqual(expired.incomeMultiplier(from: end, to: end), 1)
        XCTAssertEqual(expired.money, restored.money)
        XCTAssertEqual(expired.workerMorale, restored.workerMorale)
    }

    func testSaveWithoutEventFieldsRestoresPlayerProgress() throws {
        var legacy = snapshot(money: 345)
        legacy.pendingEffects = nil
        legacy.incomeModifiers = nil
        try SaveFile.write(legacy, in: dir)

        let restored = GameState()
        let saves = SaveManager(gameState: restored, directory: dir)
        XCTAssertNil(saves.lastLoadMessage)
        XCTAssertEqual(restored.money, 345)
        XCTAssertTrue(restored.pendingEffects.isEmpty)
        XCTAssertTrue(restored.incomeModifiers.isEmpty)
    }

    func testLaunchCommitsOverduePenaltyBeforeAnyGameplayOrAutosave() throws {
        let state = GameState()
        state.money = 100
        state.pendingEffects = [DelayedEffect(triggerTime: Date.distantPast.timeIntervalSinceReferenceDate,
                                              fine: 25, consequences: [.publicPerception(-10)])]
        try SaveFile.write(GameSnapshot(from: state), in: dir)

        for _ in 0..<2 {
            let restarted = GameState()
            _ = SaveManager(gameState: restarted, directory: dir)
            let saved = try XCTUnwrap(SaveFile.read(in: dir))
            XCTAssertEqual(saved.money, 75)
            XCTAssertEqual(saved.publicPerception, 40)
            XCTAssertTrue(try XCTUnwrap(saved.pendingEffects).isEmpty)
        }
    }

    func testReadMissingFileReturnsNil() {
        XCTAssertNil(SaveFile.read(in: dir))
    }

    func testDeleteRemovesFile() throws {
        try SaveFile.write(GameSnapshot(from: GameState()), in: dir)
        XCTAssertNotNil(SaveFile.read(in: dir))

        SaveFile.delete(in: dir)
        XCTAssertNil(SaveFile.read(in: dir))
    }

    // MARK: - Backup rotation & recovery

    private func snapshot(money: Double) -> GameSnapshot {
        let gs = GameState()
        gs.money = money
        return GameSnapshot(from: gs)
    }

    private var fm: FileManager { .default }

    func testBackupCreatedOnSecondWrite() throws {
        let backup = SaveFile.backupURL(in: dir)
        XCTAssertFalse(fm.fileExists(atPath: backup.path))

        try SaveFile.write(snapshot(money: 111), in: dir)
        // Nothing to rotate on the first write.
        XCTAssertFalse(fm.fileExists(atPath: backup.path))

        try SaveFile.write(snapshot(money: 222), in: dir)
        // Second write rotates the previous good file into the backup.
        XCTAssertTrue(fm.fileExists(atPath: backup.path))
    }

    func testRecoversFromBackupWhenPrimaryCorrupt() throws {
        try SaveFile.write(snapshot(money: 111), in: dir)   // primary = 111
        try SaveFile.write(snapshot(money: 222), in: dir)   // backup = 111, primary = 222

        // Corrupt the primary file.
        try Data("garbage not json".utf8).write(to: SaveFile.url(in: dir))

        let result = SaveFile.load(in: dir)

        XCTAssertEqual(result.outcome, .recoveredFromBackup)
        XCTAssertEqual(result.snapshot?.money, 111)
        // The corrupt primary is quarantined.
        XCTAssertTrue(fm.fileExists(atPath: SaveFile.corruptURL(in: dir).path))
    }

    func testCorruptWithNoBackupReportsCorruptedNoBackup() throws {
        try Data("garbage not json".utf8).write(to: SaveFile.url(in: dir))

        let result = SaveFile.load(in: dir)

        XCTAssertNil(result.snapshot)
        XCTAssertEqual(result.outcome, .corruptedNoBackup)
        XCTAssertTrue(fm.fileExists(atPath: SaveFile.corruptURL(in: dir).path))
        XCTAssertFalse(fm.fileExists(atPath: SaveFile.url(in: dir).path))
    }

    func testEmptyDirectoryReportsEmptyOutcome() {
        let result = SaveFile.load(in: dir)
        XCTAssertNil(result.snapshot)
        XCTAssertEqual(result.outcome, .empty)
    }

    func testDeleteAlsoRemovesBackup() throws {
        try SaveFile.write(snapshot(money: 111), in: dir)
        try SaveFile.write(snapshot(money: 222), in: dir)
        XCTAssertTrue(fm.fileExists(atPath: SaveFile.backupURL(in: dir).path))

        SaveFile.delete(in: dir)

        XCTAssertFalse(fm.fileExists(atPath: SaveFile.url(in: dir).path))
        XCTAssertFalse(fm.fileExists(atPath: SaveFile.backupURL(in: dir).path))
    }
}
