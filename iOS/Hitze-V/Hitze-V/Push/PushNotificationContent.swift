import Foundation
import UserNotifications

nonisolated enum PushNotificationContent {
    static func normalizedGKZ(_ raw: String) -> String {
        raw.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    }

    static func gkz(in userInfo: [AnyHashable: Any]) -> String? {
        guard let raw = userInfo["gkz"] as? String else { return nil }
        let gkz = normalizedGKZ(raw)
        return gkz.isEmpty ? nil : gkz
    }

    static func isVersion2(_ userInfo: [AnyHashable: Any]) -> Bool {
        (userInfo["v"] as? String) == "2"
    }

    /// The content as delivered (German fallback alert from the backend), grouped per GKZ.
    static func fallback(for content: UNNotificationContent) -> UNNotificationContent {
        let fallback = (content.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()
        if let gkz = gkz(in: content.userInfo) {
            fallback.threadIdentifier = "hitze-\(gkz)"
        }
        return fallback
    }

    /// Title/body rendered in the user's language, or nil when the push isn't a renderable v2
    /// message; the caller then shows `fallback(for:)`.
    static func rendered(
        from content: UNNotificationContent,
        renderer: PushCopyRenderer,
        languageCode: String?,
        now: Date
    ) -> UNNotificationContent? {
        guard isVersion2(content.userInfo),
              let rendered = try? renderer.render(userInfo: content.userInfo, languageCode: languageCode, now: now),
              let result = fallback(for: content).mutableCopy() as? UNMutableNotificationContent else {
            return nil
        }
        result.title = rendered.title
        result.body = rendered.body
        return result
    }
}
