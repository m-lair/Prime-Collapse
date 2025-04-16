import Foundation
import SwiftUI

@Observable class EventManager {
    // Currently active event
    var currentEvent: GameEvent?
    
    // Time-based event tracking
    private var lastEventTime = Date()
    private let minTimeBetweenEvents: TimeInterval = 120 // 2 minutes between events
    
    // Event chance parameters
    private let baseEventChance = 0.02 // 2% chance per check when eligible
    
    // Predefined catalog of possible events
    private let eventCatalog: [GameEvent] = [
        // Workplace events
        GameEvent(
            title: "Worker Unrest",
            description: "Your workers are complaining about long hours and poor conditions.",
            choices: [
                EventChoice(
                    text: "Improve conditions (+$500 per worker cost)",
                    moralImpact: 1.0,
                    effect: { state in
                        state.money -= Double(state.workers) * 500
                        state.workerEfficiency += 0.1
                    }
                ),
                EventChoice(
                    text: "Ignore their complaints",
                    moralImpact: -1.0,
                    effect: { state in
                        state.workerEfficiency -= 0.2
                        state.workerMorale -= 0.1
                    }
                )
            ],
            triggerCondition: { state in
                state.workers >= 5 && state.workerMorale < 0.7
            },
            category: .workplace
        ),
        
        // Market events
        GameEvent(
            title: "Market Boom",
            description: "The shipping market is experiencing unexpected growth!",
            choices: [
                EventChoice(
                    text: "Raise prices temporarily",
                    moralImpact: -0.5,
                    effect: { state in
                        state.packageValue *= 1.5
                        
                        // Schedule price return after 30 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            state.packageValue /= 1.5
                        }
                    }
                ),
                EventChoice(
                    text: "Keep prices stable for customer loyalty",
                    moralImpact: 0.5,
                    effect: { state in
                        state.customerSatisfaction += 0.1
                    }
                )
            ],
            triggerCondition: { state in
                state.totalPackagesShipped > 100
            },
            category: .market
        ),
        
        // Public Relations events
        GameEvent(
            title: "Media Spotlight",
            description: "A popular business magazine wants to do a feature on your company.",
            choices: [
                EventChoice(
                    text: "Showcase innovation and efficiency",
                    moralImpact: 0.0,
                    effect: { state in
                        state.automationEfficiency += 0.05
                    }
                ),
                EventChoice(
                    text: "Highlight worker treatment",
                    moralImpact: 0.5,
                    effect: { state in
                        state.workerMorale += 0.2
                        state.money -= 1000
                    }
                )
            ],
            triggerCondition: { state in
                state.totalPackagesShipped > 500
            },
            category: .publicRelations
        ),
        
        // Regulatory events
        GameEvent(
            title: "Environmental Inspection",
            description: "Government officials are inspecting your facility for environmental compliance.",
            choices: [
                EventChoice(
                    text: "Upgrade for full compliance ($5000)",
                    moralImpact: 1.0,
                    effect: { state in
                        state.money -= 5000
                    }
                ),
                EventChoice(
                    text: "Cut corners with minimal upgrades ($1000)",
                    moralImpact: -0.5,
                    effect: { state in
                        state.money -= 1000
                        state.corporateEthics -= 0.1
                    }
                ),
                EventChoice(
                    text: "Bribe the inspector ($2000)",
                    moralImpact: -2.0,
                    effect: { state in
                        state.money -= 2000
                        state.corporateEthics -= 0.3
                    }
                )
            ],
            triggerCondition: { state in
                state.automationLevel >= 2
            },
            category: .regulatory
        )
    ]
    
    // Called regularly from game loop to determine if an event should trigger
    func checkForEvents(gameState: GameState, currentTime: Date) {
        // Don't trigger events if one is already active or if we're in collapse mode
        guard currentEvent == nil && !gameState.isCollapsing else {
            return
        }
        
        // Don't trigger events too frequently
        let timeSinceLastEvent = currentTime.timeIntervalSince(lastEventTime)
        guard timeSinceLastEvent >= minTimeBetweenEvents else {
            return
        }
        
        // Increase chance of event based on time since last event (caps at ~10%)
        let adjustedChance = min(baseEventChance * (timeSinceLastEvent / minTimeBetweenEvents), 0.1)
        
        // Random roll to determine if an event triggers
        if Double.random(in: 0...1) < adjustedChance {
            triggerRandomEvent(gameState: gameState)
            lastEventTime = currentTime
        }
    }
    
    // Select an eligible random event
    private func triggerRandomEvent(gameState: GameState) {
        // Filter for eligible events based on trigger conditions
        let eligibleEvents = eventCatalog.filter { $0.triggerCondition(gameState) }
        
        // Only proceed if there are eligible events
        guard !eligibleEvents.isEmpty else {
            return
        }
        
        // Select a random event from eligible ones
        if let selectedEvent = eligibleEvents.randomElement() {
            currentEvent = selectedEvent
        }
    }
    
    // Handle player's choice for the current event
    func processChoice(choice: EventChoice, gameState: GameState) {
        // Apply the choice effect
        choice.effect(gameState)
        
        // Update moral compass based on choice
        gameState.corporateEthics += choice.moralImpact / 10.0
        
        // Clear the current event
        currentEvent = nil
    }
} 