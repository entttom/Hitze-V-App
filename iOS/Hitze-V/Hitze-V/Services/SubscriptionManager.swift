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
    private let languageDefaultsKey = "subscription_manager.lastSubscribedLanguageCode"
    private let defaultGeoSphereBaseURL = "https://warnungen.zamg.at/wsapp/api/getWarningsForCoords"
    private let networkTimeout: TimeInterval = 10
    private let defaultLanguageCode = "en"

    init(urlSession: URLSession = .shared, userDefaults: UserDefaults = .standard) {
        self.urlSession = urlSession
        self.userDefaults = userDefaults

        let persisted = userDefaults.stringArray(forKey: userDefaultsKey) ?? []
        self.subscribedMunicipalityIDs = Set(persisted.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        self.lastError = nil
    }

    private var geosphereBaseURL: String {
        if AppFeatureFlags.enableCustomGeoSphereURLSetting {
            let configuredURL = userDefaults.string(forKey: "network.customGeoSphereUrl")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !configuredURL.isEmpty {
                return configuredURL
            }
        }

        return defaultGeoSphereBaseURL
    }

    private var customGeoSphereURL: String? {
        guard AppFeatureFlags.enableCustomGeoSphereURLSetting else {
            return nil
        }

        let configuredURL = userDefaults.string(forKey: "network.customGeoSphereUrl")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return configuredURL.isEmpty ? nil : configuredURL
    }

    /// Synchronisiert ein einzelnes Arbeitsplatz-Topic anhand einer Koordinate.
    func syncTopic(for coordinate: CLLocationCoordinate2D, languageCode: String) async {
        await syncTopics(for: [coordinate], languageCode: languageCode)
    }

    /// Synchronisiert Topics für mehrere Arbeitsplaetze. Bei Lookup-Teilfehlern wird nur additiv synchronisiert.
    func syncTopics(for coordinates: [CLLocationCoordinate2D], languageCode: String) async {
        lastError = nil
        let desiredLanguageCode = normalizeLanguageCode(languageCode)
        let storedLanguageCode = storedSubscribedLanguageCode()
        let previousLanguageCode = storedLanguageCode ?? desiredLanguageCode

        if coordinates.isEmpty {
            let errors = await synchronizeTopics(
                desiredMunicipalityIDs: [],
                previousLanguageCode: previousLanguageCode,
                desiredLanguageCode: desiredLanguageCode,
                hasStoredLanguageCode: storedLanguageCode != nil,
                allowUnsubscribe: true
            )
            apply(errors: errors)
            return
        }

        var resolvedMunicipalityIDs = Set<String>()
        var lookupErrors: [SubscriptionError] = []

        for coordinate in coordinates {
            do {
                let municipalityID = try await fetchMunicipalityID(for: coordinate)
                resolvedMunicipalityIDs.insert(municipalityID)
            } catch is CancellationError {
                NSLog("GeoSphere subscription lookup cancelled")
                return
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
            previousLanguageCode: previousLanguageCode,
            desiredLanguageCode: desiredLanguageCode,
            hasStoredLanguageCode: storedLanguageCode != nil,
            allowUnsubscribe: lookupErrors.isEmpty
        )

        apply(errors: lookupErrors + syncErrors)
    }

    /// Entfernt alle aktuellen Topic-Abonnements.
    func unsubscribeAll() async {
        lastError = nil
        let currentLanguageCode = storedSubscribedLanguageCode() ?? defaultLanguageCode
        let errors = await synchronizeTopics(
            desiredMunicipalityIDs: [],
            previousLanguageCode: currentLanguageCode,
            desiredLanguageCode: currentLanguageCode,
            hasStoredLanguageCode: true,
            allowUnsubscribe: true
        )
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
        previousLanguageCode: String,
        desiredLanguageCode: String,
        hasStoredLanguageCode: Bool,
        allowUnsubscribe: Bool
    ) async -> [SubscriptionError] {
        var errors: [SubscriptionError] = []
        var workingSet = subscribedMunicipalityIDs
        let languageChanged = previousLanguageCode != desiredLanguageCode
        let requiresTopicMigration = !hasStoredLanguageCode
        let shouldResubscribeAll = languageChanged || requiresTopicMigration

        let toSubscribe = shouldResubscribeAll ? desiredMunicipalityIDs : desiredMunicipalityIDs.subtracting(workingSet)
        let toUnsubscribe = allowUnsubscribe
            ? (shouldResubscribeAll ? workingSet : workingSet.subtracting(desiredMunicipalityIDs))
            : Set<String>()
        let shouldCleanupLegacyTopics = allowUnsubscribe && previousLanguageCode == desiredLanguageCode && !hasStoredLanguageCode
        var successfulTargetSubscriptions = Set<String>()

        if !toSubscribe.isEmpty || !toUnsubscribe.isEmpty || shouldCleanupLegacyTopics {
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
                try await subscribe(
                    toMunicipalityID: municipalityID,
                    languageCode: desiredLanguageCode
                )
                workingSet.insert(municipalityID)
                successfulTargetSubscriptions.insert(municipalityID)
                print("Subscribed municipalityId: \(municipalityID)")
            } catch let error as SubscriptionError {
                errors.append(error)
            } catch {
                errors.append(.firebase(message: error.localizedDescription))
            }
        }

        for municipalityID in toUnsubscribe.sorted() {
            let shouldUnsubscribe: Bool
            if !shouldResubscribeAll {
                shouldUnsubscribe = true
            } else {
                shouldUnsubscribe = !desiredMunicipalityIDs.contains(municipalityID) || successfulTargetSubscriptions.contains(municipalityID)
            }

            if !shouldUnsubscribe {
                continue
            }

            do {
                try await unsubscribe(
                    fromMunicipalityID: municipalityID,
                    languageCode: previousLanguageCode
                )
                if !desiredMunicipalityIDs.contains(municipalityID) {
                    workingSet.remove(municipalityID)
                }
                print("Unsubscribed municipalityId: \(municipalityID)")
            } catch let error as SubscriptionError {
                errors.append(error)
            } catch {
                errors.append(.firebase(message: error.localizedDescription))
            }
        }

        if shouldCleanupLegacyTopics {
            for municipalityID in workingSet.sorted() {
                do {
                    try await unsubscribeFromLegacyTopic(municipalityID: municipalityID)
                } catch let error as SubscriptionError {
                    errors.append(error)
                } catch {
                    errors.append(.firebase(message: error.localizedDescription))
                }
            }
        }

        subscribedMunicipalityIDs = workingSet
        persistSubscribedMunicipalityIDs()
        persistSubscribedLanguageCode(desiredLanguageCode)

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

    private func normalizeLanguageCode(_ rawValue: String) -> String {
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? defaultLanguageCode : normalized
    }

    private func storedSubscribedLanguageCode() -> String? {
        guard let rawValue = userDefaults.string(forKey: languageDefaultsKey) else {
            return nil
        }

        let normalized = normalizeLanguageCode(rawValue)
        return normalized.isEmpty ? nil : normalized
    }

    private func fetchMunicipalityID(for coordinate: CLLocationCoordinate2D) async throws -> String {
        let url: URL
        if let customURL = customGeoSphereURL {
            guard let parsedURL = URL(string: customURL) else {
                throw SubscriptionError.invalidResponse
            }
            url = parsedURL
        } else {
            var components = URLComponents(string: geosphereBaseURL)
            components?.queryItems = [
                URLQueryItem(name: "lat", value: String(format: "%.6f", coordinate.latitude)),
                URLQueryItem(name: "lon", value: String(format: "%.6f", coordinate.longitude))
            ]

            guard let parsedURL = components?.url else {
                throw SubscriptionError.invalidResponse
            }
            url = parsedURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = networkTimeout
        request.cachePolicy = .reloadIgnoringLocalCacheData

        NSLog("GeoSphere subscription request URL: %@", url.absoluteString)
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            NSLog("GeoSphere subscription transport error for %@: %@", url.absoluteString, error.localizedDescription)
            throw SubscriptionError.network(message: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyPreview = String(data: data.prefix(600), encoding: .utf8) ?? "<non-utf8 body>"
            NSLog("GeoSphere subscription HTTP failure: %ld for %@", httpResponse.statusCode, url.absoluteString)
            NSLog("GeoSphere subscription HTTP body preview: %@", bodyPreview)
            throw SubscriptionError.network(message: "GeoSphere HTTP \(httpResponse.statusCode)")
        }

        let decoded: GeoSphereLookupResponse
        do {
            decoded = try JSONDecoder().decode(GeoSphereLookupResponse.self, from: data)
        } catch {
            debugGeoSphereDecodingFailure(error: error, data: data, url: url, response: httpResponse)
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

    private func debugGeoSphereDecodingFailure(
        error: Error,
        data: Data,
        url: URL,
        response: HTTPURLResponse
    ) {
        NSLog("GeoSphere decode failed for URL: %@", url.absoluteString)
        NSLog("GeoSphere HTTP status: %ld", response.statusCode)
        NSLog("GeoSphere decoding error: %@", String(describing: error))

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            NSLog("GeoSphere top-level keys: %@", object.keys.sorted().joined(separator: ", "))

            if let firstKey = object.keys.sorted().first,
               let nestedObject = object[firstKey] as? [String: Any] {
                NSLog(
                    "GeoSphere nested keys for %@: %@",
                    firstKey,
                    nestedObject.keys.sorted().joined(separator: ", ")
                )
            }
        }

        let bodyPreview = String(data: data.prefix(1200), encoding: .utf8) ?? "<non-utf8 body>"
        NSLog("GeoSphere body preview: %@", bodyPreview)
    }

    private func subscribe(toMunicipalityID municipalityID: String, languageCode: String) async throws {
        let topic = topicName(for: municipalityID, languageCode: languageCode)

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

    private func unsubscribe(fromMunicipalityID municipalityID: String, languageCode: String) async throws {
        let topic = topicName(for: municipalityID, languageCode: languageCode)

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

    private func unsubscribeFromLegacyTopic(municipalityID: String) async throws {
        let topic = legacyTopicName(for: municipalityID)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                if let error {
                    continuation.resume(throwing: SubscriptionError.firebase(
                        message: "FCM legacy unsubscribe failed for \(topic): \(error.localizedDescription)"
                    ))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func topicName(for municipalityID: String, languageCode: String) -> String {
        "warngebiet_\(municipalityID)_\(normalizeLanguageCode(languageCode))"
    }

    private func legacyTopicName(for municipalityID: String) -> String {
        "warngebiet_\(municipalityID)"
    }

    private func persistSubscribedMunicipalityIDs() {
        userDefaults.set(subscribedMunicipalityIDs.sorted(), forKey: userDefaultsKey)
    }

    private func persistSubscribedLanguageCode(_ languageCode: String) {
        userDefaults.set(normalizeLanguageCode(languageCode), forKey: languageDefaultsKey)
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
