import XCTest
@testable import Prime_Collapse

@MainActor final class GamePlayCoordinatorTests: XCTestCase {
    func testHomeAndChallengeCannotAdvanceCompanyOrAwardCatchUp() {
        var now = Date(timeIntervalSince1970: 1000)
        let company = GameState()
        company.reset()
        let challenge = makeChallenge()
        let play = GamePlayCoordinator(company: company, challenge: challenge, now: { now })
        XCTAssertFalse(play.advanceCompany(at: now.addingTimeInterval(100)))
        XCTAssertEqual(company.totalPackagesShipped, 0)
        play.openCompany()
        now = now.addingTimeInterval(20)
        XCTAssertTrue(play.advanceCompany(at: now))
        let packages = company.totalPackagesShipped
        let fraction = company.packageAccumulator
        play.openHolidayRush()
        now = now.addingTimeInterval(5000)
        XCTAssertFalse(play.advanceCompany(at: now))
        XCTAssertEqual(company.totalPackagesShipped, packages)
        play.goHome()
        play.openCompany()
        XCTAssertTrue(play.advanceCompany(at: now.addingTimeInterval(0.1)))
        XCTAssertEqual(company.totalPackagesShipped, packages)
        XCTAssertEqual(company.packageAccumulator, fraction + company.automaticPackagesPerSecond * 0.1, accuracy: 0.000001)
    }

    func testHomePausesAndPersistsChallengeWithoutResettingCompany() {
        let company = GameState()
        company.reset()
        company.money = 4321
        let challenge = makeChallenge()
        let play = GamePlayCoordinator(company: company, challenge: challenge)
        play.openHolidayRush()
        XCTAssertFalse(challenge.hasRun)
        challenge.start()
        challenge.advance(seconds: 20)
        play.goHome()
        XCTAssertFalse(challenge.isRunning)
        challenge.advance(seconds: 100)
        XCTAssertEqual(challenge.elapsed, 20)
        play.openHolidayRush()
        XCTAssertFalse(challenge.isRunning)
        XCTAssertEqual(challenge.elapsed, 20)
        XCTAssertEqual(company.money, 4321)
        XCTAssertTrue(FileManager.default.fileExists(atPath: challenge.saveURL.path))
    }

    func testDeepLinkSelectsChallengeButNeverStartsOrResetsIt() {
        let challenge = makeChallenge()
        let play = GamePlayCoordinator(company: GameState(), challenge: challenge)
        XCTAssertFalse(play.open(URL(string: "primecollapse://events/unknown")!))
        XCTAssertEqual(play.destination, .home)
        XCTAssertTrue(play.open(URL(string: "primecollapse://events/holiday-rush")!))
        XCTAssertEqual(play.destination, .holidayRush)
        XCTAssertFalse(challenge.hasRun)
        challenge.start()
        challenge.advance(seconds: 20)
        XCTAssertTrue(play.open(URL(string: "primecollapse://events/holiday-rush")!))
        XCTAssertEqual(challenge.elapsed, 20)
        XCTAssertTrue(challenge.isRunning)
    }

    func testCompanyTerminalStateCannotProduceIncomeFromHomeContinue() {
        let company = GameState()
        company.reset()
        company.isCollapsing = true
        let play = GamePlayCoordinator(company: company, challenge: makeChallenge())
        play.openCompany()
        XCTAssertFalse(play.advanceCompany(at: Date.distantFuture))
        XCTAssertEqual(company.totalPackagesShipped, 0)
    }

    private func makeChallenge() -> HolidayRushSession {
        HolidayRushSession(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }
}
