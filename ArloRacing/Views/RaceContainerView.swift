import SwiftUI
import SpriteKit

struct RaceContainerView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scene: RaceScene?
    @State private var showFinish = false
    @State private var showPause = false

    var body: some View {
        ZStack {
            if let scene = scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Pause button
            if !gameState.isRaceComplete && !gameState.isCountingDown {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            scene?.pauseGame()
                            showPause = true
                        } label: {
                            Image(systemName: "pause.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
            }

            // Pause overlay
            if showPause {
                PauseOverlay(
                    onResume: {
                        showPause = false
                        scene?.resumeGame()
                    },
                    onQuit: {
                        showPause = false
                        scene?.cleanup()
                        dismiss()
                    }
                )
            }

            // Finish screen
            if gameState.isRaceComplete {
                FinishScreenView(
                    onRetry: {
                        gameState.isRaceComplete = false
                        scene?.cleanup()
                        createScene()
                    },
                    onMenu: {
                        scene?.cleanup()
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            createScene()
        }
        .onDisappear {
            scene?.cleanup()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if !gameState.isRaceComplete {
                scene?.pauseGame()
                showPause = true
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func createScene() {
        let newScene = RaceScene(size: UIScreen.main.bounds.size)
        newScene.scaleMode = .resizeFill
        newScene.gameState = gameState
        scene = newScene
    }
}
