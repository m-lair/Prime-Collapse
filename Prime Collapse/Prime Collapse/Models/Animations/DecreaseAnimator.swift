import SwiftUI
import Observation

// Observer for value decreases
@Observable final class DecreaseAnimator {
    var decreases: [ValueDecrease] = []
    var workerQuitNotifications: [WorkerQuitNotification] = []
    private var cleanupTimer: Timer?
    
    init() {
        // Set up a timer to periodically clean up completed animations
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.decreases.removeAll(where: { !$0.isActive })
            self.workerQuitNotifications.removeAll(where: { !$0.isActive })
        }
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    func addDecrease(_ amount: Double, at position: CGPoint) {
        let decrease = ValueDecrease(amount: amount, startTime: Date(), position: position)
        decreases.append(decrease)
    }
    
    func addWorkerQuitNotification(_ count: Int, at position: CGPoint) {
        let notification = WorkerQuitNotification(count: count, startTime: Date(), position: position)
        workerQuitNotifications.append(notification)
    }
} 