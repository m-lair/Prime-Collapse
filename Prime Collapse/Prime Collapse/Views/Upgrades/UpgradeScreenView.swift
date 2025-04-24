import SwiftUI

// Detailed upgrade screen
struct UpgradeScreenView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.dismiss) private var dismiss
    @State private var hasPerformedLogging = false
    
    // Filter available upgrades based on purchase status (NOT lock status)
    private var potentiallyAvailableUpgrades: [Upgrade] {
        let upgrades = UpgradeManager.availableUpgrades.filter { upgrade in
            // Keep all repeatable upgrades and non-repeatable ones that haven't been purchased yet.
            // Lock status handled in DetailedUpgradeRow.
            if upgrade.isRepeatable {
                return true
            } else {
                let purchased = gameState.hasBeenPurchased(upgrade)
                if purchased && !hasPerformedLogging {
                    print("UpgradeScreenView - Filtering out purchased upgrade: \(upgrade.name) with ID \(upgrade.id)")
                }
                return !purchased
            }
        }
        
        return upgrades
    }
    
    // Filter to show only purchased non-repeatable upgrades
    private var purchasedNonRepeatableUpgrades: [Upgrade] {
        let upgrades = UpgradeManager.availableUpgrades.filter { upgrade in
            let purchased = !upgrade.isRepeatable && gameState.hasBeenPurchased(upgrade)
            return purchased
        }
        
        return upgrades
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
                        if !potentiallyAvailableUpgrades.isEmpty {
                            UpgradeSection(title: "Available Upgrades") {
                                VStack(spacing: 12) {
                                    ForEach(potentiallyAvailableUpgrades, id: \.id) { upgrade in
                                        DetailedUpgradeRow(upgrade: upgrade)
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
                                        
                                        // Display ethics score (0-100)
                                        Text("\(Int(gameState.ethicsScore))/100")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(ethicsScoreColor)
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
                                                    gradient: Gradient(colors: [ethicsScoreColor.opacity(0.7), ethicsScoreColor]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(CGFloat(gameState.ethicsScore) / 100.0 * UIScreen.main.bounds.width * 0.85, 10), height: 12)
                                    }
                                }
                                
                                // Warning messages (inverted logic)
                                if gameState.ethicsScore < 50 {
                                    StatusTag(
                                        icon: "exclamationmark.triangle",
                                        text: "Warning: Corporate ethics declining",
                                        color: .orange
                                    )
                                }
                                
                                if gameState.ethicsScore < 20 {
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
        .onAppear {
            // Perform logging when the view appears
            performLogging()
        }
    }
    
    // Separate method for logging to avoid state modification during view rendering
    private func performLogging() {
        if !hasPerformedLogging {
            // Set state before logging to prevent multiple logs
            hasPerformedLogging = true
            
            // Log available upgrades
            let availableCount = potentiallyAvailableUpgrades.count
            print("UpgradeScreenView - Available upgrades: \(availableCount)")
            
            // Log purchased non-repeatable upgrades
            let purchasedCount = purchasedNonRepeatableUpgrades.count
            print("UpgradeScreenView - Purchased non-repeatable upgrades: \(purchasedCount)")
            
            // Log found purchased upgrades
            for upgrade in purchasedNonRepeatableUpgrades {
                print("UpgradeScreenView - Found purchased upgrade: \(upgrade.name) with ID \(upgrade.id)")
            }
        }
    }
    
    // Renamed color calculation with inverted logic
    private var ethicsScoreColor: Color {
        switch gameState.ethicsScore {
        case 70...100:
            return .green
        case 40..<70:
            return .yellow
        case 20..<40:
            return .orange
        default: // Below 20
            return .red
        }
    }
    
    // Color for purchased upgrades (based on *inverted* moralImpact)
    private func purchasedUpgradeColor(for upgrade: Upgrade) -> Color {
        if upgrade.moralImpact < -5 { // Unethical upgrades (large negative impact)
            return Color(red: 0.5, green: 0.2, blue: 0.5) // Unethical is purple
        } else if upgrade.moralImpact > 5 { // Ethical upgrades (large positive impact)
            return Color.mint // Ethical is mint
        } else {
            return Color(red: 0.3, green: 0.4, blue: 0.6) // Neutral/minor impact is blue-ish
        }
    }
}

#Preview {
    UpgradeScreenView()
        .environment(GameState())
} 