import Foundation
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var fallbackContent: UNNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        let fallback = PushNotificationContent.fallback(for: request.content)
        self.contentHandler = contentHandler
        self.fallbackContent = fallback

        guard PushNotificationContent.isVersion2(request.content.userInfo),
              let renderer = try? PushCopyRenderer(bundle: .main) else {
            deliver(fallback)
            return
        }

        let rendered = PushNotificationContent.rendered(
            from: request.content,
            renderer: renderer,
            languageCode: PushLanguage.currentLanguageCode(defaults: .hitzeShared),
            now: Date()
        )
        deliver(rendered ?? fallback)
    }

    override func serviceExtensionTimeWillExpire() {
        if let fallbackContent {
            deliver(fallbackContent)
        }
    }

    private func deliver(_ content: UNNotificationContent) {
        guard let contentHandler else { return }
        self.contentHandler = nil
        contentHandler(content)
    }
}
