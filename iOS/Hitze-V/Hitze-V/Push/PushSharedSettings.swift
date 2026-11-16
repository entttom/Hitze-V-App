import Foundation

nonisolated enum PushSharedSettings {
    static let appGroupIdentifier = "group.org.entner.HitzeV"
    static let languageKey = "dashboard.language"

    // UserDefaults is documented as thread-safe; it just isn't marked Sendable.
    nonisolated(unsafe) fileprivate static let sharedDefaults: UserDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard

    /// Copies the in-app language from the app's own defaults into the App Group once, so the
    /// Notification Service Extension renders pushes in the language the user picked before the
    /// language setting moved to the App Group.
    static func migrateLanguageIfNeeded(
        from source: UserDefaults,
        to target: UserDefaults,
        targetSuiteName: String
    ) {
        guard source !== target else { return }
        // A suite instance also searches the app's own domain, so only the persistent domain
        // tells whether the value really lives in the App Group yet.
        let alreadyShared = target.persistentDomain(forName: targetSuiteName)?[languageKey] != nil
        guard !alreadyShared, let value = source.string(forKey: languageKey) else { return }
        target.set(value, forKey: languageKey)
    }

    static func migrateLanguageIfNeeded() {
        migrateLanguageIfNeeded(
            from: .standard,
            to: .hitzeShared,
            targetSuiteName: appGroupIdentifier
        )
    }
}

extension UserDefaults {
    /// App Group suite shared by the app and the Notification Service Extension.
    nonisolated static var hitzeShared: UserDefaults {
        PushSharedSettings.sharedDefaults
    }
}

nonisolated enum PushLanguage {
    /// The 25 languages the apps ship, in the order of the copy file.
    static let supportedCodes: [String] = [
        "bg", "da", "de", "en", "et", "fi", "fr", "el", "ga", "it", "hr", "lv", "lt",
        "mt", "nl", "pl", "pt", "ro", "sv", "sk", "sl", "es", "cs", "hu", "tr"
    ]

    /// Resolves the stored in-app language ("system", a language code, or nil) to one of the
    /// 25 codes; nil means "use the copy file's fallbackLanguage".
    static func resolve(storedValue: String?, preferredLanguages: [String]) -> String? {
        if let stored = normalizedCode(storedValue), stored != "system", supportedCodes.contains(stored) {
            return stored
        }
        for identifier in preferredLanguages {
            if let code = languageCode(ofLocaleIdentifier: identifier), supportedCodes.contains(code) {
                return code
            }
        }
        return nil
    }

    static func currentLanguageCode(defaults: UserDefaults) -> String? {
        resolve(
            storedValue: defaults.string(forKey: PushSharedSettings.languageKey),
            preferredLanguages: Locale.preferredLanguages
        )
    }

    private static func normalizedCode(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func languageCode(ofLocaleIdentifier identifier: String) -> String? {
        if let code = Locale.Language(identifier: identifier).languageCode?.identifier.lowercased() {
            return code
        }
        return identifier.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map { $0.lowercased() }
    }
}
