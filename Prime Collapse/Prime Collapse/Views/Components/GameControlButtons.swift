import SwiftUI
import SwiftData

struct GameControlButtons: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        // This view is now primarily a container for SettingsView
        // The actual buttons are triggered from ContentView
        // We keep the helper functions here for now, associated with SettingsView
        EmptyView() // Or some placeholder if needed, body cannot be empty
    }
    
    // Updated button style to match dashboard design
    private func gameButtonLabel(systemName: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(
                    ZStack {
                        Circle()
                            .fill(buttonIconColor(for: text).opacity(0.3))
                        
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(
                                        colors: [
                                            buttonIconColor(for: text).opacity(0.8),
                                            buttonIconColor(for: text).opacity(0.4)
                                        ]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
                .shadow(color: buttonIconColor(for: text).opacity(0.5), radius: 3, x: 0, y: 2)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                // Base shape
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    buttonColor(for: text).opacity(0.2),
                                    Color.clear
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    buttonColor(for: text).opacity(0.5),
                                    buttonColor(for: text).opacity(0.1)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // Return appropriate color based on button type
    private func buttonColor(for buttonText: String) -> Color {
        switch buttonText {
        case "Reset":
            return Color(red: 0.1, green: 0.5, blue: 0.85)
        case "Settings":
            return Color(red: 0.25, green: 0.6, blue: 0.8)
        case "Quit":
            return Color(red: 0.85, green: 0.25, blue: 0.25)
        default:
            return Color.blue
        }
    }
    
    // Icon color for buttons
    private func buttonIconColor(for buttonText: String) -> Color {
        switch buttonText {
        case "Reset":
            return .blue
        case "Settings":
            return .cyan
        case "Quit":
            return .red
        default:
            return .blue
        }
    }
}

// Settings view for game settings
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var gameState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(SaveManager.self) private var saveManager
    
    // State variables for dialog confirmation
    @State private var showingResetConfirmation = false
    @State private var showingQuitConfirmation = false
    @State private var showingResetSaveConfirmation = false
    @State private var showingSaveDataInfo = false
    
    // State to hold save data information
    @State private var saveDataInfo: String = "No save data found"
    @Query private var savedGames: [SavedGameState]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching dashboard style
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.3),
                        Color(red: 0.15, green: 0.25, blue: 0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Game settings section
                    settingsSection(title: "GAME CONTROLS") {
                        // Reset Button
                        Button(action: {
                            showingResetConfirmation = true
                            playHaptic(.light)
                        }) {
                            settingsButtonView(
                                icon: "arrow.counterclockwise",
                                title: "Reset Game",
                                iconColor: .red
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Reset Save Data Button (new)
                        Button(action: {
                            showingResetSaveConfirmation = true
                            playHaptic(.medium)
                        }) {
                            settingsButtonView(
                                icon: "trash",
                                title: "Delete Save Data",
                                iconColor: .orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Quit Game Button
                        Button(action: { 
                            showingQuitConfirmation = true
                            playHaptic(.light)
                        }) {
                            settingsButtonView(
                                icon: "xmark.circle",
                                title: "Quit Game",
                                iconColor: .red
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Save Data Info Button (new)
                        Button(action: {
                            loadSaveDataInfo()
                            showingSaveDataInfo = true
                            playHaptic(.light)
                        }) {
                            settingsButtonView(
                                icon: "info.circle",
                                title: "Save Data Info",
                                iconColor: .blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Audio settings section
                    settingsSection(title: "AUDIO SETTINGS") {
                        toggleSettingView(
                            icon: "speaker.wave.2.fill",
                            title: "Sound Effects",
                            isOn: .constant(true),
                            iconColor: .blue
                        )
                        
                        toggleSettingView(
                            icon: "music.note",
                            title: "Background Music",
                            isOn: .constant(true),
                            iconColor: .purple
                        )
                    }
                    
                    // About section
                    settingsSection(title: "ABOUT") {
                        infoSettingView(
                            icon: "info.circle",
                            title: "Version",
                            value: "Prime Collapse v1.0",
                            iconColor: .cyan
                        )
                        
                        infoSettingView(
                            icon: "person.fill",
                            title: "Developer",
                            value: "Prime Games",
                            iconColor: .green
                        )
                    }
                }
                .padding(.horizontal)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(.white)
        .alert("Reset Game", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetGame()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to reset the game? All progress will be lost but your saved data will remain intact.")
        }
        .alert("Delete Save Data", isPresented: $showingResetSaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                resetSaveData()
                dismiss()
            }
        } message: {
            Text("This will permanently delete all saved game data. This action cannot be undone.")
        }
        .alert("Quit Game", isPresented: $showingQuitConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Quit", role: .destructive) {
                quitGame()
                // Optionally dismiss, though quitGame might exit or change view state
                // dismiss()
            }
        } message: {
            Text("Are you sure you want to quit the game? All unsaved progress will be lost.")
        }
        .alert("Save Data Info", isPresented: $showingSaveDataInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveDataInfo)
        }
    }
    
    // Settings section view
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 8)
            
            // Section content
            VStack(spacing: 8) {
                content()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
    
    // Button style view for settings
    private func settingsButtonView(icon: String, title: String, iconColor: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.3))
                        
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [iconColor.opacity(0.8), iconColor.opacity(0.4)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
                .shadow(color: iconColor.opacity(0.5), radius: 3, x: 0, y: 2)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
    
    // Toggle style view for settings
    private func toggleSettingView(icon: String, title: String, isOn: Binding<Bool>, iconColor: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.3))
                        
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [iconColor.opacity(0.8), iconColor.opacity(0.4)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
                .shadow(color: iconColor.opacity(0.5), radius: 3, x: 0, y: 2)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: iconColor))
        }
        .padding(.vertical, 8)
    }
    
    // Info style view for settings
    private func infoSettingView(icon: String, title: String, value: String, iconColor: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.3))
                        
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [iconColor.opacity(0.8), iconColor.opacity(0.4)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
                .shadow(color: iconColor.opacity(0.5), radius: 3, x: 0, y: 2)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
    
    // Action to reset the game
    private func resetGame() {
        gameState.reset()
        playHaptic(.medium)
    }
    
    // Action to reset save data
    private func resetSaveData() {
        saveManager.resetDatabase()
        playHaptic(.heavy)
    }
    
    // Action to quit the game
    private func quitGame() {
        // Save before quitting
        saveManager.saveGameState()
        
        // Exit the app - note this may be rejected in App Store review
        // Consider alternative approaches like returning to a main menu
        exit(0)
    }
    
    // Play haptic feedback
    private func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // Load save data information
    private func loadSaveDataInfo() {
        if savedGames.isEmpty {
            saveDataInfo = "No save data found."
            return
        }
        
        let savedGame = savedGames.first!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let saveDate = dateFormatter.string(from: savedGame.savedAt)
        let saveVersion = savedGame.saveVersion
        let appVersion = savedGame.appVersionString
        
        saveDataInfo = """
        Save Date: \(saveDate)
        Schema Version: \(saveVersion)
        App Version: \(appVersion)
        
        Game Stats:
        Money: \(String(format: "%.2f", savedGame.money))
        Packages: \(savedGame.totalPackagesShipped)
        Workers: \(savedGame.workers)
        Ethics Score: \(String(format: "%.1f", savedGame.ethicsScore))
        """
    }
}

#Preview {
    GameControlButtons()
        .environment(GameState())
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
} 
