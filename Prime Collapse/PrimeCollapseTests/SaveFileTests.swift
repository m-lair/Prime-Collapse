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
