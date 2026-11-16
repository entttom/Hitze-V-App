import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss

    let copy: Copybook

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader(copy.infoScreenHeatMeasuresTitle)

                    InfoScaleCard(
                        title: copy.infoScreenHeatScaleTitle,
                        entries: [
                            (.heatYellow, copy.infoScreenLevel2Title),
                            (.heatOrange, copy.infoScreenLevel3Title),
                            (.heatRed, copy.infoScreenLevel4Title)
                        ],
                        copy: copy
                    )

                    InfoIntroCard(text: copy.infoIntro)

                    InfoSectionCard(
                        section: copy.heatProgramSection,
                        icon: "thermometer.sun.fill",
                        tint: HazardSeverity.heatOrange.iconTint
                    )

                    InfoSectionCard(
                        section: copy.heatEmergencySection,
                        icon: "cross.case.fill",
                        tint: HazardSeverity.heatRed.iconTint
                    )

                    if let checklist = copy.optionalChecklistCta {
                        Link(destination: checklist.url) {
                            InfoChecklistCard(label: checklist.label)
                        }
                        .buttonStyle(.plain)
                    }

                    sectionHeader(copy.infoScreenUvMeasuresTitle)

                    InfoSectionCard(
                        section: copy.uvSection,
                        icon: "sun.max.fill",
                        tint: DashboardPalette.uvIcon
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(copy.infoScreenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                    .accessibilityLabel(copy.settingsCloseButton)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct InfoScaleCard: View {
    let title: String
    let entries: [(severity: HazardSeverity, title: String)]
    let copy: Copybook

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                        Capsule()
                            .fill(entry.severity.fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 8)
                    }
                }
                .accessibilityHidden(true)
            }

            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                HStack(alignment: .center, spacing: 14) {
                    VStack(spacing: 2) {
                        Image(systemName: entry.severity.symbol)
                            .font(.caption.weight(.bold))
                        Text("\(entry.severity.level)")
                            .font(.headline.weight(.black))
                    }
                    .foregroundStyle(entry.severity.onFill)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(entry.severity.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text(entry.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(entry.severity.fill.opacity(0.12))
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(copy.severityDescription(entry.severity)): \(entry.title)")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

private struct InfoIntroCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body.weight(.medium))
            .foregroundStyle(.primary)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(HazardSeverity.heatOrange.fill.opacity(0.14))
                    }
            )
    }
}

private struct InfoSectionCard: View {
    let section: Copybook.InfoSection
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                Text(section.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            ForEach(Array(section.groups.enumerated()), id: \.offset) { index, group in
                VStack(alignment: .leading, spacing: 10) {
                    Text(group.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)

                    if group.bullets.isEmpty {
                        EmptyView()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(group.bullets.enumerated()), id: \.offset) { _, bullet in
                                BulletRow(bullet: bullet, tint: tint)
                            }
                        }
                    }
                }

                if index < section.groups.count - 1 {
                    Divider()
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct BulletRow: View {
    let bullet: Copybook.InfoBullet
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(tint)
                    .frame(width: 7, height: 7)
                    .padding(.top, 7)
                    .accessibilityHidden(true)

                Text(bullet.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let cta = bullet.cta {
                Link(destination: cta.url) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                        Text(cta.label)
                    }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(HazardSeverity.heatRed.fill, in: Capsule())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

private struct InfoChecklistCard: View {
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.right.square.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.white)
                .frame(width: 42, height: 42)
                .background(Color(red: 0.24, green: 0.68, blue: 0.89), in: Circle())

            Text(label)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    InfoView(copy: Copybook(language: .de))
}
