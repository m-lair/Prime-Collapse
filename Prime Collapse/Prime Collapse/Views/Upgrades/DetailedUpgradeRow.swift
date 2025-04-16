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
                        
                        // Ethics impact indicators
                        HStack(spacing: 2) {
                            let (color, count) = ethicsIndicatorDetails(for: upgrade.moralImpact)
                            if upgrade.moralImpact > 0 { // Unethical
                                ForEach(0..<count, id: \.self) { _ in
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(color)
                                }
                            } else if upgrade.moralImpact < 0 { // Ethical
                                ForEach(0..<count, id: \.self) { _ in
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(color) // Should be green from helper
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
            return "15% automation boost, Ethics +3"
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
            return "30% automation boost, Ethics +8"
        case "Community Investment Program":
            return "40% automation boost, Ethics +12"
        case "Worker Replacement System":
            return "200% automation boost (3x), reduce workers to 2"
        case "Algorithmic Wage Suppression":
            return "70% automation boost, +$500 bonus"
        default:
            return "Improves efficiency"
        }
    }
    
    private var cardBackgroundColor: Color {
        if upgrade.moralImpact < 0 { // Ethical
            return Color(red: 0.1, green: 0.5, blue: 0.3).opacity(0.8) // Greenish
        } else if upgrade.moralImpact > 10 { // Very Unethical
            return Color(red: 0.6, green: 0.1, blue: 0.3).opacity(0.8) // Dark Red/Purple
        } else if upgrade.moralImpact > 0 { // Unethical
            return Color(red: 0.5, green: 0.2, blue: 0.5).opacity(0.8) // Purple
        } else if upgrade.isRepeatable { // Neutral & Repeatable
            return Color.blue.opacity(0.8)
        } else { // Neutral & Non-Repeatable
            return Color(red: 0.3, green: 0.4, blue: 0.6).opacity(0.8) // Standard blue-ish
        }
    }
    
    // Determines color and count for ethics indicators
    private func ethicsIndicatorDetails(for impact: Double) -> (color: Color, count: Int) {
        if impact > 0 { // Unethical
            switch impact {
            case 1...3:   return (.yellow, 1)
            case 4...7:   return (.orange, 2)
            case 8...14:  return (.red, 3)
            case 15...24: return (.red.opacity(0.8), 4) // Darker red for higher impact
            default:      return (.purple, 5) // Max level for extreme impact >= 25
            }
        } else if impact < 0 { // Ethical
            switch abs(impact) {
            case 1...3:   return (.green, 1)
            case 4...7:   return (.green, 2)
            case 8...14:  return (.green.opacity(0.8), 3) // Brighter green for higher impact
            default:      return (.cyan, 4) // Max level for very ethical >= 15
            }
        } else { // Neutral
            return (.gray, 0) // No indicator for neutral
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