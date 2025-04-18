import SwiftUI

// Game notification view component
struct GameNotificationView: View {
    let notification: GameNotification
    @State private var isShowing = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(notification.color)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(notification.message)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(notification.color.opacity(0.7), lineWidth: 1.5)
                )
        )
        .opacity(isShowing ? 1.0 : 0.0)
        .offset(y: isShowing ? 0 : -20)
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isShowing = true
            }
        }
    }
} 