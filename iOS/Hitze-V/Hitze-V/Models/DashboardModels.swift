import Foundation
import CoreLocation

enum HazardSeverity: Int, Codable, Comparable {
    case none = 0
    
    // Heat
    case heatYellow = 11
    case heatOrange = 12
    case heatRed = 13
    
    // Cold
    case coldYellow = 21
    case coldOrange = 22
    case coldRed = 23

    var level: Int {
        switch self {
        case .none: return 0
        case .heatYellow, .coldYellow: return 1
        case .heatOrange, .coldOrange: return 2
        case .heatRed, .coldRed: return 3
        }
    }
    
    static func < (lhs: HazardSeverity, rhs: HazardSeverity) -> Bool {
        return lhs.level < rhs.level
    }

    static func heat(from level: Int) -> HazardSeverity {
        switch level {
        case 3...: return .heatRed
        case 2: return .heatOrange
        case 1: return .heatYellow
        default: return .none
        }
    }
    
    static func cold(from level: Int) -> HazardSeverity {
        switch level {
        case 3...: return .coldRed
        case 2: return .coldOrange
        case 1: return .coldYellow
        default: return .none
        }
    }
}

struct Worksite: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double

    init(id: UUID = UUID(), name: String, address: String? = nil, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var coordinateLabel: String {
        String(format: "%.4f, %.4f", latitude, longitude)
    }
}

struct DailyForecast: Identifiable, Codable, Hashable {
    var id = UUID()
    let date: Date
    let severity: HazardSeverity
    let apparentTemperatureMax: Double?
    let uvIndexMax: Double?
    let warningTimeRanges: [WarningTimeRange]
}

struct WarningTimeRange: Codable, Hashable {
    let start: Date
    let end: Date
}

struct WorksiteSnapshot {
    let municipalityID: String
    let municipalityName: String
    let severity: HazardSeverity
    let uvIndex: Double?
    let apparentTemperature: Double?
    let forecasts: [DailyForecast]
    let updatedAt: Date
}

enum DashboardDataError: Error, LocalizedError {
    case invalidRequest
    case network(message: String)
    case invalidGeoSphereResponse
    case municipalityNotFound(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Ungueltige Anfrageparameter."
        case .network(let message):
            return "Netzwerkfehler: \(message)"
        case .invalidGeoSphereResponse:
            return "GeoSphere Antwort konnte nicht gelesen werden."
        case .municipalityNotFound(let message):
            return "Gemeinde nicht gefunden: \(message)"
        }
    }
}
