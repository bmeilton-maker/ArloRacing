import Foundation

enum TrackTheme: String, CaseIterable {
    case desert
    case forest
    case urban
    case night
    case arctic

    var displayName: String {
        switch self {
        case .desert: return "Desert"
        case .forest: return "Forest"
        case .urban: return "City"
        case .night: return "Night"
        case .arctic: return "Arctic"
        }
    }

    var backgroundColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .desert: return (0.93, 0.79, 0.55)
        case .forest: return (0.25, 0.55, 0.25)
        case .urban: return (0.55, 0.55, 0.60)
        case .night: return (0.10, 0.10, 0.25)
        case .arctic: return (0.85, 0.90, 0.95)
        }
    }

    var roadColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .desert: return (0.75, 0.60, 0.40)
        case .forest: return (0.35, 0.30, 0.25)
        case .urban: return (0.30, 0.30, 0.32)
        case .night: return (0.20, 0.20, 0.25)
        case .arctic: return (0.70, 0.75, 0.80)
        }
    }
}

struct Track: Identifiable, Hashable {
    let id: Int
    let name: String
    let seed: UInt64
    let length: CGFloat
    let obstacleDensity: Float
    let maxSpeedModifier: CGFloat
    let theme: TrackTheme

    static func == (lhs: Track, rhs: Track) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

let allTracks: [Track] = [
    Track(id: 1, name: "Desert Sprint", seed: 12345, length: 15000, obstacleDensity: 0.3, maxSpeedModifier: 1.0, theme: .desert),
    Track(id: 2, name: "Forest Run", seed: 67890, length: 18000, obstacleDensity: 0.4, maxSpeedModifier: 0.95, theme: .forest),
    Track(id: 3, name: "City Streets", seed: 11223, length: 16500, obstacleDensity: 0.5, maxSpeedModifier: 0.9, theme: .urban),
    Track(id: 4, name: "Midnight Mile", seed: 44556, length: 19500, obstacleDensity: 0.45, maxSpeedModifier: 1.05, theme: .night),
    Track(id: 5, name: "Frozen Pass", seed: 77889, length: 21000, obstacleDensity: 0.35, maxSpeedModifier: 0.85, theme: .arctic),
]
