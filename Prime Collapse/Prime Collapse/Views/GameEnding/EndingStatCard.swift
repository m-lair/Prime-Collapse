import SwiftUI

// Ending stats card
struct EndingStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
        )
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.5).ignoresSafeArea()
        VStack(spacing: 16) {
            EndingStatCard(
                title: "Total Packages Shipped",
                value: "1,523",
                icon: "shippingbox.fill",
                color: .yellow
            )
            
            EndingStatCard(
                title: "Final Profit",
                value: "$2,450.75",
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            EndingStatCard(
                title: "Final Worker Count",
                value: "12",
                icon: "person.fill",
                color: .blue
            )
        }
        .padding()
    }
} 