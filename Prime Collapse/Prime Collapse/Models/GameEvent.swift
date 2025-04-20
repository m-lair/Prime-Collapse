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
    
    var id = UUID()
    let title: String
    let description: String
    let choices: [EventChoice]
    let triggerCondition: (GameState) -> Bool
    
    // New property for event severity that scales with game progression
    let importance: EventImportance
    
    // Categories for organization
    enum Category {
        case workplace
        case market
        case publicRelations
        case regulatory
        case technology
        case crisis
    }
    
    // Event importance determines how severely it impacts the game
    enum EventImportance {
        case minor
        case moderate
        case major
        case critical
        
        // Calculate a scaling factor based on importance
        // Critical events should scale more with game progress
        var baseScalingFactor: Double {
            switch self {
            case .minor: return 1.0
            case .moderate: return 1.2
            case .major: return 1.5
            case .critical: return 2.0
            }
        }
    }
    
    // Add a default importance if none is specified
    init(title: String, description: String, choices: [EventChoice], triggerCondition: @escaping (GameState) -> Bool, category: Category, importance: EventImportance = .moderate) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.choices = choices
        self.triggerCondition = triggerCondition
        self.category = category
        self.importance = importance
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
    
    // New property for dynamic choice scaling
    let scalingFactors: EventScalingFactors?
    
    // Struct to define how a choice scales with game progress
    struct EventScalingFactors {
        // How much more intensive monetary effects become in late game
        let monetaryScaling: Double
        // How much more drastic moral impacts become in late game
        let moralImpactScaling: Double
        // How much more significant stat effects become in late game
        let statEffectScaling: Double
        
        // Default values if none specified
        static let standard = EventScalingFactors(
            monetaryScaling: 1.0,
            moralImpactScaling: 1.0,
            statEffectScaling: 1.0
        )
        
        // Scaling for more extreme choices
        static let extreme = EventScalingFactors(
            monetaryScaling: 1.5,
            moralImpactScaling: 1.3,
            statEffectScaling: 1.2
        )
    }
    
    // Initialize with default values to simplify creation
    init(
        text: String,
        moralImpact: Double = 0,
        effect: @escaping (GameState) -> Void = { _ in },
        canChoose: ((GameState) -> Bool)? = nil,
        disabledReason: ((GameState) -> String)? = nil,
        effectDescriptions: [EffectDescription]? = nil,
        scalingFactors: EventScalingFactors? = nil
    ) {
        self.text = text
        self.moralImpact = moralImpact
        self.effect = effect
        self.canChoose = canChoose
        self.disabledReason = disabledReason
        self.effectDescriptions = effectDescriptions
        self.scalingFactors = scalingFactors
    }
} 
