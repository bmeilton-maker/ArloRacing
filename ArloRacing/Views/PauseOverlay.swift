import SwiftUI

struct PauseOverlay: View {
    let onResume: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Button {
                    onResume()
                } label: {
                    MenuButton(title: "RESUME", color: .green)
                }

                Button {
                    onQuit()
                } label: {
                    MenuButton(title: "QUIT TO MENU", color: .red)
                }
            }
        }
    }
}
