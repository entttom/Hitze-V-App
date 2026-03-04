import Foundation
import CoreLocation
import Combine
import MapKit

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

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var worksites: [Worksite]
    @Published var addressQuery: String = ""
    @Published var nameInput: String = ""
    @Published private(set) var addressResults: [AddressSearchResult] = []
    @Published private(set) var addressSearchMessage: String?
    @Published private(set) var isSearchingAddress = false
    @Published private(set) var snapshots: [UUID: WorksiteSnapshot] = [:]
    @Published private(set) var isRefreshing = false
    @Published private(set) var statusMessage: String?

    private var cancellables = Set<AnyCancellable>()

    let subscriptionManager: SubscriptionManager

    private let dataService: DashboardDataService
    private let userDefaults: UserDefaults
    private let storageKey = "dashboard.worksites.v1"
    private var hasLoaded = false

    init(
        subscriptionManager: SubscriptionManager? = nil,
        dataService: DashboardDataService? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.subscriptionManager = subscriptionManager ?? SubscriptionManager()
        self.dataService = dataService ?? DashboardDataService()
        self.userDefaults = userDefaults

        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Worksite].self, from: data),
           !decoded.isEmpty {
            self.worksites = decoded
        } else {
            self.worksites = [
                Worksite(
                    name: "Arbeitsplatz Wien",
                    address: "Stephansplatz, 1010 Wien, Oesterreich",
                    latitude: 48.2082,
                    longitude: 16.3738
                )
            ]
        }

        setupSubscribers()
    }

    func refreshIfNeeded() async {
        guard !hasLoaded else {
            return
        }

        hasLoaded = true
        await refreshAll()
    }

    func refreshAll() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        statusMessage = nil
        defer { isRefreshing = false }

        var nextSnapshots = snapshots
        var errors: [String] = []

        for worksite in worksites {
            do {
                let snapshot = try await dataService.fetchSnapshot(for: worksite.coordinate)
                nextSnapshots[worksite.id] = snapshot
            } catch {
                errors.append(error.localizedDescription)
            }
        }

        snapshots = nextSnapshots

        await subscriptionManager.syncTopics(for: worksites.map(\.coordinate))
        if let error = subscriptionManager.lastError?.errorDescription {
            errors.append(error)
        }

        if errors.isEmpty {
            statusMessage = nil
        } else {
            statusMessage = errors.joined(separator: "\n")
        }
    }

    private func setupSubscribers() {
        $addressQuery
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.searchAddress()
                }
            }
            .store(in: &cancellables)
    }

    func searchAddress() async {
        addressSearchMessage = nil

        let query = addressQuery.trimmed
        guard !query.isEmpty else {
            addressResults = []
            addressSearchMessage = "Bitte eine Adresse eingeben. / Please enter an address."
            return
        }

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
            let mapped = mapAddressResults(from: response.mapItems)

            guard !mapped.isEmpty else {
                addressResults = []
                addressSearchMessage = "Keine passende Adresse gefunden. / No matching address found."
                return
            }

            addressResults = mapped
        } catch {
            addressResults = []
            addressSearchMessage = "Adresssuche fehlgeschlagen. / Address search failed."
        }
    }

    func addWorksite(fromAddressResult result: AddressSearchResult) async {
        statusMessage = nil

        let trimmedName = nameInput.trimmed
        let worksite = Worksite(
            name: trimmedName.isEmpty ? result.title : trimmedName,
            address: result.subtitle,
            latitude: result.latitude,
            longitude: result.longitude
        )

        worksites.append(worksite)
        persistWorksites()

        nameInput = ""
        addressQuery = ""
        addressResults = []
        addressSearchMessage = nil

        await refreshAll()
    }

    func deleteWorksites(at offsets: IndexSet) async {
        let removedIDs = offsets.compactMap { index -> UUID? in
            guard worksites.indices.contains(index) else {
                return nil
            }

            return worksites[index].id
        }

        worksites = worksites.enumerated().compactMap { item in
            offsets.contains(item.offset) ? nil : item.element
        }

        for id in removedIDs {
            snapshots.removeValue(forKey: id)
        }

        persistWorksites()

        await subscriptionManager.syncTopics(for: worksites.map(\.coordinate))
        if let error = subscriptionManager.lastError?.errorDescription {
            statusMessage = error
        }
    }

    func deleteWorksite(id: UUID) async {
        guard let index = worksites.firstIndex(where: { $0.id == id }) else {
            return
        }

        await deleteWorksites(at: IndexSet(integer: index))
    }

    private func mapAddressResults(from mapItems: [MKMapItem]) -> [AddressSearchResult] {
        var seen = Set<String>()
        var results: [AddressSearchResult] = []

        for mapItem in mapItems {
            let coordinate = mapItem.location.coordinate

            let subtitle = formattedAddress(from: mapItem)
            let preferredTitle = mapItem.name?.trimmed
            let title = (preferredTitle?.isEmpty == false ? preferredTitle : nil) ?? subtitle

            let key = "\(subtitle.lowercased())|\(String(format: "%.4f", coordinate.latitude))|\(String(format: "%.4f", coordinate.longitude))"
            guard seen.insert(key).inserted else {
                continue
            }

            results.append(
                AddressSearchResult(
                    id: key,
                    title: title,
                    subtitle: subtitle,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            )

            if results.count == 6 {
                break
            }
        }

        return results
    }

    private func formattedAddress(from mapItem: MKMapItem) -> String {
        // Fallback to manual formatting if Contacts framework isn't available
        let placemark = mapItem.placemark
        var components: [String] = []
        
        if let street = placemark.thoroughfare {
            var fullStreet = street
            if let houseNumber = placemark.subThoroughfare {
                fullStreet += " \(houseNumber)"
            }
            components.append(fullStreet)
        }
        
        if let postalCode = placemark.postalCode, let city = placemark.locality {
            components.append("\(postalCode) \(city)")
        } else if let city = placemark.locality {
            components.append(city)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        let addressString = components.joined(separator: ", ").trimmed
        if !addressString.isEmpty {
            return addressString
        }

        if let fallbackName = mapItem.name?.trimmed, !fallbackName.isEmpty {
            return fallbackName
        }

        return "Unbekannte Adresse"
    }

    private func persistWorksites() {
        if let encoded = try? JSONEncoder().encode(worksites) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
