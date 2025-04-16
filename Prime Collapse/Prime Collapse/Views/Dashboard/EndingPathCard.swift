import SwiftUI

// Path requirement item for ending requirements
struct RequirementItem {
    let title: String
    let value: String
    let isMet: Bool
}

// Path card for available endings
struct EndingPathCard: View {
    let title: String
    let description: String
    let color: Color
    let icon: String
    let requirements: [RequirementItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon background
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Requirements
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<requirements.count, id: \.self) { index in
                    let req = requirements[index]
                    
                    HStack {
                        // Status icon
                        Image(systemName: req.isMet ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(req.isMet ? .green : .white.opacity(0.5))
                            .font(.system(size: 14, weight: .bold))
                        
                        // Requirement text
                        Text(req.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        // Value
                        Text(req.value)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(req.isMet ? .green : .white.opacity(0.7))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        EndingPathCard(
            title: "Corporate Reform Ending",
            description: "Build a successful company while maintaining ethical standards.",
            color: .green,
            icon: "leaf.fill",
            requirements: [
                RequirementItem(
                    title: "Ethical Choices",
                    value: "3/5",
                    isMet: false
                ),
                RequirementItem(
                    title: "Ethics Level",
                    value: "< 50",
                    isMet: true
                ),
                RequirementItem(
                    title: "Money Earned",
                    value: "> $1,000",
                    isMet: true
                )
            ]
        )
        .padding()
    }
} 