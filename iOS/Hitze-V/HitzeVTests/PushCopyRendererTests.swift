import Foundation
import Testing
import UserNotifications
@testable import Hitze_V

private final class TestBundleToken {}

private struct GoldenFile: Decodable {
    struct Expected: Decodable {
        let title: String
        let body: String
    }

    struct Case: Decodable {
        let id: String
        let now: String
        let event: String
        let name: String
        let days: [PushDay]
        let expected: [String: Expected]
    }

    let cases: [Case]

    static func load() throws -> GoldenFile {
        let bundle = Bundle(for: TestBundleToken.self)
        let url = try #require(bundle.url(forResource: "push-copy-examples", withExtension: "json"))
        return try JSONDecoder().decode(GoldenFile.self, from: Data(contentsOf: url))
    }
}

/// The copy file bundled into the app (and, via the same file reference, the extension).
private func bundledRenderer() throws -> PushCopyRenderer {
    try PushCopyRenderer(bundle: .main)
}

struct PushCopyRendererGoldenTests {
    @Test(arguments: ["de", "en"])
    func reproducesGoldenVectors(language: String) throws {
        let renderer = try bundledRenderer()
        let golden = try GoldenFile.load()
        #expect(golden.cases.count >= 6)

        for testCase in golden.cases {
            let expected = try #require(testCase.expected[language], "\(testCase.id) has no \(language)")
            let event = try #require(PushEvent(rawValue: testCase.event))
            let now = try PushCopyRenderer.parseTimestamp(testCase.now)

            let rendered = try renderer.render(
                event: event,
                name: testCase.name,
                days: testCase.days,
                languageCode: language,
                now: now
            )

            #expect(rendered.title == expected.title, "\(testCase.id) [\(language)] title")
            #expect(rendered.body == expected.body, "\(testCase.id) [\(language)] body")
        }
    }

    @Test func rendersFromFCMDataPayload() throws {
        let renderer = try bundledRenderer()
        let userInfo: [AnyHashable: Any] = [
            "v": "2",
            "type": "heat_warning",
            "event": "new",
            "gkz": "60101",
            "name": "Graz",
            "days": "[{\"date\":\"2026-07-07\",\"level\":3,\"start\":\"2026-07-07T08:00:00Z\",\"end\":\"2026-07-07T16:00:00Z\"}]",
            "warningIds": "123,124",
            "sentAt": "2026-07-07T06:30:00Z"
        ]
        let rendered = try renderer.render(
            userInfo: userInfo,
            languageCode: "de",
            now: try PushCopyRenderer.parseTimestamp("2026-07-07T06:30:00Z")
        )
        #expect(rendered.title == "Hitzewarnung")
        #expect(rendered.body == "Heute in Graz: Hitzewarnstufe 3 (orange), 10:00–18:00 Uhr. Schutzmaßnahmen nach Hitze-V umsetzen.")
    }

    @Test func viennaTimesIgnoreDeviceTimeZone() throws {
        let renderer = try bundledRenderer()
        // Winter time: UTC+1.
        let rendered = try renderer.render(
            event: .new,
            name: "Graz",
            days: [PushDay(date: "2026-01-15", level: 2, start: "2026-01-15T08:05:00Z", end: "2026-01-15T15:30:00Z")],
            languageCode: "en",
            now: try PushCopyRenderer.parseTimestamp("2026-01-15T07:00:00Z")
        )
        #expect(rendered.body.hasPrefix("Today in Graz: heat warning level 2 (yellow), 09:05–16:30."))
    }

    @Test func endBeforeMidnightStartAfterMidnightIsNotAllDay() throws {
        let renderer = try bundledRenderer()
        let rendered = try renderer.render(
            event: .new,
            name: "Graz",
            days: [PushDay(date: "2026-07-07", level: 2, start: "2026-07-07T09:00:00Z", end: "")],
            languageCode: "en",
            now: try PushCopyRenderer.parseTimestamp("2026-07-07T06:30:00Z")
        )
        #expect(rendered.body.contains("11:00–24:00"))
    }

    @Test func errorsInsteadOfGuessing() throws {
        let renderer = try bundledRenderer()
        let now = Date()
        #expect(throws: PushRenderError.noDays) {
            try renderer.render(event: .new, name: "Graz", days: [], languageCode: "de", now: now)
        }
        #expect(throws: PushRenderError.missingLevelName(7)) {
            try renderer.render(
                event: .new,
                name: "Graz",
                days: [PushDay(date: "2026-07-07", level: 7, start: "", end: "")],
                languageCode: "de",
                now: now
            )
        }
        #expect(throws: PushRenderError.unknownEvent("cancelled")) {
            try renderer.render(userInfo: ["event": "cancelled", "name": "Graz", "days": "[]"], languageCode: "de", now: now)
        }
        #expect(throws: PushRenderError.invalidDays) {
            try renderer.render(userInfo: ["event": "new", "name": "Graz", "days": "not json"], languageCode: "de", now: now)
        }
    }

    @Test func placeholdersAreReplacedOnceAndLiterally() {
        let result = PushCopyRenderer.fill("{day} in {name}: {unknown} {", ["day": "Heute", "name": "{day} & \\1 $0"])
        #expect(result == "Heute in {day} & \\1 $0: {unknown} {")
    }
}

struct PushLanguageFallbackTests {
    private func copy(languages: String) throws -> PushCopy {
        let json = "{\"version\":1,\"fallbackLanguage\":\"en\",\"languages\":{\(languages)}}"
        return try JSONDecoder().decode(PushCopy.self, from: Data(json.utf8))
    }

    private func languageJSON(_ code: String, title: String) -> String {
        """
        "\(code)": {"title":"\(title)","titleEscalated":"e","titleUpdated":"u","titleTest":"t",
        "levelNames":{"2":"y","3":"o","4":"r"},"dayToday":"T","dayTomorrow":"M",
        "weekdays":["1","2","3","4","5","6","7"],"allDay":"all","timeRange":"{start}-{end}",
        "bodyNew":"{day} {name}","bodyEscalated":"b","bodyUpdated":"b","bodyTodayTomorrow":"b","bodyTest":"{name}"}
        """
    }

    @Test func unknownOrMissingLanguageFallsBackToFallbackLanguage() throws {
        let renderer = PushCopyRenderer(copy: try copy(languages: languageJSON("en", title: "EN") + "," + languageJSON("de", title: "DE")))
        let now = Date()
        let days = [PushDay(date: "2026-07-07", level: 2, start: "", end: "")]
        #expect(try renderer.render(event: .new, name: "X", days: days, languageCode: "de", now: now).title == "DE")
        #expect(try renderer.render(event: .new, name: "X", days: days, languageCode: "fr", now: now).title == "EN")
        #expect(try renderer.render(event: .new, name: "X", days: days, languageCode: nil, now: now).title == "EN")
        #expect(try renderer.languageCopy(for: "xx").code == "en")
    }

    @Test func incompleteLanguageIsSkippedNotFatal() throws {
        let decoded = try copy(languages: languageJSON("en", title: "EN") + ",\"fr\":{\"title\":\"Alerte\"}")
        #expect(decoded.languages.keys.sorted() == ["en"])
        let renderer = PushCopyRenderer(copy: decoded)
        #expect(try renderer.languageCopy(for: "fr").code == "en")
        #expect(try renderer.render(event: .test, name: "X", days: [], languageCode: "fr", now: Date()).body == "X")
    }

    @Test func bundledCopyHasFallbackAndGermanAndEnglish() throws {
        let renderer = try bundledRenderer()
        #expect(renderer.copy.fallbackLanguage == "en")
        #expect(renderer.copy.languages["de"] != nil)
        #expect(renderer.copy.languages["en"] != nil)
        for code in renderer.copy.languages.keys {
            #expect(PushLanguage.supportedCodes.contains(code), "unexpected language \(code)")
        }
    }

    @Test func resolvesInAppLanguage() {
        #expect(PushLanguage.resolve(storedValue: "de", preferredLanguages: ["en-US"]) == "de")
        #expect(PushLanguage.resolve(storedValue: "hu", preferredLanguages: ["en-US"]) == "hu")
        #expect(PushLanguage.resolve(storedValue: "system", preferredLanguages: ["fr-FR", "de-AT"]) == "fr")
        #expect(PushLanguage.resolve(storedValue: nil, preferredLanguages: ["ja-JP", "de-AT"]) == "de")
        #expect(PushLanguage.resolve(storedValue: "system", preferredLanguages: ["el-GR"]) == "el")
        #expect(PushLanguage.resolve(storedValue: "system", preferredLanguages: ["pt-BR"]) == "pt")
        #expect(PushLanguage.resolve(storedValue: "system", preferredLanguages: ["ja-JP"]) == nil)
        #expect(PushLanguage.resolve(storedValue: "klingon", preferredLanguages: ["ja-JP", "sv-SE"]) == "sv")
        #expect(PushLanguage.supportedCodes.count == 25)
    }

    @Test func readsLanguageFromSharedDefaults() throws {
        let suite = "test.push.language.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("it", forKey: PushSharedSettings.languageKey)
        #expect(PushLanguage.currentLanguageCode(defaults: defaults) == "it")
    }
}

struct PushSharedSettingsTests {
    @Test func copiesLanguageOnceAndKeepsExistingSharedValue() throws {
        let sourceSuite = "test.push.source.\(UUID().uuidString)"
        let targetSuite = "test.push.target.\(UUID().uuidString)"
        let source = try #require(UserDefaults(suiteName: sourceSuite))
        let target = try #require(UserDefaults(suiteName: targetSuite))
        defer {
            source.removePersistentDomain(forName: sourceSuite)
            target.removePersistentDomain(forName: targetSuite)
        }

        PushSharedSettings.migrateLanguageIfNeeded(from: source, to: target, targetSuiteName: targetSuite)
        #expect(target.string(forKey: PushSharedSettings.languageKey) == nil)

        source.set("de", forKey: PushSharedSettings.languageKey)
        PushSharedSettings.migrateLanguageIfNeeded(from: source, to: target, targetSuiteName: targetSuite)
        #expect(target.string(forKey: PushSharedSettings.languageKey) == "de")

        target.set("en", forKey: PushSharedSettings.languageKey)
        source.set("fr", forKey: PushSharedSettings.languageKey)
        PushSharedSettings.migrateLanguageIfNeeded(from: source, to: target, targetSuiteName: targetSuite)
        #expect(target.string(forKey: PushSharedSettings.languageKey) == "en")
    }

    @Test func unitTestHostDoesNotConfigureFirebase() {
        #expect(FirebaseRegistrationManager.isRunningUnitTests)
        #expect(!FirebaseRegistrationManager.shared.isConfigured)
    }
}

struct PushNotificationContentTests {
    private func content(_ userInfo: [AnyHashable: Any]) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Hitzewarnung"
        content.body = "Deutscher Fallback"
        content.userInfo = userInfo
        return content
    }

    @Test func rewritesV2AndGroupsByGKZ() throws {
        let renderer = try bundledRenderer()
        let original = content([
            "v": "2",
            "event": "test",
            "gkz": " 60101 ",
            "name": "Graz",
            "days": "[]"
        ])
        let rewritten = try #require(PushNotificationContent.rendered(
            from: original,
            renderer: renderer,
            languageCode: "en",
            now: Date()
        ))
        #expect(rewritten.title == "Test notification")
        #expect(rewritten.body == "Test notification for Graz. If you can read this, heat warnings reach this device.")
        #expect(rewritten.threadIdentifier == "hitze-60101")
        #expect(rewritten.userInfo["gkz"] as? String == " 60101 ")
    }

    @Test func nonV2OrBrokenPayloadKeepsFallback() throws {
        let renderer = try bundledRenderer()
        let legacy = content(["gkz": "60101"])
        #expect(PushNotificationContent.rendered(from: legacy, renderer: renderer, languageCode: "en", now: Date()) == nil)

        let broken = content(["v": "2", "event": "new", "gkz": "60101", "name": "Graz", "days": "{"])
        #expect(PushNotificationContent.rendered(from: broken, renderer: renderer, languageCode: "en", now: Date()) == nil)

        let fallback = PushNotificationContent.fallback(for: broken)
        #expect(fallback.title == "Hitzewarnung")
        #expect(fallback.body == "Deutscher Fallback")
        #expect(fallback.threadIdentifier == "hitze-60101")
    }

    @Test func tapRoutingReadsNormalizedGKZ() {
        #expect(PushNotificationContent.gkz(in: ["gkz": "6 01 01"]) == "60101")
        #expect(PushNotificationContent.gkz(in: ["gkz": "  "]) == nil)
        #expect(PushNotificationContent.gkz(in: [:]) == nil)
    }
}
