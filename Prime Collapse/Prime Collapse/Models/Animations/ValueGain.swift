import SwiftUI

// "+$X" floater rising from the ship button
struct ValueGain: Identifiable {
    let id = UUID()
    let amount: Double
    let startTime = Date()
    let xJitter = CGFloat.random(in: -36...36)
    static let duration: Double = 1.0

    func progress(at date: Date) -> Double {
        min(1, date.timeIntervalSince(startTime) / Self.duration)
    }

    func isActive(at date: Date) -> Bool {
        date.timeIntervalSince(startTime) < Self.duration
    }
}
