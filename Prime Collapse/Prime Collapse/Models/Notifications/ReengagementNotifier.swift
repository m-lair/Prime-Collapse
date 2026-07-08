//
//  ReengagementNotifier.swift
//  Prime Collapse
//
//  Local re-engagement notifications. When the player leaves with an active
//  workforce, a reminder is scheduled for the moment offline earnings hit the
//  8-hour catch-up cap (GameState.maxAutomationCatchUp) — the point where staying
//  away stops paying. Returning to the app cancels it.
//
//  Permission is requested once, at an engaged moment (first upgrade purchase),
//  never at launch.
//

import Foundation
import UserNotifications

/// Thin seam over UNUserNotificationCenter so scheduling logic is unit-testable.
protocol NotificationScheduling {
    func requestAuthorization() async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removeAllPendingRequests()
}

extension UNUserNotificationCenter: NotificationScheduling {
    func requestAuthorization() async throws -> Bool {
        try await requestAuthorization(options: [.alert, .sound, .badge])
    }

    func removeAllPendingRequests() {
        removeAllPendingNotificationRequests()
    }
}

@MainActor
final class ReengagementNotifier {
    static let offlineCapNotificationID = "offline-earnings-cap"
    private static let authRequestedKey = "reengagementAuthorizationRequested"

    private let center: NotificationScheduling
    private let defaults: UserDefaults

    init(center: NotificationScheduling = UNUserNotificationCenter.current(),
         defaults: UserDefaults? = nil) {
        self.center = center
        self.defaults = defaults ?? .standard
    }

    /// Ask for notification permission the first time this is called; no-ops after.
    /// Call at an engaged moment (e.g. the first upgrade purchase).
    func requestAuthorizationIfNeeded() async {
        guard !defaults.bool(forKey: Self.authRequestedKey) else { return }
        defaults.set(true, forKey: Self.authRequestedKey)
        _ = try? await center.requestAuthorization()
    }

    /// Schedule the "offline earnings are capped" reminder. Call when the app is
    /// backgrounded; harmless if permission was never granted (delivery is skipped
    /// by the system).
    func scheduleOfflineEarningsCapReminder(workers: Int) async {
        guard workers > 0 else { return } // no workforce, no offline earnings

        let content = UNMutableNotificationContent()
        content.title = "Your warehouse has gone quiet"
        content.body = workers == 1
            ? "Offline earnings just hit the 8-hour cap. Your worker is standing around — come put them back to work."
            : "Offline earnings just hit the 8-hour cap. Your \(workers) workers are standing around — come put them back to work."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: GameState.maxAutomationCatchUp,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.offlineCapNotificationID,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Cancel any scheduled reminder. Call when the app returns to the foreground.
    func cancelPendingReminders() {
        center.removeAllPendingRequests()
    }
}
