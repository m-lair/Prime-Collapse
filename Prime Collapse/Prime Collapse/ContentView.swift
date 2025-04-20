//
//  ContentView.swift
//  Prime Collapse
//
//  Created by Marcus Lair on 4/15/25.
//

import SwiftUI
import SwiftData
import Observation
import Combine
import UIKit
import GameKit

// Value decrease animation model has been moved to Models/Animations/ValueDecrease.swift

// Worker quit notification model has been moved to Models/Animations/WorkerQuitNotification.swift

// Observer for value decreases has been moved to Models/Animations/DecreaseAnimator.swift

// Notification system for important game alerts has been moved to Models/Notifications/GameNotification.swift

// Notification manager to handle display of game notifications has been moved to Models/Notifications/NotificationManager.swift

// Position tracker for the ship package button
struct ShipButtonPositionReader: ViewModifier {
    @Binding var position: CGPoint
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            position = CGPoint(
                                x: geo.frame(in: .global).midX,
                                y: geo.frame(in: .global).midY
                            )
                        }
                }
            )
    }
}

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
    
    // State for settings panel presentation
    @State private var showingSettings = false
    
    // Value decrease animation state
    @State private var decreaseAnimator = DecreaseAnimator()
    @State private var previousMoney: Double = 0
    @State private var previousWorkers: Int = 0
    
    // Game notification system
    @State private var notificationManager = NotificationManager()
    
    // Track UI element positions
    @State private var moneyPosition: CGPoint = .zero
    @State private var workersPosition: CGPoint = .zero
    @State private var shipButtonPosition: CGPoint = .zero // Add tracking for button position
    
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
                        // Add position tracking for money and workers
                        .background(MoneyPositionReader(position: $moneyPosition))
                        .background(WorkersPositionReader(position: $workersPosition))
                }
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
                )
                
                Spacer()
                
                // Main tap button
                ShipPackageButton()
                    .modifier(ShipButtonPositionReader(position: $shipButtonPosition)) // Track button position
                    .environment(\.accessDecreaseAnimator, decreaseAnimator) // Provide decreaseAnimator
                
                Spacer()
                
                // Upgrade section
                UpgradeListView()
                    .padding(.bottom, 16)
            }
            
            // Value decrease animations layer
            TimelineView(.animation(minimumInterval: 0.016, paused: false)) { timeline in // Increase frame rate to 60FPS
                ZStack {
                    // Package shipping animations
                    ForEach(decreaseAnimator.packageAnimations) { animation in
                        PackageAnimationView(animation: animation)
                    }
                    
                    ForEach(decreaseAnimator.decreases) { decrease in
                        Text("-\(formatValue(decrease.amount))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .opacity(decrease.opacity)
                            .offset(y: decrease.offset)
                            .position(decrease.position)
                            .shadow(color: .black.opacity(0.3), radius: 1)
                    }
                    
                    // Worker quit notifications
                    ForEach(decreaseAnimator.workerQuitNotifications) { notification in
                        Text("\(notification.count) worker\(notification.count > 1 ? "s" : "") quit!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black.opacity(0.6))
                            )
                            .opacity(notification.opacity)
                            .offset(y: notification.offset)
                            .position(notification.position)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                }
            }
            
            // Game notifications overlay
            VStack {
                Spacer().frame(height: 180) // Push notifications below header
                
                ForEach(notificationManager.notifications) { notification in
                    GameNotificationView(notification: notification)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: notificationManager.notifications.count)
            
            // Observe when packages are shipped and trigger animations
            Color.clear
                .frame(width: 0, height: 0)
                .onChange(of: gameState.totalPackagesShipped) { oldValue, newValue in
                    if newValue > oldValue {
                        // Add animation for each package shipped (limit to avoid flooding)
                        let packagesShipped = min(newValue - oldValue, 3) // Reduce max from 5 to 3
                        
                        // Space out animations slightly for more natural effect
                        for i in 0..<packagesShipped {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                                // Just pass the current button position - PackageAnimationView will
                                // only use the Y component and randomize from there
                                decreaseAnimator.addPackageAnimation(at: shipButtonPosition)
                            }
                        }
                    }
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
            
            // Dashboard button and game controls
            VStack {
                HStack {
                    // Settings button (New)
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill") // Gear icon
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.8)) // Style like Dashboard
                                    .shadow(color: .black.opacity(0.3), radius: 3)
                            )
                    }
                    .padding(.leading)
                    
                    
                    Spacer()
                    
                    // Dashboard button
                    Button(action: {
                        showDashboard = true
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.8))
                                    .shadow(color: .black.opacity(0.3), radius: 3)
                            )
                    }
                    .padding(.trailing)
                }
                .padding(.top)
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
            
            // Initialize previous values
            previousMoney = gameState.money
            previousWorkers = gameState.workers
            
            // If we're already in collapse state, show effects
            if gameState.isCollapsing {
                startCollapseEffects()
            }
        }
        .onDisappear {
            saveGameState()
            stopGameLoop()
        }
        .onChange(of: gameState.money) { oldValue, newValue in
            if newValue < oldValue {
                // Money decreased, trigger animation
                let decrease = oldValue - newValue
                decreaseAnimator.addDecrease(decrease, at: moneyPosition)
                
                // Play subtle haptic
                playHaptic(.light)
            }
            previousMoney = newValue
        }
        .onChange(of: gameState.workers) { oldValue, newValue in
            if newValue < oldValue {
                // Workers decreased, trigger animation
                let decrease = Double(oldValue - newValue)
                decreaseAnimator.addDecrease(decrease, at: workersPosition)
                
                // Play medium haptic for worker loss
                playHaptic(.medium)
            }
            previousWorkers = newValue
        }
        // Add an observer for worker quitting notifications
        .onChange(of: gameState.hasWorkersQuit) { _, hasQuit in
            if hasQuit && gameState.workersQuit > 0 {
                decreaseAnimator.addWorkerQuitNotification(gameState.workersQuit, at: workersPosition)
                
                // Add to notification system
                notificationManager.addNotification(.workerQuit(count: gameState.workersQuit))
                
                // Play strong haptic for workers quitting
                playHaptic(.heavy)
            }
        }
        // Check for notifications periodically
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            notificationManager.checkGameStateForNotifications(gameState: gameState)
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
                lifetimeTotalMoneyEarned: gameState.lifetimeTotalMoneyEarned,
                ethicalChoicesMade: gameState.ethicalChoicesMade,
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
        .sheet(isPresented: $showingSettings) { // Present SettingsView
            SettingsView()
        }
    }
    
    // Helper to format value for display
    private func formatValue(_ value: Double) -> String {
        if value == round(value) {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
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

#Preview {
    ContentView()
}
