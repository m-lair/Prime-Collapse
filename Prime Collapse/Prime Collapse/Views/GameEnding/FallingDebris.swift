import SwiftUI

// Falling debris animation for collapse ending
struct FallingDebris: View {
    @State private var xPosition = Double.random(in: -20...UIScreen.main.bounds.width + 20)
    @State private var yPosition = Double.random(in: -200...0)
    @State private var rotation = Double.random(in: 0...360)
    @State private var size = Double.random(in: 5...20)
    @State private var speed = Double.random(in: 50...150)
    
    var body: some View {
        Image(systemName: ["dollarsign", "building.2.fill", "chart.bar.fill"].randomElement()!)
            .font(.system(size: size))
            .foregroundColor(.white.opacity(Double.random(in: 0.3...0.7)))
            .position(x: xPosition, y: yPosition)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    yPosition = UIScreen.main.bounds.height + 100
                    rotation += Double.random(in: 180...360)
                }
            }
    }
}

#Preview {
    ZStack {
        Color.red.opacity(0.7).ignoresSafeArea()
        ForEach(0..<20, id: \.self) { _ in
            FallingDebris()
        }
    }
} 