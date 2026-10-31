import GameKit
import Testing
@testable import Prime_Collapse

@MainActor
struct GameCenterManagerTests {
    @Test func gameStateUpdateSendsScoresBeforeCachingThem() {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.isAuthenticated = true
        let game = makeGame()

        manager.updateFromGameState(game)

        #expect(transport.scores == expectedScores)
        #expect(manager.lastSubmittedScores.isEmpty)
    }

    @Test func manualRefreshSendsScoresBeforeCachingThem() {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.isAuthenticated = true

        manager.forceRefreshScores(makeGame())

        #expect(transport.scores == expectedScores)
        #expect(manager.lastSubmittedScores.isEmpty)
    }

    @Test func scoreIsConfirmedOnlyAfterSuccessfulUpload() {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.isAuthenticated = true
        let id = GameCenterManager.totalPackagesLeaderboardID

        manager.submitScore(123, to: id)

        #expect(manager.lastSubmittedScores[id] == nil)
        transport.requests[0].complete(nil)
        #expect(manager.lastSubmittedScores[id] == 123)
        manager.submitScore(123, to: id)
        #expect(transport.requests.count == 1)
    }

    @Test func failedUploadCanBeSubmittedAgain() {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.isAuthenticated = true
        let id = GameCenterManager.totalPackagesLeaderboardID

        manager.submitScore(123, to: id)
        transport.requests[0].complete(GKError(.communicationsFailure))
        #expect(manager.lastSubmittedScores[id] == nil)

        manager.submitScore(123, to: id)
        #expect(transport.requests.count == 2)
    }

    @Test func duplicateScoresWaitForTheUploadInProgress() {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.isAuthenticated = true
        let id = GameCenterManager.totalPackagesLeaderboardID

        manager.submitScore(123, to: id)
        manager.submitScore(123, to: id)

        #expect(transport.requests.count == 1)
    }

    @Test func lateCompletionDoesNotLowerTheConfirmedScore() {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.isAuthenticated = true
        let id = GameCenterManager.totalPackagesLeaderboardID

        manager.submitScore(123, to: id)
        manager.submitScore(456, to: id)
        transport.requests[1].complete(nil)
        transport.requests[0].complete(nil)

        #expect(manager.lastSubmittedScores[id] == 456)
        manager.submitScore(456, to: id)
        #expect(transport.requests.count == 2)
    }

    @Test func throttledUpdateDoesNotConfirmUnsentProgress() {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.isAuthenticated = true
        let game = makeGame()
        manager.updateFromGameState(game)
        transport.requests.forEach { $0.complete(nil) }

        game.totalPackagesShipped = 234
        manager.updateFromGameState(game)
        #expect(manager.lastSubmittedScores[GameCenterManager.totalPackagesLeaderboardID] == 123)
        #expect(transport.requests.count == 5)

        manager.forceRefreshScores(game)
        #expect(transport.requests.count == 6)
        #expect(transport.requests.last?.score == 234)
    }

    @Test func failedScoreIsRetriedAndConfirmed() async throws {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.isAuthenticated = true
        let id = GameCenterManager.totalPackagesLeaderboardID
        manager.submitScore(123, to: id)
        transport.requests[0].complete(GKError(.communicationsFailure))

        try await waitUntil { transport.requests.count == 2 }
        #expect(transport.requests[1].score == 123)
        #expect(manager.lastSubmittedScores[id] == nil)
        transport.requests[1].complete(nil)
        try await waitUntil { manager.lastSubmittedScores[id] == 123 }
    }

    @Test func newerFailureDuringRetryIsPreserved() async throws {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.isAuthenticated = true
        let id = GameCenterManager.totalPackagesLeaderboardID
        manager.submitScore(123, to: id)
        transport.requests[0].complete(GKError(.communicationsFailure))
        try await waitUntil { transport.requests.count == 2 }

        manager.submitScore(456, to: id)
        transport.requests[2].complete(GKError(.communicationsFailure))
        transport.requests[1].complete(nil)

        try await waitUntil { transport.requests.count == 4 }
        #expect(transport.requests[3].score == 456)
        transport.requests[3].complete(nil)
        try await waitUntil { manager.lastSubmittedScores[id] == 456 }
    }

    @Test func signedOutPlayerDoesNotUploadScores() {
        let transport = ScoreTransport()
        let manager = GameCenterManager(submitLeaderboardScore: transport.submit)
        manager.updateFromGameState(makeGame())
        manager.forceRefreshScores(makeGame())
        manager.submitScore(123, to: GameCenterManager.totalPackagesLeaderboardID)
        #expect(transport.requests.isEmpty)
        #expect(manager.lastSubmittedScores.isEmpty)
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while !condition(), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(condition())
    }

    private var expectedScores: [String: Int] {
        [
            GameCenterManager.totalPackagesLeaderboardID: 123,
            GameCenterManager.totalMoneyLeaderboardID: 456,
            GameCenterManager.highestEthicsScoreLeaderboardID: 80,
            GameCenterManager.packagesPerSecondLeaderboardID: 350,
            GameCenterManager.totalWorkersLeaderboardID: 3
        ]
    }

    private func makeGame() -> GameState {
        let game = GameState()
        game.totalPackagesShipped = 123
        game.lifetimeTotalMoneyEarned = 456
        game.ethicsScore = 80
        game.workers = 3
        game.baseWorkerRate = 1
        game.workerEfficiency = 1
        game.baseSystemRate = 0.5
        game.automationEfficiency = 1
        return game
    }
}

@MainActor
private final class ScoreTransport {
    struct Request {
        let score: Int
        let leaderboardID: String
        let complete: @MainActor (Error?) -> Void
    }

    var requests: [Request] = []

    var scores: [String: Int] {
        Dictionary(requests.map { ($0.leaderboardID, $0.score) }, uniquingKeysWith: max)
    }

    func submit(_ score: Int, to leaderboardID: String, completion: @escaping @MainActor (Error?) -> Void) {
        requests.append(Request(score: score, leaderboardID: leaderboardID, complete: completion))
    }
}
