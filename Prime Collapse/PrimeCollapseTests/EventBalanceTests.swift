//
//  EventBalanceTests.swift
//  PrimeCollapseTests
//
//  Guards the core tension of every random event: the shortcut pays now, the decent option
//  costs now. Regression for "Competitor Undercuts Prices", where the ethical choice was free
//  and the unethical ones cost money with no upside.
//

import XCTest
@testable import Prime_Collapse

final class EventBalanceTests: XCTestCase {

    private var events: [GameEvent] { EventManager().allEventsForTesting }

    /// ~300 packages in: one worker, a little cash, mostly tap income.
    private func earlyGame() -> GameState {
        let state = GameState()
        state.reset()
        state.totalPackagesShipped = 300
        state.lifetimeTotalMoneyEarned = 300
        state.money = 150
        return state
    }

    /// Late game: real automation and a healthy balance.
    private func lateGame() -> GameState {
        let state = GameState()
        state.reset()
        state.totalPackagesShipped = 3000
        state.workers = 20
        state.baseWorkerRate = 0.15
        state.workerEfficiency = 1.2
        state.baseSystemRate = 2.0
        state.packageValue = 2.5
        state.lifetimeTotalMoneyEarned = 60_000
        state.money = 8_000
        return state
    }

    /// Just spent everything on an upgrade.
    private func broke() -> GameState {
        let state = earlyGame()
        state.money = 0
        return state
    }

    /// Big balance, barely any automation — the case where "+$300 to sell the company" vs
    /// "-$13K to protect workers" made greed pointless.
    private func hoarder() -> GameState {
        let state = earlyGame()
        state.money = 42_000
        state.lifetimeTotalMoneyEarned = 42_000
        return state
    }

    private var fixtures: [(name: String, make: () -> GameState)] {
        [("early", earlyGame), ("late", lateGame), ("broke", broke), ("hoarder", hoarder)]
    }

    func testShortcutOutpaysTheDecentOptionsBillWhenRich() {
        for event in events {
            let state = hoarder()
            let ranked = byMorality(event)
            let payout = ranked.first!.cash!.amount(in: state)
            let bill = -(ranked.last!.cash?.signedAmount(in: state) ?? 0)
            XCTAssertGreaterThan(payout, bill, event.title)
        }
    }

    private func byMorality(_ event: GameEvent) -> [EventChoice] {
        event.choices.sorted { $0.moralImpact < $1.moralImpact }
    }

    func testCatalogIsNotEmpty() {
        XCTAssertEqual(events.count, 17)
        for event in events {
            XCTAssertGreaterThanOrEqual(event.choices.count, 2, event.title)
            XCTAssertEqual(Set(event.choices.map(\.moralImpact)).count, event.choices.count,
                           "\(event.title): choices need distinct moral impacts to rank them")
        }
    }

    func testMostUnethicalChoicePaysStrictlyMoreThanMostEthical() {
        for (name, make) in fixtures {
            for event in events {
                let state = make()
                let ranked = byMorality(event)
                let greedy = ranked.first!.projectedMoney(in: state)
                let decent = ranked.last!.projectedMoney(in: state)
                XCTAssertGreaterThan(greedy, decent, "\(event.title) [\(name)]")
            }
        }
    }

    func testMostUnethicalChoicePaysMeaningfulCashNow() {
        for (name, make) in fixtures {
            for event in events {
                let state = make()
                let greedy = byMorality(event).first!
                XCTAssertEqual(greedy.cash?.direction, .gain, "\(event.title): shortcut should pay cash")
                XCTAssertGreaterThanOrEqual(greedy.projectedMoney(in: state), 25, "\(event.title) [\(name)]")
            }
        }
    }

    func testMoneyNeverRisesAsChoicesGetMoreEthical() {
        for (name, make) in fixtures {
            for event in events {
                let state = make()
                let money = byMorality(event).map { $0.projectedMoney(in: state) }
                for (less, more) in zip(money, money.dropFirst()) {
                    XCTAssertGreaterThanOrEqual(less, more, "\(event.title) [\(name)]: \(money)")
                }
            }
        }
    }

    func testEthicalChoicesAlwaysCostSomething() {
        for (name, make) in fixtures {
            for event in events {
                for choice in event.choices where choice.moralImpact > 0 {
                    XCTAssertLessThan(choice.projectedMoney(in: make()), 0,
                                      "\(event.title) / \(choice.text) [\(name)] is free")
                }
            }
        }
    }

    func testCostsNeverLockAChoice() {
        let state = earlyGame()
        state.money = 3
        for event in events {
            for choice in event.choices {
                XCTAssertTrue(choice.canChoose?(state) ?? true, "\(event.title) / \(choice.text)")
                if let cash = choice.cash, cash.direction == .cost {
                    XCTAssertLessThanOrEqual(cash.amount(in: state), state.money)
                }
            }
        }
    }

    /// Money may only move through declared stakes, so the sheet and these tests see all of it.
    func testEffectClosuresNeverTouchMoney() {
        for event in events {
            for choice in event.choices {
                let state = lateGame()
                choice.effect(state)
                choice.fallout?.consequences(state)
                XCTAssertEqual(state.money, 8_000, "\(event.title) / \(choice.text)")
                XCTAssertEqual(state.lifetimeTotalMoneyEarned, 60_000, "\(event.title) / \(choice.text)")
            }
        }
    }

    func testCompetitorUndercutRegression() throws {
        let manager = EventManager()
        let event = try XCTUnwrap(manager.allEventsForTesting.first { $0.title == "Competitor Undercuts Prices" })
        let rumors = try XCTUnwrap(event.choices.first { $0.text.contains("rumors") })
        let quality = try XCTUnwrap(event.choices.first { $0.text.contains("quality over price") })

        let state = earlyGame()
        let expected = rumors.cash!.amount(in: state)
        manager.presentForTesting(titled: event.title)
        manager.processChoice(choice: rumors, gameState: state)

        XCTAssertEqual(state.money, 150 + expected, accuracy: 0.001)
        XCTAssertFalse(state.pendingEffects.isEmpty, "the bill for the rumors should be scheduled")
        XCTAssertLessThan(state.ethicsScore, 100)
        XCTAssertLessThan(quality.projectedMoney(in: earlyGame()), 0)
    }

    func testEthicalChoiceChargesAndShiftsIncome() throws {
        let manager = EventManager()
        let event = try XCTUnwrap(manager.allEventsForTesting.first { $0.title == "Market Boom" })
        let stable = try XCTUnwrap(byMorality(event).last)

        let state = lateGame()
        let cost = stable.cash!.amount(in: state)
        manager.presentForTesting(titled: event.title)
        manager.processChoice(choice: stable, gameState: state)

        XCTAssertEqual(state.money, 8_000 - cost, accuracy: 0.001)
        XCTAssertEqual(state.incomeModifiers.count, 1)
        XCTAssertLessThan(state.incomeMultiplier(from: Date(), to: Date()), 1.0)
    }

    func testFalloutLandsAfterItsDelay() {
        let manager = EventManager()
        let state = lateGame()
        let start = Date()
        state.lastUpdate = start
        let fine = EventStakes.fine.sizedAmount(in: state)
        let choice = EventChoice(
            text: "Shortcut",
            moralImpact: -5,
            fallout: Fallout(delay: 45, fine: EventStakes.fine,
                             consequences: { $0.publicPerception -= 10 })
        )

        manager.processChoice(choice: choice, gameState: state, now: start)
        state.processAutomation(currentTime: start.addingTimeInterval(30))
        XCTAssertEqual(state.publicPerception, 50, "nothing lands before the delay")

        let before = state.money
        let earned = state.baseIncomePerSecond * 16 // before the perception hit lowers income
        state.processAutomation(currentTime: start.addingTimeInterval(46))
        XCTAssertEqual(state.publicPerception, 40)
        XCTAssertEqual(state.money, before + earned - fine, accuracy: state.valuePerPackage * 2)
        XCTAssertTrue(state.pendingEffects.isEmpty)
    }

    func testIncomeModifierIsProratedAcrossLongTicks() {
        let state = GameState()
        let start = Date()
        state.applyIncomeShift(IncomeShift(bonus: 1.0, duration: 60), at: start)

        XCTAssertEqual(state.incomeMultiplier(from: start, to: start.addingTimeInterval(30)), 2.0, accuracy: 0.0001)
        // An 8-hour catch-up tick only gets 60 seconds of the boost.
        XCTAssertEqual(state.incomeMultiplier(from: start, to: start.addingTimeInterval(3600)),
                       1.0 + 60.0 / 3600.0, accuracy: 0.0001)
        XCTAssertEqual(state.incomeMultiplier(from: start.addingTimeInterval(61), to: start.addingTimeInterval(61)), 1.0)
    }

    func testIncomeModifierAppliesToAutomationAndExpires() {
        let state = lateGame()
        let start = Date()
        state.lastUpdate = start
        state.applyIncomeShift(IncomeShift(bonus: 1.0, duration: 60), at: start)

        state.processAutomation(currentTime: start.addingTimeInterval(10))
        let boosted = state.money - 8_000
        XCTAssertEqual(state.incomeModifiers.count, 1)

        state.processAutomation(currentTime: start.addingTimeInterval(70))
        XCTAssertTrue(state.incomeModifiers.isEmpty)
        // 10s at double speed earns about as much as 20s at base rate.
        XCTAssertEqual(boosted, state.baseIncomePerSecond * 20, accuracy: state.valuePerPackage * 2)
    }

    // MARK: Reform ending

    /// The run from a player report: Reform fired at 2,227 packages after five cheap good deeds.
    func testReformDoesNotFireOnAnEarlyRun() {
        let state = GameState()
        state.reset()
        state.totalPackagesShipped = 2_227
        state.lifetimeTotalMoneyEarned = 2_569
        state.workers = 9
        state.ethicalChoicesMade = 5
        state.ethicsScore = 100
        state.money = 1_500

        state.checkForReformEnding()

        XCTAssertFalse(state.endingReached)
        XCTAssertNotEqual(state.endingType, .reform)
    }

    func testReformNeedsEveryRequirement() {
        let shortfalls: [(String, (GameState) -> Void)] = [
            ("choices", { $0.ethicalChoicesMade -= 1 }),
            ("ethics", { $0.ethicsScore -= 1 }),
            ("lifetime", { $0.lifetimeTotalMoneyEarned -= 1 }),
        ]
        for (name, fallShort) in shortfalls {
            let state = GameState()
            state.ethicalChoicesMade = GameState.reformEthicalChoices
            state.ethicsScore = GameState.reformEthicsScore
            state.lifetimeTotalMoneyEarned = GameState.reformLifetimeEarnings
            fallShort(state)

            state.checkForReformEnding()

            XCTAssertFalse(state.endingReached, "short on \(name)")
        }
    }

    /// Events go through the same gate as upgrades and ticks, and actually end the game.
    func testEthicalEventChoiceCanCompleteReform() throws {
        let manager = EventManager()
        let event = try XCTUnwrap(manager.allEventsForTesting.first { $0.title == "Market Boom" })
        let stable = try XCTUnwrap(byMorality(event).last)

        let state = lateGame()
        state.lifetimeTotalMoneyEarned = GameState.reformLifetimeEarnings
        state.ethicalChoicesMade = GameState.reformEthicalChoices - 1
        manager.presentForTesting(titled: event.title)
        manager.processChoice(choice: stable, gameState: state)

        XCTAssertTrue(state.endingReached)
        XCTAssertEqual(state.endingType, .reform)
    }

    func testResetClearsPendingEffectsAndModifiers() {
        let state = lateGame()
        state.applyIncomeShift(IncomeShift(bonus: 0.5, duration: 60))
        state.scheduleEffect(after: 30) { $0.money -= 1_000 }

        state.reset()

        XCTAssertTrue(state.pendingEffects.isEmpty)
        XCTAssertTrue(state.incomeModifiers.isEmpty)
    }
}
