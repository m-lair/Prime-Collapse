import SwiftUI

// MARK: - Detailed Stats Overlay View

struct DetailedStatsOverlayView: View {
    @Environment(GameState.self) private var gameState
    @Binding var isPresented: Bool
    
    // State for handling drag gesture
    @State private var dragOffset: CGFloat = 0
    private let dismissThreshold: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 8) {
            // Drag indicator
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .cornerRadius(2.5)
                .padding(.vertical, 8)
            
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
                // Corporate ethics (Renamed to Ethics)
                StatCard(
                    icon: ethicsIcon, // Use ethicsIcon
                    title: "Ethics",  // Use "Ethics"
                    value: ethicsRating.rawValue, // Use ethicsRating
                    secondaryText: "\(String(format: "%.0f", gameState.ethicsScore))/100", // Show score
                    iconColor: ethicsRating.color // Use ethicsRating color
                )
                
                // Effective automation rate
                let workerContribution = gameState.baseWorkerRate * Double(gameState.workers) * gameState.workerEfficiency
                let systemContribution = gameState.baseSystemRate * gameState.automationEfficiency
                let effectiveRate = workerContribution + systemContribution
                StatCard(
                    icon: "bolt.horizontal.fill",
                    title: "Effective Rate",
                    value: "\(String(format: "%.2f", effectiveRate))/sec",
                    secondaryText: "$\(String(format: "%.2f", effectiveRate * gameState.packageValue))/sec",
                    iconColor: .orange
                )
            }
        }
        .padding() // Add padding around the content
        .background(.ultraThinMaterial) // Use a material background
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 5)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only track upward drag movement
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    // If dragged past threshold, dismiss the view
                    if dragOffset > dismissThreshold {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = UIScreen.main.bounds.height
                        }
                        
                        // Dismiss after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
                            dragOffset = 0 // Reset for next time
                        }
                    } else {
                        // Spring back to original position
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .transition(.move(edge: .bottom))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPresented)
    }
    
    // Helper methods for detailed stats
    
    private var workerEfficiencyLabel: String {
        if gameState.workerEfficiency < 1.0 { return "Poor Performance" }
        else if gameState.workerEfficiency < 1.5 { return "Standard Output" }
        else if gameState.workerEfficiency < 2.0 { return "High Productivity" }
        else { return "Maximum Output" }
    }
    
    private var moraleLabel: String {
        if gameState.workerMorale < 0.3 { return "Near Rebellion" }
        else if gameState.workerMorale < 0.5 { return "Discontent" }
        else if gameState.workerMorale < 0.7 { return "Neutral" }
        else if gameState.workerMorale < 0.9 { return "Satisfied" }
        else { return "Highly Motivated" }
    }
    
    private var moraleRatingText: String {
        if gameState.workerMorale < 0.3 { return "Very Low" }
        else if gameState.workerMorale < 0.5 { return "Low" }
        else if gameState.workerMorale < 0.7 { return "Moderate" }
        else if gameState.workerMorale < 0.9 { return "High" }
        else { return "Excellent" }
    }
    
    private var moraleColor: Color {
        if gameState.workerMorale < 0.3 { return .red }
        else if gameState.workerMorale < 0.5 { return .orange }
        else if gameState.workerMorale < 0.7 { return .yellow }
        else if gameState.workerMorale < 0.9 { return .green }
        else { return .mint }
    }
    
    private var customerSatisfactionLabel: String {
        if gameState.customerSatisfaction < 0.3 { return "Outraged" }
        else if gameState.customerSatisfaction < 0.5 { return "Dissatisfied" }
        else if gameState.customerSatisfaction < 0.7 { return "Acceptable" }
        else if gameState.customerSatisfaction < 0.9 { return "Satisfied" }
        else { return "Delighted" }
    }
    
    private var customerSatisfactionRatingText: String {
        if gameState.customerSatisfaction < 0.3 { return "Very Poor" }
        else if gameState.customerSatisfaction < 0.5 { return "Poor" }
        else if gameState.customerSatisfaction < 0.7 { return "Adequate" }
        else if gameState.customerSatisfaction < 0.9 { return "Good" }
        else { return "Excellent" }
    }
    
    private var customerSatisfactionColor: Color {
        if gameState.customerSatisfaction < 0.3 { return .red }
        else if gameState.customerSatisfaction < 0.5 { return .orange }
        else if gameState.customerSatisfaction < 0.7 { return .yellow }
        else if gameState.customerSatisfaction < 0.9 { return .green }
        else { return .mint }
    }
    
    // Ethics logic
    
    private var ethicsRating: EthicsRating {
        switch gameState.ethicsScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .neutral
        case 20..<40: return .concerning
        case 1..<20: return .poor
        default: return .critical // Handles 0 or less
        }
    }
    
    private var ethicsIcon: String {
        switch ethicsRating {
        case .excellent, .good: return "checkmark.circle.fill"
        case .neutral: return "equal.circle.fill"
        case .concerning: return "exclamationmark.triangle.fill"
        case .poor, .critical: return "xmark.circle.fill"
        }
    }
    
    // EthicsRating enum
    enum EthicsRating: String {
        case excellent = "Excellent"
        case good = "Good"
        case neutral = "Neutral"
        case concerning = "Concerning"
        case poor = "Poor"
        case critical = "Critical" // Added for completeness
        
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