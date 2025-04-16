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
                    moralImpact: -5.0, // Negative value reduces moral decay
                    effect: { state in
                        state.money -= Double(state.workers) * 500
                        state.workerEfficiency += 0.1
                        state.workerMorale += 0.2
                    }
                ),
                EventChoice(
                    text: "Ignore their complaints",
                    moralImpact: 8.0, // Positive value increases moral decay
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
                    moralImpact: 5.0, // Increase moral decay (unethical)
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
                    moralImpact: -3.0, // Decrease moral decay (ethical)
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
                    moralImpact: 2.0, // Slightly unethical (focuses on profits)
                    effect: { state in
                        state.automationEfficiency += 0.05
                    }
                ),
                EventChoice(
                    text: "Highlight worker treatment",
                    moralImpact: -4.0, // Ethical choice
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
                    moralImpact: -8.0, // Very ethical choice
                    effect: { state in
                        state.money -= 5000
                        // Count this as an ethical choice for ending conditions
                        state.ethicalChoicesMade += 1
                    }
                ),
                EventChoice(
                    text: "Cut corners with minimal upgrades ($1000)",
                    moralImpact: 5.0, // Unethical
                    effect: { state in
                        state.money -= 1000
                        state.corporateEthics -= 0.1
                    }
                ),
                EventChoice(
                    text: "Bribe the inspector ($2000)",
                    moralImpact: 12.0, // Very unethical
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
        
        // Update moral decay based on choice
        gameState.moralDecay += choice.moralImpact
        
        // Update corporate ethics as well (scaled down)
        gameState.corporateEthics += choice.moralImpact > 0 ? -0.05 : 0.05
        
        // Track ethical choices for ending conditions
        if choice.moralImpact < 0 {
            gameState.ethicalChoicesMade += 1
            // Check for potential reform ending
            if gameState.moralDecay < 50 && gameState.money >= 1000 && gameState.ethicalChoicesMade >= 5 {
                gameState.endingType = .reform
            }
        }
        
        // Check if we've entered collapse phase
        if gameState.moralDecay >= 100 {
            gameState.isCollapsing = true
            gameState.endingType = .collapse
        }
        
        // Clear the current event
        currentEvent = nil
    }
} 