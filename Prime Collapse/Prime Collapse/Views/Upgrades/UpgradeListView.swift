import SwiftUI

// Horizontal scrolling list of available upgrades
struct UpgradeListView: View {
    var gameState: GameState
    @State private var showDetailedUpgrades = false
    
    // Filter available upgrades based on purchase status
    private var availableUpgrades: [Upgrade] {
        UpgradeManager.availableUpgrades.filter { upgrade in
            // Keep all repeatable upgrades and non-repeatable ones that haven't been purchased
            upgrade.isRepeatable || !gameState.hasBeenPurchased(upgrade)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Upgrades header with ribbon effect
            ZStack {
                // Ribbon background
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 220, y: 0))
                    path.addLine(to: CGPoint(x: 200, y: 30))
                    path.addLine(to: CGPoint(x: 220, y: 60))
                    path.addLine(to: CGPoint(x: 0, y: 60))
                    path.closeSubpath()
                }
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 220, y: 0))
                        path.addLine(to: CGPoint(x: 200, y: 30))
                        path.addLine(to: CGPoint(x: 220, y: 60))
                        path.addLine(to: CGPoint(x: 0, y: 60))
                        path.closeSubpath()
                    }
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 3)
                
                // Heading with button
                HStack {
                    Text("UPGRADES")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1)
                        .padding(.leading, 16)
                    
                    Spacer()
                    
                    Button(action: {
                        showDetailedUpgrades = true
                    }) {
                        Text("MORE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.trailing, 24)
                }
                .frame(width: 220, height: 60)
            }
            .frame(height: 60)
            .padding(.leading)
            
            // Upgrade cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableUpgrades, id: \.id) { upgrade in
                        UpgradeCardView(upgrade: upgrade, gameState: gameState)
                            .shadow(color: .black.opacity(0.2), radius: 3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showDetailedUpgrades) {
            UpgradeScreenView(gameState: gameState)
        }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        UpgradeListView(gameState: GameState())
    }
} 