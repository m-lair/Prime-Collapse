import SwiftUI

struct EventView: View {
    @Environment(GameState.self) private var gameState
    @Environment(EventManager.self) private var eventManager
    
    // Animation properties
    @State private var slideIn = false
    
    var body: some View {
        if let event = eventManager.currentEvent {
            VStack(spacing: 0) {
                // Event header
                VStack(spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 16)
                    
                    // Category indicator
                    Text(categoryName(event.category))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor(event.category))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7))
                
                // Event description
                Text(event.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.9))
                
                // Event choices
                VStack(spacing: 0) {
                    ForEach(event.choices) { choice in
                        Button(action: {
                            withAnimation {
                                eventManager.processChoice(choice: choice, gameState: gameState)
                                slideIn = false
                            }
                        }) {
                            HStack(alignment: .center) {
                                Text(choice.text)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                
                                Spacer()
                                
                                // Moral compass indicator
                                moraleIndicator(choice.moralImpact)
                            }
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color.blue.opacity(0.8))
                        
                        if choice.id != event.choices.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(0)
                        }
                    }
                }
                .background(Color.blue.opacity(0.6))
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
            .frame(maxWidth: 400)
            .offset(y: slideIn ? 0 : UIScreen.main.bounds.height)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: slideIn)
            .onAppear {
                withAnimation {
                    slideIn = true
                }
            }
        } else {
            EmptyView()
        }
    }
    
    // Helper for moral impact visualization
    private func moraleIndicator(_ impact: Double) -> some View {
        HStack(spacing: 2) {
            if impact > 0 {
                ForEach(0..<Int(impact * 2), id: \.self) { _ in
                    Image(systemName: "arrow.up")
                        .foregroundColor(.green)
                }
            } else if impact < 0 {
                ForEach(0..<Int(abs(impact) * 2), id: \.self) { _ in
                    Image(systemName: "arrow.down")
                        .foregroundColor(.red)
                }
            } else {
                Image(systemName: "minus")
                    .foregroundColor(.gray)
            }
        }
        .font(.caption)
    }
    
    // Helper for category display
    private func categoryName(_ category: GameEvent.Category) -> String {
        switch category {
            case .workplace: return "Workplace"
            case .market: return "Market"
            case .publicRelations: return "PR"
            case .regulatory: return "Regulatory"
        }
    }
    
    private func categoryColor(_ category: GameEvent.Category) -> Color {
        switch category {
            case .workplace: return .blue
            case .market: return .green
            case .publicRelations: return .purple
            case .regulatory: return .orange
        }
    }
}

#Preview {
    EventView()
        .environment(GameState())
        .environment(EventManager())
} 