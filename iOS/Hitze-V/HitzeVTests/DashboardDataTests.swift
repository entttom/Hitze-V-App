import Foundation
import Testing
@testable import Hitze_V

@MainActor
struct DashboardDataTests {
    // 2026-07-07 10:00 Europe/Vienna
    private let now = Date(timeIntervalSince1970: 1_783_411_200)

    private func geoSphere(level: Int, start: String = "07.07.2026 08:00", end: String = "07.07.2026 18:00") -> Data {
        Data("""
        {"type":"Feature","properties":{"location":{"properties":{"gemeindenr":" 60101 ","name":"Graz  Stadt"}},
         "warnings":[{"properties":{"warntypid":6,"warnstufeid":\(level),"begin":"\(start)","end":"\(end)"}}]}}
        """.utf8)
    }

    @Test func geoSphereAloneProducesWarningWhenOpenMeteoIsMissing() throws {
        let snapshot = try DashboardDataService.makeSnapshot(geoSphereData: geoSphere(level: 2), openMeteoData: nil, now: now)
        #expect(snapshot.severity == .heatOrange)
        #expect(snapshot.municipalityID == "60101")
        #expect(snapshot.municipalityName == "Graz Stadt")
        #expect(snapshot.uvIndex == nil)
        #expect(snapshot.apparentTemperature == nil)
        #expect(snapshot.forecasts.count == DashboardDataService.forecastDayCount)
    }

    @Test func openMeteoValuesAreMatchedByDateAndShortArraysAreTolerated() throws {
        let meteo = Data("""
        {"daily":{"time":["2026-07-07","2026-07-08","2026-07-09","2026-07-10"],
                  "uv_index_max":[6.4],
                  "apparent_temperature_max":[27.5,41.2,null,30.0]}}
        """.utf8)
        let snapshot = try DashboardDataService.makeSnapshot(geoSphereData: geoSphere(level: 1), openMeteoData: meteo, now: now)
        #expect(snapshot.uvIndex == 6.4)
        // Raw Open-Meteo value, no clamp to the warning level's threshold.
        #expect(snapshot.apparentTemperature == 27.5)
        #expect(snapshot.forecasts[1].apparentTemperatureMax == 41.2)
        #expect(snapshot.forecasts[1].uvIndexMax == nil)
        #expect(snapshot.forecasts[2].apparentTemperatureMax == nil)
    }

    @Test func warningOutsideTodayDoesNotRaiseToday() throws {
        let data = geoSphere(level: 3, start: "08.07.2026 10:00", end: "08.07.2026 17:00")
        let snapshot = try DashboardDataService.makeSnapshot(geoSphereData: data, openMeteoData: nil, now: now)
        #expect(snapshot.severity == .none)
        #expect(snapshot.forecasts[1].severity == .heatRed)
        #expect(snapshot.forecasts[1].warningTimeRanges.count == 1)
    }

    @Test func geoSphereErrorIsMunicipalityNotFound() {
        let data = Data(#"{"type":"error","msg":"Could not find municipal for coords."}"#.utf8)
        #expect(throws: DashboardDataError.self) {
            try DashboardDataService.makeSnapshot(geoSphereData: data, openMeteoData: nil, now: now)
        }
    }

    @Test func statusNeverClaimsAllClearWithoutFreshDataForEveryWorksite() {
        let a = Worksite(name: "A", latitude: 48, longitude: 16)
        let b = Worksite(name: "B", latitude: 47, longitude: 15)
        let calm = WorksiteSnapshot(municipalityID: "1", municipalityName: nil, severity: .none, uvIndex: 2, apparentTemperature: 20, forecasts: [], updatedAt: now)

        let loading = DashboardViewModel.makeStatus(worksites: [a, b], snapshots: [a.id: calm], loadStates: [a.id: .loaded, b.id: .loading])
        #expect(loading.phase == .loading)

        let partial = DashboardViewModel.makeStatus(worksites: [a, b], snapshots: [a.id: calm], loadStates: [a.id: .loaded, b.id: .failed])
        #expect(partial.phase == .partial)

        let failed = DashboardViewModel.makeStatus(worksites: [a], snapshots: [:], loadStates: [a.id: .failed])
        #expect(failed.phase == .failed)

        let complete = DashboardViewModel.makeStatus(worksites: [a], snapshots: [a.id: calm], loadStates: [a.id: .loaded])
        #expect(complete.phase == .complete)
        #expect(!complete.hasWarning)
    }

    @Test func oldWorksiteDataDecodesWithoutMunicipalityID() throws {
        let json = Data(#"[{"id":"3F2504E0-4F89-11D3-9A0C-0305E82C3301","name":"Baustelle","latitude":48.2,"longitude":16.37}]"#.utf8)
        let defaults = try #require(UserDefaults(suiteName: "DashboardDataTests.old"))
        defaults.removePersistentDomain(forName: "DashboardDataTests.old")
        defaults.set(json, forKey: DashboardViewModel.storageKey)
        let worksites = DashboardViewModel.loadWorksites(from: defaults)
        #expect(worksites.count == 1)
        #expect(worksites.first?.municipalityID == nil)
    }

    @Test func undecodableEntryKeepsTheRestAndBacksUpRawData() throws {
        let json = Data(#"[{"id":"3F2504E0-4F89-11D3-9A0C-0305E82C3301","name":"OK","latitude":48.2,"longitude":16.37},{"name":"broken"}]"#.utf8)
        let suite = "DashboardDataTests.lossy"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defaults.set(json, forKey: DashboardViewModel.storageKey)
        let worksites = DashboardViewModel.loadWorksites(from: defaults)
        #expect(worksites.map(\.name) == ["OK"])
        #expect(defaults.data(forKey: DashboardViewModel.corruptBackupKey) == json)
    }

    @Test func pushSyncUsesOnlyPersistedGKZsOfEnabledWorksites() async throws {
        let suite = "DashboardDataTests.push"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let on = Worksite(name: "On", latitude: 48, longitude: 16, municipalityID: "90001")
        let off = Worksite(name: "Off", latitude: 47, longitude: 15, municipalityID: "60101")
        defaults.set(try JSONEncoder().encode([on, off]), forKey: DashboardViewModel.storageKey)
        defaults.set([off.id.uuidString], forKey: "push.notifications.disabledWorksiteIds")

        var received: (Set<String>, Bool)?
        let viewModel = DashboardViewModel(userDefaults: defaults) { gkzs, enabled in
            received = (gkzs, enabled)
            return .success
        }
        await viewModel.syncPush()
        #expect(received?.0 == ["90001"])
        #expect(received?.1 == true)
    }
}
