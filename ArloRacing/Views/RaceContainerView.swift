import SwiftUI
import SpriteKit

struct RaceContainerView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scene: RaceScene?
    @State private var showPause = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let scene = scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }

                // Pause button
                if !gameState.isRaceComplete && !gameState.isCountingDown && !showPause {
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
                            scene?.cleanup()
                            gameState.reset()
                            createScene(size: geo.size)
                        },
                        onMenu: {
                            scene?.cleanup()
                            dismiss()
                        }
                    )
                }
            }
            .onAppear {
                createScene(size: geo.size)
            }
        }
        .ignoresSafeArea()
        .onDisappear {
            scene?.cleanup()
        }
        .onChange(of: gameState.isRaceComplete) { _, isComplete in
            // The race can finish while the pause overlay is up (finish/crash
            // animations aren't frozen by pause) — never leave both showing.
            if isComplete {
                showPause = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if !gameState.isRaceComplete && !showPause {
                scene?.pauseGame()
                showPause = true
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func createScene(size: CGSize) {
        let newScene = RaceScene(size: size)
        newScene.scaleMode = .resizeFill
        newScene.gameState = gameState
        scene = newScene
    }
}
