import SwiftUI

struct GameInvestmentTray: View {
    @Environment(\.dismiss) private var dismiss
    let game: GameState
    var remaining: Double? = nil
    let preview: (Upgrade) -> HolidayRushUpgradePreview?
    let purchase: (Upgrade) -> Void
    @State private var category = Category.team
    @State private var selectedID: UUID?

    private enum Category: String, CaseIterable {
        case team = "Team", process = "Process", automation = "Automation"

        func contains(_ upgrade: Upgrade) -> Bool {
            let automation = ["Automate Sorting", "AI Optimization", "Predictive Maintenance",
                              "Worker Replacement System", "Robotic Workforce Enhancement"]
            let team = ["Hire Worker", "Basic Training", "Safety Placards", "Extended Shifts",
                        "Performance Bonuses", "Remove Worker Breaks", "Child Labor Loopholes", "Employee Surveillance"]
            switch self {
            case .automation: return automation.contains(upgrade.name)
            case .team: return team.contains(upgrade.name)
            case .process: return !automation.contains(upgrade.name) && !team.contains(upgrade.name)
            }
        }
    }

    private var upgrades: [Upgrade] {
        UpgradeManager.availableUpgrades.filter {
            category.contains($0) && ($0.isRepeatable || !game.hasBeenPurchased($0))
        }
    }

    private var selected: Upgrade? {
        upgrades.first { $0.id == selectedID } ?? upgrades.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Investments").font(.title2.bold())
                Spacer()
                Text(game.money.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    .font(.headline).monospacedDigit()
                Button("Done") { dismiss() }.frame(minHeight: 44)
            }
            Picker("Investment type", selection: $category) {
                ForEach(Category.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let upgrade = selected { details(upgrade) }
                    VStack(spacing: 0) {
                        ForEach(upgrades) { upgrade in
                            Button { selectedID = upgrade.id } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: upgrade.id == selected?.id ? "largecircle.fill.circle" : "circle")
                                        .foregroundStyle(upgrade.id == selected?.id ? GamePalette.orange : GamePalette.label.opacity(0.5))
                                    Text(upgrade.name).frame(maxWidth: .infinity, alignment: .leading)
                                    if !game.isUpgradeUnlocked(upgrade) {
                                        Image(systemName: "lock").accessibilityLabel("Locked")
                                    }
                                    Text(game.getCurrentUpgradeCost(upgrade).formatted(.currency(code: "USD").precision(.fractionLength(0))))
                                        .monospacedDigit()
                                }
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(upgrade.id == selected?.id ? .isSelected : [])
                            Divider().overlay(GamePalette.label.opacity(0.1))
                        }
                    }
                    if upgrades.isEmpty { Text("All investments in this category are complete.") }
                }
            }
        }
        .padding(20)
        .foregroundStyle(GamePalette.label)
        .background(GamePalette.ink)
        .tint(GamePalette.orange)
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: category) { _, _ in selectedID = nil }
    }

    private func details(_ upgrade: Upgrade) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(upgrade.name).font(.title2.bold())
            Text(upgrade.description).font(.callout).foregroundStyle(GamePalette.label.opacity(0.75))
            if let estimate = preview(upgrade) {
                Text("\(estimate.automaticRateBefore.formatted(.number.precision(.fractionLength(0...3)))) → \(estimate.automaticRateAfter.formatted(.number.precision(.fractionLength(0...3)))) packages / sec")
                    .font(.headline).foregroundStyle(GamePalette.teal)
                Text("Per package \(estimate.packageValueBefore.formatted(.currency(code: "USD"))) → \(estimate.packageValueAfter.formatted(.currency(code: "USD")))")
                    .font(.callout)
                DisclosureGroup("Income details") {
                    VStack(alignment: .leading, spacing: 6) {
                        if let seconds = estimate.paybackSeconds {
                            Text(seconds == 0 ? "Cash returned covers the price." : "Passive income payback: about \((seconds / 60).formatted(.number.precision(.fractionLength(1)))) minutes.")
                            if let remaining, seconds > remaining {
                                Text("That is longer than the active time left. Production benefits start immediately.")
                            }
                        } else {
                            Text("No increase in passive income at current rates.")
                        }
                        Text("Income estimate at current rates. Manual shipping and later decisions change the payback.")
                    }
                    .font(.caption).foregroundStyle(GamePalette.label.opacity(0.7))
                }
                .font(.callout)
            }
            if upgrade.moralImpact != 0 {
                Text("Ethics \(upgrade.moralImpact.formatted(.number.sign(strategy: .always())) )")
                    .font(.callout)
            }
            if !game.isUpgradeUnlocked(upgrade) {
                Text(game.getUpgradeRequirementDescription(upgrade) ?? "Requirements not met")
                    .font(.callout).foregroundStyle(GamePalette.orange)
            }
            if upgrade.name == "Hire Worker", game.workers >= GameState.maxWorkers {
                Text("Worker limit reached").font(.callout)
            }
            Button {
                purchase(upgrade)
            } label: {
                Text("Invest \(game.getCurrentUpgradeCost(upgrade).formatted(.currency(code: "USD").precision(.fractionLength(2))))")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(game.isRunTerminal || !game.isUpgradeUnlocked(upgrade) ||
                      game.money < game.getCurrentUpgradeCost(upgrade) ||
                      (upgrade.name == "Hire Worker" && game.workers >= GameState.maxWorkers))
        }
        .padding(18)
        .background(GamePalette.floor, in: RoundedRectangle(cornerRadius: 12))
    }
}
