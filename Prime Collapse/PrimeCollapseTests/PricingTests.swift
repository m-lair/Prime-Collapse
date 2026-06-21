//
//  PricingTests.swift
//  PrimeCollapseTests
//
//  The upgrade price scaling must never produce inf/NaN or exceed its caps, even at
//  absurd purchase counts.
//

import XCTest
@testable import Prime_Collapse

final class PricingTests: XCTestCase {

    func testSafeCalculatePriceStaysFiniteAndCapped() {
        let gs = GameState()
        for count in [0, 1, 10, 50, 100, 1000, 10_000] {
            let price = gs.safeCalculatePrice(basePrice: 50, timesPurchased: count, scalingFactor: 1.6)
            XCTAssertTrue(price.isFinite, "price was not finite at count \(count)")
            XCTAssertGreaterThanOrEqual(price, 50)
            XCTAssertLessThanOrEqual(price, 1_000_000_000.0, "price exceeded cap at count \(count)")
        }
    }

    func testSafeCalculateWorkerPriceStaysFiniteAndCapped() {
        let gs = GameState()
        for count in [0, 1, 20, 50, 100, 1000, 10_000] {
            let price = gs.safeCalculateWorkerPrice(basePrice: 50, workerCount: count, scalingFactor: 1.4)
            XCTAssertTrue(price.isFinite, "worker price was not finite at count \(count)")
            XCTAssertLessThanOrEqual(price, 1_000_000.0, "worker price exceeded cap at count \(count)")
        }
    }

    func testUpgradeManagerCalculatePriceStaysFinite() {
        for count in [0, 1, 50, 51, 1000, 10_000] {
            let price = UpgradeManager.calculatePrice(basePrice: 50, timesPurchased: count, scalingFactor: 1.6)
            XCTAssertTrue(price.isFinite, "calculatePrice was not finite at count \(count)")
            XCTAssertGreaterThanOrEqual(price, 50)
        }
    }

    func testNonPositiveScalingFactorDoesNotCrash() {
        let price = UpgradeManager.calculatePrice(basePrice: 50, timesPurchased: 5, scalingFactor: 0)
        XCTAssertEqual(price, 50)
    }
}
