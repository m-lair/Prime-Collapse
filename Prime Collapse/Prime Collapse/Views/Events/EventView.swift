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
        if impact <= -8 { return "Very Unethical" }
        else if impact <= -3 { return "Unethical" }       // Includes -3, -4, -5, -6, -7
        else if impact < 0 { return "Slightly Unethical" } // Includes -1, -2
        else if impact == 0 { return "Neutral" }
        else if impact < 3 { return "Slightly Ethical" } // Includes 1, 2
        else if impact < 8 { return "Ethical" }           // Includes 3, 4, 5, 6, 7
        else { return "Very Ethical" }                  // Includes 8+
    }
    
    // Helper for ethics impact visualization
    private func ethicsImpactIndicator(_ impact: Double) -> some View {
        // Map impact ranges to color and circle count
        let (color, count): (Color, Int) = {
            if impact <= -8 { return (.red, 5) }          // Very Unethical
            else if impact <= -3 { return (.red, 4) }      // Unethical
            else if impact < 0 { return (.red, 2) }        // Slightly Unethical
            else if impact == 0 { return (.gray, 1) }      // Neutral
            else if impact < 3 { return (.green, 2) }      // Slightly Ethical
            else if impact < 8 { return (.green, 4) }      // Ethical
            else { return (.green, 5) }                  // Very Ethical (>= 8)
        }()

        return HStack(spacing: 2) {
            // Ensure neutral shows one gray circle
            if impact == 0 {
                 Image(systemName: "circle")
                    .foregroundColor(.gray)
                    .font(.system(size: 8))
            } else {
                // Display filled circles based on calculated count and color
                ForEach(0..<count, id: \.self) { _ in
                    Image(systemName: "circle.fill")
                        .foregroundColor(color)
                        .font(.system(size: 8))
                }
            }
        }
    }
    
    // Helper for ethics impact color (used for background)
    private func ethicsImpactColor(_ impact: Double) -> Color {
        if impact < 0 { // Negative impact -> Unethical -> Red
            return .red
        } else if impact > 0 { // Positive impact -> Ethical -> Green
            return .green
        } else { // Neutral -> Gray
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
