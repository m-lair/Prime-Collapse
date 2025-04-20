import SwiftUI

// Detailed upgrade row
struct DetailedUpgradeRow: View {
    let upgrade: Upgrade
    @Environment(GameState.self) private var gameState
    @State private var isPressed = false
    
    // Check if the upgrade requirements are met
    private var isUnlocked: Bool {
        gameState.isUpgradeUnlocked(upgrade)
    }
    
    // Calculate current price accounting for repeat purchases
    private var currentPrice: Double {
        return gameState.getCurrentUpgradeCost(upgrade)
    }
    
    // Get the requirement description
    private var requirementDescription: String? {
        return gameState.getUpgradeRequirementDescription(upgrade)
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
                        
                        // Ethics impact indicators - CONSISTENT LOGIC
                        HStack(spacing: 2) {
                            let (color, count) = ethicsIndicatorDetails(for: upgrade.moralImpact)
                            // Positive Impact = Ethical (Leaf)
                            if upgrade.moralImpact > 0 { // ETHICAL
                                ForEach(0..<count, id: \.self) { _ in
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(color)
                                }
                            // Negative Impact = Unethical (Triangle)
                            } else if upgrade.moralImpact < 0 { // UNETHICAL
                                ForEach(0..<count, id: \.self) { _ in
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(color)
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
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
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
                    .disabled(!gameState.canAfford(currentPrice) || !isUnlocked)
                }
                .frame(minWidth: 160, alignment: .trailing)
                .layoutPriority(2)
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
                // Add lock overlay if not unlocked
                .overlay(
                    !isUnlocked ? 
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.7)) // Slightly increased opacity
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                if let requirementText = requirementDescription {
                                    Text(requirementText)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                } else {
                                    Text("Locked")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        )
                    : nil
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.8) // Slightly increased opacity for better readability
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    // Generate a clear description of the upgrade's effects
    private var upgradeEffectDescription: String {
        var effects: [String] = []
        
        // Determine effects based on upgrade name (mirroring GameState.applyUpgrade logic)
        switch upgrade.name {
        case "Hire Worker":
            // Assuming each worker adds 0.1 base rate
            effects.append("+1 Worker")
            effects.append("+0.1 Base Pkg/sec") // Clarify it's the base rate
        case "Improve Packaging":
            effects.append("+20% Automation Eff.")
        case "Basic Training":
            effects.append("+15% Automation Eff.")
            // Add ethics if moralImpact indicates it
            if upgrade.moralImpact != 0 {
                 effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics")
            }
        case "Rush Delivery":
            effects.append("+40% Automation Eff.")
             if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "Extended Shifts":
            effects.append("+60% Automation Eff.")
             if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "Automate Sorting":
            effects.append("+30% Automation Eff.")
            if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "Child Labor Loopholes":
            effects.append("+100% Automation Eff.")
            effects.append("+$200 Bonus")
            if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "Employee Surveillance":
            effects.append("+50% Automation Eff.")
             if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "AI Optimization":
            effects.append("+100% Automation Eff.") // (2x multiplier implied)
            if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "Remove Worker Breaks":
            effects.append("+80% Automation Eff.")
            if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "Sustainable Practices":
            effects.append("+30% Automation Eff.")
            if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "Community Investment Program":
            effects.append("+40% Automation Eff.")
            if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "Worker Replacement System":
            effects.append("+200% Automation Eff.")
            effects.append("Set Workers to 2") // More specific
            if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        case "Algorithmic Wage Suppression":
            effects.append("+70% Automation Eff.")
            effects.append("+$500 Bonus")
            if upgrade.moralImpact != 0 { effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics") }
        default:
            // If other effects exist but aren't named, check moral impact
             if upgrade.moralImpact != 0 {
                 effects.append("\(ethicsChangeText(upgrade.moralImpact)) Ethics")
             } else {
                 // Fallback for unknown upgrades
                 return "Improves corporate metrics" 
             }
        }
        
        // Join the effects with commas
        return effects.joined(separator: ", ")
    }
    
    // Helper to format ethics change text - CONSISTENT LOGIC
    private func ethicsChangeText(_ impact: Double) -> String {
        // Positive impact = ethical = positive score change
        // Negative impact = unethical = negative score change
        let actualEthicsChange = Int(impact) // No longer need to invert
        return String(format: "%@%d", actualEthicsChange >= 0 ? "+" : "", actualEthicsChange)
    }
    
    private var cardBackgroundColor: Color {
        // Use consistent logic: Positive = Ethical (Greenish), Negative = Unethical (Red/Purple)
        let impact = upgrade.moralImpact
        if impact > 8 { // Very Ethical
            return Color(red: 0.1, green: 0.6, blue: 0.4).opacity(0.8) // Brighter Green
        } else if impact > 0 { // Ethical
            return Color(red: 0.1, green: 0.5, blue: 0.3).opacity(0.8) // Greenish
        } else if impact < -15 { // Extremely Unethical
            return Color(red: 0.7, green: 0.1, blue: 0.4).opacity(0.8) // Darker Red/Purple
        } else if impact < -8 { // Very Unethical
            return Color(red: 0.6, green: 0.1, blue: 0.3).opacity(0.8) // Dark Red/Purple
        } else if impact < 0 { // Unethical
            return Color(red: 0.5, green: 0.2, blue: 0.5).opacity(0.8) // Purple
        } else if upgrade.isRepeatable { // Neutral & Repeatable
            return Color.blue.opacity(0.8)
        } else { // Neutral & Non-Repeatable
            return Color(red: 0.3, green: 0.4, blue: 0.6).opacity(0.8) // Standard blue-ish
        }
    }
    
    // Determines color and count for ethics indicators - CONSISTENT LOGIC
    private func ethicsIndicatorDetails(for impact: Double) -> (color: Color, count: Int) {
        if impact > 0 { // ETHICAL
            switch impact {
            case 1...3:   return (.green, 1)
            case 4...7:   return (.green, 2)
            case 8...14:  return (.green, 3)
            default:      return (.cyan, 4) // Very ethical >= 15
            }
        } else if impact < 0 { // UNETHICAL
            let level = abs(impact) // Use absolute value for level calculation
            switch level {
            case 1...3:   return (.yellow, 1)
            case 4...7:   return (.orange, 2)
            case 8...14:  return (.red, 3)
            case 15...24: return (.red.opacity(0.8), 4)
            default:      return (.purple, 5) // Extreme unethical >= 25
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
        DetailedUpgradeRow(upgrade: UpgradeManager.availableUpgrades.first!)
            .environment(GameState())
            .padding()
    }
} 