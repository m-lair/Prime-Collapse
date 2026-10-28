import SwiftUI

struct DispatchHUD: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let game: GameState
    var remaining: Double? = nil
    var isRunning = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let remaining {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("HOLIDAY RUSH")
                            .font(.caption2.weight(.bold)).tracking(1.5)
                        Text("\(game.totalPackagesShipped.formatted()) / 1,500 packages")
                            .font(.headline)
                    }
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(timeLabel(remaining))
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .monospacedDigit()
                        Text(isRunning ? "remaining" : "paused")
                            .font(.caption)
                    }
                }
                .foregroundStyle(GamePalette.label)
                ProgressView(value: min(Double(game.totalPackagesShipped), 1500), total: 1500)
                    .tint(GamePalette.orange)
                    .accessibilityLabel("Package goal")
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 280 : 130), alignment: .leading)], alignment: .leading, spacing: 14) {
                metric("Balance", value: game.money.formatted(.currency(code: "USD").precision(.fractionLength(0))), symbol: "dollarsign.circle")
                metric("Packages", value: game.totalPackagesShipped.formatted(), symbol: "shippingbox")
                metric("Workforce", value: "\(game.workers.formatted()) · \(Int(game.workerMorale * 100))% morale", symbol: "person.2", color: GamePalette.teal)
                metric("Automatic", value: "\(game.automaticPackagesPerSecond.formatted(.number.precision(.fractionLength(1)))) / sec", symbol: "gearshape.2")
            }
            HStack(spacing: 6) {
                Image(systemName: "scale.3d")
                Text("Ethics \(Int(game.ethicsScore)) / 100")
                if remaining != nil {
                    Text("· Goal: 40 ethics & 40% morale")
                }
            }
            .font(.caption)
            .foregroundStyle(GamePalette.label.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(GamePalette.ink)
    }

    private func metric(_ title: String, value: String, symbol: String, color: Color = GamePalette.label) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(GamePalette.label.opacity(0.75))
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func timeLabel(_ seconds: Double) -> String {
        let value = Int(ceil(max(0, seconds)))
        return "\(value / 60):\(String(format: "%02d", value % 60))"
    }
}
