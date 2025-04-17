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
                    moralImpact: 5.0, // Ethical
                    effect: { state in
                        state.money -= Double(state.workers) * 500
                        state.workerEfficiency += 0.1
                        state.workerMorale += 0.2
                        state.publicPerception += 5 // Positive perception for improvement
                    },
                    canChoose: { $0.money >= Double($0.workers) * 500 },
                    disabledReason: { state in
                        let cost = Double(state.workers) * 500
                        return "Requires $\(String(format: "%.0f", cost))"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$500 / worker", impactType: .negative),
                        EffectDescription(metricName: "Efficiency", changeDescription: "+0.1", impactType: .positive),
                        EffectDescription(metricName: "Morale", changeDescription: "+20%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+5", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Ignore their complaints",
                    moralImpact: -8.0, // Unethical
                    effect: { state in
                        state.workerEfficiency -= 0.2
                        state.workerMorale -= 0.1
                        state.publicPerception -= 10 // Negative perception for ignoring
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Efficiency", changeDescription: "-0.2", impactType: .negative),
                        EffectDescription(metricName: "Morale", changeDescription: "-10%", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-10", impactType: .negative)
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
            description: "The shipping market is experiencing unexpected growth!",
            choices: [
                EventChoice(
                    text: "Raise prices temporarily",
                    moralImpact: -5.0, // Unethical
                    effect: { state in
                        state.packageValue *= 1.5
                        state.publicPerception -= 3 // Slight negative perception for price gouging
                        
                        // Schedule price return after 30 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            state.packageValue /= 1.5
                        }
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Package Value", changeDescription: "+50% (Temporary)", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "-3", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Keep prices stable for customer loyalty",
                    moralImpact: 3.0, // Ethical
                    effect: { state in
                        state.customerSatisfaction += 0.1
                        state.publicPerception += 5 // Positive perception for loyalty focus
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Satisfaction", changeDescription: "+10%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+5", impactType: .positive)
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
            description: "A popular business magazine wants to do a feature on your company.",
            choices: [
                EventChoice(
                    text: "Showcase innovation and efficiency",
                    moralImpact: -2.0, // Slightly unethical
                    effect: { state in
                        state.automationEfficiency += 0.05
                        state.publicPerception += 3 // Slight boost for seeming innovative
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Perception", changeDescription: "+3", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Highlight worker treatment",
                    moralImpact: 4.0, // Ethical
                    effect: { state in
                        state.workerMorale += 0.2
                        state.money -= 1000
                        state.publicPerception += 8 // Better perception for worker focus
                    },
                    canChoose: { $0.money >= 1000 },
                    disabledReason: { state in
                        "Requires $1000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Morale", changeDescription: "+20%", impactType: .positive),
                        EffectDescription(metricName: "Money", changeDescription: "-$1000", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "+8", impactType: .positive)
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
                    text: "Upgrade for full compliance ($5000)",
                    moralImpact: 8.0, // Very ethical
                    effect: { state in
                        state.money -= 5000
                        state.ethicalChoicesMade += 1
                        state.environmentalImpact = max(0, state.environmentalImpact - 15) // Significant improvement
                        state.publicPerception += 5 // Positive perception
                    },
                    canChoose: { $0.money >= 5000 },
                    disabledReason: { state in
                        "Requires $5000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$5000", impactType: .negative),
                        EffectDescription(metricName: "Environment", changeDescription: "-15", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+5", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Cut corners with minimal upgrades ($1000)",
                    moralImpact: -5.0, // Unethical
                    effect: { state in
                        state.money -= 1000
                        state.corporateEthics -= 0.1
                        state.environmentalImpact = min(100, state.environmentalImpact + 5) // Slight increase
                        state.publicPerception -= 5 // Negative perception
                    },
                    canChoose: { $0.money >= 1000 },
                    disabledReason: { state in
                        "Requires $1000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$1000", impactType: .negative),
                        EffectDescription(metricName: "Environment", changeDescription: "+5", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-5", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-5", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Bribe the inspector ($2000)",
                    moralImpact: -12.0, // Very unethical
                    effect: { state in
                        state.money -= 2000
                        state.corporateEthics -= 0.3
                        state.environmentalImpact = min(100, state.environmentalImpact + 10) // Worse impact due to neglect
                        state.publicPerception -= 15 // Major negative perception hit
                    },
                    canChoose: { $0.money >= 2000 },
                    disabledReason: { state in
                        "Requires $2000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$2000", impactType: .negative),
                        EffectDescription(metricName: "Environment", changeDescription: "+10", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-15", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-12", impactType: .negative)
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
            description: "A specialized training program is available that could improve worker skills.",
            choices: [
                EventChoice(
                    text: "Invest in training ($1000 per worker)",
                    moralImpact: 6.0, // Ethical
                    effect: { state in
                        state.money -= Double(state.workers) * 1000
                        state.workerEfficiency += 0.15
                        state.workerMorale += 0.1
                        state.publicPerception += 4 // Positive perception for investing in workers
                    },
                    canChoose: { $0.money >= Double($0.workers) * 1000 },
                    disabledReason: { state in
                        let cost = Double(state.workers) * 1000
                        return "Requires $\(String(format: "%.0f", cost))"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$1000 / worker", impactType: .negative),
                        EffectDescription(metricName: "Efficiency", changeDescription: "+0.15", impactType: .positive),
                        EffectDescription(metricName: "Morale", changeDescription: "+10%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+4", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Skip training, focus on productivity",
                    moralImpact: -3.0, // Somewhat unethical
                    effect: { state in
                        state.workerMorale -= 0.05
                        state.publicPerception -= 2 // Slight negative perception
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Morale", changeDescription: "-5%", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-2", impactType: .negative)
                    ]
                )
            ],
            triggerCondition: { state in
                state.workers >= 3 && state.money > Double(state.workers) * 1000
            },
            category: .workplace
        ),
        
        GameEvent(
            title: "Workplace Safety Incident",
            description: "There's been an accident in your facility due to outdated safety measures.",
            choices: [
                EventChoice(
                    text: "Overhaul safety protocols ($3000)",
                    moralImpact: 7.0, // Very ethical
                    effect: { state in
                        state.money -= 3000
                        state.workerMorale += 0.2
                        state.ethicalChoicesMade += 1
                        state.publicPerception += 7 // Good perception for safety focus
                    },
                    canChoose: { $0.money >= 3000 },
                    disabledReason: { state in
                        "Requires $3000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$3000", impactType: .negative),
                        EffectDescription(metricName: "Morale", changeDescription: "+20%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+7", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Minimum required fixes ($800)",
                    moralImpact: -4.0, // Somewhat unethical
                    effect: { state in
                        state.money -= 800
                        state.workerMorale -= 0.1
                        state.publicPerception -= 4 // Negative perception for cutting corners
                    },
                    canChoose: { $0.money >= 800 },
                    disabledReason: { state in
                        "Requires $800"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$800", impactType: .negative),
                        EffectDescription(metricName: "Morale", changeDescription: "-10%", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-4", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-4", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Cover it up (legal risk)",
                    moralImpact: -10.0, // Very unethical
                    effect: { state in
                        state.corporateEthics -= 0.2
                        state.publicPerception -= 18 // Major hit for cover-up
                        // Risk of future legal costs
                        if Double.random(in: 0...1) < 0.3 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                                state.money -= 10000
                            }
                        }
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Perception", changeDescription: "-18", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-10", impactType: .negative),
                        EffectDescription(metricName: "Money", changeDescription: "Risk of -$10000", impactType: .negative)
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
                    text: "Match their prices temporarily",
                    moralImpact: -2.0, // Slightly unethical
                    effect: { state in
                        state.packageValue *= 0.8
                        state.money -= 2000 // Cost of price adjustment campaign
                        
                        // Return prices to normal after 45 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
                            state.packageValue /= 0.8
                        }
                    },
                    canChoose: { $0.money >= 2000 },
                    disabledReason: { state in
                        "Requires $2000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Package Value", changeDescription: "-20% (Temporary)", impactType: .negative),
                        EffectDescription(metricName: "Money", changeDescription: "-$2000", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-2", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Focus on quality over price",
                    moralImpact: 3.0, // Ethical
                    effect: { state in
                        state.customerSatisfaction += 0.15
                        state.workerMorale += 0.05
                        state.publicPerception += 6 // Good perception for quality focus
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Satisfaction", changeDescription: "+15%", impactType: .positive),
                        EffectDescription(metricName: "Morale", changeDescription: "+5%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+6", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Spread rumors about competitor quality",
                    moralImpact: -8.0, // Unethical
                    effect: { state in
                        state.packageValue *= 0.9 // Still need a small price drop
                        state.corporateEthics -= 0.2
                        state.publicPerception -= 12 // Negative perception for dirty tactics
                        
                        // Return prices to normal after 30 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            state.packageValue /= 0.9
                        }
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Package Value", changeDescription: "-10% (Temporary)", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-12", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-8", impactType: .negative)
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
                    text: "Absorb the costs temporarily",
                    moralImpact: 4.0, // Ethical
                    effect: { state in
                        state.money -= 3000
                        state.customerSatisfaction += 0.1
                        state.publicPerception += 5 // Positive perception for not passing costs
                    },
                    canChoose: { $0.money >= 3000 },
                    disabledReason: { state in
                        "Requires $3000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$3000", impactType: .negative),
                        EffectDescription(metricName: "Satisfaction", changeDescription: "+10%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+5", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Pass costs to customers",
                    moralImpact: -5.0, // Somewhat unethical
                    effect: { state in
                        state.packageValue *= 1.2
                        state.customerSatisfaction -= 0.15
                        state.publicPerception -= 5 // Negative perception for price hikes
                        
                        // Return prices after 40 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 40) {
                            state.packageValue /= 1.2
                        }
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Package Value", changeDescription: "+20% (Temporary)", impactType: .negative),
                        EffectDescription(metricName: "Satisfaction", changeDescription: "-15%", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-5", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-5", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Cut worker benefits to offset costs",
                    moralImpact: -7.0, // Unethical
                    effect: { state in
                        state.workerMorale -= 0.2
                        state.workerEfficiency -= 0.1
                        state.publicPerception -= 8 // Negative perception for cutting benefits
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Morale", changeDescription: "-20%", impactType: .negative),
                        EffectDescription(metricName: "Efficiency", changeDescription: "-0.1", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-8", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-7", impactType: .negative)
                    ]
                )
            ],
            triggerCondition: { state in
                state.money > 3000 && state.totalPackagesShipped > 300
            },
            category: .market
        ),
        
        // Additional Public Relations events
        GameEvent(
            title: "Charity Partnership Offer",
            description: "A local charity wants to partner with your company for a community initiative.",
            choices: [
                EventChoice(
                    text: "Fully sponsor the program ($5000)",
                    moralImpact: 8.0, // Very ethical
                    effect: { state in
                        state.money -= 5000
                        state.corporateEthics += 0.2
                        state.customerSatisfaction += 0.1
                        state.ethicalChoicesMade += 1
                        state.publicPerception += 15 // Significant perception boost
                    },
                    canChoose: { $0.money >= 5000 },
                    disabledReason: { state in
                        "Requires $5000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$5000", impactType: .negative),
                        EffectDescription(metricName: "Satisfaction", changeDescription: "+10%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+15", impactType: .positive),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "+8", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Minimal participation ($1000)",
                    moralImpact: 2.0, // Somewhat ethical
                    effect: { state in
                        state.money -= 1000
                        state.corporateEthics += 0.05
                        state.publicPerception += 4 // Minor perception boost
                    },
                    canChoose: { $0.money >= 1000 },
                    disabledReason: { state in
                        "Requires $1000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$1000", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "+4", impactType: .positive),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "+2", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Decline but use PR to claim involvement",
                    moralImpact: -9.0, // Very unethical
                    effect: { state in
                        state.customerSatisfaction += 0.05
                        state.corporateEthics -= 0.25
                        state.publicPerception -= 20 // Major hit for deceptive PR
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Satisfaction", changeDescription: "+5% (?)", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "-20", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-9", impactType: .negative)
                    ]
                )
            ],
            triggerCondition: { state in
                state.money > 5000 && state.totalPackagesShipped > 400
            },
            category: .publicRelations
        ),
        
        GameEvent(
            title: "Social Media Backlash",
            description: "Your company's practices are being criticized on social media platforms.",
            choices: [
                EventChoice(
                    text: "Address concerns with real changes",
                    moralImpact: 6.0, // Ethical
                    effect: { state in
                        state.money -= 4000
                        state.corporateEthics += 0.15
                        state.customerSatisfaction += 0.05
                        state.ethicalChoicesMade += 1
                        state.publicPerception += 10 // Good boost for addressing issues
                    },
                    canChoose: { $0.money >= 4000 },
                    disabledReason: { state in
                        "Requires $4000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$4000", impactType: .negative),
                        EffectDescription(metricName: "Satisfaction", changeDescription: "+5%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+10", impactType: .positive),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "+6", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Issue PR statement without changes",
                    moralImpact: -6.0, // Unethical
                    effect: { state in
                        state.money += 0
                        state.corporateEthics -= 0.1
                        state.publicPerception -= 8 // Hit for empty PR
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Perception", changeDescription: "-8", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-6", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Pay for positive reviews and comments",
                    moralImpact: -10.0, // Very unethical
                    effect: { state in
                        state.money -= 2500
                        state.corporateEthics -= 0.2
                        state.customerSatisfaction += 0.1 // Short term boost
                        state.publicPerception -= 15 // Initial hit for astroturfing
                        
                        // Risk of future fallout
                        DispatchQueue.main.asyncAfter(deadline: .now() + 50) {
                            if Double.random(in: 0...1) < 0.4 {
                                state.customerSatisfaction -= 0.3
                                state.corporateEthics -= 0.1
                                state.publicPerception -= 10 // Further hit if caught
                            }
                        }
                    },
                    canChoose: { $0.money >= 2500 },
                    disabledReason: { state in
                        "Requires $2500"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$2500", impactType: .negative),
                        EffectDescription(metricName: "Satisfaction", changeDescription: "+10% (Temporary)", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "-15", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-10", impactType: .negative),
                        EffectDescription(metricName: "Future Risk", changeDescription: "High", impactType: .negative)
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
                    text: "Implement full compliance",
                    moralImpact: 7.0, // Very ethical
                    effect: { state in
                        state.money -= 6000
                        state.workerMorale += 0.15
                        state.corporateEthics += 0.1
                        state.ethicalChoicesMade += 1
                        state.publicPerception += 6 // Positive perception for compliance
                    },
                    canChoose: { $0.money >= 6000 },
                    disabledReason: { state in
                        "Requires $6000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$6000", impactType: .negative),
                        EffectDescription(metricName: "Morale", changeDescription: "+15%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+6", impactType: .positive),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "+7", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Minimal compliance with loopholes",
                    moralImpact: -5.0, // Somewhat unethical
                    effect: { state in
                        state.money -= 1500
                        state.workerMorale -= 0.05
                        state.corporateEthics -= 0.05
                        state.publicPerception -= 6 // Negative perception
                    },
                    canChoose: { $0.money >= 1500 },
                    disabledReason: { state in
                        "Requires $1500"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$1500", impactType: .negative),
                        EffectDescription(metricName: "Morale", changeDescription: "-5%", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-6", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-5", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Lobby against regulations ($8000)",
                    moralImpact: -9.0, // Very unethical
                    effect: { state in
                        state.money -= 8000
                        state.corporateEthics -= 0.2
                        state.publicPerception -= 12 // Negative perception for lobbying
                        
                        // Risk of future investigation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 70) {
                            if Double.random(in: 0...1) < 0.5 {
                                state.money -= 10000
                                state.corporateEthics -= 0.1
                            }
                        }
                    },
                    canChoose: { $0.money >= 8000 },
                    disabledReason: { state in
                        "Requires $8000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$8000", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-12", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-9", impactType: .negative),
                        EffectDescription(metricName: "Future Risk", changeDescription: "High", impactType: .negative)
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
                    text: "Full transparency with records",
                    moralImpact: 5.0, // Ethical
                    effect: { state in
                        state.money -= 1000
                        state.corporateEthics += 0.1
                        state.publicPerception += 5 // Positive perception for transparency
                    },
                    canChoose: { $0.money >= 1000 },
                    disabledReason: { state in
                        "Requires $1000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$1000", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "+5", impactType: .positive),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "+5", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Hide questionable deductions",
                    moralImpact: -7.0, // Unethical
                    effect: { state in
                        state.publicPerception -= 8 // Negative perception for hiding
                        // Risk of larger fine if caught
                        if Double.random(in: 0...1) < 0.4 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 40) {
                                state.money -= 8000
                                state.corporateEthics -= 0.15
                            }
                        }
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Perception", changeDescription: "-8", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-7", impactType: .negative),
                        EffectDescription(metricName: "Future Risk", changeDescription: "Moderate", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Bribe the auditor ($3000)",
                    moralImpact: -12.0, // Very unethical
                    effect: { state in
                        state.money -= 3000
                        state.corporateEthics -= 0.3
                        state.publicPerception -= 18 // Major hit for bribery
                        
                        // High risk of major scandal
                        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                            if Double.random(in: 0...1) < 0.6 {
                                state.money -= 15000
                                state.corporateEthics -= 0.2
                                state.publicPerception -= 15 // Scandal hits perception hard
                            }
                        }
                    },
                    canChoose: { $0.money >= 3000 },
                    disabledReason: { state in
                        "Requires $3000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$3000", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-18", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-12", impactType: .negative),
                        EffectDescription(metricName: "Future Risk", changeDescription: "Very High", impactType: .negative)
                    ]
                )
            ],
            triggerCondition: { state in
                state.money > 15000 || state.totalPackagesShipped > 700
            },
            category: .regulatory
        ),
        
        // Technology events
        GameEvent(
            title: "Automation Breakthrough",
            description: "A new technology could significantly improve your automation systems.",
            choices: [
                EventChoice(
                    text: "Invest in advanced tech ($12000)",
                    moralImpact: -3.0, // Slightly unethical
                    effect: { state in
                        state.money -= 12000
                        state.automationEfficiency += 0.25
                        state.workerMorale -= 0.1
                        state.publicPerception -= 4 // Slight negative perception (job loss fear)
                        state.environmentalImpact += 3 // Tech often has env cost initially
                    },
                    canChoose: { $0.money >= 12000 },
                    disabledReason: { state in
                        "Requires $12000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$12000", impactType: .negative),
                        EffectDescription(metricName: "Morale", changeDescription: "-10%", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-4", impactType: .negative),
                        EffectDescription(metricName: "Environment", changeDescription: "+3", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-3", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Balanced approach with worker retraining ($8000)",
                    moralImpact: 4.0, // Ethical
                    effect: { state in
                        state.money -= 8000
                        state.automationEfficiency += 0.15
                        state.workerEfficiency += 0.1
                        state.workerMorale += 0.05
                        state.publicPerception += 6 // Positive perception for retraining
                        state.environmentalImpact += 1 // Still some impact
                    },
                    canChoose: { $0.money >= 8000 },
                    disabledReason: { state in
                        "Requires $8000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$8000", impactType: .negative),
                        EffectDescription(metricName: "Efficiency", changeDescription: "+0.1", impactType: .positive),
                        EffectDescription(metricName: "Morale", changeDescription: "+5%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+6", impactType: .positive),
                        EffectDescription(metricName: "Environment", changeDescription: "+1", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "+4", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Ignore new technology",
                    moralImpact: 1.0, // Slightly ethical
                    effect: { state in
                        state.customerSatisfaction -= 0.05
                        state.publicPerception -= 2 // Seen as stagnant
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Satisfaction", changeDescription: "-5%", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-2", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "+1", impactType: .positive)
                    ]
                )
            ],
            triggerCondition: { state in
                state.automationLevel >= 3 && state.money > 12000
            },
            category: .technology
        ),
        
        // Crisis events
        GameEvent(
            title: "Natural Disaster",
            description: "A natural disaster has affected your region, disrupting operations.",
            choices: [
                EventChoice(
                    text: "Support affected workers ($3000)",
                    moralImpact: 8.0, // Very ethical
                    effect: { state in
                        state.money -= 3000
                        state.workerMorale += 0.3
                        state.ethicalChoicesMade += 1
                        state.publicPerception += 12 // Strong positive perception
                    },
                    canChoose: { $0.money >= 3000 },
                    disabledReason: { state in
                        "Requires $3000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$3000", impactType: .negative),
                        EffectDescription(metricName: "Morale", changeDescription: "+30%", impactType: .positive),
                        EffectDescription(metricName: "Perception", changeDescription: "+12", impactType: .positive),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "+8", impactType: .positive)
                    ]
                ),
                EventChoice(
                    text: "Minimal support, focus on resuming operations",
                    moralImpact: -4.0, // Somewhat unethical
                    effect: { state in
                        state.money -= 1000
                        state.workerMorale -= 0.1
                        state.workerEfficiency -= 0.05
                        state.publicPerception -= 7 // Negative perception
                    },
                    canChoose: { $0.money >= 1000 },
                    disabledReason: { state in
                        "Requires $1000"
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Money", changeDescription: "-$1000", impactType: .negative),
                        EffectDescription(metricName: "Morale", changeDescription: "-10%", impactType: .negative),
                        EffectDescription(metricName: "Efficiency", changeDescription: "-0.05", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-7", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-4", impactType: .negative)
                    ]
                ),
                EventChoice(
                    text: "Use disaster to layoff underperforming workers",
                    moralImpact: -10.0, // Very unethical
                    effect: { state in
                        let workersToLayoff = min(state.workers / 4, 5)
                        state.workers -= workersToLayoff
                        state.workerMorale -= 0.3
                        state.corporateEthics -= 0.25
                        state.publicPerception -= 20 // Major negative perception
                    },
                    effectDescriptions: [
                        EffectDescription(metricName: "Workers", changeDescription: "Reduced", impactType: .negative),
                        EffectDescription(metricName: "Morale", changeDescription: "-30%", impactType: .negative),
                        EffectDescription(metricName: "Perception", changeDescription: "-20", impactType: .negative),
                        EffectDescription(metricName: "Ethics Score", changeDescription: "-10", impactType: .negative)
                    ]
                )
            ],
            triggerCondition: { state in
                state.workers >= 8
            },
            category: .crisis
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
        
        // Ensure money doesn't go negative
        if gameState.money < 0 {
            gameState.money = 0
        }
        
        // Update ethics score based on choice (uses inverted moralImpact)
        gameState.ethicsScore += choice.moralImpact
        gameState.ethicsScore = max(0, min(100, gameState.ethicsScore)) // Clamp score
        
        // Update corporate ethics as well (scaled down, logic inverted)
        let ethicsChange = choice.moralImpact / 20.0 // Scale impact to roughly -0.6 to +0.6 range
        gameState.corporateEthics += ethicsChange
        gameState.corporateEthics = max(0, min(1, gameState.corporateEthics)) // Clamp
        
        // Apply perception and environment impact from the choice effect closure
        // The effect closure now handles these directly. Ensure clamping after effect.
        gameState.publicPerception = max(0, min(100, gameState.publicPerception))
        gameState.environmentalImpact = max(0, min(100, gameState.environmentalImpact))
        
        // Track ethical choices for ending conditions (positive impact is now ethical)
        if choice.moralImpact > 0 {
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
        
        // Clear the current event
        currentEvent = nil
    }
} 
