import SwiftUI
import Combine

/// Set once the root view has its initial state (stored worksites are loaded synchronously),
/// so the launch overlay can go away without waiting for the network.
@MainActor
final class LaunchReadiness: ObservableObject {
    static let shared = LaunchReadiness()
    @Published private(set) var isReady = false

    func markReady() {
        isReady = true
    }
}

struct LaunchView: View {
    @Binding var isPresented: Bool

    @ObservedObject private var readiness = LaunchReadiness.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppSettingsKey.language, store: .hitzeShared) private var languageRawValue = AppLanguage.system.rawValue
    @State private var circleScale: CGFloat = 0.9
    @State private var hasMinimumDisplayElapsed = false

    private static let minimumDisplay: Duration = .milliseconds(350)
    private static let maximumDisplay: Duration = .seconds(1)

    private var copy: Copybook {
        Copybook(language: (AppLanguage(rawValue: languageRawValue) ?? .system).resolvedLanguage)
    }

    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(Color(red: 0.99, green: 0.65, blue: 0.27).opacity(0.18))
                    .frame(width: 220, height: 220)
                    .offset(x: 160, y: -250)
                Circle()
                    .fill(Color(red: 0.21, green: 0.71, blue: 0.88).opacity(0.14))
                    .frame(width: 260, height: 260)
                    .offset(x: -170, y: 260)
            }
            .scaleEffect(circleScale)
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                    .padding(.bottom, 16)
                    .accessibilityHidden(true)

                Text(copy.shortTitle)
                    .font(.largeTitle.weight(.black))
                    .fontDesign(.rounded)
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15))

                Text(copy.dashboardTitle)
                    .font(.headline.weight(.medium))
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.8)) {
                    circleScale = 1.1
                }
            }
            try? await Task.sleep(for: Self.minimumDisplay)
            hasMinimumDisplayElapsed = true
            dismissIfReady()
            try? await Task.sleep(for: Self.maximumDisplay - Self.minimumDisplay)
            dismiss()
        }
        .onChange(of: readiness.isReady) { _, _ in
            dismissIfReady()
        }
    }

    private func dismissIfReady() {
        if readiness.isReady && hasMinimumDisplayElapsed {
            dismiss()
        }
    }

    private func dismiss() {
        guard isPresented else { return }
        if reduceMotion {
            isPresented = false
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        }
    }
}

#Preview {
    LaunchView(isPresented: .constant(true))
}
