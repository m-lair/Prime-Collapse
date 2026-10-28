import Foundation
import Observation

@MainActor @Observable final class GamePlayCoordinator {
    enum Destination { case home, company, holidayRush }

    private(set) var destination: Destination = .home
    let company: GameState
    let challenge: HolidayRushSession
    private let now: () -> Date

    init(company: GameState, challenge: HolidayRushSession, now: @escaping () -> Date = Date.init) {
        self.company = company
        self.challenge = challenge
        self.now = now
    }

    func openCompany() { move(to: .company) }
    func openHolidayRush() { move(to: .holidayRush) }
    func goHome() { move(to: .home) }

    @discardableResult func open(_ url: URL) -> Bool {
        guard HolidayRushRoute.matches(url) else { return false }
        openHolidayRush()
        return true
    }

    @discardableResult func advanceCompany(at date: Date) -> Bool {
        guard destination == .company, !company.isRunTerminal else { return false }
        company.processAutomation(currentTime: date)
        return true
    }

    private func move(to destination: Destination) {
        guard self.destination != destination else { return }
        challenge.pause()
        let date = now()
        company.lastUpdate = date
        company.resetForegroundTiming(currentTime: date)
        self.destination = destination
    }
}
