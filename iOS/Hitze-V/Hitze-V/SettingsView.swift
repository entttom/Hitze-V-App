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
    
    @AppStorage("dashboard.language") private var languageRawValue = AppLanguage.system.rawValue
    @AppStorage("app.theme") private var themeRawValue = AppTheme.system.rawValue
    
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
                    Picker(copy.languageSection, selection: $languageRawValue) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(copy.languageOption(language))
                                .tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text(copy.aboutSection)) {
                    VStack(alignment: .center, spacing: 10) {
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
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
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
    }
}
