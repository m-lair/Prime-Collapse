import SwiftUI

struct DispatchStage: View {
    let packages: Int
    let workers: Int
    let automaticRate: Double
    let isRunning: Bool
    var onShip: (() -> Void)? = nil

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var dispatchCount = 0

    private var motionAllowed: Bool {
        isRunning && scenePhase == .active && !reduceMotion && onShip != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                let headerLayout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                    : AnyLayout(HStackLayout())
                headerLayout {
                    Text("DISPATCH FLOOR").tracking(2)
                    if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                    Label(isRunning ? "LIVE" : "ON HOLD", systemImage: isRunning ? "circle.fill" : "pause.fill")
                        .foregroundStyle(GamePalette.label)
                }
                .font(.caption.weight(.bold))
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) { counter }
                    VStack(alignment: .leading, spacing: 4) { counter }
                }
                .accessibilityElement(children: .combine)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .foregroundStyle(GamePalette.label)

            TimelineView(.animation(minimumInterval: 1 / 24, paused: !motionAllowed || automaticRate <= 0)) { timeline in
                Canvas { context, size in
                    let phase = motionAllowed && automaticRate > 0 ? timeline.date.timeIntervalSinceReferenceDate : 0
                    DispatchFloorDrawing.draw(context: &context, size: size, phase: phase,
                                              workers: workers, automaticRate: automaticRate)
                }
            }
            .overlay {
                GeometryReader { geometry in
                    let reduceMotion = reduceMotion
                    DispatchParcel()
                        .frame(width: 42, height: 48)
                        .shadow(color: .black.opacity(0.4), radius: 2, y: 4)
                        .keyframeAnimator(initialValue: CGFloat.zero, trigger: dispatchCount) { content, progress in
                            content
                                .offset(x: reduceMotion ? 0 : progress * geometry.size.width * 0.55,
                                        y: reduceMotion ? 0 : -progress * 20)
                                .opacity(1 - progress)
                        } keyframes: { _ in
                            LinearKeyframe(1, duration: 0.35)
                            MoveKeyframe(0)
                        }
                        .position(x: geometry.size.width * 0.32, y: geometry.size.height * 0.54)
                }
            }
            .aspectRatio(400.0 / 235.0, contentMode: .fit)
            .frame(maxHeight: dynamicTypeSize.isAccessibilitySize ? 170 : 340)
            .accessibilityHidden(true)
            .clipped()

            if let onShip {
                Button {
                    onShip()
                    dispatchCount += 1
                } label: {
                    HStack(spacing: 12) {
                        if !dynamicTypeSize.isAccessibilitySize { Image(systemName: "shippingbox.fill") }
                        Text("Ship package").fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        if !dynamicTypeSize.isAccessibilitySize { Image(systemName: "arrow.right") }
                    }
                }
                .buttonStyle(GameActionStyle())
                .disabled(!isRunning)
                .sensoryFeedback(.impact(weight: .light), trigger: dispatchCount)
                .accessibilityHint(isRunning ? "Dispatch one package" : "Resume the game to dispatch packages")
                .padding(16)
                .padding(.top, -8)
            }
        }
        .background(LinearGradient(colors: [GamePalette.floor, GamePalette.ink], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(GamePalette.label.opacity(0.12), lineWidth: 1) }
    }

    @ViewBuilder private var counter: some View {
        Text(packages, format: .number)
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .monospacedDigit()
            .contentTransition(.numericText())
        Text("packages dispatched")
            .font(.subheadline)
            .foregroundStyle(GamePalette.label.opacity(0.75))
    }
}
