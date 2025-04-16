import SwiftUI

// Card view for an individual upgrade
struct UpgradeCardView: View {
    let upgrade: Upgrade
    var gameState: GameState
    @State private var isPressed = false
    
    // Calculate current price accounting for repeat purchases
    private var currentPrice: Double {
        return gameState.getCurrentUpgradeCost(upgrade)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title area with ethics indicator
            VStack(alignment: .leading) {
                Text(upgrade.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Ethics impact indicator
                HStack(spacing: 2) {
                    if upgrade.moralImpact > 0 {
                        // Unethical indicators (red/orange/yellow triangles)
                        let (color, count) = ethicsIndicatorDetails(for: upgrade.moralImpact)
                        ForEach(0..<count, id: \.self) { _ in
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(color)
                        }
                    } else if upgrade.moralImpact < 0 {
                        // Ethical indicators (green leaves)
                        let (_, count) = ethicsIndicatorDetails(for: upgrade.moralImpact)
                        ForEach(0..<count, id: \.self) { _ in
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                        }
                    } else {
                        // Neutral indicator (optional, could be omitted or use a gray circle)
//                        Image(systemName: "circle")
//                           .font(.system(size: 8))
//                           .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            
            // Description
            Text(upgrade.description)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .frame(height: 50, alignment: .top)
            
            Spacer()
            
            // Price and buy button
            HStack {
                // Price tag with coin icon
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("\(Int(currentPrice))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(gameState.canAfford(currentPrice) ? .white : .white.opacity(0.5))
                }
                
                Spacer()
                
                // Buy button
                Button {
                    isPressed = true
                    
                    // Reset animation after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                        gameState.applyUpgrade(upgrade)
                        playHaptic(.light)
                    }
                } label: {
                    Text("BUY")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
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
        .padding(12)
        .frame(width: 230, height: 165)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    cardBackgroundColor.opacity(0.9),
                    cardBackgroundColor.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    private var cardBackgroundColor: Color {
        if upgrade.moralImpact < 0 { // Ethical
            return Color(red: 0.1, green: 0.5, blue: 0.3) // Greenish
        } else if upgrade.moralImpact > 10 { // Very Unethical
             return Color(red: 0.6, green: 0.1, blue: 0.3) // Dark Red/Purple
        } else if upgrade.moralImpact > 0 { // Unethical
            return Color(red: 0.5, green: 0.2, blue: 0.5) // Purple
        } else if upgrade.isRepeatable { // Neutral & Repeatable
            return Color.blue
        } else { // Neutral & Non-Repeatable
            return Color(red: 0.3, green: 0.4, blue: 0.6) // Standard blue-ish
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
    
    // Function kept for reference but logic moved to ethicsIndicatorDetails
//    private var ethicsImpactColor: Color {
//        switch upgrade.moralImpact {
//        case 1...3: return .yellow // Slightly Unethical
//        case 4...7: return .orange // Moderately Unethical
//        case 8...: return .red    // Highly Unethical
//        default: return .clear    // Default case for 0 or negative (ethical)
//        }
//    }
    
    private func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    UpgradeCardView(upgrade: UpgradeManager.availableUpgrades[0], gameState: GameState())
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.blue.opacity(0.3))
} 
