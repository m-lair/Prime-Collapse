import Foundation

struct HolidayRushUpgradePreview {
    let automaticRateBefore: Double
    let automaticRateAfter: Double
    let packageValueBefore: Double
    let packageValueAfter: Double
    let netCost: Double
    let ethicsAfter: Double
    let moraleAfter: Double

    var paybackSeconds: Double? {
        if netCost <= 0 { return 0 }
        let extraIncome = automaticRateAfter * packageValueAfter - automaticRateBefore * packageValueBefore
        guard extraIncome.isFinite, extraIncome > 0 else { return nil }
        let seconds = netCost / extraIncome
        return seconds.isFinite ? seconds : nil
    }
}
