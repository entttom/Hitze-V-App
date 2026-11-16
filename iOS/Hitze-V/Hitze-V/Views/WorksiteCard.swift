import SwiftUI

struct WorksiteCard: View {
    let copy: Copybook
    let worksite: Worksite
    let snapshot: WorksiteSnapshot?
    let loadState: WorksiteLoadState
    let isHighlighted: Bool
    let onRetry: () -> Void
    let onDelete: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isShowingDeleteConfirmation = false

    private var severity: HazardSeverity { snapshot?.severity ?? .none }
    private var isWarning: Bool { severity.isHeatWarning }
    private var titleColor: Color { isWarning ? severity.onFill : .primary }
    private var detailColor: Color { isWarning ? severity.onFill.opacity(0.85) : .secondary }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    private var showsUvBadge: Bool {
        (snapshot?.uvIndex ?? 0) >= DashboardViewModel.uvWarningThreshold
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            summary
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilitySummary)
                .accessibilityAction(named: copy.deleteWorkplace) {
                    isShowingDeleteConfirmation = true
                }

            if let snapshot, !snapshot.forecasts.isEmpty {
                ForecastStrip(forecasts: snapshot.forecasts, copy: copy)
                warningTimes(snapshot.forecasts)
            }

            if loadState == .failed {
                Button(action: onRetry) {
                    Label(copy.retryButton, systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(isWarning ? severity.onFill : .accentColor)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isWarning {
                shape.fill(severity.fill)
            } else {
                shape.fill(.regularMaterial)
            }
        }
        .overlay {
            shape.strokeBorder(
                isHighlighted ? Color.accentColor : Color.primary.opacity(0.08),
                lineWidth: isHighlighted ? 3 : 1
            )
        }
        .contentShape(.contextMenuPreview, shape)
        .contextMenu {
            Button(copy.deleteWorkplace, systemImage: "trash", role: .destructive) {
                isShowingDeleteConfirmation = true
            }
        }
        .confirmationDialog(
            copy.deleteWorkplace,
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(copy.deleteWorkplace, role: .destructive, action: onDelete)
            Button(copy.cancelButton, role: .cancel) {}
        } message: {
            Text(copy.deleteWorkplaceMessage(worksite.name))
        }
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 8) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 12))

            layout {
                if isWarning {
                    Image(systemName: severity.symbol)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(severity.onFill)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(worksite.name)
                        .font(.headline)
                        .foregroundStyle(titleColor)
                        .fixedSize(horizontal: false, vertical: true)
                    if let address = worksite.address, !address.isEmpty {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(detailColor)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if snapshot != nil {
                    facts
                }
            }

            statusLine
        }
    }

    private var facts: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 6) {
            Label(copy.uvText(snapshot?.uvIndex), systemImage: "sun.max")
            Label(copy.temperature(snapshot?.apparentTemperature), systemImage: "thermometer.medium")
            if showsUvBadge {
                Text(copy.uvWarningBadge5Plus)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DashboardPalette.uvBadgeFill, in: Capsule())
            }
        }
        .font(.caption)
        .foregroundStyle(detailColor)
    }

    @ViewBuilder
    private var statusLine: some View {
        HStack(spacing: 6) {
            switch loadState {
            case .loading where snapshot == nil:
                ProgressView().controlSize(.small)
                Text(copy.loading)
            case .failed:
                Image(systemName: "exclamationmark.icloud")
                Text(snapshot == nil ? copy.loadFailed : copy.notUpToDate)
            default:
                EmptyView()
            }
            if let snapshot {
                Text(snapshot.municipalityName ?? copy.municipalityFallback(snapshot.municipalityID))
                if isWarning {
                    Text("·")
                    Text(copy.levelShort(severity.level)).bold()
                }
            }
        }
        .font(.caption)
        .foregroundStyle(detailColor)
    }

    @ViewBuilder
    private func warningTimes(_ forecasts: [DailyForecast]) -> some View {
        let lines = forecasts.compactMap { forecast -> String? in
            guard let text = warningTimeText(for: forecast) else { return nil }
            return "\(copy.dayLabel(forecast.date)): \(text)"
        }
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines, id: \.self) { line in
                    Label(line, systemImage: "clock")
                }
            }
            .font(.caption)
            .foregroundStyle(detailColor)
        }
    }

    private func warningTimeText(for forecast: DailyForecast) -> String? {
        guard !forecast.warningTimeRanges.isEmpty,
              let nextDay = ViennaTime.calendar.date(byAdding: .day, value: 1, to: forecast.date) else {
            return nil
        }
        let level = " (\(copy.levelShort(forecast.severity.level)))"
        return forecast.warningTimeRanges
            .map { range in
                if range.start <= forecast.date && range.end >= nextDay {
                    return copy.warningAllDay + level
                }
                let end = range.end >= nextDay ? "24:00" : copy.time(range.end)
                return "\(copy.time(range.start))–\(end)" + level
            }
            .joined(separator: " · ")
    }

    private var accessibilitySummary: String {
        var parts = [worksite.name]
        if let address = worksite.address, !address.isEmpty {
            parts.append(address)
        }
        switch loadState {
        case .loading where snapshot == nil:
            parts.append(copy.loading)
        case .failed:
            parts.append(snapshot == nil ? copy.loadFailed : copy.notUpToDate)
        default:
            break
        }
        if let snapshot {
            parts.append(copy.severityDescription(snapshot.severity))
            parts.append("\(copy.uvAccessibilityLabel): \(copy.spokenUV(snapshot.uvIndex))")
            parts.append("\(copy.apparentAccessibilityLabel): \(copy.spokenTemperature(snapshot.apparentTemperature))")
            parts.append(snapshot.municipalityName ?? copy.municipalityFallback(snapshot.municipalityID))
        }
        return parts.joined(separator: ", ")
    }
}

/// One pill per forecast day; a Grid at accessibility sizes so pills wrap instead of squeezing.
struct ForecastStrip: View {
    let forecasts: [DailyForecast]
    let copy: Copybook

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(Array(stride(from: 0, to: forecasts.count, by: 2)), id: \.self) { index in
                        GridRow {
                            ForecastPill(forecast: forecasts[index], copy: copy)
                            if index + 1 < forecasts.count {
                                ForecastPill(forecast: forecasts[index + 1], copy: copy)
                            } else {
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                            }
                        }
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(forecasts) { forecast in
                        ForecastPill(forecast: forecast, copy: copy)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .contain)
    }
}

struct ForecastPill: View {
    let forecast: DailyForecast
    let copy: Copybook

    private var severity: HazardSeverity { forecast.severity }

    var body: some View {
        VStack(spacing: 4) {
            Text(copy.dayLabel(forecast.date))
                .font(.caption.weight(.bold))
            if severity.isHeatWarning {
                Label("\(severity.level)", systemImage: severity.symbol)
                    .labelStyle(.titleAndIcon)
                    .font(.caption.weight(.heavy))
            }
            Text(forecast.apparentTemperatureMax.map { copy.temperature($0, fractionDigits: 0) } ?? copy.notAvailableShort)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(severity.isHeatWarning ? severity.onFill : .primary)
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(
            severity.isHeatWarning ? severity.fill : Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(severity.isHeatWarning ? severity.onFill.opacity(0.45) : Color.primary.opacity(0.12), lineWidth: severity.isHeatWarning ? 1.5 : 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(copy.dayLabel(forecast.date)): \(copy.severityDescription(severity)), \(copy.apparentAccessibilityLabel): \(copy.spokenTemperature(forecast.apparentTemperatureMax))"
        )
    }
}
