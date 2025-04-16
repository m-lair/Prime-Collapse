import SwiftUI

// Detailed upgrade screen
struct UpgradeScreenView: View {
    var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    // Filter available upgrades based on purchase status
    private var availableUpgrades: [Upgrade] {
        UpgradeManager.availableUpgrades.filter { upgrade in
            // Keep all repeatable upgrades and non-repeatable ones that haven't been purchased
            upgrade.isRepeatable || !gameState.hasBeenPurchased(upgrade)
        }
    }
    
    // Filter to show only purchased non-repeatable upgrades
    private var purchasedNonRepeatableUpgrades: [Upgrade] {
        UpgradeManager.availableUpgrades.filter { upgrade in
            !upgrade.isRepeatable && gameState.hasBeenPurchased(upgrade)
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.3, blue: 0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Header with title and close button
                HStack {
                    Text("CORPORATE UPGRADES")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // Available upgrades section
                        if !availableUpgrades.isEmpty {
                            UpgradeSection(title: "Available Upgrades") {
                                VStack(spacing: 12) {
                                    ForEach(availableUpgrades, id: \.id) { upgrade in
                                        DetailedUpgradeRow(upgrade: upgrade, gameState: gameState)
                                    }
                                }
                            }
                        }
                        
                        // Purchased upgrades section
                        UpgradeSection(title: "Purchased Upgrades") {
                            if gameState.upgrades.isEmpty && purchasedNonRepeatableUpgrades.isEmpty {
                                HStack {
                                    Spacer()
                                    
                                    Text("No upgrades purchased yet")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .italic()
                                        .padding(20)
                                    
                                    Spacer()
                                }
                            } else {
                                VStack(spacing: 12) {
                                    // Repeatable upgrades
                                    ForEach(gameState.upgrades, id: \.id) { upgrade in
                                        PurchasedUpgradeRow(
                                            name: upgrade.name,
                                            description: upgrade.description,
                                            color: .blue,
                                            isRepeatable: true
                                        )
                                    }
                                    
                                    // Non-repeatable upgrades
                                    ForEach(purchasedNonRepeatableUpgrades, id: \.id) { upgrade in
                                        PurchasedUpgradeRow(
                                            name: upgrade.name,
                                            description: upgrade.description,
                                            color: purchasedUpgradeColor(for: upgrade),
                                            isRepeatable: false
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Corporate ethics impact section
                        UpgradeSection(title: "Corporate Ethics Impact") {
                            VStack(spacing: 15) {
                                // Progress bar
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Ethics Level")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(gameState.moralDecay))/100")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(moralDecayColor)
                                    }
                                    
                                    // Styled progress bar
                                    ZStack(alignment: .leading) {
                                        // Background
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 12)
                                        
                                        // Fill
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [moralDecayColor.opacity(0.7), moralDecayColor]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(CGFloat(gameState.moralDecay) / 100.0 * UIScreen.main.bounds.width * 0.85, 10), height: 12)
                                    }
                                }
                                
                                // Warning messages
                                if gameState.moralDecay > 50 {
                                    StatusTag(
                                        icon: "exclamationmark.triangle",
                                        text: "Warning: Corporate ethics declining",
                                        color: .orange
                                    )
                                }
                                
                                if gameState.moralDecay > 80 {
                                    StatusTag(
                                        icon: "exclamationmark.triangle.fill",
                                        text: "CRITICAL: Economic collapse imminent",
                                        color: .red
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
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
    
    private func purchasedUpgradeColor(for upgrade: Upgrade) -> Color {
        if upgrade.moralImpact > 5 {
            return Color(red: 0.5, green: 0.2, blue: 0.5) // High moral impact is purple
        } else {
            return Color(red: 0.3, green: 0.4, blue: 0.6) // Standard upgrades are blue-ish
        }
    }
}

#Preview {
    UpgradeScreenView(gameState: GameState())
} 