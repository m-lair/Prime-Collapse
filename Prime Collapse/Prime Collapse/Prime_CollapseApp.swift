//
//  Prime_CollapseApp.swift
//  Prime Collapse
//
//  Created by Marcus Lair on 4/15/25.
//

import SwiftUI
import Foundation
import GameKit

@main
struct Prime_CollapseApp: App {
    @State private var game: GameState
    @State private var gameCenterManager: GameCenterManager
    @State private var eventManager = EventManager()
    @State private var saveManager: SaveManager
    @State private var prestigeManager: PrestigeManager

    init() {
        // Build the core objects up front and load any existing save synchronously,
        // so the game never renders (or auto-saves) fresh state over a real save.
        let game = GameState()
        let gameCenterManager = GameCenterManager()
        // Load prestige before the save so a fresh-install reset() seeds its bonuses.
        let prestigeManager = PrestigeManager(gameState: game)
        let saveManager = SaveManager(gameState: game, gameCenterManager: gameCenterManager)

        _game = State(initialValue: game)
        _gameCenterManager = State(initialValue: gameCenterManager)
        _saveManager = State(initialValue: saveManager)
        _prestigeManager = State(initialValue: prestigeManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(game)
                .environment(gameCenterManager)
                .environment(eventManager)
                .environment(saveManager)
                .environment(prestigeManager)
                .onAppear {
                    // Authenticate Game Center when the app launches.
                    gameCenterManager.authenticatePlayer()
                    #if DEBUG
                    presentDebugEventIfRequested()
                    #endif
                }
                .onChange(of: game.totalPackagesShipped) { _, newValue in
                    // Save on milestone package counts.
                    saveManager.saveOnEvent(.milestone(newValue))
                }
        }
    }

    #if DEBUG
    /// QA hook: `-debugEvent "Competitor Undercuts Prices" -debugMoney 500` opens that event on launch.
    private func presentDebugEventIfRequested() {
        let defaults = UserDefaults.standard
        guard let title = defaults.string(forKey: "debugEvent") else { return }
        let money = defaults.double(forKey: "debugMoney")
        if money > 0 {
            game.money = money
            // Stakes scale with earnings; a balance nobody earned would understate them.
            game.lifetimeTotalMoneyEarned = max(game.lifetimeTotalMoneyEarned, money)
        }
        eventManager.presentForTesting(titled: title)
    }
    #endif
}
