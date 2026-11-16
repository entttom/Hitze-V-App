import SwiftUI

struct AddWorkplaceView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let copy: Copybook
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var addFailureMessage: DashboardUserMessage?

    var body: some View {
        NavigationStack {
            Form {
                Section(copy.namePlaceholder) {
                    TextField(copy.optionalFieldPlaceholder, text: $viewModel.nameInput)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.next)
                        .onSubmit { isSearchFocused = true }
                }

                Section(copy.addressPlaceholder) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        TextField(copy.cityStreetPlaceholder, text: $viewModel.addressQuery)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .textContentType(.fullStreetAddress)
                            .submitLabel(.search)
                            .focused($isSearchFocused)
                            .onSubmit {
                                Task { await viewModel.searchAddress() }
                            }
                        if viewModel.isSearchingAddress {
                            ProgressView()
                        } else if !viewModel.addressQuery.isEmpty {
                            Button {
                                viewModel.addressQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(copy.clearSearchLabel)
                        }
                    }
                }

                if let message = viewModel.addressSearchMessage {
                    Section {
                        Label(copy.text(for: message), systemImage: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                }

                if !viewModel.addressResults.isEmpty {
                    Section(copy.searchResultsTitle) {
                        ForEach(viewModel.addressResults) { result in
                            AddressResultRow(
                                copy: copy,
                                result: result,
                                isAdding: viewModel.addingResultID == result.id,
                                isDisabled: viewModel.addingResultID != nil
                            ) {
                                add(result)
                            }
                        }
                    }
                }
            }
            .navigationTitle(copy.addWorkplaceTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                    .accessibilityLabel(copy.cancelButton)
                }
            }
            .onAppear {
                viewModel.resetAddWorkplaceForm()
                isSearchFocused = true
            }
            .alert(
                copy.addWorkplaceFailureTitle,
                isPresented: Binding(
                    get: { addFailureMessage != nil },
                    set: { if !$0 { addFailureMessage = nil } }
                ),
                presenting: addFailureMessage
            ) { _ in
                Button(copy.settingsCloseButton, role: .cancel) {}
            } message: { message in
                Text(copy.text(for: message))
            }
        }
    }

    private func add(_ result: AddressSearchResult) {
        isSearchFocused = false
        Task {
            if await viewModel.addWorksite(fromAddressResult: result) {
                dismiss()
            } else if viewModel.addingResultID == nil {
                addFailureMessage = viewModel.addressSearchMessage ?? .workplaceCouldNotBeAdded
            }
        }
    }
}

private struct AddressResultRow: View {
    let copy: Copybook
    let result: AddressSearchResult
    let isAdding: Bool
    let isDisabled: Bool
    let onUse: () -> Void

    var body: some View {
        Button(action: onUse) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    if result.subtitle != result.title {
                        Text(result.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isAdding {
                    ProgressView()
                        .accessibilityLabel(copy.addingWorkplace)
                } else {
                    Label(copy.useAddressButton, systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .disabled(isDisabled)
        .accessibilityElement(children: .combine)
        .accessibilityHint(copy.useAddressButton)
    }
}
