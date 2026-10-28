import SwiftUI

struct HolidayRushEntryCard: View {
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                Image(systemName: "snowflake")
                    .font(.title2)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Holiday Rush")
                        .font(.headline)
                    Text("Free challenge · Beat the rush. Protect your team.")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .foregroundStyle(.white)
            .padding(12)
            .background(.blue.opacity(0.25), in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.25)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("holidayRushEntry")
        .accessibilityHint("Opens a separate challenge. Your company is preserved.")
    }
}
