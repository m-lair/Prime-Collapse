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
    @Environment(GameCenterManager.self) private var gameCenterManager
    @Environment(EventManager.self) private var eventManager
    @State private var gameTask: Task<Void, Never>?
    @Query private var savedGames: [SavedGameState]
    @Environment(\.modelContext) private var modelContext
    
    // State for showing/hiding detailed stats overlay
    @State private var showDetailedStatsOverlay = false
    
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
                    
                    GameStatsView(isShowingDetails: $showDetailedStatsOverlay)
                        .padding(.horizontal)
                }
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
                )
                
                Spacer()
                
                // Main tap button
                ShipPackageButton()
                
                Spacer()
                
                // Upgrade section
                UpgradeListView()
                    .padding(.bottom, 16)
            }
            
            // --- Detailed Stats Overlay Layer ---
            // Positioned within the ZStack, appears when showDetailedStatsOverlay is true
            if showDetailedStatsOverlay {
                VStack {
                    // Spacer to push the overlay down below the header area
                    // Adjust the height based on the actual header height
                    Spacer(minLength: 180) // Approximate height of header + basic GameStatsView
                    
                    DetailedStatsOverlayView()
                        .padding(.horizontal) // Add horizontal padding
                    
                    Spacer() // Pushes the overlay towards the top spacer
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .move(edge: .top))) // Slide down + fade
                .zIndex(1) // Ensure it's above the main content layer
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
            
            // Event overlay
            EventView()
        }
        .animation(.easeInOut(duration: 0.3), value: showDetailedStatsOverlay) // Animate overlay appearance
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
        // Collapse detailed stats when an event appears
        .onChange(of: eventManager.currentEvent) {
            if eventManager.currentEvent != nil {
                withAnimation {
                    showDetailedStatsOverlay = false
                }
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
            DashboardView()
        }
    }
    
    private func startGameLoop() {
        // Cancel any existing task
        gameTask?.cancel()
        
        // Use Combine's Timer publisher as an AsyncSequence driving the game loop
        let updateInterval = 0.1 // 100ms
        let timer = Timer.publish(every: updateInterval, on: .main, in: .common).autoconnect()
        gameTask = Task {
            do {
                for try await currentTime in timer.values {
                    // Exit if cancelled
                    if Task.isCancelled { break }
                    // Process automation and events on the main actor
                    gameState.processAutomation(currentTime: currentTime)
                    eventManager.checkForEvents(gameState: gameState, currentTime: currentTime)
                }
            } catch is CancellationError {
                // Task was cancelled, exit gracefully
            } catch {
                print("Game loop timer error: \(error)")
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
            
            // Update Game Center with the latest stats
            gameCenterManager.updateFromGameState(gameState)
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

// MARK: - Detailed Stats Overlay View

struct DetailedStatsOverlayView: View {
    @Environment(GameState.self) private var gameState
    
    // Re-add helper properties/methods needed for detailed stats
    // (Copied from the previous version of GameStatsView)
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Worker metrics
                StatCard(
                    icon: "gauge.medium",
                    title: "Worker Efficiency",
                    value: "\(String(format: "%.2f", gameState.workerEfficiency))×",
                    secondaryText: workerEfficiencyLabel,
                    iconColor: .indigo
                )
                
                // Automation metrics
                StatCard(
                    icon: "gearshape.2.fill",
                    title: "Automation",
                    value: "\(String(format: "%.2f", gameState.automationEfficiency))×",
                    secondaryText: "Efficiency Multiplier",
                    iconColor: .mint
                )
            }
            
            HStack(spacing: 16) {
                // Worker morale
                StatCard(
                    icon: "face.smiling.fill",
                    title: "Worker Morale",
                    value: moraleRatingText,
                    secondaryText: moraleLabel,
                    iconColor: moraleColor
                )
                
                // Customer satisfaction
                StatCard(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "Customer Sat.",
                    value: customerSatisfactionRatingText,
                    secondaryText: customerSatisfactionLabel,
                    iconColor: customerSatisfactionColor
                )
            }
            
            // Corporate ethics and effective rate
            HStack(spacing: 16) {
                // Corporate ethics
                StatCard(
                    icon: "building.2.fill",
                    title: "Corp Virtue",
                    value: corporateVirtueRatingText,
                    secondaryText: corporateEthicsLabel,
                    iconColor: corporateEthicsColor
                )
                
                // Effective automation rate
                let workerContribution = gameState.baseWorkerRate * Double(gameState.workers) * gameState.workerEfficiency
                let systemContribution = gameState.baseSystemRate * gameState.automationEfficiency
                let effectiveRate = workerContribution + systemContribution
                StatCard(
                    icon: "bolt.horizontal.fill",
                    title: "Effective Rate",
                    value: "\(String(format: "%.2f", effectiveRate))/sec",
                    secondaryText: "$\(String(format: "%.2f", effectiveRate * gameState.packageValue))/sec",
                    iconColor: .orange
                )
            }
        }
        .padding() // Add padding around the content
        .background(.ultraThinMaterial) // Use a material background
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 5)
    }
    
    // --- Helper methods for detailed stats (Copied back) --- 
    private var workerEfficiencyLabel: String {
        if gameState.workerEfficiency < 1.0 { return "Poor Performance" }
        else if gameState.workerEfficiency < 1.5 { return "Standard Output" }
        else if gameState.workerEfficiency < 2.0 { return "High Productivity" }
        else { return "Maximum Output" }
    }
    
    private var moraleLabel: String {
        if gameState.workerMorale < 0.3 { return "Near Rebellion" }
        else if gameState.workerMorale < 0.5 { return "Discontent" }
        else if gameState.workerMorale < 0.7 { return "Neutral" }
        else if gameState.workerMorale < 0.9 { return "Satisfied" }
        else { return "Highly Motivated" }
    }
    
    private var moraleRatingText: String {
        if gameState.workerMorale < 0.3 { return "Very Low" }
        else if gameState.workerMorale < 0.5 { return "Low" }
        else if gameState.workerMorale < 0.7 { return "Moderate" }
        else if gameState.workerMorale < 0.9 { return "High" }
        else { return "Excellent" }
    }
    
    private var moraleColor: Color {
        if gameState.workerMorale < 0.3 { return .red }
        else if gameState.workerMorale < 0.5 { return .orange }
        else if gameState.workerMorale < 0.7 { return .yellow }
        else if gameState.workerMorale < 0.9 { return .green }
        else { return .mint }
    }
    
    private var customerSatisfactionLabel: String {
        if gameState.customerSatisfaction < 0.3 { return "Outraged" }
        else if gameState.customerSatisfaction < 0.5 { return "Dissatisfied" }
        else if gameState.customerSatisfaction < 0.7 { return "Acceptable" }
        else if gameState.customerSatisfaction < 0.9 { return "Satisfied" }
        else { return "Delighted" }
    }
    
    private var customerSatisfactionRatingText: String {
        if gameState.customerSatisfaction < 0.3 { return "Very Poor" }
        else if gameState.customerSatisfaction < 0.5 { return "Poor" }
        else if gameState.customerSatisfaction < 0.7 { return "Adequate" }
        else if gameState.customerSatisfaction < 0.9 { return "Good" }
        else { return "Excellent" }
    }
    
    private var customerSatisfactionColor: Color {
        if gameState.customerSatisfaction < 0.3 { return .red }
        else if gameState.customerSatisfaction < 0.5 { return .orange }
        else if gameState.customerSatisfaction < 0.7 { return .yellow }
        else if gameState.customerSatisfaction < 0.9 { return .green }
        else { return .mint }
    }
    
    private var corporateEthicsLabel: String {
        if gameState.corporateEthics < 0.3 { return "Corruption" }
        else if gameState.corporateEthics < 0.5 { return "Shady Practices" }
        else if gameState.corporateEthics < 0.7 { return "Standard Business" }
        else if gameState.corporateEthics < 0.9 { return "Ethical Business" }
        else { return "Industry Leader" }
    }
    
    private var corporateVirtueRatingText: String {
        if gameState.corporateEthics < 0.3 { return "Very Low" }
        else if gameState.corporateEthics < 0.5 { return "Low" }
        else if gameState.corporateEthics < 0.7 { return "Moderate" }
        else if gameState.corporateEthics < 0.9 { return "High" }
        else { return "Exemplary" }
    }
    
    private var corporateEthicsColor: Color {
        if gameState.corporateEthics < 0.3 { return .red }
        else if gameState.corporateEthics < 0.5 { return .orange }
        else if gameState.corporateEthics < 0.7 { return .yellow }
        else if gameState.corporateEthics < 0.9 { return .green }
        else { return .mint }
    }
}

#Preview {
    ContentView()
}
