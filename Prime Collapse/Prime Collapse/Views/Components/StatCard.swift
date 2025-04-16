import SwiftUI

// Card for displaying a statistic
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    var secondaryText: String? = nil
    var iconColor: Color = .blue
    var valueColor: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .bold))
                    .shadow(color: iconColor.opacity(0.5), radius: 2, x: 0, y: 1)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(valueColor ?? .white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let secondaryText = secondaryText {
                Text(secondaryText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
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
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
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
        }
        .padding()
    }
} 
