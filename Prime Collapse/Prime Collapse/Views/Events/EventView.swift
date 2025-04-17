import SwiftUI

// MARK: - Custom Button Style for subtle scaling effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.05 : 0) // Slightly darken on press
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0) // Scale down a bit more
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct EventView: View {
    @Environment(GameState.self) private var gameState
    @Environment(EventManager.self) private var eventManager
    
    // Animation properties
    @State private var slideIn = false
    @State private var isInteractable = false // New state for interaction delay
    
    var body: some View {
        if let event = eventManager.currentEvent {
            ScrollView(.vertical, showsIndicators: true) {
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
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                categoryColor(event.category).opacity(0.9),
                                categoryColor(event.category).opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    // Event description
                    Text(event.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(categoryColor(event.category).opacity(0.3))
                        )
                    
                    // Event choices
                    VStack(spacing: 1) {
                        ForEach(event.choices) { choice in
                            // Determine if the choice should be enabled
                            let canMakeChoice = choice.canChoose?(gameState) ?? true
                            let isButtonEnabled = isInteractable && canMakeChoice
                            
                            Button(action: {
                                guard isButtonEnabled else { return } // Use the combined enabled state
                                withAnimation {
                                    eventManager.processChoice(choice: choice, gameState: gameState)
                                    slideIn = false // This might need adjustment later if interaction closes the view
                                    // Reset interaction state if needed when the view is dismissed/reused
                                    isInteractable = false
                                }
                            }) {
                                // Use the helper function to build the button label content
                                choiceButtonLabel(choice: choice, isButtonEnabled: isButtonEnabled, canMakeChoice: canMakeChoice)
                            }
                            .buttonStyle(ScaleButtonStyle()) // Apply custom button style
                            .disabled(!isButtonEnabled) // Disable button based on combined state
                            // Removed opacity modifier, handled by overlay now
                            .animation(.easeIn(duration: 0.3).delay(0.6), value: isButtonEnabled) // Animate based on combined state

                            if choice.id != event.choices.last?.id {
                                Divider()
                                    .frame(height: 1)
                                    .background(Color.white.opacity(0.2))
                                    .padding(0)
                            }
                        }
                    }
                    .background(Color.clear)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                .frame(maxWidth: 400, maxHeight: UIScreen.main.bounds.height * 0.8)
                .offset(y: slideIn ? 0 : UIScreen.main.bounds.height)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: slideIn)
                .onAppear {
                    isInteractable = false // Ensure it's false initially
                    withAnimation {
                        slideIn = true
                    }
                    // Delay enabling interaction
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { // Adjust delay as needed
                        withAnimation {
                             isInteractable = true
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Helper View Builder for Choice Button Label
    @ViewBuilder
    private func choiceButtonLabel(choice: EventChoice, isButtonEnabled: Bool, canMakeChoice: Bool) -> some View {
        // Main HStack for two-column layout
        HStack(alignment: .top, spacing: 12) { // Align tops, add spacing
            // Left Column: Choice Text & Ethics
            VStack(alignment: .leading, spacing: 8) {
                Text(choice.text)
                    .font(.headline) // Make choice text more prominent
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil) // Allow text to wrap

                // Ethics impact indicator
                HStack(spacing: 6) {
                    Text(ethicsImpactLabel(choice.moralImpact))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))

                    ethicsImpactIndicator(choice.moralImpact)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(ethicsImpactColor(choice.moralImpact).opacity(0.4)) // Slightly more opaque bg
                .cornerRadius(6)
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Allow left column to expand

            // Right Column: Effects
            if let descriptions = choice.effectDescriptions, !descriptions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(descriptions) { description in
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Image(systemName: iconName(for: description.impactType))
                                .font(.caption) // Keep icon size reasonable
                                .foregroundColor(color(for: description.impactType))
                                .frame(width: 15, alignment: .center) // Give icon consistent space

                            VStack(alignment: .leading, spacing: 1) { // Reduced spacing
                                // Metric Name and Change
                                HStack(spacing: 4) { 
                                    Text("\(description.metricName):")
                                        .font(.caption) // Keep captions
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.9))
                                    Text(description.changeDescription)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(color(for: description.impactType))
                                }

                                // Current Value (if available)
                                if let currentValue = getCurrentValueString(for: description.metricName) {
                                    Text(currentValue)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6)) // Slightly dimmer
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Allow right column to expand
            }
        }
        .padding(16) // Apply padding to the HStack content
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(white: 0.2, opacity: 0.5)) // Darker, more distinct background
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .overlay(
            // More prominent disabled overlay
            Group {
                if !isButtonEnabled {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.6))
                    
                    if !canMakeChoice, let reasonClosure = choice.disabledReason {
                        Text(reasonClosure(gameState))
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(8)
                            .background(Material.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(radius: 2)
                    }
                }
            }
        )
    }
    
    // Helper to get current value string for a metric
    private func getCurrentValueString(for metricName: String) -> String? {
        let value: String?
        switch metricName.lowercased() { // Use lowercased for case-insensitivity
        case "money":
            value = String(format: "$%.2f", gameState.money)
        case "workers":
            value = "\(gameState.workers)"
        case "worker morale", "morale":
            value = String(format: "%.0f%%", gameState.workerMorale * 100)
        case "worker efficiency", "efficiency":
             value = String(format: "%.2f", gameState.workerEfficiency)
        case "customer satisfaction", "satisfaction":
            value = String(format: "%.0f%%", gameState.customerSatisfaction * 100)
        case "public perception", "perception":
            value = String(format: "%.0f / 100", gameState.publicPerception)
        case "environmental impact", "environment":
             value = String(format: "%.0f / 100", gameState.environmentalImpact)
        case "package value":
            value = String(format: "$%.2f", gameState.packageValue)
        case "ethics", "ethics score":
            value = String(format: "%.0f / 100", gameState.ethicsScore)
        // Add other cases for relevant GameState properties as needed
        default:
            return nil // Return nil if metricName doesn't match known properties
        }
        return "Currently: \(value ?? "N/A")"
    }

    // Helper functions for EffectDescription display
    private func iconName(for impactType: EffectDescription.ImpactType) -> String {
        switch impactType {
        case .positive: return "arrow.up.right.circle.fill"
        case .negative: return "arrow.down.right.circle.fill"
        case .neutral: return "circle.dashed"
        }
    }

    private func color(for impactType: EffectDescription.ImpactType) -> Color {
        switch impactType {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
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
