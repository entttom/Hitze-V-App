import Combine
import Foundation

@MainActor
final class PushRouter: ObservableObject {
    static let shared = PushRouter()

    /// Set when the user taps a notification; the dashboard consumes it and resets it to nil.
    @Published var pendingGKZ: String?

    init() {}
}
