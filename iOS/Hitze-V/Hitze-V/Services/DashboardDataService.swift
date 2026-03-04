import Foundation
import CoreLocation

final class DashboardDataService {
    private let urlSession: URLSession
    private let geosphereBaseURL = "https://warnungen.zamg.at/wsapp/api/getWarningsForCoords"
    private let openMeteoBaseURL = "https://api.open-meteo.com/v1/forecast"

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func fetchSnapshot(for coordinate: CLLocationCoordinate2D) async throws -> WorksiteSnapshot {
        async let geoSphere = fetchGeoSphere(for: coordinate)
        async let meteo = fetchOpenMeteo(for: coordinate)

        let geoResult = try await geoSphere
        let meteoResult = try await meteo

        return WorksiteSnapshot(
            municipalityID: geoResult.municipalityID,
            municipalityName: geoResult.municipalityName,
            severity: geoResult.severity,
            uvIndex: meteoResult.uvIndex,
            apparentTemperature: meteoResult.apparentTemperature,
            updatedAt: Date()
        )
    }

    private func fetchGeoSphere(for coordinate: CLLocationCoordinate2D) async throws -> GeoSphereResolvedState {
        var components = URLComponents(string: geosphereBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.6f", coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(format: "%.6f", coordinate.longitude))
        ]

        guard let url = components?.url else {
            throw DashboardDataError.invalidRequest
        }

        let (data, response) = try await performGET(url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DashboardDataError.network(message: "GeoSphere HTTP Fehler")
        }

        let decoded: GeoSphereLookupResponse
        do {
            decoded = try JSONDecoder().decode(GeoSphereLookupResponse.self, from: data)
        } catch {
            throw DashboardDataError.invalidGeoSphereResponse
        }

        if decoded.type.lowercased() == "error" {
            throw DashboardDataError.municipalityNotFound(
                message: decoded.msg ?? "Could not find municipal for coords."
            )
        }

        guard let municipality = decoded.properties?.location?.properties,
              let municipalityID = municipality.gemeindenr.value,
              !municipalityID.isEmpty else {
            throw DashboardDataError.invalidGeoSphereResponse
        }

        let municipalityName = municipality.name ?? "Gemeinde \(municipalityID)"
        let severity = highestHeatSeverity(warnings: decoded.properties?.warnings ?? [])

        return GeoSphereResolvedState(
            municipalityID: municipalityID,
            municipalityName: municipalityName,
            severity: severity
        )
    }

    private func highestHeatSeverity(warnings: [GeoSphereWarning]) -> HeatSeverity {
        let levels = warnings.compactMap { warning -> Int? in
            let properties = warning.properties
            if !isHeatWarning(properties) {
                return nil
            }

            if let level = properties.warnstufeid {
                return level
            }

            if let level = properties.wlevel {
                return level
            }

            if let level = properties.rawinfo?.wlevel {
                return level
            }

            return properties.rawfinfo?.wlevel
        }

        return HeatSeverity.from(level: levels.max() ?? 0)
    }

    private func isHeatWarning(_ properties: GeoSphereWarningProperties) -> Bool {
        if let type = properties.warntypid, type == 6 {
            return true
        }

        if let type = properties.wtype, type == 6 {
            return true
        }

        if let type = properties.rawinfo?.wtype, type == 6 {
            return true
        }

        if let type = properties.rawfinfo?.wtype, type == 6 {
            return true
        }

        if let textualType = properties.warningType?.lowercased(), textualType.contains("hitze") || textualType.contains("heat") {
            return true
        }

        return false
    }

    private func fetchOpenMeteo(for coordinate: CLLocationCoordinate2D) async throws -> OpenMeteoResolvedState {
        var components = URLComponents(string: openMeteoBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.6f", coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.6f", coordinate.longitude)),
            URLQueryItem(name: "hourly", value: "uv_index,apparent_temperature"),
            URLQueryItem(name: "timezone", value: "Europe/Vienna")
        ]

        guard let url = components?.url else {
            throw DashboardDataError.invalidRequest
        }

        let (data, response) = try await performGET(url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DashboardDataError.network(message: "Open-Meteo HTTP Fehler")
        }

        let decoded = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
        return pickNearestHourlyPoint(from: decoded.hourly)
    }

    private func pickNearestHourlyPoint(from hourly: OpenMeteoHourly) -> OpenMeteoResolvedState {
        let count = min(hourly.time.count, hourly.uvIndex.count, hourly.apparentTemperature.count)
        guard count > 0 else {
            return OpenMeteoResolvedState(uvIndex: nil, apparentTemperature: nil)
        }

        var bestIndex = 0
        var bestDistance = Double.greatestFiniteMagnitude
        let now = Date()

        for index in 0..<count {
            guard let date = Self.hourDateFormatter.date(from: hourly.time[index]) else {
                continue
            }

            let distance = abs(date.timeIntervalSince(now))
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }

        return OpenMeteoResolvedState(
            uvIndex: hourly.uvIndex[bestIndex],
            apparentTemperature: hourly.apparentTemperature[bestIndex]
        )
    }

    private func performGET(_ url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        do {
            return try await urlSession.data(for: request)
        } catch {
            throw DashboardDataError.network(message: error.localizedDescription)
        }
    }

    private static let hourDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "Europe/Vienna")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

private struct GeoSphereResolvedState {
    let municipalityID: String
    let municipalityName: String
    let severity: HeatSeverity
}

private struct OpenMeteoResolvedState {
    let uvIndex: Double?
    let apparentTemperature: Double?
}

private struct GeoSphereLookupResponse: Decodable {
    let type: String
    let msg: String?
    let properties: GeoSphereLookupProperties?
}

private struct GeoSphereLookupProperties: Decodable {
    let location: GeoSphereLocation?
    let warnings: [GeoSphereWarning]?
}

private struct GeoSphereLocation: Decodable {
    let properties: GeoSphereMunicipality?
}

private struct GeoSphereMunicipality: Decodable {
    let gemeindenr: GeoSphereIDValue
    let name: String?
}

private struct GeoSphereIDValue: Decodable {
    let value: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = String(intValue)
            return
        }

        if let stringValue = try? container.decode(String.self) {
            value = stringValue
            return
        }

        value = nil
    }
}

private struct GeoSphereWarning: Decodable {
    let properties: GeoSphereWarningProperties
}

private struct GeoSphereWarningProperties: Decodable {
    let warntypid: Int?
    let warnstufeid: Int?
    let wtype: Int?
    let wlevel: Int?
    let rawinfo: GeoSphereRawInfo?
    let rawfinfo: GeoSphereRawInfo?
    let warningType: String?

    enum CodingKeys: String, CodingKey {
        case warntypid
        case warnstufeid
        case wtype
        case wlevel
        case rawinfo
        case rawfinfo
        case warningType = "warning_type"
    }
}

private struct GeoSphereRawInfo: Decodable {
    let wtype: Int?
    let wlevel: Int?
}

private struct OpenMeteoForecastResponse: Decodable {
    let hourly: OpenMeteoHourly
}

private struct OpenMeteoHourly: Decodable {
    let time: [String]
    let uvIndex: [Double?]
    let apparentTemperature: [Double?]

    enum CodingKeys: String, CodingKey {
        case time
        case uvIndex = "uv_index"
        case apparentTemperature = "apparent_temperature"
    }
}
