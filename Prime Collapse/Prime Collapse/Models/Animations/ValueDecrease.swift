import SwiftUI

// Value decrease animation model
struct ValueDecrease: Identifiable {
    let id = UUID()
    let amount: Double
    let startTime: Date
    let position: CGPoint
    let duration: Double = 2.0 // Increased from 1.5 to make animation longer
    
    var isActive: Bool {
        Date().timeIntervalSince(startTime) < duration
    }
    
    var opacity: Double {
        let progress = Date().timeIntervalSince(startTime) / duration
        // Slow down opacity change - stay more visible for longer
        return max(0, progress < 0.6 ? 1.0 : 1.0 - ((progress - 0.6) / 0.4))
    }
    
    var offset: CGFloat {
        let progress = Date().timeIntervalSince(startTime) / duration
        return -50 * CGFloat(progress)
    }
} 