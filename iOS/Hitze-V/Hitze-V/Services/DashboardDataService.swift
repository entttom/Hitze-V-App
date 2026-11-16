import Foundation
import CoreLocation
import os

nonisolated let dashboardLogger = Logger(subsystem: "org.entner.HitzeV", category: "Dashboard")

/// GeoSphere (heat warnings) is required; Open-Meteo (UV, feels-like) is optional so that an
/// Open-Meteo outage can never hide a heat warning.
nonisolated final class DashboardDataService: Sendable {
    static let forecastDayCount = 4

    private let urlSession: URLSession
    private let geoSphereBaseURL = "https://warnungen.zamg.at/wsapp/api/getWarningsForCoords"
    private let openMeteoBaseURL = "https://api.open-meteo.com/v1/forecast"

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func fetchSnapshot(for coordinate: CLLocationCoordinate2D, now: Date = Date()) async throws -> WorksiteSnapshot {
        async let meteo: OpenMeteoForecastResponse? = fetchOpenMeteoIgnoringErrors(for: coordinate)
        let geoSphereData = try await fetchGeoSphereData(for: coordinate)
        let meteoResult = await meteo
        return try Self.makeSnapshot(geoSphereData: geoSphereData, openMeteo: meteoResult, now: now)
    }

    // MARK: - Parsing (static so it can be unit-tested without network)

    static func makeSnapshot(
        geoSphereData: Data,
        openMeteoData: Data?,
        now: Date
    ) throws -> WorksiteSnapshot {
        let meteo = openMeteoData.flatMap { try? JSONDecoder().decode(OpenMeteoForecastResponse.self, from: $0) }
        return try makeSnapshot(geoSphereData: geoSphereData, openMeteo: meteo, now: now)
    }

    private static func makeSnapshot(
        geoSphereData: Data,
        openMeteo: OpenMeteoForecastResponse?,
        now: Date
    ) throws -> WorksiteSnapshot {
        let geo = try parseGeoSphere(geoSphereData)
        let meteoByDay = openMeteo?.daily.valuesByDay() ?? [:]
        let calendar = ViennaTime.calendar
        let today = calendar.startOfDay(for: now)

        let forecasts: [DailyForecast] = (0..<forecastDayCount).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else {
                return nil
            }
            let warnings = heatWarnings(on: day, in: geo.warnings)
            let meteoValues = meteoByDay[ViennaTime.dayKey(for: day)]
            return DailyForecast(
                date: day,
                severity: HazardSeverity.heat(from: warnings.map(\.level).max() ?? 0),
                apparentTemperatureMax: meteoValues?.apparentTemperatureMax,
                uvIndexMax: meteoValues?.uvIndexMax,
                warningTimeRanges: mergedTimeRanges(for: day, warnings: warnings)
            )
        }

        let todayForecast = forecasts.first
        return WorksiteSnapshot(
            municipalityID: geo.municipalityID,
            municipalityName: geo.municipalityName,
            severity: todayForecast?.severity ?? .none,
            uvIndex: todayForecast?.uvIndexMax,
            apparentTemperature: todayForecast?.apparentTemperatureMax,
            forecasts: forecasts,
            updatedAt: now
        )
    }

    private static func parseGeoSphere(_ data: Data) throws -> GeoSphereResolvedState {
        let decoded: GeoSphereLookupResponse
        do {
            decoded = try JSONDecoder().decode(GeoSphereLookupResponse.self, from: data)
        } catch {
            dashboardLogger.error("GeoSphere decode failed: \(String(describing: error), privacy: .public)")
            throw DashboardDataError.invalidGeoSphereResponse
        }

        if decoded.type.lowercased() == "error" {
            throw DashboardDataError.municipalityNotFound(message: decoded.msg ?? "Could not find municipal for coords.")
        }

        guard let municipality = decoded.properties?.location?.properties,
              let rawID = municipality.gemeindenr.value else {
            throw DashboardDataError.invalidGeoSphereResponse
        }
        let municipalityID = Worksite.normalizedMunicipalityID(rawID)
        guard !municipalityID.isEmpty else {
            throw DashboardDataError.invalidGeoSphereResponse
        }

        let name = municipality.name?
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return GeoSphereResolvedState(
            municipalityID: municipalityID,
            municipalityName: (name?.isEmpty == false) ? name : nil,
            warnings: decoded.properties?.warnings ?? []
        )
    }

    private static func heatWarnings(on day: Date, in warnings: [GeoSphereWarning]) -> [DailyHeatWarning] {
        let calendar = ViennaTime.calendar
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
            return []
        }

        return warnings.compactMap { warning in
            let properties = warning.properties
            guard isHeatWarning(properties) else {
                return nil
            }
            let start = parseTimestamp(firstNonEmpty([properties.start, properties.begin, properties.rawinfo?.start, properties.rawfinfo?.start]))
            let end = parseTimestamp(firstNonEmpty([properties.end, properties.rawinfo?.end, properties.rawfinfo?.end]))

            if let start, start >= nextDay { return nil }
            if let end, end <= day { return nil }

            let level = normalizedHeatWarningLevel(warningLevel(properties))
            guard level > 0 else { return nil }
            return DailyHeatWarning(level: level, start: start, end: end)
        }
    }

    private static func mergedTimeRanges(for day: Date, warnings: [DailyHeatWarning]) -> [WarningTimeRange] {
        guard let nextDay = ViennaTime.calendar.date(byAdding: .day, value: 1, to: day) else {
            return []
        }

        return warnings
            .map { WarningTimeRange(start: max($0.start ?? day, day), end: min($0.end ?? nextDay, nextDay)) }
            .sorted { $0.start < $1.start }
            .reduce(into: [WarningTimeRange]()) { merged, range in
                if let last = merged.last, range.start <= last.end {
                    merged[merged.count - 1] = WarningTimeRange(start: last.start, end: max(last.end, range.end))
                } else {
                    merged.append(range)
                }
            }
    }

    private static func firstNonEmpty(_ candidates: [String?]) -> String? {
        candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private static func warningLevel(_ properties: GeoSphereWarningProperties) -> Int {
        [properties.warnstufeid, properties.wlevel, properties.rawinfo?.wlevel, properties.rawfinfo?.wlevel]
            .compactMap { $0 }
            .max() ?? 0
    }

    private static func normalizedHeatWarningLevel(_ geoSphereLevel: Int) -> Int {
        geoSphereLevel > 0 ? min(geoSphereLevel + 1, 4) : 0
    }

    private static func isHeatWarning(_ properties: GeoSphereWarningProperties) -> Bool {
        let typeCandidates = [properties.wtype, properties.warntypid, properties.rawinfo?.wtype, properties.rawfinfo?.wtype]
            .compactMap { $0 }
        if !typeCandidates.isEmpty {
            return typeCandidates.contains(6)
        }
        guard let textualType = properties.warningType?.lowercased() else {
            return false
        }
        return textualType.contains("hitze") || textualType.contains("heat")
    }

    nonisolated(unsafe) private static let isoFormatter = ISO8601DateFormatter()

    private static let localFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = ViennaTime.timeZone
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()

    static func parseTimestamp(_ value: String?) -> Date? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        if let interval = TimeInterval(value) {
            // GeoSphere sends epoch seconds or milliseconds depending on the field.
            return Date(timeIntervalSince1970: interval > 100_000_000_000 ? interval / 1000 : interval)
        }
        return isoFormatter.date(from: value) ?? localFormatter.date(from: value)
    }

    // MARK: - Network

    private func fetchGeoSphereData(for coordinate: CLLocationCoordinate2D) async throws -> Data {
        var components = URLComponents(string: geoSphereBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: Self.coordinateString(coordinate.latitude)),
            URLQueryItem(name: "lon", value: Self.coordinateString(coordinate.longitude))
        ]
        guard let url = components?.url else {
            throw DashboardDataError.invalidRequest
        }

        let (data, response) = try await performGET(url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            dashboardLogger.error("GeoSphere HTTP status \(status, privacy: .public)")
            if let message = Self.municipalityNotFoundMessage(from: data) {
                throw DashboardDataError.municipalityNotFound(message: message)
            }
            throw DashboardDataError.network(message: "GeoSphere HTTP \(status)")
        }
        return data
    }

    private func fetchOpenMeteoIgnoringErrors(for coordinate: CLLocationCoordinate2D) async -> OpenMeteoForecastResponse? {
        var components = URLComponents(string: openMeteoBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: Self.coordinateString(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: Self.coordinateString(coordinate.longitude)),
            URLQueryItem(name: "daily", value: "uv_index_max,apparent_temperature_max"),
            URLQueryItem(name: "timezone", value: "Europe/Vienna"),
            URLQueryItem(name: "forecast_days", value: String(Self.forecastDayCount))
        ]
        guard let url = components?.url else {
            return nil
        }

        do {
            let (data, response) = try await performGET(url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                dashboardLogger.notice("Open-Meteo unavailable; showing heat warnings without UV/feels-like")
                return nil
            }
            return try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
        } catch {
            dashboardLogger.notice("Open-Meteo failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private static func municipalityNotFoundMessage(from data: Data) -> String? {
        guard let decoded = try? JSONDecoder().decode(GeoSphereLookupResponse.self, from: data),
              decoded.type.lowercased() == "error" else {
            return nil
        }
        let message = decoded.msg?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !message.isEmpty else {
            return "Could not find municipal for coords."
        }
        let normalized = message.lowercased()
        if normalized.contains("municipal for coords") || normalized.contains("could not find municipality") {
            return message
        }
        return nil
    }

    private static func coordinateString(_ value: Double) -> String {
        String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), value)
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
            dashboardLogger.error("Network transport error (\(url.host() ?? "-", privacy: .public)): \(error.localizedDescription, privacy: .public)")
            throw DashboardDataError.network(message: error.localizedDescription)
        }
    }
}

private nonisolated struct DailyHeatWarning {
    let level: Int
    let start: Date?
    let end: Date?
}

private nonisolated struct GeoSphereResolvedState {
    let municipalityID: String
    let municipalityName: String?
    let warnings: [GeoSphereWarning]
}

private nonisolated struct GeoSphereLookupResponse: Decodable {
    let type: String
    let msg: String?
    let properties: GeoSphereLookupProperties?
}

private nonisolated struct GeoSphereLookupProperties: Decodable {
    let location: GeoSphereLocation?
    let warnings: [GeoSphereWarning]?
}

private nonisolated struct GeoSphereLocation: Decodable {
    let properties: GeoSphereMunicipality?
}

private nonisolated struct GeoSphereMunicipality: Decodable {
    let gemeindenr: GeoSphereIDValue
    let name: String?
}

private nonisolated struct GeoSphereIDValue: Decodable {
    let value: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = String(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else {
            value = nil
        }
    }
}

private nonisolated struct GeoSphereWarning: Decodable {
    let properties: GeoSphereWarningProperties
}

private nonisolated struct GeoSphereWarningProperties: Decodable {
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
        case warntypid, warnstufeid, wtype, wlevel, rawinfo, rawfinfo, begin, start, end
        case warningType = "warning_type"
    }
}

private nonisolated struct GeoSphereRawInfo: Decodable {
    let wtype: Int?
    let wlevel: Int?
    let start: String?
    let end: String?
}

private nonisolated struct OpenMeteoForecastResponse: Decodable {
    let daily: OpenMeteoDaily
}

private nonisolated struct OpenMeteoDaily: Decodable {
    let time: [String]
    let uvIndexMax: [Double?]?
    let apparentTemperatureMax: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case uvIndexMax = "uv_index_max"
        case apparentTemperatureMax = "apparent_temperature_max"
    }

    struct DayValues {
        let uvIndexMax: Double?
        let apparentTemperatureMax: Double?
    }

    /// Keyed by the `time` entry (yyyy-MM-dd, Europe/Vienna); arrays of unequal length are
    /// tolerated so a short `uv_index_max` never shifts values onto the wrong day.
    func valuesByDay() -> [String: DayValues] {
        var result: [String: DayValues] = [:]
        for (index, day) in time.enumerated() {
            let uv = uvIndexMax.flatMap { index < $0.count ? $0[index] : nil }
            let apparent = apparentTemperatureMax.flatMap { index < $0.count ? $0[index] : nil }
            result[day] = DayValues(uvIndexMax: uv, apparentTemperatureMax: apparent)
        }
        return result
    }
}
