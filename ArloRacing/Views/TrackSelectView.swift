import SwiftUI

struct TrackSelectView: View {
    @Environment(GameState.self) private var gameState
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(allTracks.enumerated()), id: \.element.id) { index, track in
                        NavigationLink(destination: VehicleSelectView(track: track)) {
                            TrackCard(track: track)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.75).delay(Double(index) * 0.07),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Select Track")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { appeared = true }
    }
}

struct TrackCard: View {
    let track: Track

    var body: some View {
        VStack(spacing: 10) {
            TrackSceneThumbnail(theme: track.theme)
                .frame(width: 186, height: 104)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(track.theme.accentColor, lineWidth: 2)
                )
                .shadow(color: track.theme.accentColor.opacity(0.35), radius: 8, y: 4)

            Text(track.name)
                .font(AppTheme.titleFont(16))
                .foregroundColor(.white)
                .lineLimit(1)

            HStack(spacing: 10) {
                chip(icon: "road.lanes", text: "\(Int(track.length / 1500)) mi", tint: AppTheme.textSecondary)
                chip(icon: "exclamationmark.triangle.fill", text: difficultyLabel(track.obstacleDensity), tint: difficultyColor(track.obstacleDensity))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(track.theme.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func chip(icon: String, text: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.06)))
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

// MARK: - Mini scene illustration
//
// Built entirely from the shared per-theme palette in DesignSystem.swift so
// each track card reads as a tiny snapshot of the actual track: sky, a far
// scenery silhouette, a ground strip, and a dashed road band.

private struct TrackSceneThumbnail: View {
    let theme: TrackTheme

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [color(theme.skyTopColor), color(theme.skyHorizonColor)],
                    startPoint: .top, endPoint: .bottom
                )

                HillsShape()
                    .fill(color(theme.sceneryFarColor))
                    .frame(height: h * 0.42)

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(color(theme.groundColor))
                        .frame(height: h * 0.18)
                    Rectangle()
                        .fill(Color.black.opacity(0.55))
                        .frame(height: h * 0.24)
                        .overlay(
                            HStack(spacing: 5) {
                                ForEach(0..<7, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.75))
                                        .frame(width: 8, height: 2.5)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 4)
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func color(_ t: (r: CGFloat, g: CGFloat, b: CGFloat)) -> Color {
        Color(red: t.r, green: t.g, blue: t.b)
    }
}

private struct HillsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height * 0.55))
        p.addCurve(
            to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.15),
            control1: CGPoint(x: rect.width * 0.18, y: rect.height * 0.65),
            control2: CGPoint(x: rect.width * 0.32, y: rect.height * 0.05)
        )
        p.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.5),
            control1: CGPoint(x: rect.width * 0.68, y: rect.height * 0.3),
            control2: CGPoint(x: rect.width * 0.85, y: rect.height * 0.1)
        )
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.closeSubpath()
        return p
    }
}
