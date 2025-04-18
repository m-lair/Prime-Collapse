import SwiftUI

// Dashboard stat card
struct DashboardStatCard: View {
    let icon: String
    let title: String
    let value: String
    var secondaryText: String? = nil
    var iconColor: Color = .blue
    var valueColor: Color? = nil
    var tooltip: String? = nil
    
    @State private var showTooltip = false
    
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
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                
                if tooltip != nil {
                    Button {
                        showTooltip.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
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
        .overlay(
            Group {
                if showTooltip, let tooltip = tooltip {
                    VStack {
                        Text(tooltip)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.8))
                            )
                            .shadow(radius: 5)
                            .padding(.horizontal, 8)
                            .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity)
                    .zIndex(100)
                    .offset(y: -50)
                }
            }
        )
        .onTapGesture {
            if tooltip != nil {
                showTooltip.toggle()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(tooltip ?? "")
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
                iconColor: .yellow,
                tooltip: "The total number of packages shipped throughout your company's history."
            )
            
            DashboardStatCard(
                icon: "dollarsign.circle.fill",
                title: "Current Money",
                value: "$1,250.00",
                iconColor: .green, 
                valueColor: .green,
                tooltip: "Your company's current cash reserve. This is used for purchasing upgrades and paying workers."
            )
            
            DashboardStatCard(
                icon: "person.3.fill",
                title: "Workforce",
                value: "12 Workers",
                secondaryText: "Efficiency: 1.75×",
                iconColor: .blue,
                tooltip: "The number of workers employed by your company. Each worker contributes to your package production rate."
            )
        }
        .padding()
    }
} 
