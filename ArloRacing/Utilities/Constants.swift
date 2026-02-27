import Foundation

enum GameConstants {
    static let carScreenXRatio: CGFloat = 0.25
    static let steerSensitivity: CGFloat = 8.0
    static let steerSmoothing: CGFloat = 0.15
    static let leaderboardMaxEntries: Int = 10
    static let laneCount: Int = 5
    static let countdownDuration: TimeInterval = 3.0
    static let slipDuration: TimeInterval = 1.5
    static let recoveryDuration: TimeInterval = 1.0
    static let obstacleSegmentLength: CGFloat = 200
    static let obstacleStartOffset: CGFloat = 500
    static let dodgeDistanceThreshold: CGFloat = 60
    static let dustSpawnInterval: TimeInterval = 0.15
}

enum ZPositions {
    static let background: CGFloat = -100
    static let track: CGFloat = 0
    static let laneMarkers: CGFloat = 5
    static let obstacles: CGFloat = 10
    static let car: CGFloat = 20
    static let effects: CGFloat = 30
    static let hud: CGFloat = 100
}
