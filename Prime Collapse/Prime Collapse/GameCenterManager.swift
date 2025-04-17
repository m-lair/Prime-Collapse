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
    private let leaderboardUpdateInterval: TimeInterval = 5.0
    
    /// Minimum interval between achievement updates (in seconds)
    private let achievementUpdateInterval: TimeInterval = 5.0
    
    /// Cache of last submitted scores to avoid duplicate submissions
    private var lastSubmittedScores: [String: Int] = [:]
    
    /// Cache of last reported achievement progresses to avoid duplicate reports
    private var lastReportedAchievements: [String: Double] = [:]
    
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
        guard isAuthenticated, let rootViewController = getRootViewController() else {
            print("Cannot show leaderboards: Player not authenticated or no root view controller")
            return
        }
        
        let gcViewController = GKGameCenterViewController(state: .leaderboards)
        gcViewController.gameCenterDelegate = self
        rootViewController.present(gcViewController, animated: true)
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
        
        // Update the cache
        lastSubmittedScores[leaderboardID] = score
        
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Error submitting score to leaderboard \(leaderboardID): \(error.localizedDescription)")
            } else {
                print("Successfully submitted score \(score) to leaderboard \(leaderboardID)")
            }
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
            // Submit scores to leaderboards
            submitScore(gameState.totalPackagesShipped, to: Self.totalPackagesLeaderboardID)
            submitScore(Int(gameState.money), to: Self.totalMoneyLeaderboardID)
            
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
            
            lastAchievementUpdate = now
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
