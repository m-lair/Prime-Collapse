import SwiftUI

struct DispatchHUD: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let game: GameState
    var remaining: Double? = nil
    var isRunning = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let remaining {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) { objective(remaining) }
                    VStack(alignment: .leading, spacing: 8) { objective(remaining) }
                }
                ProgressView(value: min(Double(game.totalPackagesShipped), 1500), total: 1500)
                    .tint(GamePalette.orange)
                    .accessibilityLabel("Package goal")
                    .accessibilityValue("\(game.totalPackagesShipped) of 1,500 packages")
            }
            let columns = Array(repeating: GridItem(.flexible(), alignment: .leading), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                metric("AVAILABLE", value: game.money.formatted(.currency(code: "USD").precision(.fractionLength(0))), symbol: "dollarsign.circle")
                metric("AUTOMATIC / SEC", value: game.automaticPackagesPerSecond.formatted(.number.precision(.fractionLength(0...2))), symbol: "gearshape.2")
            }
            Divider().overlay(GamePalette.label.opacity(0.12))
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                health("Morale", value: game.workerMorale, label: "\(Int(game.workerMorale * 100))%", symbol: "person.2")
                health("Ethics", value: game.ethicsScore / 100, label: "\(Int(game.ethicsScore))", symbol: "scale.3d")
            }
            if remaining != nil {
                Text("Finish with ethics ≥ 40 and morale ≥ 40%")
                    .font(.caption).foregroundStyle(GamePalette.label.opacity(0.75))
            }
        }
        .foregroundStyle(GamePalette.label)
    }

    @ViewBuilder private func objective(_ seconds: Double) -> some View {
        Text("GOAL  /  1,500 PACKAGES")
            .font(.caption.weight(.bold)).tracking(1)
        Spacer(minLength: 0)
        Label("\(timeLabel(seconds)) \(isRunning ? "left" : "paused")", systemImage: isRunning ? "timer" : "pause.circle")
            .font(.system(.headline, design: .rounded)).monospacedDigit()
            .foregroundStyle(GamePalette.orange)
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold)).foregroundStyle(GamePalette.label.opacity(0.7))
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold)).monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func health(_ title: String, value: Double, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(title, systemImage: symbol)
                Spacer(minLength: 4)
                Text(label).bold().monospacedDigit()
            }
            .font(.subheadline)
            ProgressView(value: min(1, max(0, value)))
                .tint(value < 0.4 ? GamePalette.orange : GamePalette.teal)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(label)
    }

    private func timeLabel(_ seconds: Double) -> String {
        let value = Int(ceil(max(0, seconds)))
        return "\(value / 60):\(String(format: "%02d", value % 60))"
    }
}
