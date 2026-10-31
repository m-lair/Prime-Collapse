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
                    VStack(spacing: 6) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        // Category indicator
                        Text(categoryName(event.category))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(categoryColor(event.category).opacity(0.8))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
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
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
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
                                choiceButtonLabel(choice: choice, importance: event.importance,
                                                  isButtonEnabled: isButtonEnabled, canMakeChoice: canMakeChoice)
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
                .padding(.vertical, 12) // room for the card's shadow inside the scroll view
                .frame(maxWidth: 400)
                .frame(maxWidth: .infinity)
            }
            // Cap the scroll view, not its content: capping the content let tall events
            // overflow above the screen edge, hiding the title under the status bar.
            .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
            .fixedSize(horizontal: false, vertical: true)
            .scrollBounceBehavior(.basedOnSize)
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
            // Full-screen backdrop: a decision is pending, so the game behind it must not take
            // taps (otherwise players could spend down their balance to shrink an ethical cost).
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(slideIn ? 0.35 : 0).ignoresSafeArea())
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.3), value: slideIn)
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Choice Button Label

    /// Title and ethics badge, then one wrapping row of effect chips (money first), then a single
    /// line for what lands later. Compact enough that a three-choice event fits without scrolling.
    @ViewBuilder
    private func choiceButtonLabel(choice: EventChoice, importance: GameEvent.EventImportance,
                                   isButtonEnabled: Bool, canMakeChoice: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(choice.text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            FlowLayout(spacing: 5) {
                ethicsBadge(choice: choice, importance: importance)
                ForEach(moneyDescriptions(for: choice) + (choice.effectDescriptions ?? [])) { description in
                    effectChip(description)
                }
            }

            if let fallout = choice.fallout {
                Label(falloutSummary(fallout), systemImage: "clock.badge.exclamationmark")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
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

    /// "Very Unethical ●●●●● −10": label, dots and the scaled ethics change actually applied.
    private func ethicsBadge(choice: EventChoice, importance: GameEvent.EventImportance) -> some View {
        let impact = EventManager.scaledMoralImpact(of: choice, importance: importance, state: gameState)
        return HStack(spacing: 4) {
            Text(ethicsImpactLabel(choice.moralImpact))
            ethicsImpactIndicator(choice.moralImpact)
            if impact.rounded() != 0 {
                Text(String(format: "%+.0f", impact))
                    .fontWeight(.bold)
            }
        }
        .font(.caption2)
        .foregroundColor(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(ethicsImpactColor(choice.moralImpact).opacity(0.45))
        .clipShape(Capsule())
    }

    private func effectChip(_ description: EffectDescription) -> some View {
        let tint = color(for: description.impactType)
        // Money chips are already self-describing ("+$75 now"); stat chips need their name.
        let text = description.metricName == "Cash"
            ? description.changeDescription
            : "\(description.metricName) \(description.changeDescription)"
        return Text(text)
            .font(.caption2)
            .fontWeight(description.metricName == "Cash" ? .bold : .medium)
            .foregroundColor(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15))
            .clipShape(Capsule())
    }

    /// "+$340 now" / "Income +25% · 60s", sized from the economy as it stands right now.
    private func moneyDescriptions(for choice: EventChoice) -> [EffectDescription] {
        var rows: [EffectDescription] = []
        if let cash = choice.cash {
            let amount = cash.signedAmount(in: gameState)
            rows.append(EffectDescription(metricName: "Cash",
                                          changeDescription: "\(MoneyFormat.signed(amount)) now",
                                          impactType: amount >= 0 ? .positive : .negative))
        }
        if let shift = choice.incomeShift {
            let percent = String(format: "%+.0f%%", shift.bonus * 100)
            rows.append(EffectDescription(metricName: "Income",
                                          changeDescription: "\(percent) · \(Int(shift.duration))s",
                                          impactType: shift.bonus >= 0 ? .positive : .negative))
        }
        return rows
    }

    /// One line: "In 45s: Perception −10" or "40% risk in 60s: −$1.3K, Perception −15".
    private func falloutSummary(_ fallout: Fallout) -> String {
        let when = fallout.chance < 1
            ? "\(Int(fallout.chance * 100))% risk in \(Int(fallout.delay))s"
            : "In \(Int(fallout.delay))s"
        let fine = fallout.fine.map { [MoneyFormat.signed(-$0.sizedAmount(in: gameState))] } ?? []
        let effects = fallout.descriptions.map { "\($0.metricName) \($0.changeDescription)" }
        return "\(when): " + (fine + effects).joined(separator: ", ")
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

/// Left-to-right wrapping layout for effect chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
