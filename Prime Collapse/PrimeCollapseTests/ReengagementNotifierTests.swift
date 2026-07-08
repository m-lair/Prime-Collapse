//
//  ReengagementNotifierTests.swift
//  PrimeCollapseTests
//
//  The re-engagement notifier schedules a local notification for the moment offline
//  earnings hit their cap, cancels it when the player returns, and asks for permission
//  exactly once. Tested through a spy seam so no real UNUserNotificationCenter is hit.
//

import XCTest
import UserNotifications
@testable import Prime_Collapse

private final class SpyScheduler: NotificationScheduling {
    var added: [UNNotificationRequest] = []
    var removeAllCount = 0
    var authorizationRequests = 0
    var authorizationGranted = true

    func requestAuthorization() async throws -> Bool {
        authorizationRequests += 1
        return authorizationGranted
    }

    func add(_ request: UNNotificationRequest) async throws {
        added.append(request)
    }

    func removeAllPendingRequests() {
        removeAllCount += 1
    }
}

@MainActor
final class ReengagementNotifierTests: XCTestCase {

    private var spy: SpyScheduler!
    private var defaults: UserDefaults!
    private var notifier: ReengagementNotifier!

    override func setUp() async throws {
        spy = SpyScheduler()
        let suiteName = "ReengagementNotifierTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        notifier = ReengagementNotifier(center: spy, defaults: defaults)
    }

    func testSchedulesOfflineCapReminderAtCatchUpLimit() async {
        await notifier.scheduleOfflineEarningsCapReminder(workers: 3)

        XCTAssertEqual(spy.added.count, 1)
        let request = spy.added[0]
        XCTAssertEqual(request.identifier, ReengagementNotifier.offlineCapNotificationID)
        let trigger = request.trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertEqual(trigger?.timeInterval, GameState.maxAutomationCatchUp,
                       "reminder must fire exactly when offline earnings stop accruing")
        XCTAssertFalse(trigger?.repeats ?? true)
    }

    func testDoesNotScheduleWithoutWorkers() async {
        await notifier.scheduleOfflineEarningsCapReminder(workers: 0)

        XCTAssertTrue(spy.added.isEmpty,
                      "no workforce means no offline earnings — nothing to announce")
    }

    func testCancelRemovesPendingReminders() {
        notifier.cancelPendingReminders()

        XCTAssertEqual(spy.removeAllCount, 1)
    }

    func testAuthorizationIsRequestedExactlyOnce() async {
        await notifier.requestAuthorizationIfNeeded()
        await notifier.requestAuthorizationIfNeeded()

        XCTAssertEqual(spy.authorizationRequests, 1,
                       "the permission prompt must never be re-triggered")
    }

    func testAuthorizationOnceFlagPersistsAcrossInstances() async {
        await notifier.requestAuthorizationIfNeeded()

        let second = ReengagementNotifier(center: spy, defaults: defaults)
        await second.requestAuthorizationIfNeeded()

        XCTAssertEqual(spy.authorizationRequests, 1)
    }
}
