import Foundation

// New struct to describe an effect
struct EffectDescription: Identifiable, Hashable {
    let id = UUID()
    let metricName: String // e.g., "Money", "Worker Morale", "Public Perception"
    let changeDescription: String // e.g., "+$100", "-5%", "Significant Increase"
    let impactType: ImpactType // Enum to help with formatting (positive, negative, neutral)

    enum ImpactType {
        case positive
        case negative
        case neutral
    }
}

struct GameEvent: Identifiable, Equatable {
    
    let id = UUID()
    let title: String
    let description: String
    let choices: [EventChoice]
    let triggerCondition: (GameState) -> Bool
    
    // Categories for organization
    enum Category {
        case workplace
        case market
        case publicRelations
        case regulatory
        case technology
        case crisis
    }
    
    static func == (lhs: GameEvent, rhs: GameEvent) -> Bool {
        lhs.title == rhs.title
    }
    
    let category: Category
}

struct EventChoice: Identifiable {
    let id = UUID()
    let text: String
    let effect: (GameState) -> Void
    let moralImpact: Double // Negative for unethical, positive for ethical
    let canChoose: ((GameState) -> Bool)? // Optional condition to enable/disable choice
    let disabledReason: ((GameState) -> String)? // Change to closure type
    let effectDescriptions: [EffectDescription]? // Optional array of effect descriptions
    
    // Initialize with default values to simplify creation
    init(
        text: String,
        moralImpact: Double = 0,
        effect: @escaping (GameState) -> Void = { _ in },
        canChoose: ((GameState) -> Bool)? = nil,
        disabledReason: ((GameState) -> String)? = nil, // Update initializer type
        effectDescriptions: [EffectDescription]? = nil
    ) {
        self.text = text
        self.moralImpact = moralImpact
        self.effect = effect
        self.canChoose = canChoose
        self.disabledReason = disabledReason // Assign the closure
        self.effectDescriptions = effectDescriptions
    }
} 
