import SwiftUI
import GameKit

/// Displays Game Center information and provides buttons to access leaderboards and achievements
struct GameCenterView: View {
    @Environment(GameCenterManager.self) private var gameCenterManager
    
    // State variables to store leaderboard scores
    @State private var packagesScore: Int = 0
    @State private var moneyScore: Int = 0
    @State private var isLoadingScores: Bool = false
    @State private var scoreError: String? = nil
    @State private var lastRefreshTime = Date()
    @State private var showDebugInfo: Bool = false
    
    // Timer for auto-refreshing scores
    @State private var refreshTimer: Timer?
    
    // Dependency for manual score submissions
    @Environment(GameState.self) private var gameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Game Center")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Debug toggle button
                Button(action: {
                    showDebugInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                
                if let playerImage = gameCenterManager.playerProfileImage {
                    Image(uiImage: playerImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            
            if gameCenterManager.isAuthenticated {
                if let player = gameCenterManager.localPlayer {
                    Text("Welcome, \(player.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Display current leaderboard scores
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Your Stats")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        // Force submit button
                        Button(action: {
                            forceSubmitScores()
                        }) {
                            Label("Submit", systemImage: "arrow.up.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.2)))
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Packages")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            if isLoadingScores {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.white)
                            } else {
                                Text("\(packagesScore)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            // Debug info
                            if showDebugInfo {
                                HStack(spacing: 4) {
                                    Text("Game:")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Text("\(gameState.totalPackagesShipped)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                }
                                
                                HStack(spacing: 4) {
                                    Text("Cache:")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Text("\(gameCenterManager.lastSubmittedScores[GameCenterManager.totalPackagesLeaderboardID] ?? 0)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading) {
                            Text("Money Earned")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            if isLoadingScores {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.white)
                            } else {
                                Text("$\(moneyScore)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            // Debug info
                            if showDebugInfo {
                                HStack(spacing: 4) {
                                    Text("Game:")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Text("$\(Int(gameState.lifetimeTotalMoneyEarned))")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                }
                                
                                HStack(spacing: 4) {
                                    Text("Cache:")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Text("$\(gameCenterManager.lastSubmittedScores[GameCenterManager.totalMoneyLeaderboardID] ?? 0)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            loadPlayerScores()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Circle().fill(Color.blue.opacity(0.6)))
                        }
                    }
                    
                    if let error = scoreError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    
                    // Display last update time in debug mode
                    if showDebugInfo {
                        Text("Last updated: \(formattedDate(lastRefreshTime))")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
                
                HStack(spacing: 12) {
                    // Leaderboards button
                    Button(action: {
                        // Force refresh scores before showing
                        forceSubmitScores()
                        
                        // Show leaderboards after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            gameCenterManager.showLeaderboards()
                        }
                    }) {
                        HStack {
                            Image(systemName: "list.star")
                                .font(.system(size: 14, weight: .bold))
                            Text("Leaderboards")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    // Achievements button
                    Button(action: {
                        gameCenterManager.showAchievements()
                    }) {
                        HStack {
                            Image(systemName: "trophy")
                                .font(.system(size: 14, weight: .bold))
                            Text("Achievements")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            } else {
                HStack {
                    if let error = gameCenterManager.authenticationError {
                        Text("Authentication error: \(error)")
                            .font(.subheadline)
                            .foregroundColor(.red.opacity(0.8))
                            .padding()
                    } else {
                        Text("Not signed in")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        gameCenterManager.authenticatePlayer()
                    }) {
                        Text("Sign In")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.blue.opacity(0.5), lineWidth: 1.5)
                )
        )
        .onAppear {
            // Start with cached scores from GameCenterManager
            updateScoresFromCache()
            
            if gameCenterManager.isAuthenticated {
                loadPlayerScores()
            }
            
            // Start the refresh timer
            startRefreshTimer()
        }
        .onDisappear {
            // Clean up timer when view disappears
            stopRefreshTimer()
        }
        .onChange(of: gameCenterManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                loadPlayerScores()
                startRefreshTimer()
            } else {
                stopRefreshTimer()
            }
        }
    }
    
    /// Starts a timer to refresh scores periodically
    private func startRefreshTimer() {
        // Cancel any existing timer first
        stopRefreshTimer()
        
        // Create a new timer that fires every 3 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            
            // Update from cache first (immediate)
            self.updateScoresFromCache()
            
            // Check if we should do a full refresh from Game Center
            let now = Date()
            if now.timeIntervalSince(self.lastRefreshTime) >= 15.0 {  // Full refresh every 15 seconds
                self.loadPlayerScores()
                self.lastRefreshTime = now
            }
        }
    }
    
    /// Stops the refresh timer
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    /// Updates scores directly from GameCenterManager's cache
    private func updateScoresFromCache() {
        if let packageScore = gameCenterManager.lastSubmittedScores[GameCenterManager.totalPackagesLeaderboardID] {
            packagesScore = packageScore
        }
        
        if let moneyScore = gameCenterManager.lastSubmittedScores[GameCenterManager.totalMoneyLeaderboardID] {
            self.moneyScore = moneyScore
        }
    }
    
    /// Loads the player's current scores from Game Center
    private func loadPlayerScores() {
        guard gameCenterManager.isAuthenticated else { return }
        
        isLoadingScores = true
        scoreError = nil
        
        // Update from cache immediately first
        updateScoresFromCache()
        
        // Fetch latest scores from Game Center
        let leaderboardIDs = [
            GameCenterManager.totalPackagesLeaderboardID,
            GameCenterManager.totalMoneyLeaderboardID
        ]
        
        GKLeaderboard.loadLeaderboards(IDs: leaderboardIDs) { leaderboards, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.scoreError = "Could not load scores"
                    self.isLoadingScores = false
                }
                print("Error loading leaderboards: \(error.localizedDescription)")
                return
            }
            
            // Array of leaderboard scores to load
            var localPlayerScores: [(leaderboardID: String, entry: GKLeaderboard.Entry)] = []
            
            // Create a dispatch group to wait for all score requests
            let group = DispatchGroup()
            
            // Process each leaderboard
            if let leaderboards = leaderboards {
                for leaderboard in leaderboards {
                    group.enter()
                    leaderboard.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime) { playerEntry, entries, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error loading entries for \(leaderboard.title): \(error.localizedDescription)")
                            return
                        }
                        
                        if let playerEntry = playerEntry {
                            // Store the entry along with its leaderboard ID
                            localPlayerScores.append((leaderboardID: leaderboard.baseLeaderboardID, entry: playerEntry))
                        }
                    }
                }
            }
            
            // When all scores have been loaded
            group.notify(queue: .main) {
                self.isLoadingScores = false
                
                // Process the loaded scores
                for (leaderboardID, entry) in localPlayerScores {
                    if leaderboardID == GameCenterManager.totalPackagesLeaderboardID {
                        self.packagesScore = entry.score
                    } else if leaderboardID == GameCenterManager.totalMoneyLeaderboardID {
                        self.moneyScore = entry.score
                    }
                }
            }
        }
    }
    
    /// Formats a date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    /// Forces immediate submission of current scores to Game Center
    private func forceSubmitScores() {
        if gameCenterManager.isAuthenticated {
            // Force a refresh of the scores
            gameCenterManager.forceRefreshScores(gameState)
            
            // Update our local display
            updateScoresFromCache()
            
            // Set refresh time 
            lastRefreshTime = Date()
        }
    }
}

#Preview {
    GameCenterView()
        .environment(GameCenterManager())
        .preferredColorScheme(.dark)
        .padding()
        .background(Color(red: 0.1, green: 0.2, blue: 0.3))
} 
