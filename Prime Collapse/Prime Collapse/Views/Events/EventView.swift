import SwiftUI

struct EventView: View {
    @Environment(GameState.self) private var gameState
    @Environment(EventManager.self) private var eventManager
    
    // Animation properties
    @State private var slideIn = false
    
    var body: some View {
        if let event = eventManager.currentEvent {
            VStack {
                // Event header
                VStack(spacing: 4) {
                    Text(event.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                    
                    // Category indicator
                    Text(categoryName(event.category))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor(event.category).opacity(0.8))
                        .clipShape(Capsule())
                }
                .padding(.bottom)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.8))
                
                // Event description
                Text(event.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.65))
                
                // Event choices
                VStack(spacing: 1) {
                    ForEach(event.choices) { choice in
                        Button(action: {
                            withAnimation {
                                eventManager.processChoice(choice: choice, gameState: gameState)
                                slideIn = false
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(choice.text)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.white)
                                
                                // Ethics impact indicator
                                HStack(spacing: 6) {
                                    Text(ethicsImpactLabel(choice.moralImpact))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    ethicsImpactIndicator(choice.moralImpact)
                                }
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(ethicsImpactColor(choice.moralImpact).opacity(0.3))
                                .cornerRadius(4)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(white: 0.2, opacity: 0.8))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if choice.id != event.choices.last?.id {
                            Divider()
                                .frame(height: 1)
                                .background(Color.white.opacity(0.2))
                                .padding(0)
                        }
                    }
                }
                .background(Color(white: 0.15, opacity: 1))
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
    
    // Helper for ethics impact label
    private func ethicsImpactLabel(_ impact: Double) -> String {
        if impact > 8 {
            return "Very Unethical"
        } else if impact > 3 {
            return "Unethical"
        } else if impact > 0 {
            return "Slightly Unethical"
        } else if impact < -8 {
            return "Very Ethical"
        } else if impact < -3 {
            return "Ethical"
        } else if impact < 0 {
            return "Slightly Ethical"
        } else {
            return "Neutral"
        }
    }
    
    // Helper for ethics impact visualization
    private func ethicsImpactIndicator(_ impact: Double) -> some View {
        HStack(spacing: 2) {
            if impact > 0 {
                // Unethical choice (moral decay increases)
                ForEach(0..<min(5, Int(impact / 2) + 1), id: \.self) { index in
                    Image(systemName: index < Int(impact / 2) ? "circle.fill" : "circle")
                        .foregroundColor(.red)
                        .font(.system(size: 8))
                }
            } else if impact < 0 {
                // Ethical choice (moral decay decreases)
                ForEach(0..<min(5, Int(abs(impact) / 2) + 1), id: \.self) { index in
                    Image(systemName: index < Int(abs(impact) / 2) ? "circle.fill" : "circle")
                        .foregroundColor(.green)
                        .font(.system(size: 8))
                }
            } else {
                // Neutral
                Image(systemName: "circle")
                    .foregroundColor(.gray)
                    .font(.system(size: 8))
            }
        }
    }
    
    // Helper for ethics impact color
    private func ethicsImpactColor(_ impact: Double) -> Color {
        if impact > 0 {
            return .red
        } else if impact < 0 {
            return .green
        } else {
            return .gray
        }
    }
    
    // Helper for category display
    private func categoryName(_ category: GameEvent.Category) -> String {
        switch category {
        case .workplace: return "Workplace"
        case .market: return "Market"
        case .publicRelations: return "PR"
        case .regulatory: return "Regulatory"
        case .technology: return "Technology"
        case .crisis: return "Crisis"
            
        }
    }
    
    private func categoryColor(_ category: GameEvent.Category) -> Color {
        switch category {
            case .workplace: return .blue
            case .market: return .green
            case .publicRelations: return .purple
            case .regulatory: return .orange
            case .technology: return .yellow
            case .crisis: return .red
        }
    }
}

#Preview {
    EventView()
        .environment(GameState())
        .environment(EventManager())
}
