import SwiftUI

struct GameHomeView: View {
    let game: GameState
    let challenge: HolidayRushSession
    let onContinue: () -> Void
    let onChallenge: () -> Void
    let onSettings: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Text("Prime Collapse")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Spacer(minLength: 12)
                    Button("Settings", systemImage: "gearshape.fill", action: onSettings)
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.1), in: Circle())
                }
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 14) {
                        if !textSize.isAccessibilitySize {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 30))
                                .frame(width: 64, height: 64)
                                .background(.blue.gradient, in: Circle())
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your company")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                            Text("\(game.workers.formatted()) \(game.workers == 1 ? "worker" : "workers") · \(Int(game.workerMorale * 100))% morale")
                                .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    let layout = textSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                        : AnyLayout(HStackLayout(spacing: 24))
                    layout {
                        summary("Packages shipped", value: game.totalPackagesShipped.formatted())
                        summary("Available cash", value: game.money.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    }
                    Button(action: onContinue) {
                        HStack {
                            Text(game.isRunTerminal ? "View company outcome" : "Continue Company")
                            Spacer(minLength: 8)
                            if !textSize.isAccessibilitySize { Image(systemName: "arrow.right") }
                        }
                        .font(.system(.headline, design: .rounded))
                        .padding(18)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color(red: 0.025, green: 0.32, blue: 0.68).gradient, in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(HomePressStyle())
                }
                .padding(22)
                .background(.black.opacity(0.18), in: .rect(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.15)))

                VStack(alignment: .leading, spacing: 12) {
                    Text("CHALLENGES").font(.caption.weight(.bold)).tracking(1.4)
                        .foregroundStyle(.white.opacity(0.75))
                    HolidayRushEntryCard(subtitle: challengeSummary, actionTitle: challengeAction, open: onChallenge)
                }
            }
            .padding(24)
            .padding(.top, 20)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .foregroundStyle(.white)
        .background {
            LinearGradient(colors: [Color(red: 0.1, green: 0.2, blue: 0.3), Color(red: 0.2, green: 0.3, blue: 0.5)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }

    private func summary(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(.title2, design: .rounded, weight: .bold)).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var challengeSummary: String {
        if challenge.result != nil { return "Your latest run is complete." }
        guard challenge.hasRun else { return "Free challenge · 12 minutes to ship 1,500 packages." }
        let seconds = Int(ceil(max(0, challenge.remaining)))
        return "Paused · \(challenge.game.totalPackagesShipped.formatted()) packages · \(seconds / 60):\(String(format: "%02d", seconds % 60)) left"
    }

    private var challengeAction: String {
        challenge.result != nil ? "View result" : challenge.hasRun ? "Resume challenge" : "Explore Holiday Rush"
    }
}

private struct HomePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.75 : 1)
    }
}
