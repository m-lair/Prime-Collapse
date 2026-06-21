//
//  OnboardingOverlayView.swift
//  Prime Collapse
//
//  A lightweight, one-time tutorial shown to brand-new players. Gated by the
//  "hasSeenTutorial" AppStorage flag in ContentView.
//

import SwiftUI

struct OnboardingOverlayView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.blue)
                    Text("Welcome to Prime Collapse")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 20) {
                    row(icon: "hand.tap.fill", color: .blue,
                        title: "Ship packages",
                        text: "Tap the big button to ship packages and earn money.")
                    row(icon: "person.2.fill", color: .green,
                        title: "Hire & automate",
                        text: "Spend money on upgrades to ship packages automatically while you watch.")
                    row(icon: "scalemass.fill", color: .orange,
                        title: "Mind your ethics",
                        text: "Every upgrade has a moral cost. Let your ethics score hit zero and the whole system collapses.")
                }
                .padding(.horizontal, 8)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Text("Start Shipping")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue)
                        )
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 40)
        }
    }

    private func row(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(color.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingOverlayView(isPresented: .constant(true))
}
