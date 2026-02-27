import Foundation

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

enum ObstacleType: CaseIterable {
    case cone
    case banana
}

enum OncomingVehicleType: CaseIterable {
    case sedan
    case semi
    case motorcycle
    case dumpTruck

    var speedModifier: CGFloat {
        switch self {
        case .sedan: return 1.0
        case .semi: return 0.7
        case .motorcycle: return 1.4
        case .dumpTruck: return 0.6
        }
    }
}

struct ObstacleData {
    let x: CGFloat
    let lane: Int
    let type: ObstacleType
}

struct OncomingCarData {
    let x: CGFloat
    let lane: Int
    let speed: CGFloat
    let vehicleType: OncomingVehicleType
}

class TrackGenerator {
    private var rng: SeededRandomNumberGenerator

    init(seed: UInt64) {
        rng = SeededRandomNumberGenerator(seed: seed)
    }

    func generateObstacles(density: Float, trackLength: CGFloat, laneCount: Int) -> [ObstacleData] {
        var obstacles: [ObstacleData] = []
        let segmentLength: CGFloat = GameConstants.obstacleSegmentLength

        var x: CGFloat = GameConstants.obstacleStartOffset
        while x < trackLength {
            let randVal = Float(rng.next() % 1000) / 1000.0
            if randVal < density {
                let lane = Int(rng.next() % UInt64(laneCount))
                let typeRand = rng.next() % 2
                let type: ObstacleType = typeRand == 0 ? .cone : .banana
                obstacles.append(ObstacleData(x: x, lane: lane, type: type))
            }
            x += segmentLength
        }
        return obstacles
    }

    func generateOncomingCars(trackLength: CGFloat, laneCount: Int) -> [OncomingCarData] {
        var cars: [OncomingCarData] = []
        // Space them out more than obstacles — every ~800-1200 pts
        let spacing: CGFloat = 800
        var x: CGFloat = 1500 // start further in than obstacles

        while x < trackLength {
            let randVal = Float(rng.next() % 1000) / 1000.0
            if randVal < 0.5 { // ~50% chance per segment
                let lane = Int(rng.next() % UInt64(laneCount))
                let baseSpeed: CGFloat = CGFloat(165 + (rng.next() % 220)) // 165–385 pts/sec
                let typeIndex = Int(rng.next() % UInt64(OncomingVehicleType.allCases.count))
                let vehicleType = OncomingVehicleType.allCases[typeIndex]
                let speed = baseSpeed * vehicleType.speedModifier
                cars.append(OncomingCarData(x: x, lane: lane, speed: speed, vehicleType: vehicleType))
            }
            x += spacing + CGFloat(rng.next() % 400) // vary spacing
        }
        return cars
    }
}
