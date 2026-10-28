import Foundation

enum HolidayRushRoute {
    static func matches(_ url: URL) -> Bool {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        return parts.scheme?.lowercased() == "primecollapse" &&
            parts.host?.lowercased() == "events" && parts.percentEncodedPath == "/holiday-rush" &&
            parts.user == nil && parts.password == nil && parts.port == nil &&
            parts.query == nil && parts.fragment == nil
    }
}
