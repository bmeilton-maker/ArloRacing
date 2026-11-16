import SwiftUI

struct MainMenuView: View {
    @Environment(GameState.self) private var gameState
    @State private var animateTitle = false
    @State private var breathe = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                MenuBackdrop()

                VStack(spacing: 22) {
                    Spacer()

                    titleView

                    VStack(spacing: 14) {
                        NavigationLink(destination: TrackSelectView()) {
                            MenuButton(title: "START RACE", color: AppTheme.primary, icon: "flag.checkered")
                        }
                        .buttonStyle(PressableButtonStyle())

                        NavigationLink(destination: LeaderboardView()) {
                            MenuButton(title: "LEADERBOARDS", color: .blue, icon: "trophy.fill")
                        }
                        .buttonStyle(PressableButtonStyle())
                    }

                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .onAppear {
                gameState.reset()
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    animateTitle = true
                }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(0.9)) {
                    breathe = true
                }
            }
        }
    }

    private var titleView: some View {
        Text("ARLO RACING")
            .font(AppTheme.displayFont(46))
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .foregroundStyle(AppTheme.titleGradient)
            .shadow(color: .black.opacity(0.45), radius: 1, y: 2)
            .shadow(color: AppTheme.primary.opacity(0.55), radius: animateTitle ? 16 : 4)
            .scaleEffect((animateTitle ? 1.0 : 0.8) * (breathe ? 1.035 : 1.0))
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateTitle)
            .padding(.horizontal, 20)
    }
}

// MARK: - Animated backdrop
//
// Low-opacity twinkling stars + slow diagonal speed-line streaks drifting
// across the menu behind the title/buttons. Purely decorative — no hit
// testing, so it never interferes with taps.

private struct MenuBackdrop: View {
    @State private var driftPhase = false

    private struct Star {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let delay: Double
        let duration: Double
    }

    // @State (not `let`) so the random layout is generated once and
    // survives re-renders of the parent view instead of reshuffling.
    @State private var stars: [Star] = (0..<16).map { _ in
        Star(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 1.4...3.0),
            delay: Double.random(in: 0...2),
            duration: Double.random(in: 1.6...3.2)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<stars.count, id: \.self) { i in
                    let s = stars[i]
                    Circle()
                        .fill(Color.white)
                        .frame(width: s.size, height: s.size)
                        .position(x: geo.size.width * s.x, y: geo.size.height * s.y)
                        .opacity(driftPhase ? 0.8 : 0.15)
                        .animation(
                            .easeInOut(duration: s.duration).repeatForever(autoreverses: true).delay(s.delay),
                            value: driftPhase
                        )
                }

                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary.opacity(0), AppTheme.primary.opacity(0.20), AppTheme.primary.opacity(0)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.55, height: 3)
                        .rotationEffect(.degrees(-24))
                        .offset(
                            x: driftPhase ? geo.size.width * 0.85 : -geo.size.width * 0.95,
                            y: geo.size.height * (CGFloat(i) / 5.0) - geo.size.height * 0.15
                        )
                        .animation(
                            .linear(duration: Double(6 + i)).repeatForever(autoreverses: false).delay(Double(i) * 0.6),
                            value: driftPhase
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { driftPhase = true }
    }
}

// MARK: - Shared button treatment
//
// Used by MainMenuView, FinishScreenView, and PauseOverlay. `icon`, `width`,
// and `height` are optional so every existing `MenuButton(title:color:)`
// call site keeps compiling unchanged.

struct MenuButton: View {
    let title: String
    let color: Color
    var icon: String? = nil
    var width: CGFloat = 280
    var height: CGFloat = 56

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
            }
            Text(title)
                .font(AppTheme.titleFont(20))
        }
        .foregroundColor(.white)
        .frame(width: width, height: height)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [color.opacity(0.88), color], startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.32), Color.white.opacity(0)], startPoint: .top, endPoint: .center))
                    .padding(2)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
        )
        .shadow(color: color.opacity(0.45), radius: 10, y: 5)
    }
}
