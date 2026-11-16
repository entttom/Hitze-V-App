import Foundation

nonisolated enum PushTopics {
    /// Language codes of the legacy per-language topics `warngebiet_<GKZ>_<lang>`.
    static let legacyLanguageCodes: [String] = [
        "bg", "da", "de", "en", "et", "fi", "fr", "el", "ga", "it", "hr", "lv", "lt",
        "mt", "nl", "pl", "pt", "ro", "sv", "sk", "sl", "es", "cs", "hu", "tr"
    ]

    static func normalizedGKZ(_ raw: String) -> String {
        PushNotificationContent.normalizedGKZ(raw)
    }

    static func normalizedGKZs<S: Sequence>(_ raws: S) -> Set<String> where S.Element == String {
        Set(raws.map(normalizedGKZ).filter { !$0.isEmpty })
    }

    static func v2Topic(for gkz: String) -> String {
        "warngebiet_v2_\(gkz)"
    }

    /// `warngebiet_<GKZ>` plus `warngebiet_<GKZ>_<lang>` for all 25 languages.
    static func legacyTopics(for gkz: String) -> [String] {
        ["warngebiet_\(gkz)"] + legacyLanguageCodes.map { "warngebiet_\(gkz)_\($0)" }
    }
}

nonisolated enum PushDesiredGKZs {
    /// `worksiteGKZs`: one entry per push-enabled worksite, nil while its GKZ is unknown (stored
    /// by an older version and not fetched yet). While any is unknown, `retained` (the GKZs that
    /// already get pushes) is kept: additions happen right away, removals wait for the full set.
    static func resolve(worksiteGKZs: [String?], retained: Set<String>) -> Set<String> {
        let known = PushTopics.normalizedGKZs(worksiteGKZs.compactMap { $0 })
        let isComplete = worksiteGKZs.allSatisfy { gkz in
            gkz.map { !PushTopics.normalizedGKZ($0).isEmpty } ?? false
        }
        return isComplete ? known : known.union(PushTopics.normalizedGKZs(retained))
    }
}

/// Pure diff between the desired and the persisted subscription state.
nonisolated struct PushSubscriptionPlan: Equatable {
    var subscribe: Set<String> = []
    var unsubscribe: Set<String> = []
    var migrate: Set<String> = []
    var deleteToken = false

    static func make(
        desired: Set<String>,
        subscribed: Set<String>,
        migrated: Set<String>,
        legacyCandidates: Set<String>,
        resubscribeAll: Bool,
        tokenDeleted: Bool,
        tokenUsedForSubscriptions: Bool
    ) -> PushSubscriptionPlan {
        if desired.isEmpty {
            let pendingLegacy = legacyCandidates.union(subscribed).subtracting(migrated)
            let tokenHasTopics = tokenUsedForSubscriptions || !subscribed.isEmpty || !pendingLegacy.isEmpty
            // Deleting the FCM token drops every topic of that token, legacy ones included, so the
            // per-topic migration is skipped here; it is done only once on the way to zero.
            return PushSubscriptionPlan(
                subscribe: [],
                unsubscribe: subscribed,
                migrate: [],
                deleteToken: !tokenDeleted && tokenHasTopics
            )
        }

        return PushSubscriptionPlan(
            subscribe: resubscribeAll ? desired : desired.subtracting(subscribed),
            unsubscribe: subscribed.subtracting(desired),
            migrate: desired.union(legacyCandidates).union(subscribed).subtracting(migrated),
            deleteToken: false
        )
    }
}
