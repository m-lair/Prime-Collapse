import SwiftUI

// Notification system for important game alerts
struct GameNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let color: Color
    let startTime = Date()
    let duration: Double
    
    var isActive: Bool {
        Date().timeIntervalSince(startTime) < duration
    }
    
    static func workerQuit(count: Int) -> GameNotification {
        GameNotification(
            title: "Workers Quitting!",
            message: "\(count) worker\(count > 1 ? "s" : "") quit due to low morale.",
            icon: "person.fill.xmark",
            color: .red,
            duration: 5.0
        )
    }
    
    static func lowMorale() -> GameNotification {
        GameNotification(
            title: "Critical Morale",
            message: "Worker production severely reduced due to very low morale.",
            icon: "exclamationmark.triangle.fill",
            color: .orange,
            duration: 5.0
        )
    }
    
    static func lowCustomerSatisfaction() -> GameNotification {
        GameNotification(
            title: "Unhappy Customers",
            message: "Low customer satisfaction is reducing package value.",
            icon: "person.crop.circle.badge.exclamationmark",
            color: .red,
            duration: 5.0
        )
    }
} 