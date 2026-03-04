import Foundation
import CoreLocation

enum HeatSeverity: Int {
    case none = 0
    case yellow = 1
    case orange = 2
    case red = 3

    var title: String {
        switch self {
        case .none:
            return "Gruen"
        case .yellow:
            return "Gelb"
        case .orange:
            return "Orange"
        case .red:
            return "Rot"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .none:
            return "Keine Hitzewarnung"
        case .yellow:
            return "Hitzewarnung gelb"
        case .orange:
            return "Hitzewarnung orange"
        case .red:
            return "Hitzewarnung rot"
        }
    }

    static func from(level: Int) -> HeatSeverity {
        switch level {
        case 3...:
            return .red
        case 2:
            return .orange
        case 1:
            return .yellow
        default:
            return .none
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

struct WorksiteSnapshot {
    let municipalityID: String
    let municipalityName: String
    let severity: HeatSeverity
    let uvIndex: Double?
    let apparentTemperature: Double?
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
