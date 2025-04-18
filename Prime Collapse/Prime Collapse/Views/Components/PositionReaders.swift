import SwiftUI

// Preference key to track view positions
struct ViewPositionKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

// Helper view to track the position of the money value
struct MoneyPositionReader: View {
    @Binding var position: CGPoint
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ViewPositionKey.self, value: getMoneyPosition(in: geometry))
                .onPreferenceChange(ViewPositionKey.self) { position in
                    self.position = position
                }
        }
    }
    
    private func getMoneyPosition(in geometry: GeometryProxy) -> CGPoint {
        // Target the money value's approximate position (the right side of the first row of stat cards)
        let x = geometry.frame(in: .global).midX + 60 // Offset to right card
        let y = geometry.frame(in: .global).minY - 15 // Adjusted higher (was -5)
        return CGPoint(x: x, y: y)
    }
}

// Helper view to track the position of the workers value
struct WorkersPositionReader: View {
    @Binding var position: CGPoint
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ViewPositionKey.self, value: getWorkersPosition(in: geometry))
                .onPreferenceChange(ViewPositionKey.self) { position in
                    self.position = position
                }
        }
    }
    
    private func getWorkersPosition(in geometry: GeometryProxy) -> CGPoint {
        // Target the workers value's approximate position (the left side of the second row of stat cards)
        let x = geometry.frame(in: .global).midX - 60 // Offset to left card
        let y = geometry.frame(in: .global).minY + 10 // Adjusted higher (was 20)
        return CGPoint(x: x, y: y)
    }
} 