import SwiftUI

// Main tap button for shipping packages
struct ShipPackageButton: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .headline) private var diameter = 180
    @State private var isPressed = false
    @State private var animateScale = false
    @Environment(\.accessDecreaseAnimator) private var decreaseAnimator
    
    var body: some View {
        Button {
            isPressed = true
            animateScale = !reduceMotion
            
            // Reset animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateScale = false
            }
            
            gameState.shipPackage()
            playHaptic(.medium)
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
                    .scaleEffect(isPressed && !reduceMotion ? 0.95 : 1.0)
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
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .foregroundColor(.white)
                }
                .offset(y: isPressed && !reduceMotion ? 2 : 0)
            }
            .frame(width: min(diameter, 290), height: min(diameter, 290))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(gameState.isRunTerminal)
        .accessibilityLabel("Ship package")
        .accessibilityHint("Dispatch one package")
    }
    
    private func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
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