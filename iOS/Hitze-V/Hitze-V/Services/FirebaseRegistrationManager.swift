import FirebaseCore
import FirebaseMessaging
import Foundation
import os
import UIKit

@MainActor
final class FirebaseRegistrationManager {
    static let shared = FirebaseRegistrationManager()

    /// True while the app is only the host of the unit tests; Firebase stays unconfigured then so
    /// tests never talk to the real Firebase project.
    nonisolated static let isRunningUnitTests: Bool = {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestBundlePath"] != nil
            || environment["XCTestSessionIdentifier"] != nil
    }()

    private let apnsWaitTimeout: Duration = .seconds(5)
    private var apnsRegistrationFailed = false
    private var apnsWaiters: [UUID: CheckedContinuation<Void, Never>] = [:]

    private init() {}

    var isConfigured: Bool {
        FirebaseApp.app() != nil
    }

    func configureIfNeeded() {
        guard !Self.isRunningUnitTests, FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }

    /// Doesn't prompt; an APNs token is issued regardless of notification permission, and FCM
    /// topic (un)subscription only needs that token.
    func registerForRemoteNotifications() {
        guard !Self.isRunningUnitTests else { return }
        UIApplication.shared.registerForRemoteNotifications()
    }

    func notifyAPNsRegistrationSucceeded() {
        apnsRegistrationFailed = false
        resumeAPNsWaiters()
    }

    func notifyAPNsRegistrationFailed(_ error: any Error) {
        apnsRegistrationFailed = true
        pushLogger.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
        resumeAPNsWaiters()
    }

    /// The current FCM token. Waits at most a few seconds for the APNs token on a cold start;
    /// if it arrives later, the token-refresh callback triggers another sync.
    func currentFCMToken() async throws -> String {
        guard isConfigured else { throw FirebaseRegistrationError.notConfigured }

        if let token = Messaging.messaging().fcmToken, !token.isEmpty {
            return token
        }

        if Messaging.messaging().apnsToken == nil, !apnsRegistrationFailed {
            await waitForAPNsToken()
        }
        guard Messaging.messaging().apnsToken != nil else {
            throw FirebaseRegistrationError.apnsTokenUnavailable
        }

        let token = try await Messaging.messaging().token()
        guard !token.isEmpty else { throw FirebaseRegistrationError.tokenMissing }
        return token
    }

    func deleteFCMToken() async throws {
        guard isConfigured else { throw FirebaseRegistrationError.notConfigured }
        try await Messaging.messaging().deleteToken()
    }

    private func waitForAPNsToken() async {
        let id = UUID()
        let timeout = Task { [apnsWaitTimeout] in
            try? await Task.sleep(for: apnsWaitTimeout)
            self.resumeAPNsWaiter(id)
        }
        await withCheckedContinuation { continuation in
            apnsWaiters[id] = continuation
        }
        timeout.cancel()
    }

    private func resumeAPNsWaiter(_ id: UUID) {
        apnsWaiters.removeValue(forKey: id)?.resume()
    }

    private func resumeAPNsWaiters() {
        let waiters = apnsWaiters
        apnsWaiters.removeAll()
        for continuation in waiters.values {
            continuation.resume()
        }
    }
}

final class FirebaseTopicClient: PushTopicClient {
    func currentToken() async throws -> String {
        try await FirebaseRegistrationManager.shared.currentFCMToken()
    }

    func subscribe(toTopic topic: String) async throws {
        guard FirebaseRegistrationManager.shared.isConfigured else {
            throw FirebaseRegistrationError.notConfigured
        }
        try await Messaging.messaging().subscribe(toTopic: topic)
    }

    func unsubscribe(fromTopic topic: String) async throws {
        guard FirebaseRegistrationManager.shared.isConfigured else {
            throw FirebaseRegistrationError.notConfigured
        }
        try await Messaging.messaging().unsubscribe(fromTopic: topic)
    }

    func deleteToken() async throws {
        try await FirebaseRegistrationManager.shared.deleteFCMToken()
    }
}

enum FirebaseRegistrationError: LocalizedError {
    case notConfigured
    case apnsTokenUnavailable
    case tokenMissing

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase ist nicht konfiguriert."
        case .apnsTokenUnavailable:
            return "APNs-Token ist noch nicht verfügbar."
        case .tokenMissing:
            return "FCM-Token wurde nicht geliefert."
        }
    }
}
