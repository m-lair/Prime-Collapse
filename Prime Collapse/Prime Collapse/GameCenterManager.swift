import SwiftUI
import GameKit

/// Manages Game Center functionality including authentication, leaderboards, and achievements
@Observable final class GameCenterManager: NSObject {
    // MARK: - Properties
    
    /// Whether the user is authenticated with Game Center
    var isAuthenticated = false
    
    /// Whether authentication has been attempted
    private var hasAttemptedAuthentication = false
    
    /// The current player's Game Center profile
    var localPlayer: GKLocalPlayer?
    
    /// The current player's profile image
    var playerProfileImage: UIImage?
    
    /// Error message if authentication fails
    var authenticationError: String?
    
    // MARK: - Throttling Properties
    
    /// Timestamp of last leaderboard update
    private var lastLeaderboardUpdate = Date(timeIntervalSince1970: 0)
    
    /// Timestamp of last achievement update
    private var lastAchievementUpdate = Date(timeIntervalSince1970: 0)
    
    /// Minimum interval between leaderboard updates (in seconds)
    private let leaderboardUpdateInterval: TimeInterval = 3.0
    
    /// Minimum interval between achievement updates (in seconds)
    private let achievementUpdateInterval: TimeInterval = 5.0
    
    /// Cache of last submitted scores to avoid duplicate submissions
    var lastSubmittedScores: [String: Int] = [:]
    
    /// Cache of last reported achievement progresses to avoid duplicate reports
    private var lastReportedAchievements: [String: Double] = [:]
    
    /// Pending leaderboard updates that failed and need to be retried
    private var pendingLeaderboardUpdates: [(leaderboardID: String, score: Int)] = []
    
    /// Maximum number of retry attempts for leaderboard submissions
    private let maxRetryAttempts = 3
    
    /// Current retry count for leaderboard submissions
    private var retryCount = 0
    
    /// Background task for retrying failed leaderboard submissions
    private var retryTask: Task<Void, Never>?
    
    // MARK: - Leaderboard IDs
    
    /// Leaderboard for total packages shipped
    static let totalPackagesLeaderboardID = "total_packages_shipped"
    
    /// Leaderboard for total money earned
    static let totalMoneyLeaderboardID = "total_money_earned"
    
    // MARK: - Achievement IDs
    
    /// Achievement for hiring first worker
    static let firstWorkerAchievementID = "first_worker_hired"
    
    /// Achievement for reaching automation milestone (10 packages/sec)
    static let automationMilestoneAchievementID = "automation_milestone"
    
    /// Achievement for making ethical choices
    static let ethicalChoicesAchievementID = "ethical_choices"
    
    /// Achievement for experiencing economic collapse
    static let economicCollapseAchievementID = "economic_collapse"
    
    /// Achievement for reaching the reform ending
    static let reformEndingAchievementID = "reform_ending"
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        // Don't authenticate automatically on init
        
        // Load achievement descriptions once during init
        loadAchievementDescriptions()
    }
    
    // MARK: - Authentication
    
    /// Authenticates the local player with Game Center
    func authenticatePlayer() {
        // Prevent multiple authentication attempts
        guard !hasAttemptedAuthentication else { return }
        
        hasAttemptedAuthentication = true
        
        // Make sure we're on the main thread
        DispatchQueue.main.async {
            GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
                guard let self = self else { return }
                
                if let viewController = viewController {
                    // Present the authentication view controller
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(viewController, animated: true)
                    }
                    return
                }
                
                if let error = error {
                    self.authenticationError = error.localizedDescription
                    self.isAuthenticated = false
                    print("Game Center authentication error: \(error.localizedDescription)")
                    return
                }
                
                if GKLocalPlayer.local.isAuthenticated {
                    self.localPlayer = GKLocalPlayer.local
                    self.isAuthenticated = true
                    print("Successfully authenticated with Game Center")
                    
                    // Load the player's profile image
                    self.loadPlayerProfileImage()
                    
                    // Load achievement descriptions
                    self.loadAchievementDescriptions()
                    
                    // Check if leaderboards are properly configured
                    self.checkLeaderboardAvailability()
                    
                    // Register for challenges
                    GKLocalPlayer.local.register(self)
                } else {
                    self.isAuthenticated = false
                    self.authenticationError = "Player is not authenticated"
                    print("Game Center authentication failed: Player is not authenticated")
                }
            }
        }
    }
    
    /// Checks if the leaderboards are properly configured and available
    func checkLeaderboardAvailability() {
        print("Checking leaderboard availability...")
        
        // Check specifically for our configured leaderboard
        GKLeaderboard.loadLeaderboards(IDs: [Self.totalPackagesLeaderboardID]) { leaderboards, error in
            if let error = error {
                print("❌ ERROR loading leaderboard: \(error.localizedDescription)")
            } else if let leaderboards = leaderboards, !leaderboards.isEmpty {
                print("✅ SUCCESS: Found \(leaderboards.count) leaderboards")
                for leaderboard in leaderboards {
                    print("  - Leaderboard: \(leaderboard.title) (ID: \(leaderboard.baseLeaderboardID))")
                }
            } else {
                print("⚠️ WARNING: No leaderboards found with ID '\(Self.totalPackagesLeaderboardID)'")
                print("   Make sure this exact ID is configured in App Store Connect")
            }
        }
    }
    
    /// Loads the player's profile image
    private func loadPlayerProfileImage() {
        guard let player = localPlayer else { return }
        
        player.loadPhoto(for: .normal) { [weak self] (image, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading player photo: \(error.localizedDescription)")
                return
            }
            
            if let image = image {
                DispatchQueue.main.async {
                    self.playerProfileImage = image
                }
            }
        }
    }
    
    /// Loads achievement descriptions to ensure they exist before reporting
    private func loadAchievementDescriptions() {
        guard isAuthenticated else { return }
        
        let achievementIDs = [
            Self.firstWorkerAchievementID,
            Self.automationMilestoneAchievementID,
            Self.ethicalChoicesAchievementID,
            Self.economicCollapseAchievementID,
            Self.reformEndingAchievementID
        ]
        
        GKAchievementDescription.loadAchievementDescriptions { [weak self] descriptions, error in
            if let error = error {
                print("Error loading achievement descriptions: \(error.localizedDescription)")
                return
            }
            
            guard let descriptions = descriptions else {
                print("No achievement descriptions loaded")
                return
            }
            
            print("Loaded \(descriptions.count) achievement descriptions")
            
            // Check if all our achievement IDs exist
            let loadedIDs = Set(descriptions.map { $0.identifier })
            for achievementID in achievementIDs {
                if !loadedIDs.contains(achievementID) {
                    print("WARNING: Achievement ID '\(achievementID)' is not configured in App Store Connect")
                }
            }
        }
    }
    
    // MARK: - Leaderboards
    
    /// Presents the Game Center leaderboards UI
    func showLeaderboards() {
        guard isAuthenticated else {
            print("Cannot show leaderboards: Player not authenticated")
            return
        }
        
        guard let rootViewController = getRootViewController() else {
            print("Cannot show leaderboards: No root view controller found")
            return
        }
        
        // Check if a view is already being presented
        if rootViewController.presentedViewController != nil {
            print("Dismissing currently presented view before showing leaderboards")
            rootViewController.dismiss(animated: false) { [weak self] in
                // After dismissal, proceed with presenting leaderboards
                self?.loadAndPresentLeaderboards(on: rootViewController)
            }
        } else {
            // No view is currently presented, proceed directly
            loadAndPresentLeaderboards(on: rootViewController)
        }
    }
    
    /// Helper method to load and present leaderboards
    private func loadAndPresentLeaderboards(on viewController: UIViewController) {
        // Load all available leaderboards instead of just one
        let leaderboardIDs = [Self.totalPackagesLeaderboardID, Self.totalMoneyLeaderboardID]
        
        // First load available leaderboards specifically
        GKLeaderboard.loadLeaderboards(IDs: leaderboardIDs) { [weak self, weak viewController] leaderboards, error in
            guard let self = self, let viewController = viewController else { return }
            
            if let error = error {
                print("Error loading leaderboards: \(error.localizedDescription)")
                return
            }
            
            // Log available leaderboards
            if let leaderboards = leaderboards {
                print("Loaded \(leaderboards.count) leaderboards")
                for leaderboard in leaderboards {
                    print("  - Leaderboard: \(leaderboard.title) (ID: \(leaderboard.baseLeaderboardID))")
                }
            } else {
                print("No leaderboards found")
            }
            
            // Run presentation on main thread to avoid any threading issues
            DispatchQueue.main.async {
                // Proceed with presenting the UI
                let gcViewController = GKGameCenterViewController()
                gcViewController.gameCenterDelegate = self
                
                // Set the view state to leaderboards
                gcViewController.viewState = .leaderboards
                
                // Specify which leaderboard to show - can now show the default view with all leaderboards
                // or specify a starting leaderboard
                gcViewController.leaderboardIdentifier = Self.totalPackagesLeaderboardID
                
                // Final check that no other view is currently presented
                if viewController.presentedViewController == nil {
                    viewController.present(gcViewController, animated: true)
                } else {
                    print("Cannot present Game Center: Another view is already being presented")
                }
            }
        }
    }
    
    /// Submits a score to the specified leaderboard
    /// - Parameters:
    ///   - score: The score to submit
    ///   - leaderboardID: The ID of the leaderboard to submit the score to
    func submitScore(_ score: Int, to leaderboardID: String) {
        guard isAuthenticated else {
            // Silently ignore if not authenticated to prevent console spam
            return
        }
        
        // Check if we've already submitted this score
        if let lastScore = lastSubmittedScores[leaderboardID], lastScore >= score {
            // Skip if the new score is not higher than the last submitted score
            return
        }
        
        print("Submitting score \(score) to leaderboard \(leaderboardID)")
        
        // Update the cache
        lastSubmittedScores[leaderboardID] = score
        
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ ERROR submitting score to leaderboard \(leaderboardID): \(error.localizedDescription)")
                
                // Add to pending updates for retry
                self.pendingLeaderboardUpdates.append((leaderboardID: leaderboardID, score: score))
                
                // Start retry mechanism if not already running
                self.startRetryMechanismIfNeeded()
            } else {
                print("✅ Successfully submitted score \(score) to leaderboard \(leaderboardID)")
            }
        }
    }
    
    /// Submits multiple scores to leaderboards in a batch
    /// - Parameter scores: Dictionary mapping leaderboardIDs to scores
    func submitBatchScores(_ scores: [String: Int]) {
        guard isAuthenticated, !scores.isEmpty else { return }
        
        // Filter out scores that don't need to be updated
        let scoresToSubmit = scores.filter { leaderboardID, score in
            if let lastScore = lastSubmittedScores[leaderboardID], lastScore >= score {
                return false
            }
            return true
        }
        
        guard !scoresToSubmit.isEmpty else { 
            print("No new scores to submit - all scores are already at or above current values")
            return 
        }
        
        print("Batch submitting new scores: \(scoresToSubmit)")
        
        // Update the cache with new scores
        for (leaderboardID, score) in scoresToSubmit {
            lastSubmittedScores[leaderboardID] = score
        }
        
        // Process each score individually to ensure proper submission
        for (leaderboardID, score) in scoresToSubmit {
            GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ ERROR batch submitting score \(score) to leaderboard \(leaderboardID): \(error.localizedDescription)")
                    
                    // Add to pending updates for retry
                    self.pendingLeaderboardUpdates.append((leaderboardID: leaderboardID, score: score))
                    
                    // Start retry mechanism if not already running
                    self.startRetryMechanismIfNeeded()
                } else {
                    print("✅ Successfully submitted score \(score) to leaderboard \(leaderboardID)")
                }
            }
        }
    }
    
    /// Starts the retry mechanism for failed leaderboard submissions if not already running
    private func startRetryMechanismIfNeeded() {
        // If there's already a retry task running, we don't need to start another one
        guard retryTask == nil || retryTask?.isCancelled == true else { return }
        
        retryTask = Task {
            // Reset retry count for new retry session
            retryCount = 0
            
            while !pendingLeaderboardUpdates.isEmpty && retryCount < maxRetryAttempts {
                // Wait with exponential backoff
                let delay = pow(2.0, Double(retryCount)) // 1, 2, 4 seconds
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                if Task.isCancelled { break }
                
                // Increase retry count
                retryCount += 1
                
                // Create a copy of the current pending updates
                let updatesToRetry = pendingLeaderboardUpdates
                
                // Group submissions by score value to reduce API calls
                let submissionsByScore = Dictionary(grouping: updatesToRetry) { $0.score }
                
                var failedUpdates: [(leaderboardID: String, score: Int)] = []
                
                for (score, leaderboardEntries) in submissionsByScore {
                    let leaderboardIDs = leaderboardEntries.map { $0.leaderboardID }
                    
                    // Submit the score to multiple leaderboards
                    let result = await withCheckedContinuation { continuation in
                        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: leaderboardIDs) { error in
                            continuation.resume(returning: error == nil)
                        }
                    }
                    
                    if !result {
                        // If submission failed, add back to failed updates
                        failedUpdates.append(contentsOf: leaderboardEntries)
                    }
                }
                
                // Update pending updates with only the failed ones
                pendingLeaderboardUpdates = failedUpdates
                
                if pendingLeaderboardUpdates.isEmpty {
                    print("Successfully retried all pending leaderboard updates")
                    break
                }
            }
            
            // Log if we still have pending updates after max retries
            if !pendingLeaderboardUpdates.isEmpty {
                print("Failed to submit \(pendingLeaderboardUpdates.count) leaderboard updates after \(maxRetryAttempts) attempts")
                // Clear pending updates to avoid buildup
                pendingLeaderboardUpdates.removeAll()
            }
            
            retryTask = nil
        }
    }
    
    // MARK: - Achievements
    
    /// Presents the Game Center achievements UI
    func showAchievements() {
        guard isAuthenticated, let rootViewController = getRootViewController() else {
            print("Cannot show achievements: Player not authenticated or no root view controller")
            return
        }
        
        let gcViewController = GKGameCenterViewController(state: .achievements)
        gcViewController.gameCenterDelegate = self
        rootViewController.present(gcViewController, animated: true)
    }
    
    /// Reports progress for an achievement
    /// - Parameters:
    ///   - achievementID: The ID of the achievement
    ///   - percentComplete: The percentage of completion (0.0 to 100.0)
    func reportAchievement(achievementID: String, percentComplete: Double) {
        guard isAuthenticated else {
            // Silently ignore if not authenticated to prevent console spam
            return
        }
        
        // Check if we've already reported this progress
        if let lastProgress = lastReportedAchievements[achievementID] {
            // Skip if the new progress is not significantly different (allow for small rounding differences)
            if abs(lastProgress - percentComplete) < 1.0 {
                return
            }
            
            // Skip if the achievement is already completed
            if lastProgress >= 100.0 {
                return
            }
        }
        
        // Update the cache
        lastReportedAchievements[achievementID] = percentComplete
        
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = percentComplete
        
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Error reporting achievement \(achievementID): \(error.localizedDescription)")
            } else {
                print("Successfully reported achievement \(achievementID) with progress \(percentComplete)%")
            }
        }
    }
    
    /// Resets all achievements for the player
    func resetAchievements() {
        guard isAuthenticated else {
            print("Cannot reset achievements: Player not authenticated")
            return
        }
        
        GKAchievement.resetAchievements { error in
            if let error = error {
                print("Error resetting achievements: \(error.localizedDescription)")
            } else {
                print("Successfully reset all achievements")
                // Clear achievement cache
                self.lastReportedAchievements.removeAll()
            }
        }
    }
    
    // MARK: - GameState Integration
    
    /// Updates Game Center with the current game state
    /// - Parameter gameState: The current game state
    func updateFromGameState(_ gameState: GameState) {
        // Only proceed if authenticated
        guard isAuthenticated else {
            // Silently ignore to prevent console spam
            return
        }
        
        let now = Date()
        
        // Throttle leaderboard updates
        if now.timeIntervalSince(lastLeaderboardUpdate) >= leaderboardUpdateInterval {
            // Update local score cache immediately (even before submission)
            lastSubmittedScores[Self.totalPackagesLeaderboardID] = gameState.totalPackagesShipped
            lastSubmittedScores[Self.totalMoneyLeaderboardID] = Int(gameState.lifetimeTotalMoneyEarned)
            
            // Prepare batch scores update
            var scores: [String: Int] = [:]
            
            // Add total packages shipped score
            scores[Self.totalPackagesLeaderboardID] = gameState.totalPackagesShipped
            
            // Add total money earned score (convert to integer)
            let moneyEarnedAsInt = Int(gameState.lifetimeTotalMoneyEarned)
            scores[Self.totalMoneyLeaderboardID] = moneyEarnedAsInt
            
            // Submit scores in batch
            submitBatchScores(scores)
            
            lastLeaderboardUpdate = now
        } else {
            // Even if we're throttling network updates, still update the local cache
            // This ensures the UI can always see the latest scores
            lastSubmittedScores[Self.totalPackagesLeaderboardID] = gameState.totalPackagesShipped
            lastSubmittedScores[Self.totalMoneyLeaderboardID] = Int(gameState.lifetimeTotalMoneyEarned)
        }
        
        // Throttle achievement updates
        if now.timeIntervalSince(lastAchievementUpdate) >= achievementUpdateInterval {
            // Update achievements
            
            // First worker hired
            if gameState.workers >= 1 {
                reportAchievement(achievementID: Self.firstWorkerAchievementID, percentComplete: 100.0)
            }
            
            // Automation milestone (10 packages/sec)
            let effectiveAutomationRate = (gameState.baseWorkerRate * Double(gameState.workers) * gameState.workerEfficiency) + (gameState.baseSystemRate * gameState.automationEfficiency)
            let automationProgress = min(effectiveAutomationRate / 10.0 * 100.0, 100.0)
            reportAchievement(achievementID: Self.automationMilestoneAchievementID, percentComplete: automationProgress)
            
            // Ethical choices (based on ethical choices made)
            let ethicalChoicesProgress = min(Double(gameState.ethicalChoicesMade) / 5.0 * 100.0, 100.0)
            reportAchievement(achievementID: Self.ethicalChoicesAchievementID, percentComplete: ethicalChoicesProgress)
            
            // Economic collapse
            if gameState.isCollapsing {
                reportAchievement(achievementID: Self.economicCollapseAchievementID, percentComplete: 100.0)
            }
            
            // Reform ending
            if gameState.endingType == .reform {
                reportAchievement(achievementID: Self.reformEndingAchievementID, percentComplete: 100.0)
            }
            
            lastAchievementUpdate = now
        }
    }
    
    /// Force a refresh of all leaderboard scores without throttling
    func forceRefreshScores(_ gameState: GameState) {
        guard isAuthenticated else { return }
        
        // Calculate scores to submit
        let packagesScore = gameState.totalPackagesShipped
        let moneyScore = Int(gameState.lifetimeTotalMoneyEarned)
        
        print("🔄 Force refreshing scores: Packages=\(packagesScore), Money=\(moneyScore)")
        
        // Update local score cache immediately
        lastSubmittedScores[Self.totalPackagesLeaderboardID] = packagesScore
        lastSubmittedScores[Self.totalMoneyLeaderboardID] = moneyScore
        
        // Check for meaningfully different scores from what's already been submitted
        let shouldSubmitPackages = packagesScore > 0
        let shouldSubmitMoney = moneyScore > 0
        
        if shouldSubmitPackages || shouldSubmitMoney {
            // Prepare scores dictionary
            var scores: [String: Int] = [:]
            
            if shouldSubmitPackages {
                scores[Self.totalPackagesLeaderboardID] = packagesScore
            }
            
            if shouldSubmitMoney {
                scores[Self.totalMoneyLeaderboardID] = moneyScore
            }
            
            // Submit scores individually for better error tracking
            for (leaderboardID, score) in scores {
                submitScore(score, to: leaderboardID)
            }
            
            // Update last update time to prevent immediate re-submission
            lastLeaderboardUpdate = Date()
        } else {
            print("No scores to update: current scores are already submitted or zero")
        }
    }
    
    // MARK: - Helper Functions
    
    /// Gets the root view controller of the app
    /// - Returns: The root view controller if available
    private func getRootViewController() -> UIViewController? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            return rootViewController
        }
        return nil
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

// MARK: - GKLocalPlayerListener

extension GameCenterManager: GKLocalPlayerListener {
    func player(_ player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer]) {
        // Not used in this game, but required by the protocol
    }
    
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        // Not used in this game, but required by the protocol
    }
    
    func player(_ player: GKPlayer, didReceive challenge: GKChallenge) {
        // Handle any Game Center challenges
        print("Received Game Center challenge: \(challenge.description)")
    }
} 
