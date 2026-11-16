import SwiftUI
import UIKit

struct VehicleSelectView: View {
    @Environment(GameState.self) private var gameState
    let track: Track

    @State private var selectedVehicle: Vehicle = allVehicles[0]
    @State private var selectedColor: Color = .red
    @State private var navigateToRace = false

    private let availableColors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .white, .black]

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            HStack(spacing: 24) {
                vehicleList
                    .frame(width: 180)

                carPreview
                    .frame(width: 210)

                statsAndActions
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .navigationTitle("Select Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToRace) {
            RaceContainerView()
        }
    }

    // MARK: - Vehicle list

    private var vehicleList: some View {
        VStack(spacing: 10) {
            ForEach(allVehicles) { vehicle in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        selectedVehicle = vehicle
                    }
                } label: {
                    HStack {
                        Text(vehicle.name)
                            .font(AppTheme.bodyFont(15, weight: .semibold))
                            .foregroundColor(selectedVehicle.id == vehicle.id ? .white : AppTheme.textSecondary)
                        Spacer()
                        if selectedVehicle.id == vehicle.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 13))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                selectedVehicle.id == vehicle.id
                                ? AnyShapeStyle(LinearGradient(colors: [AppTheme.primary, AppTheme.primaryBright], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.white.opacity(0.05))
                            )
                    )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    // MARK: - Live car preview
    //
    // Renders the actual in-game sprite (CarNode.previewImage) in the
    // player's chosen color. Keyed by vehicle + color so SwiftUI treats a
    // change as a new view and animates the swap.

    private var carPreview: some View {
        VStack(spacing: 10) {
            Text(selectedVehicle.name)
                .font(AppTheme.titleFont(18))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.surface)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.primary.opacity(0.35), lineWidth: 1.5)

                Image(uiImage: CarNode.previewImage(vehicleId: selectedVehicle.id, color: selectedColor, scale: 6))
                    .resizable()
                    .scaledToFit()
                    .padding(22)
                    .id(previewKey)
                    .transition(.scale.combined(with: .opacity))
            }
            .frame(height: 150)
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: previewKey)
        }
    }

    private var previewKey: String {
        "\(selectedVehicle.id)-\(colorKey(selectedColor))"
    }

    private func colorKey(_ color: Color) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%.2f-%.2f-%.2f-%.2f", r, g, b, a)
    }

    // MARK: - Stats, color picker, race button

    private var statsAndActions: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                let maxSpeedNorm = allVehicles.map(\.maxSpeed).max()!
                let maxAccelNorm = allVehicles.map(\.acceleration).max()!
                let maxBrakeNorm = allVehicles.map(\.braking).max()!
                StatBar(label: "Speed", value: selectedVehicle.maxSpeed / maxSpeedNorm, color: .red)
                StatBar(label: "Accel", value: selectedVehicle.acceleration / maxAccelNorm, color: .green)
                StatBar(label: "Brake", value: selectedVehicle.braking / maxBrakeNorm, color: .blue)
                StatBar(label: "Grip", value: selectedVehicle.grip, color: .yellow)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedVehicle.id)

            colorPicker

            Button {
                gameState.selectedTrack = track
                gameState.selectedVehicle = selectedVehicle
                gameState.vehicleColor = selectedColor
                gameState.reset()
                navigateToRace = true
            } label: {
                MenuButton(title: "RACE!", color: AppTheme.primary, icon: "flag.checkered", width: 220, height: 52)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private var colorPicker: some View {
        HStack(spacing: 10) {
            ForEach(availableColors, id: \.self) { color in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        selectedColor = color
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        if selectedColor == color {
                            Circle()
                                .stroke(AppTheme.primaryBright, lineWidth: 3)
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(color == .white || color == .yellow ? .black : .white)
                        }
                    }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

struct StatBar: View {
    let label: String
    let value: CGFloat
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(AppTheme.bodyFont(12, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 44, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.gradient)
                        .frame(width: geo.size.width * min(value, 1.0))
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: value)
                }
            }
            .frame(height: 9)
        }
    }
}
