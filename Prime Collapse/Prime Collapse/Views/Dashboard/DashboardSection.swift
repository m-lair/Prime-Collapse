import SwiftUI

// Dashboard section with title
struct DashboardSection: View {
    let title: String
    var titleColor: Color = .white
    let content: () -> AnyView
    @State private var isExpanded: Bool = true
    
    init(title: String, titleColor: Color = .white, @ViewBuilder content: @escaping () -> some View) {
        self.title = title
        self.titleColor = titleColor
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 15 : 0) {
            // Section header with collapsible functionality
            HStack {
                // Section title
                Text(title.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(titleColor.opacity(0.7))
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(titleColor.opacity(0.7))
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(isExpanded ? "Collapse section" : "Expand section")
            }
            .padding(.horizontal)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }
            
            // Content (only visible when expanded)
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        VStack(spacing: 15) {
            DashboardSection(title: "Business Performance") {
                Text("Section Content")
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            DashboardSection(title: "Workforce Analytics", titleColor: .mint) {
                Text("Another Section")
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
    }
} 