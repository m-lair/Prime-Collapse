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
}
