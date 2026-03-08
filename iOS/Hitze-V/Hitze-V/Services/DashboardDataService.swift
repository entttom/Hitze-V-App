import Foundation
import CoreLocation

final class DashboardDataService {
    private let urlSession: URLSession
    private let defaultGeoSphereBaseURL = "https://warnungen.zamg.at/wsapp/api/getWarningsForCoords"
    private let openMeteoBaseURL = "https://api.open-meteo.com/v1/forecast"
    private let viennaTimeZone = TimeZone(identifier: "Europe/Vienna") ?? .current

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    private var geoSphereBaseURL: String {
        if AppFeatureFlags.enableCustomGeoSphereURLSetting {
            let configuredURL = UserDefaults.standard.string(forKey: "network.customGeoSphereUrl")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !configuredURL.isEmpty {
                return configuredURL
            }
        }

        return defaultGeoSphereBaseURL
    }

    private var customGeoSphereURL: String? {
        guard AppFeatureFlags.enableCustomGeoSphereURLSetting else {
            return nil
        }

        let configuredURL = UserDefaults.standard.string(forKey: "network.customGeoSphereUrl")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return configuredURL.isEmpty ? nil : configuredURL
    }

    func fetchSnapshot(for coordinate: CLLocationCoordinate2D) async throws -> WorksiteSnapshot {
        async let geoSphere = fetchGeoSphere(for: coordinate)
        async let meteo = fetchOpenMeteo(for: coordinate)

        let geoResult = try await geoSphere
        let meteoResult = try await meteo

        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = viennaTimeZone
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
            let warningTimeRanges = warningTimeRanges(for: targetDate, warnings: geoResult.warnings)
            
            forecasts.append(DailyForecast(
                date: targetDate,
                severity: severity,
                apparentTemperatureMax: tempMax,
                uvIndexMax: uvMax,
                warningTimeRanges: warningTimeRanges
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
        let url: URL
        if let customURL = customGeoSphereURL {
            guard let parsedURL = URL(string: customURL) else {
                throw DashboardDataError.invalidRequest
            }
            url = parsedURL
        } else {
            var components = URLComponents(string: geoSphereBaseURL)
            components?.queryItems = [
                URLQueryItem(name: "lat", value: String(format: "%.6f", coordinate.latitude)),
                URLQueryItem(name: "lon", value: String(format: "%.6f", coordinate.longitude))
            ]

            guard let parsedURL = components?.url else {
                throw DashboardDataError.invalidRequest
            }
            url = parsedURL
        }

        NSLog("GeoSphere request URL: %@", url.absoluteString)
        let (data, response) = try await performGET(url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse {
                let bodyPreview = String(data: data.prefix(600), encoding: .utf8) ?? "<non-utf8 body>"
                NSLog("GeoSphere HTTP failure: %ld for %@", httpResponse.statusCode, url.absoluteString)
                NSLog("GeoSphere HTTP failure body preview: %@", bodyPreview)
            }
            if let municipalityNotFoundMessage = municipalityNotFoundMessage(from: data) {
                throw DashboardDataError.municipalityNotFound(message: municipalityNotFoundMessage)
            }
            throw DashboardDataError.network(message: "GeoSphere HTTP Fehler")
        }

        let decoded: GeoSphereLookupResponse
        do {
            decoded = try JSONDecoder().decode(GeoSphereLookupResponse.self, from: data)
        } catch {
            debugGeoSphereDecodingFailure(error: error, data: data, url: url, response: httpResponse)
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
        let warnings = decoded.properties?.warnings ?? []

        if warnings.isEmpty {
            NSLog("GeoSphere response for municipality %@ contains 0 warnings", municipalityID)
        } else {
            NSLog("GeoSphere response for municipality %@ contains %ld warnings", municipalityID, warnings.count)
        }

        return GeoSphereResolvedState(
            municipalityID: municipalityID,
            municipalityName: municipalityName,
            warnings: warnings
        )
    }

    private func municipalityNotFoundMessage(from data: Data) -> String? {
        guard let decoded = try? JSONDecoder().decode(GeoSphereLookupResponse.self, from: data) else {
            return nil
        }

        guard decoded.type.lowercased() == "error" else {
            return nil
        }

        let message = decoded.msg?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !message.isEmpty else {
            return "Could not find municipal for coords."
        }

        let normalizedMessage = message.lowercased()
        if normalizedMessage.contains("could not find municipal for coords") ||
            normalizedMessage.contains("could not find municipality") ||
            normalizedMessage.contains("municipal for coords") {
            return message
        }

        return nil
    }
    
    private func parseGeosphereTimestamp(_ value: String?) -> Date? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        
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

        let localFormatter = DateFormatter()
        localFormatter.locale = Locale(identifier: "de_AT_POSIX")
        localFormatter.timeZone = viennaTimeZone
        localFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        if let date = localFormatter.date(from: value) {
            return date
        }
        
        return nil
    }

    private func highestHazardSeverity(for targetDate: Date, warnings: [GeoSphereWarning]) -> HazardSeverity {
        let highestHeat = heatWarnings(for: targetDate, warnings: warnings)
            .map(\.level)
            .max() ?? 0

        if highestHeat > 0 {
            return HazardSeverity.heat(from: highestHeat)
        }
        
        return .none
    }

    private func warningTimeRanges(for targetDate: Date, warnings: [GeoSphereWarning]) -> [WarningTimeRange] {
        let calendar = gregorianViennaCalendar()
        let startOfDay = calendar.startOfDay(for: targetDate)
        guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else {
            return []
        }

        return heatWarnings(for: targetDate, warnings: warnings)
            .map { warning in
                WarningTimeRange(
                    start: max(warning.start ?? startOfDay, startOfDay),
                    end: min(warning.end ?? endOfDay, endOfDay)
                )
            }
            .sorted { $0.start < $1.start }
            .reduce(into: [WarningTimeRange]()) { merged, range in
                guard let lastRange = merged.last else {
                    merged.append(range)
                    return
                }

                if range.start > lastRange.end {
                    merged.append(range)
                } else {
                    merged[merged.count - 1] = WarningTimeRange(
                        start: lastRange.start,
                        end: max(lastRange.end, range.end)
                    )
                }
            }
    }

    private func heatWarnings(for targetDate: Date, warnings: [GeoSphereWarning]) -> [DailyHeatWarning] {
        let calendar = gregorianViennaCalendar()
        let startOfTargetDay = calendar.startOfDay(for: targetDate)
        guard let endOfTargetDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfTargetDay) else {
            return []
        }

        return warnings.compactMap { warning in
            let properties = warning.properties
            let startDate = parseGeosphereTimestamp(resolvedWarningStart(properties))
            let endDate = parseGeosphereTimestamp(resolvedWarningEnd(properties))

            let isActiveOnTargetDate: Bool
            switch (startDate, endDate) {
            case let (startDate?, endDate?):
                isActiveOnTargetDate = !(endDate < startOfTargetDay || startDate > endOfTargetDay)
            case let (startDate?, nil):
                isActiveOnTargetDate = startDate <= endOfTargetDay
            case let (nil, endDate?):
                isActiveOnTargetDate = endDate >= startOfTargetDay
            case (nil, nil):
                isActiveOnTargetDate = true
            }

            guard isActiveOnTargetDate, isHeatWarning(properties) else {
                return nil
            }

            let level = resolvedWarningLevel(properties)
            return DailyHeatWarning(level: level, start: startDate, end: endDate)
        }
    }

    private func resolvedWarningStart(_ properties: GeoSphereWarningProperties) -> String? {
        let candidates = [
            properties.start,
            properties.begin,
            properties.rawinfo?.start,
            properties.rawfinfo?.start
        ]

        return candidates.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty }
    }

    private func resolvedWarningEnd(_ properties: GeoSphereWarningProperties) -> String? {
        let candidates = [
            properties.end,
            properties.rawinfo?.end,
            properties.rawfinfo?.end
        ]

        return candidates.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty }
    }

    private func resolvedWarningLevel(_ properties: GeoSphereWarningProperties) -> Int {
        let candidates = [
            properties.warnstufeid,
            properties.wlevel,
            properties.rawinfo?.wlevel,
            properties.rawfinfo?.wlevel
        ]
        .compactMap { $0 }

        return candidates.max() ?? 0
    }

    private func isHeatWarning(_ properties: GeoSphereWarningProperties) -> Bool {
        let typeCandidates = [
            properties.wtype,
            properties.warntypid,
            properties.rawinfo?.wtype,
            properties.rawfinfo?.wtype
        ]
        .compactMap { $0 }

        if !typeCandidates.isEmpty {
            return typeCandidates.contains(6)
        }

        guard let textualType = properties.warningType?.lowercased() else {
            return false
        }

        return textualType.contains("hitze") || textualType.contains("heat")
    }

    private func gregorianViennaCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = viennaTimeZone
        return calendar
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
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            return try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            NSLog("Network transport error for %@: %@", url.absoluteString, error.localizedDescription)
            throw DashboardDataError.network(message: error.localizedDescription)
        }
    }

    private func debugGeoSphereDecodingFailure(
        error: Error,
        data: Data,
        url: URL,
        response: HTTPURLResponse
    ) {
        NSLog("GeoSphere decode failed for URL: %@", url.absoluteString)
        NSLog("GeoSphere HTTP status: %ld", response.statusCode)
        NSLog("GeoSphere decoding error: %@", String(describing: error))

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            NSLog("GeoSphere top-level keys: %@", object.keys.sorted().joined(separator: ", "))

            if let firstKey = object.keys.sorted().first,
               let nestedObject = object[firstKey] as? [String: Any] {
                NSLog(
                    "GeoSphere nested keys for %@: %@",
                    firstKey,
                    nestedObject.keys.sorted().joined(separator: ", ")
                )
            }
        }

        let bodyPreview = String(data: data.prefix(1200), encoding: .utf8) ?? "<non-utf8 body>"
        NSLog("GeoSphere body preview: %@", bodyPreview)
    }
}

private struct DailyHeatWarning {
    let level: Int
    let start: Date?
    let end: Date?
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
    let begin: String?
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
        case begin
        case start
        case end
    }
}

private struct GeoSphereRawInfo: Decodable {
    let wtype: Int?
    let wlevel: Int?
    let start: String?
    let end: String?
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
