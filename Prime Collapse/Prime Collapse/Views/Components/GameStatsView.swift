import SwiftUI

// Shows the main game stats
struct GameStatsView: View {
    var gameState: GameState
    @State private var showDetailedStats = false
    
    // Ethics rating enum for better readability
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
                            secondaryText: "\(String(format: "%.1f", gameState.automationRate))/sec",
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
                showDetailedStats.toggle()
            }) {
                HStack {
                    Image(systemName: showDetailedStats ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                    Text(showDetailedStats ? "Hide Details" : "Show Details")
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
            
            // Detailed game stats
            if showDetailedStats {
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        // Worker metrics
                        StatCard(
                            icon: "gauge.medium",
                            title: "Worker Efficiency",
                            value: "\(String(format: "%.2f", gameState.workerEfficiency))×",
                            secondaryText: workerEfficiencyLabel,
                            iconColor: .indigo
                        )
                        
                        // Automation metrics
                        StatCard(
                            icon: "gearshape.2.fill",
                            title: "Automation",
                            value: "\(String(format: "%.2f", gameState.automationEfficiency))×",
                            secondaryText: "Efficiency Multiplier",
                            iconColor: .mint
                        )
                    }
                    
                    HStack(spacing: 16) {
                        // Worker morale
                        StatCard(
                            icon: "face.smiling.fill",
                            title: "Worker Morale",
                            value: moraleRatingText,
                            secondaryText: moraleLabel,
                            iconColor: moraleColor
                        )
                        
                        // Customer satisfaction
                        StatCard(
                            icon: "person.crop.circle.badge.checkmark",
                            title: "Customer Sat.",
                            value: customerSatisfactionRatingText,
                            secondaryText: customerSatisfactionLabel,
                            iconColor: customerSatisfactionColor
                        )
                    }
                    
                    // Corporate ethics and effective rate
                    HStack(spacing: 16) {
                        // Corporate ethics
                        StatCard(
                            icon: "building.2.fill",
                            title: "Corp Virtue",
                            value: corporateVirtueRatingText,
                            secondaryText: corporateEthicsLabel,
                            iconColor: corporateEthicsColor
                        )
                        
                        // Effective automation rate
                        let effectiveRate = gameState.automationRate * gameState.workerEfficiency * gameState.automationEfficiency
                        StatCard(
                            icon: "bolt.horizontal.fill",
                            title: "Effective Rate",
                            value: "\(String(format: "%.2f", effectiveRate))/sec",
                            secondaryText: "$\(String(format: "%.2f", effectiveRate * gameState.packageValue))/sec",
                            iconColor: .orange
                        )
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showDetailedStats)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
    
    // Ethics rating based on ethics score (inverted logic)
    private var ethicsRating: EthicsRating {
        switch gameState.ethicsScore {
        case 80...100:
            return .excellent
        case 60..<80:
            return .good
        case 40..<60:
            return .neutral
        case 20..<40:
            return .concerning
        case 1..<20: // Changed from 80..<100
            return .poor
        default: // 0 or less
            return .critical
        }
    }
    
    // Ethics icon
    private var ethicsIcon: String {
        switch ethicsRating {
        case .excellent, .good:
            return "checkmark.circle.fill"
        case .neutral:
            return "equal.circle.fill"
        case .concerning:
            return "exclamationmark.triangle.fill"
        case .poor, .critical:
            return "xmark.circle.fill"
        }
    }
    
    // Helper methods for labels and colors
    private var workerEfficiencyLabel: String {
        if gameState.workerEfficiency < 1.0 {
            return "Poor Performance"
        } else if gameState.workerEfficiency < 1.5 {
            return "Standard Output"
        } else if gameState.workerEfficiency < 2.0 {
            return "High Productivity"
        } else {
            return "Maximum Output"
        }
    }
    
    private var moraleLabel: String {
        if gameState.workerMorale < 0.3 {
            return "Near Rebellion"
        } else if gameState.workerMorale < 0.5 {
            return "Discontent"
        } else if gameState.workerMorale < 0.7 {
            return "Neutral"
        } else if gameState.workerMorale < 0.9 {
            return "Satisfied"
        } else {
            return "Highly Motivated"
        }
    }
    
    // Morale rating text
    private var moraleRatingText: String {
        if gameState.workerMorale < 0.3 {
            return "Very Low"
        } else if gameState.workerMorale < 0.5 {
            return "Low"
        } else if gameState.workerMorale < 0.7 {
            return "Moderate"
        } else if gameState.workerMorale < 0.9 {
            return "High"
        } else {
            return "Excellent"
        }
    }
    
    private var moraleColor: Color {
        if gameState.workerMorale < 0.3 {
            return .red
        } else if gameState.workerMorale < 0.5 {
            return .orange
        } else if gameState.workerMorale < 0.7 {
            return .yellow
        } else if gameState.workerMorale < 0.9 {
            return .green
        } else {
            return .mint
        }
    }
    
    private var customerSatisfactionLabel: String {
        if gameState.customerSatisfaction < 0.3 {
            return "Outraged"
        } else if gameState.customerSatisfaction < 0.5 {
            return "Dissatisfied"
        } else if gameState.customerSatisfaction < 0.7 {
            return "Acceptable"
        } else if gameState.customerSatisfaction < 0.9 {
            return "Satisfied"
        } else {
            return "Delighted"
        }
    }
    
    // Customer satisfaction rating text
    private var customerSatisfactionRatingText: String {
        if gameState.customerSatisfaction < 0.3 {
            return "Very Poor"
        } else if gameState.customerSatisfaction < 0.5 {
            return "Poor"
        } else if gameState.customerSatisfaction < 0.7 {
            return "Adequate"
        } else if gameState.customerSatisfaction < 0.9 {
            return "Good"
        } else {
            return "Excellent"
        }
    }
    
    private var customerSatisfactionColor: Color {
        if gameState.customerSatisfaction < 0.3 {
            return .red
        } else if gameState.customerSatisfaction < 0.5 {
            return .orange
        } else if gameState.customerSatisfaction < 0.7 {
            return .yellow
        } else if gameState.customerSatisfaction < 0.9 {
            return .green
        } else {
            return .mint
        }
    }
    
    private var corporateEthicsLabel: String {
        if gameState.corporateEthics < 0.3 {
            return "Corruption"
        } else if gameState.corporateEthics < 0.5 {
            return "Shady Practices"
        } else if gameState.corporateEthics < 0.7 {
            return "Standard Business"
        } else if gameState.corporateEthics < 0.9 {
            return "Ethical Business"
        } else {
            return "Industry Leader"
        }
    }
    
    // Corporate ethics (virtue) rating text
    private var corporateVirtueRatingText: String {
        if gameState.corporateEthics < 0.3 {
            return "Very Low"
        } else if gameState.corporateEthics < 0.5 {
            return "Low"
        } else if gameState.corporateEthics < 0.7 {
            return "Moderate"
        } else if gameState.corporateEthics < 0.9 {
            return "High"
        } else {
            return "Exemplary"
        }
    }
    
    private var corporateEthicsColor: Color {
        if gameState.corporateEthics < 0.3 {
            return .red
        } else if gameState.corporateEthics < 0.5 {
            return .orange
        } else if gameState.corporateEthics < 0.7 {
            return .yellow
        } else if gameState.corporateEthics < 0.9 {
            return .green
        } else {
            return .mint
        }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.5).ignoresSafeArea()
        GameStatsView(gameState: GameState())
    }
} 