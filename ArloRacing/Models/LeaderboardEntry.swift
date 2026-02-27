import Foundation
import SwiftData

@Model
class LeaderboardEntry {
    var id: UUID
    var trackId: Int
    var playerName: String
    var timeMillis: Int
    var vehicleId: String
    var date: Date

    init(trackId: Int, playerName: String, timeMillis: Int, vehicleId: String) {
        self.id = UUID()
        self.trackId = trackId
        self.playerName = playerName
        self.timeMillis = timeMillis
        self.vehicleId = vehicleId
        self.date = Date()
    }
}
