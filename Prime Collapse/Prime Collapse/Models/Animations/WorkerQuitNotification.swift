import SwiftUI

// Worker quit notification model
struct WorkerQuitNotification: Identifiable {
    let id = UUID()
    let count: Int
    let startTime: Date
    let position: CGPoint
    let duration: Double = 3.0
    
    var isActive: Bool {
        Date().timeIntervalSince(startTime) < duration
    }
    
    var opacity: Double {
        let progress = Date().timeIntervalSince(startTime) / duration
        return max(0, progress < 0.7 ? 1.0 : 1.0 - ((progress - 0.7) / 0.3))
    }
    
    var offset: CGFloat {
        let progress = Date().timeIntervalSince(startTime) / duration
        return -60 * CGFloat(progress)
    }
} 