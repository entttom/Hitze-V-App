import Foundation
import Synchronization
import Testing
@testable import Hitze_V

/// UserDefaults exactly as app version 1.2.4 left them: legacy topic keys, old worksites without
/// a GKZ, the global toggle under its unchanged key, and no `push.v2.*` key at all.
private final class UpgradeFixture {
    let suiteName = "test.push.upgrade.\(UUID().uuidString)"
    nonisolated(unsafe) let defaults: UserDefaults
    let store: PushSubscriptionStore
    let client = FakeTopicClient()
    let worksiteA = UUID()
    let worksiteB = UUID()

    init(legacyGKZs: [String], pushEnabled: Bool?, latitudeA: Double = 47.07, latitudeB: Double = 48.21) {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(legacyGKZs, forKey: "subscription_manager.subscribedMunicipalityIDs")
        defaults.set("de", forKey: "subscription_manager.lastSubscribedLanguageCode")
        if let pushEnabled {
            defaults.set(pushEnabled, forKey: "push.notifications.enabled")
        }
        let worksites = """
        [{"id":"\(worksiteA.uuidString)","name":"Baustelle A","address":"Hauptplatz 1","latitude":\(latitudeA),"longitude":15.44},
         {"id":"\(worksiteB.uuidString)","name":"Baustelle B","latitude":\(latitudeB),"longitude":16.37}]
        """
        defaults.set(Data(worksites.utf8), forKey: DashboardViewModel.storageKey)
        store = PushSubscriptionStore(defaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func makeManager() -> SubscriptionManager {
        SubscriptionManager(client: client, store: store)
    }

    func makeViewModel(manager: SubscriptionManager, dataService: DashboardDataService? = nil) -> DashboardViewModel {
        DashboardViewModel(
            dataService: dataService,
            userDefaults: defaults,
            pushSync: { gkzs, enabled in await manager.sync(desiredGKZs: gkzs, enabled: enabled) },
            retainedPushGKZs: { manager.retainedGKZs }
        )
    }

    var legacyKeysPresent: Bool {
        defaults.object(forKey: "subscription_manager.subscribedMunicipalityIDs") != nil
            && defaults.object(forKey: "subscription_manager.lastSubscribedLanguageCode") != nil
    }
}

struct PushDesiredGKZsTests {
    @Test func completeWorksiteListIsExactSoRemovalsHappen() {
        let desired = PushDesiredGKZs.resolve(worksiteGKZs: ["60101", " 30101 "], retained: ["60101", "90001"])
        #expect(desired == ["60101", "30101"])
    }

    @Test func unknownGKZKeepsRetainedButStillAddsNewOnes() {
        let desired = PushDesiredGKZs.resolve(worksiteGKZs: ["60101", nil, "30101"], retained: ["90001", "60101"])
        #expect(desired == ["60101", "30101", "90001"])
    }

    @Test func emptyGKZCountsAsUnknown() {
        #expect(PushDesiredGKZs.resolve(worksiteGKZs: ["  "], retained: ["90001"]) == ["90001"])
    }

    @Test func noPushWorksitesMeansNoTopics() {
        #expect(PushDesiredGKZs.resolve(worksiteGKZs: [], retained: ["90001"]).isEmpty)
    }
}

struct PushUpgradeFrom124Tests {
    @Test func launchAndTokenResyncBeforeFirstSyncTouchNothing() async {
        let fixture = UpgradeFixture(legacyGKZs: ["60101", "90001"], pushEnabled: nil)

        let launch = await fixture.makeManager().resyncStoredState()
        fixture.client.token = "rotated-token"
        let tokenRefresh = await fixture.makeManager().resyncStoredState()

        #expect(launch == .success)
        #expect(tokenRefresh == .success)
        #expect(fixture.client.deleteTokenCalls == 0)
        #expect(fixture.client.unsubscribeCalls.isEmpty)
        #expect(fixture.client.subscribeCalls.isEmpty)
        #expect(fixture.store.migratedGKZs.isEmpty)
        #expect(!fixture.store.hasDesiredState)
        #expect(fixture.legacyKeysPresent)
    }

    @Test func firstDashboardSyncSubscribesV2AndDropsLegacyOnlyAfterConfirmation() async {
        let fixture = UpgradeFixture(legacyGKZs: ["60101", "90001"], pushEnabled: nil)
        fixture.client.failingTopics = ["warngebiet_v2_90001"]
        let manager = fixture.makeManager()
        await manager.resyncStoredState()

        let viewModel = fixture.makeViewModel(manager: manager)
        #expect(viewModel.isPushNotificationsEnabled)
        // No worksite has a GKZ yet, so the legacy GKZs are carried over instead of dropped.
        #expect(viewModel.desiredPushGKZs == ["60101", "90001"])
        await viewModel.syncPush()

        #expect(Set(fixture.client.subscribeCalls) == ["warngebiet_v2_60101", "warngebiet_v2_90001"])
        #expect(Set(fixture.client.unsubscribeCalls) == Set(PushTopics.legacyTopics(for: "60101")))
        #expect(fixture.client.deleteTokenCalls == 0)
        #expect(fixture.store.migratedGKZs == ["60101"])
        #expect(fixture.legacyKeysPresent)

        fixture.client.failingTopics = []
        fixture.client.resetCalls()
        let relaunch = await fixture.makeManager().resyncStoredState()

        #expect(relaunch == .success)
        #expect(Set(fixture.client.subscribeCalls) == ["warngebiet_v2_60101", "warngebiet_v2_90001"])
        #expect(Set(fixture.client.unsubscribeCalls) == Set(PushTopics.legacyTopics(for: "90001")))
        #expect(fixture.client.deleteTokenCalls == 0)
        #expect(fixture.store.subscribedGKZs == ["60101", "90001"])
        #expect(!fixture.legacyKeysPresent)
    }

    @Test func pushDisabledInOldVersionStaysOff() async {
        // 1.2.4 cleared its legacy list when push was switched off; a GKZ left over from a failed
        // unsubscribe must still be cleaned up rather than resubscribed.
        let fixture = UpgradeFixture(legacyGKZs: ["60101"], pushEnabled: false)
        let manager = fixture.makeManager()
        await manager.resyncStoredState()
        #expect(fixture.client.deleteTokenCalls == 0)

        let viewModel = fixture.makeViewModel(manager: manager)
        #expect(!viewModel.isPushNotificationsEnabled)
        await viewModel.syncPush()

        #expect(fixture.client.subscribeCalls.isEmpty)
        #expect(fixture.client.deleteTokenCalls == 1)
        #expect(!fixture.store.enabled)
        #expect(!fixture.legacyKeysPresent)
    }

    @Test func refreshFillsGKZsPerWorksiteAndNeverShrinksWhileOneIsUnknown() async throws {
        let latitudeA = 46.111111
        let latitudeB = 46.222222
        let fixture = UpgradeFixture(legacyGKZs: ["60101", "90001"], pushEnabled: nil, latitudeA: latitudeA, latitudeB: latitudeB)
        GeoSphereStub.set(.gkz("60101"), forLatitude: latitudeA)
        GeoSphereStub.set(.failure, forLatitude: latitudeB)
        defer {
            GeoSphereStub.remove(latitudes: [latitudeA, latitudeB])
        }
        let manager = fixture.makeManager()
        let viewModel = fixture.makeViewModel(manager: manager, dataService: DashboardDataService(urlSession: GeoSphereStub.session))

        await viewModel.refreshAll()

        let stored = DashboardViewModel.loadWorksites(from: fixture.defaults)
        #expect(stored.first { $0.id == fixture.worksiteA }?.municipalityID == "60101")
        #expect(stored.first { $0.id == fixture.worksiteB }?.municipalityID == nil)
        #expect(viewModel.loadState(for: fixture.worksiteB) == .failed)
        #expect(fixture.store.desiredGKZs == ["60101", "90001"])
        #expect(!fixture.client.unsubscribeCalls.contains { $0.hasPrefix("warngebiet_v2_") })

        GeoSphereStub.set(.gkz("30101"), forLatitude: latitudeB)
        fixture.client.resetCalls()
        await viewModel.refreshAll()

        #expect(fixture.store.desiredGKZs == ["60101", "30101"])
        #expect(fixture.client.subscribeCalls == ["warngebiet_v2_30101"])
        #expect(fixture.client.unsubscribeCalls.contains("warngebiet_v2_90001"))
        #expect(fixture.store.subscribedGKZs == ["60101", "30101"])
    }

    @Test func retainedGKZsIgnoreDesiredStateWhilePushIsOff() async {
        let fixture = UpgradeFixture(legacyGKZs: [], pushEnabled: nil)
        let manager = fixture.makeManager()
        fixture.client.failingTopics = ["warngebiet_v2_90001"]
        _ = await manager.sync(desiredGKZs: ["60101", "90001"], enabled: true)
        #expect(manager.retainedGKZs == ["60101", "90001"])

        _ = await manager.sync(desiredGKZs: ["60101", "90001"], enabled: false)
        #expect(manager.retainedGKZs.isEmpty)
    }
}

/// Serves GeoSphere lookups per latitude; Open-Meteo is always down (it is optional).
nonisolated final class GeoSphereStub: URLProtocol {
    enum Route: Sendable {
        case gkz(String)
        case failure
    }

    private static let routes = Mutex<[String: Route]>([:])

    static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GeoSphereStub.self]
        return URLSession(configuration: configuration)
    }()

    static func set(_ route: Route, forLatitude latitude: Double) {
        routes.withLock { $0[key(latitude)] = route }
    }

    static func remove(latitudes: [Double]) {
        routes.withLock { routes in
            for latitude in latitudes {
                routes[key(latitude)] = nil
            }
        }
    }

    private static func key(_ latitude: Double) -> String {
        String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), latitude)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        let latitude = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "lat" }?.value
        let route = latitude.flatMap { key in Self.routes.withLock { $0[key] } }

        let status: Int
        let body: String
        if case .gkz(let gkz) = route {
            status = 200
            body = #"{"type":"Feature","properties":{"location":{"properties":{"gemeindenr":"\#(gkz)","name":"Ort"}},"warnings":[]}}"#
        } else {
            status = 503
            body = ""
        }
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
