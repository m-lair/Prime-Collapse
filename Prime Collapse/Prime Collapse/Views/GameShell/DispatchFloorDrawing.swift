import SwiftUI

/// A small loading dock, drawn in a stable 400 × 235 coordinate space.
enum DispatchFloorDrawing {
    static func draw(context: inout GraphicsContext, size: CGSize, phase: Double, workers: Int, automaticRate: Double) {
        context.scaleBy(x: size.width / 400, y: size.height / 235)
        func polygon(_ points: [CGPoint], _ color: Color) {
            context.fill(Path { path in
                path.addLines(points)
                path.closeSubpath()
            }, with: .color(color))
        }
        func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ color: Color) {
            context.fill(Path(CGRect(x: x, y: y, width: width, height: height)), with: .color(color))
        }
        func line(_ from: CGPoint, _ to: CGPoint, _ color: Color, width: CGFloat = 1) {
            context.stroke(Path { $0.move(to: from); $0.addLine(to: to) }, with: .color(color), lineWidth: width)
        }
        func parcel(_ x: CGFloat, _ y: CGFloat, _ side: CGFloat) {
            let depth = side * 0.4
            polygon([.init(x: x, y: y), .init(x: x + side, y: y), .init(x: x + side, y: y + side), .init(x: x, y: y + side)], GamePalette.carton)
            polygon([.init(x: x, y: y), .init(x: x + depth, y: y - depth), .init(x: x + side + depth, y: y - depth), .init(x: x + side, y: y)], Color(red: 0.88, green: 0.72, blue: 0.51))
            polygon([.init(x: x + side, y: y), .init(x: x + side + depth, y: y - depth), .init(x: x + side + depth, y: y + side - depth), .init(x: x + side, y: y + side)], Color(red: 0.61, green: 0.43, blue: 0.29))
            rect(x + side * 0.43, y, side * 0.16, side, GamePalette.label.opacity(0.6))
            rect(x + side * 0.66, y + side * 0.5, side * 0.25, side * 0.22, GamePalette.label)
            rect(x + side * 0.69, y + side * 0.58, side * 0.19, 1.5, GamePalette.ink)
        }

        // Wall, structural beams and an illuminated loading bay.
        rect(0, 0, 400, 106, GamePalette.ink.opacity(0.22))
        for x in stride(from: 18, to: 400, by: 90) {
            rect(CGFloat(x), 0, 3, 104, GamePalette.label.opacity(0.06))
        }
        rect(265, 3, 114, 108, GamePalette.ink)
        rect(272, 12, 100, 92, .black.opacity(0.2))
        for y in stride(from: 20, to: 100, by: 12) {
            rect(272, CGFloat(y), 100, 2, GamePalette.floor.opacity(0.6))
        }
        rect(265, 3, 114, 3, GamePalette.teal)
        rect(260, 10, 4, 104, GamePalette.orange)
        rect(380, 10, 4, 104, GamePalette.orange)
        context.draw(Text("OUTBOUND  /  01").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(GamePalette.label), at: CGPoint(x: 322, y: 40))
        polygon([.init(x: 0, y: 106), .init(x: 400, y: 106), .init(x: 400, y: 235), .init(x: 0, y: 235)], GamePalette.ink.opacity(0.24))
        for x in stride(from: -80, to: 500, by: 80) {
            line(.init(x: CGFloat(x), y: 235), .init(x: CGFloat(x + 85), y: 106), GamePalette.label.opacity(0.05))
        }
        line(.init(x: 0, y: 204), .init(x: 400, y: 204), GamePalette.label.opacity(0.05))
        // Pallet and reserve cartons.
        rect(24, 95, 77, 8, GamePalette.carton.opacity(0.45))
        parcel(29, 67, 26)
        parcel(65, 70, 23)
        parcel(44, 40, 24)
        // Conveyor runs into the dock; rails and rollers establish depth.
        polygon([.init(x: -20, y: 154), .init(x: 319, y: 102), .init(x: 371, y: 126), .init(x: 0, y: 185)], GamePalette.ink)
        polygon([.init(x: 0, y: 185), .init(x: 371, y: 126), .init(x: 371, y: 140), .init(x: 0, y: 199)], GamePalette.floor)
        for index in 0..<20 {
            let shift = CGFloat((phase * min(12, 2 + automaticRate)).truncatingRemainder(dividingBy: 18))
            let x = CGFloat(index) * 20 + shift - 20
            let y = 155 - x * 0.155
            line(.init(x: x, y: y), .init(x: x + 41, y: y + 23), GamePalette.label.opacity(0.16), width: 4)
        }
        line(.init(x: 0, y: 185), .init(x: 371, y: 126), GamePalette.label.opacity(0.4), width: 3)
        line(.init(x: 0, y: 153), .init(x: 319, y: 103), GamePalette.teal.opacity(0.8), width: 3)
        rect(36, 193, 6, 30, GamePalette.ink)
        rect(285, 148, 6, 34, GamePalette.ink)
        if automaticRate > 0 {
            for index in 0..<3 {
                let travel = CGFloat((phase * min(40, 8 + automaticRate * 5)).truncatingRemainder(dividingBy: 340))
                let x = (CGFloat(index) * 113 + travel).truncatingRemainder(dividingBy: 340)
                parcel(x, 129 - x * 0.155, 25)
            }
        }
        // Each visible operator represents one of the first six workers.
        for index in 0..<min(max(workers, 0), 6) {
            let x = 116 + CGFloat(index) * 38
            let y = 206 - CGFloat(index) * 5
            context.fill(Path(ellipseIn: CGRect(x: x - 4, y: y + 7, width: 26, height: 9)), with: .color(.black.opacity(0.18)))
            rect(x + 2, y + 1, 5, 12, GamePalette.ink)
            rect(x + 11, y + 1, 5, 12, GamePalette.ink)
            context.fill(Path(roundedRect: CGRect(x: x, y: y - 14, width: 19, height: 20), cornerRadius: 5), with: .color(GamePalette.teal))
            rect(x + 7, y - 12, 4, 15, GamePalette.label.opacity(0.65))
            context.fill(Path(ellipseIn: CGRect(x: x + 3, y: y - 26, width: 13, height: 13)), with: .color(GamePalette.carton))
            context.fill(Path(ellipseIn: CGRect(x: x + 1, y: y - 29, width: 17, height: 8)), with: .color(GamePalette.orange))
        }
    }
}
