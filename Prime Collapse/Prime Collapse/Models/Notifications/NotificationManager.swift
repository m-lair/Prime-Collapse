import SwiftUI
import Observation

// Notification manager to handle display of game notifications
@Observable class NotificationManager {
    var notifications: [GameNotification] = []
    private var cleanupTimer: Timer?
    private var lastMoraleWarningTime: Date?
    private var lastSatisfactionWarningTime: Date?
    
    init() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.notifications.removeAll(where: { !$0.isActive })
        }
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    func addNotification(_ notification: GameNotification) {
        notifications.append(notification)
    }
    
    func checkGameStateForNotifications(gameState: GameState) {
        // Check for critically low morale (max once per minute)
        if gameState.workerMorale < 0.1 && gameState.workers > 1 {
            if lastMoraleWarningTime == nil || Date().timeIntervalSince(lastMoraleWarningTime!) > 60 {
                addNotification(.lowMorale())
                lastMoraleWarningTime = Date()
            }
        }
        
        // Check for low customer satisfaction (max once per minute)
        if gameState.customerSatisfaction < 0.3 {
            if lastSatisfactionWarningTime == nil || Date().timeIntervalSince(lastSatisfactionWarningTime!) > 60 {
                addNotification(.lowCustomerSatisfaction())
                lastSatisfactionWarningTime = Date()
            }
        }
        
        // Worker quit notifications are handled via onChange in ContentView
    }
} 