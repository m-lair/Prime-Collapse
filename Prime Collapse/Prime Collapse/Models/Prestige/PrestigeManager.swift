//
//  PrestigeManager.swift
//  Prime Collapse
//
//  Observable owner of the persisted prestige state. Bridges the pure PrestigeState /
//  PrestigeStore to the game: mirrors prestige into GameState (so reset() seeds its
//  bonuses), banks points when a run ends, and applies perk purchases — persisting
//  after every change.
//

import Foundation
import Observation

@MainActor
@Observable
final class PrestigeManager {
    private(set) var state: PrestigeState

    private let gameState: GameState
    private let directory: URL?

    init(gameState: GameState, directory: URL? = nil) {
        self.gameState = gameState
        self.directory = directory
        self.state = PrestigeStore.load(in: directory)
        // Mirror into the game so the next reset() applies the earned head start.
        gameState.prestige = state
    }

    /// Bank the prestige earned by the run that just ended. Idempotent per run.
    /// Returns the points awarded (0 if none / already banked).
    @discardableResult
    func concludeRun() -> Int {
        let earned = gameState.concludeRun()
        if earned > 0 {
            state = gameState.prestige
            persist()
        }
        return earned
    }

    /// Buy one level of `perk` if affordable. Returns whether it happened.
    @discardableResult
    func purchase(_ perk: PrestigePerk) -> Bool {
        guard state.purchase(perk) else { return false }
        gameState.prestige = state
        persist()
        return true
    }

    func cost(of perk: PrestigePerk) -> Int { state.cost(of: perk) }
    func level(of perk: PrestigePerk) -> Int { state.level(of: perk) }
    func canAfford(_ perk: PrestigePerk) -> Bool { state.canAfford(perk) }
    var points: Int { state.points }

    private func persist() {
        PrestigeStore.save(state, in: directory)
    }
}
