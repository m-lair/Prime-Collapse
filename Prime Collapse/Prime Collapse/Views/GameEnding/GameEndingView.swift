import SwiftUI

// Game ending types
enum GameEnding {
    case collapse
    case reform
    case loop
}

// Game ending screen
struct GameEndingView: View {
    let gameEnding: GameEnding
    let packagesShipped: Int
    let profit: Double // This is the final cash balance
    let workerCount: Int
    let lifetimeTotalMoneyEarned: Double // Added for lifetime stats
    let ethicalChoicesMade: Int // Added for ethical stats
    let onReset: () -> Void
    
    @State private var showConfetti = false
    @State private var showStats = false
    @State private var showQuote = false
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            // Background color based on ending type
            backgroundColor
                .ignoresSafeArea()
            
            // Additional background elements based on ending type
            Group {
                switch gameEnding {
                case .collapse:
                    // Falling debris elements for collapse ending
                    ForEach(0..<30) { _ in
                        FallingDebris()
                    }
                    
                case .reform:
                    // Light rays for reform ending
                    GeometryReader { geo in
                        ForEach(0..<8, id: \.self) { index in
                            let angle = Double(index) * (Double.pi / 4.0)
                            Path { path in
                                path.move(to: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                                path.addLine(to: CGPoint(
                                    x: geo.size.width / 2 + cos(angle) * max(geo.size.width, geo.size.height),
                                    y: geo.size.height / 2 + sin(angle) * max(geo.size.width, geo.size.height)
                                ))
                            }
                            .stroke(Color.white.opacity(0.3), lineWidth: 15)
                            .blur(radius: 20)
                        }
                    }
                    
                case .loop:
                    // Circular patterns for loop ending
                    GeometryReader { geo in
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                .frame(width: CGFloat(100 + index * 50))
                                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        }
                    }
                }
            }
            
            // Content
            VStack(spacing: 24) {
                // Title with icon
                VStack(spacing: 16) {
                    Image(systemName: endingIcon)
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 5)
                        .padding(.top, 40)
                    
                    Text(endingTitle)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.5), radius: 3)
                        .padding(.horizontal)
                    
                    Text(endingSubtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Statistics
                VStack(spacing: 16) {
                    if showStats {
                        EndingStatCard(
                            title: "Total Packages Shipped",
                            value: "\(packagesShipped)",
                            icon: "shippingbox.fill",
                            color: .yellow
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        
                        EndingStatCard(
                            title: "Final Cash Balance",
                            value: "$\(String(format: "%.2f", profit))",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        
                        EndingStatCard(
                            title: "Lifetime Money Earned",
                            value: "$\(String(format: "%.2f", lifetimeTotalMoneyEarned))",
                            icon: "banknote.fill",
                            color: .purple
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        
                        EndingStatCard(
                            title: "Final Worker Count",
                            value: "\(workerCount)",
                            icon: "person.fill",
                            color: .blue
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        
                        EndingStatCard(
                            title: "Ethical Choices Made",
                            value: "\(ethicalChoicesMade)",
                            icon: "heart.circle.fill",
                            color: gameEnding == .reform ? .pink : .orange
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Quote
                if showQuote {
                    Text(endingQuote)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.2))
                        )
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Play again button
                if showButton {
                    Button(action: onReset) {
                        Text("PLAY AGAIN")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(backgroundColor)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.3), radius: 5)
                            )
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical)
            
            // Confetti for certain endings
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            // Animate elements in sequence
            withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
                showStats = true
            }
            
            withAnimation(.easeIn(duration: 0.8).delay(1.5)) {
                showQuote = true
            }
            
            withAnimation(.spring().delay(2.3)) {
                showButton = true
            }
            
            // Show confetti if appropriate for the ending
            if gameEnding == .reform {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        switch gameEnding {
        case .collapse:
            return Color(red: 0.7, green: 0.1, blue: 0.1)
        case .reform:
            return Color(red: 0.1, green: 0.6, blue: 0.3)
        case .loop:
            return Color(red: 0.1, green: 0.3, blue: 0.7)
        }
    }
    
    private var endingIcon: String {
        switch gameEnding {
        case .collapse:
            return "building.columns.fill"
        case .reform:
            return "leaf.fill"
        case .loop:
            return "infinity"
        }
    }
    
    private var endingTitle: String {
        switch gameEnding {
        case .collapse:
            return "Economic Collapse"
        case .reform:
            return "Corporate Reform"
        case .loop:
            return "Infinite Growth"
        }
    }
    
    private var endingSubtitle: String {
        switch gameEnding {
        case .collapse:
            return "Your ruthless pursuit of profit has caused the economy to collapse. Society will rebuild... eventually."
        case .reform:
            return "You've managed to build a successful company while maintaining ethical standards. A rare achievement!"
        case .loop:
            return "You've managed to balance on the razor's edge of extraction and sustainability for a brief moment. Such a delicate balance could never last long..."
        }
    }
    
    private var endingQuote: String {
        switch gameEnding {
        case .collapse:
            return "\"The inherent vice of capitalism is the unequal sharing of blessings; the inherent virtue of socialism is the equal sharing of miseries.\" — Winston Churchill"
        case .reform:
            return "\"The business of business should not just be about money, it should be about responsibility. It should be about public good, not private greed.\" — Anita Roddick"
        case .loop:
            return "\"Growth for the sake of growth is the ideology of the cancer cell.\" — Edward Abbey"
        }
    }
}

#Preview {
    GameEndingView(
        gameEnding: .reform,
        packagesShipped: 12345,
        profit: 56789.12,
        workerCount: 50,
        lifetimeTotalMoneyEarned: 150000.00,
        ethicalChoicesMade: 15,
        onReset: { print("Reset tapped") }
    )
}

#Preview {
    GameEndingView(
        gameEnding: .collapse,
        packagesShipped: 500,
        profit: -1000.00,
        workerCount: 2,
        lifetimeTotalMoneyEarned: 10000.00,
        ethicalChoicesMade: 2,
        onReset: { print("Reset tapped") }
    )
}

#Preview {
    GameEndingView(
        gameEnding: .loop,
        packagesShipped: 9999,
        profit: 10000.00,
        workerCount: 100,
        lifetimeTotalMoneyEarned: 200000.00,
        ethicalChoicesMade: 8,
        onReset: { print("Reset tapped") }
    )
} 
