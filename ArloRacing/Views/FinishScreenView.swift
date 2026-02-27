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

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 20) {
                if gameState.isCrashed {
                    Text("CRASHED!")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                } else {
                    Text(isNewHighScore ? "NEW HIGH SCORE!" : "RACE COMPLETE!")
                        .font(.system(size: 36, weight: .black, design: .rounded))
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
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
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
                        MenuButton(title: "RETRY", color: .orange)
                    }

                    Button {
                        onMenu()
                    } label: {
                        MenuButton(title: "MENU", color: .gray)
                    }
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
        }
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

        if isNewHighScore && !hasSaved {
            showNameEntry = true
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
