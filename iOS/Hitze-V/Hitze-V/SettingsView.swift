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
    let onActivateMockMode: () -> Void
    
    @AppStorage("dashboard.language") private var languageRawValue = AppLanguage.system.rawValue
    @AppStorage("app.theme") private var themeRawValue = AppTheme.system.rawValue
    @AppStorage("network.customGeoSphereUrl") private var customGeoSphereURL = ""
    @ObservedObject private var mockModeController: MockModeController
    @State private var isPressingAboutCard = false
    @State private var isShowingMockModeAlert = false

    init(
        copy: Copybook,
        viewModel: DashboardViewModel,
        mockModeController: MockModeController = .shared,
        onActivateMockMode: @escaping () -> Void = {}
    ) {
        self.copy = copy
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.onActivateMockMode = onActivateMockMode
        _mockModeController = ObservedObject(wrappedValue: mockModeController)
    }
    
    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .system
    }
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(copy.appearanceSection)) {
                    Picker(copy.appearanceSection, selection: $themeRawValue) {
                        Text(copy.themeSystem).tag(AppTheme.system.rawValue)
                        Text(copy.themeLight).tag(AppTheme.light.rawValue)
                        Text(copy.themeDark).tag(AppTheme.dark.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }
                
                Section(header: Text(copy.languageSection)) {
                    NavigationLink {
                        LanguageSelectionView(copy: copy, languageRawValue: $languageRawValue)
                    } label: {
                        HStack {
                            Text(copy.languageOption(selectedLanguage))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }

                Section(
                    header: Text(copy.pushNotificationsSection),
                    footer: Text(copy.pushNotificationsDescription)
                ) {
                    Toggle(
                        copy.pushNotificationsEnabledLabel,
                        isOn: Binding(
                            get: { viewModel.isPushNotificationsEnabled },
                            set: { newValue in
                                Task {
                                    await viewModel.setPushNotificationsEnabled(newValue)
                                }
                            }
                        )
                    )
                }

                Section(header: Text(copy.pushWorksitesSectionTitle)) {
                    if viewModel.worksites.isEmpty {
                        Text(copy.pushNoWorksitesMessage)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.worksites) { worksite in
                            Toggle(
                                isOn: Binding(
                                    get: { viewModel.isPushEnabled(forWorksiteID: worksite.id) },
                                    set: { newValue in
                                        Task {
                                            await viewModel.setPushEnabled(newValue, forWorksiteID: worksite.id)
                                        }
                                    }
                                )
                                ) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(worksite.name)
                                        .foregroundStyle(.primary)
                                    Text(
                                        worksite.address?
                                            .trimmingCharacters(in: .whitespacesAndNewlines)
                                            .nonEmpty ?? copy.pushWorksiteFallbackSubtitle
                                    )
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .disabled(!viewModel.isPushNotificationsEnabled)
                            .opacity(viewModel.isPushNotificationsEnabled ? 1 : 0.55)
                        }
                    }
                }

                if AppFeatureFlags.enableCustomGeoSphereURLSetting {
                    Section(header: Text(copy.developerSection), footer: Text(copy.customGeoSphereURLHint)) {
                        TextField(copy.customGeoSphereURLLabel, text: $customGeoSphereURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .textContentType(.URL)
                    }
                }
                
                Section(header: Text(copy.aboutSection)) {
                    aboutCard
                }
            }
            .navigationTitle(copy.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(copy.settingsCloseButton) {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                }
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
        .alert(copy.mockModeActivatedTitle, isPresented: $isShowingMockModeAlert) {
            Button(copy.settingsCloseButton, role: .cancel) {}
        } message: {
            Text(copy.mockModeActivatedMessage)
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .center, spacing: 10) {
            if mockModeController.isEnabled {
                Text(copy.mockModeActiveBadge)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.85, green: 0.24, blue: 0.20), in: Capsule())
            }

            Text(copy.dataSourceLine)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            
            Text(copy.copyrightLine(year: currentYear))
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            if let legalURL = URL(string: copy.legalLinkURL) {
                Link(copy.legalLinkLabel, destination: legalURL)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }

            Text(copy.machineTranslationDisclaimer)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if mockModeController.isEnabled {
                Text(copy.mockModeSessionHint)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isPressingAboutCard ? Color.red.opacity(0.65) : Color.black.opacity(0.06),
                    lineWidth: isPressingAboutCard ? 2 : 1
                )
        )
        .scaleEffect(isPressingAboutCard ? 0.985 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onLongPressGesture(minimumDuration: 10, maximumDistance: 36, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressingAboutCard = isPressing
            }
        }) {
            mockModeController.activate()
            isShowingMockModeAlert = true
            onActivateMockMode()
        }
        .animation(.easeInOut(duration: 0.2), value: isPressingAboutCard)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(Color.clear)
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
