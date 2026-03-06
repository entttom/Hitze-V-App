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

        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        var forecasts: [DailyForecast] = []
        
        let targetDates = (0..<4).compactMap { calendar.date(byAdding: .day, value: $0, to: now) }
        
        for (i, targetDate) in targetDates.enumerated() {
            var uvMax: Double?
            var tempMax: Double?
            
            if i < meteoResult.daily.time.count {
                uvMax = meteoResult.daily.uvIndexMax[i]
                tempMax = meteoResult.daily.apparentTemperatureMax[i]
            }
            
            let severity = highestHazardSeverity(for: targetDate, warnings: geoResult.warnings)
            
            forecasts.append(DailyForecast(
                date: targetDate,
                severity: severity,
                apparentTemperatureMax: tempMax,
                uvIndexMax: uvMax
            ))
        }

        let todayForecast = forecasts.first

        return WorksiteSnapshot(
            municipalityID: geoResult.municipalityID,
            municipalityName: geoResult.municipalityName,
            severity: todayForecast?.severity ?? .none,
            uvIndex: todayForecast?.uvIndexMax ?? nil,
            apparentTemperature: todayForecast?.apparentTemperatureMax ?? nil,
            forecasts: forecasts,
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
            print("Decoding err:", error)
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

        return GeoSphereResolvedState(
            municipalityID: municipalityID,
            municipalityName: municipalityName,
            warnings: decoded.properties?.warnings ?? []
        )
    }
    
    private func parseGeosphereTimestamp(_ value: String?) -> Date? {
        guard let value = value else { return nil }
        
        if let timeInterval = TimeInterval(value) {
            // ZamG timestamps are often in milliseconds
            if timeInterval > 100000000000 {
                return Date(timeIntervalSince1970: timeInterval / 1000.0)
            }
            return Date(timeIntervalSince1970: timeInterval)
        }
        
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: value) {
            return date
        }
        
        return nil
    }

    private func highestHazardSeverity(for targetDate: Date, warnings: [GeoSphereWarning]) -> HazardSeverity {
        var highestHeat = 0
        let calendar = Calendar(identifier: .gregorian)
        
        for warning in warnings {
            let properties = warning.properties
            
            // Check if warning falls into the target targetDate
            var isActiveOnTargetDate = true // Fallback to true if we cannot parse
            
            if let startStr = properties.start, let endStr = properties.end {
                // If the strings are not nil, try to parse
                let startDate = parseGeosphereTimestamp(startStr)
                let endDate = parseGeosphereTimestamp(endStr)
                
                if let startDate = startDate, let endDate = endDate {
                    // Start of target day
                    let startOfTargetDay = calendar.startOfDay(for: targetDate)
                    // End of target day
                    guard let endOfTargetDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfTargetDay) else {
                        continue
                    }
                    
                    // Check intersection
                    if endDate < startOfTargetDay || startDate > endOfTargetDay {
                        isActiveOnTargetDate = false
                    }
                }
            }
            
            if !isActiveOnTargetDate {
                continue
            }
            
            guard let type = properties.wtype ?? properties.warntypid ?? properties.rawinfo?.wtype ?? properties.rawfinfo?.wtype else {
                
                // Fallback for textual matching if wtype is missing
                if let textualType = properties.warningType?.lowercased() {
                    let level = properties.warnstufeid ?? properties.wlevel ?? properties.rawinfo?.wlevel ?? properties.rawfinfo?.wlevel ?? 0
                    if textualType.contains("hitze") || textualType.contains("heat") {
                        highestHeat = max(highestHeat, level)
                    }
                }
                continue
            }
            
            let level = properties.warnstufeid ?? properties.wlevel ?? properties.rawinfo?.wlevel ?? properties.rawfinfo?.wlevel ?? 0
            
            // GeoSphere API: 6 = heat, 7 = cold (cold intentionally ignored here)
            if type == 6 {
                highestHeat = max(highestHeat, level)
            }
        }
        
        if highestHeat > 0 {
            return HazardSeverity.heat(from: highestHeat)
        }
        
        return .none
    } 

    private func fetchOpenMeteo(for coordinate: CLLocationCoordinate2D) async throws -> OpenMeteoForecastResponse {
        var components = URLComponents(string: openMeteoBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.6f", coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.6f", coordinate.longitude)),
            URLQueryItem(name: "daily", value: "uv_index_max,apparent_temperature_max"),
            URLQueryItem(name: "timezone", value: "Europe/Vienna"),
            URLQueryItem(name: "forecast_days", value: "4")
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
        return decoded
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
}

private struct GeoSphereResolvedState {
    let municipalityID: String
    let municipalityName: String
    let warnings: [GeoSphereWarning]
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
    let start: String?
    let end: String?

    enum CodingKeys: String, CodingKey {
        case warntypid
        case warnstufeid
        case wtype
        case wlevel
        case rawinfo
        case rawfinfo
        case warningType = "warning_type"
        case start
        case end
    }
}

private struct GeoSphereRawInfo: Decodable {
    let wtype: Int?
    let wlevel: Int?
}

private struct OpenMeteoForecastResponse: Decodable {
    let daily: OpenMeteoDaily
}

private struct OpenMeteoDaily: Decodable {
    let time: [String]
    let uvIndexMax: [Double?]
    let apparentTemperatureMax: [Double?]

    enum CodingKeys: String, CodingKey {
        case time
        case uvIndexMax = "uv_index_max"
        case apparentTemperatureMax = "apparent_temperature_max"
    }
}
