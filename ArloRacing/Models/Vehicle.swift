import SwiftUI

struct Vehicle: Identifiable, Hashable {
    let id: String
    let name: String
    let maxSpeed: CGFloat
    let acceleration: CGFloat
    let braking: CGFloat
    let grip: CGFloat
    let spriteBaseName: String
}

let allVehicles: [Vehicle] = [
    Vehicle(id: "sports", name: "Sports Car", maxSpeed: 440, acceleration: 165, braking: 220, grip: 0.9, spriteBaseName: "car_sports"),
    Vehicle(id: "pickup", name: "Pickup Truck", maxSpeed: 352, acceleration: 110, braking: 198, grip: 0.85, spriteBaseName: "car_pickup"),
    Vehicle(id: "monster", name: "Monster Truck", maxSpeed: 308, acceleration: 88, braking: 165, grip: 0.95, spriteBaseName: "car_monster"),
    Vehicle(id: "motorcycle", name: "Motorcycle", maxSpeed: 495, acceleration: 220, braking: 275, grip: 0.7, spriteBaseName: "car_motorcycle"),
]
