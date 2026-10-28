import Foundation
import Observation

struct HolidayRushResult: Codable, Equatable, Identifiable {
    enum Outcome: String, Codable { case success, deadline, collapse }
    let id: UUID
    let outcome: Outcome
    let packages: Int
    let elapsed: Double
    let ethics: Double
    let morale: Double
    let completedAt: Date
    let earnedEventBadge: Bool

    var shareText: String {
        "Holiday Rush: \(outcome == .success ? "Challenge complete!" : "Challenge attempt") \(packages)/1,500 packages in \(Int(elapsed)) active seconds. Ethics \(Int(ethics)), morale \(Int(morale * 100))%. Play Prime Collapse."
    }
}

struct HolidayRushEarnedBadge: Codable, Equatable {
    let runID: UUID
    let earnedAt: Date
}

enum HolidayRushFeedback: String, Codable, CaseIterable { case yes = "Yes", maybe = "Maybe", no = "No" }

struct HolidayRushActivity: Codable, Identifiable {
    var schemaVersion = 1
    let id: UUID
    let runID: UUID
    let date: Date
    let kind: String
    let value: String?
}

private struct HolidayRushSave: Codable {
    var schemaVersion = 1
    let runID: UUID
    let hasRun: Bool
    let elapsed: Double
    let nextDecision: Int
    let pendingDecisionID: String?
    let game: GameSnapshot
    let result: HolidayRushResult?
    let lastResult: HolidayRushResult?
    let bestResult: HolidayRushResult?
    let feedback: HolidayRushFeedback?
    let activity: [HolidayRushActivity]
    var earnedEventBadge: HolidayRushEarnedBadge? = nil
}

@MainActor @Observable final class HolidayRushSession {
    static let duration = 720.0
    static let packageGoal = 1500
    static let minimumEthics = 40.0
    static let minimumMorale = 0.4

    private(set) var game = GameState()
    private(set) var hasRun = false
    private(set) var isRunning = false
    private(set) var elapsed = 0.0
    private(set) var pendingDecision: HolidayRushDecision?
    private(set) var result: HolidayRushResult?
    private(set) var lastResult: HolidayRushResult?
    private(set) var bestResult: HolidayRushResult?
    private(set) var feedback: HolidayRushFeedback?
    private(set) var earnedEventBadge: HolidayRushEarnedBadge?
    private(set) var activity: [HolidayRushActivity] = []
    private(set) var saveError: String?
    private(set) var recoveryNotice: String?
    let configuration: HolidayRushConfiguration
    private let directory: URL
    private let now: () -> Date
    private var runID = UUID()
    private var nextDecision = 0
    private var resumeAfterDecision = false
    private var lastAutosaveElapsed = 0.0

    var remaining: Double { max(0, Self.duration - elapsed) }
    var eventAvailable: Bool { configuration.contains(now()) }
    var saveURL: URL { directory.appendingPathComponent("holiday-rush.json") }

    init(directory: URL? = nil, now: @escaping () -> Date = Date.init,
         configuration: HolidayRushConfiguration = .bundled) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PrimeCollapse/HolidayRush", isDirectory: true)
        self.now = now
        self.configuration = configuration
        game.baseEndingsEnabled = false
        load()
    }

    func start() {
        guard !hasRun else { return }
        begin()
        log("start")
        save()
    }

    private func begin() {
        game = GameState()
        game.baseEndingsEnabled = false
        game.reset()
        game.money = 150
        game.workers = 3
        let worker = UpgradeManager.EarlyGame.hireWorker
        for _ in 0..<2 {
            game.upgrades.append(Upgrade(name: worker.name, description: worker.description, cost: worker.cost,
                                         effect: worker.effect, isRepeatable: true, priceScalingFactor: worker.priceScalingFactor))
        }
        game.lastUpdate = Date(timeIntervalSince1970: 0)
        runID = UUID()
        hasRun = true
        isRunning = true
        elapsed = 0
        lastAutosaveElapsed = 0
        nextDecision = 0
        pendingDecision = nil
        result = nil
        resumeAfterDecision = false
    }

    func resume() {
        guard hasRun, result == nil, pendingDecision == nil, !isRunning else { return }
        isRunning = true
        log("resume")
        save()
    }

    func pause() {
        isRunning = false
        resumeAfterDecision = false
        if hasRun { save() }
    }

    func advance(seconds: Double) {
        guard hasRun, isRunning, result == nil, pendingDecision == nil,
              seconds.isFinite, seconds > 0 else { return }
        if resolveIfNeeded() { return }
        let decisionTime = nextDecision < HolidayRushDecision.schedule.count
            ? HolidayRushDecision.schedule[nextDecision].time : Self.duration
        let delta = max(0, min(seconds, remaining, decisionTime - elapsed))
        elapsed += delta
        game.processAutomation(currentTime: Date(timeIntervalSince1970: elapsed))
        if resolveIfNeeded() { return }
        if nextDecision < HolidayRushDecision.schedule.count, elapsed >= decisionTime {
            pendingDecision = HolidayRushDecision.schedule[nextDecision]
            resumeAfterDecision = true
            isRunning = false
            save()
        } else if elapsed - lastAutosaveElapsed >= 5 {
            save()
        }
    }

    func shipPackage() {
        guard canAct else { return }
        game.shipPackage()
        _ = resolveIfNeeded()
    }

    func purchase(_ upgrade: Upgrade) {
        guard canAct, UpgradeManager.availableUpgrades.contains(where: { $0.id == upgrade.id }) else { return }
        game.applyUpgrade(upgrade)
        _ = resolveIfNeeded()
        save()
    }

    private var canAct: Bool { hasRun && isRunning && pendingDecision == nil && result == nil }

    func choose(_ id: String) {
        guard result == nil, let decision = pendingDecision,
              let choice = decision.choices.first(where: { $0.id == id }), game.money >= choice.cost else { return }
        game.money -= choice.cost
        game.ethicsScore += choice.ethics
        game.workerMorale += choice.morale
        game.workerEfficiency *= choice.efficiency
        pendingDecision = nil
        nextDecision += 1
        isRunning = resumeAfterDecision
        resumeAfterDecision = false
        _ = resolveIfNeeded()
        save()
    }

    @discardableResult private func resolveIfNeeded() -> Bool {
        guard result == nil else { return true }
        let outcome: HolidayRushResult.Outcome
        if game.ethicsScore <= 0 || game.isCollapsing { outcome = .collapse }
        else if game.totalPackagesShipped >= Self.packageGoal,
                game.ethicsScore >= Self.minimumEthics, game.workerMorale >= Self.minimumMorale { outcome = .success }
        else if elapsed >= Self.duration { outcome = .deadline }
        else { return false }
        let completion = now()
        let resolved = HolidayRushResult(id: runID, outcome: outcome, packages: game.totalPackagesShipped,
                                         elapsed: elapsed, ethics: game.ethicsScore, morale: game.workerMorale,
                                         completedAt: completion,
                                         earnedEventBadge: outcome == .success && configuration.contains(completion))
        if resolved.earnedEventBadge, earnedEventBadge == nil {
            earnedEventBadge = .init(runID: resolved.id, earnedAt: resolved.completedAt)
        }
        result = resolved
        lastResult = resolved
        if outcome == .success, bestResult == nil || elapsed < bestResult!.elapsed { bestResult = resolved }
        isRunning = false
        resumeAfterDecision = false
        pendingDecision = nil
        log(outcome == .success ? "completion" : "failure", value: outcome.rawValue)
        save()
        return true
    }

    func replay() {
        guard result != nil else { return }
        begin()
        log("retry")
        save()
    }

    func recordFeedback(_ response: HolidayRushFeedback) {
        guard result != nil, feedback != response else { return }
        feedback = response
        log("feedback", value: response.rawValue)
        save()
    }

    func recordShare() {
        guard result != nil else { return }
        log("share", value: "share_sheet_opened")
        save()
    }

    func diagnosticsExport() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        struct Export: Encodable {
            let schemaVersion = 1
            let result: HolidayRushResult?
            let bestResult: HolidayRushResult?
            let feedback: HolidayRushFeedback?
            let activity: [HolidayRushActivity]
        }
        let export = Export(result: lastResult, bestResult: bestResult, feedback: feedback, activity: activity)
        return (try? String(decoding: encoder.encode(export), as: UTF8.self)) ?? "Unable to export challenge diagnostics."
    }

    private func log(_ kind: String, value: String? = nil) {
        activity.append(.init(id: UUID(), runID: runID, date: now(), kind: kind, value: value))
        activity = Array(activity.suffix(100))
    }

    func save() {
        guard hasRun else { return }
        do {
            let snapshot = HolidayRushSave(runID: runID, hasRun: hasRun, elapsed: elapsed,
                                           nextDecision: nextDecision, pendingDecisionID: pendingDecision?.id,
                                           game: GameSnapshot(from: game), result: result, lastResult: lastResult,
                                           bestResult: bestResult, feedback: feedback, activity: activity, earnedEventBadge: earnedEventBadge)
            let data = try JSONEncoder().encode(snapshot)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: saveURL, options: .atomic)
            lastAutosaveElapsed = elapsed
            saveError = nil
        } catch {
            saveError = "Holiday Rush could not be saved. Your company is unaffected. \(error.localizedDescription)"
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let snapshot = try JSONDecoder().decode(HolidayRushSave.self, from: Data(contentsOf: saveURL))
            guard snapshot.schemaVersion == 1, snapshot.elapsed.isFinite,
                  (0...Self.duration).contains(snapshot.elapsed), (0...3).contains(snapshot.nextDecision),
                  snapshot.game.repeatableUpgradeCounts.values.allSatisfy({ (0...500).contains($0) }),
                  snapshot.game.totalPackagesShipped >= 0 else { throw CocoaError(.coderReadCorrupt) }
            let expectedPending = HolidayRushDecision.schedule.first { $0.id == snapshot.pendingDecisionID }
            if snapshot.pendingDecisionID != nil {
                guard snapshot.nextDecision < 3, expectedPending?.id == HolidayRushDecision.schedule[snapshot.nextDecision].id,
                      expectedPending?.time == snapshot.elapsed else { throw CocoaError(.coderReadCorrupt) }
            }
            snapshot.game.apply(to: game)
            game.baseEndingsEnabled = false
            game.lastUpdate = Date(timeIntervalSince1970: snapshot.elapsed)
            hasRun = snapshot.hasRun
            runID = snapshot.runID
            elapsed = snapshot.elapsed
            nextDecision = snapshot.nextDecision
            pendingDecision = expectedPending
            result = snapshot.result
            lastResult = snapshot.lastResult
            bestResult = snapshot.bestResult
            feedback = snapshot.feedback
            let previousBadgeResult = [snapshot.result, snapshot.lastResult, snapshot.bestResult]
                .compactMap { $0 }.filter(\.earnedEventBadge).min { $0.completedAt < $1.completedAt }
            earnedEventBadge = snapshot.earnedEventBadge ?? previousBadgeResult.map {
                HolidayRushEarnedBadge(runID: $0.id, earnedAt: $0.completedAt)
            }
            activity = Array(snapshot.activity.suffix(100))
            lastAutosaveElapsed = elapsed
        } catch {
            recoveryNotice = "The Holiday Rush save could not be read. Start a fresh challenge; your company save is unaffected."
            let backup = directory.appendingPathComponent("holiday-rush-unreadable-\(UUID().uuidString).json")
            do { try FileManager.default.moveItem(at: saveURL, to: backup) }
            catch { saveError = "The unreadable challenge save could not be preserved. \(error.localizedDescription)" }
        }
    }
}
