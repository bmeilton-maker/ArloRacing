import SwiftUI
import SwiftData

struct FinishScreenView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.modelContext) private var modelContext

    let onRetry: () -> Void
    let onMenu: () -> Void

    @State private var showNameEntry = false
    @State private var isNewHighScore = false
    @State private var hasSaved = false

    // Staggered stat reveal animation
    @State private var showStat1 = false
    @State private var showStat2 = false
    @State private var showStat3 = false
    @State private var showStat4 = false

    // Crash shake + new-high-score confetti burst
    @State private var shakeAmount: CGFloat = 0
    @State private var runConfetti = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            if runConfetti {
                ConfettiBurst()
            }

            VStack(spacing: 18) {
                headerIcon

                if gameState.isCrashed {
                    Text("CRASHED!")
                        .font(AppTheme.displayFont(40))
                        .foregroundStyle(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                        .modifier(ShakeEffect(animatableData: shakeAmount))
                } else {
                    Text(isNewHighScore ? "NEW HIGH SCORE!" : "RACE COMPLETE!")
                        .font(AppTheme.displayFont(36))
                        .foregroundStyle(
                            isNewHighScore
                            ? AnyShapeStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.white)
                        )
                }

                if let time = gameState.lastRaceTime {
                    Text(time.raceTimeString)
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                } else if gameState.isCrashed {
                    Text("DNF")
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundColor(.red.opacity(0.7))
                }

                if let track = gameState.selectedTrack {
                    Text(track.name)
                        .font(AppTheme.bodyFont(18))
                        .foregroundColor(AppTheme.textSecondary)
                }

                // Stats breakdown with staggered animation
                VStack(spacing: 8) {
                    StatLine(icon: "speedometer", label: "Top Speed", value: "\(Int(gameState.topSpeedReached * 0.5)) mph")
                        .opacity(showStat1 ? 1 : 0)
                        .offset(x: showStat1 ? 0 : 60)

                    StatLine(icon: "arrow.left.arrow.right", label: "Dodged", value: "\(gameState.dodgeCount)")
                        .opacity(showStat2 ? 1 : 0)
                        .offset(x: showStat2 ? 0 : 60)

                    if gameState.maxCombo > 1 {
                        StatLine(icon: "flame.fill", label: "Best Combo", value: "x\(gameState.maxCombo)")
                            .opacity(showStat3 ? 1 : 0)
                            .offset(x: showStat3 ? 0 : 60)
                    }

                    StatLine(icon: "exclamationmark.triangle", label: "Hits", value: "\(gameState.obstaclesHit)")
                        .opacity(showStat4 ? 1 : 0)
                        .offset(x: showStat4 ? 0 : 60)
                }
                .padding(.horizontal, 40)

                HStack(spacing: 20) {
                    Button {
                        onRetry()
                    } label: {
                        MenuButton(title: "RETRY", color: .orange, icon: "arrow.clockwise")
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button {
                        onMenu()
                    } label: {
                        MenuButton(title: "MENU", color: .gray, icon: "house.fill")
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }

            if showNameEntry {
                NameEntryModal(isPresented: $showNameEntry) { name in
                    saveScore(name: name)
                }
            }
        }
        .onAppear {
            checkHighScore()
            animateStats()
            if gameState.isCrashed {
                withAnimation(.easeOut(duration: 0.55)) { shakeAmount = 1 }
            }
        }
    }

    private var headerIcon: some View {
        Image(systemName: gameState.isCrashed ? "exclamationmark.triangle.fill" : (isNewHighScore ? "trophy.fill" : "flag.checkered"))
            .font(.system(size: 32, weight: .bold))
            .foregroundStyle(
                gameState.isCrashed
                ? AnyShapeStyle(Color.red)
                : AnyShapeStyle(AppTheme.titleGradient)
            )
            .shadow(color: (gameState.isCrashed ? Color.red : AppTheme.primary).opacity(0.5), radius: 8, y: 3)
    }

    private func animateStats() {
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) { showStat1 = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.6)) { showStat2 = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.9)) { showStat3 = true }
        withAnimation(.easeOut(duration: 0.4).delay(1.2)) { showStat4 = true }
    }

    private func checkHighScore() {
        guard let trackId = gameState.selectedTrack?.id,
              let time = gameState.lastRaceTime else { return }

        let timeMillis = Int(time * 1000)
        isNewHighScore = LeaderboardManager.isTopScore(trackId: trackId, timeMillis: timeMillis, context: modelContext)

        if isNewHighScore {
            runConfetti = true
            if !hasSaved {
                showNameEntry = true
            }
        }
    }

    private func saveScore(name: String) {
        guard let trackId = gameState.selectedTrack?.id,
              let time = gameState.lastRaceTime,
              let vehicleId = gameState.selectedVehicle?.id else { return }

        let timeMillis = Int(time * 1000)
        let entry = LeaderboardEntry(trackId: trackId, playerName: name, timeMillis: timeMillis, vehicleId: vehicleId)
        LeaderboardManager.addEntry(entry, context: modelContext)
        hasSaved = true
    }
}

// MARK: - Crash impact shake
//
// Classic SwiftUI shake: a GeometryEffect driven by an animatable CGFloat
// running 0→1, with the amplitude tapering off (decay) as it settles.

private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let decay = 1 - animatableData
        let translation = 7 * sin(animatableData * .pi * 8) * decay
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Confetti burst (new high score)
//
// Pure SwiftUI, one-shot: a handful of tiny rectangles fall from the top and
// fade out. No timers — each piece's own `.animation` runs once on appear.

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let xFraction: CGFloat
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
}

private struct ConfettiBurst: View {
    @State private var animate = false

    // @State (not `let`) so the random burst is generated once and survives
    // re-renders of the parent view instead of reshuffling mid-animation.
    @State private var pieces: [ConfettiPiece] = (0..<26).map { _ in
        ConfettiPiece(
            xFraction: CGFloat.random(in: 0.02...0.98),
            color: [Color.orange, .yellow, .red, .white, .green, .blue].randomElement()!,
            width: CGFloat.random(in: 5...9),
            height: CGFloat.random(in: 3...5),
            rotation: Double.random(in: 0...360),
            delay: Double.random(in: 0...0.3),
            duration: Double.random(in: 0.8...1.4)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(piece.color)
                        .frame(width: piece.width, height: piece.height)
                        .rotationEffect(.degrees(animate ? piece.rotation + 220 : piece.rotation))
                        .position(
                            x: geo.size.width * piece.xFraction,
                            y: animate ? geo.size.height + 20 : -16
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: animate)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}

struct StatLine: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.orange)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
        )
    }
}
