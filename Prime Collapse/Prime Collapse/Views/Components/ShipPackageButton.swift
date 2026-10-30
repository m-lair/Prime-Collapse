import SwiftUI

// Main tap button for shipping packages
struct ShipPackageButton: View {
    @Environment(GameState.self) private var gameState
    @State private var isPressed = false
    @State private var animateScale = false
    @State private var gains: [ValueGain] = []
    @State private var shipCount = 0
    @Environment(\.accessDecreaseAnimator) private var decreaseAnimator
    /// Called with the payout of each tap.
    var onShip: (Double) -> Void = { _ in }
    
    var body: some View {
        Button {
            isPressed = true
            animateScale = true
            
            // Reset animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateScale = false
            }
            
            let before = gameState.money
            gameState.shipPackage()
            let payout = gameState.money - before
            shipCount += 1
            if payout > 0 {
                let now = Date()
                gains = Array(gains.filter { $0.isActive(at: now) }.suffix(11)) + [ValueGain(amount: payout)]
            }
            onShip(payout)
        } label: {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        gameState.isCollapsing 
                        ? Color.red.opacity(0.3) 
                        : Color.blue.opacity(0.3)
                    )
                    .scaleEffect(animateScale ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.3).repeatCount(1),
                        value: animateScale
                    )
                
                // Button background
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                gameState.isCollapsing ? Color.red.opacity(0.8) : Color.blue.opacity(0.8),
                                gameState.isCollapsing ? Color.red.opacity(0.6) : Color.blue.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 5)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                
                // Content
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                    
                    Text("SHIP PACKAGE")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .offset(y: isPressed ? 2 : 0)
            }
            .frame(width: 180, height: 180)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(gameState.isCollapsing)
        .sensoryFeedback(.impact(weight: .medium), trigger: shipCount)
        .overlay(alignment: .top) { gainFloaters }
        .task(id: gains.last?.id) {
            // Drop finished floaters once the latest one has run its course.
            try? await Task.sleep(for: .seconds(ValueGain.duration))
            gains.removeAll { !$0.isActive(at: Date()) }
        }
    }
    
    private var gainFloaters: some View {
        TimelineView(.animation(paused: gains.isEmpty)) { timeline in
            ZStack {
                ForEach(gains) { gain in
                    let progress = gain.progress(at: timeline.date)
                    Text("+\(gain.amount.shortCurrency)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                        .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                        .scaleEffect(progress < 0.15 ? 0.7 + progress * 2 : 1)
                        .opacity(progress < 0.6 ? 1 : 1 - (progress - 0.6) / 0.4)
                        .offset(x: gain.xJitter, y: -70 * progress)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// Environment key for accessing the DecreaseAnimator
private struct DecreaseAnimatorKey: EnvironmentKey {
    static let defaultValue: DecreaseAnimator? = nil
}

extension EnvironmentValues {
    var accessDecreaseAnimator: DecreaseAnimator? {
        get { self[DecreaseAnimatorKey.self] }
        set { self[DecreaseAnimatorKey.self] = newValue }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        ShipPackageButton()
            .environment(GameState())
    }
} 