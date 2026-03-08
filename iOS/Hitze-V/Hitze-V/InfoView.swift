import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    let copy: Copybook
    private typealias LevelEntry = (tint: Color, title: String)

    private var heatEntries: [LevelEntry] {
        [
            (Color(red: 0.89, green: 0.72, blue: 0.11), copy.infoScreenLevel2Title),
            (Color(red: 0.95, green: 0.52, blue: 0.18), copy.infoScreenLevel3Title),
            (Color(red: 0.85, green: 0.24, blue: 0.20), copy.infoScreenLevel4Title)
        ]
    }

    private var uvEntries: [LevelEntry] {
        [
            (Color(red: 0.89, green: 0.72, blue: 0.11), copy.infoScreenUvLevel35Title),
            (Color(red: 0.95, green: 0.52, blue: 0.18), copy.infoScreenUvLevel67Title),
            (Color(red: 0.85, green: 0.24, blue: 0.20), copy.infoScreenUvLevel810Title),
            (Color(red: 0.42, green: 0.45, blue: 0.50), copy.infoScreenUvLevel11Title)
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    levelGroupCard(icon: "thermometer.sun.fill", entries: heatEntries)
                } header: {
                    sectionHeader(copy.infoScreenHeatMeasuresTitle)
                }

                Section {
                    levelGroupCard(icon: "sun.max.fill", entries: uvEntries)
                } header: {
                    sectionHeader(copy.infoScreenUvMeasuresTitle)
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
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.headline, design: .rounded).weight(.bold))
    }

    @ViewBuilder
    private func levelGroupCard(icon: String, entries: [LevelEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(entry.tint)
                        .frame(width: 18, alignment: .center)

                    Text(entry.title)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(entry.tint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if index < entries.count - 1 {
                    Divider()
                        .padding(.leading, 28)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    InfoView(copy: Copybook(language: .de))
}
