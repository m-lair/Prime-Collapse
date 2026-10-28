import SwiftUI

struct GameInvestmentTray: View {
    @Environment(\.dismiss) private var dismiss
    let game: GameState
    var remaining: Double? = nil
    let preview: (Upgrade) -> HolidayRushUpgradePreview?
    let purchase: (Upgrade) -> Void
    @State private var category = Category.team
    @State private var selectedID: UUID?
    @State private var purchaseReceipt: String?
    @State private var purchaseCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Investments").font(.system(.title2, design: .rounded, weight: .bold))
                    Text("\(game.money.formatted(.currency(code: "USD").precision(.fractionLength(0)))) available")
                        .font(.subheadline).monospacedDigit().foregroundStyle(GamePalette.teal)
                }
                Spacer()
                Button("Done") { dismiss() }.frame(minWidth: 44, minHeight: 44)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Category.allCases, id: \.self) { item in
                        Button { category = item } label: {
                            Text(item.rawValue).font(.subheadline.bold())
                                .padding(.horizontal, 16).frame(minHeight: 44)
                                .foregroundStyle(category == item ? GamePalette.ink : GamePalette.label)
                                .background(category == item ? GamePalette.label : GamePalette.floor, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(category == item ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let receipt = purchaseReceipt {
                            Label(receipt, systemImage: "checkmark.circle.fill")
                                .font(.callout).foregroundStyle(GamePalette.teal)
                                .accessibilityLabel("Investment purchased. \(receipt)")
                        }
                        if let upgrade = selected { details(upgrade).id("selection") }
                        Text("CHOOSE AN INVESTMENT")
                            .font(.caption.weight(.bold)).tracking(1.5)
                            .foregroundStyle(GamePalette.label.opacity(0.7))
                        VStack(spacing: 0) {
                            ForEach(upgrades) { upgrade in
                                Button {
                                    selectedID = upgrade.id
                                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                                        proxy.scrollTo("selection", anchor: .top)
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: upgrade.id == selected?.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(upgrade.id == selected?.id ? GamePalette.orange : GamePalette.label.opacity(0.5))
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(upgrade.name).font(.headline)
                                            if !game.isUpgradeUnlocked(upgrade) {
                                                Label("Locked · View requirements", systemImage: "lock")
                                                    .font(.caption).foregroundStyle(GamePalette.label.opacity(0.7))
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(game.getCurrentUpgradeCost(upgrade).formatted(.currency(code: "USD").precision(.fractionLength(0))))
                                            .font(.subheadline).monospacedDigit()
                                    }
                                    .padding(.vertical, 16).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(upgrade.id == selected?.id ? .isSelected : [])
                                Divider().overlay(GamePalette.label.opacity(0.1))
                            }
                        }
                        if upgrades.isEmpty { Text("All investments in this category are complete.") }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(22)
        .foregroundStyle(GamePalette.label)
        .background(GamePalette.ink)
        .tint(GamePalette.orange)
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.success, trigger: purchaseCount)
        .onChange(of: category) { _, _ in selectedID = nil }
    }

    private func details(_ upgrade: Upgrade) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(upgrade.name).font(.system(.title, design: .rounded, weight: .bold))
            Text(upgrade.description).font(.callout).foregroundStyle(GamePalette.label.opacity(0.8))
            if let estimate = preview(upgrade) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AUTOMATIC PACKAGES / SEC")
                        .font(.caption.weight(.bold)).tracking(1)
                    Text("\(estimate.automaticRateBefore.formatted(.number.precision(.fractionLength(0...3)))) → \(estimate.automaticRateAfter.formatted(.number.precision(.fractionLength(0...3))))")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(GamePalette.teal).monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading, spacing: 8) {
                    if estimate.ethicsAfter != game.ethicsScore {
                        Label("Ethics \(Int(game.ethicsScore)) → \(Int(estimate.ethicsAfter))", systemImage: "scale.3d")
                    }
                    if estimate.moraleAfter != game.workerMorale {
                        Label("Morale \(Int(game.workerMorale * 100))% → \(Int(estimate.moraleAfter * 100))%", systemImage: "person.2")
                    }
                }
                .font(.callout)
                DisclosureGroup("Income details") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Per package \(estimate.packageValueBefore.formatted(.currency(code: "USD"))) → \(estimate.packageValueAfter.formatted(.currency(code: "USD")))")
                        if let seconds = estimate.paybackSeconds {
                            Text(seconds == 0 ? "Cash returned covers the price." : "Passive income payback: about \((seconds / 60).formatted(.number.precision(.fractionLength(1)))) minutes.")
                            if let remaining, seconds > remaining {
                                Text("That is longer than the active time left. Production benefits start immediately.")
                            }
                        } else {
                            Text("No increase in passive income at current rates.")
                        }
                        Text("At current rates. Manual shipping and later decisions change the payback.")
                    }
                    .font(.callout).foregroundStyle(GamePalette.label.opacity(0.75)).padding(.top, 8)
                }
                .font(.callout)
            }
            if !game.isUpgradeUnlocked(upgrade) {
                Label(game.getUpgradeRequirementDescription(upgrade) ?? "Requirements not met", systemImage: "lock")
                    .font(.callout).foregroundStyle(GamePalette.orange)
            }
            if upgrade.name == "Hire Worker", game.workers >= GameState.maxWorkers {
                Text("Worker limit reached").font(.callout)
            } else if game.money < game.getCurrentUpgradeCost(upgrade) {
                Text("Need \((game.getCurrentUpgradeCost(upgrade) - game.money).formatted(.currency(code: "USD"))) more")
                    .font(.callout).foregroundStyle(GamePalette.label.opacity(0.8))
            }
            Button {
                let previousCount = game.purchasedUpgradeIDs.count
                purchase(upgrade)
                if game.purchasedUpgradeIDs.count > previousCount {
                    purchaseReceipt = "\(upgrade.name) · applied to your operation"
                    purchaseCount += 1
                }
            } label: {
                Text("Invest \(game.getCurrentUpgradeCost(upgrade).formatted(.currency(code: "USD").precision(.fractionLength(2))))")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GameActionStyle())
            .disabled(game.isRunTerminal || !game.isUpgradeUnlocked(upgrade) ||
                      game.money < game.getCurrentUpgradeCost(upgrade) ||
                      (upgrade.name == "Hire Worker" && game.workers >= GameState.maxWorkers))
        }
        .padding(.vertical, 8)
    }
}
