import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    let copy: Copybook

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(copy.infoScreenHeatMeasuresTitle)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                        Text(copy.infoScreenHeatMeasuresSubtitle)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    infoCard(
                        icon: "2.circle.fill",
                        tint: Color(red: 0.89, green: 0.72, blue: 0.11),
                        title: copy.infoScreenLevel2Title,
                        body: copy.infoScreenLevel2Body
                    )
                }

                Section {
                    infoCard(
                        icon: "3.circle.fill",
                        tint: Color(red: 0.95, green: 0.52, blue: 0.18),
                        title: copy.infoScreenLevel3Title,
                        body: copy.infoScreenLevel3Body
                    )
                }

                Section {
                    infoCard(
                        icon: "4.circle.fill",
                        tint: Color(red: 0.85, green: 0.24, blue: 0.20),
                        title: copy.infoScreenLevel4Title,
                        body: copy.infoScreenLevel4Body
                    )
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(copy.infoScreenUvMeasuresTitle)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                        Text(copy.infoScreenUvMeasuresSubtitle)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    infoCard(
                        icon: "sun.max.fill",
                        tint: Color(red: 0.89, green: 0.72, blue: 0.11),
                        title: copy.infoScreenUvLevel35Title,
                        body: copy.infoScreenUvLevel35Body
                    )
                }

                Section {
                    infoCard(
                        icon: "sun.max.fill",
                        tint: Color(red: 0.95, green: 0.52, blue: 0.18),
                        title: copy.infoScreenUvLevel67Title,
                        body: copy.infoScreenUvLevel67Body
                    )
                }

                Section {
                    infoCard(
                        icon: "sun.max.fill",
                        tint: Color(red: 0.85, green: 0.24, blue: 0.20),
                        title: copy.infoScreenUvLevel810Title,
                        body: copy.infoScreenUvLevel810Body
                    )
                }

                Section {
                    infoCard(
                        icon: "sun.max.fill",
                        tint: Color(red: 0.42, green: 0.45, blue: 0.50),
                        title: copy.infoScreenUvLevel11Title,
                        body: copy.infoScreenUvLevel11Body
                    )
                }
            }
            .listStyle(.insetGrouped)
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
        }
    }

    @ViewBuilder
    private func infoCard(icon: String, tint: Color, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(tint)

            Text(body)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    InfoView(copy: Copybook(language: .de))
}
