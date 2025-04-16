import SwiftUI

// Dashboard stat card
struct DashboardStatCard: View {
    let icon: String
    let title: String
    let value: String
    var secondaryText: String? = nil
    var iconColor: Color = .blue
    var valueColor: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(
                        ZStack {
                            Circle()
                                .fill(iconColor.opacity(0.3))
                            
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(
                                            colors: [
                                                iconColor.opacity(0.8),
                                                iconColor.opacity(0.4)
                                            ]
                                        ),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    )
                    .shadow(color: iconColor.opacity(0.5), radius: 3, x: 0, y: 2)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Value
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(valueColor ?? .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if let secondaryText = secondaryText {
                    Text(secondaryText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            ZStack {
                // Base shape
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    iconColor.opacity(0.1),
                                    Color.clear
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    iconColor.opacity(0.5),
                                    iconColor.opacity(0.1)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        VStack(spacing: 20) {
            DashboardStatCard(
                icon: "shippingbox.fill",
                title: "Total Packages",
                value: "523",
                secondaryText: "45% increase this week",
                iconColor: .yellow
            )
            
            DashboardStatCard(
                icon: "dollarsign.circle.fill",
                title: "Current Money",
                value: "$1,250.00",
                iconColor: .green, valueColor: .green
            )
            
            DashboardStatCard(
                icon: "person.3.fill",
                title: "Workforce",
                value: "12 Workers",
                secondaryText: "Efficiency: 1.75×",
                iconColor: .blue
            )
        }
        .padding()
    }
} 
