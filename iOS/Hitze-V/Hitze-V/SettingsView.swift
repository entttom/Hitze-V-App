import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let copy: Copybook
    @ObservedObject private var viewModel: DashboardViewModel
    @ObservedObject private var mockModeController = MockModeController.shared

    @AppStorage(AppSettingsKey.language, store: .hitzeShared) private var languageRawValue = AppLanguage.system.rawValue
    @AppStorage("app.theme") private var themeRawValue = AppTheme.system.rawValue
    @State private var isPressingAboutCard = false
    @State private var isShowingMockModeAlert = false
    @State private var isShowingPermissionExplainer = false

    init(copy: Copybook, viewModel: DashboardViewModel) {
        self.copy = copy
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .system
    }

    private var isPermissionDenied: Bool {
        viewModel.pushPermission == .denied
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(copy.appearanceSection) {
                    Picker(copy.appearanceSection, selection: $themeRawValue) {
                        Text(copy.themeSystem).tag(AppTheme.system.rawValue)
                        Text(copy.themeLight).tag(AppTheme.light.rawValue)
                        Text(copy.themeDark).tag(AppTheme.dark.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section(copy.languageSection) {
                    NavigationLink {
                        LanguageSelectionView(copy: copy, languageRawValue: $languageRawValue)
                    } label: {
                        Text(copy.languageOption(selectedLanguage))
                    }
                }

                pushSection
                pushWorksitesSection

                Section(copy.aboutSection) {
                    aboutCard
                }
            }
            .navigationTitle(copy.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                    .accessibilityLabel(copy.settingsCloseButton)
                }
            }
            .task {
                await viewModel.refreshPermissionStatus()
            }
            .sheet(isPresented: $isShowingPermissionExplainer) {
                OnboardingView(copy: copy, mode: .permissionOnly) {
                    await viewModel.requestPermissionFromExplainer()
                    isShowingPermissionExplainer = false
                }
                .interactiveDismissDisabled()
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
        .alert(copy.mockModeActivatedTitle, isPresented: $isShowingMockModeAlert) {
            Button(copy.settingsCloseButton, role: .cancel) {}
        } message: {
            Text(copy.mockModeActivatedMessage)
        }
    }

    private var pushSection: some View {
        Section {
            Toggle(
                copy.pushNotificationsEnabledLabel,
                isOn: Binding(
                    get: { viewModel.isPushNotificationsEnabled && !isPermissionDenied },
                    set: { newValue in
                        Task {
                            await viewModel.setPushNotificationsEnabled(newValue)
                            if newValue, viewModel.pushPermission == .notDetermined {
                                isShowingPermissionExplainer = true
                            }
                        }
                    }
                )
            )
            .disabled(isPermissionDenied)

            if isPermissionDenied {
                VStack(alignment: .leading, spacing: 6) {
                    Label(copy.pushDeniedTitle, systemImage: "bell.slash.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(copy.pushDeniedMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: url) {
                        Label(copy.openSettingsButton, systemImage: "gear")
                    }
                }
            }

            if viewModel.hasPushSyncError, !isPermissionDenied, viewModel.isPushNotificationsEnabled {
                Label(copy.pushSyncFailedMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                Button(copy.retryButton, systemImage: "arrow.clockwise") {
                    Task { await viewModel.syncPush() }
                }
            }
        } header: {
            Text(copy.pushNotificationsSection)
        } footer: {
            Text(copy.pushNotificationsDescription)
        }
    }

    private var pushWorksitesSection: some View {
        Section(copy.pushWorksitesSectionTitle) {
            if viewModel.worksites.isEmpty {
                Text(copy.pushNoWorksitesMessage)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.worksites) { worksite in
                    Toggle(
                        isOn: Binding(
                            get: { viewModel.isPushEnabled(forWorksiteID: worksite.id) && !isPermissionDenied },
                            set: { newValue in
                                Task { await viewModel.setPushEnabled(newValue, forWorksiteID: worksite.id) }
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(worksite.name)
                            Text(
                                worksite.address?
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .nonEmpty ?? copy.pushWorksiteFallbackSubtitle
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.isPushNotificationsEnabled || isPermissionDenied)
                }
            }
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .center, spacing: 10) {
            if mockModeController.isEnabled {
                Text(copy.mockModeActiveBadge)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.45, green: 0.18, blue: 0.62), in: Capsule())
            }

            Text(copy.dataSourceLine)
                .font(.subheadline.weight(.semibold))

            Text(copy.copyrightLine(year: Calendar.current.component(.year, from: Date())))
                .font(.footnote.weight(.medium))

            if let legalURL = URL(string: copy.legalLinkURL) {
                Link(copy.legalLinkLabel, destination: legalURL)
                    .font(.footnote.weight(.semibold))
            }

            Text(copy.machineTranslationDisclaimer)
                .font(.caption)
                .foregroundStyle(.secondary)

            if mockModeController.isEnabled {
                Text(copy.mockModeSessionHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 6)
        .scaleEffect(isPressingAboutCard ? 0.985 : 1)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 10, maximumDistance: 36, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressingAboutCard = isPressing
            }
        }) {
            isShowingMockModeAlert = true
            Task { await viewModel.activateMockMode() }
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

private struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let copy: Copybook
    @Binding var languageRawValue: String

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    var body: some View {
        List {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    languageRawValue = language.rawValue
                    dismiss()
                } label: {
                    HStack {
                        Text(copy.languageOption(language))
                            .foregroundStyle(.primary)
                        Spacer()
                        if language == selectedLanguage {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .navigationTitle(copy.languageSection)
        .navigationBarTitleDisplayMode(.inline)
    }
}
