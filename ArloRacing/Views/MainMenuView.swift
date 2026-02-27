import SwiftUI

struct MainMenuView: View {
    @Environment(GameState.self) private var gameState
    @State private var showTrackSelect = false
    @State private var showLeaderboards = false
    @State private var animateTitle = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.15, green: 0.05, blue: 0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Text("ARLO RACING")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 10)
                        .scaleEffect(animateTitle ? 1.0 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateTitle)
                        .padding(.horizontal, 20)

                    VStack(spacing: 16) {
                        NavigationLink(destination: TrackSelectView()) {
                            MenuButton(title: "START RACE", color: .orange)
                        }

                        NavigationLink(destination: LeaderboardView()) {
                            MenuButton(title: "LEADERBOARDS", color: .blue)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 16)
            }
            .onAppear {
                animateTitle = true
                gameState.reset()
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 280, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.gradient)
                    .shadow(color: color.opacity(0.4), radius: 8, y: 4)
            )
    }
}
