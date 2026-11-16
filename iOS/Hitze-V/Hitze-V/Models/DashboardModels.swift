import Foundation
import CoreLocation

/// Heat warning severity on the Hitze-V scale (GeoSphere `wlevel` + 1).
nonisolated enum HazardSeverity: Int, Comparable, Sendable {
    case none = 0
    case heatYellow = 2
    case heatOrange = 3
    case heatRed = 4

    var level: Int { rawValue }

    var isHeatWarning: Bool { self != .none }

    static func < (lhs: HazardSeverity, rhs: HazardSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func heat(from level: Int) -> HazardSeverity {
        switch level {
        case 4...: return .heatRed
        case 3: return .heatOrange
        case 2: return .heatYellow
        default: return .none
        }
    }
}

nonisolated struct Worksite: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double
    /// GeoSphere `gemeindenr` (GKZ), whitespace stripped. Nil for worksites stored by older
    /// versions until the next successful fetch fills it in.
    var municipalityID: String?

    init(
        id: UUID = UUID(),
        name: String,
        address: String? = nil,
        latitude: Double,
        longitude: Double,
        municipalityID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.municipalityID = municipalityID
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func normalizedMunicipalityID(_ raw: String) -> String {
        raw.components(separatedBy: .whitespacesAndNewlines).joined()
    }
}

nonisolated struct DailyForecast: Identifiable, Hashable, Sendable {
    /// Start of the Europe/Vienna calendar day.
    let date: Date
    let severity: HazardSeverity
    let apparentTemperatureMax: Double?
    let uvIndexMax: Double?
    let warningTimeRanges: [WarningTimeRange]

    var id: Date { date }
}

nonisolated struct WarningTimeRange: Hashable, Sendable {
    let start: Date
    let end: Date
}

nonisolated struct WorksiteSnapshot: Sendable {
    let municipalityID: String
    /// Nil when GeoSphere returned no name; the UI shows a localized fallback.
    let municipalityName: String?
    let severity: HazardSeverity
    let uvIndex: Double?
    let apparentTemperature: Double?
    let forecasts: [DailyForecast]
    let updatedAt: Date
}

nonisolated enum WorksiteLoadState: Equatable, Sendable {
    case loading
    case loaded
    case failed
}

nonisolated enum DashboardDataError: Error, LocalizedError {
    case invalidRequest
    case network(message: String)
    case invalidGeoSphereResponse
    case municipalityNotFound(message: String)

    // Developer-facing only (logs); the UI maps errors to DashboardUserMessage.
    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Invalid request parameters."
        case .network(let message):
            return "Network error: \(message)"
        case .invalidGeoSphereResponse:
            return "GeoSphere response could not be decoded."
        case .municipalityNotFound(let message):
            return "Municipality not found: \(message)"
        }
    }
}

nonisolated enum ViennaTime {
    static let timeZone = TimeZone(identifier: "Europe/Vienna") ?? .current

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }()

    static func dayKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    static func isToday(_ date: Date, now: Date = Date()) -> Bool {
        calendar.isDate(date, inSameDayAs: now)
    }
}
