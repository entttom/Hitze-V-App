import SwiftUI
import MapKit

struct AddWorkplaceView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let copy: Copybook
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                textField(copy.namePlaceholder, text: $viewModel.nameInput)
                
                textField(copy.addressPlaceholder, text: $viewModel.addressQuery)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    .onSubmit {
                        Task {
                            await viewModel.searchAddress()
                        }
                    }

                Button {
                    Task {
                        await viewModel.searchAddress()
                    }
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass.circle.fill")
                        Text(copy.searchAddressButton)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.14, green: 0.66, blue: 0.86), Color(red: 0.10, green: 0.56, blue: 0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
                .disabled(viewModel.isSearchingAddress)

                if viewModel.isSearchingAddress {
                    Label(copy.searchingAddress, systemImage: "hourglass")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if let addressSearchMessage = viewModel.addressSearchMessage,
                   !addressSearchMessage.isEmpty {
                    Label(addressSearchMessage, systemImage: "info.circle.fill")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if !viewModel.addressResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(copy.searchResultsTitle)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(.secondary)

                        ForEach(viewModel.addressResults) { result in
                            AddressResultRow(copy: copy, result: result) {
                                Task {
                                    await viewModel.addWorksite(fromAddressResult: result)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(18)
            .navigationTitle(copy.addWorkplaceTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { // Need to update Copybook for this later or use a generic close
                        dismiss()
                    }
                }
            }
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
}
