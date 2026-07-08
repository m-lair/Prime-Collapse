//
//  PrestigeView.swift
//  Prime Collapse
//
//  Spend banked prestige points on permanent perks that give the next run a head start.
//

import SwiftUI

struct PrestigeView: View {
    @Environment(PrestigeManager.self) private var prestige
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.10, blue: 0.24),
                             Color(red: 0.20, green: 0.14, blue: 0.36)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        pointsBanner

                        ForEach(PrestigePerk.allCases, id: \.self) { perk in
                            perkRow(perk)
                        }

                        Text("Prestige is permanent — it carries across every reset and boosts the start of each new run.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Prestige")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var pointsBanner: some View {
        VStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(.yellow)
            Text("\(prestige.points)")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text("Prestige Points")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.25)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prestige.points) prestige points available")
    }

    private func perkRow(_ perk: PrestigePerk) -> some View {
        let level = prestige.level(of: perk)
        let cost = prestige.cost(of: perk)
        let affordable = prestige.canAfford(perk)

        return HStack(spacing: 14) {
            Image(systemName: perk.icon)
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.15)))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(perk.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if level > 0 {
                        Text("Lv \(level)")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.yellow.opacity(0.85)))
                            .foregroundStyle(.black)
                    }
                }
                Text(perk.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button {
                prestige.purchase(perk)
            } label: {
                VStack(spacing: 1) {
                    Text("\(cost)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("pts")
                        .font(.system(size: 10))
                }
                .foregroundStyle(affordable ? .black : .white.opacity(0.5))
                .frame(width: 56, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(affordable ? Color.yellow : Color.white.opacity(0.12))
                )
            }
            .disabled(!affordable)
            .accessibilityLabel("Buy \(perk.displayName) for \(cost) points")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
    }
}
