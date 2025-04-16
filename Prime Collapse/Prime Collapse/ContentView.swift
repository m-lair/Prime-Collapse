//
//  ContentView.swift
//  Prime Collapse
//
//  Created by Marcus Lair on 4/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(GameState.self) private var gameState
    @State private var gameTask: Task<Void, Never>?
    @Query private var savedGames: [SavedGameState]
    @Environment(\.modelContext) private var modelContext
    
    // Animation states for collapse phase
    @State private var showCollapseAlert = false
    @State private var glitchEffect = false
    @State private var slowdownFactor: Double = 1.0
    @State private var showEndingScreen = false
    @State private var showDashboard = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    gameState.isCollapsing ? Color(red: 0.3, green: 0.1, blue: 0.1) : Color(red: 0.1, green: 0.2, blue: 0.3),
                    gameState.isCollapsing ? Color(red: 0.5, green: 0.1, blue: 0.1) : Color(red: 0.2, green: 0.3, blue: 0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Game content
            VStack(spacing: 0) {
                // Header with title and stats
                VStack(spacing: 2) {
                    Text("Prime Collapse")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 12)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                    
                    GameStatsView(gameState: gameState)
                        .padding(.horizontal)
                }
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
                )
                
                Spacer()
                
                // Main tap button
                ShipPackageButton(gameState: gameState)
                
                Spacer()
                
                // Upgrade section
                UpgradeListView(gameState: gameState)
                    .padding(.bottom, 16)
            }
            
            // Dashboard button
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showDashboard = true
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.8))
                                    .shadow(color: .black.opacity(0.3), radius: 3)
                            )
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
            
            // Collapse effects overlay
            if gameState.isCollapsing {
                CollapseEffectsView(showCollapseAlert: $showCollapseAlert)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: glitchEffect)
        .animation(.easeInOut(duration: 0.5), value: gameState.isCollapsing)
        .onAppear {
            loadGameState()
            startGameLoop()
            
            // If we're already in collapse state, show effects
            if gameState.isCollapsing {
                startCollapseEffects()
            }
        }
        .onDisappear {
            saveGameState()
            stopGameLoop()
        }
        // Save game state periodically
        .onChange(of: gameState.totalPackagesShipped) { _, _ in
            saveGameStateDebounced()
        }
        // Start collapse effects when entering collapse phase
        .onChange(of: gameState.isCollapsing) { _, isCollapsing in
            if isCollapsing {
                playHaptic(.heavy) // Strong haptic for collapse
                startCollapseEffects()
            }
        }
        // Show the collapse alert dialog
        .alert("Economic Collapse Imminent", isPresented: $showCollapseAlert) {
            Button("Continue", role: .destructive) {
                // After a brief delay, show the ending screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    stopGameLoop()
                    showEndingScreen = true
                }
            }
            Button("Reset", role: .cancel) {
                gameState.reset()
            }
        } message: {
            Text("Your corporate ethics have reached an unsustainable level. The economy is collapsing!")
        }
        .fullScreenCover(isPresented: $showEndingScreen) {
            GameEndingView(
                gameEnding: gameState.endingType,
                packagesShipped: gameState.totalPackagesShipped,
                profit: gameState.money,
                workerCount: gameState.workers,
                onReset: {
                    gameState.reset()
                    showEndingScreen = false
                    startGameLoop()
                }
            )
        }
        .sheet(isPresented: $showDashboard) {
            DashboardView(gameState: gameState)
        }
    }
    
    private func startGameLoop() {
        // Cancel any existing task
        gameTask?.cancel()
        
        // Create a new Task that won't be affected by UI interactions
        gameTask = Task {
            // Timer loop using Task
            let updateInterval = 0.1 // 100ms
            
            while !Task.isCancelled {
                // Process game updates
                await MainActor.run {
                    gameState.processAutomation(currentTime: Date())
                }
                
                // Wait for the next update interval
                try? await Task.sleep(for: .seconds(updateInterval))
            }
        }
    }
    
    private func stopGameLoop() {
        gameTask?.cancel()
        gameTask = nil
    }
    
    private func startCollapseEffects() {
        // Start the visual glitch effect
        startGlitchingEffect()
        
        // Show the alert after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showCollapseAlert = true
        }
        
        // Slow down the automation
        slowdownFactor = 0.5
    }
    
    private func startGlitchingEffect() {
        // Create a repeating timer that toggles the glitch effect
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            guard gameState.isCollapsing else {
                timer.invalidate()
                return
            }
            
            glitchEffect.toggle()
        }
    }
    
    // Play haptic feedback based on intensity level
    private func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // Save debouncer to avoid saving too frequently
    @State private var saveTask: Task<Void, Error>?
    private func saveGameStateDebounced() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled {
                saveGameState()
            }
        }
    }
    
    private func saveGameState() {
        // Only save if we've made some progress
        guard gameState.totalPackagesShipped > 0 else { return }
        
        // Delete any existing saved games
        for game in savedGames {
            modelContext.delete(game)
        }
        
        // Create a new saved game state
        let savedState = SavedGameState.from(gameState: gameState)
        modelContext.insert(savedState)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving game: \(error)")
        }
    }
    
    private func loadGameState() {
        // Load the most recently saved game if one exists
        if let savedGame = savedGames.first {
            savedGame.apply(to: gameState)
        }
    }
}

#Preview {
    ContentView()
}
