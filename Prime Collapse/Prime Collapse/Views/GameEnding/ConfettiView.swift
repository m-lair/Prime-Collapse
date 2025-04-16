import SwiftUI

// Confetti animation view
struct ConfettiView: View {
    @State private var particles = (0..<100).map { _ in ConfettiParticle() }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for index in 0..<particles.count {
                    let timeInterval = timeline.date.timeIntervalSince1970
                    particles[index].update(for: timeInterval, in: size)
                    
                    let path = Path(ellipseIn: CGRect(
                        x: particles[index].x - particles[index].size/2,
                        y: particles[index].y - particles[index].size/2,
                        width: particles[index].size,
                        height: particles[index].size
                    ))
                    
                    context.fill(
                        path,
                        with: .color(particles[index].color)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// Particle for the confetti animation
struct ConfettiParticle {
    var x: Double
    var y: Double
    var size: Double
    var speed: Double
    var color: Color
    private var creationTime: TimeInterval
    
    init() {
        x = Double.random(in: 0..<UIScreen.main.bounds.width)
        y = Double.random(in: -50..<0)
        size = Double.random(in: 5..<15)
        speed = Double.random(in: 20..<80)
        creationTime = Date().timeIntervalSince1970
        
        // Random color
        let colors: [Color] = [.red, .green, .blue, .yellow, .purple, .orange]
        color = colors.randomElement()!
    }
    
    mutating func update(for currentTime: TimeInterval, in size: CGSize) {
        let elapsedTime = currentTime - creationTime
        y += speed * 0.1
        
        // Reset particles that have fallen off screen
        if y > size.height {
            y = -size.height * 0.1
            x = Double.random(in: 0..<size.width)
            creationTime = currentTime
        }
    }
}

#Preview {
    ZStack {
        Color.green.opacity(0.3).ignoresSafeArea()
        ConfettiView()
    }
} 