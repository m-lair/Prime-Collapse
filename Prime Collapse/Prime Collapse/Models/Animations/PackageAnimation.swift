import SwiftUI

// Package shipping animation model
struct PackageAnimation: Identifiable {
    let id = UUID()
    let startTime: Date
    let duration: Double = 2.5
    let emoji: String
    let startPosition: CGPoint
    let speed: Double // Animation speed multiplier
    
    init(startTime: Date, startPosition: CGPoint) {
        self.startTime = startTime
        self.startPosition = startPosition
        
        // Randomly select from package emojis
        let packageEmojis = ["📦", "🗃️", "📥", "🧰", "📨"]
        self.emoji = packageEmojis.randomElement() ?? "📦"
        
        // Random speed variation
        self.speed = Double.random(in: 0.35...0.85)
    }
    
    var isActive: Bool {
        Date().timeIntervalSince(startTime) < duration
    }
    
    var progress: Double {
        min(1.0, Date().timeIntervalSince(startTime) / duration)
    }
    
    var opacity: Double {
        let progress = Date().timeIntervalSince(startTime) / duration
        // Start visible, then fade out near the end
        return progress < 0.8 ? 1.0 : 1.0 - ((progress - 0.8) / 0.2)
    }
    
    var position: CGPoint {
        let progress = Date().timeIntervalSince(startTime) / duration
        let screenWidth = UIScreen.main.bounds.width
        
        // Calculate x position (left to right)
        let startX = startPosition.x
        let targetX = screenWidth + 50 // Move off-screen to the right
        let currentX = startX + (targetX - startX) * progress
        
        // Add a slight arc for y position
        let startY = startPosition.y
        let arcHeight = CGFloat(40)
        let arcProgress = sin(progress * .pi) // Sine wave for smooth up-down
        let currentY = startY - (arcHeight * arcProgress)
        
        return CGPoint(x: currentX, y: currentY)
    }
    
    var rotation: Double {
        // Rotate the package slightly as it moves
        let progress = Date().timeIntervalSince(startTime) / duration
        return progress * 30 // Rotate up to 30 degrees
    }
    
    var scale: CGFloat {
        // Start normal size, get slightly larger in the middle, then shrink
        let progress = Date().timeIntervalSince(startTime) / duration
        let midScale = 1.3
        
        if progress < 0.5 {
            // First half: grow to midScale
            return 1.0 + (midScale - 1.0) * (progress / 0.5)
        } else {
            // Second half: shrink back to 1.0 or smaller as it exits
            return midScale - (midScale - 0.8) * ((progress - 0.5) / 0.5)
        }
    }
} 
