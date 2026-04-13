import Foundation
import Combine

@MainActor
final class MockModeController: ObservableObject {
    static let shared = MockModeController()

    @Published private(set) var isEnabled = false
    private(set) var sessionSeed: UInt64 = MockModeController.makeSeed()

    private init() {}

    func activate() {
        isEnabled = true
        sessionSeed = Self.makeSeed()
    }

    private static func makeSeed() -> UInt64 {
        DispatchTime.now().uptimeNanoseconds ^ UInt64.random(in: .min ... .max)
    }
}

enum MockSnapshotFactory {
    static func makeSnapshot(for worksite: Worksite, sessionSeed: UInt64, now: Date = Date()) -> WorksiteSnapshot {
        var generator = SeededGenerator(seed: seed(for: worksite, sessionSeed: sessionSeed))
        let calendar = gregorianViennaCalendar()

        var daySeverities: [HazardSeverity] = [.heatYellow, .heatOrange, .heatRed, .none]
        daySeverities.shuffle(using: &generator)

        let municipalityID = "mock-\(Int.random(in: 1000 ... 9999, using: &generator))"
        let municipalityName = mockMunicipalityName(using: &generator)
        let forecasts = (0..<4).compactMap { dayOffset -> DailyForecast? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
                return nil
            }

            let severity = daySeverities[dayOffset % daySeverities.count]
            let temperature = apparentTemperature(for: severity, using: &generator)
            let uvIndex = uvIndex(for: severity, using: &generator)
            let warningTimeRanges = warningTimeRanges(
                for: date,
                severity: severity,
                calendar: calendar,
                using: &generator
            )

            return DailyForecast(
                date: date,
                severity: severity,
                apparentTemperatureMax: temperature,
                uvIndexMax: uvIndex,
                warningTimeRanges: warningTimeRanges
            )
        }

        let todayForecast = forecasts.first

        return WorksiteSnapshot(
            municipalityID: municipalityID,
            municipalityName: municipalityName,
            severity: todayForecast?.severity ?? .none,
            uvIndex: todayForecast?.uvIndexMax,
            apparentTemperature: todayForecast?.apparentTemperatureMax,
            forecasts: forecasts,
            updatedAt: now
        )
    }

    private static func seed(for worksite: Worksite, sessionSeed: UInt64) -> UInt64 {
        var seed = sessionSeed
        seed ^= worksite.latitude.bitPattern
        seed ^= worksite.longitude.bitPattern &* 0x9E3779B97F4A7C15

        for byte in worksite.id.uuidString.utf8 {
            seed = seed &* 2862933555777941757 &+ UInt64(byte) &+ 3037000493
        }

        return seed == 0 ? 0xA5A5A5A5A5A5A5A5 : seed
    }

    private static func mockMunicipalityName<T: RandomNumberGenerator>(using generator: inout T) -> String {
        let prefixes = ["Nord", "Sued", "West", "Ost", "Mitte", "Hoch", "Sonn"]
        let suffixes = ["feld", "blick", "dorf", "markt", "berg", "tal", "au"]
        let prefix = prefixes.randomElement(using: &generator) ?? "Mock"
        let suffix = suffixes.randomElement(using: &generator) ?? "stadt"
        return "Mock \(prefix)\(suffix)"
    }

    private static func apparentTemperature<T: RandomNumberGenerator>(
        for severity: HazardSeverity,
        using generator: inout T
    ) -> Double {
        switch severity {
        case .heatYellow:
            return Double.random(in: 30 ... 34, using: &generator)
        case .heatOrange:
            return Double.random(in: 35 ... 39, using: &generator)
        case .heatRed:
            return Double.random(in: 40 ... 44, using: &generator)
        case .none, .coldYellow, .coldOrange, .coldRed:
            return Double.random(in: 24 ... 29, using: &generator)
        }
    }

    private static func uvIndex<T: RandomNumberGenerator>(
        for severity: HazardSeverity,
        using generator: inout T
    ) -> Double {
        switch severity {
        case .heatYellow:
            return Double.random(in: 5.0 ... 6.8, using: &generator)
        case .heatOrange:
            return Double.random(in: 5.6 ... 7.8, using: &generator)
        case .heatRed:
            return Double.random(in: 6.5 ... 9.5, using: &generator)
        case .none, .coldYellow, .coldOrange, .coldRed:
            return Double.random(in: 2.0 ... 4.9, using: &generator)
        }
    }

    private static func warningTimeRanges<T: RandomNumberGenerator>(
        for date: Date,
        severity: HazardSeverity,
        calendar: Calendar,
        using generator: inout T
    ) -> [WarningTimeRange] {
        guard severity != .none else {
            return []
        }

        let startOfDay = calendar.startOfDay(for: date)
        let isAllDay = severity == .heatRed && Bool.random(using: &generator)
        if isAllDay,
           let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) {
            return [WarningTimeRange(start: startOfDay, end: endOfDay)]
        }

        let startHourRange: ClosedRange<Int>
        let durationRange: ClosedRange<Int>

        switch severity {
        case .heatYellow:
            startHourRange = 9 ... 11
            durationRange = 3 ... 5
        case .heatOrange:
            startHourRange = 10 ... 12
            durationRange = 4 ... 6
        case .heatRed:
            startHourRange = 11 ... 13
            durationRange = 5 ... 8
        case .none, .coldYellow, .coldOrange, .coldRed:
            return []
        }

        let startHour = Int.random(in: startHourRange, using: &generator)
        let startMinute = [0, 15, 30, 45].randomElement(using: &generator) ?? 0
        let durationHours = Int.random(in: durationRange, using: &generator)
        let endMinute = [0, 15, 30, 45].randomElement(using: &generator) ?? 0

        guard
            let start = calendar.date(byAdding: DateComponents(hour: startHour, minute: startMinute), to: startOfDay),
            let end = calendar.date(byAdding: DateComponents(hour: startHour + durationHours, minute: endMinute), to: startOfDay)
        else {
            return []
        }

        return [WarningTimeRange(start: start, end: end)]
    }

    private static func gregorianViennaCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Vienna") ?? .current
        return calendar
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}
