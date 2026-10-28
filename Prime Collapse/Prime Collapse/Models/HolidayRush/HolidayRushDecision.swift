import Foundation

struct HolidayRushDecision: Identifiable {
    struct Choice: Identifiable {
        let id: String
        let title: String
        let detail: String
        let cost: Double
        let ethics: Double
        let morale: Double
        let efficiency: Double
    }

    let id: String
    let time: Double
    let title: String
    let detail: String
    let choices: [Choice]

    static let schedule: [Self] = [
        .init(id: "staffing", time: 120, title: "Seasonal staffing", detail: "The team needs support as holiday orders rise.", choices: [
            .init(id: "staffing-care", title: "Fund paid training", detail: "$35 · Ethics +8 · Morale +10% · Efficiency +10%", cost: 35, ethics: 8, morale: 0.10, efficiency: 1.10),
            .init(id: "staffing-balanced", title: "Rotate the workload", detail: "Free · Ethics +3 · Morale +5% · Efficiency −10%", cost: 0, ethics: 3, morale: 0.05, efficiency: 0.90),
            .init(id: "staffing-fast", title: "Demand faster shifts", detail: "Free · Ethics −22 · Morale −18% · Efficiency +30%", cost: 0, ethics: -22, morale: -0.18, efficiency: 1.30)
        ]),
        .init(id: "backlog", time: 300, title: "The delivery backlog", detail: "Orders are stacking up. How will you handle overtime?", choices: [
            .init(id: "backlog-care", title: "Pay voluntary overtime", detail: "$65 · Ethics +8 · Morale +10% · Efficiency +15%", cost: 65, ethics: 8, morale: 0.10, efficiency: 1.15),
            .init(id: "backlog-balanced", title: "Protect rest breaks", detail: "Free · Ethics +5 · Morale +10% · Efficiency −10%", cost: 0, ethics: 5, morale: 0.10, efficiency: 0.90),
            .init(id: "backlog-fast", title: "Make overtime mandatory", detail: "Free · Ethics −25 · Morale −22% · Efficiency +40%", cost: 0, ethics: -25, morale: -0.22, efficiency: 1.40)
        ]),
        .init(id: "priority", time: 480, title: "A late priority shipment", detail: "A rush order arrives as the deadline approaches.", choices: [
            .init(id: "priority-care", title: "Fund a safe final push", detail: "$95 · Ethics +6 · Morale +8% · Efficiency +20%", cost: 95, ethics: 6, morale: 0.08, efficiency: 1.20),
            .init(id: "priority-balanced", title: "Keep the agreed pace", detail: "Free · Ethics +3 · Morale +5% · Efficiency unchanged", cost: 0, ethics: 3, morale: 0.05, efficiency: 1),
            .init(id: "priority-fast", title: "Skip safety checks", detail: "Free · Ethics −30 · Morale −25% · Efficiency +50%", cost: 0, ethics: -30, morale: -0.25, efficiency: 1.50)
        ])
    ]
}
