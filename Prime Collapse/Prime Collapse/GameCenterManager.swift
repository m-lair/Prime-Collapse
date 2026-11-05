import SwiftUI
import GameKit

/// Manages Game Center functionality including authentication, leaderboards, and achievements
@Observable final class GameCenterManager: NSObject {
    typealias ScoreSubmitter = (Int, String, @escaping @MainActor (Error?) -> Void) -> Void

    private let submitLeaderboardScore: ScoreSubmitter
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
    private(set) var lastSubmittedScores: [String: Int] = [:]
    private var inFlightScores: [String: Int] = [:]
    
    /// Cache of last reported achievement progresses to avoid duplicate reports
    private var lastReportedAchievements: [String: Double] = [:]
    
    /// Pending leaderboard updates that failed and need to be retried
    private var pendingLeaderboardUpdates: [String: Int] = [:]
    
    /// Maximum number of retry attempts for leaderboard submissions
    private let maxRetryAttempts = 3
    
    /// Background task for retrying failed leaderboard submissions
    private var retryTask: Task<Void, Never>?
    
    // MARK: - Leaderboard IDs
    
    /// Leaderboard for total packages shipped
    static let totalPackagesLeaderboardID = "total_packages_shipped"
    
    /// Leaderboard for total money earned
    static let totalMoneyLeaderboardID = "total_money_earned"
    
    /// Leaderboard for highest ethics score achieved
    static let highestEthicsScoreLeaderboardID = "highest_ethics_score"
    
    /// Leaderboard for packages per second rate
    static let packagesPerSecondLeaderboardID = "packages_per_second"
    
    /// Leaderboard for total workers hired
    static let totalWorkersLeaderboardID = "total_workers_hired"
    
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
    
    /// Achievement for reaching the loop ending
    static let loopEndingAchievementID = "loop_ending"
    
    /// Achievement for shipping 100 packages
    static let packages100AchievementID = "packages_100"
    
    /// Achievement for shipping 1,000 packages
    static let packages1000AchievementID = "packages_1000"
    
    /// Achievement for shipping 10,000 packages
    static let packages10000AchievementID = "packages_10000"
    
    /// Achievement for earning $1,000
    static let money1000AchievementID = "money_1000"
    
    /// Achievement for earning $10,000
    static let money10000AchievementID = "money_10000"
    
    /// Achievement for earning $100,000
    static let money100000AchievementID = "money_100000"
    
    /// Achievement for hiring 10 workers
    static let workers10AchievementID = "workers_10"
    
    /// Achievement for hiring 50 workers
    static let workers50AchievementID = "workers_50"
    
    /// Achievement for reaching maximum automation efficiency
    static let maxAutomationAchievementID = "max_automation"
    
    /// Achievement for maintaining perfect ethics
    static let perfectEthicsAchievementID = "perfect_ethics"
    
    // MARK: - Initialization
    
    init(submitLeaderboardScore: @escaping ScoreSubmitter = { score, leaderboardID, completion in
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            Task { @MainActor in completion(error) }
        }
    }) {
        self.submitLeaderboardScore = submitLeaderboardScore
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
            Self.reformEndingAchievementID,
            Self.loopEndingAchievementID,
            Self.packages100AchievementID,
            Self.packages1000AchievementID,
            Self.packages10000AchievementID,
            Self.money1000AchievementID,
            Self.money10000AchievementID,
            Self.money100000AchievementID,
            Self.workers10AchievementID,
            Self.workers50AchievementID,
            Self.maxAutomationAchievementID,
            Self.perfectEthicsAchievementID
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
        let leaderboardIDs = [Self.totalPackagesLeaderboardID, Self.totalMoneyLeaderboardID, Self.highestEthicsScoreLeaderboardID, Self.packagesPerSecondLeaderboardID, Self.totalWorkersLeaderboardID]
        
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
    
    /// Only acknowledged scores enter the cache used to suppress duplicate uploads.
    func submitScore(_ score: Int, to leaderboardID: String) {
        guard isAuthenticated else { return }
        let score = max(score, pendingLeaderboardUpdates[leaderboardID] ?? score)
        if let confirmed = lastSubmittedScores[leaderboardID], confirmed >= score { return }
        if let inFlight = inFlightScores[leaderboardID], inFlight >= score { return }

        inFlightScores[leaderboardID] = score
        submitLeaderboardScore(score, leaderboardID) { [weak self] error in
            guard let self else { return }
            if self.inFlightScores[leaderboardID] == score {
                self.inFlightScores.removeValue(forKey: leaderboardID)
            }

            if let error {
                print("Error submitting score to \(leaderboardID): \(error.localizedDescription)")
                if let confirmed = self.lastSubmittedScores[leaderboardID], confirmed >= score { return }
                self.pendingLeaderboardUpdates[leaderboardID] = max(
                    self.pendingLeaderboardUpdates[leaderboardID] ?? score, score
                )
                self.startRetryMechanismIfNeeded()
            } else {
                self.recordSuccessfulScore(score, for: leaderboardID)
            }
        }
    }

    func submitBatchScores(_ scores: [String: Int]) {
        for (leaderboardID, score) in scores {
            submitScore(score, to: leaderboardID)
        }
    }

    private func recordSuccessfulScore(_ score: Int, for leaderboardID: String) {
        lastSubmittedScores[leaderboardID] = max(lastSubmittedScores[leaderboardID] ?? score, score)
        if let pending = pendingLeaderboardUpdates[leaderboardID], pending <= score {
            pendingLeaderboardUpdates.removeValue(forKey: leaderboardID)
        }
    }

    private func startRetryMechanismIfNeeded() {
        guard retryTask == nil else { return }
        retryTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.retryTask = nil }

            for attempt in 0..<self.maxRetryAttempts {
                guard !self.pendingLeaderboardUpdates.isEmpty else { return }
                do {
                    try await Task.sleep(for: .seconds(pow(2.0, Double(attempt))))
                } catch {
                    return
                }
                guard self.isAuthenticated, !Task.isCancelled else { return }

                let updates = self.pendingLeaderboardUpdates
                for (leaderboardID, score) in updates {
                    if let confirmed = self.lastSubmittedScores[leaderboardID], confirmed >= score {
                        continue
                    }
                    guard self.inFlightScores[leaderboardID] == nil else { continue }
                    self.inFlightScores[leaderboardID] = score
                    let succeeded = await withCheckedContinuation { continuation in
                        self.submitLeaderboardScore(score, leaderboardID) { error in
                            continuation.resume(returning: error == nil)
                        }
                    }
                    if self.inFlightScores[leaderboardID] == score {
                        self.inFlightScores.removeValue(forKey: leaderboardID)
                    }
                    if succeeded {
                        self.recordSuccessfulScore(score, for: leaderboardID)
                    }
                }
            }
            // Keep the highest failed scores eligible for the next save or manual refresh.
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
        
        if now.timeIntervalSince(lastLeaderboardUpdate) >= leaderboardUpdateInterval {
            submitBatchScores(leaderboardScores(from: gameState))
            lastLeaderboardUpdate = now
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
            
            // Loop ending
            if gameState.endingType == .loop {
                reportAchievement(achievementID: Self.loopEndingAchievementID, percentComplete: 100.0)
            }
            
            // Shipping 100 packages
            if gameState.totalPackagesShipped >= 100 {
                reportAchievement(achievementID: Self.packages100AchievementID, percentComplete: 100.0)
            }
            
            // Shipping 1,000 packages
            if gameState.totalPackagesShipped >= 1000 {
                reportAchievement(achievementID: Self.packages1000AchievementID, percentComplete: 100.0)
            }
            
            // Shipping 10,000 packages
            if gameState.totalPackagesShipped >= 10000 {
                reportAchievement(achievementID: Self.packages10000AchievementID, percentComplete: 100.0)
            }
            
            // Earning $1,000
            if gameState.lifetimeTotalMoneyEarned >= 1000 {
                reportAchievement(achievementID: Self.money1000AchievementID, percentComplete: 100.0)
            }
            
            // Earning $10,000
            if gameState.lifetimeTotalMoneyEarned >= 10000 {
                reportAchievement(achievementID: Self.money10000AchievementID, percentComplete: 100.0)
            }
            
            // Earning $100,000
            if gameState.lifetimeTotalMoneyEarned >= 100000 {
                reportAchievement(achievementID: Self.money100000AchievementID, percentComplete: 100.0)
            }
            
            // Hiring 10 workers
            if gameState.workers >= 10 {
                reportAchievement(achievementID: Self.workers10AchievementID, percentComplete: 100.0)
            }
            
            // Hiring 50 workers
            if gameState.workers >= 50 {
                reportAchievement(achievementID: Self.workers50AchievementID, percentComplete: 100.0)
            }
            
            // Reaching maximum automation efficiency
            let maxAutomationProgress = min(gameState.automationEfficiency * 100.0, 100.0)
            reportAchievement(achievementID: Self.maxAutomationAchievementID, percentComplete: maxAutomationProgress)
            
            // Maintaining perfect ethics
            let perfectEthicsProgress = gameState.ethicalChoicesMade == 5 ? 100.0 : 0.0
            reportAchievement(achievementID: Self.perfectEthicsAchievementID, percentComplete: perfectEthicsProgress)
            
            lastAchievementUpdate = now
        }
    }
    
    /// Bypasses the update interval, while still skipping confirmed or in-flight scores.
    func forceRefreshScores(_ gameState: GameState) {
        guard isAuthenticated else { return }
        submitBatchScores(leaderboardScores(from: gameState).filter { $0.value > 0 })
        lastLeaderboardUpdate = Date()
    }

    private func leaderboardScores(from gameState: GameState) -> [String: Int] {
        let workerContribution = gameState.baseWorkerRate * Double(gameState.workers) * gameState.workerEfficiency
        let systemContribution = gameState.baseSystemRate * gameState.automationEfficiency
        return [
            Self.totalPackagesLeaderboardID: gameState.totalPackagesShipped,
            Self.totalMoneyLeaderboardID: Int(gameState.lifetimeTotalMoneyEarned),
            Self.highestEthicsScoreLeaderboardID: Int(gameState.ethicsScore),
            Self.packagesPerSecondLeaderboardID: Int((workerContribution + systemContribution) * 100),
            Self.totalWorkersLeaderboardID: gameState.workers
        ]
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
