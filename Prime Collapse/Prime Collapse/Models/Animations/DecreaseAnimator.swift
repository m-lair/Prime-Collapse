import SwiftUI
import Observation

// Observer for value decreases
@Observable final class DecreaseAnimator {
    var decreases: [ValueDecrease] = []
    var workerQuitNotifications: [WorkerQuitNotification] = []
    var packageAnimations: [PackageAnimation] = []
    private var cleanupTimer: Timer?
    
    init() {
        // Set up a timer to more frequently clean up completed animations
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.decreases.removeAll(where: { !$0.isActive })
            self.workerQuitNotifications.removeAll(where: { !$0.isActive })
            self.packageAnimations.removeAll(where: { !$0.isActive })
            
            // Also cap the arrays at a reasonable size to prevent performance issues
            if self.packageAnimations.count > 20 {
                self.packageAnimations = Array(self.packageAnimations.suffix(20))
            }
            if self.decreases.count > 15 {
                self.decreases = Array(self.decreases.suffix(15))
            }
            if self.workerQuitNotifications.count > 5 {
                self.workerQuitNotifications = Array(self.workerQuitNotifications.suffix(5))
            }
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
    
    func addPackageAnimation(at position: CGPoint) {
        let animation = PackageAnimation(startTime: Date(), startPosition: position)
        packageAnimations.append(animation)
    }
} 