import Foundation

extension TimeInterval {
    var raceTimeString: String {
        let totalMillis = Int(self * 1000)
        let minutes = totalMillis / 60000
        let seconds = (totalMillis % 60000) / 1000
        let millis = totalMillis % 1000
        if minutes > 0 {
            return String(format: "%d:%02d.%03d", minutes, seconds, millis)
        }
        return String(format: "%d.%03d", seconds, millis)
    }

    var raceTimeStringShort: String {
        let totalMillis = Int(self * 1000)
        let minutes = totalMillis / 60000
        let seconds = (totalMillis % 60000) / 1000
        let millis = (totalMillis % 1000) / 10
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, millis)
        }
        return String(format: "%d.%02d", seconds, millis)
    }
}

extension Int {
    var millisToRaceTime: String {
        let totalMillis = self
        let minutes = totalMillis / 60000
        let seconds = (totalMillis % 60000) / 1000
        let millis = totalMillis % 1000
        if minutes > 0 {
            return String(format: "%d:%02d.%03d", minutes, seconds, millis)
        }
        return String(format: "%d.%03d", seconds, millis)
    }
}
