import SwiftUI

// Shows the main game stats
struct GameStatsView: View {
    @Environment(GameState.self) private var gameState
    @Binding var isShowingDetails: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Packages info
                StatCard(
                    icon: "shippingbox.fill",
                    title: "Packages",
                    value: "\(gameState.totalPackagesShipped)",
                    secondaryText: "$\(String(format: "%.2f", gameState.packageValue)) per pack",
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
            
            // Show ethics if score is not perfect (100) or if workers exist
            if gameState.workers > 0 || gameState.ethicsScore < 100 {
                HStack(spacing: 16) {
                    // Workers info (only show if we have workers)
                    if gameState.workers > 0 {
                        StatCard(
                            icon: "person.fill",
                            title: "Workers",
                            value: "\(gameState.workers)",
                            secondaryText: "\(String(format: "%.2f", effectiveAutomationRate))/sec",
                            iconColor: .blue
                        )
                    }
                    
                    // Ethics rating indicator (only show if score is not perfect)
                    if gameState.ethicsScore < 100 {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: ethicsIcon)
                                    .foregroundColor(ethicsRating.color)
                                    .font(.system(size: 14, weight: .bold))
                                
                                Text("Ethics")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text(ethicsRating.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(ethicsRating.color)
                            }
                            
                            // Progress bar shows ethics score (0-100 scale)
                            ProgressView(value: gameState.ethicsScore / 100.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: ethicsRating.color))
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
                                        .strokeBorder(ethicsRating.color.opacity(0.5), lineWidth: 1.5)
                                )
                        )
                    }
                }
            }
            
            // Detailed stats button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowingDetails.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isShowingDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                    Text(isShowingDetails ? "Hide Details" : "Show Details")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
            
            // Detailed stats content is NOT rendered here anymore.
            // It will be handled by ContentView using the binding.
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
    
    // Calculate the effective automation rate for display
    private var effectiveAutomationRate: Double {
        let workerContribution = gameState.baseWorkerRate * Double(gameState.workers) * gameState.workerEfficiency
        let systemContribution = gameState.baseSystemRate * gameState.automationEfficiency
        return workerContribution + systemContribution
    }
    
    // Ethics rating based on ethics score (inverted logic)
    private var ethicsRating: EthicsRating {
        switch gameState.ethicsScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .neutral
        case 20..<40: return .concerning
        case 1..<20: return .poor
        default: return .critical
        }
    }
    
    // Ethics icon
    private var ethicsIcon: String {
        switch ethicsRating {
        case .excellent, .good: return "checkmark.circle.fill"
        case .neutral: return "equal.circle.fill"
        case .concerning: return "exclamationmark.triangle.fill"
        case .poor, .critical: return "xmark.circle.fill"
        }
    }
    
    // Define EthicsRating here if not defined globally
    enum EthicsRating: String {
        case excellent = "Excellent"
        case good = "Good"
        case neutral = "Neutral"
        case concerning = "Concerning"
        case poor = "Poor"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .excellent: return .mint
            case .good: return .green
            case .neutral: return .yellow
            case .concerning: return .orange
            case .poor, .critical: return .red
            }       
        }
    }
}

#Preview {
    // Preview needs adjustment to work with @Binding
    struct PreviewWrapper: View {
        @State private var showDetails = false
        var body: some View {
            ZStack {
                Color.blue.opacity(0.5).ignoresSafeArea()
                GameStatsView(isShowingDetails: $showDetails)
                    .environment(GameState())
            }
        }
    }
    return PreviewWrapper()
} 