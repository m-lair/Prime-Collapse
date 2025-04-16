import SwiftUI

// Card view for an individual upgrade
struct UpgradeCardView: View {
    let upgrade: Upgrade
    var gameState: GameState
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title area with ethics indicator
            HStack {
                Text(upgrade.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                if upgrade.moralImpact > 0 {
                    // Ethics impact indicator
                    HStack(spacing: 2) {
                        ForEach(0..<min(5, Int(upgrade.moralImpact)), id: \.self) { _ in
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(ethicsImpactColor)
                        }
                    }
                }
            }
            
            // Description
            Text(upgrade.description)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 50, alignment: .top)
            
            Spacer()
            
            // Price and buy button
            HStack {
                // Price tag with coin icon
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("\(Int(upgrade.cost))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(gameState.canAfford(upgrade.cost) ? .white : .white.opacity(0.5))
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
                                    gameState.canAfford(upgrade.cost) 
                                    ? Color.green 
                                    : Color.gray.opacity(0.5)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        )
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                }
                .disabled(!gameState.canAfford(upgrade.cost))
            }
        }
        .padding(12)
        .frame(width: 180, height: 165)
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
    UpgradeCardView(upgrade: UpgradeManager.availableUpgrades.first!, gameState: GameState())
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.blue.opacity(0.3))
} 