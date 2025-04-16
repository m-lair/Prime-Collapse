import SwiftUI

// Card for displaying a statistic
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    var secondaryText: String? = nil
    var iconColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .bold))
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if let secondaryText = secondaryText {
                Text(secondaryText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(iconColor.opacity(0.5), lineWidth: 1.5)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.5).ignoresSafeArea()
        StatCard(icon: "shippingbox.fill", title: "Packages", value: "143", iconColor: .yellow)
            .padding()
    }
} 