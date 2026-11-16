import Foundation

nonisolated enum PushEvent: String, Sendable {
    case new
    case escalated
    case updated
    case test
}

nonisolated struct PushDay: Decodable, Equatable, Sendable {
    let date: String
    let level: Int
    let start: String
    let end: String

    init(date: String, level: Int, start: String, end: String) {
        self.date = date
        self.level = level
        self.start = start
        self.end = end
    }

    private enum CodingKeys: String, CodingKey {
        case date, level, start, end
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        level = try container.decode(Int.self, forKey: .level)
        start = try container.decodeIfPresent(String.self, forKey: .start) ?? ""
        end = try container.decodeIfPresent(String.self, forKey: .end) ?? ""
    }
}

nonisolated struct RenderedPush: Equatable, Sendable {
    let title: String
    let body: String
}

nonisolated enum PushRenderError: Error, Equatable {
    case copyFileMissing
    case noLanguageAvailable
    case unknownEvent(String)
    case missingField(String)
    case invalidDays
    case noDays
    case invalidDate(String)
    case invalidTimestamp(String)
    case missingLevelName(Int)
}

nonisolated struct PushLanguageCopy: Decodable, Sendable {
    let title: String
    let titleEscalated: String
    let titleUpdated: String
    let titleTest: String
    let levelNames: [String: String]
    let dayToday: String
    let dayTomorrow: String
    let weekdays: [String]
    let allDay: String
    let timeRange: String
    let bodyNew: String
    let bodyEscalated: String
    let bodyUpdated: String
    let bodyTodayTomorrow: String
    let bodyTest: String
}

nonisolated struct PushCopy: Decodable, Sendable {
    let fallbackLanguage: String
    /// Only complete languages; an incomplete entry is skipped so it falls back instead of
    /// breaking every language.
    let languages: [String: PushLanguageCopy]

    private enum CodingKeys: String, CodingKey {
        case fallbackLanguage, languages
    }

    private struct LanguageKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(fallbackLanguage: String, languages: [String: PushLanguageCopy]) {
        self.fallbackLanguage = fallbackLanguage
        self.languages = languages
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fallbackLanguage = try container.decode(String.self, forKey: .fallbackLanguage)
        let languagesContainer = try container.nestedContainer(keyedBy: LanguageKey.self, forKey: .languages)
        var languages: [String: PushLanguageCopy] = [:]
        for key in languagesContainer.allKeys {
            if let copy = try? languagesContainer.decode(PushLanguageCopy.self, forKey: key),
               copy.weekdays.count == 7 {
                languages[key.stringValue] = copy
            }
        }
        self.languages = languages
    }
}

/// Renders v2 push title/body exactly as described in docs/push-contract-v2.md.
nonisolated struct PushCopyRenderer: Sendable {
    static let resourceName = "push-copy"

    let copy: PushCopy

    init(copy: PushCopy) {
        self.copy = copy
    }

    init(data: Data) throws {
        copy = try JSONDecoder().decode(PushCopy.self, from: data)
    }

    init(bundle: Bundle) throws {
        guard let url = bundle.url(forResource: Self.resourceName, withExtension: "json") else {
            throw PushRenderError.copyFileMissing
        }
        try self.init(data: Data(contentsOf: url))
    }

    /// The copy for `languageCode`, or for `fallbackLanguage` when that language is unknown
    /// or not (yet) in the copy file.
    func languageCopy(for languageCode: String?) throws -> (code: String, copy: PushLanguageCopy) {
        if let languageCode, let languageCopy = copy.languages[languageCode] {
            return (languageCode, languageCopy)
        }
        if let languageCopy = copy.languages[copy.fallbackLanguage] {
            return (copy.fallbackLanguage, languageCopy)
        }
        throw PushRenderError.noLanguageAvailable
    }

    func render(
        event: PushEvent,
        name: String,
        days: [PushDay],
        languageCode: String?,
        now: Date
    ) throws -> RenderedPush {
        let strings = try languageCopy(for: languageCode).copy

        let title: String
        switch event {
        case .new: title = strings.title
        case .escalated: title = strings.titleEscalated
        case .updated: title = strings.titleUpdated
        case .test: title = strings.titleTest
        }

        if event == .test {
            return RenderedPush(title: title, body: Self.fill(strings.bodyTest, ["name": name]))
        }

        guard let first = days.first else {
            throw PushRenderError.noDays
        }

        if days.count == 2, event != .updated {
            let second = days[1]
            let body = Self.fill(strings.bodyTodayTomorrow, [
                "name": name,
                "level1": String(first.level),
                "levelName1": try levelName(first.level, strings),
                "time1": try time(of: first, strings),
                "level2": String(second.level),
                "levelName2": try levelName(second.level, strings),
                "time2": try time(of: second, strings)
            ])
            return RenderedPush(title: title, body: body)
        }

        let template: String
        switch event {
        case .new: template = strings.bodyNew
        case .escalated: template = strings.bodyEscalated
        case .updated, .test: template = strings.bodyUpdated
        }

        let body = Self.fill(template, [
            "day": try dayLabel(first.date, now: now, strings),
            "name": name,
            "level": String(first.level),
            "levelName": try levelName(first.level, strings),
            "time": try time(of: first, strings)
        ])
        return RenderedPush(title: title, body: body)
    }

    /// Renders the FCM data payload (`v`, `event`, `name`, `days`) of a v2 message.
    func render(userInfo: [AnyHashable: Any], languageCode: String?, now: Date) throws -> RenderedPush {
        guard let rawEvent = userInfo["event"] as? String else {
            throw PushRenderError.missingField("event")
        }
        guard let event = PushEvent(rawValue: rawEvent) else {
            throw PushRenderError.unknownEvent(rawEvent)
        }
        guard let name = userInfo["name"] as? String else {
            throw PushRenderError.missingField("name")
        }
        let days: [PushDay]
        if let rawDays = userInfo["days"] as? String {
            days = try Self.decodeDays(rawDays)
        } else if event == .test {
            days = []
        } else {
            throw PushRenderError.missingField("days")
        }
        return try render(event: event, name: name, days: days, languageCode: languageCode, now: now)
    }

    static func decodeDays(_ json: String) throws -> [PushDay] {
        guard let data = json.data(using: .utf8),
              let days = try? JSONDecoder().decode([PushDay].self, from: data) else {
            throw PushRenderError.invalidDays
        }
        return days
    }

    // MARK: - Rules

    static let viennaCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Vienna") ?? TimeZone(secondsFromGMT: 3600)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    private func dayLabel(_ date: String, now: Date, _ strings: PushLanguageCopy) throws -> String {
        let calendar = Self.viennaCalendar
        let dayStart = try Self.viennaStartOfDay(date)
        let todayStart = calendar.startOfDay(for: now)
        guard let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) else {
            throw PushRenderError.invalidDate(date)
        }
        if dayStart == todayStart {
            return strings.dayToday
        }
        if dayStart == tomorrowStart {
            return strings.dayTomorrow
        }
        let weekday = calendar.component(.weekday, from: dayStart)
        let isoWeekday = (weekday + 5) % 7 + 1
        return strings.weekdays[isoWeekday - 1]
    }

    private func time(of day: PushDay, _ strings: PushLanguageCopy) throws -> String {
        let dayStart = try Self.viennaStartOfDay(day.date)
        guard let nextDayStart = Self.viennaCalendar.date(byAdding: .day, value: 1, to: dayStart) else {
            throw PushRenderError.invalidDate(day.date)
        }

        var startText = "00:00"
        if !day.start.isEmpty {
            let start = try Self.parseTimestamp(day.start)
            if start > dayStart {
                startText = Self.viennaClock(start)
            }
        }

        var endText = "24:00"
        if !day.end.isEmpty {
            let end = try Self.parseTimestamp(day.end)
            if end < nextDayStart {
                endText = Self.viennaClock(end)
            }
        }

        if startText == "00:00", endText == "24:00" {
            return strings.allDay
        }
        return Self.fill(strings.timeRange, ["start": startText, "end": endText])
    }

    private func levelName(_ level: Int, _ strings: PushLanguageCopy) throws -> String {
        guard let name = strings.levelNames[String(level)] else {
            throw PushRenderError.missingLevelName(level)
        }
        return name
    }

    static func viennaStartOfDay(_ date: String) throws -> Date {
        let parts = date.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              let result = viennaCalendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            throw PushRenderError.invalidDate(date)
        }
        return result
    }

    static func parseTimestamp(_ value: String) throws -> Date {
        if let date = try? Date(value, strategy: .iso8601) {
            return date
        }
        if let date = try? Date(value, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
            return date
        }
        throw PushRenderError.invalidTimestamp(value)
    }

    static func viennaClock(_ date: Date) -> String {
        let components = viennaCalendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    /// Single pass so a value that itself contains "{…}" (e.g. a municipality name) is never
    /// substituted again.
    static func fill(_ template: String, _ values: [String: String]) -> String {
        var result = ""
        var remainder = template[...]
        while let open = remainder.firstIndex(of: "{") {
            result += remainder[..<open]
            let afterOpen = remainder.index(after: open)
            guard let close = remainder[afterOpen...].firstIndex(of: "}") else {
                remainder = remainder[open...]
                break
            }
            let key = String(remainder[afterOpen..<close])
            if let value = values[key] {
                result += value
            } else {
                result += remainder[open...close]
            }
            remainder = remainder[remainder.index(after: close)...]
        }
        result += remainder
        return result
    }
}
