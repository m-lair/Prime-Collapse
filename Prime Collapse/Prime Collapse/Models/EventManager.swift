import Foundation
import SwiftUI

/// Standard money stakes. Every event is built on the same tension: the shortcut pays now,
/// the decent option costs now, and the bill for the shortcut arrives later.
enum EventStakes {
    // Shortcut payouts: minutes of earnings or a share of the balance, with an early-game floor.
    // Balance shares sit above the matching cost tiers so greed stays tempting when rich.
    static let skim = MoneyStake.gain(minutes: 0.75, balanceShare: 0.12, minimum: 25)
    static let windfall = MoneyStake.gain(minutes: 1.5, balanceShare: 0.22, minimum: 40)
    static let jackpot = MoneyStake.gain(minutes: 3, balanceShare: 0.3, minimum: 75)
    static let heist = MoneyStake.gain(minutes: 6, balanceShare: 0.4, minimum: 150)
    static let liquidation = MoneyStake.gain(minutes: 10, balanceShare: 0.5, minimum: 300)

    // Costs of doing the right thing. Capped at the balance, so they never lock a choice.
    static let token = MoneyStake.cost(minutes: 0.25, balanceShare: 0.03, minimum: 5)
    static let investment = MoneyStake.cost(minutes: 1, balanceShare: 0.1, minimum: 20)
    static let commitment = MoneyStake.cost(minutes: 2, balanceShare: 0.2, minimum: 40)
    static let sacrifice = MoneyStake.cost(minutes: 4, balanceShare: 0.3, minimum: 80)

    // Delayed fines for shortcuts that get caught. Balance shares keep them in proportion
    // to the shortcut payouts, which also scale with the balance.
    static let fine = MoneyStake.cost(minutes: 1.5, balanceShare: 0.15, minimum: 40)
    static let penalty = MoneyStake.cost(minutes: 3, balanceShare: 0.25, minimum: 100)
}

private func better(_ metric: String, _ change: String) -> EffectDescription {
    EffectDescription(metricName: metric, changeDescription: change, impactType: .positive)
}

private func worse(_ metric: String, _ change: String) -> EffectDescription {
    EffectDescription(metricName: metric, changeDescription: change, impactType: .negative)
}

@Observable class EventManager {
    // Currently active event
    var currentEvent: GameEvent?

    // Time-based event tracking
    private var lastEventTime = Date()
    private let minTimeBetweenEvents: TimeInterval = 120 // 2 minutes between events

    // Event chance parameters
    private let baseEventChance = 0.02 // 2% chance per check when eligible

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

        let adjustedChance = EventManager.eventTriggerChance(
            packagesShipped: gameState.totalPackagesShipped,
            timeSinceLastEvent: timeSinceLastEvent,
            baseChance: baseEventChance,
            minInterval: minTimeBetweenEvents
        )

        // Random roll to determine if an event triggers
        if Double.random(in: 0...1) < adjustedChance {
            triggerRandomEvent(gameState: gameState)
        }
    }

    /// Probability that an event triggers on a single check. Pure and testable.
    ///
    /// Returns 0 until the minimum interval has elapsed. Otherwise the chance scales with how
    /// long it's been since the last event and a late-game factor. The factor is clamped to
    /// **at least 1.0** so events also fire in the early game — previously it used integer
    /// division (`packages / 1000`), which evaluated to 0 below 1000 packages and silently
    /// disabled all random events for new players. Capped at 15%.
    static func eventTriggerChance(packagesShipped: Int,
                                   timeSinceLastEvent: TimeInterval,
                                   baseChance: Double,
                                   minInterval: TimeInterval) -> Double {
        guard minInterval > 0, timeSinceLastEvent >= minInterval else { return 0 }
        let lateGameFactor = max(1.0, min(Double(packagesShipped) / 1000.0, 1.5))
        let chance = baseChance * (timeSinceLastEvent / minInterval) * lateGameFactor
        return min(max(chance, 0), 0.15)
    }

    /// Ethics change a choice will actually apply. Shared by `processChoice` and the event sheet
    /// so the displayed number matches. Progress scaling ramps smoothly from 1500 packages
    /// (previously integer division made it jump straight from 1.0x to 1.5x at 3000).
    static func scaledMoralImpact(of choice: EventChoice,
                                  importance: GameEvent.EventImportance,
                                  state: GameState) -> Double {
        var factor = importance.baseScalingFactor * (choice.scalingFactors?.moralImpactScaling ?? 1.0)
        let progressFactor = min(Double(state.totalPackagesShipped) / 1500.0, 1.5)
        // Already-unethical companies sink faster; ethical choices aren't amplified.
        let ethicsFactor = choice.moralImpact < 0 && state.ethicsScore < 40 ? 1.3 : 1.0
        factor *= max(1.0, progressFactor * ethicsFactor)
        return choice.moralImpact * factor
    }

    // Select an eligible random event
    private func triggerRandomEvent(gameState: GameState) {
        let eligibleEvents = allEvents.filter { $0.triggerCondition(gameState) }
        if let selectedEvent = eligibleEvents.randomElement() {
            currentEvent = selectedEvent
        }
    }

    // Handle player's choice for the current event
    func processChoice(choice: EventChoice, gameState: GameState, now: Date = Date()) {
        let importance = currentEvent?.importance ?? .moderate

        // Money first, sized from the economy as the player saw it on the sheet.
        if let cash = choice.cash {
            let amount = cash.amount(in: gameState)
            if cash.direction == .gain {
                gameState.earnMoney(amount)
            } else {
                gameState.money -= amount
            }
        }
        if let shift = choice.incomeShift {
            gameState.applyIncomeShift(shift, at: now)
        }
        if let fallout = choice.fallout, Double.random(in: 0..<1) < fallout.chance {
            let fine = fallout.fine?.sizedAmount(in: gameState) ?? 0
            let consequences = fallout.consequences
            gameState.scheduleEffect(after: fallout.delay, from: now) { gs in
                gs.money -= fine
                consequences(gs)
            }
        }

        choice.effect(gameState)

        let scaledMoralImpact = EventManager.scaledMoralImpact(of: choice, importance: importance, state: gameState)
        gameState.ethicsScore += scaledMoralImpact

        // Update corporate ethics as well (scaled down to roughly -0.6 to +0.6)
        gameState.corporateEthics += scaledMoralImpact / 20.0

        // Track ethical choices for ending conditions (positive impact is now ethical)
        if scaledMoralImpact > 0 {
            gameState.ethicalChoicesMade += 1
            // Check for potential reform ending (uses ethicsScore)
            if gameState.ethicsScore >= 50 && gameState.money >= 1000 && gameState.ethicalChoicesMade >= 5 {
                gameState.endingType = .reform
            }
        }

        // Check if we've entered collapse phase (uses ethicsScore)
        if gameState.ethicsScore <= 0 {
            gameState.isCollapsing = true
            gameState.endingType = .collapse
        }

        currentEvent = nil

        // Start the cooldown timer now that the event is resolved
        lastEventTime = Date()
    }

    // MARK: - Late-game events

    private let lateGameEvent = GameEvent(
        title: "Corporate Espionage Opportunity",
        description: "A former competitor employee is offering their client list. It's very detailed.",
        choices: [
            EventChoice(
                text: "Buy the client list",
                moralImpact: -15.0,
                cash: EventStakes.heist,
                incomeShift: IncomeShift(bonus: 0.2, duration: 120),
                fallout: Fallout(
                    chance: 0.5,
                    delay: 90,
                    fine: EventStakes.penalty,
                    descriptions: [worse("Perception", "-20")],
                    consequences: { gs in
                        gs.publicPerception -= 20
                        gs.corporateEthics -= 0.2
                    }
                ),
                effect: { state in
                    state.publicPerception -= 5
                },
                effectDescriptions: [
                    worse("Perception", "-5")
                ]
            ),
            EventChoice(
                text: "Decline the offer",
                moralImpact: 3.0,
                cash: EventStakes.token,
                incomeShift: IncomeShift(bonus: -0.05, duration: 30),
                effect: { state in
                    state.publicPerception += 2
                },
                effectDescriptions: [
                    better("Perception", "+2")
                ]
            ),
            EventChoice(
                text: "Inform the authorities",
                moralImpact: 10.0,
                cash: EventStakes.investment,
                incomeShift: IncomeShift(bonus: -0.1, duration: 60),
                effect: { state in
                    state.publicPerception += 15
                    state.corporateEthics += 0.15
                },
                effectDescriptions: [
                    better("Perception", "+15")
                ]
            )
        ],
        triggerCondition: { state in
            state.totalPackagesShipped >= 800
        },
        category: .crisis
    )

    private let systemicCollapseEvent = GameEvent(
        title: "Systemic Industry Crisis",
        description: "The entire shipping industry is facing a downturn. Some see a crisis. Others see a sale.",
        choices: [
            EventChoice(
                text: "Buy out struggling rivals at fire-sale prices",
                moralImpact: -18.0,
                cash: EventStakes.heist,
                incomeShift: IncomeShift(bonus: 0.3, duration: 120),
                fallout: Fallout(
                    delay: 60,
                    descriptions: [worse("Perception", "-15"), worse("Satisfaction", "-10%")],
                    consequences: { gs in
                        gs.publicPerception -= 15
                        gs.customerSatisfaction -= 0.1
                    }
                ),
                effect: { state in
                    state.publicPerception -= 10
                    state.environmentalImpact += 10
                    state.workerMorale -= 0.2
                },
                effectDescriptions: [
                    worse("Perception", "-10"),
                    worse("Morale", "-20%"),
                    worse("Environment", "+10")
                ]
            ),
            EventChoice(
                text: "Weather the storm independently",
                moralImpact: 0.0,
                incomeShift: IncomeShift(bonus: -0.15, duration: 90),
                effect: { state in
                    state.customerSatisfaction -= 0.05
                },
                effectDescriptions: [
                    worse("Satisfaction", "-5%")
                ]
            ),
            EventChoice(
                text: "Collaborate with competitors on solutions",
                moralImpact: 12.0,
                cash: EventStakes.commitment,
                incomeShift: IncomeShift(bonus: -0.15, duration: 120),
                effect: { state in
                    state.publicPerception += 20
                    state.workerMorale += 0.2
                },
                effectDescriptions: [
                    better("Perception", "+20"),
                    better("Morale", "+20%")
                ]
            )
        ],
        triggerCondition: { state in
            state.totalPackagesShipped >= 1200
        },
        category: .crisis
    )

    private let corporateTakeoverEvent = GameEvent(
        title: "Hostile Takeover Attempt",
        description: "A large conglomerate wants your company. Your workers are included in the price.",
        choices: [
            EventChoice(
                text: "Strip the assets, sell the shell",
                moralImpact: -25.0,
                cash: EventStakes.liquidation,
                fallout: Fallout(
                    delay: 45,
                    descriptions: [worse("Perception", "-20")],
                    consequences: { gs in
                        gs.publicPerception -= 20
                    }
                ),
                effect: { state in
                    state.workerMorale -= 0.4
                    state.publicPerception -= 25
                    state.environmentalImpact += 20
                    state.workers = max(1, state.workers / 2)
                },
                effectDescriptions: [
                    worse("Workers", "Cut by 50%"),
                    worse("Morale", "-40%"),
                    worse("Perception", "-25"),
                    worse("Environment", "+20")
                ],
                scalingFactors: EventChoice.EventScalingFactors.extreme
            ),
            EventChoice(
                text: "Fight the takeover",
                moralImpact: 5.0,
                cash: EventStakes.commitment,
                incomeShift: IncomeShift(bonus: -0.1, duration: 90),
                fallout: Fallout(
                    chance: 0.3,
                    delay: 120,
                    fine: EventStakes.fine,
                    descriptions: [worse("Perception", "-10"), worse("Morale", "-10%")],
                    consequences: { gs in
                        gs.publicPerception -= 10
                        gs.workerMorale -= 0.1
                    }
                ),
                effect: { state in
                    state.workerMorale += 0.1
                    state.publicPerception += 8
                },
                effectDescriptions: [
                    better("Morale", "+10%"),
                    better("Perception", "+8")
                ],
                scalingFactors: EventChoice.EventScalingFactors.extreme
            ),
            EventChoice(
                text: "Merge on terms that protect workers",
                moralImpact: 15.0,
                cash: EventStakes.sacrifice,
                incomeShift: IncomeShift(bonus: -0.2, duration: 120),
                effect: { state in
                    state.workerMorale += 0.25
                    state.publicPerception += 20
                },
                effectDescriptions: [
                    better("Morale", "+25%"),
                    better("Perception", "+20")
                ],
                scalingFactors: EventChoice.EventScalingFactors.extreme
            )
        ],
        triggerCondition: { state in
            state.totalPackagesShipped >= 1500
        },
        category: .crisis,
        importance: .critical
    )

    // MARK: - Event catalog

    private let eventCatalog: [GameEvent] = [
        // Workplace events
        GameEvent(
            title: "Worker Unrest",
            description: "Your workers are complaining about long hours and poor conditions.",
            choices: [
                EventChoice(
                    text: "Mandate overtime until morale improves",
                    moralImpact: -8.0,
                    cash: EventStakes.jackpot,
                    incomeShift: IncomeShift(bonus: 0.25, duration: 60),
                    fallout: Fallout(
                        delay: 45,
                        descriptions: [worse("Perception", "-8"), worse("Morale", "-5%")],
                        consequences: { gs in
                            gs.publicPerception -= 8
                            gs.workerMorale -= 0.05
                        }
                    ),
                    effect: { state in
                        state.workerMorale -= 0.15
                    },
                    effectDescriptions: [
                        worse("Morale", "-15%")
                    ]
                ),
                EventChoice(
                    text: "Improve conditions and cut hours",
                    moralImpact: 5.0,
                    cash: EventStakes.commitment,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 60),
                    effect: { state in
                        state.workerMorale += 0.2
                        state.workerEfficiency += 0.05
                        state.publicPerception += 5
                    },
                    effectDescriptions: [
                        better("Morale", "+20%"),
                        better("Efficiency", "+0.05"),
                        better("Perception", "+5")
                    ]
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
            description: "Demand for shipping is surging. Customers will pay almost anything.",
            choices: [
                EventChoice(
                    text: "Introduce surge pricing",
                    moralImpact: -5.0,
                    cash: EventStakes.windfall,
                    incomeShift: IncomeShift(bonus: 0.4, duration: 60),
                    fallout: Fallout(
                        delay: 45,
                        descriptions: [worse("Satisfaction", "-10%")],
                        consequences: { gs in
                            gs.customerSatisfaction -= 0.1
                        }
                    ),
                    effect: { state in
                        state.publicPerception -= 3
                    },
                    effectDescriptions: [
                        worse("Perception", "-3")
                    ]
                ),
                EventChoice(
                    text: "Keep prices stable for loyal customers",
                    moralImpact: 3.0,
                    cash: EventStakes.investment,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 60),
                    effect: { state in
                        state.customerSatisfaction += 0.1
                        state.publicPerception += 5
                    },
                    effectDescriptions: [
                        better("Satisfaction", "+10%"),
                        better("Perception", "+5")
                    ]
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
            description: "A business magazine wants to feature your company. Investors read it.",
            choices: [
                EventChoice(
                    text: "Showcase automation, crop out the workers",
                    moralImpact: -2.0,
                    cash: EventStakes.skim,
                    fallout: Fallout(
                        delay: 30,
                        descriptions: [worse("Morale", "-10%")],
                        consequences: { gs in
                            gs.workerMorale -= 0.1
                        }
                    ),
                    effect: { state in
                        state.publicPerception += 3
                    },
                    effectDescriptions: [
                        better("Perception", "+3")
                    ]
                ),
                EventChoice(
                    text: "Highlight worker treatment",
                    moralImpact: 4.0,
                    cash: EventStakes.investment,
                    incomeShift: IncomeShift(bonus: -0.05, duration: 60),
                    effect: { state in
                        state.workerMorale += 0.15
                        state.publicPerception += 8
                    },
                    effectDescriptions: [
                        better("Morale", "+15%"),
                        better("Perception", "+8")
                    ]
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
                    text: "Bribe the inspector, keep the upgrade budget",
                    moralImpact: -12.0,
                    cash: EventStakes.jackpot,
                    fallout: Fallout(
                        chance: 0.4,
                        delay: 60,
                        fine: EventStakes.fine,
                        descriptions: [worse("Perception", "-15")],
                        consequences: { gs in
                            gs.publicPerception -= 15
                        }
                    ),
                    effect: { state in
                        state.environmentalImpact += 10
                    },
                    effectDescriptions: [
                        worse("Environment", "+10")
                    ]
                ),
                EventChoice(
                    text: "Minimal upgrades, generous paperwork",
                    moralImpact: -3.0,
                    cash: EventStakes.token,
                    effect: { state in
                        state.environmentalImpact += 5
                        state.publicPerception -= 3
                    },
                    effectDescriptions: [
                        worse("Environment", "+5"),
                        worse("Perception", "-3")
                    ]
                ),
                EventChoice(
                    text: "Upgrade for full compliance",
                    moralImpact: 8.0,
                    cash: EventStakes.commitment,
                    incomeShift: IncomeShift(bonus: -0.15, duration: 90),
                    effect: { state in
                        state.environmentalImpact -= 15
                        state.publicPerception += 5
                    },
                    effectDescriptions: [
                        better("Environment", "-15"),
                        better("Perception", "+5")
                    ]
                )
            ],
            triggerCondition: { state in
                state.automationLevel >= 2
            },
            category: .regulatory
        ),

        // Additional Workplace events
        GameEvent(
            title: "Employee Training Opportunity",
            description: "A subsidized training program is available. The subsidy is paid to you.",
            choices: [
                EventChoice(
                    text: "Skip the training, keep the subsidy",
                    moralImpact: -5.0,
                    cash: EventStakes.windfall,
                    fallout: Fallout(
                        delay: 45,
                        descriptions: [worse("Perception", "-5")],
                        consequences: { gs in
                            gs.publicPerception -= 5
                        }
                    ),
                    effect: { state in
                        state.workerMorale -= 0.05
                    },
                    effectDescriptions: [
                        worse("Morale", "-5%")
                    ]
                ),
                EventChoice(
                    text: "Invest in training",
                    moralImpact: 6.0,
                    cash: EventStakes.commitment,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 60),
                    effect: { state in
                        state.workerEfficiency += 0.15
                        state.workerMorale += 0.1
                        state.publicPerception += 4
                    },
                    effectDescriptions: [
                        better("Efficiency", "+0.15"),
                        better("Morale", "+10%"),
                        better("Perception", "+4")
                    ]
                )
            ],
            triggerCondition: { state in
                state.workers >= 3 && state.totalPackagesShipped > 250
            },
            category: .workplace
        ),

        GameEvent(
            title: "Workplace Safety Incident",
            description: "There's been an accident in your facility due to outdated safety measures.",
            choices: [
                EventChoice(
                    text: "Cover it up, file the insurance claim",
                    moralImpact: -10.0,
                    cash: EventStakes.jackpot,
                    fallout: Fallout(
                        chance: 0.4,
                        delay: 60,
                        fine: EventStakes.penalty,
                        descriptions: [worse("Perception", "-15"), worse("Morale", "-15%")],
                        consequences: { gs in
                            gs.publicPerception -= 15
                            gs.workerMorale -= 0.15
                        }
                    ),
                    effect: { state in
                        state.workerMorale -= 0.1
                    },
                    effectDescriptions: [
                        worse("Morale", "-10%")
                    ]
                ),
                EventChoice(
                    text: "Minimum required fixes",
                    moralImpact: -4.0,
                    cash: EventStakes.token,
                    effect: { state in
                        state.workerMorale -= 0.1
                        state.publicPerception -= 4
                    },
                    effectDescriptions: [
                        worse("Morale", "-10%"),
                        worse("Perception", "-4")
                    ]
                ),
                EventChoice(
                    text: "Overhaul safety protocols",
                    moralImpact: 7.0,
                    cash: EventStakes.commitment,
                    incomeShift: IncomeShift(bonus: -0.15, duration: 60),
                    effect: { state in
                        state.workerMorale += 0.2
                        state.publicPerception += 7
                    },
                    effectDescriptions: [
                        better("Morale", "+20%"),
                        better("Perception", "+7")
                    ]
                )
            ],
            triggerCondition: { state in
                state.workers >= 8 && state.corporateEthics < 0.7
            },
            category: .workplace
        ),

        // Additional Market events
        GameEvent(
            title: "Competitor Undercuts Prices",
            description: "A rival shipping company has dramatically lowered their prices.",
            choices: [
                EventChoice(
                    text: "Spread rumors about their quality",
                    moralImpact: -8.0,
                    cash: EventStakes.jackpot,
                    fallout: Fallout(
                        delay: 45,
                        descriptions: [worse("Perception", "-10")],
                        consequences: { gs in
                            gs.publicPerception -= 10
                        }
                    ),
                    effect: { state in
                        state.publicPerception -= 3
                    },
                    effectDescriptions: [
                        worse("Perception", "-3")
                    ]
                ),
                EventChoice(
                    text: "Match their prices temporarily",
                    moralImpact: 0.0,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 45),
                    effect: { state in
                        state.customerSatisfaction += 0.05
                    },
                    effectDescriptions: [
                        better("Satisfaction", "+5%")
                    ]
                ),
                EventChoice(
                    text: "Focus on quality over price",
                    moralImpact: 3.0,
                    cash: EventStakes.investment,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 60),
                    effect: { state in
                        state.customerSatisfaction += 0.15
                        state.workerMorale += 0.05
                        state.publicPerception += 6
                    },
                    effectDescriptions: [
                        better("Satisfaction", "+15%"),
                        better("Morale", "+5%"),
                        better("Perception", "+6")
                    ]
                )
            ],
            triggerCondition: { state in
                state.totalPackagesShipped > 200
            },
            category: .market
        ),

        GameEvent(
            title: "Supply Chain Disruption",
            description: "Global events have disrupted your supply chain, increasing operational costs.",
            choices: [
                EventChoice(
                    text: "Cut worker benefits to offset costs",
                    moralImpact: -7.0,
                    cash: EventStakes.windfall,
                    fallout: Fallout(
                        delay: 45,
                        descriptions: [worse("Perception", "-6")],
                        consequences: { gs in
                            gs.publicPerception -= 6
                        }
                    ),
                    effect: { state in
                        state.workerMorale -= 0.15
                        state.workerEfficiency -= 0.05
                    },
                    effectDescriptions: [
                        worse("Morale", "-15%"),
                        worse("Efficiency", "-0.05")
                    ]
                ),
                EventChoice(
                    text: "Pass the costs on to customers",
                    moralImpact: -5.0,
                    incomeShift: IncomeShift(bonus: 0.25, duration: 90),
                    effect: { state in
                        state.customerSatisfaction -= 0.1
                        state.publicPerception -= 3
                    },
                    effectDescriptions: [
                        worse("Satisfaction", "-10%"),
                        worse("Perception", "-3")
                    ]
                ),
                EventChoice(
                    text: "Absorb the costs",
                    moralImpact: 4.0,
                    cash: EventStakes.investment,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 60),
                    effect: { state in
                        state.customerSatisfaction += 0.1
                        state.publicPerception += 5
                    },
                    effectDescriptions: [
                        better("Satisfaction", "+10%"),
                        better("Perception", "+5")
                    ]
                )
            ],
            triggerCondition: { state in
                state.totalPackagesShipped > 300
            },
            category: .market
        ),

        // Additional Public Relations events
        GameEvent(
            title: "Charity Partnership Offer",
            description: "A local charity wants a partner for a community initiative. They're offering matching funds.",
            choices: [
                EventChoice(
                    text: "Take the matching funds, route them to \"operations\"",
                    moralImpact: -9.0,
                    cash: EventStakes.jackpot,
                    fallout: Fallout(
                        delay: 60,
                        descriptions: [worse("Perception", "-18"), worse("Satisfaction", "-5%")],
                        consequences: { gs in
                            gs.publicPerception -= 18
                            gs.customerSatisfaction -= 0.05
                        }
                    ),
                    effect: { state in
                        state.publicPerception += 6
                    },
                    effectDescriptions: [
                        better("Perception", "+6")
                    ]
                ),
                EventChoice(
                    text: "Minimal participation",
                    moralImpact: 2.0,
                    cash: EventStakes.token,
                    incomeShift: IncomeShift(bonus: -0.05, duration: 30),
                    effect: { state in
                        state.publicPerception += 4
                    },
                    effectDescriptions: [
                        better("Perception", "+4")
                    ]
                ),
                EventChoice(
                    text: "Fully sponsor the program",
                    moralImpact: 8.0,
                    cash: EventStakes.commitment,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 60),
                    effect: { state in
                        state.customerSatisfaction += 0.1
                        state.publicPerception += 15
                    },
                    effectDescriptions: [
                        better("Satisfaction", "+10%"),
                        better("Perception", "+15")
                    ]
                )
            ],
            triggerCondition: { state in
                state.totalPackagesShipped > 400
            },
            category: .publicRelations
        ),

        GameEvent(
            title: "Social Media Backlash",
            description: "Your company's practices are trending. Not in a good way.",
            choices: [
                EventChoice(
                    text: "Buy five-star reviews in bulk",
                    moralImpact: -10.0,
                    cash: EventStakes.jackpot,
                    fallout: Fallout(
                        chance: 0.5,
                        delay: 60,
                        descriptions: [worse("Satisfaction", "-15%"), worse("Perception", "-10")],
                        consequences: { gs in
                            gs.customerSatisfaction -= 0.15
                            gs.publicPerception -= 10
                        }
                    ),
                    effect: { state in
                        state.customerSatisfaction += 0.05
                    },
                    effectDescriptions: [
                        better("Satisfaction", "+5%")
                    ]
                ),
                EventChoice(
                    text: "Issue a heartfelt statement. Change nothing.",
                    moralImpact: -4.0,
                    cash: EventStakes.skim,
                    effect: { state in
                        state.publicPerception -= 4
                    },
                    effectDescriptions: [
                        worse("Perception", "-4")
                    ]
                ),
                EventChoice(
                    text: "Address concerns with real changes",
                    moralImpact: 6.0,
                    cash: EventStakes.commitment,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 60),
                    effect: { state in
                        state.customerSatisfaction += 0.05
                        state.publicPerception += 10
                    },
                    effectDescriptions: [
                        better("Satisfaction", "+5%"),
                        better("Perception", "+10")
                    ]
                )
            ],
            triggerCondition: { state in
                state.corporateEthics < 0.6 && state.totalPackagesShipped > 350
            },
            category: .publicRelations
        ),

        // Additional Regulatory events
        GameEvent(
            title: "Labor Law Changes",
            description: "New regulations require increased worker benefits and safety measures.",
            choices: [
                EventChoice(
                    text: "Lobby to kill the bill",
                    moralImpact: -9.0,
                    cash: EventStakes.jackpot,
                    fallout: Fallout(
                        chance: 0.5,
                        delay: 70,
                        fine: EventStakes.fine,
                        descriptions: [worse("Perception", "-10")],
                        consequences: { gs in
                            gs.publicPerception -= 10
                            gs.corporateEthics -= 0.1
                        }
                    ),
                    effect: { state in
                        state.publicPerception -= 4
                    },
                    effectDescriptions: [
                        worse("Perception", "-4")
                    ]
                ),
                EventChoice(
                    text: "Comply on paper, exploit the loopholes",
                    moralImpact: -5.0,
                    cash: EventStakes.skim,
                    effect: { state in
                        state.workerMorale -= 0.05
                        state.publicPerception -= 4
                    },
                    effectDescriptions: [
                        worse("Morale", "-5%"),
                        worse("Perception", "-4")
                    ]
                ),
                EventChoice(
                    text: "Implement full compliance",
                    moralImpact: 7.0,
                    cash: EventStakes.commitment,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 90),
                    effect: { state in
                        state.workerMorale += 0.15
                        state.publicPerception += 6
                    },
                    effectDescriptions: [
                        better("Morale", "+15%"),
                        better("Perception", "+6")
                    ]
                )
            ],
            triggerCondition: { state in
                state.workers >= 10
            },
            category: .regulatory
        ),

        GameEvent(
            title: "Tax Audit",
            description: "Government tax authorities are conducting an audit of your business.",
            choices: [
                EventChoice(
                    text: "Bribe the auditor",
                    moralImpact: -12.0,
                    cash: EventStakes.jackpot,
                    fallout: Fallout(
                        chance: 0.5,
                        delay: 60,
                        fine: EventStakes.penalty,
                        descriptions: [worse("Perception", "-15")],
                        consequences: { gs in
                            gs.publicPerception -= 15
                            gs.corporateEthics -= 0.2
                        }
                    ),
                    effect: { state in
                        state.publicPerception -= 3
                    },
                    effectDescriptions: [
                        worse("Perception", "-3")
                    ]
                ),
                EventChoice(
                    text: "Keep the creative deductions",
                    moralImpact: -7.0,
                    cash: EventStakes.windfall,
                    fallout: Fallout(
                        chance: 0.4,
                        delay: 45,
                        fine: EventStakes.fine,
                        descriptions: [worse("Perception", "-5")],
                        consequences: { gs in
                            gs.publicPerception -= 5
                            gs.corporateEthics -= 0.15
                        }
                    )
                ),
                EventChoice(
                    text: "Full transparency, pay what's owed",
                    moralImpact: 5.0,
                    cash: EventStakes.investment,
                    incomeShift: IncomeShift(bonus: -0.05, duration: 60),
                    effect: { state in
                        state.publicPerception += 5
                    },
                    effectDescriptions: [
                        better("Perception", "+5")
                    ]
                )
            ],
            triggerCondition: { state in
                state.totalPackagesShipped > 700
            },
            category: .regulatory
        ),

        // Technology events
        GameEvent(
            title: "Automation Breakthrough",
            description: "A new technology could replace a significant share of your workforce's tasks.",
            choices: [
                EventChoice(
                    text: "Roll it out, pocket the payroll savings",
                    moralImpact: -6.0,
                    cash: EventStakes.windfall,
                    fallout: Fallout(
                        delay: 45,
                        descriptions: [worse("Perception", "-6")],
                        consequences: { gs in
                            gs.publicPerception -= 6
                        }
                    ),
                    effect: { state in
                        state.automationEfficiency += 0.25
                        state.workerMorale -= 0.15
                        state.environmentalImpact += 3
                    },
                    effectDescriptions: [
                        better("Automation", "+0.25"),
                        worse("Morale", "-15%"),
                        worse("Environment", "+3")
                    ]
                ),
                EventChoice(
                    text: "Pass on it for now",
                    moralImpact: 0.0,
                    effect: { state in
                        state.customerSatisfaction -= 0.05
                        state.publicPerception -= 2
                    },
                    effectDescriptions: [
                        worse("Satisfaction", "-5%"),
                        worse("Perception", "-2")
                    ]
                ),
                EventChoice(
                    text: "Gradual rollout with worker retraining",
                    moralImpact: 4.0,
                    cash: EventStakes.investment,
                    incomeShift: IncomeShift(bonus: -0.1, duration: 60),
                    effect: { state in
                        state.automationEfficiency += 0.15
                        state.workerEfficiency += 0.1
                        state.workerMorale += 0.05
                        state.publicPerception += 6
                    },
                    effectDescriptions: [
                        better("Automation", "+0.15"),
                        better("Efficiency", "+0.1"),
                        better("Morale", "+5%"),
                        better("Perception", "+6")
                    ]
                )
            ],
            triggerCondition: { state in
                state.automationLevel >= 3
            },
            category: .technology
        ),

        // Crisis events
        GameEvent(
            title: "Natural Disaster",
            description: "A natural disaster has affected your region, disrupting operations.",
            choices: [
                EventChoice(
                    text: "Use the disaster to trim payroll",
                    moralImpact: -10.0,
                    cash: EventStakes.jackpot,
                    fallout: Fallout(
                        delay: 45,
                        descriptions: [worse("Perception", "-12")],
                        consequences: { gs in
                            gs.publicPerception -= 12
                        }
                    ),
                    effect: { state in
                        let workersToLayoff = min(state.workers / 4, 5)
                        state.workers -= workersToLayoff
                        state.workerMorale -= 0.2
                    },
                    effectDescriptions: [
                        worse("Workers", "-25% (max 5)"),
                        worse("Morale", "-20%")
                    ]
                ),
                EventChoice(
                    text: "Minimal support, resume operations",
                    moralImpact: -4.0,
                    cash: EventStakes.skim,
                    effect: { state in
                        state.workerMorale -= 0.1
                        state.publicPerception -= 5
                    },
                    effectDescriptions: [
                        worse("Morale", "-10%"),
                        worse("Perception", "-5")
                    ]
                ),
                EventChoice(
                    text: "Paid leave for affected workers",
                    moralImpact: 8.0,
                    cash: EventStakes.commitment,
                    incomeShift: IncomeShift(bonus: -0.15, duration: 60),
                    effect: { state in
                        state.workerMorale += 0.3
                        state.publicPerception += 12
                    },
                    effectDescriptions: [
                        better("Morale", "+30%"),
                        better("Perception", "+12")
                    ]
                )
            ],
            triggerCondition: { state in
                state.workers >= 8
            },
            category: .crisis
        )
    ]

    // Include the new events in the event catalog
    private var allEvents: [GameEvent] {
        return eventCatalog + [lateGameEvent, systemicCollapseEvent, corporateTakeoverEvent]
    }

#if DEBUG
    /// Read-only access to the full event catalog for simulation/validation tests.
    /// Mirrors the existing "internal (not private) so tests can exercise it" pattern used
    /// by `eventTriggerChance`, `checkForReformEnding`, and `safeCalculatePrice`. Has no
    /// effect on shipping behavior and is excluded from release builds.
    var allEventsForTesting: [GameEvent] { allEvents }

    /// Present an event by title, for screenshots and manual QA (`-debugEvent "<title>"`).
    func presentForTesting(titled title: String) {
        currentEvent = allEvents.first { $0.title == title }
    }
#endif
}
