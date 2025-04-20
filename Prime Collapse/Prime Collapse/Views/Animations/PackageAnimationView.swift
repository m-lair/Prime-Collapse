import SwiftUI

struct PackageAnimationView: View {
    let animation: PackageAnimation
    
    // Animation states
    @State private var xPosition: CGFloat
    @State private var yPosition: CGFloat
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var animationOffset: Double = 0 // Used for Y-axis oscillation
    
    // Screen boundaries
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width
    
    init(animation: PackageAnimation) {
        self.animation = animation
        
        // Start off-screen to the left
        _xPosition = State(initialValue: -50)
        
        // Use the y-position from the button, but with a random offset to spread out packages
        let yOffset = CGFloat.random(in: -100...100)
        _yPosition = State(initialValue: animation.startPosition.y + yOffset)
    }
    
    var body: some View {
        Text(animation.emoji)
            .font(.system(size: 36))
            .opacity(opacity)
            .position(x: xPosition, y: yPosition + CGFloat(sin(animationOffset) * 10)) // Add slight wave motion
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                // Start subtle up-down movement
                withAnimation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: true)
                ) {
                    animationOffset = 6.28 // 2π, a full wave cycle
                }
                
                // Main flight animation
                withAnimation(
                    .spring(response: 0.8, dampingFraction: 0.8)
                    .speed(animation.speed)
                ) {
                    xPosition = screenWidth + 50 // Move off right side of screen
                    rotation = Double.random(in: -20...40) * animation.speed
                    scale = 1.2
                }
                
                // Fade out near the end
                withAnimation(
                    .easeIn(duration: 0.3)
                    .delay(1.8 / animation.speed)
                ) {
                    opacity = 0
                }
            }
    }
} 