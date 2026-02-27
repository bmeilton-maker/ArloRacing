import SwiftUI

struct TrackSelectView: View {
    @Environment(GameState.self) private var gameState

    private let themeColors: [TrackTheme: Color] = [
        .desert: Color(red: 0.93, green: 0.79, blue: 0.55),
        .forest: Color(red: 0.25, green: 0.55, blue: 0.25),
        .urban: Color(red: 0.55, green: 0.55, blue: 0.60),
        .night: Color(red: 0.15, green: 0.15, blue: 0.35),
        .arctic: Color(red: 0.75, green: 0.85, blue: 0.95),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(allTracks) { track in
                        NavigationLink(destination: VehicleSelectView(track: track)) {
                            TrackCard(track: track, color: themeColors[track.theme] ?? .gray)
                        }
                    }
                }
                .padding(.horizontal, 30)
            }
        }
        .navigationTitle("Select Track")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct TrackCard: View {
    let track: Track
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.gradient)
                .frame(width: 180, height: 120)
                .overlay(
                    Text(track.theme.displayName.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                )

            Text(track.name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            HStack(spacing: 16) {
                Label("\(Int(track.length / 1500)) mi", systemImage: "road.lanes")
                    .font(.caption)
                    .foregroundColor(.gray)

                Label(difficultyLabel(track.obstacleDensity), systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(difficultyColor(track.obstacleDensity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.15))
        )
    }

    private func difficultyLabel(_ density: Float) -> String {
        if density < 0.35 { return "Easy" }
        if density < 0.45 { return "Medium" }
        return "Hard"
    }

    private func difficultyColor(_ density: Float) -> Color {
        if density < 0.35 { return .green }
        if density < 0.45 { return .yellow }
        return .red
    }
}
