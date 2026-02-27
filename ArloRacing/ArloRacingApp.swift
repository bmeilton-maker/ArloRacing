import SwiftUI
import SwiftData

@main
struct ArloRacingApp: App {
    @State private var gameState = GameState()

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environment(gameState)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: LeaderboardEntry.self)
    }
}
