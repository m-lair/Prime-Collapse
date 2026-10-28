import Foundation

/// Scripted catalog choices and taps; only the clock is injected, never outcome metrics.
func playEndingRoute(_ ending: GameEnding) -> GameState {
    let state = GameState()
    state.reset()
    let start = Date(timeIntervalSince1970: 1800000000)
    state.lastUpdate = start
    for _ in 0..<4000 { state.shipPackage() }
    state.applyUpgrade(UpgradeManager.EarlyGame.hireWorker)
    state.applyUpgrade(UpgradeManager.EarlyGame.hireWorker)
    if ending == .reform {
        state.applyUpgrade(UpgradeManager.EarlyGame.optimizeLogistics)
        state.applyUpgrade(UpgradeManager.EarlyGame.basicTraining)
        state.applyUpgrade(UpgradeManager.EarlyGame.safetyPlacards)
        state.applyUpgrade(UpgradeManager.MidGame.performanceBonuses)
        state.applyUpgrade(UpgradeManager.MidGame.performanceBonuses)
    } else {
        let events = EventManager()
        let boom = events.allEventsForTesting.first { $0.title == "Market Boom" }!
        let raisePrices = boom.choices.first { $0.moralImpact < 0 }!
        while !state.isRunTerminal && (ending != .loop || !(15...25).contains(state.ethicsScore)) {
            precondition(boom.triggerCondition(state))
            events.currentEvent = boom
            let choice = ending == .loop && state.ethicsScore < 15 ? boom.choices.first { $0.moralImpact > 0 }! : raisePrices
            events.processChoice(choice: choice, gameState: state, currentTime: start)
        }
        for second in 1...60 {
            state.processAutomation(currentTime: start.addingTimeInterval(Double(second)))
        }
    }
    return state
}
