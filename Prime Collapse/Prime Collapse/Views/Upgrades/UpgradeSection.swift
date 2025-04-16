import SwiftUI

// Upgrade section with title
struct UpgradeSection: View {
    let title: String
    let content: () -> AnyView
    
    init(title: String, @ViewBuilder content: @escaping () -> some View) {
        self.title = title
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Section title
            Text(title.uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            
            // Content
            content()
        }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        UpgradeSection(title: "Sample Section") {
            Text("Section Content")
                .foregroundStyle(.white)
                .padding()
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }
} 