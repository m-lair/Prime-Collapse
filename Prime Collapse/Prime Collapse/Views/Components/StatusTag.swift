import SwiftUI

// Status indicator tag
struct StatusTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16, weight: .bold))
            
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusTag(icon: "checkmark.circle.fill", text: "Ethical Corporation", color: .green)
        StatusTag(icon: "exclamationmark.triangle", text: "Ethics Declining", color: .orange)
        StatusTag(icon: "xmark.circle.fill", text: "Critical Ethics Failure", color: .red)
    }
    .padding()
    .background(Color.blue.opacity(0.3))
    .previewLayout(.sizeThatFits)
} 