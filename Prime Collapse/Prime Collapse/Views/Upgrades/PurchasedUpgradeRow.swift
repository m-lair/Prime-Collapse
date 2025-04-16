import SwiftUI

// Row for purchased upgrades
struct PurchasedUpgradeRow: View {
    let name: String
    let description: String
    let color: Color
    let isRepeatable: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Badge/icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isRepeatable ? "arrow.triangle.2.circlepath" : "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Name and description
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Repeatable badge
            if isRepeatable {
                Text("REPEATABLE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        VStack {
            PurchasedUpgradeRow(
                name: "Hire Worker",
                description: "Each worker adds to your automation rate",
                color: .blue,
                isRepeatable: true
            )
            
            PurchasedUpgradeRow(
                name: "AI Optimization",
                description: "Use machine learning to optimize delivery routes",
                color: .purple,
                isRepeatable: false
            )
        }
        .padding()
    }
} 