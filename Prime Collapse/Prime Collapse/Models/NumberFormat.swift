import Foundation

// Compact number display for idle-game scale values.
enum NumberFormat {
    private static let suffixes = ["", "K", "M", "B", "T", "Qa", "Qi"]

    /// Full precision under 1,000, then three significant digits with a suffix: "1.23K", "45.6M", "789B".
    static func short(_ value: Double, decimalsBelowThousand: Int = 0) -> String {
        guard value.isFinite else { return "0" }
        let sign = value < 0 ? "-" : ""
        var magnitude = abs(value)

        let small = rounded(magnitude, decimals: decimalsBelowThousand)
        if small < 1000 {
            return sign + String(format: "%.\(decimalsBelowThousand)f", small)
        }

        var tier = 0
        while magnitude >= 1000 && tier < suffixes.count - 1 {
            magnitude /= 1000
            tier += 1
        }

        var decimals = significantDecimals(for: magnitude)
        var display = rounded(magnitude, decimals: decimals)
        if display >= 1000 && tier < suffixes.count - 1 {
            // Rounding carried into the next tier: 999.95K → 1.00M.
            tier += 1
            decimals = 2
            display = rounded(magnitude / 1000, decimals: decimals)
        } else if significantDecimals(for: display) < decimals {
            // Rounding carried into the next digit: 9.996K → 10.0K, not 10.00K.
            decimals = significantDecimals(for: display)
            display = rounded(magnitude, decimals: decimals)
        }
        return sign + String(format: "%.\(decimals)f", display) + suffixes[tier]
    }

    private static func significantDecimals(for value: Double) -> Int {
        value < 10 ? 2 : value < 100 ? 1 : 0
    }

    private static func rounded(_ value: Double, decimals: Int) -> Double {
        let factor = pow(10, Double(decimals))
        return (value * factor).rounded() / factor
    }
}

extension Double {
    /// "$12.50" under $1,000, then "$1.23K", "$45.6M"…
    var shortCurrency: String {
        let body = NumberFormat.short(self, decimalsBelowThousand: 2)
        return body.hasPrefix("-") ? "-$" + body.dropFirst() : "$" + body
    }
}

extension Int {
    /// "999", then "1.00K", "12.3K"…
    var shortCount: String { NumberFormat.short(Double(self)) }
}
