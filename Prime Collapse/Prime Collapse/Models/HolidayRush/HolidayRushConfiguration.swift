import Foundation

struct HolidayRushConfiguration: Codable, Equatable {
    var start: Date? = nil
    var end: Date? = nil

    var hasEventWindow: Bool {
        guard let start, let end else { return false }
        return start < end && end.timeIntervalSince(start) <= 31 * 24 * 60 * 60
    }

    func contains(_ date: Date) -> Bool {
        guard hasEventWindow, let start, let end else { return false }
        return date >= start && date < end
    }

    static var bundled: Self {
        guard let url = Bundle.main.url(forResource: "HolidayRushWindow", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return .init() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(Self.self, from: data)) ?? .init()
    }
}
