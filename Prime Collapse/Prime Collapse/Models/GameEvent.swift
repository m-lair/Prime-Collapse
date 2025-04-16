import Foundation

struct GameEvent: Identifiable {
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
    }
    
    let category: Category
}

struct EventChoice: Identifiable {
    let id = UUID()
    let text: String
    let effect: (GameState) -> Void
    let moralImpact: Double
    
    // Initialize with default values to simplify creation
    init(
        text: String,
        moralImpact: Double = 0,
        effect: @escaping (GameState) -> Void = { _ in }
    ) {
        self.text = text
        self.moralImpact = moralImpact
        self.effect = effect
    }
} 