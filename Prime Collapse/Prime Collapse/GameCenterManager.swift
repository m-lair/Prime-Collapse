import SwiftUI
import GameKit

/// Manages Game Center functionality including authentication, leaderboards, and achievements
@Observable final class GameCenterManager: NSObject {
    // MARK: - Properties
    
    /// Whether the user is authenticated with Game Center
    var isAuthenticated = false
    
    /// The current player's Game Center profile
    var localPlayer: GKLocalPlayer?
    
    /// The current player's profile image
    var playerProfileImage: UIImage?
    
    /// Error message if authentication fails
    var authenticationError: String?
    
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
        authenticatePlayer()
    }
    
    // MARK: - Authentication
    
    /// Authenticates the local player with Game Center
    func authenticatePlayer() {
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
                
                // Register for challenges
                GKLocalPlayer.local.register(self)
            } else {
                self.isAuthenticated = false
                self.authenticationError = "Player is not authenticated"
                print("Game Center authentication failed: Player is not authenticated")
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
            print("Cannot submit score: Player not authenticated")
            return
        }
        
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
            print("Cannot report achievement: Player not authenticated")
            return
        }
        
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
            }
        }
    }
    
    // MARK: - GameState Integration
    
    /// Updates Game Center with the current game state
    /// - Parameter gameState: The current game state
    func updateFromGameState(_ gameState: GameState) {
        // Submit scores to leaderboards
        submitScore(gameState.totalPackagesShipped, to: Self.totalPackagesLeaderboardID)
        submitScore(Int(gameState.money), to: Self.totalMoneyLeaderboardID)
        
        // Update achievements
        
        // First worker hired
        if gameState.workers >= 1 {
            reportAchievement(achievementID: Self.firstWorkerAchievementID, percentComplete: 100.0)
        }
        
        // Automation milestone (10 packages/sec)
        let automationProgress = min(gameState.automationRate / 10.0 * 100.0, 100.0)
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
