import SwiftUI

struct HeroCard: View {
    let copy: Copybook
    let status: DashboardStatus
    let worksiteCount: Int
    let onRetry: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var headline: String {
        switch status.phase {
        case .noWorksites:
            return copy.dashboardTitle
        case _ where status.hasWarning:
            return copy.severityDescription(status.highestSeverity)
        case .complete:
            return copy.severityHeadline(status.isUvOnlyElevated ? .heatYellow : .none)
        case .loading:
            return copy.heroLoadingHeadline
        case .failed, .partial:
            return copy.heroUnknownHeadline
        }
    }

    private var actionText: String {
        switch status.phase {
        case .noWorksites:
            return copy.heroNoWorkplacesText
        case .loading where !status.hasWarning:
            return copy.loading
        case .failed:
            return copy.heroLoadFailedText
        case .partial where !status.hasWarning:
            return copy.heroPartialDataText
        default:
            if status.hasWarning {
                let action = copy.severityAction(status.highestSeverity)
                return status.phase == .partial ? action + "\n" + copy.heroPartialDataText : action
            }
            return status.isUvOnlyElevated
                ? copy.uvOnlyAction(worksitesCount: status.uvAffectedCount)
                : copy.severityAction(.none)
        }
    }

    private var headlineSymbol: String {
        if status.hasWarning { return status.highestSeverity.symbol }
        switch status.phase {
        case .complete: return status.isUvOnlyElevated ? "sun.max.fill" : "checkmark.seal.fill"
        case .loading: return "arrow.triangle.2.circlepath"
        case .failed, .partial: return "questionmark.circle.fill"
        case .noWorksites: return "sun.max.trianglebadge.exclamationmark.fill"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(copy.dashboardTitle)
                .font(.title.weight(.black))
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if status.phase != .noWorksites {
                VStack(spacing: 8) {
                    Label(headline, systemImage: headlineSymbol)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.22), in: Capsule())

                    Text(actionText)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)

                    if let oldestUpdate = status.oldestUpdate {
                        Text(copy.updatedAt(copy.time(oldestUpdate)))
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    if status.phase == .failed {
                        Button(copy.retryButton, systemImage: "arrow.clockwise", action: onRetry)
                            .buttonStyle(.bordered)
                            .tint(.white)
                    }
                }
                .accessibilityElement(children: .combine)

                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 10))
                    : AnyLayout(HStackLayout(spacing: 10))
                layout {
                    HeroMetricBubble(icon: "briefcase.fill", label: copy.workplaceLabel, value: worksiteCount.formatted(.number.locale(copy.locale)))
                    HeroMetricBubble(icon: "exclamationmark.triangle.fill", label: copy.warningsLabel, value: status.heatWarningCount.formatted(.number.locale(copy.locale)))
                }
            } else {
                Text(actionText)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DashboardPalette.heroGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.black.opacity(0.08))
                }
        }
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
    }
}

private struct HeroMetricBubble: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(value)
                .font(.title2.weight(.heavy))
                .fontDesign(.rounded)
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(10)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct GlanceCard: View {
    let copy: Copybook
    let status: DashboardStatus

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var riskSeverity: HazardSeverity {
        status.isUvOnlyElevated ? .heatYellow : status.highestSeverity
    }

    private var riskValue: String {
        if status.hasWarning || status.phase == .complete {
            return copy.severityHeadline(riskSeverity)
        }
        return status.phase == .loading ? copy.heroLoadingHeadline : copy.unknownRisk
    }

    private var riskIcon: (String, Color) {
        if status.hasWarning || status.phase == .complete {
            return (riskSeverity.symbol, riskSeverity.iconTint)
        }
        return ("questionmark.circle.fill", DashboardPalette.neutralIcon)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(copy.glanceTitle)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(copy.glanceSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 10))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
            layout {
                GlanceTile(
                    title: copy.currentRiskTitle,
                    value: riskValue,
                    accessibilityValue: status.hasWarning ? copy.severityDescription(status.highestSeverity) : riskValue,
                    icon: riskIcon.0,
                    tint: riskIcon.1
                )
                GlanceTile(
                    title: copy.uvPeakTitle,
                    value: copy.uvText(status.highestUV),
                    accessibilityValue: copy.spokenUV(status.highestUV),
                    icon: "sun.max.fill",
                    tint: DashboardPalette.uvIcon,
                    isEmphasized: status.uvAffectedCount > 0
                )
                GlanceTile(
                    title: copy.apparentTitle,
                    value: copy.temperature(status.highestApparentTemperature),
                    accessibilityValue: copy.spokenTemperature(status.highestApparentTemperature),
                    icon: "thermometer.medium",
                    tint: DashboardPalette.apparentIcon
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct GlanceTile: View {
    let title: String
    let value: String
    let accessibilityValue: String
    let icon: String
    let tint: Color
    var isEmphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.subheadline.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isEmphasized ? tint : Color.primary.opacity(0.06), lineWidth: isEmphasized ? 2 : 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
    }
}

struct MockModeBanner: View {
    let copy: Copybook
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Label(copy.mockModeBanner, systemImage: "theatermasks.fill")
            .labelStyle(BannerLabelStyle(showsIcon: !dynamicTypeSize.isAccessibilitySize))
            .font(.footnote.weight(.semibold))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(red: 0.45, green: 0.18, blue: 0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}

private struct BannerLabelStyle: LabelStyle {
    let showsIcon: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if showsIcon {
                configuration.icon
            }
            configuration.title
        }
    }
}

struct LegalFooter: View {
    let copy: Copybook

    var body: some View {
        VStack(spacing: 6) {
            Text(copy.dataSourceLine)
            Text(copy.copyrightLine(year: Calendar.current.component(.year, from: Date())))
            if let legalURL = URL(string: copy.legalLinkURL) {
                Link(copy.legalLinkLabel, destination: legalURL)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }
}

struct AtmosphereBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        LinearGradient(
            colors: isDark
                ? [Color(red: 0.08, green: 0.09, blue: 0.14), Color(red: 0.12, green: 0.15, blue: 0.22), Color(red: 0.10, green: 0.08, blue: 0.12)]
                : [Color(red: 0.97, green: 0.96, blue: 0.90), Color(red: 0.90, green: 0.95, blue: 0.98), Color(red: 0.96, green: 0.92, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(red: 0.99, green: 0.65, blue: 0.27).opacity(0.18))
                .frame(width: 220, height: 220)
                .offset(x: 60, y: -40)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color(red: 0.21, green: 0.71, blue: 0.88).opacity(0.14))
                .frame(width: 260, height: 260)
                .offset(x: -70, y: 60)
        }
        .ignoresSafeArea()
    }
}
