import SwiftUI

// Detailed upgrade row
struct DetailedUpgradeRow: View {
    let upgrade: Upgrade
    var gameState: GameState
    @State private var isPressed = false
    
    // Calculate current price accounting for repeat purchases
    private var currentPrice: Double {
        return gameState.getCurrentUpgradeCost(upgrade)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and cost
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Title with ethics indicators
                    HStack {
                        Text(upgrade.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if upgrade.moralImpact > 0 {
                            // Ethics impact indicator
                            HStack(spacing: 2) {
                                ForEach(0..<min(5, Int(upgrade.moralImpact)), id: \.self) { _ in
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(ethicsImpactColor)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Repeatable badge
                        if upgrade.isRepeatable {
                            Text("REPEATABLE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.3))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    
                    // Description
                    Text(upgrade.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Divider
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.white.opacity(0.15))
            
            // Effects and buy button row
            HStack {
                // Effect label
                VStack(alignment: .leading, spacing: 4) {
                    Text("EFFECT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(upgradeEffectDescription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Cost and buy button
                HStack(spacing: 12) {
                    // Cost with coin icon
                    HStack(spacing: 4) {
                        Text("$\(Int(currentPrice))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(gameState.canAfford(currentPrice) ? .white : .white.opacity(0.5))
                    }
                    
                    // Buy button
                    Button {
                        isPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPressed = false
                            gameState.applyUpgrade(upgrade)
                            playHaptic(.light)
                        }
                    } label: {
                        Text("PURCHASE")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        gameState.canAfford(currentPrice) 
                                        ? Color.green 
                                        : Color.gray.opacity(0.5)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                            )
                            .scaleEffect(isPressed ? 0.95 : 1.0)
                    }
                    .disabled(!gameState.canAfford(currentPrice))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            cardBackgroundColor.opacity(0.8),
                            cardBackgroundColor.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    private var upgradeEffectDescription: String {
        switch upgrade.name {
        case "Hire Worker":
            return "+0.1 packages/sec"
        case "Improve Packaging":
            return "20% automation boost"
        case "Basic Training":
            return "15% automation boost, -2 moral decay"
        case "Rush Delivery":
            return "40% automation boost"
        case "Extended Shifts":
            return "60% automation boost"
        case "Automate Sorting":
            return "30% automation boost"
        case "Child Labor Loopholes":
            return "100% automation boost, +$200 bonus"
        case "Employee Surveillance":
            return "50% automation boost"
        case "AI Optimization":
            return "100% automation boost (2x)"
        case "Remove Worker Breaks":
            return "80% automation boost"
        case "Sustainable Practices":
            return "30% automation boost, -5 moral decay"
        case "Community Investment Program":
            return "40% automation boost, -10 moral decay"
        case "Worker Replacement System":
            return "200% automation boost (3x), reduce workers to 2"
        case "Algorithmic Wage Suppression":
            return "70% automation boost, +$500 bonus"
        default:
            return "Improves efficiency"
        }
    }
    
    private var cardBackgroundColor: Color {
        if upgrade.isRepeatable {
            return Color.blue // Repeatable upgrades are blue
        } else if upgrade.moralImpact > 5 {
            return Color(red: 0.5, green: 0.2, blue: 0.5) // High moral impact is purple
        } else {
            return Color(red: 0.3, green: 0.4, blue: 0.6) // Standard upgrades are blue-ish
        }
    }
    
    private var ethicsImpactColor: Color {
        switch upgrade.moralImpact {
        case 0..<3:
            return .yellow
        case 3..<7:
            return .orange
        default:
            return .red
        }
    }
    
    private func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        DetailedUpgradeRow(upgrade: UpgradeManager.availableUpgrades.first!, gameState: GameState())
            .padding()
    }
} 