import CryptoKit
import Foundation
import os

struct PushSyncResult: Equatable, Sendable {
    var failedGKZs: Set<String>
    var errorDescription: String?

    static let success = PushSyncResult(failedGKZs: [], errorDescription: nil)
}

/// FCM operations the subscription logic needs; wrapped so the logic is testable without Firebase.
protocol PushTopicClient: AnyObject, Sendable {
    func currentToken() async throws -> String
    func subscribe(toTopic topic: String) async throws
    func unsubscribe(fromTopic topic: String) async throws
    func deleteToken() async throws
}

nonisolated let pushLogger = Logger(subsystem: "org.entner.HitzeV", category: "Push")

final class PushSubscriptionStore {
    private enum Key {
        static let desired = "push.v2.desiredGKZs"
        static let enabled = "push.v2.enabled"
        static let subscribed = "push.v2.subscribedGKZs"
        static let tokenHash = "push.v2.subscriptionTokenHash"
        static let migrated = "push.v2.migratedLegacyGKZs"
        static let tokenDeleted = "push.v2.tokenDeleted"
        static let legacySubscribed = "subscription_manager.subscribedMunicipalityIDs"
        static let legacyLanguage = "subscription_manager.lastSubscribedLanguageCode"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var desiredGKZs: Set<String> {
        get { stringSet(Key.desired) }
        set { setStringSet(newValue, Key.desired) }
    }

    var enabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    /// False until the app has stored a v2 desired state once. An install upgraded from ≤ 1.2.4
    /// starts without one, and its legacy topics must survive until the dashboard has synced.
    var hasDesiredState: Bool {
        defaults.object(forKey: Key.enabled) != nil
    }

    /// GKZs whose v2 topic is confirmed subscribed for the token in `subscriptionTokenHash`.
    var subscribedGKZs: Set<String> {
        get { stringSet(Key.subscribed) }
        set { setStringSet(newValue, Key.subscribed) }
    }

    var subscriptionTokenHash: String? {
        get { defaults.string(forKey: Key.tokenHash) }
        set { defaults.set(newValue, forKey: Key.tokenHash) }
    }

    /// GKZs whose legacy topics have all been unsubscribed.
    var migratedGKZs: Set<String> {
        get { stringSet(Key.migrated) }
        set { setStringSet(newValue, Key.migrated) }
    }

    var tokenDeleted: Bool {
        get { defaults.bool(forKey: Key.tokenDeleted) }
        set { defaults.set(newValue, forKey: Key.tokenDeleted) }
    }

    /// GKZs subscribed by app versions ≤ 1.2.4 (legacy topics).
    var legacyGKZs: Set<String> {
        stringSet(Key.legacySubscribed)
    }

    func removeLegacyState() {
        defaults.removeObject(forKey: Key.legacySubscribed)
        defaults.removeObject(forKey: Key.legacyLanguage)
    }

    private func stringSet(_ key: String) -> Set<String> {
        PushTopics.normalizedGKZs(defaults.stringArray(forKey: key) ?? [])
    }

    private func setStringSet(_ value: Set<String>, _ key: String) {
        defaults.set(value.sorted(), forKey: key)
    }
}

/// Applies the persisted desired state to FCM. Not reentrant; `SubscriptionManager` serializes calls.
final class PushTopicSyncEngine {
    private let client: any PushTopicClient
    private let store: PushSubscriptionStore
    /// Token for which every desired topic was re-subscribed in this process.
    private var resubscribedTokenHash: String?

    init(client: any PushTopicClient, store: PushSubscriptionStore) {
        self.client = client
        self.store = store
    }

    func run(shouldStopMigrating: () -> Bool) async -> PushSyncResult {
        // An empty desired state here would tear down (delete the token, drop legacy topics)
        // before an upgraded install has subscribed anything in v2.
        guard store.hasDesiredState else {
            return .success
        }
        let desired = store.enabled ? store.desiredGKZs : []
        if desired.isEmpty {
            return await tearDown()
        }

        let token: String
        do {
            token = try await client.currentToken()
        } catch {
            pushLogger.error("FCM token unavailable: \(error.localizedDescription, privacy: .public)")
            return PushSyncResult(failedGKZs: desired, errorDescription: error.localizedDescription)
        }

        let tokenHash = Self.hash(token)
        if store.subscriptionTokenHash != tokenHash {
            store.subscribedGKZs = []
            store.subscriptionTokenHash = tokenHash
        }
        store.tokenDeleted = false

        let plan = PushSubscriptionPlan.make(
            desired: desired,
            subscribed: store.subscribedGKZs,
            migrated: store.migratedGKZs,
            legacyCandidates: store.legacyGKZs,
            resubscribeAll: resubscribedTokenHash != tokenHash,
            tokenDeleted: false,
            tokenUsedForSubscriptions: true
        )

        var failed = Set<String>()
        var firstError: String?

        for gkz in plan.subscribe.sorted() {
            do {
                try await client.subscribe(toTopic: PushTopics.v2Topic(for: gkz))
                store.subscribedGKZs.insert(gkz)
            } catch {
                store.subscribedGKZs.remove(gkz)
                failed.insert(gkz)
                firstError = firstError ?? error.localizedDescription
                pushLogger.error("Subscribe failed for \(gkz, privacy: .private): \(error.localizedDescription, privacy: .public)")
            }
        }
        resubscribedTokenHash = tokenHash

        for gkz in plan.unsubscribe.sorted() {
            do {
                try await client.unsubscribe(fromTopic: PushTopics.v2Topic(for: gkz))
                store.subscribedGKZs.remove(gkz)
            } catch {
                failed.insert(gkz)
                firstError = firstError ?? error.localizedDescription
                pushLogger.error("Unsubscribe failed for \(gkz, privacy: .private): \(error.localizedDescription, privacy: .public)")
            }
        }

        for gkz in plan.migrate.sorted() {
            if shouldStopMigrating() { break }
            // Dropping the legacy topics before v2 is confirmed would leave this GKZ without pushes.
            if desired.contains(gkz), !store.subscribedGKZs.contains(gkz) { continue }
            if await unsubscribeAll(PushTopics.legacyTopics(for: gkz)) {
                store.migratedGKZs.insert(gkz)
            } else {
                pushLogger.notice("Legacy topic cleanup incomplete for \(gkz, privacy: .private); retrying on next sync")
            }
        }
        removeLegacyStateIfMigrated()

        return PushSyncResult(failedGKZs: failed, errorDescription: firstError)
    }

    private func tearDown() async -> PushSyncResult {
        let subscribed = store.subscribedGKZs
        let plan = PushSubscriptionPlan.make(
            desired: [],
            subscribed: subscribed,
            migrated: store.migratedGKZs,
            legacyCandidates: store.legacyGKZs,
            resubscribeAll: false,
            tokenDeleted: store.tokenDeleted,
            tokenUsedForSubscriptions: store.subscriptionTokenHash != nil
        )
        guard plan.deleteToken || !plan.unsubscribe.isEmpty else {
            return .success
        }

        var failed = Set<String>()
        var firstError: String?
        for gkz in plan.unsubscribe.sorted() {
            do {
                try await client.unsubscribe(fromTopic: PushTopics.v2Topic(for: gkz))
                store.subscribedGKZs.remove(gkz)
            } catch {
                failed.insert(gkz)
                firstError = firstError ?? error.localizedDescription
            }
        }

        guard plan.deleteToken else {
            return PushSyncResult(failedGKZs: failed, errorDescription: firstError)
        }

        do {
            try await client.deleteToken()
            store.migratedGKZs.formUnion(store.legacyGKZs.union(subscribed))
            store.subscribedGKZs = []
            store.subscriptionTokenHash = nil
            store.tokenDeleted = true
            resubscribedTokenHash = nil
            removeLegacyStateIfMigrated()
            return .success
        } catch {
            pushLogger.error("FCM token deletion failed: \(error.localizedDescription, privacy: .public)")
            return PushSyncResult(failedGKZs: failed, errorDescription: firstError ?? error.localizedDescription)
        }
    }

    private func unsubscribeAll(_ topics: [String]) async -> Bool {
        let client = client
        return await withTaskGroup(of: Bool.self) { group in
            for topic in topics {
                group.addTask {
                    do {
                        try await client.unsubscribe(fromTopic: topic)
                        return true
                    } catch {
                        return false
                    }
                }
            }
            var allSucceeded = true
            for await succeeded in group where !succeeded {
                allSucceeded = false
            }
            return allSucceeded
        }
    }

    private func removeLegacyStateIfMigrated() {
        let legacy = store.legacyGKZs
        if !legacy.isEmpty, legacy.isSubset(of: store.migratedGKZs) {
            store.removeLegacyState()
        }
    }

    private static func hash(_ token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
final class SubscriptionManager {
    static let shared = SubscriptionManager(
        client: FirebaseTopicClient(),
        store: PushSubscriptionStore(defaults: .standard)
    )

    private let store: PushSubscriptionStore
    private let engine: PushTopicSyncEngine
    private var requestedTicket = 0
    private var completedTicket = 0
    private var worker: Task<Void, Never>?
    private var waiters: [(ticket: Int, continuation: CheckedContinuation<PushSyncResult, Never>)] = []

    init(client: any PushTopicClient, store: PushSubscriptionStore) {
        self.store = store
        self.engine = PushTopicSyncEngine(client: client, store: store)
    }

    /// Desired state = GKZs of worksites with push on. Serialized + coalesced internally,
    /// never prompts for permission, never needs notification permission, no GeoSphere lookups.
    func sync(desiredGKZs: Set<String>, enabled: Bool) async -> PushSyncResult {
        store.desiredGKZs = PushTopics.normalizedGKZs(desiredGKZs)
        store.enabled = enabled
        return await enqueue()
    }

    /// GKZs that get pushes now or are meant to; kept while a worksite's GKZ is still unknown so
    /// that an incomplete worksite list never removes a subscription.
    var retainedGKZs: Set<String> {
        let desired = store.hasDesiredState && store.enabled ? store.desiredGKZs : []
        return desired
            .union(store.subscribedGKZs)
            .union(store.legacyGKZs.subtracting(store.migratedGKZs))
    }

    /// Re-applies the last desired state; used on app launch and FCM token refresh so restores,
    /// reinstalls and token rotation heal themselves. No-op until `sync` has run once.
    @discardableResult
    func resyncStoredState() async -> PushSyncResult {
        await enqueue()
    }

    private func enqueue() async -> PushSyncResult {
        requestedTicket += 1
        let ticket = requestedTicket
        if worker == nil {
            worker = Task { await self.drain() }
        }
        return await withCheckedContinuation { continuation in
            waiters.append((ticket, continuation))
        }
    }

    private func drain() async {
        while completedTicket < requestedTicket {
            let target = requestedTicket
            let result = await engine.run(shouldStopMigrating: { [unowned self] in
                self.requestedTicket > target
            })
            completedTicket = target

            let ready = waiters.filter { $0.ticket <= target }
            waiters.removeAll { $0.ticket <= target }
            for waiter in ready {
                waiter.continuation.resume(returning: result)
            }
        }
        worker = nil
    }
}
