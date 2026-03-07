import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @AppStorage("dashboard.language") private var languageRawValue = AppLanguage.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingAddWorkplace = false
    @State private var isShowingSettings = false
    @State private var isShowingInfo = false

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    private var copy: Copybook {
        Copybook(language: selectedLanguage.resolvedLanguage)
    }


    private var snapshotsInDisplayOrder: [WorksiteSnapshot] {
        viewModel.worksites.compactMap { viewModel.snapshots[$0.id] }
    }

    private var highestSeverity: HazardSeverity {
        snapshotsInDisplayOrder.max(by: { $0.severity < $1.severity })?.severity ?? .none
    }

    private var highestUV: Double? {
        snapshotsInDisplayOrder.compactMap(\.uvIndex).max()
    }

    private var maxApparentTemperature: Double? {
        snapshotsInDisplayOrder.compactMap(\.apparentTemperature).max()
    }

    private var activeWarningCount: Int {
        snapshotsInDisplayOrder.filter { $0.severity != .none }.count
    }
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
        } else {
            NavigationStack {
                ZStack {
                    AtmosphereBackground()

                    ScrollView {
                        VStack(spacing: 16) {
                            heroCard
                            glanceCard
                            workplacesCard
                            legalFooter
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
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(copy: copy)
            }
            .sheet(isPresented: $isShowingInfo) {
                InfoView(copy: copy)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingInfo = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel(copy.infoButtonLabel)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel(copy.settingsTitle)
                    
                    Button {
                        isShowingAddWorkplace = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel(copy.addWorkplaceTitle)
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
    }

    private var heroCard: some View {
        VStack(alignment: .center, spacing: 14) {
            VStack(alignment: .center, spacing: 6) {
                Text(copy.dashboardTitle)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

            }
            .frame(maxWidth: .infinity)

            Text(copy.severityAction(highestSeverity))
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                HeroMetricBubble(
                    icon: "briefcase.fill",
                    label: copy.workplaceLabel,
                    value: "\(viewModel.worksites.count)",
                    tint: Color(red: 0.27, green: 0.75, blue: 0.68)
                )
                .frame(maxWidth: .infinity)

                HeroMetricBubble(
                    icon: "exclamationmark.triangle.fill",
                    label: copy.warningsLabel,
                    value: "\(activeWarningCount)",
                    tint: Color(red: 0.99, green: 0.64, blue: 0.28)
                )
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

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
                .fill(Color.white.opacity(0.05))
                .frame(width: 120, height: 120)
                .offset(x: 35, y: -35)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
    }

    private var glanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(copy.glanceTitle)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Text(copy.glanceSubtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

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
                    value: temperatureText(maxApparentTemperature),
                    icon: "thermometer.medium",
                    tint: Color(red: 0.94, green: 0.42, blue: 0.37)
                )
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
    
    private var legalFooter: some View {
        VStack(spacing: 6) {
            Text(copy.copyrightLine(year: currentYear))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let legalURL = URL(string: copy.legalLinkURL) {
                Link(copy.legalLinkLabel, destination: legalURL)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }


    private func textField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    @State private var isShowingDeleteConfirmation = false
    @State private var isLongPressingDelete = false
    private let cardCornerRadius: CGFloat = 18

    private var severity: HazardSeverity {
        snapshot?.severity ?? .none
    }

    private var isNeutralSeverity: Bool {
        severity == .none
    }

    private var titleColor: Color {
        isNeutralSeverity ? .primary : .white
    }

    private var detailColor: Color {
        isNeutralSeverity ? .secondary : .white.opacity(0.8)
    }

    private var cardBackgroundStyle: AnyShapeStyle {
        if isNeutralSeverity {
            return AnyShapeStyle(.regularMaterial)
        }
        return AnyShapeStyle(severity.tint.gradient.opacity(0.85))
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
    }

    private var isDeleteHighlightActive: Bool {
        isLongPressingDelete || isShowingDeleteConfirmation
    }

    var body: some View {
        cardContent
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackgroundStyle, in: cardShape)
            .overlay { pressedGradientOverlay }
            .overlay(cardBorder)
            .overlay(alignment: .bottomLeading) { longPressDeleteBadge }
            .scaleEffect(isDeleteHighlightActive ? 0.985 : 1)
            .shadow(
                color: isDeleteHighlightActive ? Color.red.opacity(0.24) : Color.black.opacity(0.08),
                radius: isDeleteHighlightActive ? 16 : 8,
                x: 0,
                y: isDeleteHighlightActive ? 8 : 4
            )
            .contentShape(cardShape)
            .onLongPressGesture(minimumDuration: 0.6, maximumDistance: 24, pressing: { isPressing in
                withAnimation(.easeInOut(duration: 0.18)) {
                    isLongPressingDelete = isPressing
                }
            }) {
                isShowingDeleteConfirmation = true
            }
            .alert(copy.deleteWorkplace, isPresented: $isShowingDeleteConfirmation) {
                Button(copy.deleteWorkplace, role: .destructive) {
                    onDelete()
                }
                Button(copy.cancelButton, role: .cancel) {}
            } message: {
                Text(copy.deleteWorkplaceMessage(worksite.name))
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isDeleteHighlightActive)
    }

    private var cardContent: some View {
        HStack(alignment: .top, spacing: 12) {
            if !isNeutralSeverity {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: severity.symbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                headerRow

                if let snapshot {
                    Text(snapshot.municipalityName)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(detailColor)

                    if !snapshot.forecasts.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(snapshot.forecasts) { forecast in
                                DailyForecastItemView(forecast: forecast, copy: copy)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                        .padding(.bottom, 2)

                        let warningLines = forecastWarningLines(snapshot.forecasts)
                        if !warningLines.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(warningLines.enumerated()), id: \.offset) { _, line in
                                    Label("\(line.dayLabel): \(line.timeText)", systemImage: "clock.fill")
                                        .font(.system(.caption2, design: .rounded))
                                        .foregroundStyle(detailColor)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                } else {
                    Label(copy.loading, systemImage: "hourglass")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(worksite.name)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(titleColor)

                if let address = worksite.address, !address.isEmpty {
                    Text(address)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(detailColor)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            if let snapshot {
                HStack(spacing: 8) {
                    miniFact(icon: "sun.max", text: uvText(snapshot.uvIndex))
                    miniFact(icon: "thermometer", text: tempText(snapshot.apparentTemperature))
                }
            }
        }
    }

    @ViewBuilder
    private var pressedGradientOverlay: some View {
        if isDeleteHighlightActive {
            cardShape
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.28), Color.red.opacity(0.06)],
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                )
                .transition(.opacity)
        }
    }

    private var cardBorder: some View {
        cardShape.stroke(
            isDeleteHighlightActive ? Color.red.opacity(0.85) : Color.black.opacity(0.06),
            lineWidth: isDeleteHighlightActive ? 2 : 1
        )
    }

    @ViewBuilder
    private var longPressDeleteBadge: some View {
        if isDeleteHighlightActive {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(copy.deleteWorkplace)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Text(worksite.name)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(Color.red.opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(10)
            .allowsHitTesting(false)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func miniFact(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(detailColor)
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

    private func forecastWarningLines(_ forecasts: [DailyForecast]) -> [(dayLabel: String, timeText: String)] {
        forecasts.compactMap { forecast in
            guard let timeText = warningTimeText(for: forecast) else {
                return nil
            }

            let dayLabel = Calendar.current.isDateInToday(forecast.date)
                ? copy.todayTitle
                : copy.weekdayShort(Calendar.current.component(.weekday, from: forecast.date))
            return (dayLabel: dayLabel, timeText: timeText)
        }
    }

    private func warningTimeText(for forecast: DailyForecast) -> String? {
        guard !forecast.warningTimeRanges.isEmpty else {
            return nil
        }

        let levelSuffix: String = {
            guard forecast.severity.level > 0 else { return "" }
            return " (\(copy.t("Stufe", "Level")) \(forecast.severity.level))"
        }()

        let calendar = Self.viennaCalendar
        let startOfDay = calendar.startOfDay(for: forecast.date)
        guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else {
            return nil
        }

        return forecast.warningTimeRanges
            .map { range in
                if range.start == startOfDay && range.end == endOfDay {
                    return "\(copy.warningAllDay)\(levelSuffix)"
                }

                return "\(Self.timeFormatter.string(from: range.start))-\(Self.timeFormatter.string(from: range.end))\(levelSuffix)"
            }
            .joined(separator: " · ")
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Vienna")
        return formatter
    }()

    private static let viennaCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Vienna") ?? .current
        return calendar
    }()
}

private struct DailyForecastItemView: View {
    let forecast: DailyForecast
    let copy: Copybook
    
    var isToday: Bool {
        Calendar.current.isDateInToday(forecast.date)
    }
    
    var dayText: String {
        if isToday {
            return copy.todayTitle
        }
        let weekday = Calendar.current.component(.weekday, from: forecast.date)
        return copy.weekdayShort(weekday)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(forecast.severity == HazardSeverity.none ? Color.secondary : Color.white)
            
            if forecast.severity != HazardSeverity.none {
                Image(systemName: forecast.severity.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            if let temp = forecast.apparentTemperatureMax {
                Text(String(format: "%.0f°", temp))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(forecast.severity == HazardSeverity.none ? Color.primary : Color.white)
            } else {
                Text("-")
                    .font(.system(size: 12))
                    .foregroundStyle(forecast.severity == HazardSeverity.none ? Color.primary : Color.white)
            }
        }
        .frame(minWidth: 44)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(forecast.severity == HazardSeverity.none ? Color(UIColor.secondarySystemGroupedBackground) : forecast.severity.tint)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HeroMetricBubble: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(value)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .center)
        .padding(10)
        .background(tint.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AtmosphereBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        
        LinearGradient(
            colors: isDark ? [
                Color(red: 0.08, green: 0.09, blue: 0.14),
                Color(red: 0.12, green: 0.15, blue: 0.22),
                Color(red: 0.10, green: 0.08, blue: 0.12)
            ] : [
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
    var dashboardSubtitle: String { t("Ampelstatus, UV und Arbeitsplätze live auf einen Blick.", "Traffic-light status, UV and workplaces live in one view.") }
    var glanceTitle: String { t("Schnellübersicht", "Quick Glance") }
    var glanceSubtitle: String { t("Maximalwerte aller Arbeitsplätze", "Maximum values across all workplaces") }
    var currentRiskTitle: String { t("Aktuelles Risiko", "Current Risk") }
    var uvPeakTitle: String { t("Höchster UV", "Peak UV") }
    var apparentTitle: String { t("Gefühlte Temp", "Feels Like") }
    var workplaceLabel: String { t("Arbeitsplätze", "Workplaces") }
    var warningsLabel: String { t("Warnungen", "Warnings") }
    var topicsLabel: String { t("Topics", "Topics") }
    var addWorkplaceTitle: String { t("Neuen Arbeitsplatz anlegen", "Create New Workplace") }
    var namePlaceholder: String { t("Bezeichnung (optional)", "Label (optional)") }
    var addressPlaceholder: String { t("Adresse oder Ort suchen", "Search address or place") }
    var searchAddressButton: String { t("Adresse suchen", "Search Address") }
    var searchingAddress: String { t("Adresse wird gesucht...", "Searching address...") }
    var searchResultsTitle: String { t("Treffer auswählen", "Choose a result") }
    var useAddressButton: String { t("Hinzufügen", "Add") }
    var monitoredWorkplacesTitle: String { t("Überwachte Arbeitsplätze", "Monitored Workplaces") }
    var noWorkplaces: String { t("Noch keine Arbeitsplätze vorhanden.", "No workplaces yet.") }
    var loading: String { t("Lade Live-Daten", "Loading live data") }
    var deleteWorkplace: String { t("Arbeitsplatz löschen", "Delete workplace") }
    func deleteWorkplaceMessage(_ name: String) -> String { t("Der Arbeitsplatz \"\(name)\" wird gelöscht.", "The workplace \"\(name)\" will be deleted.") }
    var topicSectionTitle: String { t("Aktive Topic-Abos", "Active Topic Subscriptions") }
    var noTopics: String { t("Keine aktiven Topic-Abos", "No active topic subscriptions") }
    var refreshButton: String { t("Daten aktualisieren", "Refresh data") }
    var languageMenuTitle: String { t("Sprache", "Language") }
    var notAvailableShort: String { t("n/v", "n/a") }
    var cancelButton: String { t("Abbrechen", "Cancel") }
    var settingsCloseButton: String { t("Schließen", "Close") }
    var settingsTitle: String { t("Einstellungen", "Settings") }
    var infoButtonLabel: String { t("Info öffnen", "Open info") }
    var infoScreenTitle: String { t("Info", "Info") }
    var infoScreenHeatMeasuresTitle: String { t("Hitze-Schutzmaßnahmen", "Heat Protection Measures") }
    var infoScreenHeatMeasuresSubtitle: String { t("Erklärung der Werte für die Stufen 2 bis 4", "Explanation of values for levels 2 to 4") }
    var infoScreenLevel2Title: String { t("2 (gefühlte Temperatur ≥ 30 °C)", "2 (apparent temperature ≥ 30 °C)") }
    var infoScreenLevel2Body: String { t("Bei dieser Belastung sollte die Arbeit so organisiert werden, dass zwischen 11:00 und 15:00 Uhr keine mittelschweren Tätigkeiten im Freien durchgeführt werden. Nutzen Sie kühlere Tageszeiten, häufige Trinkpausen und schattige Bereiche, um die körperliche Belastung wirksam zu reduzieren.", "At this level, work should be organized so that no medium-heavy outdoor tasks are carried out between 11:00 and 15:00. Use cooler times of day, frequent hydration breaks, and shaded areas to effectively reduce physical strain.") }
    var infoScreenLevel3Title: String { t("3 (gefühlte Temperatur ≥ 35 °C)", "3 (apparent temperature ≥ 35 °C)") }
    var infoScreenLevel3Body: String { t("Ab dieser Stufe sind Schutzmaßnahmen konsequent umzusetzen: Zwischen 11:00 und 15:00 Uhr maximal 2 Stunden direkte Sonneneinstrahlung, danach nur im Schatten oder in Innenbereichen arbeiten. Planen Sie zusätzliche Erholungspausen ein, rotieren Sie Teams und beobachten Sie Anzeichen von Hitzestress besonders aufmerksam.", "From this level onward, protective measures must be applied consistently: between 11:00 and 15:00, a maximum of 2 hours in direct sunlight, then continue work only in shade or indoors. Schedule extra recovery breaks, rotate teams, and closely monitor for signs of heat stress.") }
    var infoScreenLevel4Title: String { t("4 (gefühlte Temperatur ≥ 40 °C)", "4 (apparent temperature ≥ 40 °C)") }
    var infoScreenLevel4Body: String { t("Diese Stufe bedeutet eine kritische Hitzebelastung. Tätigkeiten im Freien sollen nur dann stattfinden, wenn sie unbedingt notwendig und organisatorisch nicht verschiebbar sind. Priorisieren Sie sofortige Schutzmaßnahmen, verlagern Sie Arbeiten nach innen und stellen Sie eine engmaschige Betreuung der Beschäftigten sicher.", "This level indicates critical heat stress. Outdoor activities should only take place if they are absolutely necessary and cannot be postponed organizationally. Prioritize immediate protective actions, move tasks indoors whenever possible, and ensure close supervision of workers.") }
    var appearanceSection: String { t("Erscheinungsbild", "Appearance") }
    var aboutSection: String { t("Info & Rechtliches", "Info & Legal") }
    var dataSourceLine: String { t("Datenquelle: GeoSphere Austria", "Data source: GeoSphere Austria") }
    var warningAllDay: String { t("Ganztägig", "All day") }
    var themeSystem: String { t("System", "System") }
    var themeLight: String { t("Hell", "Light") }
    var themeDark: String { t("Dunkel", "Dark") }
    var languageSection: String { t("Sprache", "Language") }
    var developerSection: String { t("Entwicklung", "Development") }
    var customGeoSphereURLLabel: String { t("GeoSphere Test-URL", "GeoSphere test URL") }
    var customGeoSphereURLHint: String {
        t(
            "Wenn gesetzt, wird diese URL statt des GeoSphere-Servers verwendet.",
            "If set, this URL is used instead of the GeoSphere server."
        )
    }
    var legalLinkURL: String { "https://www.arbeitsmediziner.wien" }
    var legalLinkLabel: String { "arbeitsmediziner.wien" }
    var onboardingWelcomeTitle: String { t("Willkommen bei Hitze-V", "Welcome to Hitze-V") }
    var onboardingWelcomeText: String { t("Wir helfen dir, die gesetzlichen Vorgaben zu Gefahren durch Hitze und natürliche UV-Strahlung bei Arbeiten im Freien einzuhalten. Behalte Temperaturen und UV-Index immer im Blick.", "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.") }
    var onboardingPushTitle: String { t("Bleib informiert", "Stay informed") }
    var onboardingPushText: String { t("Damit wir dich bei gefährlichen Hitzewerten an deinen Arbeitsplätzen rechtzeitig warnen können, benötigen wir deine Erlaubnis für Push-Benachrichtigungen. Bitte erlaube diese im nächsten Schritt.", "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.") }
    var onboardingAllowButton: String { t("Erlauben & Loslegen", "Allow & Start") }
    var onboardingSkipButton: String { t("Später / Überspringen", "Later / Skip") }
    var todayTitle: String { t("Heute", "Today") }

    func weekdayShort(_ weekday: Int) -> String {
        switch weekday {
        case 1:
            return t("SO", "SUN")
        case 2:
            return t("MO", "MON")
        case 3:
            return t("DI", "TUE")
        case 4:
            return t("MI", "WED")
        case 5:
            return t("DO", "THU")
        case 6:
            return t("FR", "FRI")
        case 7:
            return t("SA", "SAT")
        default:
            return "-"
        }
    }

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

    func severityName(_ severity: HazardSeverity) -> String {
        switch severity {
        case .none, .coldYellow, .coldOrange, .coldRed:
            return t("Grün", "Green")
        case .heatYellow:
            return t("Gelb", "Yellow")
        case .heatOrange:
            return "Orange"
        case .heatRed:
            return t("Rot", "Red")
        }
    }

    func severityHeadline(_ severity: HazardSeverity) -> String {
        switch severity {
        case .none, .coldYellow, .coldOrange, .coldRed:
            return t("Stabil", "Stable")
        case .heatYellow:
            return t("Erhöht", "Elevated")
        case .heatOrange:
            return t("Hoch", "High")
        case .heatRed:
            return t("Kritisch", "Critical")
        }
    }

    func severityAction(_ severity: HazardSeverity) -> String {
        switch severity {
        case .none:
            return t("Alles ruhig. Standardmaßnahmen reichen aus.", "All clear. Standard precautions are sufficient.")
        case .heatYellow:
            return t("Pausen und Schatten erhöhen.", "Increase breaks and shade usage.")
        case .heatOrange:
            return t("Arbeitszeiten anpassen und Teams aktiv schützen.", "Adjust schedules and actively protect teams.")
        case .heatRed:
            return t("Sofort Hitze-V Schutzmaßnahmen umsetzen.", "Apply Heat-V protective measures immediately.")
        case .coldYellow, .coldOrange, .coldRed:
            return t("Alles ruhig. Standardmaßnahmen reichen aus.", "All clear. Standard precautions are sufficient.")
        }
    }
    
    func copyrightLine(year: Int) -> String {
        "© \(year) SFK Robert Lembacher und Dr. Thomas Entner"
    }
}

private extension HazardSeverity {
    var tint: Color {
        switch self {
        case .none:
            return Color(red: 0.15, green: 0.72, blue: 0.45)
        case .heatYellow:
            return Color(red: 0.89, green: 0.72, blue: 0.11)
        case .heatOrange:
            return Color(red: 0.95, green: 0.52, blue: 0.18)
        case .heatRed:
            return Color(red: 0.85, green: 0.24, blue: 0.20)
        case .coldYellow, .coldOrange, .coldRed:
            return Color(red: 0.15, green: 0.72, blue: 0.45)
        }
    }

    var symbol: String {
        switch self {
        case .none, .coldYellow, .coldOrange, .coldRed:
            return "checkmark.seal.fill"
        case .heatYellow, .heatOrange:
            return "exclamationmark.circle.fill"
        case .heatRed:
            return "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    ContentView()
}
