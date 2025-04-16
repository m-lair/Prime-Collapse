import SwiftUI

// Dashboard view showing game statistics and progress
struct DashboardView: View {
    var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @Environment(GameCenterManager.self) private var gameCenterManager
    
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
            
            // Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("CORPORATE DASHBOARD")
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
                
                // Dashboard content
                ScrollView {
                    VStack(spacing: 20) {
                        // Game Center section
                        DashboardSection(title: "Game Center") {
                            GameCenterView()
                                .padding(.horizontal)
                        }
                        
                        // Game Statistics
                        DashboardSection(title: "Game Statistics") {
                            // Packages
                            HStack {
                                DashboardStatCard(
                                    icon: "shippingbox.fill",
                                    title: "Total Packages",
                                    value: "\(gameState.totalPackagesShipped)",
                                    iconColor: .yellow
                                )
                                
                                DashboardStatCard(
                                    icon: "dollarsign.circle.fill",
                                    title: "Current Money",
                                    value: "$\(String(format: "%.2f", gameState.money))",
                                    iconColor: .green
                                )
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                DashboardStatCard(
                                    icon: "person.3.fill",
                                    title: "Workers",
                                    value: "\(gameState.workers)",
                                    iconColor: .blue
                                )
                                
                                DashboardStatCard(
                                    icon: "speedometer",
                                    title: "Automation Rate",
                                    value: "\(String(format: "%.1f", gameState.automationRate))/sec",
                                    iconColor: .purple
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Corporate Ethics
                        DashboardSection(title: "Corporate Ethics") {
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
                                .padding(.horizontal)
                                
                                // Status indicator
                                HStack {
                                    if gameState.moralDecay < 50 {
                                        StatusTag(
                                            icon: "checkmark.circle.fill",
                                            text: "Ethical Corporation",
                                            color: .green
                                        )
                                    } else if gameState.moralDecay < 80 {
                                        StatusTag(
                                            icon: "exclamationmark.triangle.fill",
                                            text: "Ethics Declining",
                                            color: .orange
                                        )
                                    } else {
                                        StatusTag(
                                            icon: "xmark.circle.fill",
                                            text: "Critical Ethics Failure",
                                            color: .red
                                        )
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Path Progress
                        DashboardSection(title: "Available Endings") {
                            VStack(spacing: 16) {
                                // Reform path
                                EndingPathCard(
                                    title: "Corporate Reform Ending",
                                    description: "Build a successful company while maintaining ethical standards.",
                                    color: .green,
                                    icon: "leaf.fill",
                                    requirements: [
                                        RequirementItem(
                                            title: "Ethical Choices",
                                            value: "\(gameState.ethicalChoicesMade)/5",
                                            isMet: gameState.ethicalChoicesMade >= 5
                                        ),
                                        RequirementItem(
                                            title: "Ethics Level",
                                            value: "< 50",
                                            isMet: gameState.moralDecay < 50
                                        ),
                                        RequirementItem(
                                            title: "Money Earned",
                                            value: "> $1,000",
                                            isMet: gameState.money > 1000
                                        )
                                    ]
                                )
                                
                                // Loop path
                                EndingPathCard(
                                    title: "Infinite Loop Ending",
                                    description: "Master the art of extraction without triggering collapse.",
                                    color: .blue,
                                    icon: "infinity",
                                    requirements: [
                                        RequirementItem(
                                            title: "Ethics Level",
                                            value: "Between 70-90",
                                            isMet: (gameState.moralDecay >= 70 && gameState.moralDecay <= 90)
                                        ),
                                        RequirementItem(
                                            title: "Money Earned",
                                            value: "> $2,000",
                                            isMet: gameState.money > 2000
                                        ),
                                        RequirementItem(
                                            title: "Packages Shipped",
                                            value: "> 1,000",
                                            isMet: gameState.totalPackagesShipped > 1000
                                        )
                                    ]
                                )
                                
                                // Collapse path
                                EndingPathCard(
                                    title: "Economic Collapse Ending",
                                    description: "The ultimate result of unchecked corporate greed.",
                                    color: .red,
                                    icon: "chart.line.downtrend.xyaxis",
                                    requirements: [
                                        RequirementItem(
                                            title: "Ethics Level",
                                            value: "> 100",
                                            isMet: gameState.moralDecay > 100
                                        )
                                    ]
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
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
}

#Preview {
    DashboardView(gameState: {
        let state = GameState()
        state.totalPackagesShipped = 523
        state.money = 1250
        state.workers = 10
        state.moralDecay = 45
        return state
    }())
} 