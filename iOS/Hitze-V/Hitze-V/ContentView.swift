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
            .onChange(of: languageRawValue) { _ in
                Task {
                    await viewModel.resyncSubscriptionsForCurrentLanguage()
                }
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
    private enum UvExposureLevel {
        case none
        case level35
        case level67
        case level810
        case level11Plus

        init(uvIndex: Double?) {
            guard let uvIndex else {
                self = .none
                return
            }

            switch uvIndex {
            case ..<3:
                self = .none
            case ..<6:
                self = .level35
            case ..<8:
                self = .level67
            case ..<11:
                self = .level810
            default:
                self = .level11Plus
            }
        }

        var isWarning: Bool {
            switch self {
            case .level67, .level810, .level11Plus:
                return true
            case .none, .level35:
                return false
            }
        }
    }

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

    private var uvExposureLevel: UvExposureLevel {
        UvExposureLevel(uvIndex: snapshot?.uvIndex)
    }

    private var isUvRestrictionWindow: Bool {
        let hour = Self.viennaCalendar.component(.hour, from: Date())
        return hour >= 11 && hour < 15
    }

    private var uvWarningBadgeTitle: String? {
        switch uvExposureLevel {
        case .level67:
            return copy.uvWarningBadge67
        case .level810:
            return copy.uvWarningBadge810
        case .level11Plus:
            return copy.uvWarningBadge11Plus
        case .none, .level35:
            return nil
        }
    }

    private var uvWarningDetail: String? {
        switch uvExposureLevel {
        case .level67:
            return isUvRestrictionWindow ? copy.uvWarningDetail67 : copy.uvWarningDetail67OutsideWindow
        case .level810:
            return isUvRestrictionWindow ? copy.uvWarningDetail810 : copy.uvWarningDetail810OutsideWindow
        case .level11Plus:
            return copy.uvWarningDetail11Plus
        case .none, .level35:
            return nil
        }
    }

    private var uvWarningTint: Color {
        switch uvExposureLevel {
        case .level67:
            return Color(red: 0.95, green: 0.52, blue: 0.18)
        case .level810:
            return Color(red: 0.85, green: 0.24, blue: 0.20)
        case .level11Plus:
            return Color(red: 0.42, green: 0.45, blue: 0.50)
        case .none, .level35:
            return .clear
        }
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

                    if let uvWarningDetail {
                        Label(uvWarningDetail, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(uvWarningTint)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }

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
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 8) {
                        miniFact(icon: "sun.max", text: uvText(snapshot.uvIndex))
                        miniFact(icon: "thermometer", text: tempText(snapshot.apparentTemperature))
                    }

                    if let uvWarningBadgeTitle {
                        Text(uvWarningBadgeTitle)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(uvWarningTint, in: Capsule())
                    }
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
            return " (\(copy.heatWarningLevelLabel) \(forecast.severity.level))"
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
    case bg
    case da
    case de
    case en
    case et
    case fi
    case fr
    case el
    case ga
    case it
    case hr
    case lv
    case lt
    case mt
    case nl
    case pl
    case pt
    case ro
    case sv
    case sk
    case sl
    case es
    case cs
    case hu
    case tr

    var id: String { rawValue }

    var resolvedLanguage: ResolvedLanguage {
        switch self {
        case .de:
            return .de
        case .bg:
            return .bg
        case .da:
            return .da
        case .en:
            return .en
        case .et:
            return .et
        case .fi:
            return .fi
        case .fr:
            return .fr
        case .el:
            return .el
        case .ga:
            return .ga
        case .it:
            return .it
        case .hr:
            return .hr
        case .lv:
            return .lv
        case .lt:
            return .lt
        case .mt:
            return .mt
        case .nl:
            return .nl
        case .pl:
            return .pl
        case .pt:
            return .pt
        case .ro:
            return .ro
        case .sv:
            return .sv
        case .sk:
            return .sk
        case .sl:
            return .sl
        case .es:
            return .es
        case .cs:
            return .cs
        case .hu:
            return .hu
        case .tr:
            return .tr
        case .system:
            let languageCode = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
            switch languageCode {
            case "de": return .de
            case "bg": return .bg
            case "da": return .da
            case "en": return .en
            case "et": return .et
            case "fi": return .fi
            case "fr": return .fr
            case "el": return .el
            case "ga": return .ga
            case "it": return .it
            case "hr": return .hr
            case "lv": return .lv
            case "lt": return .lt
            case "mt": return .mt
            case "nl": return .nl
            case "pl": return .pl
            case "pt": return .pt
            case "ro": return .ro
            case "sv": return .sv
            case "sk": return .sk
            case "sl": return .sl
            case "es": return .es
            case "cs": return .cs
            case "hu": return .hu
            case "tr": return .tr
            default: return .en
            }
        }
    }
}

enum ResolvedLanguage {
    case de
    case bg
    case da
    case en
    case et
    case fi
    case fr
    case el
    case ga
    case it
    case hr
    case lv
    case lt
    case mt
    case nl
    case pl
    case pt
    case ro
    case sv
    case sk
    case sl
    case es
    case cs
    case hu
    case tr

    var languageCode: String {
        switch self {
        case .de: return "de"
        case .bg: return "bg"
        case .da: return "da"
        case .en: return "en"
        case .et: return "et"
        case .fi: return "fi"
        case .fr: return "fr"
        case .el: return "el"
        case .ga: return "ga"
        case .it: return "it"
        case .hr: return "hr"
        case .lv: return "lv"
        case .lt: return "lt"
        case .mt: return "mt"
        case .nl: return "nl"
        case .pl: return "pl"
        case .pt: return "pt"
        case .ro: return "ro"
        case .sv: return "sv"
        case .sk: return "sk"
        case .sl: return "sl"
        case .es: return "es"
        case .cs: return "cs"
        case .hu: return "hu"
        case .tr: return "tr"
        }
    }
}

struct Copybook {
    let language: ResolvedLanguage

    func t(_ german: String, _ english: String) -> String {
        switch language {
        case .de:
            return german
        case .en:
            return english
        default:
            return Self.translations[language]?[english]
                ?? Self.longTextTranslations[language]?[english]
                ?? english
        }
    }

    var shortTitle: String { t("Hitze-V", "Heat-V") }
    var dashboardTitle: String { t("Sicher durch die Hitze", "Heat Safety at a Glance") }
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
    var infoScreenUvMeasuresTitle: String { t("UV-Schutzmaßnahmen", "UV Protection Measures") }
    var infoScreenUvMeasuresSubtitle: String { t("Der höchste UV-Index des Tages bestimmt die Belastung durch UV-Strahlung. In Österreich ist von April bis September zwischen 11:00 und 15:00 Uhr meist mit einem UV-Index >= 5 zu rechnen.", "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.") }
    var infoScreenUvLevel35Title: String { t("UV-Index 3-5", "UV Index 3-5") }
    var infoScreenUvLevel35Body: String { t("Pflicht: T-Shirt bis mindestens Mitte Oberarm, Hose bis mindestens zum Knie. Empfohlen: Kopfbedeckung, Sonnenbrille, Sonnencreme. Keine Arbeitseinschränkungen.", "Mandatory: T-shirt to at least mid upper arm, trousers to at least the knee. Recommended: head covering, sunglasses, sunscreen. No work restrictions.") }
    var infoScreenUvLevel67Title: String { t("UV-Index 6-7", "UV Index 6-7") }
    var infoScreenUvLevel67Body: String { t("Pflicht: Kleidung wie oben plus Kopfbedeckung (idealerweise mit Nackenschutz), Sonnenbrille und Sonnencreme. Arbeit in direkter Sonne zwischen 11:00 und 15:00 Uhr maximal 2 Stunden, sonst Schatten oder Indoor.", "Mandatory: clothing as above plus head covering (ideally with neck protection), sunglasses, and sunscreen. Direct sun exposure between 11:00 and 15:00 limited to a maximum of 2 hours, otherwise shade or indoors.") }
    var infoScreenUvLevel810Title: String { t("UV-Index 8-10", "UV Index 8-10") }
    var infoScreenUvLevel810Body: String { t("Gleiche Schutzmaßnahmen wie bei UV-Index 6-7. Arbeit in direkter Sonne zwischen 11:00 und 15:00 Uhr maximal 1 Stunde, sonst Schatten oder Indoor.", "Same protective measures as UV index 6-7. Direct sun exposure between 11:00 and 15:00 limited to a maximum of 1 hour, otherwise shade or indoors.") }
    var infoScreenUvLevel11Title: String { t("UV-Index >= 11", "UV Index >= 11") }
    var infoScreenUvLevel11Body: String { t("Wurde im österreichischen Flachland bisher nicht gemessen.", "Has not been measured in Austrian lowland regions so far.") }
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
    var onboardingPushText: String { t("Damit wir dich bei gefährlichen Hitzewerten an deinen Arbeitsplätzen rechtzeitig warnen können, benötigen wir deine Erlaubnis für Push-Benachrichtigungen. Push-Nachrichten sind aktuell nur für Hitzewarnmeldungen auf iOS und Android verfügbar. UV-Warnmeldungen können derzeit nicht per Push versendet werden. Bitte erlaube diese im nächsten Schritt.", "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.") }
    var onboardingAllowButton: String { t("Erlauben & Loslegen", "Allow & Start") }
    var onboardingSkipButton: String { t("Später / Überspringen", "Later / Skip") }
    var todayTitle: String { t("Heute", "Today") }
    var heatWarningLevelLabel: String { t("Hitzewarnstufe", "Heat warning level") }
    var uvWarningBadge67: String { t("UV-Warnung 6-7", "UV Warning 6-7") }
    var uvWarningBadge810: String { t("UV-Warnung 8-10", "UV Warning 8-10") }
    var uvWarningBadge11Plus: String { t("UV-Warnung >= 11", "UV Warning >= 11") }
    var uvWarningDetail67: String { t("Direkte Sonne zwischen 11:00 und 15:00 Uhr auf max. 2 Stunden begrenzen, sonst Schatten oder Indoor.", "Limit direct sun exposure between 11:00 and 15:00 to max. 2 hours, otherwise shade or indoors.") }
    var uvWarningDetail67OutsideWindow: String { t("Erhöhte UV-Belastung heute: Schutzkleidung, Kopfbedeckung, Sonnenbrille und Sonnencreme konsequent verwenden.", "Increased UV exposure today: consistently use protective clothing, head covering, sunglasses, and sunscreen.") }
    var uvWarningDetail810: String { t("Direkte Sonne zwischen 11:00 und 15:00 Uhr auf max. 1 Stunde begrenzen, sonst Schatten oder Indoor.", "Limit direct sun exposure between 11:00 and 15:00 to max. 1 hour, otherwise shade or indoors.") }
    var uvWarningDetail810OutsideWindow: String { t("Hohe UV-Belastung heute: Schutzmaßnahmen konsequent umsetzen und Arbeiten bevorzugt in den Schatten verlagern.", "High UV exposure today: apply protective measures consistently and prioritize work in shade.") }
    var uvWarningDetail11Plus: String { t("UV-Index >= 11 wurde im österreichischen Flachland bisher nicht gemessen. Falls gemeldet: direkte Sonne vermeiden, nur mit maximalem Schutz arbeiten.", "UV index >= 11 has not been measured in Austrian lowland regions so far. If reported: avoid direct sun and work only with maximum protection.") }

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
        case .bg:
            return "BG"
        case .da:
            return "DA"
        case .de:
            return "DE"
        case .en:
            return "EN"
        case .et:
            return "ET"
        case .fi:
            return "FI"
        case .fr:
            return "FR"
        case .el:
            return "EL"
        case .ga:
            return "GA"
        case .it:
            return "IT"
        case .hr:
            return "HR"
        case .lv:
            return "LV"
        case .lt:
            return "LT"
        case .mt:
            return "MT"
        case .nl:
            return "NL"
        case .pl:
            return "PL"
        case .pt:
            return "PT"
        case .ro:
            return "RO"
        case .sv:
            return "SV"
        case .sk:
            return "SK"
        case .sl:
            return "SL"
        case .es:
            return "ES"
        case .cs:
            return "CS"
        case .hu:
            return "HU"
        case .tr:
            return "TR"
        }
    }

    func languageOption(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return t("Systemsprache", "System language")
        case .bg:
            return t("Bulgarisch", "Bulgarian")
        case .da:
            return t("Dänisch", "Danish")
        case .de:
            return t("Deutsch", "German")
        case .en:
            return t("Englisch", "English")
        case .et:
            return t("Estnisch", "Estonian")
        case .fi:
            return t("Finnisch", "Finnish")
        case .fr:
            return t("Französisch", "French")
        case .el:
            return t("Griechisch", "Greek")
        case .ga:
            return t("Irisch", "Irish")
        case .it:
            return t("Italienisch", "Italian")
        case .hr:
            return t("Kroatisch", "Croatian")
        case .lv:
            return t("Lettisch", "Latvian")
        case .lt:
            return t("Litauisch", "Lithuanian")
        case .mt:
            return t("Maltesisch", "Maltese")
        case .nl:
            return t("Niederländisch", "Dutch")
        case .pl:
            return t("Polnisch", "Polish")
        case .pt:
            return t("Portugiesisch", "Portuguese")
        case .ro:
            return t("Rumänisch", "Romanian")
        case .sv:
            return t("Schwedisch", "Swedish")
        case .sk:
            return t("Slowakisch", "Slovak")
        case .sl:
            return t("Slowenisch", "Slovenian")
        case .es:
            return t("Spanisch", "Spanish")
        case .cs:
            return t("Tschechisch", "Czech")
        case .hu:
            return t("Ungarisch", "Hungarian")
        case .tr:
            return t("Türkisch", "Turkish")
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

    private static let translations: [ResolvedLanguage: [String: String]] = [
        .bg: [
            "Settings": "Настройки",
            "Language": "Език",
            "Appearance": "Външен вид",
            "Info & Legal": "Информация и правна информация",
            "Development": "Разработка",
            "System": "Система",
            "Light": "Светъл",
            "Dark": "Тъмен",
            "Close": "Затвори",
            "Cancel": "Отказ",
            "Refresh data": "Обновяване",
            "Create New Workplace": "Създаване на ново работно място",
            "Delete workplace": "Изтриване на работно място",
            "Workplaces": "Работни места",
            "Warnings": "Предупреждения",
            "Current Risk": "Текущ риск",
            "Peak UV": "Пик UV",
            "Today": "Днес"
        ],
        .da: [
            "Settings": "Indstillinger",
            "Language": "Sprog",
            "Appearance": "Udseende",
            "Info & Legal": "Info og jura",
            "Development": "Udvikling",
            "System": "System",
            "Light": "Lys",
            "Dark": "Mørk",
            "Close": "Luk",
            "Cancel": "Annuller",
            "Refresh data": "Opdater",
            "Create New Workplace": "Opret ny arbejdsplads",
            "Delete workplace": "Slet arbejdsplads",
            "Workplaces": "Arbejdspladser",
            "Warnings": "Advarsler",
            "Current Risk": "Aktuel risiko",
            "Peak UV": "Højeste UV",
            "Today": "I dag"
        ],
        .et: ["Settings": "Seaded", "Language": "Keel"],
        .fi: ["Settings": "Asetukset", "Language": "Kieli"],
        .fr: ["Settings": "Paramètres", "Language": "Langue", "Close": "Fermer", "Cancel": "Annuler", "Today": "Aujourd'hui"],
        .el: ["Settings": "Ρυθμίσεις", "Language": "Γλώσσα"],
        .ga: ["Settings": "Socruithe", "Language": "Teanga"],
        .it: ["Settings": "Impostazioni", "Language": "Lingua", "Close": "Chiudi", "Cancel": "Annulla", "Today": "Oggi"],
        .hr: ["Settings": "Postavke", "Language": "Jezik"],
        .lv: ["Settings": "Iestatījumi", "Language": "Valoda"],
        .lt: ["Settings": "Nustatymai", "Language": "Kalba"],
        .mt: ["Settings": "Settings", "Language": "Lingwa"],
        .nl: ["Settings": "Instellingen", "Language": "Taal", "Close": "Sluiten", "Cancel": "Annuleren", "Today": "Vandaag"],
        .pl: ["Settings": "Ustawienia", "Language": "Język"],
        .pt: ["Settings": "Definições", "Language": "Idioma"],
        .ro: ["Settings": "Setări", "Language": "Limbă"],
        .sv: ["Settings": "Inställningar", "Language": "Språk", "Close": "Stäng", "Cancel": "Avbryt", "Today": "I dag"],
        .sk: ["Settings": "Nastavenia", "Language": "Jazyk"],
        .sl: ["Settings": "Nastavitve", "Language": "Jezik"],
        .es: ["Settings": "Ajustes", "Language": "Idioma", "Close": "Cerrar", "Cancel": "Cancelar", "Today": "Hoy"],
        .cs: ["Settings": "Nastavení", "Language": "Jazyk"],
        .hu: ["Settings": "Beállítások", "Language": "Nyelv"],
        .tr: ["Settings": "Ayarlar", "Language": "Dil", "Close": "Kapat", "Cancel": "İptal", "Today": "Bugün"]
    ]

    private static let longTextTranslations: [ResolvedLanguage: [String: String]] = [
        .bg: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Помагаме ви да спазвате законовите изисквания за рисковете от жега и естествено UV лъчение при работа на открито. Следете постоянно температурите и UV индекса.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "За да ви предупреждаваме навреме за опасни нива на жега на работните ви места, ни е нужно разрешение за push известия. Моля, разрешете ги в следващата стъпка.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Най-високият UV индекс за деня определя UV натоварването. В Австрия от април до септември между 11:00 и 15:00 обикновено се очаква UV индекс >= 5."
        ],
        .da: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Vi hjælper dig med at overholde lovkrav om farer fra varme og naturlig UV-stråling ved udendørs arbejde. Hold altid øje med temperaturer og UV-indeks.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "For at vi kan advare dig i tide om farlige varmeniveauer på dine arbejdspladser, har vi brug for din tilladelse til push-notifikationer. Tillad dem i næste trin.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Dagens højeste UV-indeks bestemmer UV-belastningen. I Østrig forventes der fra april til september normalt et UV-indeks >= 5 mellem kl. 11:00 og 15:00."
        ],
        .et: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Aitame sul täita õigusnõudeid, mis puudutavad kuumuse ja loodusliku UV-kiirguse ohte välitöödel. Hoia temperatuuridel ja UV-indeksil alati silm peal.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Et saaksime sind töökohtade ohtlikest kuumatasemetest õigel ajal hoiatada, vajame push-teavituste luba. Luba need järgmises sammus.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Päeva kõrgeim UV-indeks määrab UV-koormuse. Austrias on aprillist septembrini ajavahemikus 11:00–15:00 tavaliselt oodata UV-indeksit >= 5."
        ],
        .fi: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Autamme sinua noudattamaan lakisääteisiä vaatimuksia, jotka koskevat kuumuuden ja luonnollisen UV-säteilyn riskejä ulkotyössä. Seuraa lämpötiloja ja UV-indeksiä jatkuvasti.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Jotta voimme varoittaa sinua ajoissa vaarallisista kuumuustasoista työpaikoillasi, tarvitsemme luvan push-ilmoituksiin. Salli ne seuraavassa vaiheessa.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Päivän korkein UV-indeksi määrittää UV-altistuksen. Itävallassa huhti-syyskuussa UV-indeksi >= 5 on yleensä odotettavissa klo 11:00–15:00."
        ],
        .fr: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Nous vous aidons à respecter les exigences légales liées aux risques de chaleur et de rayonnement UV naturel lors du travail en extérieur. Gardez toujours un œil sur les températures et l'indice UV.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Afin de vous avertir à temps des niveaux de chaleur dangereux sur vos lieux de travail, nous avons besoin de votre autorisation pour les notifications push. Veuillez les autoriser à l'étape suivante.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "L'indice UV maximal de la journée détermine l'exposition aux UV. En Autriche, d'avril à septembre, un indice UV >= 5 est généralement attendu entre 11h00 et 15h00."
        ],
        .el: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Σας βοηθάμε να συμμορφώνεστε με τις νομικές απαιτήσεις σχετικά με τους κινδύνους από τη ζέστη και τη φυσική υπεριώδη ακτινοβολία στην υπαίθρια εργασία. Παρακολουθείτε πάντα τη θερμοκρασία και τον δείκτη UV.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Για να σας προειδοποιούμε έγκαιρα για επικίνδυνα επίπεδα ζέστης στους χώρους εργασίας σας, χρειαζόμαστε την άδειά σας για push ειδοποιήσεις. Επιτρέψτε τις στο επόμενο βήμα.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Ο υψηλότερος δείκτης UV της ημέρας καθορίζει την έκθεση στην υπεριώδη ακτινοβολία. Στην Αυστρία, από Απρίλιο έως Σεπτέμβριο, αναμένεται συνήθως δείκτης UV >= 5 μεταξύ 11:00 και 15:00."
        ],
        .ga: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Cabhraímid leat riachtanais dhlíthiúla maidir le rioscaí ó theas agus radaíocht UV nádúrtha in obair lasmuigh a chomhlíonadh. Coinnigh súil ar theocht agus ar an innéacs UV i gcónaí.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Chun rabhadh tráthúil a thabhairt duit faoi leibhéil dainséaracha teasa ag d'ionaid oibre, teastaíonn cead uainn le haghaidh fógraí brú. Ceadaigh iad sa chéad chéim eile.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Cinneann an t-innéacs UV is airde den lá an nochtadh UV. San Ostair, ó Aibreán go Meán Fómhair, bíonn innéacs UV >= 5 le súil de ghnáth idir 11:00 agus 15:00."
        ],
        .it: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Ti aiutiamo a rispettare i requisiti legali relativi ai rischi da calore e radiazione UV naturale per il lavoro all'aperto. Tieni sempre sotto controllo temperature e indice UV.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Per avvisarti in tempo sui livelli di calore pericolosi nei tuoi luoghi di lavoro, abbiamo bisogno della tua autorizzazione per le notifiche push. Consentile nel passaggio successivo.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "L'indice UV massimo della giornata determina l'esposizione ai raggi UV. In Austria, da aprile a settembre, tra le 11:00 e le 15:00 è generalmente previsto un indice UV >= 5."
        ],
        .hr: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomažemo vam uskladiti se sa zakonskim zahtjevima vezanim uz opasnosti od vrućine i prirodnog UV zračenja pri radu na otvorenom. Uvijek pratite temperaturu i UV indeks.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Kako bismo vas na vrijeme upozorili na opasne razine vrućine na vašim radnim mjestima, trebamo vaše dopuštenje za push obavijesti. Molimo omogućite ih u sljedećem koraku.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Najviši dnevni UV indeks određuje izloženost UV zračenju. U Austriji se od travnja do rujna između 11:00 i 15:00 obično očekuje UV indeks >= 5."
        ],
        .lv: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Mēs palīdzam ievērot juridiskās prasības attiecībā uz karstuma un dabiskā UV starojuma riskiem āra darbā. Vienmēr sekojiet temperatūrai un UV indeksam.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Lai mēs varētu savlaicīgi brīdināt par bīstamu karstuma līmeni jūsu darba vietās, mums nepieciešama atļauja push paziņojumiem. Lūdzu, atļaujiet tos nākamajā solī.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Dienas augstākais UV indekss nosaka UV slodzi. Austrijā no aprīļa līdz septembrim laikā no 11:00 līdz 15:00 parasti gaidāms UV indekss >= 5."
        ],
        .lt: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Padedame laikytis teisinių reikalavimų dėl karščio ir natūralios UV spinduliuotės pavojų dirbant lauke. Visada stebėkite temperatūrą ir UV indeksą.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Kad galėtume laiku įspėti apie pavojingą karščio lygį jūsų darbo vietose, mums reikia leidimo siųsti push pranešimus. Prašome juos leisti kitame žingsnyje.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Didžiausias dienos UV indeksas lemia UV poveikį. Austrijoje nuo balandžio iki rugsėjo tarp 11:00 ir 15:00 paprastai tikimasi UV indekso >= 5."
        ],
        .mt: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Ngħinuk tikkonforma mar-rekwiżiti legali dwar ir-riskji mis-sħana u r-radjazzjoni UV naturali fix-xogħol barra. Żomm għajnejk fuq it-temperaturi u l-indiċi UV il-ħin kollu.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Biex inwissuk fil-ħin dwar livelli perikolużi ta' sħana fil-postijiet tax-xogħol tiegħek, għandna bżonn il-permess tiegħek għan-notifiki push. Jekk jogħġbok ippermettilhom fil-pass li jmiss.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "L-ogħla indiċi UV tal-jum jiddetermina l-espożizzjoni UV. Fl-Awstrija, minn April sa Settembru, normalment ikun mistenni indiċi UV >= 5 bejn 11:00 u 15:00."
        ],
        .nl: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "We helpen je te voldoen aan wettelijke eisen rond risico's door hitte en natuurlijke UV-straling bij buitenwerk. Houd temperaturen en UV-index altijd in de gaten.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Om je op tijd te waarschuwen voor gevaarlijke hitteniveaus op je werkplekken, hebben we toestemming nodig voor pushmeldingen. Sta die toe in de volgende stap.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "De hoogste UV-index van de dag bepaalt de UV-belasting. In Oostenrijk wordt van april tot september tussen 11:00 en 15:00 meestal een UV-index >= 5 verwacht."
        ],
        .pl: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomagamy spełniać wymogi prawne dotyczące zagrożeń związanych z upałem i naturalnym promieniowaniem UV przy pracy na zewnątrz. Zawsze monitoruj temperaturę i indeks UV.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Abyśmy mogli na czas ostrzegać o niebezpiecznych poziomach upału w Twoich miejscach pracy, potrzebujemy zgody na powiadomienia push. Włącz je w następnym kroku.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Najwyższy dzienny indeks UV określa ekspozycję na UV. W Austrii od kwietnia do września między 11:00 a 15:00 zwykle oczekuje się indeksu UV >= 5."
        ],
        .pt: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Ajudamos a cumprir os requisitos legais relativos aos perigos do calor e da radiação UV natural no trabalho ao ar livre. Acompanhe sempre as temperaturas e o índice UV.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Para o avisarmos a tempo sobre níveis perigosos de calor nos seus locais de trabalho, precisamos da sua permissão para notificações push. Permita-as no próximo passo.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "O índice UV mais elevado do dia determina a exposição UV. Na Áustria, de abril a setembro, normalmente espera-se um índice UV >= 5 entre as 11:00 e as 15:00."
        ],
        .ro: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Te ajutăm să respecți cerințele legale privind riscurile de căldură și radiație UV naturală la munca în aer liber. Urmărește permanent temperaturile și indicele UV.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Pentru a te avertiza la timp despre niveluri periculoase de căldură la locurile tale de muncă, avem nevoie de permisiunea pentru notificări push. Te rugăm să le permiți la pasul următor.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Cel mai mare indice UV al zilei determină expunerea la UV. În Austria, din aprilie până în septembrie, între 11:00 și 15:00 se așteaptă de obicei un indice UV >= 5."
        ],
        .sv: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Vi hjälper dig att uppfylla lagkrav kring risker från värme och naturlig UV-strålning vid utomhusarbete. Håll alltid koll på temperaturer och UV-index.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "För att vi ska kunna varna dig i tid om farliga värmenivåer på dina arbetsplatser behöver vi ditt tillstånd för pushnotiser. Tillåt dem i nästa steg.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Dagens högsta UV-index bestämmer UV-belastningen. I Österrike förväntas från april till september vanligtvis ett UV-index >= 5 mellan 11:00 och 15:00."
        ],
        .sk: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomáhame vám dodržiavať zákonné požiadavky týkajúce sa rizík z tepla a prirodzeného UV žiarenia pri práci vonku. Neustále sledujte teploty a UV index.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Aby sme vás mohli včas upozorniť na nebezpečné úrovne tepla na vašich pracoviskách, potrebujeme váš súhlas s push notifikáciami. Povoľte ich v ďalšom kroku.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Najvyšší UV index dňa určuje UV záťaž. V Rakúsku sa od apríla do septembra medzi 11:00 a 15:00 zvyčajne očakáva UV index >= 5."
        ],
        .sl: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomagamo vam izpolnjevati zakonske zahteve glede nevarnosti vročine in naravnega UV sevanja pri delu na prostem. Vedno spremljajte temperature in UV indeks.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Da vas lahko pravočasno opozorimo na nevarne ravni vročine na vaših delovnih mestih, potrebujemo vaše dovoljenje za push obvestila. Omogočite jih v naslednjem koraku.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Najvišji dnevni UV indeks določa UV obremenitev. V Avstriji je od aprila do septembra med 11:00 in 15:00 običajno pričakovan UV indeks >= 5."
        ],
        .es: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Te ayudamos a cumplir los requisitos legales sobre riesgos por calor y radiación UV natural en trabajos al aire libre. Mantén siempre bajo control las temperaturas y el índice UV.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Para poder avisarte a tiempo sobre niveles peligrosos de calor en tus lugares de trabajo, necesitamos tu permiso para notificaciones push. Permítelas en el siguiente paso.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "El índice UV más alto del día determina la exposición a UV. En Austria, de abril a septiembre, normalmente se espera un índice UV >= 5 entre las 11:00 y las 15:00."
        ],
        .cs: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomáháme vám dodržovat zákonné požadavky týkající se rizik z horka a přirozeného UV záření při práci venku. Neustále sledujte teploty a UV index.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Abychom vás mohli včas varovat před nebezpečnými úrovněmi horka na vašich pracovištích, potřebujeme vaše povolení k push oznámením. Povolte je v dalším kroku.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Nejvyšší denní UV index určuje UV zátěž. V Rakousku se od dubna do září mezi 11:00 a 15:00 obvykle očekává UV index >= 5."
        ],
        .hu: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Segítünk megfelelni a szabadtéri munkát érintő hő- és természetes UV-sugárzási kockázatokra vonatkozó jogi követelményeknek. Mindig figyeld a hőmérsékletet és az UV-indexet.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Ahhoz, hogy időben figyelmeztethessünk a munkahelyeiden jelentkező veszélyes hőszintekre, engedélyre van szükségünk a push értesítésekhez. Kérjük, engedélyezd a következő lépésben.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "A napi legmagasabb UV-index határozza meg az UV-terhelést. Ausztriában áprilistól szeptemberig 11:00 és 15:00 között általában >= 5 UV-index várható."
        ],
        .tr: [
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Açık havada çalışma sırasında ısı ve doğal UV ışınımı risklerine ilişkin yasal gerekliliklere uymanıza yardımcı oluyoruz. Sıcaklıkları ve UV indeksini her zaman takip edin.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Çalışma alanlarınızdaki tehlikeli sıcaklık seviyeleri hakkında sizi zamanında uyarabilmemiz için push bildirimlerine izin vermeniz gerekir. Lütfen bir sonraki adımda izin verin.",
            "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00.": "Günün en yüksek UV indeksi UV maruziyetini belirler. Avusturya'da Nisan-Eylül arasında 11:00-15:00 saatleri arasında genellikle UV indeksi >= 5 beklenir."
        ]
    ]
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
