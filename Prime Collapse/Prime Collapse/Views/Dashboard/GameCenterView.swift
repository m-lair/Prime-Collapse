import SwiftUI
import GameKit

/// Displays Game Center information and provides buttons to access leaderboards and achievements
struct GameCenterView: View {
    @Environment(GameCenterManager.self) private var gameCenterManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Game Center")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
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
                
                HStack(spacing: 12) {
                    // Leaderboards button
                    Button(action: {
                        gameCenterManager.showLeaderboards()
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
    }
}

#Preview {
    GameCenterView()
        .environment(GameCenterManager())
        .preferredColorScheme(.dark)
        .padding()
        .background(Color(red: 0.1, green: 0.2, blue: 0.3))
} 