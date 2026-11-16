import Foundation
import CoreLocation
import Combine
import MapKit
import os

struct AddressSearchResult: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Summary the hero card and glance tiles are built from. "All clear" requires fresh data for
/// every worksite, so a failed or pending fetch can never look like a calm day.
struct DashboardStatus: Equatable {
    enum Phase: Equatable {
        case noWorksites
        case loading
        case failed
        case partial
        case complete
    }

    var phase: Phase
    var highestSeverity: HazardSeverity
    var heatWarningCount: Int
    var uvAffectedCount: Int
    var highestUV: Double?
    var highestApparentTemperature: Double?
    var oldestUpdate: Date?

    var isUvOnlyElevated: Bool {
        heatWarningCount == 0 && uvAffectedCount > 0
    }

    var hasWarning: Bool {
        heatWarningCount > 0 || highestSeverity.isHeatWarning
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    static let uvWarningThreshold = 5.0
    static let staleInterval: TimeInterval = 10 * 60

    @Published private(set) var worksites: [Worksite]
    @Published var addressQuery: String = ""
    @Published var nameInput: String = ""
    @Published private(set) var isPushNotificationsEnabled: Bool
    @Published private(set) var disabledPushWorksiteIDs: Set<UUID>
    @Published private(set) var addressResults: [AddressSearchResult] = []
    @Published private(set) var addressSearchMessage: DashboardUserMessage?
    @Published private(set) var isSearchingAddress = false
    @Published private(set) var addingResultID: String?
    @Published private(set) var snapshots: [UUID: WorksiteSnapshot] = [:]
    @Published private(set) var loadStates: [UUID: WorksiteLoadState] = [:]
    @Published private(set) var isRefreshing = false
    @Published private(set) var pushPermission: PushPermissionStatus?
    @Published private(set) var pushSyncResult: PushSyncResult?

    private let dataService: DashboardDataService
    private let mockModeController: MockModeController
    private let userDefaults: UserDefaults
    private let pushSync: (Set<String>, Bool) async -> PushSyncResult
    private let retainedPushGKZs: @MainActor () -> Set<String>
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    private var lastRefreshAttempt: Date?
    private var hasLoaded = false

    static let storageKey = "dashboard.worksites.v1"
    static let corruptBackupKey = "dashboard.worksites.v1.undecodable"
    private let pushEnabledKey = "push.notifications.enabled"
    private let disabledPushWorksiteIDsKey = "push.notifications.disabledWorksiteIds"

    init(
        dataService: DashboardDataService? = nil,
        mockModeController: MockModeController? = nil,
        userDefaults: UserDefaults? = nil,
        pushSync: ((Set<String>, Bool) async -> PushSyncResult)? = nil,
        retainedPushGKZs: (@MainActor () -> Set<String>)? = nil
    ) {
        let defaults = userDefaults ?? .standard
        self.dataService = dataService ?? DashboardDataService()
        self.mockModeController = mockModeController ?? .shared
        self.userDefaults = defaults
        self.pushSync = pushSync ?? { gkzs, enabled in
            await SubscriptionManager.shared.sync(desiredGKZs: gkzs, enabled: enabled)
        }
        self.retainedPushGKZs = retainedPushGKZs ?? { SubscriptionManager.shared.retainedGKZs }

        self.worksites = Self.loadWorksites(from: defaults)
        self.isPushNotificationsEnabled = defaults.object(forKey: pushEnabledKey) == nil ? true : defaults.bool(forKey: pushEnabledKey)
        let disabledIDs = defaults.stringArray(forKey: disabledPushWorksiteIDsKey) ?? []
        self.disabledPushWorksiteIDs = Set(disabledIDs.compactMap(UUID.init(uuidString:)))

        setupSubscribers()
    }

    var isMockModeEnabled: Bool { mockModeController.isEnabled }

    // MARK: - Status

    var status: DashboardStatus {
        Self.makeStatus(worksites: worksites, snapshots: snapshots, loadStates: loadStates)
    }

    static func makeStatus(
        worksites: [Worksite],
        snapshots: [UUID: WorksiteSnapshot],
        loadStates: [UUID: WorksiteLoadState]
    ) -> DashboardStatus {
        let available = worksites.compactMap { snapshots[$0.id] }
        let states = worksites.map { loadStates[$0.id] ?? (snapshots[$0.id] == nil ? .loading : .loaded) }

        let phase: DashboardStatus.Phase
        if worksites.isEmpty {
            phase = .noWorksites
        } else if states.allSatisfy({ $0 == .loaded }) {
            phase = .complete
        } else if states.contains(.failed) {
            phase = available.isEmpty ? .failed : .partial
        } else {
            phase = .loading
        }

        return DashboardStatus(
            phase: phase,
            highestSeverity: available.map(\.severity).max() ?? .none,
            heatWarningCount: available.filter { $0.severity.isHeatWarning }.count,
            uvAffectedCount: available.filter { ($0.uvIndex ?? 0) >= uvWarningThreshold }.count,
            highestUV: available.compactMap(\.uvIndex).max(),
            highestApparentTemperature: available.compactMap(\.apparentTemperature).max(),
            oldestUpdate: available.map(\.updatedAt).min()
        )
    }

    func loadState(for worksiteID: UUID) -> WorksiteLoadState {
        loadStates[worksiteID] ?? (snapshots[worksiteID] == nil ? .loading : .loaded)
    }

    func worksiteIDs(forMunicipalityID gkz: String) -> [UUID] {
        let normalized = Worksite.normalizedMunicipalityID(gkz)
        return worksites
            .filter { worksite in
                worksite.municipalityID == normalized
                    || (!isMockModeEnabled && snapshots[worksite.id]?.municipalityID == normalized)
            }
            .map(\.id)
    }

    // MARK: - Refresh

    func refreshIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refreshAll()
    }

    /// Called when the scene becomes active: reloads after ~10 minutes, when the Vienna date
    /// changed since the last load, or when any worksite has no fresh data.
    func refreshIfStale(now: Date = Date()) async {
        guard hasLoaded else { return }
        let needsRefresh: Bool
        if let lastRefreshAttempt {
            needsRefresh = now.timeIntervalSince(lastRefreshAttempt) > Self.staleInterval
                || !ViennaTime.calendar.isDate(lastRefreshAttempt, inSameDayAs: now)
                || worksites.contains { loadState(for: $0.id) == .failed }
        } else {
            needsRefresh = true
        }
        if needsRefresh {
            await refreshAll()
        }
    }

    func refreshAll() async {
        if let refreshTask {
            await refreshTask.value
            return
        }
        let task = Task { await performRefresh(ids: worksites.map(\.id)) }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    func retry(worksiteID: UUID) async {
        await performRefresh(ids: [worksiteID])
    }

    private func performRefresh(ids: [UUID]) async {
        let targets = worksites.filter { ids.contains($0.id) }
        guard !targets.isEmpty else { return }

        isRefreshing = true
        defer { isRefreshing = false }
        lastRefreshAttempt = Date()

        if mockModeController.isEnabled {
            for worksite in targets {
                snapshots[worksite.id] = MockSnapshotFactory.makeSnapshot(
                    for: worksite,
                    sessionSeed: mockModeController.sessionSeed
                )
                loadStates[worksite.id] = .loaded
            }
            return
        }

        for worksite in targets {
            loadStates[worksite.id] = .loading
        }

        let service = dataService
        let results = await withTaskGroup(of: (UUID, Result<WorksiteSnapshot, Error>).self) { group in
            for worksite in targets {
                let coordinate = worksite.coordinate
                group.addTask {
                    do {
                        return (worksite.id, .success(try await service.fetchSnapshot(for: coordinate)))
                    } catch {
                        return (worksite.id, .failure(error))
                    }
                }
            }
            var collected: [(UUID, Result<WorksiteSnapshot, Error>)] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        // Mock mode may have been switched on while the requests were in flight.
        guard !mockModeController.isEnabled else { return }

        var didChangeMunicipality = false
        for (id, result) in results {
            switch result {
            case .success(let snapshot):
                snapshots[id] = snapshot
                loadStates[id] = .loaded
                if let index = worksites.firstIndex(where: { $0.id == id }),
                   worksites[index].municipalityID != snapshot.municipalityID {
                    worksites[index].municipalityID = snapshot.municipalityID
                    didChangeMunicipality = true
                }
            case .failure(let error):
                loadStates[id] = error is CancellationError ? (snapshots[id] == nil ? .failed : .loaded) : .failed
                dashboardLogger.error("Refresh failed for worksite \(id.uuidString, privacy: .private): \(error.localizedDescription, privacy: .public)")
            }
        }

        if didChangeMunicipality {
            persistWorksites()
        }
        await syncPush()
    }

    // MARK: - Push

    func refreshPermissionStatus() async {
        pushPermission = await PushPermission.currentStatus()
    }

    func requestPermissionFromExplainer() async {
        pushPermission = await PushPermission.requestFromExplainer()
    }

    /// GKZs of worksites whose push toggle is on. Only real, persisted GKZs are used, so mock
    /// data can never change subscriptions.
    var desiredPushGKZs: Set<String> {
        PushDesiredGKZs.resolve(
            worksiteGKZs: activePushWorksites().map(\.municipalityID),
            retained: retainedPushGKZs()
        )
    }

    func syncPush() async {
        let result = await pushSync(desiredPushGKZs, isPushNotificationsEnabled)
        pushSyncResult = result
        if let description = result.errorDescription {
            dashboardLogger.error("Push sync failed: \(description, privacy: .public)")
        }
    }

    var hasPushSyncError: Bool {
        guard let pushSyncResult else { return false }
        return pushSyncResult.errorDescription != nil || !pushSyncResult.failedGKZs.isEmpty
    }

    func setPushNotificationsEnabled(_ isEnabled: Bool) async {
        isPushNotificationsEnabled = isEnabled
        userDefaults.set(isEnabled, forKey: pushEnabledKey)
        await syncPush()
    }

    func setPushEnabled(_ isEnabled: Bool, forWorksiteID worksiteID: UUID) async {
        if isEnabled {
            disabledPushWorksiteIDs.remove(worksiteID)
        } else {
            disabledPushWorksiteIDs.insert(worksiteID)
        }
        persistDisabledPushWorksiteIDs()
        await syncPush()
    }

    func isPushEnabled(forWorksiteID worksiteID: UUID) -> Bool {
        !disabledPushWorksiteIDs.contains(worksiteID)
    }

    private func activePushWorksites() -> [Worksite] {
        worksites.filter { !disabledPushWorksiteIDs.contains($0.id) }
    }

    // MARK: - Add / delete

    func resetAddWorkplaceForm() {
        addressQuery = ""
        nameInput = ""
        addressResults = []
        addressSearchMessage = nil
        isSearchingAddress = false
    }

    private func setupSubscribers() {
        $addressQuery
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                guard !query.isEmpty else {
                    self.addressResults = []
                    self.addressSearchMessage = nil
                    return
                }
                Task { await self.searchAddress() }
            }
            .store(in: &cancellables)
    }

    func searchAddress() async {
        let query = addressQuery.trimmed
        guard !query.isEmpty else {
            addressResults = []
            addressSearchMessage = nil
            return
        }

        addressSearchMessage = nil
        isSearchingAddress = true
        defer { isSearchingAddress = false }

        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = [.address, .pointOfInterest]
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 47.5162, longitude: 14.5501),
                span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 7.5)
            )

            let response = try await MKLocalSearch(request: request).start()
            // A newer query has replaced this one while it was running.
            guard query == addressQuery.trimmed else { return }
            let mapped = mapAddressResults(from: response.mapItems)
            addressResults = mapped
            addressSearchMessage = mapped.isEmpty ? .noMatchingAddress : nil
        } catch {
            guard query == addressQuery.trimmed else { return }
            addressResults = []
            addressSearchMessage = .addressSearchFailed
        }
    }

    /// Validates the location with GeoSphere (also in mock mode), stores the worksite with its
    /// GKZ and the validation snapshot, then syncs push in the background.
    func addWorksite(fromAddressResult result: AddressSearchResult) async -> Bool {
        guard addingResultID == nil else { return false }
        addingResultID = result.id
        defer { addingResultID = nil }
        addressSearchMessage = nil

        let snapshot: WorksiteSnapshot
        do {
            snapshot = try await dataService.fetchSnapshot(for: result.coordinate)
        } catch {
            addressSearchMessage = userMessage(for: error)
            return false
        }

        let trimmedName = nameInput.trimmed
        let worksite = Worksite(
            name: trimmedName.isEmpty ? result.title : trimmedName,
            address: result.subtitle,
            latitude: result.latitude,
            longitude: result.longitude,
            municipalityID: snapshot.municipalityID
        )

        worksites.append(worksite)
        persistWorksites()
        snapshots[worksite.id] = mockModeController.isEnabled
            ? MockSnapshotFactory.makeSnapshot(for: worksite, sessionSeed: mockModeController.sessionSeed)
            : snapshot
        loadStates[worksite.id] = .loaded

        resetAddWorkplaceForm()

        Task { await syncPush() }
        return true
    }

    func deleteWorksite(id: UUID) async {
        guard worksites.contains(where: { $0.id == id }) else { return }
        worksites.removeAll { $0.id == id }
        snapshots.removeValue(forKey: id)
        loadStates.removeValue(forKey: id)
        disabledPushWorksiteIDs.remove(id)
        persistWorksites()
        persistDisabledPushWorksiteIDs()
        await syncPush()
    }

    // MARK: - Mock mode

    func activateMockMode() async {
        mockModeController.activate()
        await refreshAll()
    }

    // MARK: - Persistence

    /// Decodes worksite by worksite so one bad entry cannot wipe the rest; the undecodable raw
    /// data is kept under a backup key instead of being overwritten.
    static func loadWorksites(from defaults: UserDefaults) -> [Worksite] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        if let decoded = try? JSONDecoder().decode([Worksite].self, from: data) {
            return decoded
        }

        let lossy = (try? JSONDecoder().decode([LossyWorksite].self, from: data)) ?? []
        let recovered = lossy.compactMap(\.worksite)
        dashboardLogger.error("Stored worksites could not be fully decoded; recovered \(recovered.count, privacy: .public) of \(lossy.count, privacy: .public)")
        if defaults.data(forKey: corruptBackupKey) == nil {
            defaults.set(data, forKey: corruptBackupKey)
        }
        return recovered
    }

    private func persistWorksites() {
        do {
            userDefaults.set(try JSONEncoder().encode(worksites), forKey: Self.storageKey)
        } catch {
            dashboardLogger.error("Persisting worksites failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func persistDisabledPushWorksiteIDs() {
        userDefaults.set(disabledPushWorksiteIDs.map(\.uuidString).sorted(), forKey: disabledPushWorksiteIDsKey)
    }

    // MARK: - Helpers

    private func mapAddressResults(from mapItems: [MKMapItem]) -> [AddressSearchResult] {
        var seen = Set<String>()
        var results: [AddressSearchResult] = []

        for mapItem in mapItems {
            let coordinate = mapItem.location.coordinate
            let subtitle = formattedAddress(from: mapItem)
            let preferredTitle = mapItem.name?.trimmed
            let title = (preferredTitle?.isEmpty == false ? preferredTitle : nil) ?? subtitle

            let key = "\(subtitle.lowercased())|\(String(format: "%.4f", coordinate.latitude))|\(String(format: "%.4f", coordinate.longitude))"
            guard seen.insert(key).inserted else { continue }

            results.append(AddressSearchResult(
                id: key,
                title: title,
                subtitle: subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ))
            if results.count == 6 { break }
        }
        return results
    }

    private func formattedAddress(from mapItem: MKMapItem) -> String {
        if let fullAddress = mapItem.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true)?.trimmed,
           !fullAddress.isEmpty {
            return fullAddress
        }
        if let fullAddress = mapItem.address?.fullAddress.trimmed, !fullAddress.isEmpty {
            return fullAddress
        }
        if let shortAddress = mapItem.address?.shortAddress?.trimmed, !shortAddress.isEmpty {
            return shortAddress
        }
        if let name = mapItem.name?.trimmed, !name.isEmpty {
            return name
        }
        let coordinate = mapItem.location.coordinate
        return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    private func userMessage(for error: Error) -> DashboardUserMessage {
        switch error {
        case DashboardDataError.municipalityNotFound:
            return .unsupportedArea
        case DashboardDataError.invalidRequest, DashboardDataError.invalidGeoSphereResponse, DashboardDataError.network:
            return .liveDataUnavailable
        default:
            return .workplaceCouldNotBeAdded
        }
    }
}

private nonisolated struct LossyWorksite: Decodable {
    let worksite: Worksite?

    init(from decoder: Decoder) throws {
        worksite = try? Worksite(from: decoder)
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
