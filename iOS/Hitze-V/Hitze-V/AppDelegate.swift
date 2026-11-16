import FirebaseMessaging
import os
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        PushSharedSettings.migrateLanguageIfNeeded()
        // Must be set before launch finishes so a tap that cold-starts the app is delivered.
        UNUserNotificationCenter.current().delegate = self

        guard !FirebaseRegistrationManager.isRunningUnitTests else {
            return true
        }

        FirebaseRegistrationManager.shared.configureIfNeeded()
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        FirebaseRegistrationManager.shared.registerForRemoteNotifications()

        Task {
            await SubscriptionManager.shared.resyncStoredState()
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        FirebaseRegistrationManager.shared.notifyAPNsRegistrationSucceeded()
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        FirebaseRegistrationManager.shared.notifyAPNsRegistrationFailed(error)
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        #if DEBUG
        pushLogger.debug("FCM token: \(fcmToken, privacy: .private)")
        #endif
        Task { @MainActor in
            await SubscriptionManager.shared.resyncStoredState()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
           let gkz = PushNotificationContent.gkz(in: response.notification.request.content.userInfo) {
            PushRouter.shared.pendingGKZ = gkz
        }
        completionHandler()
    }
}
