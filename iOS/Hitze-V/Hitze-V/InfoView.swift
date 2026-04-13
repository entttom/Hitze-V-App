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
                            ("2", copy.infoScreenLevel2Title, Color(red: 0.89, green: 0.72, blue: 0.11)),
                            ("3", copy.infoScreenLevel3Title, Color(red: 0.95, green: 0.52, blue: 0.18)),
                            ("4", copy.infoScreenLevel4Title, Color(red: 0.85, green: 0.24, blue: 0.20))
                        ]
                    )

                    InfoIntroCard(text: copy.infoIntro)

                    InfoSectionCard(
                        section: copy.heatProgramSection,
                        icon: "thermometer.sun.fill",
                        tint: Color(red: 0.95, green: 0.52, blue: 0.18)
                    )

                    InfoSectionCard(
                        section: copy.heatEmergencySection,
                        icon: "cross.case.fill",
                        tint: Color(red: 0.85, green: 0.24, blue: 0.20)
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
                        tint: Color(red: 0.89, green: 0.72, blue: 0.11)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle(copy.infoScreenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(copy.settingsCloseButton) {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

private struct InfoScaleCard: View {
    let title: String
    let entries: [(level: String, title: String, tint: Color)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                        Capsule()
                            .fill(entry.tint.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .frame(height: 8)
                    }
                }
            }

            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                HStack(alignment: .center, spacing: 14) {
                    Text(entry.level)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [entry.tint, entry.tint.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .shadow(color: entry.tint.opacity(0.28), radius: 10, x: 0, y: 4)

                    Text(entry.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(entry.tint.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(entry.tint.opacity(0.18), lineWidth: 1)
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(uiColor: .secondarySystemGroupedBackground),
                            Color(uiColor: .secondarySystemGroupedBackground).opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct InfoIntroCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.body, design: .rounded).weight(.medium))
            .foregroundStyle(.primary)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.95, blue: 0.88),
                                Color(red: 0.98, green: 0.90, blue: 0.80)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)

                Text(section.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
            }

            ForEach(Array(section.groups.enumerated()), id: \.offset) { index, group in
                VStack(alignment: .leading, spacing: 10) {
                    Text(group.title)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(tint)

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
                    .padding(.top, 6)

                Text(bullet.text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let cta = bullet.cta {
                Link(destination: cta.url) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text(cta.label)
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(tint, in: Capsule())
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
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 42, height: 42)
                .background(Color(red: 0.24, green: 0.68, blue: 0.89), in: Circle())

            Text(label)
                .font(.system(.headline, design: .rounded).weight(.bold))
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
