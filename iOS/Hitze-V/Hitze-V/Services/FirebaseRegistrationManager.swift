import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@MainActor
final class FirebaseRegistrationManager {
    static let shared = FirebaseRegistrationManager()
    private let apnsWaitTimeoutNanoseconds: UInt64 = 12_000_000_000
    private let tokenWaitTimeoutNanoseconds: UInt64 = 12_000_000_000
    private let tokenRetryDelayNanoseconds: UInt64 = 300_000_000
    private var didReceiveAPNsToken = false
    private var apnsRegistrationFailureMessage: String?

    private init() {}

    func registerForPushNotificationsIfNeeded() async throws {
        ensureFirebaseConfigured()

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else {
                throw FirebaseRegistrationError.permissionDenied
            }
        case .denied:
            throw FirebaseRegistrationError.permissionDenied
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            throw FirebaseRegistrationError.permissionDenied
        }

        if Messaging.messaging().apnsToken != nil {
            didReceiveAPNsToken = true
            apnsRegistrationFailureMessage = nil
        } else {
            didReceiveAPNsToken = false
            apnsRegistrationFailureMessage = nil
        }

        UIApplication.shared.registerForRemoteNotifications()
        try await waitForAPNsToken()
        try await waitForFCMToken()
    }

    func notifyAPNsRegistrationSucceeded() {
        didReceiveAPNsToken = true
        apnsRegistrationFailureMessage = nil
    }

    func notifyAPNsRegistrationFailed(_ error: any Error) {
        apnsRegistrationFailureMessage = error.localizedDescription
    }

    func deregisterFromFirebase() async throws {
        print("Starting Firebase deregistration...")
        UIApplication.shared.unregisterForRemoteNotifications()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            Messaging.messaging().deleteToken { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    print("Firebase Messaging token deleted successfully.")
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func ensureFirebaseConfigured() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    private func waitForAPNsToken() async throws {
        let startTime = DispatchTime.now().uptimeNanoseconds

        while DispatchTime.now().uptimeNanoseconds - startTime < apnsWaitTimeoutNanoseconds {
            if let apnsRegistrationFailureMessage {
                throw FirebaseRegistrationError.apnsRegistrationFailed(message: apnsRegistrationFailureMessage)
            }

            if didReceiveAPNsToken || Messaging.messaging().apnsToken != nil {
                print("APNs token available.")
                return
            }

            try await Task.sleep(nanoseconds: tokenRetryDelayNanoseconds)
        }

        throw FirebaseRegistrationError.apnsTokenTimeout
    }

    private func waitForFCMToken() async throws {
        let startTime = DispatchTime.now().uptimeNanoseconds

        while DispatchTime.now().uptimeNanoseconds - startTime < tokenWaitTimeoutNanoseconds {
            if let existingToken = Messaging.messaging().fcmToken,
               !existingToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("FCM token available.")
                return
            }

            do {
                let token = try await fetchFCMToken()
                if !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("FCM token fetched successfully.")
                    return
                }
            } catch {
                if !isMissingAPNsTokenError(error) {
                    throw FirebaseRegistrationError.tokenFetchFailed(message: error.localizedDescription)
                }
            }

            try await Task.sleep(nanoseconds: tokenRetryDelayNanoseconds)
        }

        throw FirebaseRegistrationError.tokenTimeout
    }

    private func fetchFCMToken() async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, any Error>) in
            Messaging.messaging().token { token, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let token else {
                    continuation.resume(throwing: FirebaseRegistrationError.tokenMissing)
                    return
                }

                continuation.resume(returning: token)
            }
        }
    }

    private func isMissingAPNsTokenError(_ error: any Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "com.google.fcm" && nsError.code == 505
    }
}

enum FirebaseRegistrationError: LocalizedError {
    case permissionDenied
    case apnsTokenTimeout
    case apnsRegistrationFailed(message: String)
    case tokenMissing
    case tokenTimeout
    case tokenFetchFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Push-Berechtigung wurde nicht erteilt."
        case .apnsTokenTimeout:
            return "APNs Token konnte nicht rechtzeitig ermittelt werden."
        case .apnsRegistrationFailed(let message):
            return "APNs Registrierung fehlgeschlagen: \(message)"
        case .tokenMissing:
            return "FCM Token wurde nicht geliefert."
        case .tokenTimeout:
            return "FCM Token konnte nicht rechtzeitig ermittelt werden."
        case .tokenFetchFailed(let message):
            return "FCM Token konnte nicht abgerufen werden: \(message)"
        }
    }
}
