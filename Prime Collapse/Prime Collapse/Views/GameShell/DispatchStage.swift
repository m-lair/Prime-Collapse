import SwiftUI

struct DispatchStage: View {
    let packages: Int
    let workers: Int
    let automaticRate: Double
    let isRunning: Bool
    var onShip: (() -> Void)? = nil

    @State private var shipmentFeedback = 0

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var motionAllowed: Bool {
        isRunning && scenePhase == .active && !reduceMotion && onShip != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TimelineView(.animation(minimumInterval: 1 / 24, paused: !motionAllowed || automaticRate <= 0)) { timeline in
                    Canvas { context, size in
                        let phase = motionAllowed && automaticRate > 0
                            ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100) : 0
                        drawFloor(context: &context, size: size, phase: phase)
                    }
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("DISPATCH FLOOR")
                        .font(.caption2.weight(.bold)).tracking(2)
                    Text(packages, format: .number)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                    Text("packages dispatched")
                        .font(.caption)
                }
                .foregroundStyle(GamePalette.label)
                .padding(24)
                .background(dynamicTypeSize.isAccessibilitySize ? GamePalette.floor : .clear)
                .accessibilityElement(children: .combine)
                .fixedSize(horizontal: false, vertical: true)

                if !dynamicTypeSize.isAccessibilitySize {
                    GeometryReader { geometry in
                        parcel
                            .keyframeAnimator(initialValue: CGFloat.zero, trigger: motionAllowed ? shipmentFeedback : 0) { content, progress in
                                content
                                    .offset(x: progress * geometry.size.width * 0.45)
                                    .opacity(1 - progress)
                            } keyframes: { _ in
                                LinearKeyframe(1, duration: 0.3)
                                MoveKeyframe(0)
                            }
                            .position(x: geometry.size.width * 0.53, y: geometry.size.height * 0.57)
                    }
                    .accessibilityHidden(true)
                }
            }
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 320 : 270)
            .background(GamePalette.floor)
            .clipped()

            if let onShip {
                Button {
                    onShip()
                    shipmentFeedback += 1
                } label: {
                    HStack(spacing: 12) {
                        if !dynamicTypeSize.isAccessibilitySize { Image(systemName: "shippingbox.fill") }
                        Text("Ship package")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .fixedSize(horizontal: false, vertical: true)
                        if !dynamicTypeSize.isAccessibilitySize {
                            Spacer(minLength: 8)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .contentShape(Rectangle())
                }
                .buttonStyle(DispatchPressStyle())
                .sensoryFeedback(.impact(weight: .light), trigger: shipmentFeedback)
                .foregroundStyle(GamePalette.ink)
                .background(GamePalette.orange)
                .disabled(!isRunning)
                .accessibilityHint(isRunning ? "Dispatch one package" : "Resume the game to dispatch packages")
            }
        }
    }

    private var parcel: some View {
        ZStack {
            Rectangle().fill(GamePalette.carton)
            Rectangle().fill(GamePalette.label.opacity(0.7)).frame(width: 9)
            Rectangle().fill(GamePalette.label).frame(width: 24, height: 16).offset(x: 15, y: 8)
            Rectangle().fill(GamePalette.ink.opacity(0.7)).frame(width: 16, height: 3).offset(x: 15, y: 8)
        }
        .frame(width: 70, height: 58)
        .overlay(Rectangle().strokeBorder(GamePalette.ink.opacity(0.25), lineWidth: 2))
        .rotationEffect(.degrees(-3))
    }

    private func drawFloor(context: inout GraphicsContext, size: CGSize, phase: Double) {
        let beltY = size.height * 0.69
        // Loading bay and floor markings remain readable at every stage size.
        let bay = CGRect(x: size.width * 0.72, y: 22, width: size.width * 0.23, height: beltY - 10)
        context.fill(Path(bay), with: .color(GamePalette.ink))
        for line in 0..<7 {
            let y = bay.minY + CGFloat(line) * (bay.height / 7)
            context.stroke(Path { $0.move(to: CGPoint(x: bay.minX, y: y)); $0.addLine(to: CGPoint(x: bay.maxX, y: y)) }, with: .color(GamePalette.floor.opacity(0.7)), lineWidth: 2)
        }
        context.fill(Path(CGRect(x: bay.minX - 5, y: bay.minY, width: 5, height: bay.height)), with: .color(GamePalette.orange))
        context.fill(Path(CGRect(x: 0, y: beltY + 30, width: size.width, height: size.height - beltY)), with: .color(GamePalette.ink.opacity(0.22)))
        context.fill(Path(CGRect(x: -4, y: beltY, width: size.width + 8, height: 25)), with: .color(GamePalette.ink))
        let beltShift = CGFloat(phase * min(28, max(4, automaticRate * 6))).truncatingRemainder(dividingBy: 24)
        for roller in 0..<Int(size.width / 24) + 2 {
            let x = CGFloat(roller) * 24 + beltShift - 24
            context.fill(Path(ellipseIn: CGRect(x: x, y: beltY + 7, width: 12, height: 12)), with: .color(GamePalette.floor))
        }
        if automaticRate > 0 {
            let spacing = size.width / 3
            for index in 0..<3 {
                let travel = CGFloat(phase * min(48, 10 + automaticRate * 5))
                let x = (CGFloat(index) * spacing + travel).truncatingRemainder(dividingBy: size.width + 45) - 45
                let box = CGRect(x: x, y: beltY - 33, width: 40, height: 32)
                context.fill(Path(box), with: .color(GamePalette.carton.opacity(0.85)))
                context.fill(Path(CGRect(x: x + 17, y: box.minY, width: 6, height: 32)), with: .color(GamePalette.label.opacity(0.65)))
            }
        }
        for index in 0..<min(max(workers, 0), 6) {
            let x = 24 + CGFloat(index) * 27
            let y = size.height - 38
            context.fill(Path(ellipseIn: CGRect(x: x + 5, y: y - 13, width: 10, height: 10)), with: .color(GamePalette.label))
            context.fill(Path(roundedRect: CGRect(x: x, y: y, width: 20, height: 20), cornerRadius: 5), with: .color(GamePalette.teal))
        }
        context.stroke(Path { $0.move(to: CGPoint(x: size.width * 0.7, y: size.height - 16)); $0.addLine(to: CGPoint(x: size.width - 16, y: size.height - 16)) }, with: .color(GamePalette.label.opacity(0.35)), style: StrokeStyle(lineWidth: 2, dash: [12, 7]))
    }
}

private struct DispatchPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(GamePalette.ink.opacity(configuration.isPressed ? 0.1 : 0))
    }
}
