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

    init() {
        // Build the core objects up front and load any existing save synchronously,
        // so the game never renders (or auto-saves) fresh state over a real save.
        let game = GameState()
        let gameCenterManager = GameCenterManager()
        let saveManager = SaveManager(gameState: game, gameCenterManager: gameCenterManager)

        _game = State(initialValue: game)
        _gameCenterManager = State(initialValue: gameCenterManager)
        _saveManager = State(initialValue: saveManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(game)
                .environment(gameCenterManager)
                .environment(eventManager)
                .environment(saveManager)
                .onAppear {
                    // Authenticate Game Center when the app launches.
                    gameCenterManager.authenticatePlayer()
                }
                .onChange(of: game.totalPackagesShipped) { _, newValue in
                    // Save on milestone package counts.
                    saveManager.saveOnEvent(.milestone(newValue))
                }
        }
    }
}
