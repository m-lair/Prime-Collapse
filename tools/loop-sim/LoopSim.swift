//
//  LoopSim.swift
//  Prime Collapse — headless loop simulator
//
//  Drives the REAL engine (GameState.processAutomation / shipPackage,
//  UpgradeManager.availableUpgrades + getCurrentUpgradeCost + applyUpgrade,
//  EventManager.eventTriggerChance + processChoice) the way the SwiftUI layer does,
//  under a set of player archetypes, for 100 games. Records key events, choices,
//  milestones and endings, then renders a markdown + JSON validation report.
//
//  Time model: the real loop ticks every 0.1s and integrates elapsed time inside
//  processAutomation(currentTime:). We advance a synthetic clock 1.0s per outer tick
//  (automation integrates identically) and run the event-eligibility roll 10x/sec to
//  match the real 0.1s check cadence and event frequency.
//

import Foundation

// MARK: - Archetypes & scenarios

enum Strategy: String, CaseIterable {
    case greedy      // chase profit/efficiency, take unethical options
    case ethical     // chase the Reform path, take ethical options
    case balanced    // buy cheapest unlocked upgrade, neutral choices
    case idle        // minimal tapping, lean on automation
    case random      // chaos-monkey baseline
}

enum Scenario: String, CaseIterable {
    case freshInstall  // GameState() defaults — what a brand-new player actually gets
    case restarted     // gs.reset() state — what you get after a collapse/restart
}

enum Outcome: String {
    case collapse              // isCollapsing == true (the only real terminal ending)
    case reformFlagOnly        // reached Reform criteria but game never ended on it
    case loopFlagOnly          // reached Loop criteria but game never ended on it
    case stagnated             // no income & nothing affordable for a long window
    case survivedToTimeout     // still running at the sim cap
}

struct EventLog { let time: Double; let title: String; let choice: String; let moral: Double }

struct RunResult {
    var strategy: Strategy
    var scenario: Scenario
    var outcome: Outcome = .survivedToTimeout
    var endSimTime: Double = 0

    var tFirstUpgrade: Double?
    var tFirstAutomationIncome: Double?
    var tFirst100Pkgs: Double?
    var tFirst500Pkgs: Double?
    var tFirst1500Pkgs: Double?
    var tFirst1000Dollars: Double?
    var tReformReached: Double?
    var tLoopReached: Double?
    var tCollapse: Double?
    var tStagnation: Double?

    var packages = 0
    var money = 0.0
    var lifetimeMoney = 0.0
    var workers = 0
    var ethics = 0.0
    var automationLevel = 0
    var perception = 0.0
    var environmental = 0.0
    var morale = 0.0
    var upgradesBought = 0

    var purchases: [String] = []
    var events: [EventLog] = []
    var taps = 0
    var ethicsSamples: [Double] = []
    var automationRateEnd = 0.0
    var idleIncomeAfterEnablersAt60s: Double?
}

// MARK: - Simulator

struct LoopSimulator {

    let gamesPerCell = 10
    let stepSeconds = 1.0
    let eventChecksPerSecond = 10
    let maxSimSeconds = 3000.0
    let maxBuysPerEval = 8     // a player can only tap "buy" a few times per decision window

    // Read-only mirrors of the engine's money/rate formulas — used ONLY to make player
    // decisions. Actual money/packages are produced by the real engine.

    func automationRatePerSecond(_ gs: GameState) -> Double {
        let moraleFactor: Double
        if gs.workerMorale < 0.5 { moraleFactor = gs.workerMorale * 2.0 }
        else if gs.workerMorale > 0.7 { moraleFactor = 1.0 + (gs.workerMorale - 0.7) / 3.0 }
        else { moraleFactor = 1.0 }
        let worker = gs.baseWorkerRate * Double(gs.workers) * gs.workerEfficiency
        let system = gs.baseSystemRate * gs.automationEfficiency
        let env = max(0, 1.0 - gs.environmentalImpact / 200.0)
        return (worker + system) * moraleFactor * env
    }

    func tapValue(_ gs: GameState) -> Double {
        let perception = 0.8 + (gs.publicPerception / 100.0 * 0.4)
        let satisfaction = 0.5 + (gs.customerSatisfaction * 0.5)
        return gs.packageValue * perception * satisfaction
    }

    func purchasePriority(_ strategy: Strategy, _ gs: GameState, _ all: [Upgrade]) -> [Upgrade] {
        func named(_ names: [String]) -> [Upgrade] { names.compactMap { n in all.first { $0.name == n } } }
        switch strategy {
        case .greedy:
            return named([
                "Optimize Logistics", "Hire Worker", "Improve Packaging",
                "Automate Sorting", "Employee Surveillance", "Rush Delivery",
                "Extended Shifts", "Child Labor Loopholes", "AI Optimization",
                "Aggressive Marketing Campaign", "Predictive Maintenance",
                "Remove Worker Breaks", "Algorithmic Wage Suppression",
                "Worker Replacement System", "Offshore Tax Havens",
                "Robotic Workforce Enhancement"
            ])
        case .ethical:
            return named([
                "Optimize Logistics", "Hire Worker", "Basic Training",
                "Safety Placards", "Improve Packaging", "Performance Bonuses",
                "Predictive Maintenance", "Sustainable Practices",
                "Community Investment Program", "Carbon Offset Program"
            ]).filter { $0.moralImpact >= 0 }
        case .balanced:
            return all.sorted { gs.getCurrentUpgradeCost($0) < gs.getCurrentUpgradeCost($1) }
        case .idle:
            return named([
                "Optimize Logistics", "Hire Worker", "Improve Packaging",
                "Automate Sorting", "Predictive Maintenance", "AI Optimization",
                "Robotic Workforce Enhancement", "Performance Bonuses"
            ])
        case .random:
            return all.shuffled()
        }
    }

    func chooseEventOption(_ strategy: Strategy, _ event: GameEvent, _ gs: GameState) -> EventChoice? {
        let affordable = event.choices.filter { ($0.canChoose?(gs) ?? true) }
        guard !affordable.isEmpty else { return event.choices.first }
        switch strategy {
        case .greedy:  return affordable.min { $0.moralImpact < $1.moralImpact }
        case .ethical: return affordable.max { $0.moralImpact < $1.moralImpact }
        case .idle:    return affordable.max { $0.moralImpact < $1.moralImpact }
        case .balanced:
            let sorted = affordable.sorted { $0.moralImpact < $1.moralImpact }
            return sorted[sorted.count / 2]
        case .random:  return affordable.randomElement()
        }
    }

    func tapsPerActiveSecond(_ strategy: Strategy) -> Int {
        switch strategy {
        case .greedy, .balanced, .ethical, .random: return 3
        case .idle: return 1
        }
    }

    // MARK: One game

    func simulateGame(strategy: Strategy, scenario: Scenario) -> RunResult {
        let gs = GameState()
        switch scenario {
        case .freshInstall: break          // keep GameState() defaults (workers 0, baseWorkerRate 0.0)
        case .restarted:    gs.reset()     // workers 1, baseWorkerRate 0.1, seeded Hire Worker
        }

        let em = EventManager()
        let catalog = em.allEventsForTesting
        let allUpgrades = UpgradeManager.availableUpgrades   // hoisted: the catalog is rebuilt per access
        let purchaseEvalInterval = 5                          // a player rescans the shop every few seconds, not every tick

        let start = Date()
        gs.lastUpdate = start

        var r = RunResult(strategy: strategy, scenario: scenario)
        var simNow = 0.0
        var lastEventTime = 0.0
        let baseEventChance = 0.02
        let minEventInterval = 120.0

        var lastMoneyProgress = 0.0
        var lastProgressTime = 0.0
        let stagnationWindow = 600.0

        var stillTapping = true
        // A player does not buy the same repeatable hundreds of times. This cap models that,
        // and also keeps the engine away from a latent crash: the repeatable-pricing bug lets
        // efficiency run away, and `totalPackagesShipped += packagesShipped` in processAutomation
        // is NOT overflow-guarded, so an unbounded runaway traps (SIGTRAP). Both are findings.
        var repeatableBuys: [String: Int] = [:]
        let maxRepeatableBuys = 40

        while simNow < maxSimSeconds {
            simNow += stepSeconds
            let currentDate = start.addingTimeInterval(simNow)

            // 1) Automation tick (real engine).
            gs.processAutomation(currentTime: currentDate)

            // 2) Event eligibility rolls (10x/sec to match the 0.1s cadence).
            if !gs.isCollapsing {
                for _ in 0..<eventChecksPerSecond {
                    let since = simNow - lastEventTime
                    guard since >= minEventInterval else { break }
                    let chance = EventManager.eventTriggerChance(
                        packagesShipped: gs.totalPackagesShipped,
                        timeSinceLastEvent: since,
                        baseChance: baseEventChance,
                        minInterval: minEventInterval
                    )
                    if Double.random(in: 0...1) < chance {
                        let eligible = catalog.filter { $0.triggerCondition(gs) }
                        if let event = eligible.randomElement(),
                           let choice = chooseEventOption(strategy, event, gs) {
                            em.currentEvent = event
                            em.processChoice(choice: choice, gameState: gs)
                            r.events.append(EventLog(time: simNow, title: event.title,
                                                     choice: choice.text, moral: choice.moralImpact))
                            lastEventTime = simNow
                        }
                        break
                    }
                }
            }

            // 3) Purchases: buy desired affordable upgrades, using the SAME methods the UI uses
            //    (getCurrentUpgradeCost runs validateGameState as a side effect — faithful).
            //    Evaluated on a realistic cadence so the validateGameState hot path doesn't
            //    dominate runtime; the priority list is ranked once per decision point.
            if !gs.isCollapsing && Int(simNow) % purchaseEvalInterval == 0 {
                let priority = purchasePriority(strategy, gs, allUpgrades)
                var boughtSomething = true
                var buysThisTick = 0
                // Bounded by a human tap-rate. Without this, the repeatable-pricing bug
                // (validateGameState dedupes purchasedUpgradeIDs, so repeatables never
                // re-scale) lets a cash-rich strategy buy one upgrade thousands of times in
                // a single window — a runaway that both breaks balance and hangs the sim.
                while boughtSomething && buysThisTick < maxBuysPerEval {
                    boughtSomething = false
                    for template in priority {
                        guard gs.isUpgradeUnlocked(template) else { continue }
                        if !template.isRepeatable && gs.hasBeenPurchased(template) { continue }
                        // Engine caps workers at 150 (validateGameState). Buying past the cap
                        // still charges money but the worker is stripped on the next validate —
                        // a real money-sink bug. A rational player stops, so the AI does too.
                        if template.name == "Hire Worker" && gs.workers >= 150 { continue }
                        if template.isRepeatable && repeatableBuys[template.name, default: 0] >= maxRepeatableBuys { continue }
                        let shownCost = gs.getCurrentUpgradeCost(template)
                        if gs.money >= shownCost {
                            let before = gs.purchasedUpgradeIDs.count
                            gs.applyUpgrade(template)
                            if gs.purchasedUpgradeIDs.count > before {
                                r.purchases.append(template.name)
                                r.upgradesBought += 1
                                repeatableBuys[template.name, default: 0] += 1
                                if r.tFirstUpgrade == nil { r.tFirstUpgrade = simNow }
                                boughtSomething = true
                                buysThisTick += 1
                                if buysThisTick >= maxBuysPerEval { break }
                            }
                        }
                    }
                }
            }

            // 4) Manual taps.
            if !gs.isCollapsing {
                let autoRate = automationRatePerSecond(gs)
                let taps = tapsPerActiveSecond(strategy)
                if autoRate >= Double(taps) && simNow > 60 { stillTapping = false }
                if autoRate <= 0 { stillTapping = true }   // dead idle loop -> must keep tapping
                if stillTapping {
                    for _ in 0..<taps { gs.shipPackage() }
                    r.taps += taps
                }
            }

            // 5) Milestones.
            if r.tFirstAutomationIncome == nil && automationRatePerSecond(gs) > 0 {
                r.tFirstAutomationIncome = simNow
            }
            if r.tFirst100Pkgs == nil && gs.totalPackagesShipped >= 100 { r.tFirst100Pkgs = simNow }
            if r.tFirst500Pkgs == nil && gs.totalPackagesShipped >= 500 { r.tFirst500Pkgs = simNow }
            if r.tFirst1500Pkgs == nil && gs.totalPackagesShipped >= 1500 { r.tFirst1500Pkgs = simNow }
            if r.tFirst1000Dollars == nil && gs.money >= 1000 { r.tFirst1000Dollars = simNow }

            if r.tReformReached == nil &&
                gs.ethicalChoicesMade >= 5 && gs.ethicsScore >= 50 && gs.money >= 1000 {
                r.tReformReached = simNow
            }
            if r.tLoopReached == nil &&
                gs.ethicsScore >= 15 && gs.ethicsScore <= 25 &&
                gs.money >= 2500 && gs.totalPackagesShipped >= 1500 && gs.workers >= 3 {
                r.tLoopReached = simNow
            }

            if Int(simNow) % 60 == 0 { r.ethicsSamples.append(gs.ethicsScore) }

            if scenario == .freshInstall && r.idleIncomeAfterEnablersAt60s == nil && simNow >= 60 {
                r.idleIncomeAfterEnablersAt60s = automationRatePerSecond(gs) * tapValue(gs)
            }

            if gs.lifetimeTotalMoneyEarned > lastMoneyProgress + 0.0001 {
                lastMoneyProgress = gs.lifetimeTotalMoneyEarned
                lastProgressTime = simNow
            }

            // Terminal conditions.
            if gs.isCollapsing {
                r.outcome = .collapse
                r.tCollapse = simNow
                break
            }
            if simNow - lastProgressTime > stagnationWindow && automationRatePerSecond(gs) <= 0 {
                r.outcome = .stagnated
                r.tStagnation = simNow
                break
            }
        }

        if r.outcome == .survivedToTimeout {
            if r.tReformReached != nil { r.outcome = .reformFlagOnly }
            else if r.tLoopReached != nil { r.outcome = .loopFlagOnly }
        }

        r.endSimTime = simNow
        r.packages = gs.totalPackagesShipped
        r.money = gs.money
        r.lifetimeMoney = gs.lifetimeTotalMoneyEarned
        r.workers = gs.workers
        r.ethics = gs.ethicsScore
        r.automationLevel = gs.automationLevel
        r.perception = gs.publicPerception
        r.environmental = gs.environmentalImpact
        r.morale = gs.workerMorale
        r.automationRateEnd = automationRatePerSecond(gs)
        return r
    }

    func runAll() -> [RunResult] {
        var results: [RunResult] = []
        for strategy in Strategy.allCases {
            for scenario in Scenario.allCases {
                for _ in 0..<gamesPerCell {
                    results.append(simulateGame(strategy: strategy, scenario: scenario))
                }
            }
        }
        return results
    }

    // MARK: Reporting

    func median(_ xs: [Double]) -> Double {
        guard !xs.isEmpty else { return .nan }
        let s = xs.sorted(); let n = s.count
        return n % 2 == 1 ? s[n/2] : (s[n/2 - 1] + s[n/2]) / 2
    }
    func fmt(_ x: Double?) -> String {
        guard let x = x, x.isFinite else { return "—" }
        return String(format: "%.0f", x)
    }
    func money(_ x: Double) -> String { String(format: "$%.0f", x) }

    func headline(_ results: [RunResult]) -> String {
        var lines: [String] = []
        lines.append("===== PRIME COLLAPSE — LOOP VALIDATION (\(results.count) GAMES) =====")
        var dist: [Outcome: Int] = [:]
        for r in results { dist[r.outcome, default: 0] += 1 }
        lines.append("Ending distribution:")
        for o in [Outcome.collapse, .reformFlagOnly, .loopFlagOnly, .stagnated, .survivedToTimeout] {
            lines.append(String(format: "  %-20@ %3d", o.rawValue as NSString, dist[o] ?? 0))
        }
        let reformReached = results.filter { $0.tReformReached != nil }.count
        let loopReached = results.filter { $0.tLoopReached != nil }.count
        lines.append("")
        lines.append("Reform criteria ever met: \(reformReached)/\(results.count)   Loop criteria ever met: \(loopReached)/\(results.count)")
        lines.append("(Reform/Loop never trigger the ending screen in code — collapse is the only terminal state.)")
        let fresh = results.filter { $0.scenario == .freshInstall }
        let freshIdle = fresh.compactMap { $0.idleIncomeAfterEnablersAt60s }
        let restarted = results.filter { $0.scenario == .restarted }
        lines.append("")
        lines.append("Fresh-install idle income at 60s (median): " + String(format: "$%.3f/s", median(freshIdle)))
        lines.append("Fresh   median time-to-first-automation-income: " + fmt(median(fresh.compactMap { $0.tFirstAutomationIncome })) + "s")
        lines.append("Restart median time-to-first-automation-income: " + fmt(median(restarted.compactMap { $0.tFirstAutomationIncome })) + "s")
        return lines.joined(separator: "\n")
    }

    func markdown(_ results: [RunResult]) -> String {
        var md: [String] = []
        md.append("# Prime Collapse — Gameplay Loop Validation Report")
        md.append("")
        md.append("Simulated **\(results.count) games** = \(Strategy.allCases.count) strategies × \(Scenario.allCases.count) scenarios × \(gamesPerCell) runs each, driving the real `GameState` / `UpgradeManager` / `EventManager` engine (compiled headless via `tools/loop-sim`). Step = \(stepSeconds)s, event checks = \(eventChecksPerSecond)/s, cap = \(Int(maxSimSeconds))s. RNG is the system generator (the engine itself uses unseeded `Double.random`), so exact numbers vary run to run; distributions at n=\(results.count) are stable.")
        md.append("")

        md.append("## Ending distribution")
        md.append("")
        md.append("| Outcome | Count |")
        md.append("|---|---|")
        var dist: [Outcome: Int] = [:]
        for r in results { dist[r.outcome, default: 0] += 1 }
        for o in [Outcome.collapse, .reformFlagOnly, .loopFlagOnly, .stagnated, .survivedToTimeout] {
            md.append("| \(o.rawValue) | \(dist[o] ?? 0) |")
        }
        md.append("")

        md.append("## Per strategy × scenario")
        md.append("")
        md.append("| Strategy | Scenario | Collapse | Reform met | Loop met | Stagnated | Median collapse t(s) | Median pkgs | Median lifetime\\$ |")
        md.append("|---|---|---|---|---|---|---|---|---|")
        for strat in Strategy.allCases {
            for scen in Scenario.allCases {
                let cell = results.filter { $0.strategy == strat && $0.scenario == scen }
                let collapses = cell.filter { $0.outcome == .collapse }.count
                let reform = cell.filter { $0.tReformReached != nil }.count
                let loop = cell.filter { $0.tLoopReached != nil }.count
                let stag = cell.filter { $0.outcome == .stagnated }.count
                md.append("| \(strat.rawValue) | \(scen.rawValue) | \(collapses) | \(reform) | \(loop) | \(stag) | \(fmt(median(cell.compactMap { $0.tCollapse }))) | \(fmt(median(cell.map { Double($0.packages) }))) | \(money(median(cell.map { $0.lifetimeMoney }))) |")
            }
        }
        md.append("")

        md.append("## Pacing (medians, seconds of active play)")
        md.append("")
        md.append("| Strategy | Scenario | 1st upgrade | 1st idle income | 100 pkg | 500 pkg | 1500 pkg | \\$1000 |")
        md.append("|---|---|---|---|---|---|---|---|")
        for strat in Strategy.allCases {
            for scen in Scenario.allCases {
                let cell = results.filter { $0.strategy == strat && $0.scenario == scen }
                func med(_ kp: (RunResult) -> Double?) -> String { fmt(median(cell.compactMap(kp))) }
                md.append("| \(strat.rawValue) | \(scen.rawValue) | \(med{$0.tFirstUpgrade}) | \(med{$0.tFirstAutomationIncome}) | \(med{$0.tFirst100Pkgs}) | \(med{$0.tFirst500Pkgs}) | \(med{$0.tFirst1500Pkgs}) | \(med{$0.tFirst1000Dollars}) |")
            }
        }
        md.append("")

        md.append("## Fresh-install economy diagnostic")
        md.append("")
        let fresh = results.filter { $0.scenario == .freshInstall }
        let freshIdle = fresh.compactMap { $0.idleIncomeAfterEnablersAt60s }
        md.append("- A brand-new install never calls `reset()`, so it keeps `GameState()` defaults: **0 workers, `baseWorkerRate = 0.0`**.")
        md.append("- Median fresh-install idle income at 60s: **\(String(format: "$%.3f/s", median(freshIdle)))**.")
        md.append("- Fresh median time-to-first-idle-income: **\(fmt(median(fresh.compactMap{$0.tFirstAutomationIncome})))s** vs restarted **\(fmt(median(results.filter{$0.scenario == .restarted}.compactMap{$0.tFirstAutomationIncome})))s**.")
        md.append("")

        md.append("## Events fired across all games")
        md.append("")
        var eventCounts: [String: Int] = [:]
        var choiceCounts: [String: Int] = [:]
        var totalEvents = 0
        for r in results {
            for e in r.events {
                eventCounts[e.title, default: 0] += 1
                choiceCounts["\(e.title) → \(e.choice)", default: 0] += 1
                totalEvents += 1
            }
        }
        md.append("Total events fired: **\(totalEvents)** (avg \(String(format: "%.1f", Double(totalEvents)/Double(max(results.count,1))))/game).")
        md.append("")
        md.append("| Event | Times fired |")
        md.append("|---|---|")
        for (title, c) in eventCounts.sorted(by: { $0.value > $1.value }) { md.append("| \(title) | \(c) |") }
        md.append("")
        md.append("### Most common choices")
        md.append("")
        md.append("| Event → Choice | Count |")
        md.append("|---|---|")
        for (k, c) in choiceCounts.sorted(by: { $0.value > $1.value }).prefix(15) { md.append("| \(k) | \(c) |") }
        md.append("")

        md.append("## Sample transcripts (restarted scenario)")
        md.append("")
        for strat in Strategy.allCases {
            if let s = results.first(where: { $0.strategy == strat && $0.scenario == .restarted }) {
                md.append("### \(strat.rawValue)")
                md.append("")
                md.append("- Outcome: **\(s.outcome.rawValue)** at \(fmt(s.endSimTime))s")
                md.append("- Final: \(s.packages) pkgs, \(money(s.money)) cash, \(money(s.lifetimeMoney)) lifetime, \(s.workers) workers, ethics \(String(format: "%.1f", s.ethics)), perception \(String(format: "%.0f", s.perception)), env \(String(format: "%.0f", s.environmental))")
                md.append("- Upgrades (\(s.upgradesBought)): \(s.purchases.isEmpty ? "none" : s.purchases.prefix(40).joined(separator: ", "))")
                if !s.events.isEmpty {
                    md.append("- Events:")
                    for e in s.events.prefix(12) {
                        md.append("    - t=\(fmt(e.time))s — *\(e.title)* → \(e.choice) (moral \(String(format: "%.0f", e.moral)))")
                    }
                }
                md.append("")
            }
        }
        return md.joined(separator: "\n")
    }

    func json(_ results: [RunResult]) -> String {
        func s(_ x: Double?) -> String { x == nil ? "null" : String(format: "%.3f", x!) }
        var objs: [String] = []
        for r in results {
            let purchases = r.purchases.map { "\"\($0.replacingOccurrences(of: "\"", with: ""))\"" }.joined(separator: ",")
            let events = r.events.map {
                "{\"t\":\(String(format: "%.0f", $0.time)),\"title\":\"\($0.title)\",\"choice\":\"\($0.choice.replacingOccurrences(of: "\"", with: "'"))\",\"moral\":\($0.moral)}"
            }.joined(separator: ",")
            objs.append("{\"strategy\":\"\(r.strategy.rawValue)\",\"scenario\":\"\(r.scenario.rawValue)\",\"outcome\":\"\(r.outcome.rawValue)\",\"endSimTime\":\(s(r.endSimTime)),\"tFirstUpgrade\":\(s(r.tFirstUpgrade)),\"tFirstAutomationIncome\":\(s(r.tFirstAutomationIncome)),\"t100\":\(s(r.tFirst100Pkgs)),\"t500\":\(s(r.tFirst500Pkgs)),\"t1500\":\(s(r.tFirst1500Pkgs)),\"t1000usd\":\(s(r.tFirst1000Dollars)),\"tReform\":\(s(r.tReformReached)),\"tLoop\":\(s(r.tLoopReached)),\"tCollapse\":\(s(r.tCollapse)),\"packages\":\(r.packages),\"money\":\(String(format: "%.2f", r.money)),\"lifetime\":\(String(format: "%.2f", r.lifetimeMoney)),\"workers\":\(r.workers),\"ethics\":\(String(format: "%.1f", r.ethics)),\"automationLevel\":\(r.automationLevel),\"perception\":\(String(format: "%.0f", r.perception)),\"environmental\":\(String(format: "%.0f", r.environmental)),\"morale\":\(String(format: "%.2f", r.morale)),\"taps\":\(r.taps),\"upgradesBought\":\(r.upgradesBought),\"purchases\":[\(purchases)],\"events\":[\(events)]}")
        }
        return "[\n" + objs.joined(separator: ",\n") + "\n]\n"
    }
}
