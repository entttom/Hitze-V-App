import SwiftUI
import MapKit

struct AddWorkplaceView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let copy: Copybook
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    private var buttonBackground: LinearGradient {
        LinearGradient(
            colors: (viewModel.addressQuery.isEmpty || viewModel.isSearchingAddress)
                ? [Color.gray.opacity(0.4), Color.gray.opacity(0.3)]
                : [Color(red: 0.14, green: 0.66, blue: 0.86), Color(red: 0.10, green: 0.56, blue: 0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Header / Input Section
                        VStack(spacing: 20) {
                            nameInputSection
                            addressInputSection
                            searchButton
                        }
                        .padding(20)
                        
                        // Messages & Loading state
                        if let addressSearchMessage = viewModel.addressSearchMessage,
                           !addressSearchMessage.isEmpty {
                            Label(addressSearchMessage, systemImage: "info.circle.fill")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                                .transition(.opacity)
                        }

                        // Results Section
                        resultsSection
                    }
                    .padding(.bottom, 40)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.addressResults.isEmpty)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isSearchingAddress)
                }
            }
            .navigationTitle(copy.addWorkplaceTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(copy.cancelButton) {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.medium))
                }
            }
            .onTapGesture {
                isSearchFocused = false
            }
            .onAppear {
                // Focus after sheet presentation animation so keyboard appears reliably.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isSearchFocused = true
                }
            }
        }
    }

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(copy.namePlaceholder)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField(copy.t("Optional", "Optional"), text: $viewModel.nameInput)
                    .font(.system(.body, design: .rounded))
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    private var addressInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(copy.addressPlaceholder)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(isSearchFocused ? Color(red: 0.14, green: 0.66, blue: 0.86) : Color.primary.opacity(0.3))
                    .font(.system(size: 16, weight: .medium))
                
                TextField(copy.t("Stadt, Straße...", "City, Street..."), text: $viewModel.addressQuery)
                    .font(.system(.body, design: .rounded))
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .onSubmit {
                        Task {
                            await viewModel.searchAddress()
                        }
                    }
                
                if !viewModel.addressQuery.isEmpty {
                    Button {
                        viewModel.addressQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSearchFocused ? Color(red: 0.14, green: 0.66, blue: 0.86).opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchFocused)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.addressQuery.isEmpty)
        }
    }

    private var searchButton: some View {
        Button {
            isSearchFocused = false
            Task {
                await viewModel.searchAddress()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSearchingAddress {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.title3)
                }
                Text(copy.searchAddressButton)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(buttonBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: (viewModel.addressQuery.isEmpty || viewModel.isSearchingAddress) ? .clear : Color(red: 0.14, green: 0.66, blue: 0.86).opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(viewModel.isSearchingAddress || viewModel.addressQuery.isEmpty)
        .padding(.top, 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.addressQuery.isEmpty)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isSearchingAddress)
    }

    @ViewBuilder
    private var resultsSection: some View {
        if !viewModel.addressResults.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(copy.searchResultsTitle)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                
                VStack(spacing: 12) {
                    ForEach(viewModel.addressResults) { result in
                        AddressResultRow(copy: copy, result: result) {
                            Task {
                                await viewModel.addWorksite(fromAddressResult: result)
                                dismiss()
                            }
                        }
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 20)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
