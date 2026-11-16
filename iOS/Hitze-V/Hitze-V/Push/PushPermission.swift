import UIKit
import UserNotifications

enum PushPermissionStatus: Equatable {
    case notDetermined
    case denied
    case authorized
}

@MainActor
enum PushPermission {
    static func currentStatus() async -> PushPermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return status(from: settings.authorizationStatus)
    }

    /// Only called from the explainer's "Weiter" button. Triggers the system prompt immediately,
    /// returns as soon as the user answered; APNs/FCM registration continues in the background.
    static func requestFromExplainer() async -> PushPermissionStatus {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
        if !FirebaseRegistrationManager.isRunningUnitTests {
            UIApplication.shared.registerForRemoteNotifications()
        }
        return await currentStatus()
    }

    static func status(from authorizationStatus: UNAuthorizationStatus) -> PushPermissionStatus {
        switch authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }
}
