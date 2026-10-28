import SwiftUI
import UIKit

struct HolidayRushView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: HolidayRushSession
    @State private var manualShipCount = 0
    @State private var sharedResult: HolidayRushResult?

    init(session: HolidayRushSession? = nil) {
        _session = State(initialValue: session ?? HolidayRushSession())
    }

    private let navy = Color(red: 0.055, green: 0.08, blue: 0.16)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let error = session.saveError {
                        panel {
                            Label("Challenge save needs attention", systemImage: "exclamationmark.triangle")
                                .font(.headline).foregroundStyle(.orange)
                            Text(error).font(.callout)
                            Button("Retry Save") { session.save() }
                        }
                    }
                    if let notice = session.recoveryNotice {
                        Text(notice).font(.callout).foregroundStyle(.secondary)
                    }
                    if let result = session.result {
                        resultContent(result)
                    } else if session.hasRun {
                        gameplay
                    } else {
                        briefing
                    }
                }
                .padding()
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(navy)
            .navigationTitle("Holiday Rush")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Return to Company", systemImage: "chevron.backward") {
                        session.pause()
                        dismiss()
                    }
                    .labelStyle(.titleOnly)
                }
                if session.isRunning {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Pause", systemImage: "pause.fill") { session.pause() }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(.cyan)
        .task {
            let clock = ContinuousClock()
            var previous = clock.now
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(100)) }
                catch { break }
                let current = clock.now
                let duration = previous.duration(to: current)
                previous = current
                let seconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
                if scenePhase == .active {
                    session.advance(seconds: min(seconds, 1))
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.pause() }
        }
        .onDisappear { session.pause() }
        .sheet(item: $sharedResult) { result in
            HolidayRushShareSheet(text: result.shareText)
        }
    }

    private var briefing: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "shippingbox.fill").font(.system(size: 52)).foregroundStyle(.cyan)
                .accessibilityHidden(true)
            Text("Beat the rush.\nProtect your workforce.")
                .font(.largeTitle.bold())
            Text("Ship 1,500 packages within 12 minutes of active play. Finish with ethics at least 40 and morale at least 40%.")
                .font(.title3)
            panel {
                Label("Your challenge company", systemImage: "building.2")
                    .font(.headline)
                Text("Start with 3 workers, $150, and no prestige bonuses. Tap to ship, buy upgrades, and make three workforce decisions.")
                Text("Time and production pause during decisions, in the background, and outside this screen. Return using Resume. Your main company stays separate.")
                    .foregroundStyle(.secondary)
            }
            eventAvailability
            Button { session.start() } label: {
                Label("Start Challenge", systemImage: "play.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            if let previous = session.lastResult {
                Text("Last attempt: \(previous.packages) packages · \(previous.outcome == .success ? "Completed" : "Try again")")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var eventAvailability: some View {
        panel {
            earnedBadgeLabel
            Label(session.eventAvailable ? "Event completion badge available" : "Free practice challenge", systemImage: session.eventAvailable ? "medal.fill" : "shippingbox")
                .font(.headline)
            if session.eventAvailable, let end = session.configuration.end {
                Text("Complete the challenge before \(end.formatted(date: .abbreviated, time: .shortened)) to earn the dated local badge.")
            } else {
                Text("Practice is always available. There is no active event window.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var gameplay: some View {
        VStack(alignment: .leading, spacing: 20) {
            panel {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(session.game.totalPackagesShipped.formatted()) / 1,500").font(.title.bold()).monospacedDigit()
                    Spacer()
                    Text(timeRemaining).font(.title2.bold()).monospacedDigit()
                        .accessibilityLabel("\(Int(ceil(session.remaining))) seconds remaining")
                }
                Text("Packages shipped · Active time remaining").font(.caption).foregroundStyle(.secondary)
                ProgressView(value: min(1, Double(session.game.totalPackagesShipped) / 1500))
                    .accessibilityLabel("Package goal")
                ViewThatFits(in: .horizontal) {
                    HStack { metrics }
                    VStack(alignment: .leading) { metrics }
                }
                Text("Finish with ethics ≥ 40 and morale ≥ 40%.").font(.callout).foregroundStyle(.secondary)
            }
            if let decision = session.pendingDecision {
                decisionContent(decision)
            } else if !session.isRunning {
                panel {
                    Label("Challenge paused", systemImage: "pause.circle.fill").font(.headline)
                    Text("Your active time and production are stopped.")
                    Button("Resume Challenge", systemImage: "play.fill") { session.resume() }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                }
            } else {
                Button { session.shipPackage(); manualShipCount += 1 } label: {
                    Label("Ship Package", systemImage: "shippingbox.fill")
                        .font(.title3.bold()).frame(maxWidth: .infinity).padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .sensoryFeedback(.impact(weight: .light), trigger: manualShipCount)
                Text(session.elapsed < 480 ? "Next decision at \(nextDecisionDescription) active minutes. Timer pauses while you choose." : "All workforce decisions are complete. Keep shipping before time runs out.")
                    .font(.callout).foregroundStyle(.secondary)
                upgrades
            }
        }
    }

    @ViewBuilder private var metrics: some View {
        Label(session.game.money.formatted(.currency(code: "USD").precision(.fractionLength(0))), systemImage: "dollarsign.circle")
        Spacer(minLength: 8)
        Label("\(session.game.workers) workers", systemImage: "person.2.fill")
        Spacer(minLength: 8)
        Text("Ethics \(Int(session.game.ethicsScore))")
        Text("Morale \(Int(session.game.workerMorale * 100))%")
    }

    private var timeRemaining: String {
        let seconds = Int(ceil(session.remaining))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var nextDecisionDescription: String {
        if session.elapsed < 120 { return "2" }
        if session.elapsed < 300 { return "5" }
        if session.elapsed < 480 { return "8" }
        return "no more scheduled"
    }

    private func decisionContent(_ decision: HolidayRushDecision) -> some View {
        panel {
            Label("Decision · Time paused", systemImage: "pause.circle").foregroundStyle(.cyan)
            Text(decision.title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
            Text(decision.detail)
            ForEach(decision.choices) { choice in
                Button { session.choose(choice.id) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(choice.title).font(.headline)
                        Text(choice.detail).font(.callout)
                        if session.game.money < choice.cost { Text("Not enough cash").font(.caption) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .disabled(session.game.money < choice.cost)
            }
        }
    }

    private var upgrades: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Challenge upgrades").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            ForEach(UpgradeManager.availableUpgrades.filter { $0.isRepeatable || !session.game.hasBeenPurchased($0) }) { upgrade in
                let cost = session.game.getCurrentUpgradeCost(upgrade)
                panel {
                    Text(upgrade.name).font(.headline)
                    Text(upgrade.description).font(.callout).foregroundStyle(.secondary)
                    if upgrade.moralImpact != 0 {
                        Text("Ethics \(upgrade.moralImpact > 0 ? "+" : "")\(upgrade.moralImpact.formatted())")
                            .font(.caption)
                    }
                    if !session.game.isUpgradeUnlocked(upgrade) {
                        Text(session.game.getUpgradeRequirementDescription(upgrade) ?? "Requirements not met")
                            .font(.caption).foregroundStyle(.orange)
                    }
                    Button("Buy · \(cost.formatted(.currency(code: "USD").precision(.fractionLength(2))))") {
                        session.purchase(upgrade)
                    }
                    .buttonStyle(.bordered)
                    .disabled(session.game.money < cost || !session.game.isUpgradeUnlocked(upgrade) ||
                              (upgrade.name == "Hire Worker" && session.game.workers >= GameState.maxWorkers))
                }
            }
        }
    }

    private func resultContent(_ result: HolidayRushResult) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: result.outcome == .success ? "checkmark.seal.fill" : "clock.badge.exclamationmark")
                .font(.system(size: 52)).foregroundStyle(result.outcome == .success ? .cyan : .orange)
                .accessibilityHidden(true)
            Text(result.outcome == .success ? "Rush complete" : result.outcome == .collapse ? "Company collapsed" : "Time’s up")
                .font(.largeTitle.bold())
            Text(result.outcome == .success ? "You delivered while protecting the team." : "Try another balance of upgrades, shipping, and workforce choices.")
            panel {
                Text("\(result.packages.formatted()) / 1,500 packages").font(.title2.bold())
                Text("Active time: \(Int(result.elapsed)) seconds")
                Text("Ethics: \(Int(result.ethics)) · Morale: \(Int(result.morale * 100))%")
                if result.outcome == .success {
                    Label("Local completion badge earned", systemImage: "medal.fill").foregroundStyle(.cyan)
                }
                earnedBadgeLabel
                if let best = session.bestResult {
                    Text("Best local completion: \(Int(best.elapsed)) active seconds").foregroundStyle(.secondary)
                }
            }
            Button("Replay Challenge", systemImage: "arrow.clockwise") { session.replay() }
                .buttonStyle(.borderedProminent).controlSize(.large)
            Button("Share Result", systemImage: "square.and.arrow.up") {
                session.recordShare()
                sharedResult = result
            }
            panel {
                Text("Would you play more challenges like this?").font(.headline)
                Text("Optional · Saved only on this device").font(.caption).foregroundStyle(.secondary)
                HStack {
                    ForEach(HolidayRushFeedback.allCases, id: \.self) { response in
                        Button(response.rawValue) { session.recordFeedback(response) }
                            .buttonStyle(.bordered)
                            .tint(session.feedback == response ? .cyan : .gray)
                            .accessibilityAddTraits(session.feedback == response ? .isSelected : [])
                    }
                }
                if let feedback = session.feedback { Text("Saved: \(feedback.rawValue). Thank you.").font(.caption) }
            }
            ShareLink(item: session.diagnosticsExport()) {
                Label("Export Local Diagnostics", systemImage: "doc.text")
            }
            Text("Share local results and up to 100 activity records. Nothing is uploaded automatically.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var earnedBadgeLabel: some View {
        if let badge = session.earnedEventBadge {
            Label("Event badge earned · \(badge.earnedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "medal.fill")
                .foregroundStyle(.cyan)
        }
    }

    private func panel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct HolidayRushShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
