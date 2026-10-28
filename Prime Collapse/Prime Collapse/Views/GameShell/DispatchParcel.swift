import SwiftUI

struct DispatchParcel: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            func face(_ points: [CGPoint], color: Color) {
                context.fill(Path { path in path.addLines(points); path.closeSubpath() }, with: .color(color))
            }
            face([.init(x: 0, y: h * 0.25), .init(x: w * 0.72, y: h * 0.25), .init(x: w * 0.72, y: h), .init(x: 0, y: h)], color: GamePalette.carton)
            face([.init(x: 0, y: h * 0.25), .init(x: w * 0.28, y: 0), .init(x: w, y: 0), .init(x: w * 0.72, y: h * 0.25)], color: Color(red: 0.88, green: 0.72, blue: 0.51))
            face([.init(x: w * 0.72, y: h * 0.25), .init(x: w, y: 0), .init(x: w, y: h * 0.75), .init(x: w * 0.72, y: h)], color: Color(red: 0.61, green: 0.43, blue: 0.29))
            context.fill(Path(CGRect(x: w * 0.3, y: h * 0.25, width: w * 0.12, height: h * 0.75)), with: .color(GamePalette.label.opacity(0.6)))
            context.fill(Path(CGRect(x: w * 0.48, y: h * 0.6, width: w * 0.18, height: h * 0.16)), with: .color(GamePalette.label))
            context.fill(Path(CGRect(x: w * 0.5, y: h * 0.66, width: w * 0.14, height: 2)), with: .color(GamePalette.ink))
        }
    }
}
