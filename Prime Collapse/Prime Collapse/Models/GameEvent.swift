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

/// Cash moved by an event choice, sized from the player's economy at the moment of the decision
/// so it stays meaningful from the first hundred packages to the late game.
struct MoneyStake {
    enum Direction { case gain, cost }

    let direction: Direction
    /// Minutes of typical earnings (`GameState.earningsPerMinute`).
    let minutes: Double
    /// Share of the current balance. Applies to gains and costs alike, so a large balance makes
    /// both the shortcut and the decent option bigger and the tension survives into the late game.
    let balanceShare: Double
    /// Floor so early-game stakes are worth noticing.
    let minimum: Double

    static func gain(minutes: Double, balanceShare: Double = 0, minimum: Double) -> MoneyStake {
        MoneyStake(direction: .gain, minutes: minutes, balanceShare: balanceShare, minimum: minimum)
    }

    static func cost(minutes: Double, balanceShare: Double = 0, minimum: Double) -> MoneyStake {
        MoneyStake(direction: .cost, minutes: minutes, balanceShare: balanceShare, minimum: minimum)
    }

    /// Size before any affordability cap. Used for delayed fines, which can exceed today's balance.
    func sizedAmount(in state: GameState) -> Double {
        max(minimum, minutes * state.earningsPerMinute, balanceShare * state.money)
    }

    /// Amount actually moved now. Costs are capped at the balance so a choice never locks.
    func amount(in state: GameState) -> Double {
        let sized = sizedAmount(in: state)
        return direction == .cost ? min(sized, state.money) : sized
    }

    func signedAmount(in state: GameState) -> Double {
        direction == .gain ? amount(in: state) : -amount(in: state)
    }
}

/// A temporary change to all income (taps and automation): +0.3 is +30% for `duration` seconds.
struct IncomeShift {
    let bonus: Double
    let duration: TimeInterval
}

/// Consequences that land later — the bill for a shortcut. Rolled once when the choice is made.
struct Fallout {
    /// 1.0 = certain.
    let chance: Double
    let delay: TimeInterval
    /// Sized when the choice is made, charged when the fallout lands.
    let fine: MoneyStake?
    /// Non-money rows for the sheet; the fine row is generated from `fine`.
    let descriptions: [EffectDescription]
    /// Must not touch money — that's what `fine` is for.
    let consequences: (GameState) -> Void

    init(chance: Double = 1.0,
         delay: TimeInterval,
         fine: MoneyStake? = nil,
         descriptions: [EffectDescription] = [],
         consequences: @escaping (GameState) -> Void = { _ in }) {
        self.chance = chance
        self.delay = delay
        self.fine = fine
        self.descriptions = descriptions
        self.consequences = consequences
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
    /// Immediate non-money effects. Money moves only through `cash`, `incomeShift` and `fallout`
    /// so the sheet always shows what the choice really pays or costs.
    let effect: (GameState) -> Void
    let moralImpact: Double // Negative for unethical, positive for ethical
    let canChoose: ((GameState) -> Bool)? // Optional condition to enable/disable choice
    let disabledReason: ((GameState) -> String)? // Change to closure type
    let effectDescriptions: [EffectDescription]? // Immediate non-money rows; money and ethics rows are generated
    let cash: MoneyStake?
    let incomeShift: IncomeShift?
    let fallout: Fallout?

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
        cash: MoneyStake? = nil,
        incomeShift: IncomeShift? = nil,
        fallout: Fallout? = nil,
        effect: @escaping (GameState) -> Void = { _ in },
        canChoose: ((GameState) -> Bool)? = nil,
        disabledReason: ((GameState) -> String)? = nil,
        effectDescriptions: [EffectDescription]? = nil,
        scalingFactors: EventScalingFactors? = nil
    ) {
        self.text = text
        self.moralImpact = moralImpact
        self.cash = cash
        self.incomeShift = incomeShift
        self.fallout = fallout
        self.effect = effect
        self.canChoose = canChoose
        self.disabledReason = disabledReason
        self.effectDescriptions = effectDescriptions
        self.scalingFactors = scalingFactors
    }

    /// Short-term money value of this choice: cash now plus the income shift over its window,
    /// at the current income rate. Ignores fallout — that's the point.
    func projectedMoney(in state: GameState) -> Double {
        let cashNow = cash?.signedAmount(in: state) ?? 0
        let shifted = incomeShift.map { $0.bonus * state.baseIncomePerSecond * $0.duration } ?? 0
        return cashNow + shifted
    }
}

/// Compact money strings for the event sheet: $45, $1.2K, $3.4M.
enum MoneyFormat {
    static func compact(_ value: Double) -> String {
        let magnitude = abs(value)
        let body: String
        switch magnitude {
        case 1_000_000...: body = String(format: "%.1fM", magnitude / 1_000_000)
        case 10_000...: body = String(format: "%.0fK", magnitude / 1_000)
        case 1_000...: body = String(format: "%.1fK", magnitude / 1_000)
        default: body = String(format: "%.0f", magnitude)
        }
        return "$" + body
    }

    static func signed(_ value: Double) -> String {
        (value < 0 ? "-" : "+") + compact(value)
    }
}
