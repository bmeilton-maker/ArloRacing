import SwiftUI

struct PauseOverlay: View {
    let onResume: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.35))
                .ignoresSafeArea()

            VStack(spacing: 26) {
                HStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(AppTheme.titleGradient)
                    Text("PAUSED")
                        .font(AppTheme.displayFont(38))
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

                VStack(spacing: 14) {
                    Button {
                        onResume()
                    } label: {
                        MenuButton(title: "RESUME", color: .green, icon: "play.fill")
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button {
                        onQuit()
                    } label: {
                        MenuButton(title: "QUIT TO MENU", color: .red, icon: "xmark.circle.fill")
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }
}
