import SwiftUI

struct OnboardingView: View {
    @AppStorage("dashboard.language") private var languageRawValue = AppLanguage.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isRequesting = false

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    private var copy: Copybook {
        Copybook(language: selectedLanguage.resolvedLanguage)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.44, blue: 0.26),
                    Color(red: 0.97, green: 0.68, blue: 0.23),
                    Color(red: 0.24, green: 0.68, blue: 0.89)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "sun.max.trianglebadge.exclamationmark.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.multicolor)
                
                VStack(spacing: 16) {
                    Text(copy.onboardingWelcomeTitle)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(copy.onboardingWelcomeText)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                    
                    Text(copy.onboardingPushTitle)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(copy.onboardingPushText)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(20)
                .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button {
                    requestNotifications()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.black)
                                .padding(.trailing, 8)
                        }
                        Text(copy.onboardingAllowButton)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white, in: Capsule())
                    .foregroundStyle(.black)
                }
                .disabled(isRequesting)
                .padding(.horizontal, 30)
                
                Button(copy.onboardingSkipButton) {
                    finishOnboarding()
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.bottom, 20)
            }
            .padding(.top, 40)
        }
    }
    
    private func requestNotifications() {
        isRequesting = true
        Task {
            do {
                try await FirebaseRegistrationManager.shared.registerForPushNotificationsIfNeeded()
            } catch {
                print("Push registration error or denied: \(error)")
            }
            await MainActor.run {
                isRequesting = false
                finishOnboarding()
            }
        }
    }
    
    private func finishOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingView()
}
