import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @AppStorage("dashboard.language") private var languageRawValue = AppLanguage.system.rawValue
    @State private var isShowingAddWorkplace = false

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    private var copy: Copybook {
        Copybook(language: selectedLanguage.resolvedLanguage)
    }

    private var sortedTopicIDs: [String] {
        Array(viewModel.subscriptionManager.subscribedMunicipalityIDs).sorted()
    }

    private var snapshotsInDisplayOrder: [WorksiteSnapshot] {
        viewModel.worksites.compactMap { viewModel.snapshots[$0.id] }
    }

    private var highestSeverity: HeatSeverity {
        snapshotsInDisplayOrder.max(by: { $0.severity.rawValue < $1.severity.rawValue })?.severity ?? .none
    }

    private var highestUV: Double? {
        snapshotsInDisplayOrder.compactMap(\.uvIndex).max()
    }

    private var averageApparentTemperature: Double? {
        let values = snapshotsInDisplayOrder.compactMap(\.apparentTemperature)
        guard !values.isEmpty else {
            return nil
        }

        return values.reduce(0, +) / Double(values.count)
    }

    private var activeWarningCount: Int {
        snapshotsInDisplayOrder.filter { $0.severity != .none }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        heroCard
                        glanceCard
                        workplacesCard
                        topicsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingAddWorkplace) {
                AddWorkplaceView(viewModel: viewModel, copy: copy)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(copy.shortTitle)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    languageMenu
                    
                    Button {
                        isShowingAddWorkplace = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel(copy.addWorkplaceTitle)

                    Button {
                        Task {
                            await viewModel.refreshAll()
                        }
                    } label: {
                        if viewModel.isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title3)
                        }
                    }
                    .disabled(viewModel.isRefreshing)
                    .accessibilityLabel(copy.refreshButton)
                }
            }
            .task {
                await viewModel.refreshIfNeeded()
            }
            .refreshable {
                await viewModel.refreshAll()
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(copy.dashboardTitle)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.white)

                    Text(copy.dashboardSubtitle)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                SeverityPill(
                    label: copy.severityName(highestSeverity),
                    icon: highestSeverity.symbol,
                    tint: highestSeverity.tint
                )
            }

            Text(copy.severityAction(highestSeverity))
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                HeroMetricBubble(
                    icon: "briefcase.fill",
                    label: copy.workplaceLabel,
                    value: "\(viewModel.worksites.count)",
                    tint: Color(red: 0.27, green: 0.75, blue: 0.68)
                )

                HeroMetricBubble(
                    icon: "exclamationmark.triangle.fill",
                    label: copy.warningsLabel,
                    value: "\(activeWarningCount)",
                    tint: Color(red: 0.99, green: 0.64, blue: 0.28)
                )

                HeroMetricBubble(
                    icon: "bell.badge.fill",
                    label: copy.topicsLabel,
                    value: "\(sortedTopicIDs.count)",
                    tint: Color(red: 0.35, green: 0.57, blue: 0.98)
                )
            }

            if let statusMessage = viewModel.statusMessage,
               !statusMessage.isEmpty {
                Label(statusMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.44, blue: 0.26),
                    Color(red: 0.97, green: 0.68, blue: 0.23),
                    Color(red: 0.24, green: 0.68, blue: 0.89)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 120, height: 120)
                .offset(x: 35, y: -35)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
    }

    private var glanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(copy.glanceTitle)
                .font(.system(.headline, design: .rounded).weight(.bold))

            HStack(spacing: 10) {
                GlanceTile(
                    title: copy.currentRiskTitle,
                    value: copy.severityHeadline(highestSeverity),
                    icon: highestSeverity.symbol,
                    tint: highestSeverity.tint
                )

                GlanceTile(
                    title: copy.uvPeakTitle,
                    value: uvText(highestUV),
                    icon: "sun.max.fill",
                    tint: Color(red: 0.99, green: 0.66, blue: 0.25)
                )

                GlanceTile(
                    title: copy.apparentTitle,
                    value: temperatureText(averageApparentTemperature),
                    icon: "thermometer.medium",
                    tint: Color(red: 0.94, green: 0.42, blue: 0.37)
                )
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private var workplacesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(copy.monitoredWorkplacesTitle)
                .font(.system(.headline, design: .rounded).weight(.bold))

            if viewModel.worksites.isEmpty {
                Label(copy.noWorkplaces, systemImage: "briefcase")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.worksites) { worksite in
                        WorksiteCard(
                            copy: copy,
                            worksite: worksite,
                            snapshot: viewModel.snapshots[worksite.id],
                            onDelete: {
                                Task {
                                    await viewModel.deleteWorksite(id: worksite.id)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private var topicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(copy.topicSectionTitle)
                .font(.system(.headline, design: .rounded).weight(.bold))

            if sortedTopicIDs.isEmpty {
                Text(copy.noTopics)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 8)], spacing: 8) {
                    ForEach(sortedTopicIDs, id: \.self) { municipalityID in
                        Text("warngebiet_\(municipalityID)")
                            .font(.system(.caption, design: .monospaced).weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.90, green: 0.95, blue: 1.00), in: Capsule())
                    }
                }
            }

            if let subscriptionError = viewModel.subscriptionManager.lastError?.errorDescription {
                Label(subscriptionError, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color.red)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private var languageMenu: some View {
        Menu {
            Picker(copy.languageMenuTitle, selection: $languageRawValue) {
                ForEach(AppLanguage.allCases) { language in
                    Text(copy.languageOption(language))
                        .tag(language.rawValue)
                }
            }
        } label: {
            Label(copy.languageMenuShort(selectedLanguage), systemImage: "globe")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
        }
    }

    private func textField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }

    private func uvText(_ value: Double?) -> String {
        guard let value else {
            return copy.notAvailableShort
        }

        return String(format: "UV %.1f", value)
    }

    private func temperatureText(_ value: Double?) -> String {
        guard let value else {
            return copy.notAvailableShort
        }

        return String(format: "%.1f C", value)
    }
}

private struct WorksiteCard: View {
    let copy: Copybook
    let worksite: Worksite
    let snapshot: WorksiteSnapshot?
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill((snapshot?.severity ?? .none).tint.opacity(0.22))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: (snapshot?.severity ?? .none).symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle((snapshot?.severity ?? .none).tint)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(worksite.name)
                    .font(.system(.headline, design: .rounded).weight(.bold))

                if let address = worksite.address, !address.isEmpty {
                    Text(address)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if let snapshot {
                    Text("\(snapshot.municipalityName) (\(snapshot.municipalityID))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        miniFact(icon: "sun.max", text: uvText(snapshot.uvIndex))
                        miniFact(icon: "thermometer", text: tempText(snapshot.apparentTemperature))
                        miniFact(icon: "clock", text: snapshot.updatedAt.formatted(date: .omitted, time: .shortened))
                    }
                } else {
                    Label(copy.loading, systemImage: "hourglass")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                SeverityPill(
                    label: copy.severityName(snapshot?.severity ?? .none),
                    icon: (snapshot?.severity ?? .none).symbol,
                    tint: (snapshot?.severity ?? .none).tint
                )

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .bold))
                        .padding(8)
                }
                .buttonStyle(.plain)
                .background(Color.red.opacity(0.12), in: Circle())
                .accessibilityLabel(copy.deleteWorkplace)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func miniFact(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.secondary)
    }

    private func uvText(_ value: Double?) -> String {
        guard let value else {
            return "UV n/a"
        }

        return String(format: "UV %.1f", value)
    }

    private func tempText(_ value: Double?) -> String {
        guard let value else {
            return copy.notAvailableShort
        }

        return String(format: "%.1f C", value)
    }
}

struct AddressResultRow: View {
    let copy: Copybook
    let result: AddressSearchResult
    let onUse: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(Color(red: 0.11, green: 0.62, blue: 0.82))

            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text(result.subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onUse) {
                Text(copy.useAddressButton)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.18, green: 0.68, blue: 0.85), in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SeverityPill: View {
    let label: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
            Text(label)
                .font(.system(.caption, design: .rounded).weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.16), in: Capsule())
        .foregroundStyle(tint)
    }
}

private struct GlanceTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HeroMetricBubble: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            Text(value)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AtmosphereBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.96, blue: 0.90),
                Color(red: 0.90, green: 0.95, blue: 0.98),
                Color(red: 0.96, green: 0.92, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
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
        }
        .ignoresSafeArea()
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case de
    case en

    var id: String { rawValue }

    var resolvedLanguage: ResolvedLanguage {
        switch self {
        case .de:
            return .de
        case .en:
            return .en
        case .system:
            let languageCode = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
            return languageCode.hasPrefix("de") ? .de : .en
        }
    }
}

enum ResolvedLanguage {
    case de
    case en
}

struct Copybook {
    let language: ResolvedLanguage

    private var isGerman: Bool {
        language == .de
    }

    func t(_ german: String, _ english: String) -> String {
        isGerman ? german : english
    }

    var shortTitle: String { t("Hitze-V", "Heat-V") }
    var dashboardTitle: String { t("Sicher durch Hitze", "Heat Safety at a Glance") }
    var dashboardSubtitle: String { t("Ampelstatus, UV und Arbeitsplaetze live auf einen Blick.", "Traffic-light status, UV and workplaces live in one view.") }
    var glanceTitle: String { t("Schnelluebersicht", "Quick Glance") }
    var currentRiskTitle: String { t("Aktuelles Risiko", "Current Risk") }
    var uvPeakTitle: String { t("Hoechster UV", "Peak UV") }
    var apparentTitle: String { t("Gefuehlte Temp", "Feels Like") }
    var workplaceLabel: String { t("Arbeitsplaetze", "Workplaces") }
    var warningsLabel: String { t("Warnungen", "Warnings") }
    var topicsLabel: String { t("Topics", "Topics") }
    var addWorkplaceTitle: String { t("Neuen Arbeitsplatz anlegen", "Create New Workplace") }
    var namePlaceholder: String { t("Bezeichnung (optional)", "Label (optional)") }
    var addressPlaceholder: String { t("Adresse oder Ort suchen", "Search address or place") }
    var searchAddressButton: String { t("Adresse suchen", "Search Address") }
    var searchingAddress: String { t("Adresse wird gesucht...", "Searching address...") }
    var searchResultsTitle: String { t("Treffer auswaehlen", "Choose a result") }
    var useAddressButton: String { t("Als Arbeitsplatz", "Use") }
    var monitoredWorkplacesTitle: String { t("Ueberwachte Arbeitsplaetze", "Monitored Workplaces") }
    var noWorkplaces: String { t("Noch keine Arbeitsplaetze vorhanden.", "No workplaces yet.") }
    var loading: String { t("Lade Live-Daten", "Loading live data") }
    var deleteWorkplace: String { t("Arbeitsplatz loeschen", "Delete workplace") }
    var topicSectionTitle: String { t("Aktive Topic-Abos", "Active Topic Subscriptions") }
    var noTopics: String { t("Keine aktiven Topic-Abos", "No active topic subscriptions") }
    var refreshButton: String { t("Daten aktualisieren", "Refresh data") }
    var languageMenuTitle: String { t("Sprache", "Language") }
    var notAvailableShort: String { t("n/v", "n/a") }
    var cancelButton: String { t("Abbrechen", "Cancel") }

    func languageMenuShort(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return t("Auto", "Auto")
        case .de:
            return "DE"
        case .en:
            return "EN"
        }
    }

    func languageOption(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return t("Systemsprache", "System language")
        case .de:
            return t("Deutsch", "German")
        case .en:
            return t("Englisch", "English")
        }
    }

    func severityName(_ severity: HeatSeverity) -> String {
        switch severity {
        case .none:
            return t("Gruen", "Green")
        case .yellow:
            return t("Gelb", "Yellow")
        case .orange:
            return "Orange"
        case .red:
            return t("Rot", "Red")
        }
    }

    func severityHeadline(_ severity: HeatSeverity) -> String {
        switch severity {
        case .none:
            return t("Stabil", "Stable")
        case .yellow:
            return t("Erhoeht", "Elevated")
        case .orange:
            return t("Hoch", "High")
        case .red:
            return t("Kritisch", "Critical")
        }
    }

    func severityAction(_ severity: HeatSeverity) -> String {
        switch severity {
        case .none:
            return t("Alles ruhig. Standardmassnahmen reichen aus.", "All clear. Standard precautions are sufficient.")
        case .yellow:
            return t("Pausen und Schatten erhoehen.", "Increase breaks and shade usage.")
        case .orange:
            return t("Arbeitszeiten anpassen und Teams aktiv schuetzen.", "Adjust schedules and actively protect teams.")
        case .red:
            return t("Sofort Hitze-V Schutzmassnahmen umsetzen.", "Apply Heat-V protective measures immediately.")
        }
    }
}

private extension HeatSeverity {
    var tint: Color {
        switch self {
        case .none:
            return Color(red: 0.15, green: 0.72, blue: 0.45)
        case .yellow:
            return Color(red: 0.89, green: 0.72, blue: 0.11)
        case .orange:
            return Color(red: 0.95, green: 0.52, blue: 0.18)
        case .red:
            return Color(red: 0.85, green: 0.24, blue: 0.20)
        }
    }

    var symbol: String {
        switch self {
        case .none:
            return "checkmark.seal.fill"
        case .yellow:
            return "exclamationmark.circle.fill"
        case .orange:
            return "flame.fill"
        case .red:
            return "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    ContentView()
}
