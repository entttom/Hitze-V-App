import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@MainActor
final class FirebaseRegistrationManager {
    static let shared = FirebaseRegistrationManager()

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

        UIApplication.shared.registerForRemoteNotifications()
    }

    func deregisterFromFirebase() async throws {
        UIApplication.shared.unregisterForRemoteNotifications()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            Messaging.messaging().deleteToken { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
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
}

enum FirebaseRegistrationError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Push-Berechtigung wurde nicht erteilt."
        }
    }
}
