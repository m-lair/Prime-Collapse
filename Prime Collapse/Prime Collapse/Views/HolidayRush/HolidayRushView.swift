import SwiftUI
import UIKit

struct HolidayRushView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var session: HolidayRushSession
    @State private var decisionReceipt: String?
    @State private var sharedResult: HolidayRushResult?
    @State private var showInvestments = false
    @State private var showProductionDetails = false
    private let onReturn: (() -> Void)?

    init(session: HolidayRushSession? = nil, onReturn: (() -> Void)? = nil) {
        self.onReturn = onReturn
        _session = State(initialValue: session ?? HolidayRushSession())
    }

    private let navy = GamePalette.ink

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Game home", systemImage: "house") {
                    session.pause()
                    if let onReturn { onReturn() } else { dismiss() }
                }
                .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                Text("Holiday Rush")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if session.hasRun && session.result == nil {
                    Button("Production details", systemImage: "chart.bar") {
                        session.pause()
                        showProductionDetails = true
                    }
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                }
                if session.isRunning {
                    Button("Pause", systemImage: "pause") { session.pause() }
                        .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: 740)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if session.hasRun && session.result == nil {
                        DispatchHUD(game: session.game, remaining: session.remaining, isRunning: session.isRunning)
                    }
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
                .padding(22)
                .frame(maxWidth: 740)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(navy)
        }
        .background(navy.ignoresSafeArea())
        .foregroundStyle(GamePalette.label)
        .preferredColorScheme(.dark)
        .tint(GamePalette.orange)
        .task {
            let clock = ContinuousClock()
            var previous = clock.now
            var receiptAge = 0.0
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
                if decisionReceipt != nil {
                    receiptAge += seconds
                    if receiptAge >= 5 { decisionReceipt = nil }
                } else {
                    receiptAge = 0
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.pause() }
        }
        .onDisappear { session.pause() }
        .sheet(isPresented: $showInvestments) {
            GameInvestmentTray(game: session.game, remaining: session.remaining,
                               preview: { session.preview(for: $0) }, purchase: { session.purchase($0) })
        }
        .sheet(isPresented: $showProductionDetails) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Production outlook").font(.title2.bold())
                        Spacer()
                        Button("Done") { showProductionDetails = false }
                    }
                    productionOutlook
                }
                .padding(24)
            }
            .background(GamePalette.ink)
            .foregroundStyle(GamePalette.label)
            .presentationDetents([.medium, .large])
        }
        .onChange(of: session.pendingDecision?.id) { _, pending in
            if pending != nil { showInvestments = false }
        }
        .onChange(of: session.result?.id) { _, result in
            if result != nil { showInvestments = false }
        }
        .sheet(item: $sharedResult) { result in
            HolidayRushShareSheet(text: result.shareText)
        }
    }

    private var briefing: some View {
        VStack(alignment: .leading, spacing: 24) {
            Label("\(session.eventAvailable ? "FEATURED CHALLENGE" : "FREE PRACTICE")", systemImage: "sparkles")
                .font(.caption.weight(.bold)).tracking(1.5)
                .foregroundStyle(GamePalette.teal)
            Text("Beat the rush.\nProtect your team.")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            DispatchStage(packages: 0, workers: 3, automaticRate: 0.3, isRunning: false)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { briefingGoals }
                VStack(alignment: .leading, spacing: 12) { briefingGoals }
            }
            Text("Keep ethics ≥ 40 and morale ≥ 40%. Start with 3 workers and $150, and face three workforce decisions.")
                .font(.body).foregroundStyle(GamePalette.label.opacity(0.8))
            Button { session.start() } label: {
                HStack {
                    Text("Start challenge")
                    Spacer()
                    Image(systemName: "play.fill")
                }
            }
            .buttonStyle(GameActionStyle())
            DisclosureGroup("How this shift works") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Finish with ethics at least 40 and morale at least 40%. Tap to ship and invest to increase production.")
                    Text("Time and production pause during decisions, in the background, and outside this screen. Resume when you return. Your main company stays separate; prestige bonuses do not apply.")
                    eventAvailability
                }
                .font(.callout).padding(.top, 12)
            }
            if let previous = session.lastResult {
                Text("Last attempt: \(previous.packages) packages · \(previous.outcome == .success ? "Completed" : "Try again")")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var briefingGoals: some View {
        Label("1,500 packages", systemImage: "shippingbox")
        Label("12 minutes", systemImage: "timer")
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
        VStack(alignment: .leading, spacing: 22) {
            if let decision = session.pendingDecision {
                decisionContent(decision)
            } else {
                DispatchStage(packages: session.game.totalPackagesShipped, workers: session.game.workers,
                              automaticRate: session.game.automaticPackagesPerSecond, isRunning: session.isRunning,
                              onShip: session.isRunning ? { session.shipPackage() } : nil)
                if !session.isRunning {
                    Button("Resume challenge", systemImage: "play.fill") { session.resume() }
                        .buttonStyle(GameActionStyle())
                    Text("Your time and production are on hold.")
                        .font(.callout).foregroundStyle(GamePalette.label.opacity(0.75))
                } else {
                    if let receipt = decisionReceipt {
                        Label(receipt, systemImage: "checkmark.circle.fill")
                            .font(.callout).foregroundStyle(GamePalette.teal)
                            .accessibilityLabel("Decision applied. \(receipt)")
                    }
                    if let next = session.upcomingDecision, let paid = next.choices.first(where: { $0.cost > 0 }) {
                        ViewThatFits(in: .horizontal) {
                            HStack { nextDecision(next, paid: paid) }
                            VStack(alignment: .leading, spacing: 8) { nextDecision(next, paid: paid) }
                        }
                        .font(.caption).foregroundStyle(GamePalette.label.opacity(0.75))
                    } else {
                        Label("All decisions made. Keep shipping.", systemImage: "checkmark.circle")
                            .font(.callout).foregroundStyle(GamePalette.teal)
                    }
                    Button { showInvestments = true } label: {
                        HStack {
                            Text("Investments")
                            if !dynamicTypeSize.isAccessibilitySize {
                                Spacer(minLength: 8)
                                Image(systemName: "arrow.up.right")
                            }
                        }
                    }
                    .buttonStyle(GameActionStyle(prominent: false))
                }
            }
        }
    }

    @ViewBuilder private func nextDecision(_ decision: HolidayRushDecision, paid: HolidayRushDecision.Choice) -> some View {
        let seconds = Int(ceil(max(0, decision.time - session.elapsed)))
        Label("Decision in \(seconds / 60):\(String(format: "%02d", seconds % 60))", systemImage: "person.2")
        Spacer(minLength: 0)
        Text("Paid option \(paid.cost.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
    }

    private func decisionContent(_ decision: HolidayRushDecision) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("FLOOR PAUSED · YOUR CALL", systemImage: "pause.circle.fill")
                .font(.caption.weight(.bold)).tracking(1)
                .foregroundStyle(GamePalette.teal)
            Text(decision.title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text(decision.detail).foregroundStyle(GamePalette.label.opacity(0.8))
            ForEach(decision.choices) { choice in
                Button {
                    session.choose(choice.id)
                    decisionReceipt = choice.title + " · " + choice.detail
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(choice.title).font(.system(.headline, design: .rounded))
                            Spacer(minLength: 4)
                            Image(systemName: "arrow.right")
                        }
                        Text(choice.detail).font(.callout)
                            .foregroundStyle(GamePalette.label.opacity(0.85))
                        if session.game.money < choice.cost {
                            Text("Need \((choice.cost - session.game.money).formatted(.currency(code: "USD"))) more")
                                .font(.caption.bold()).foregroundStyle(GamePalette.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(GameActionStyle(prominent: false))
                .disabled(session.game.money < choice.cost)
            }
        }
        .sensoryFeedback(.success, trigger: session.pendingDecision == nil)
    }

    private var productionOutlook: some View {
            panel {
                Text("Production outlook").font(.headline)
                Text("Automatic-only finish: \(HolidayRushInsights.projectedPackages(game: session.game, remaining: session.remaining).formatted()) / 1,500 packages")
                    .font(.title3.bold())
                Text("At current rates, with no further taps, purchases, or decisions.")
                    .font(.caption).foregroundStyle(.secondary)
                if session.remaining > 0 {
                    let required = max(0, Double(HolidayRushSession.packageGoal - session.game.totalPackagesShipped)) / session.remaining
                    Text("Required total pace: \(required.formatted(.number.precision(.fractionLength(2)))) pkg/s · manual + automatic")
                        .font(.callout)
                }
                Text("Finish with ethics ≥ 40 and morale ≥ 40%.")
                    .font(.callout).foregroundStyle(.secondary)
            }
    }

    private func resultContent(_ result: HolidayRushResult) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: result.outcome == .success ? "checkmark.seal.fill" : "clock.badge.exclamationmark")
                .font(.system(size: 52)).foregroundStyle(result.outcome == .success ? .cyan : .orange)
                .accessibilityHidden(true)
            Text(result.outcome == .success ? "Rush complete" : result.outcome == .collapse ? "Company collapsed" : "Time’s up")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text(result.retryAdvice)
            panel {
                Text("\(result.packages.formatted()) / 1,500 packages").font(.title2.bold())
                Text("Active time: \(Int(result.elapsed)) seconds")
                Text("Ethics: \(Int(result.ethics)) · Morale: \(Int(result.morale * 100))%")
                ForEach(result.unmetRequirements, id: \.self) { requirement in
                    Label(requirement, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                }
                Text("Run average: \(result.averagePackagesPerSecond.formatted(.number.precision(.fractionLength(2)))) pkg/s · manual + automatic")
                    .font(.callout)
                Text("The volume goal needs an average \((Double(HolidayRushSession.packageGoal) / HolidayRushSession.duration).formatted(.number.precision(.fractionLength(2)))) pkg/s over 12 active minutes.")
                    .font(.caption).foregroundStyle(.secondary)
                if result.outcome == .success {
                    Label("Local completion badge earned", systemImage: "medal.fill").foregroundStyle(GamePalette.teal)
                }
                earnedBadgeLabel
                if let best = session.bestResult {
                    Text("Best local completion: \(Int(best.elapsed)) active seconds").foregroundStyle(.secondary)
                }
            }
            Button("Replay challenge", systemImage: "arrow.clockwise") {
                decisionReceipt = nil
                session.replay()
            }
            .buttonStyle(GameActionStyle())
            Button("Share Result", systemImage: "square.and.arrow.up") {
                session.recordShare()
                sharedResult = result
            }
            DisclosureGroup("Optional playtest feedback") {
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
                .foregroundStyle(GamePalette.teal)
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
