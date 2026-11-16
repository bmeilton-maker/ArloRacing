import Foundation

/// Accumulates race time from the same delta-time steps that drive the
/// simulation, so the clock and the world can never disagree (wall-clock
/// timing would penalize devices that drop frames). Pausing is implicit:
/// the scene simply doesn't tick while paused.
class TimingSystem {
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var isRunning: Bool = false

    func start() {
        elapsedTime = 0
        isRunning = true
    }

    func tick(_ deltaTime: TimeInterval) {
        guard isRunning else { return }
        elapsedTime += deltaTime
    }

    @discardableResult
    func stop() -> TimeInterval {
        isRunning = false
        return elapsedTime
    }

    func reset() {
        elapsedTime = 0
        isRunning = false
    }
}
