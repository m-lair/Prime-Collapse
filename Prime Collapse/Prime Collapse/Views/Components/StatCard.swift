import SwiftUI

// Card for displaying a statistic
struct StatCard: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let icon: String
    let title: String
    let value: String
    var secondaryText: String? = nil
    var iconColor: Color = .blue
    var valueColor: Color? = nil
    var isHighlightSecondary: Bool = false // Highlight secondary text for emphasis
    var secondaryTextColor: Color? = nil
    
    var minimumContentHeight: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .bold))
                    .shadow(color: iconColor.opacity(0.5), radius: 2, x: 0, y: 1)
                
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
            }
            
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(valueColor ?? .white)
                .lineLimit(textSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(0.8)
            
            if let secondaryText = secondaryText {
                Text(secondaryText)
                    .font(.caption2.weight(isHighlightSecondary ? .bold : .medium))
                    .foregroundColor(secondaryTextColor ?? (isHighlightSecondary ? .orange : .white.opacity(0.7)))
                    .lineLimit(textSize.isAccessibilitySize ? nil : 1)
                    .minimumScaleFactor(0.8)
                    .padding(.vertical, isHighlightSecondary ? 2 : 0)
                    .padding(.horizontal, isHighlightSecondary ? 4 : 0)
                    .background(
                        isHighlightSecondary ?
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange.opacity(0.2))
                            : nil
                    )
            }
        }
        .frame(maxWidth: .infinity, minHeight: minimumContentHeight, alignment: .topLeading)
        .padding(12)
        .background(
            ZStack {
                // Base shape
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    iconColor.opacity(0.2),
                                    Color.clear
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    iconColor.opacity(0.7),
                                    iconColor.opacity(0.3)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .accessibilityElement(children: .combine)
    }
}

// Extension to create an animated StatCard for changing values
extension StatCard {
    func animatedValue(isChanging: Bool) -> some View {
        self.modifier(AnimatedValueModifier(isChanging: isChanging))
    }
}

// Modifier to add animation to values that are changing
struct AnimatedValueModifier: ViewModifier {
    let isChanging: Bool
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .onChange(of: isChanging) { _, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isAnimating = true
                    }
                    
                    // Reset after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            isAnimating = false
                        }
                    }
                }
            }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.5).ignoresSafeArea()
        VStack(spacing: 20) {
            StatCard(
                icon: "shippingbox.fill",
                title: "Packages",
                value: "143", 
                secondaryText: "$1.25 per package",
                iconColor: .yellow
            )
            
            StatCard(
                icon: "dollarsign.circle.fill",
                title: "Money",
                value: "$1,250.75",
                iconColor: .green, valueColor: .green
            )
            
            StatCard(
                icon: "gauge.medium",
                title: "Worker Efficiency",
                value: "1.75×",
                secondaryText: "High Productivity",
                iconColor: .indigo
            )
            
            StatCard(
                icon: "person.fill",
                title: "Workers",
                value: "40",
                secondaryText: "44.56 → 8.91/sec",
                iconColor: .blue,
                isHighlightSecondary: true
            )
        }
        .padding()
    }
} 
