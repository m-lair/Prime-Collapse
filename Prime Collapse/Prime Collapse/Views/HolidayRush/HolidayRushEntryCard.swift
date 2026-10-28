import SwiftUI

struct HolidayRushEntryCard: View {
    @Environment(\.dynamicTypeSize) private var textSize
    var subtitle = "Free challenge · Beat the rush. Protect your team."
    var actionTitle: String? = nil
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                if !textSize.isAccessibilitySize {
                    Image(systemName: "snowflake")
                        .font(.title2)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Holiday Rush")
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                    if let actionTitle {
                        Text(actionTitle).font(.subheadline.weight(.semibold)).padding(.top, 8)
                    }
                }
                Spacer(minLength: 0)
                if !textSize.isAccessibilitySize {
                    Image(systemName: "chevron.right")
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(.white)
            .padding(18)
            .background(.blue.opacity(0.25), in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.25)))
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityIdentifier("holidayRushEntry")
        .accessibilityHint("Opens a separate challenge. Your company is preserved.")
    }
}
