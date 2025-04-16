import SwiftUI

// Dashboard stat card
struct DashboardStatCard: View {
    let icon: String
    let title: String
    let value: String
    var iconColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with icon
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.3))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Value
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        VStack {
            DashboardStatCard(
                icon: "shippingbox.fill",
                title: "Total Packages",
                value: "523",
                iconColor: .yellow
            )
            
            DashboardStatCard(
                icon: "dollarsign.circle.fill",
                title: "Current Money",
                value: "$1,250.00",
                iconColor: .green
            )
        }
        .padding()
    }
} 