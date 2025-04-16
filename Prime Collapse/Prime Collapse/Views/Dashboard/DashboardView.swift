import SwiftUI

// Dashboard view showing game statistics and progress
struct DashboardView: View {
    var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @Environment(GameCenterManager.self) private var gameCenterManager
    
    // Ethics rating enum for better readability
    enum EthicsRating: String {
        case excellent = "Excellent"
        case good = "Good"
        case neutral = "Neutral"
        case concerning = "Concerning"
        case poor = "Poor"
        case critical = "Critical"
        
        var description: String {
            switch self {
            case .excellent:
                return "Industry-leading ethical standards and practices"
            case .good:
                return "Strong ethical foundation with positive societal impact"
            case .neutral:
                return "Standard business practices with no major concerns"
            case .concerning:
                return "Some questionable practices that may attract criticism"
            case .poor:
                return "Significantly unethical practices damaging reputation"
            case .critical:
                return "Severely unethical behavior risking systemic collapse"
            }
        }
        
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
                        // Business KPIs
                        DashboardSection(title: "Business Performance") {
                            // Key business metrics
                            VStack(spacing: 10) {
                                HStack {
                                    DashboardStatCard(
                                        icon: "dollarsign.circle.fill",
                                        title: "Revenue",
                                        value: "$\(String(format: "%.2f", gameState.money))",
                                        iconColor: .green
                                    )
                                    
                                    DashboardStatCard(
                                        icon: "shippingbox.fill",
                                        title: "Total Packages",
                                        value: "\(gameState.totalPackagesShipped)",
                                        iconColor: .yellow
                                    )
                                }
                                
                                // Package and delivery metrics
                                HStack {
                                    DashboardStatCard(
                                        icon: "dollarsign.square.fill",
                                        title: "Package Value",
                                        value: "$\(String(format: "%.2f", gameState.packageValue))",
                                        iconColor: .mint
                                    )
                                    
                                    let effectiveRate = gameState.automationRate * gameState.workerEfficiency * gameState.automationEfficiency
                                    DashboardStatCard(
                                        icon: "chart.line.uptrend.xyaxis",
                                        title: "Hourly Income",
                                        value: "$\(String(format: "%.2f", effectiveRate * gameState.packageValue * 3600))",
                                        iconColor: .orange
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Workforce Section
                        DashboardSection(title: "Workforce Analytics") {
                            VStack(spacing: 10) {
                                // Workers and efficiency
                                HStack {
                                    DashboardStatCard(
                                        icon: "person.3.fill",
                                        title: "Workers",
                                        value: "\(gameState.workers)",
                                        iconColor: .blue
                                    )
                                    
                                    DashboardStatCard(
                                        icon: "gauge.medium",
                                        title: "Worker Efficiency",
                                        value: "\(String(format: "%.2f", gameState.workerEfficiency))×",
                                        iconColor: .indigo
                                    )
                                }
                                
                                // Worker morale
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Worker Morale")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(moraleRatingText)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(moraleColor)
                                    }
                                    
                                    // Morale bar
                                    ZStack(alignment: .leading) {
                                        // Background
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 12)
                                        
                                        // Fill
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [moraleColor.opacity(0.7), moraleColor]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(CGFloat(gameState.workerMorale) * UIScreen.main.bounds.width * 0.85, 10), height: 12)
                                    }
                                    
                                    Text(moraleEffectDescription)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                )
                                .padding(.horizontal)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Automation Section
                        DashboardSection(title: "Automation Systems") {
                            VStack(spacing: 10) {
                                // Automation metrics
                                HStack {
                                    DashboardStatCard(
                                        icon: "speedometer",
                                        title: "Base Rate",
                                        value: "\(String(format: "%.1f", gameState.automationRate))/sec",
                                        iconColor: .purple
                                    )
                                    
                                    DashboardStatCard(
                                        icon: "gearshape.2.fill",
                                        title: "Efficiency",
                                        value: "\(String(format: "%.2f", gameState.automationEfficiency))×",
                                        iconColor: .teal
                                    )
                                }
                                
                                // Effective production
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Effective Production")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        let effectiveRate = gameState.automationRate * gameState.workerEfficiency * gameState.automationEfficiency
                                        Text("\(String(format: "%.2f", effectiveRate)) packages/sec")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Factors breakdown
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Base rate: \(String(format: "%.2f", gameState.automationRate)) packages/sec")
                                        Text("Worker efficiency: ×\(String(format: "%.2f", gameState.workerEfficiency))")
                                        Text("Automation efficiency: ×\(String(format: "%.2f", gameState.automationEfficiency))")
                                        Text("Package value: $\(String(format: "%.2f", gameState.packageValue))")
                                        Text("Customer satisfaction: \(Int(gameState.customerSatisfaction * 100))%")
                                        
                                        Divider()
                                            .background(Color.white.opacity(0.3))
                                            .padding(.vertical, 4)
                                        
                                        let incomePerSec = gameState.automationRate * gameState.workerEfficiency * gameState.automationEfficiency * gameState.packageValue * (0.5 + gameState.customerSatisfaction * 0.5)
                                        Text("Income rate: $\(String(format: "%.2f", incomePerSec))/sec")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                )
                                .padding(.horizontal)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Customer Metrics
                        DashboardSection(title: "Customer Metrics") {
                            VStack(spacing: 10) {
                                // Customer satisfaction
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Customer Satisfaction")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(customerSatisfactionRatingText)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(customerSatisfactionColor)
                                    }
                                    
                                    // Satisfaction bar
                                    ZStack(alignment: .leading) {
                                        // Background
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 12)
                                        
                                        // Fill
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [customerSatisfactionColor.opacity(0.7), customerSatisfactionColor]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(CGFloat(gameState.customerSatisfaction) * UIScreen.main.bounds.width * 0.85, 10), height: 12)
                                    }
                                    
                                    Text(customerSatisfactionEffect)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                )
                                .padding(.horizontal)
                            }
                            .padding(.horizontal)
                        }
                        
                        // New Societal Impact Section
                        DashboardSection(title: "Societal Impact") {
                            VStack(spacing: 10) {
                                // Public Perception
                                HStack {
                                    DashboardStatCard(
                                        icon: "person.crop.circle.badge.checkmark",
                                        title: "Public Perception",
                                        value: "\(Int(gameState.publicPerception))/100",
                                        iconColor: publicPerceptionColor
                                    )
                                    
                                    DashboardStatCard(
                                        icon: "leaf.arrow.triangle.circlepath",
                                        title: "Environmental Impact",
                                        value: "\(Int(gameState.environmentalImpact))/100",
                                        iconColor: environmentalImpactColor
                                    )
                                }
                                
                                // Add progress bars or detailed text descriptions if needed
                                // Example for Public Perception:
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Perception Level: \(publicPerceptionText)")
                                        .font(.caption)
                                    ProgressView(value: gameState.publicPerception / 100.0)
                                        .tint(publicPerceptionColor)
                                }
                                .padding(.horizontal)
                                
                                // Example for Environmental Impact:
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Impact Level: \(environmentalImpactText)")
                                        .font(.caption)
                                    ProgressView(value: gameState.environmentalImpact / 100.0)
                                        .tint(environmentalImpactColor)
                                }
                                .padding(.horizontal)
                                
                            }
                            .padding(.horizontal)
                        }
                        
                        // Corporate Ethics
                        DashboardSection(title: "Corporate Ethics") {
                            VStack(spacing: 15) {
                                // Ethics status card
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Ethics Rating")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(ethicsRating.rawValue)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(ethicsRating.color)
                                    }
                                    
                                    // Risk level indicator
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
                                        
                                        // Descriptive markers
                                        HStack(spacing: 0) {
                                            ForEach(0..<5) { i in
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.5))
                                                    .frame(width: 1, height: 8)
                                                    .frame(maxWidth: .infinity)
                                            }
                                        }
                                    }
                                    
                                    // Risk level labels
                                    HStack(spacing: 0) {
                                        Text("Low Risk")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text("Moderate")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        
                                        Text("Collapse Risk")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                    
                                    Text(ethicsRating.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.top, 4)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                )
                                .padding(.horizontal)
                                
                                // Ethical choices and corporate virtue
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ethical Choices Made")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text("\(gameState.ethicalChoicesMade)")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Corporate Virtue")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text(corporateVirtueRatingText)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(corporateEthicsColor)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                                .padding(.horizontal)
                                
                                // Status indicator
                                HStack {
                                    StatusTag(
                                        icon: statusIcon,
                                        text: statusText,
                                        color: ethicsRating.color
                                    )
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Game Center section
                        DashboardSection(title: "Game Center") {
                            GameCenterView()
                                .padding(.horizontal)
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
                                            title: "Ethics Rating",
                                            value: "Good or Better",
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
                                            title: "Ethics Rating",
                                            value: "Concerning",
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
                                            title: "Ethics Rating",
                                            value: "Critical",
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
    
    // Ethics rating based on moral decay
    private var ethicsRating: EthicsRating {
        switch gameState.moralDecay {
        case 0..<20:
            return .excellent
        case 20..<40:
            return .good
        case 40..<60:
            return .neutral
        case 60..<80:
            return .concerning
        case 80..<100:
            return .poor
        default:
            return .critical
        }
    }
    
    // Status icon for the ethics status tag
    private var statusIcon: String {
        switch ethicsRating {
        case .excellent, .good:
            return "checkmark.circle.fill"
        case .neutral:
            return "equal.circle.fill"
        case .concerning:
            return "exclamationmark.triangle.fill"
        case .poor, .critical:
            return "xmark.circle.fill"
        }
    }
    
    // Status text for the ethics status tag
    private var statusText: String {
        switch ethicsRating {
        case .excellent, .good:
            return "Ethical Corporation"
        case .neutral:
            return "Standard Business Practices"
        case .concerning:
            return "Ethics Under Review"
        case .poor:
            return "Ethics Failure"
        case .critical:
            return "Critical Ethics Failure"
        }
    }
    
    // Corporate ethics (virtue) rating text
    private var corporateVirtueRatingText: String {
        if gameState.corporateEthics < 0.3 {
            return "Very Low"
        } else if gameState.corporateEthics < 0.5 {
            return "Low"
        } else if gameState.corporateEthics < 0.7 {
            return "Moderate"
        } else if gameState.corporateEthics < 0.9 {
            return "High"
        } else {
            return "Exemplary"
        }
    }
    
    // Morale rating text
    private var moraleRatingText: String {
        if gameState.workerMorale < 0.3 {
            return "Very Low"
        } else if gameState.workerMorale < 0.5 {
            return "Low"
        } else if gameState.workerMorale < 0.7 {
            return "Moderate"
        } else if gameState.workerMorale < 0.9 {
            return "High"
        } else {
            return "Excellent"
        }
    }
    
    // Customer satisfaction rating text
    private var customerSatisfactionRatingText: String {
        if gameState.customerSatisfaction < 0.3 {
            return "Very Poor"
        } else if gameState.customerSatisfaction < 0.5 {
            return "Poor"
        } else if gameState.customerSatisfaction < 0.7 {
            return "Adequate"
        } else if gameState.customerSatisfaction < 0.9 {
            return "Good"
        } else {
            return "Excellent"
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
    
    private var moraleColor: Color {
        if gameState.workerMorale < 0.3 {
            return .red
        } else if gameState.workerMorale < 0.5 {
            return .orange
        } else if gameState.workerMorale < 0.7 {
            return .yellow
        } else if gameState.workerMorale < 0.9 {
            return .green
        } else {
            return .mint
        }
    }
    
    private var moraleEffectDescription: String {
        if gameState.workerMorale < 0.3 {
            return "Worker efficiency severely reduced, high risk of strikes and resignations."
        } else if gameState.workerMorale < 0.5 {
            return "Worker efficiency reduced, increased turnover and complaints."
        } else if gameState.workerMorale < 0.7 {
            return "Neutral morale, standard worker performance."
        } else if gameState.workerMorale < 0.9 {
            return "Good morale, workers are productive and efficient."
        } else {
            return "Excellent morale, workers are highly motivated and maximally efficient."
        }
    }
    
    private var customerSatisfactionColor: Color {
        if gameState.customerSatisfaction < 0.3 {
            return .red
        } else if gameState.customerSatisfaction < 0.5 {
            return .orange
        } else if gameState.customerSatisfaction < 0.7 {
            return .yellow
        } else if gameState.customerSatisfaction < 0.9 {
            return .green
        } else {
            return .mint
        }
    }
    
    private var customerSatisfactionEffect: String {
        if gameState.customerSatisfaction < 0.3 {
            return "Package value severely reduced, reputation damage limits growth."
        } else if gameState.customerSatisfaction < 0.5 {
            return "Package value reduced, customer complaints increasing."
        } else if gameState.customerSatisfaction < 0.7 {
            return "Standard customer expectations met, average package value."
        } else if gameState.customerSatisfaction < 0.9 {
            return "Customers are satisfied, increased package value and referrals."
        } else {
            return "Customers are delighted, maximum package values and excellent reputation."
        }
    }
    
    private var corporateEthicsColor: Color {
        if gameState.corporateEthics < 0.3 {
            return .red
        } else if gameState.corporateEthics < 0.5 {
            return .orange
        } else if gameState.corporateEthics < 0.7 {
            return .yellow
        } else if gameState.corporateEthics < 0.9 {
            return .green
        } else {
            return .mint
        }
    }
    
    // --- ADD HELPER VARS FOR NEW METRICS --- 
    
    private var publicPerceptionColor: Color {
        let perception = gameState.publicPerception
        if perception < 20 { return .red }
        if perception < 40 { return .orange }
        if perception < 60 { return .yellow }
        if perception < 80 { return .green }
        return .mint
    }
    
    private var publicPerceptionText: String {
        let perception = gameState.publicPerception
        if perception < 20 { return "Very Negative" }
        if perception < 40 { return "Negative" }
        if perception < 60 { return "Neutral" }
        if perception < 80 { return "Positive" }
        return "Very Positive"
    }
    
    private var environmentalImpactColor: Color {
        let impact = gameState.environmentalImpact
        // Higher impact is worse, so colors are reversed
        if impact < 20 { return .green } // Low impact
        if impact < 40 { return .yellow }
        if impact < 60 { return .orange }
        if impact < 80 { return .red }
        return Color(red: 0.6, green: 0, blue: 0) // Dark Red for very high impact
    }
    
    private var environmentalImpactText: String {
        let impact = gameState.environmentalImpact
        if impact < 20 { return "Minimal" }
        if impact < 40 { return "Low" }
        if impact < 60 { return "Moderate" }
        if impact < 80 { return "High" }
        return "Severe"
    }
    
    // --- END HELPER VARS --- 
}

#Preview {
    DashboardView(gameState: {
        let state = GameState()
        state.totalPackagesShipped = 523
        state.money = 1250
        state.workers = 5
        state.automationRate = 0.75
        state.moralDecay = 35
        state.workerEfficiency = 1.2
        state.automationEfficiency = 1.5
        state.workerMorale = 0.75
        state.customerSatisfaction = 0.85
        return state
    }())
} 