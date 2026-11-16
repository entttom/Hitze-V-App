import SwiftUI

/// Colours for the Hitze-V levels. Fills are fixed (they carry meaning), so each fill comes with
/// a foreground that keeps ≥ 4.5:1 contrast in light and dark mode: dark text on yellow and
/// orange, white on red.
extension HazardSeverity {
    var fill: Color {
        switch self {
        case .none: return Color(red: 0.15, green: 0.62, blue: 0.40)
        case .heatYellow: return Color(red: 0.98, green: 0.82, blue: 0.20)
        case .heatOrange: return Color(red: 0.96, green: 0.56, blue: 0.16)
        case .heatRed: return Color(red: 0.75, green: 0.16, blue: 0.14)
        }
    }

    var onFill: Color {
        switch self {
        case .heatYellow, .heatOrange: return Color(red: 0.13, green: 0.09, blue: 0.02)
        case .none, .heatRed: return .white
        }
    }

    /// Distinct shapes per level so yellow and orange differ without colour.
    var symbol: String {
        switch self {
        case .none: return "checkmark.seal.fill"
        case .heatYellow: return "exclamationmark.circle.fill"
        case .heatOrange: return "exclamationmark.triangle.fill"
        case .heatRed: return "exclamationmark.octagon.fill"
        }
    }

    /// Icon tint on neutral (material) backgrounds.
    var iconTint: Color {
        switch self {
        case .none: return Color(red: 0.15, green: 0.62, blue: 0.40)
        case .heatYellow: return Color(red: 0.80, green: 0.60, blue: 0.0)
        case .heatOrange: return Color(red: 0.90, green: 0.45, blue: 0.08)
        case .heatRed: return Color(red: 0.80, green: 0.18, blue: 0.16)
        }
    }
}

enum DashboardPalette {
    static let uvBadgeFill = Color(red: 0.55, green: 0.24, blue: 0.70)
    static let uvIcon = Color(red: 0.93, green: 0.60, blue: 0.10)
    static let apparentIcon = Color(red: 0.90, green: 0.36, blue: 0.30)
    static let neutralIcon = Color.secondary

    /// Darkened brand gradient: white text on every stop stays above 4.5:1.
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.70, green: 0.20, blue: 0.10),
            Color(red: 0.66, green: 0.31, blue: 0.03),
            Color(red: 0.06, green: 0.34, blue: 0.54)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Small capsule showing the level symbol and number, e.g. "⚠︎ Stufe 3".
struct SeverityBadge: View {
    let severity: HazardSeverity
    let copy: Copybook

    var body: some View {
        Label(copy.levelShort(severity.level), systemImage: severity.symbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(severity.onFill)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severity.fill, in: Capsule())
            .accessibilityLabel(copy.severityDescription(severity))
    }
}
