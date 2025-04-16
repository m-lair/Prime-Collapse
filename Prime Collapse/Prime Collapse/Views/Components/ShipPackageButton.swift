import SwiftUI

// Main tap button for shipping packages
struct ShipPackageButton: View {
    var gameState: GameState
    @State private var isPressed = false
    @State private var animateScale = false
    
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
        .disabled(gameState.isCollapsing && gameState.moralDecay > 120)
    }
    
    private func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        ShipPackageButton(gameState: GameState())
    }
} 