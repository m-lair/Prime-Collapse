import SwiftUI

/// A physical dispatch key, shared by play and navigation actions.
struct GameActionStyle: ButtonStyle {
    var prominent = true
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(prominent && isEnabled ? GamePalette.ink : GamePalette.label)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? (prominent ? GamePalette.orange : GamePalette.floor) : GamePalette.floor)
                    .shadow(color: .black.opacity(0.25), radius: 0, y: configuration.isPressed ? 0 : 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(GamePalette.label.opacity(prominent ? 0.18 : 0.25), lineWidth: 1)
            }
            .offset(y: configuration.isPressed && !reduceMotion ? 3 : 0)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
