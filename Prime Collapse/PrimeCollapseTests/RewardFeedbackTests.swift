//
//  RewardFeedbackTests.swift
//  PrimeCollapseTests
//
//  Compact number display and milestone detection used by the reward feedback.
//

import XCTest
@testable import Prime_Collapse

final class RewardFeedbackTests: XCTestCase {

    func testShortCurrencyKeepsCentsUnderOneThousand() {
        XCTAssertEqual(0.0.shortCurrency, "$0.00")
        XCTAssertEqual(12.5.shortCurrency, "$12.50")
        XCTAssertEqual(999.994.shortCurrency, "$999.99")
    }

    func testShortCurrencyAbbreviatesWithThreeSignificantDigits() {
        XCTAssertEqual(1_234.0.shortCurrency, "$1.23K")
        XCTAssertEqual(12_345.0.shortCurrency, "$12.3K")
        XCTAssertEqual(123_456.0.shortCurrency, "$123K")
        XCTAssertEqual(1_500_000_000.0.shortCurrency, "$1.50B")
    }

    func testRoundingCarriesIntoTheNextUnitOrDigit() {
        XCTAssertEqual(999.996.shortCurrency, "$1.00K")
        XCTAssertEqual(999_950.0.shortCurrency, "$1.00M")
        XCTAssertEqual(9_996.0.shortCurrency, "$10.0K")
        XCTAssertEqual(99_960.0.shortCurrency, "$100K")
    }

    func testShortCountAndNonFiniteValues() {
        XCTAssertEqual(999.shortCount, "999")
        XCTAssertEqual(1_000.shortCount, "1.00K")
        XCTAssertEqual((-2_500.0).shortCurrency, "-$2.50K")
        XCTAssertEqual(NumberFormat.short(.nan), "0")
        XCTAssertEqual(NumberFormat.short(.infinity), "0")
    }

    func testMilestoneFiresOnlyWhenATierIsCrossed() {
        let tiers = Milestone.lifetimeEarningsTiers
        XCTAssertEqual(Milestone.highestTierCrossed(in: tiers, old: 99, new: 100), 100)
        XCTAssertNil(Milestone.highestTierCrossed(in: tiers, old: 100, new: 150))
        XCTAssertNil(Milestone.highestTierCrossed(in: tiers, old: 500, new: 400))
    }

    func testCatchUpJumpCelebratesOnlyTheHighestTier() {
        XCTAssertEqual(Milestone.highestTierCrossed(in: Milestone.lifetimeEarningsTiers, old: 50, new: 25_000), 10_000)
        XCTAssertEqual(Milestone.highestTierCrossed(in: Milestone.packageTiers, old: 0, new: 1_200), 1_000)
    }
}
