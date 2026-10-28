import SwiftUI

struct GameHomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let game: GameState
    let challenge: HolidayRushSession
    let onContinue: () -> Void
    let onChallenge: () -> Void
    let onSettings: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PRIME")
                            .font(.system(.largeTitle, design: .rounded, weight: .black))
                            .tracking(3)
                        Text("COLLAPSE")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .tracking(5)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Prime Collapse")
                    Spacer()
                    Button("Settings", systemImage: "gearshape", action: onSettings)
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .buttonStyle(.plain)
                }

                VStack(spacing: 16) {
                    DispatchStage(packages: game.totalPackagesShipped, workers: game.workers,
                                  automaticRate: game.automaticPackagesPerSecond, isRunning: false)
                    Button(action: onContinue) {
                        VStack(alignment: .leading, spacing: 9) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("Continue company")
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.right")
                            }
                            Text("\(game.money.formatted(.currency(code: "USD").precision(.fractionLength(0)))) available · \(game.workers.formatted()) \(game.workers == 1 ? "worker" : "workers")")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(GameActionStyle())
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("THE NEXT SHIFT")
                        .font(.caption2.weight(.bold)).tracking(2)
                        .foregroundStyle(GamePalette.floor)
                    Button(action: onChallenge) {
                        let challengeLayout = dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 18))
                            : AnyLayout(HStackLayout(alignment: .top, spacing: 18))
                        challengeLayout {
                            Image(systemName: "shippingbox.and.arrow.backward.fill")
                                .font(.title)
                                .foregroundStyle(GamePalette.orange)
                                .padding(12)
                                .background(GamePalette.ink, in: RoundedRectangle(cornerRadius: 14))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("Holiday Rush")
                                        .font(.system(.title2, design: .rounded, weight: .bold))
                                    Spacer(minLength: 8)
                                    Image(systemName: "arrow.up.right")
                                        .font(.headline)
                                }
                                Text(challenge.eventAvailable ? "12-minute dispatch challenge" : "Free practice · 12 minutes")
                                    .font(.subheadline)
                                    .foregroundStyle(GamePalette.floor)
                                Text(challengeSummary)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let best = challenge.bestResult {
                                    Text("Best finish · \(timeLabel(best.elapsed))")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(GamePalette.floor)
                                }
                                Label(challengeAction, systemImage: "play.fill")
                                    .font(.headline)
                                    .padding(.top, 3)
                            }
                            .padding(.vertical, 6)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 12)
            }
            .padding(24)
            .frame(maxWidth: 780)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(GamePalette.ink)
        .background(GamePalette.label.ignoresSafeArea())
    }

    private var challengeSummary: String {
        if let result = challenge.result ?? (challenge.hasRun ? nil : challenge.lastResult) {
            if result.outcome == .success {
                return "Challenge complete · \(result.packages.formatted()) packages in \(timeLabel(result.elapsed))"
            }
            return "Last attempt · \(result.packages.formatted()) / 1,500 packages"
        }
        if challenge.hasRun {
            return "\(challenge.isRunning ? "In progress" : "Paused") · \(challenge.game.totalPackagesShipped.formatted()) packages · \(timeLabel(challenge.remaining)) left"
        }
        return "A busy floor. A ticking clock. A team counting on you."
    }

    private var challengeAction: String {
        if challenge.result != nil { return "View result" }
        return challenge.hasRun ? "Return to challenge" : "Explore Holiday Rush"
    }

    private func timeLabel(_ seconds: Double) -> String {
        let value = Int(ceil(max(0, seconds)))
        return "\(value / 60):\(String(format: "%02d", value % 60))"
    }
}
