import SwiftUI

struct EndingProgressView: View {
    @Environment(GameState.self) private var game

    var body: some View {
        VStack(spacing: 12) {
            EndingPathCard(
                title: "Corporate Reform", description: "Grow without sacrificing your values.",
                color: .green, icon: "leaf.fill", requirements: [
                    RequirementItem(title: "Positive choices", value: "\(game.ethicalChoicesMade)/\(GameState.EndingPolicy.reformChoices)",
                                    isMet: game.ethicalChoicesMade >= GameState.EndingPolicy.reformChoices),
                    RequirementItem(title: "Ethics", value: "\(Int(game.ethicsScore))/\(Int(GameState.EndingPolicy.reformEthics)) minimum",
                                    isMet: game.ethicsScore >= GameState.EndingPolicy.reformEthics),
                    earningsRequirement(GameState.EndingPolicy.reformEarnings)
                ])
            EndingPathCard(
                title: "The Loop", description: "Hold a fragile company together for one minute.",
                color: .orange, icon: "arrow.trianglehead.2.clockwise.rotate.90", requirements: [
                    earningsRequirement(GameState.EndingPolicy.loopEarnings),
                    RequirementItem(title: "Packages", value: "\(game.totalPackagesShipped)/\(GameState.EndingPolicy.loopPackages)",
                                    isMet: game.totalPackagesShipped >= GameState.EndingPolicy.loopPackages),
                    RequirementItem(title: "Workers", value: "\(game.workers)/\(GameState.EndingPolicy.loopWorkers) minimum",
                                    isMet: game.workers >= GameState.EndingPolicy.loopWorkers),
                    RequirementItem(title: "Ethics", value: "\(Int(game.ethicsScore)) • stay at 15–25",
                                    isMet: GameState.EndingPolicy.loopEthics.contains(game.ethicsScore)),
                    RequirementItem(title: "Active stability", value: "\(Int(game.loopStabilitySeconds))/\(Int(GameState.EndingPolicy.loopDuration)) sec",
                                    isMet: game.loopStabilityProgress >= 1)
                ])
            Text("Ethics reaching zero causes Collapse. Leaving the Loop's ethics band or dropping below three workers resets its stability timer.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func earningsRequirement(_ target: Double) -> RequirementItem {
        RequirementItem(title: "Total earned", value: "$\(Int(min(game.lifetimeTotalMoneyEarned, 999_999_999)))/$\(Int(target))",
                        isMet: game.lifetimeTotalMoneyEarned >= target)
    }
}
