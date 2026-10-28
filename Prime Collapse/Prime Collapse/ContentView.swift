//
//  ContentView.swift
//  Prime Collapse
//
//  Created by Marcus Lair on 4/15/25.
//

import SwiftUI
import Observation
import Combine
import UIKit
import GameKit

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
    @Environment(GamePlayCoordinator.self) private var playSession
    @Environment(GameState.self) private var gameState
    @Environment(GameCenterManager.self) private var gameCenterManager
    @Environment(EventManager.self) private var eventManager
    @Environment(SaveManager.self) private var saveManager
    @State private var gameTask: Task<Void, Never>?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    // State for showing/hiding detailed stats overlay
    @State private var showDetailedStatsOverlay = false
    
    // Animation states for collapse phase
    @State private var showCollapseAlert = false
    @State private var glitchEffect = false
    @State private var slowdownFactor: Double = 1.0
    @State private var showEndingScreen = false
    @State private var showDashboard = false
    private var showHolidayRush: Bool { playSession.destination == .holidayRush }
    @State private var pendingHolidayRush = false
    @State private var openingHolidayRush = false
    
    // State for settings panel presentation
    @State private var showingSettings = false

    // First-run onboarding
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var showOnboarding = false

    // Value decrease animation state
    @State private var decreaseAnimator = DecreaseAnimator()
    @State private var previousMoney: Double = 0
    @State private var previousWorkers: Int = 0
    
    // Game notification system
    @State private var notificationManager = NotificationManager()

    // Local re-engagement notifications (offline-earnings cap reminder)
    @State private var reengagementNotifier = ReengagementNotifier()
    
    // Track UI element positions
    @State private var moneyPosition: CGPoint = .zero
    @State private var workersPosition: CGPoint = .zero
    @State private var shipButtonPosition: CGPoint = .zero // Add tracking for button position
    
    var body: some View {
        ZStack {
            if playSession.destination == .home {
                GameHomeView(game: gameState, challenge: playSession.challenge,
                             onContinue: continueCompany, onChallenge: openHolidayRush,
                             onSettings: { showingSettings = true })
            } else if showHolidayRush {
                HolidayRushView(session: playSession.challenge, onReturn: { playSession.goHome() })
            } else {
                backgroundView
                if dynamicTypeSize.isAccessibilitySize {
                    ScrollView { mainContentView }
                } else {
                    mainContentView
                }
                animationLayer
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                notificationOverlay
                packageShippingTrigger
                detailedStatsOverlay
                collapseEffectsOverlay
                EventView()
                SaveIndicatorView()
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showDetailedStatsOverlay) // Animate overlay appearance
        .animation(.easeInOut(duration: 0.3), value: glitchEffect)
        .animation(.easeInOut(duration: 0.5), value: gameState.isCollapsing)
        .onAppear {
            // Only run the simulation once the initial save has loaded, so progress
            // is never overwritten by a freshly-started game. (Load is synchronous at
            // launch, so this is normally already true; the guard is defensive.)
            gameState.resetForegroundTiming()
            if gameState.endingReached && playSession.destination == .company && !openingHolidayRush {
                showEndingScreen = true
            } else if saveManager.hasCompletedInitialLoad {
                startGameLoop()
            }

            // Initialize previous values
            previousMoney = gameState.money
            previousWorkers = gameState.workers

            // If we're already in collapse state, show effects
            if gameState.isCollapsing && playSession.destination == .company && !openingHolidayRush {
                startCollapseEffects()
            }

        }
        .onChange(of: saveManager.hasCompletedInitialLoad) { _, loaded in
            if loaded && gameTask == nil {
                startGameLoop()
            }
        }
        .onChange(of: showOnboarding) { _, shown in
            // Mark the tutorial as seen once it's been dismissed.
            if !shown {
                hasSeenTutorial = true
                if pendingHolidayRush {
                    pendingHolidayRush = false
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        playSession.openHolidayRush()
                    }
                } else if playSession.destination == .company {
                    resumeCompany()
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingOverlayView(isPresented: $showOnboarding)
        }
        .onDisappear {
            saveManager.saveGameState()
            stopGameLoop()
        }
        .onChange(of: gameState.money) { oldValue, newValue in
            if newValue < oldValue {
                // Money decreased, trigger animation
                let decrease = oldValue - newValue
                decreaseAnimator.addDecrease(decrease, at: moneyPosition)
                
                // Play subtle haptic
                playHaptic(.light)
            } else if newValue > oldValue && newValue > previousMoney + 100 {
                // Significant money increase - trigger save
                saveManager.saveOnEvent(.moneyGain(newValue - previousMoney))
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
            if isCollapsing && playSession.destination == .company && !openingHolidayRush {
                playHaptic(.heavy) // Strong haptic for collapse
                startCollapseEffects()
            }
        }
        // Show the ending screen when a win-state ending (Reform/Loop) is earned.
        // Collapse keeps its own flow through the collapse alert above.
        .onChange(of: gameState.endingReached) { _, reached in
            if reached && playSession.destination == .company && !openingHolidayRush {
                playHaptic(.heavy)
                stopGameLoop()
                showEndingScreen = true
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
                    guard gameState.isCollapsing, playSession.destination == .company, !openingHolidayRush else { return }
                    stopGameLoop()
                    showEndingScreen = true
                }
            }
            Button("Reset", role: .cancel) {
                // Use SaveManager instead of direct reset
                saveManager.handleGameEnding(type: .restart)
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
                    // Use SaveManager to properly handle game ending
                    let endingType: GameEndingType = gameState.endingType == .collapse ? .lose : .win
                    saveManager.handleGameEnding(type: endingType)
                    showEndingScreen = false
                    startGameLoop()
                }
            )
            .safeAreaInset(edge: .top) {
                Button("Game home", systemImage: "house.fill") {
                    showEndingScreen = false
                    playSession.goHome()
                }
                .buttonStyle(.bordered).padding(8)
            }
        }
        .sheet(isPresented: $showDashboard) {
            DashboardView()
        }
        .sheet(isPresented: $showingSettings) { // Present SettingsView
            SettingsView()
        }
        .onChange(of: playSession.destination) { _, destination in
            stopGameLoop()
            saveManager.saveGameState()
            gameState.resetForegroundTiming()
            if destination == .company {
                resumeCompany()
            } else {
                showEndingScreen = false
                showCollapseAlert = false
                openingHolidayRush = false
            }
        }
        .onOpenURL { url in
            guard HolidayRushRoute.matches(url) else { return }
            openHolidayRush()
        }
        .onChange(of: scenePhase) { _, newPhase in
            gameState.resetForegroundTiming()
            if newPhase == .background {
                stopGameLoop()
                saveManager.saveOnEvent(.backgrounding)
                // Remind the player when offline earnings hit the 8-hour cap.
                let workers = gameState.workers
                Task { await reengagementNotifier.scheduleOfflineEarningsCapReminder(workers: workers) }
            } else if newPhase == .active {
                // They're back — the reminder is moot.
                reengagementNotifier.cancelPendingReminders()
                if playSession.destination == .company { resumeCompany() }
                if gameState.isCollapsing && playSession.destination == .company && !openingHolidayRush {
                    // Re-enable collapse effects when returning to the app
                    startCollapseEffects()
                }
            }
        }
        .onChange(of: gameState.purchasedUpgradeIDs.count) { _, _ in
            // Save when the player buys an upgrade (repeatable or not — both append here).
            saveManager.saveOnEvent(.upgrade)
            // First purchase marks an engaged player — the right moment to ask for
            // notification permission (no-ops after the first request).
            Task { await reengagementNotifier.requestAuthorizationIfNeeded() }
        }
    }
    
    // MARK: - Extracted View Components
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                gameState.isCollapsing ? Color(red: 0.3, green: 0.1, blue: 0.1) : Color(red: 0.1, green: 0.2, blue: 0.3),
                gameState.isCollapsing ? Color(red: 0.5, green: 0.1, blue: 0.1) : Color(red: 0.2, green: 0.3, blue: 0.5)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Header with title and stats
            headerView

            Spacer()

            // Main tap button
            ShipPackageButton()
                .modifier(ShipButtonPositionReader(position: $shipButtonPosition))
                .environment(\.accessDecreaseAnimator, decreaseAnimator)

            Spacer()

            // Upgrade section
            UpgradeListView()
                .padding(.bottom, 16)
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Game home", systemImage: "house.fill") { playSession.goHome() }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44)
                Text("Prime Collapse")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Company details", systemImage: "chart.bar.fill") { showDashboard = true }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44)
                Button("Settings", systemImage: "gearshape.fill") { showingSettings = true }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            GameStatsView(isShowingDetails: $showDetailedStatsOverlay)
                .padding(.horizontal)
                // Add position tracking for money and workers
                .background(MoneyPositionReader(position: $moneyPosition))
                .background(WorkersPositionReader(position: $workersPosition))
            if gameState.isInLoopEndingState {
                ProgressView("Loop stability: \(Int(gameState.loopStabilitySeconds))/60 sec", value: gameState.loopStabilityProgress)
                    .font(.caption)
                    .tint(.orange)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.8))
                .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
        )
    }

    private var animationLayer: some View {
        TimelineView(.animation(minimumInterval: 0.016, paused: false)) { timeline in
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
    }
    
    private var notificationOverlay: some View {
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
    }
    
    private var packageShippingTrigger: some View {
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
    }
    
    private var detailedStatsOverlay: some View {
        Group {
            if showDetailedStatsOverlay {
                VStack {
                    Spacer(minLength: 180)
                    
                    DetailedStatsOverlayView(isPresented: $showDetailedStatsOverlay)
                        .padding(.horizontal) // Add horizontal padding
                    
                    Spacer() // Pushes the overlay towards the top spacer
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .move(edge: .top))) // Slide down + fade
                .zIndex(1) // Ensure it's above the main content layer
            }
        }
    }
    
    private var collapseEffectsOverlay: some View {
        Group {
            if gameState.isCollapsing && playSession.destination == .company && !openingHolidayRush {
                CollapseEffectsView(showCollapseAlert: $showCollapseAlert)
            }
        }
    }
    
    // MARK: - Helper Functions
    
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
        guard playSession.destination == .company, !showOnboarding, !gameState.isRunTerminal else { return }
        
        // Use Combine's Timer publisher as an AsyncSequence driving the game loop
        let updateInterval = 0.1 // 100ms
        let timer = Timer.publish(every: updateInterval, on: .main, in: .common).autoconnect()
        gameTask = Task {
            do {
                for try await currentTime in timer.values {
                    // Exit if cancelled
                    if Task.isCancelled { break }
                    // Process automation and events on the main actor
                    guard scenePhase == .active else { continue }
                    if playSession.advanceCompany(at: currentTime) {
                        eventManager.checkForEvents(gameState: gameState, currentTime: currentTime)
                    }
                }
            } catch is CancellationError {
                // Task was cancelled, exit gracefully
            } catch {
                print("Game loop timer error: \(error)")
            }
        }
    }

    private func continueCompany() {
        playSession.openCompany()
        if !hasSeenTutorial { showOnboarding = true }
    }

    private func resumeCompany() {
        guard playSession.destination == .company else { return }
        openingHolidayRush = false
        gameState.lastUpdate = Date()
        gameState.resetForegroundTiming()
        if gameState.isRunTerminal {
            showEndingScreen = true
        } else {
            startGameLoop()
        }
    }

    private func openHolidayRush() {
        guard !showHolidayRush else { return }
        guard !showOnboarding else {
            pendingHolidayRush = true
            return
        }
        openingHolidayRush = true
        let dismissingPresentation = showDashboard || showingSettings || showEndingScreen || showCollapseAlert
        showDashboard = false
        showingSettings = false
        showEndingScreen = false
        showCollapseAlert = false
        if dismissingPresentation {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                playSession.openHolidayRush()
            }
        } else {
            playSession.openHolidayRush()
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
            guard gameState.isCollapsing, playSession.destination == .company, !openingHolidayRush, !showEndingScreen else { return }
            showCollapseAlert = true
        }
        
        // Slow down the automation
        slowdownFactor = 0.5
    }
    
    private func startGlitchingEffect() {
        // Create a repeating timer that toggles the glitch effect
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            MainActor.assumeIsolated {
            guard gameState.isCollapsing, playSession.destination == .company, !openingHolidayRush, !showEndingScreen else {
                timer.invalidate()
                return
            }
            
            glitchEffect.toggle()
            }
        }
    }
    
    // Play haptic feedback based on intensity level
    private func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    ContentView()
}
