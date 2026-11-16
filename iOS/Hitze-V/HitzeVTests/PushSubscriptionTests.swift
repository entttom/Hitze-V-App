import Foundation
import Testing
@testable import Hitze_V

private struct FakeFCMError: LocalizedError {
    let errorDescription: String? = "fake FCM failure"
}

final class FakeTopicClient: PushTopicClient {
    var token = "token-A"
    var tokenAvailable = true
    var failingTopics: Set<String> = []
    var deleteTokenFails = false
    /// Suspends every subscribe call once, so concurrent sync requests overlap a running sync.
    var yieldDuringSubscribe = false

    private(set) var subscribeCalls: [String] = []
    private(set) var unsubscribeCalls: [String] = []
    private(set) var deleteTokenCalls = 0

    func currentToken() async throws -> String {
        guard tokenAvailable else { throw FakeFCMError() }
        return token
    }

    func subscribe(toTopic topic: String) async throws {
        if yieldDuringSubscribe {
            await Task.yield()
        }
        subscribeCalls.append(topic)
        if failingTopics.contains(topic) { throw FakeFCMError() }
    }

    func unsubscribe(fromTopic topic: String) async throws {
        unsubscribeCalls.append(topic)
        if failingTopics.contains(topic) { throw FakeFCMError() }
    }

    func deleteToken() async throws {
        deleteTokenCalls += 1
        if deleteTokenFails { throw FakeFCMError() }
    }

    func resetCalls() {
        subscribeCalls = []
        unsubscribeCalls = []
        deleteTokenCalls = 0
    }
}

private final class Fixture {
    let suiteName = "test.push.subscriptions.\(UUID().uuidString)"
    nonisolated(unsafe) let defaults: UserDefaults
    let store: PushSubscriptionStore
    let client = FakeTopicClient()

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        store = PushSubscriptionStore(defaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    /// A fresh manager over the same persisted state = an app relaunch.
    func makeManager() -> SubscriptionManager {
        SubscriptionManager(client: client, store: store)
    }
}

struct PushSubscriptionPlanTests {
    @Test func diffsDesiredAgainstSubscribed() {
        let plan = PushSubscriptionPlan.make(
            desired: ["10101", "20202"],
            subscribed: ["20202", "30303"],
            migrated: ["20202", "30303"],
            legacyCandidates: ["40404"],
            resubscribeAll: false,
            tokenDeleted: false,
            tokenUsedForSubscriptions: true
        )
        #expect(plan.subscribe == ["10101"])
        #expect(plan.unsubscribe == ["30303"])
        #expect(plan.migrate == ["10101", "40404"])
        #expect(!plan.deleteToken)
    }

    @Test func resubscribeAllCoversEveryDesiredGKZ() {
        let plan = PushSubscriptionPlan.make(
            desired: ["10101", "20202"],
            subscribed: ["10101", "20202"],
            migrated: ["10101", "20202"],
            legacyCandidates: [],
            resubscribeAll: true,
            tokenDeleted: false,
            tokenUsedForSubscriptions: true
        )
        #expect(plan.subscribe == ["10101", "20202"])
        #expect(plan.unsubscribe.isEmpty)
        #expect(plan.migrate.isEmpty)
    }

    @Test func goingToZeroDeletesTokenOnlyOnce() {
        let first = PushSubscriptionPlan.make(
            desired: [],
            subscribed: ["10101"],
            migrated: [],
            legacyCandidates: [],
            resubscribeAll: true,
            tokenDeleted: false,
            tokenUsedForSubscriptions: true
        )
        #expect(first.unsubscribe == ["10101"])
        #expect(first.deleteToken)
        #expect(first.subscribe.isEmpty)

        let again = PushSubscriptionPlan.make(
            desired: [],
            subscribed: [],
            migrated: ["10101"],
            legacyCandidates: [],
            resubscribeAll: true,
            tokenDeleted: true,
            tokenUsedForSubscriptions: false
        )
        #expect(again == PushSubscriptionPlan())

        let afterFailedDeletion = PushSubscriptionPlan.make(
            desired: [],
            subscribed: [],
            migrated: ["10101"],
            legacyCandidates: [],
            resubscribeAll: false,
            tokenDeleted: false,
            tokenUsedForSubscriptions: true
        )
        #expect(afterFailedDeletion.deleteToken)
        #expect(afterFailedDeletion.unsubscribe.isEmpty)

        let freshInstall = PushSubscriptionPlan.make(
            desired: [],
            subscribed: [],
            migrated: [],
            legacyCandidates: [],
            resubscribeAll: true,
            tokenDeleted: false,
            tokenUsedForSubscriptions: false
        )
        #expect(!freshInstall.deleteToken)
    }

    @Test func topicNames() {
        #expect(PushTopics.v2Topic(for: "60101") == "warngebiet_v2_60101")
        let legacy = PushTopics.legacyTopics(for: "60101")
        #expect(legacy.count == 26)
        #expect(legacy.first == "warngebiet_60101")
        #expect(Set(legacy.dropFirst()) == Set(PushTopics.legacyLanguageCodes.map { "warngebiet_60101_\($0)" }))
        #expect(Set(PushTopics.legacyLanguageCodes) == Set(PushLanguage.supportedCodes))
        #expect(PushTopics.normalizedGKZs([" 601 01", "", "  ", "90001"]) == ["60101", "90001"])
    }
}

struct SubscriptionManagerTests {
    @Test func firstSyncSubscribesV2AndMigratesLegacyTopics() async {
        let fixture = Fixture()
        let manager = fixture.makeManager()

        let result = await manager.sync(desiredGKZs: ["60101", " 90001 "], enabled: true)

        #expect(result == .success)
        #expect(Set(fixture.client.subscribeCalls) == ["warngebiet_v2_60101", "warngebiet_v2_90001"])
        #expect(Set(fixture.client.unsubscribeCalls) == Set(PushTopics.legacyTopics(for: "60101") + PushTopics.legacyTopics(for: "90001")))
        #expect(fixture.store.subscribedGKZs == ["60101", "90001"])
        #expect(fixture.store.migratedGKZs == ["60101", "90001"])
        #expect(!fixture.client.subscribeCalls.contains { !$0.hasPrefix("warngebiet_v2_") })
    }

    @Test func repeatedSyncIsQuietButRelaunchResubscribesEverything() async {
        let fixture = Fixture()
        _ = await fixture.makeManager().sync(desiredGKZs: ["60101"], enabled: true)

        let manager = fixture.makeManager()
        fixture.client.resetCalls()
        _ = await manager.resyncStoredState()
        #expect(fixture.client.subscribeCalls == ["warngebiet_v2_60101"])
        #expect(fixture.client.unsubscribeCalls.isEmpty)

        fixture.client.resetCalls()
        _ = await manager.sync(desiredGKZs: ["60101"], enabled: true)
        #expect(fixture.client.subscribeCalls.isEmpty)
        #expect(fixture.client.unsubscribeCalls.isEmpty)
    }

    @Test func tokenChangeResubscribesAllDesiredTopics() async {
        let fixture = Fixture()
        let manager = fixture.makeManager()
        _ = await manager.sync(desiredGKZs: ["60101", "90001"], enabled: true)

        fixture.client.resetCalls()
        fixture.client.token = "token-B"
        let result = await manager.resyncStoredState()

        #expect(result == .success)
        #expect(Set(fixture.client.subscribeCalls) == ["warngebiet_v2_60101", "warngebiet_v2_90001"])
        #expect(fixture.store.subscribedGKZs == ["60101", "90001"])
    }

    @Test func removedGKZIsUnsubscribed() async {
        let fixture = Fixture()
        let manager = fixture.makeManager()
        _ = await manager.sync(desiredGKZs: ["60101", "90001"], enabled: true)

        fixture.client.resetCalls()
        let result = await manager.sync(desiredGKZs: ["60101"], enabled: true)

        #expect(result == .success)
        #expect(fixture.client.subscribeCalls.isEmpty)
        #expect(fixture.client.unsubscribeCalls == ["warngebiet_v2_90001"])
        #expect(fixture.store.subscribedGKZs == ["60101"])
    }

    @Test func oneFailingGKZDoesNotBlockOthersAndIsRetried() async {
        let fixture = Fixture()
        fixture.client.failingTopics = ["warngebiet_v2_90001"]
        let manager = fixture.makeManager()

        let result = await manager.sync(desiredGKZs: ["60101", "90001", "30101"], enabled: true)

        #expect(result.failedGKZs == ["90001"])
        #expect(result.errorDescription == "fake FCM failure")
        #expect(fixture.store.subscribedGKZs == ["60101", "30101"])
        // Legacy topics of the failed GKZ stay until v2 works, so it never ends up with no pushes.
        #expect(fixture.store.migratedGKZs == ["60101", "30101"])
        #expect(!fixture.client.unsubscribeCalls.contains("warngebiet_90001"))

        fixture.client.failingTopics = []
        fixture.client.resetCalls()
        let retry = await manager.sync(desiredGKZs: ["60101", "90001", "30101"], enabled: true)

        #expect(retry == .success)
        #expect(fixture.client.subscribeCalls == ["warngebiet_v2_90001"])
        #expect(Set(fixture.client.unsubscribeCalls) == Set(PushTopics.legacyTopics(for: "90001")))
        #expect(fixture.store.migratedGKZs == ["60101", "90001", "30101"])
    }

    @Test func failedLegacyCleanupIsRetriedOnLaterSync() async {
        let fixture = Fixture()
        fixture.client.failingTopics = ["warngebiet_60101_tr"]
        let manager = fixture.makeManager()

        let result = await manager.sync(desiredGKZs: ["60101"], enabled: true)
        #expect(result == .success)
        #expect(fixture.store.migratedGKZs.isEmpty)

        fixture.client.failingTopics = []
        fixture.client.resetCalls()
        _ = await manager.sync(desiredGKZs: ["60101"], enabled: true)
        #expect(Set(fixture.client.unsubscribeCalls) == Set(PushTopics.legacyTopics(for: "60101")))
        #expect(fixture.store.migratedGKZs == ["60101"])

        fixture.client.resetCalls()
        _ = await manager.sync(desiredGKZs: ["60101"], enabled: true)
        #expect(fixture.client.unsubscribeCalls.isEmpty)
    }

    @Test func legacyGKZsFromOldVersionAreMigratedAndOldKeysRemoved() async {
        let fixture = Fixture()
        fixture.defaults.set(["60101", "70101"], forKey: "subscription_manager.subscribedMunicipalityIDs")
        fixture.defaults.set("de", forKey: "subscription_manager.lastSubscribedLanguageCode")
        let manager = fixture.makeManager()

        let result = await manager.sync(desiredGKZs: ["60101"], enabled: true)

        #expect(result == .success)
        #expect(fixture.client.subscribeCalls == ["warngebiet_v2_60101"])
        #expect(Set(fixture.client.unsubscribeCalls) == Set(PushTopics.legacyTopics(for: "60101") + PushTopics.legacyTopics(for: "70101")))
        #expect(fixture.defaults.object(forKey: "subscription_manager.subscribedMunicipalityIDs") == nil)
        #expect(fixture.defaults.object(forKey: "subscription_manager.lastSubscribedLanguageCode") == nil)
    }

    @Test func disablingUnsubscribesAllAndDeletesTokenOnce() async {
        let fixture = Fixture()
        let manager = fixture.makeManager()
        _ = await manager.sync(desiredGKZs: ["60101", "90001"], enabled: true)

        fixture.client.resetCalls()
        let off = await manager.sync(desiredGKZs: ["60101", "90001"], enabled: false)
        #expect(off == .success)
        #expect(Set(fixture.client.unsubscribeCalls) == ["warngebiet_v2_60101", "warngebiet_v2_90001"])
        #expect(fixture.client.deleteTokenCalls == 1)
        #expect(fixture.store.subscribedGKZs.isEmpty)

        fixture.client.resetCalls()
        _ = await manager.resyncStoredState()
        _ = await fixture.makeManager().sync(desiredGKZs: [], enabled: true)
        #expect(fixture.client.deleteTokenCalls == 0)
        #expect(fixture.client.unsubscribeCalls.isEmpty)
        #expect(fixture.client.subscribeCalls.isEmpty)

        fixture.client.token = "token-after-delete"
        let on = await manager.sync(desiredGKZs: ["60101"], enabled: true)
        #expect(on == .success)
        #expect(fixture.client.subscribeCalls == ["warngebiet_v2_60101"])
    }

    @Test func failedTokenDeletionIsRetried() async {
        let fixture = Fixture()
        let manager = fixture.makeManager()
        _ = await manager.sync(desiredGKZs: ["60101"], enabled: true)

        fixture.client.deleteTokenFails = true
        let failed = await manager.sync(desiredGKZs: [], enabled: true)
        #expect(failed.errorDescription != nil)

        fixture.client.deleteTokenFails = false
        fixture.client.resetCalls()
        let retried = await manager.sync(desiredGKZs: [], enabled: true)
        #expect(retried == .success)
        #expect(fixture.client.deleteTokenCalls == 1)
    }

    @Test func missingTokenReportsAllDesiredAsFailedWithoutTouchingState() async {
        let fixture = Fixture()
        fixture.client.tokenAvailable = false
        let manager = fixture.makeManager()

        let result = await manager.sync(desiredGKZs: ["60101", "90001"], enabled: true)

        #expect(result.failedGKZs == ["60101", "90001"])
        #expect(result.errorDescription != nil)
        #expect(fixture.client.subscribeCalls.isEmpty)
        #expect(fixture.store.desiredGKZs == ["60101", "90001"])

        fixture.client.tokenAvailable = true
        let healed = await manager.resyncStoredState()
        #expect(healed == .success)
        #expect(fixture.store.subscribedGKZs == ["60101", "90001"])
    }

    @Test func concurrentSyncsAreSerializedAndLatestDesiredStateWins() async {
        let fixture = Fixture()
        fixture.client.yieldDuringSubscribe = true
        let manager = fixture.makeManager()

        async let first = manager.sync(desiredGKZs: ["10101", "20202"], enabled: true)
        async let second = manager.sync(desiredGKZs: ["20202", "30303"], enabled: true)
        async let third = manager.sync(desiredGKZs: ["30303"], enabled: true)
        let results = await [first, second, third]

        // The three requests arrive in an unspecified order; whichever came last must be applied.
        #expect(results.allSatisfy { $0.failedGKZs.isEmpty })
        #expect(!fixture.store.desiredGKZs.isEmpty)
        #expect(fixture.store.subscribedGKZs == fixture.store.desiredGKZs)
    }

    @Test func requestDuringRunningSyncIsAppliedAfterIt() async {
        let fixture = Fixture()
        fixture.client.yieldDuringSubscribe = true
        let manager = fixture.makeManager()

        let running = Task { await manager.sync(desiredGKZs: ["10101", "20202"], enabled: true) }
        await Task.yield()
        let latest = await manager.sync(desiredGKZs: ["30303"], enabled: true)
        let earlier = await running.value

        #expect(latest == .success)
        #expect(earlier.failedGKZs.isEmpty)
        #expect(fixture.store.desiredGKZs == ["30303"])
        #expect(fixture.store.subscribedGKZs == ["30303"])
    }
}
