//
//  PrestigeStoreTests.swift
//  PrimeCollapseTests
//
//  Prestige persistence lives in its own file, separate from the game save, so it
//  survives game resets and never collides with GameSnapshot.
//

import XCTest
@testable import Prime_Collapse

final class PrestigeStoreTests: XCTestCase {

    func testRoundTripsStateThroughDisk() {
        let dir = TestHelpers.makeTempDirectory()
        var state = PrestigeState()
        state.points = 42
        _ = state.purchase(.efficientOperations)
        _ = state.purchase(.efficientOperations)
        _ = state.purchase(.seedCapital)

        PrestigeStore.save(state, in: dir)
        let loaded = PrestigeStore.load(in: dir)

        XCTAssertEqual(loaded, state)
        XCTAssertEqual(loaded.level(of: .efficientOperations), 2)
        XCTAssertEqual(loaded.level(of: .seedCapital), 1)
    }

    func testLoadReturnsEmptyStateWhenNoFile() {
        let dir = TestHelpers.makeTempDirectory()
        let loaded = PrestigeStore.load(in: dir)
        XCTAssertEqual(loaded, PrestigeState())
    }

    func testCorruptFileFallsBackToEmptyState() throws {
        let dir = TestHelpers.makeTempDirectory()
        try Data("not json".utf8).write(to: PrestigeStore.url(in: dir))

        let loaded = PrestigeStore.load(in: dir)

        XCTAssertEqual(loaded, PrestigeState())
    }
}
