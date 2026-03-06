import Foundation
import CoreLocation
import Combine
import FirebaseMessaging

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var subscribedMunicipalityIDs: Set<String>
    @Published private(set) var lastError: SubscriptionError?

    private let urlSession: URLSession
    private let userDefaults: UserDefaults
    private let userDefaultsKey = "subscription_manager.subscribedMunicipalityIDs"

    private let geosphereBaseURL = "https://warnungen.zamg.at/wsapp/api/getWarningsForCoords"
    private let networkTimeout: TimeInterval = 10

    init(urlSession: URLSession = .shared, userDefaults: UserDefaults = .standard) {
        self.urlSession = urlSession
        self.userDefaults = userDefaults

        let persisted = userDefaults.stringArray(forKey: userDefaultsKey) ?? []
        self.subscribedMunicipalityIDs = Set(persisted.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        self.lastError = nil
    }

    /// Synchronisiert ein einzelnes Arbeitsplatz-Topic anhand einer Koordinate.
    func syncTopic(for coordinate: CLLocationCoordinate2D) async {
        await syncTopics(for: [coordinate])
    }

    /// Synchronisiert Topics für mehrere Arbeitsplaetze. Bei Lookup-Teilfehlern wird nur additiv synchronisiert.
    func syncTopics(for coordinates: [CLLocationCoordinate2D]) async {
        lastError = nil

        if coordinates.isEmpty {
            let errors = await synchronizeTopics(desiredMunicipalityIDs: [], allowUnsubscribe: true)
            apply(errors: errors)
            return
        }

        var resolvedMunicipalityIDs = Set<String>()
        var lookupErrors: [SubscriptionError] = []

        for coordinate in coordinates {
            do {
                let municipalityID = try await fetchMunicipalityID(for: coordinate)
                resolvedMunicipalityIDs.insert(municipalityID)
            } catch let error as SubscriptionError {
                lookupErrors.append(error)
            } catch {
                lookupErrors.append(.network(message: error.localizedDescription))
            }
        }

        // Keine destruktiven Unsubscribes durchführen, wenn kein einziger Standort erfolgreich aufgelöst wurde.
        if resolvedMunicipalityIDs.isEmpty {
            apply(errors: lookupErrors.isEmpty ? [.invalidResponse] : lookupErrors)
            return
        }

        // Bei teilweisem Lookup-Fehler nur additiv synchronisieren, um versehentliche Topic-Verluste zu vermeiden.
        let syncErrors = await synchronizeTopics(
            desiredMunicipalityIDs: resolvedMunicipalityIDs,
            allowUnsubscribe: lookupErrors.isEmpty
        )

        apply(errors: lookupErrors + syncErrors)
    }

    /// Entfernt alle aktuellen Topic-Abonnements.
    func unsubscribeAll() async {
        lastError = nil
        let errors = await synchronizeTopics(desiredMunicipalityIDs: [], allowUnsubscribe: true)
        apply(errors: errors)
    }

    private func apply(errors: [SubscriptionError]) {
        if errors.isEmpty {
            lastError = nil
            return
        }

        if errors.count == 1 {
            lastError = errors[0]
            return
        }

        lastError = .partialSync(
            message: "Topic-Synchronisierung mit Teilfehlern abgeschlossen.",
            failures: errors.count
        )
    }

    private func synchronizeTopics(
        desiredMunicipalityIDs: Set<String>,
        allowUnsubscribe: Bool
    ) async -> [SubscriptionError] {
        var errors: [SubscriptionError] = []
        var workingSet = subscribedMunicipalityIDs

        let toSubscribe = desiredMunicipalityIDs.subtracting(workingSet)
        let toUnsubscribe = allowUnsubscribe ? workingSet.subtracting(desiredMunicipalityIDs) : Set<String>()

        if !toSubscribe.isEmpty || !toUnsubscribe.isEmpty {
            do {
                try await FirebaseRegistrationManager.shared.registerForPushNotificationsIfNeeded()
                print("Firebase registration successful.")
            } catch {
                print("Firebase registration failed: \(error.localizedDescription)")
                errors.append(.firebaseRegistration(message: error.localizedDescription))
                return errors
            }
        }

        for municipalityID in toSubscribe.sorted() {
            do {
                try await subscribe(toMunicipalityID: municipalityID)
                workingSet.insert(municipalityID)
                print("Subscribed municipalityId: \(municipalityID)")
            } catch let error as SubscriptionError {
                errors.append(error)
            } catch {
                errors.append(.firebase(message: error.localizedDescription))
            }
        }

        for municipalityID in toUnsubscribe.sorted() {
            do {
                try await unsubscribe(fromMunicipalityID: municipalityID)
                workingSet.remove(municipalityID)
                print("Unsubscribed municipalityId: \(municipalityID)")
            } catch let error as SubscriptionError {
                errors.append(error)
            } catch {
                errors.append(.firebase(message: error.localizedDescription))
            }
        }

        subscribedMunicipalityIDs = workingSet
        persistSubscribedMunicipalityIDs()

        if workingSet.isEmpty {
            do {
                try await FirebaseRegistrationManager.shared.deregisterFromFirebase()
                print("Firebase deregistration successful.")
            } catch {
                print("Firebase deregistration failed: \(error.localizedDescription)")
                // Ignore deregistration cleanup failures to avoid noisy UI errors.
            }
        }

        return errors
    }

    private func fetchMunicipalityID(for coordinate: CLLocationCoordinate2D) async throws -> String {
        var components = URLComponents(string: geosphereBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.6f", coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(format: "%.6f", coordinate.longitude))
        ]

        guard let url = components?.url else {
            throw SubscriptionError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = networkTimeout

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw SubscriptionError.network(message: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SubscriptionError.network(message: "GeoSphere HTTP \(httpResponse.statusCode)")
        }

        let decoded: GeoSphereLookupResponse
        do {
            decoded = try JSONDecoder().decode(GeoSphereLookupResponse.self, from: data)
        } catch {
            throw SubscriptionError.invalidResponse
        }

        if decoded.type.lowercased() == "error" {
            throw SubscriptionError.municipalityNotFound(
                message: decoded.msg ?? "Could not find municipal for coords."
            )
        }

        guard let municipalityID = decoded.properties?.location?.properties?.gemeindenr.value,
              !municipalityID.isEmpty else {
            throw SubscriptionError.invalidResponse
        }

        return municipalityID
    }

    private func subscribe(toMunicipalityID municipalityID: String) async throws {
        let topic = topicName(for: municipalityID)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            Messaging.messaging().subscribe(toTopic: topic) { error in
                if let error {
                    continuation.resume(throwing: SubscriptionError.firebase(
                        message: "FCM subscribe failed for \(topic): \(error.localizedDescription)"
                    ))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func unsubscribe(fromMunicipalityID municipalityID: String) async throws {
        let topic = topicName(for: municipalityID)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                if let error {
                    continuation.resume(throwing: SubscriptionError.firebase(
                        message: "FCM unsubscribe failed for \(topic): \(error.localizedDescription)"
                    ))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func topicName(for municipalityID: String) -> String {
        "warngebiet_\(municipalityID)"
    }

    private func persistSubscribedMunicipalityIDs() {
        userDefaults.set(subscribedMunicipalityIDs.sorted(), forKey: userDefaultsKey)
    }
}

enum SubscriptionError: Error, LocalizedError {
    case invalidResponse
    case network(message: String)
    case municipalityNotFound(message: String)
    case firebase(message: String)
    case firebaseRegistration(message: String)
    case partialSync(message: String, failures: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Ungültige Antwortstruktur von GeoSphere."
        case .network(let message):
            return "Netzwerkfehler: \(message)"
        case .municipalityNotFound(let message):
            return "Gemeinde konnte nicht ermittelt werden: \(message)"
        case .firebase(let message):
            return "Firebase Messaging Fehler: \(message)"
        case .firebaseRegistration(let message):
            return "Firebase Registrierung Fehler: \(message)"
        case .partialSync(let message, let failures):
            return "\(message) Fehlgeschlagene Operationen: \(failures)."
        }
    }
}

private struct GeoSphereLookupResponse: Decodable {
    let type: String
    let msg: String?
    let properties: GeoSphereLookupProperties?
}

private struct GeoSphereLookupProperties: Decodable {
    let location: GeoSphereLocation?
}

private struct GeoSphereLocation: Decodable {
    let properties: GeoSphereMunicipality?
}

private struct GeoSphereMunicipality: Decodable {
    let gemeindenr: MunicipalityIdentifier
}

private struct MunicipalityIdentifier: Decodable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = String(intValue)
            return
        }

        if let stringValue = try? container.decode(String.self) {
            value = stringValue
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported gemeindenr format")
    }
}
