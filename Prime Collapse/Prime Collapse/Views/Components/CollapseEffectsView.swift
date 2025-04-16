import SwiftUI

// Collapse phase visual effects
struct CollapseEffectsView: View {
    @Binding var showCollapseAlert: Bool
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Red warning flashes
            Color.red.opacity(opacity)
                .blendMode(.overlay)
                .onAppear {
                    // Pulsing effect
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever()) {
                        opacity = 0.7
                    }
                }
            
            // Warning text with glitch effect
            Text("ECONOMIC COLLAPSE")
                .font(.system(size: 36, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .red, radius: 10)
                .rotationEffect(.degrees(rotation))
                .overlay(
                    Text("ECONOMIC COLLAPSE")
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(.red)
                        .shadow(color: .white, radius: 2)
                        .offset(x: 2, y: 2)
                        .blendMode(.difference)
                        .rotationEffect(.degrees(rotation * -0.5))
                )
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.2).repeatForever()) {
                        rotation = 2
                    }
                }
            
            // Digital noise effect
            GeometryReader { geo in
                ForEach(0..<50, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                        .frame(
                            width: Double.random(in: 1...50),
                            height: Double.random(in: 1...5)
                        )
                        .position(
                            x: Double.random(in: 0...geo.size.width),
                            y: Double.random(in: 0...geo.size.height)
                        )
                }
            }
            .drawingGroup() // Better performance for complex view
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false) // Let touches pass through
    }
}

#Preview {
    CollapseEffectsView(showCollapseAlert: .constant(false))
} 