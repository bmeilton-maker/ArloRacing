import SwiftUI

struct VehicleSelectView: View {
    @Environment(GameState.self) private var gameState
    let track: Track

    @State private var selectedVehicle: Vehicle = allVehicles[0]
    @State private var selectedColor: Color = .red
    @State private var navigateToRace = false

    private let availableColors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .white, .black]

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()

            HStack(spacing: 30) {
                // Vehicle list
                VStack(spacing: 12) {
                    ForEach(allVehicles) { vehicle in
                        Button {
                            selectedVehicle = vehicle
                        } label: {
                            HStack {
                                Text(vehicle.name)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedVehicle.id == vehicle.id ? .orange : .white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedVehicle.id == vehicle.id ? Color.orange.opacity(0.2) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedVehicle.id == vehicle.id ? Color.orange : Color.clear, lineWidth: 2)
                                    )
                            )
                        }
                    }
                }
                .frame(width: 200)

                // Stats
                VStack(spacing: 16) {
                    Text(selectedVehicle.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    VStack(spacing: 8) {
                        let maxSpeedNorm = allVehicles.map(\.maxSpeed).max()!
                        let maxAccelNorm = allVehicles.map(\.acceleration).max()!
                        let maxBrakeNorm = allVehicles.map(\.braking).max()!
                        StatBar(label: "Speed", value: selectedVehicle.maxSpeed / maxSpeedNorm, color: .red)
                        StatBar(label: "Accel", value: selectedVehicle.acceleration / maxAccelNorm, color: .green)
                        StatBar(label: "Brake", value: selectedVehicle.braking / maxBrakeNorm, color: .blue)
                        StatBar(label: "Grip", value: selectedVehicle.grip, color: .yellow)
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedVehicle.id)

                    // Color picker
                    HStack(spacing: 8) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.top, 8)

                    Button {
                        gameState.selectedTrack = track
                        gameState.selectedVehicle = selectedVehicle
                        gameState.vehicleColor = selectedColor
                        gameState.reset()
                        navigateToRace = true
                    } label: {
                        Text("RACE!")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.orange.gradient)
                            )
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(30)

        }
        .navigationTitle("Select Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToRace) {
            RaceContainerView()
        }
    }
}

struct StatBar: View {
    let label: String
    let value: CGFloat
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.gradient)
                        .frame(width: geo.size.width * min(value, 1.0))
                }
            }
            .frame(height: 10)
        }
    }
}
