import SwiftUI

/// Permission explainer (App Review 5.1.1(iv)): the only control is a neutral "Weiter", which
/// immediately triggers the system prompt; there is no skip, later or close on this step.
struct OnboardingView: View {
    enum Mode {
        /// First launch: welcome text plus the push explainer.
        case welcome
        /// Restored or pre-configured setups that were never asked.
        case permissionOnly
    }

    let copy: Copybook
    let mode: Mode
    let onContinue: () async -> Void

    @State private var isRequesting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if mode == .welcome {
                    VStack(spacing: 16) {
                        Image(systemName: "sun.max.trianglebadge.exclamationmark.fill")
                            .font(.system(.largeTitle))
                            .imageScale(.large)
                            .symbolRenderingMode(.multicolor)
                            .accessibilityHidden(true)

                        Text(copy.onboardingWelcomeTitle)
                            .font(.largeTitle.weight(.black))
                            .fontDesign(.rounded)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text(copy.onboardingWelcomeText)
                            .font(.body.weight(.medium))
                            .multilineTextAlignment(.center)
                    }
                }

                VStack(spacing: 14) {
                    Image(systemName: "bell.badge.fill")
                        .font(.largeTitle)
                        .accessibilityHidden(true)

                    Text(copy.onboardingPushTitle)
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(copy.onboardingPushText)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            Button {
                Task {
                    isRequesting = true
                    await onContinue()
                    isRequesting = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isRequesting {
                        ProgressView()
                    }
                    Text(copy.continueButton)
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.glassProminent)
            .tint(Color(red: 0.06, green: 0.34, blue: 0.54))
            .disabled(isRequesting)
            .frame(maxWidth: 560)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background {
            DashboardPalette.heroGradient
                .ignoresSafeArea()
        }
    }
}

#Preview {
    OnboardingView(copy: Copybook(language: .de), mode: .welcome) {}
}
