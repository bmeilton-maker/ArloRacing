import SwiftUI

@Observable
class GameState {
    var selectedTrack: Track?
    var selectedVehicle: Vehicle?
    var vehicleColor: Color = .red
    var lastRaceTime: TimeInterval?
    var isRaceComplete: Bool = false
    var isCrashed: Bool = false
    var isPaused: Bool = false
    var isCountingDown: Bool = false

    // Race stats for finish screen
    var dodgeCount: Int = 0
    var maxCombo: Int = 0
    var obstaclesHit: Int = 0
    var topSpeedReached: CGFloat = 0

    func reset() {
        lastRaceTime = nil
        isRaceComplete = false
        isCrashed = false
        isPaused = false
        isCountingDown = false
        dodgeCount = 0
        maxCombo = 0
        obstaclesHit = 0
        topSpeedReached = 0
    }
}
