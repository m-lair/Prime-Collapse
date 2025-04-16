import SwiftUI

// Shows the main game stats
struct GameStatsView: View {
    var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Packages info
                StatCard(
                    icon: "shippingbox.fill",
                    title: "Packages",
                    value: "\(gameState.totalPackagesShipped)",
                    iconColor: .yellow
                )
                
                // Money info
                StatCard(
                    icon: "dollarsign.circle.fill",
                    title: "Money",
                    value: "$\(String(format: "%.2f", gameState.money))",
                    iconColor: .green
                )
            }
            
            if gameState.workers > 0 || gameState.moralDecay > 0 {
                HStack(spacing: 16) {
                    // Workers info (only show if we have workers)
                    if gameState.workers > 0 {
                        StatCard(
                            icon: "person.fill",
                            title: "Workers",
                            value: "\(gameState.workers)",
                            secondaryText: "\(String(format: "%.1f", gameState.automationRate))/sec",
                            iconColor: .blue
                        )
                    }
                    
                    // Moral decay indicator (only show if > 0)
                    if gameState.moralDecay > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(moralDecayColor)
                                    .font(.system(size: 14, weight: .bold))
                                
                                Text("Ethics")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            ProgressView(value: gameState.moralDecay, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: moralDecayColor))
                                .frame(height: 8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(moralDecayColor.opacity(0.5), lineWidth: 1.5)
                                )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
    
    private var moralDecayColor: Color {
        switch gameState.moralDecay {
        case 0..<30:
            return .green
        case 30..<60:
            return .yellow
        case 60..<90:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    GameStatsView(gameState: GameState())
} 