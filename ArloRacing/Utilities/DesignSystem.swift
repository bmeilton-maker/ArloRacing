import SwiftUI

// MARK: - App-wide design tokens
//
// Single source of truth for the menu/UI look. The game's identity:
// rounded black typography, orange→yellow heat gradient, deep night-blue
// backdrops, playful hand-drawn vector art.

enum AppTheme {
    // Core palette
    static let primary = Color.orange
    static let primaryBright = Color.yellow
    static let backgroundTop = Color(red: 0.08, green: 0.09, blue: 0.18)
    static let backgroundBottom = Color(red: 0.13, green: 0.06, blue: 0.26)
    static let surface = Color(white: 0.15)
    static let surfaceElevated = Color(white: 0.19)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.72)
    static let textTertiary = Color(white: 0.5)

    static let titleGradient = LinearGradient(
        colors: [.orange, .yellow],
        startPoint: .leading, endPoint: .trailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top, endPoint: .bottom
    )

    // Typography — everything rounded, weights carry the hierarchy
    static func displayFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static func titleFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func bodyFont(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func monoFont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Shared button treatment

/// Squishy arcade button: scales down on press with a snappy spring.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Per-theme scene palette (menus + in-game share these)

extension TrackTheme {
    /// SwiftUI accent used on menu cards and chips for this theme.
    var accentColor: Color {
        switch self {
        case .desert: return Color(red: 0.95, green: 0.65, blue: 0.25)
        case .forest: return Color(red: 0.35, green: 0.72, blue: 0.35)
        case .urban:  return Color(red: 0.55, green: 0.65, blue: 0.75)
        case .night:  return Color(red: 0.45, green: 0.40, blue: 0.90)
        case .arctic: return Color(red: 0.55, green: 0.78, blue: 0.95)
        }
    }

    /// Sky gradient, top → horizon (r, g, b in 0...1).
    var skyTopColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .desert: return (0.45, 0.65, 0.90)
        case .forest: return (0.50, 0.75, 0.92)
        case .urban:  return (0.55, 0.62, 0.72)
        case .night:  return (0.03, 0.03, 0.12)
        case .arctic: return (0.65, 0.80, 0.95)
        }
    }

    var skyHorizonColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .desert: return (0.98, 0.80, 0.55)
        case .forest: return (0.85, 0.92, 0.75)
        case .urban:  return (0.90, 0.75, 0.60)
        case .night:  return (0.18, 0.10, 0.35)
        case .arctic: return (0.90, 0.95, 1.00)
        }
    }

    /// Far scenery silhouette (mountains / skyline / treeline).
    var sceneryFarColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .desert: return (0.80, 0.58, 0.38)
        case .forest: return (0.18, 0.40, 0.22)
        case .urban:  return (0.35, 0.38, 0.45)
        case .night:  return (0.08, 0.07, 0.20)
        case .arctic: return (0.72, 0.80, 0.90)
        }
    }

    /// Near scenery (dunes / bushes / buildings / drifts) — darker than far.
    var sceneryNearColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .desert: return (0.70, 0.48, 0.28)
        case .forest: return (0.12, 0.30, 0.15)
        case .urban:  return (0.22, 0.24, 0.30)
        case .night:  return (0.05, 0.04, 0.14)
        case .arctic: return (0.60, 0.70, 0.82)
        }
    }

    /// Grass/ground strip between road and scenery.
    var groundColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .desert: return (0.88, 0.72, 0.45)
        case .forest: return (0.28, 0.50, 0.25)
        case .urban:  return (0.45, 0.45, 0.48)
        case .night:  return (0.10, 0.09, 0.20)
        case .arctic: return (0.82, 0.88, 0.94)
        }
    }

    /// Road shoulder/edge line color.
    var roadEdgeColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .desert: return (0.95, 0.90, 0.75)
        case .forest: return (0.90, 0.90, 0.85)
        case .urban:  return (0.95, 0.95, 0.95)
        case .night:  return (0.85, 0.85, 0.60)
        case .arctic: return (0.45, 0.50, 0.58)
        }
    }

    /// Celestial body: sun position/color, or moon for night.
    var celestialColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .night: return (0.92, 0.92, 0.85) // moon
        case .urban: return (1.00, 0.85, 0.60) // hazy sun
        default:     return (1.00, 0.92, 0.55) // sun
        }
    }
}
