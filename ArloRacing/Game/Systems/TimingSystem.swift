import Foundation

class TimingSystem {
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStart: Date?
    private var stopped: Bool = false
    private var finalTime: TimeInterval = 0

    var elapsedTime: TimeInterval {
        if stopped { return finalTime }
        guard let start = startTime else { return 0 }
        let raw = Date().timeIntervalSince(start)
        let paused = pauseStart != nil ? Date().timeIntervalSince(pauseStart!) : 0
        return raw - pausedDuration - paused
    }

    var isRunning: Bool {
        return startTime != nil && !stopped && pauseStart == nil
    }

    func start() {
        startTime = Date()
        pausedDuration = 0
        pauseStart = nil
        stopped = false
        finalTime = 0
    }

    func pause() {
        guard pauseStart == nil, !stopped else { return }
        pauseStart = Date()
    }

    func resume() {
        if let ps = pauseStart {
            pausedDuration += Date().timeIntervalSince(ps)
            pauseStart = nil
        }
    }

    func stop() -> TimeInterval {
        finalTime = elapsedTime
        stopped = true
        return finalTime
    }

    func reset() {
        startTime = nil
        pausedDuration = 0
        pauseStart = nil
        stopped = false
        finalTime = 0
    }
}
