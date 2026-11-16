import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @AppStorage(AppSettingsKey.language, store: .hitzeShared) private var languageRawValue = AppLanguage.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var copy: Copybook {
        Copybook(language: (AppLanguage(rawValue: languageRawValue) ?? .system).resolvedLanguage)
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                DashboardView(viewModel: viewModel, copy: copy)
            } else {
                OnboardingView(copy: copy, mode: .welcome) {
                    await viewModel.requestPermissionFromExplainer()
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
        .onAppear {
            LaunchReadiness.shared.markReady()
        }
        .task {
            await viewModel.refreshPermissionStatus()
        }
    }
}

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let copy: Copybook

    @ObservedObject private var pushRouter = PushRouter.shared
    @ObservedObject private var mockModeController = MockModeController.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isShowingAddWorkplace = false
    @State private var isShowingSettings = false
    @State private var isShowingInfo = false
    @State private var highlightedWorksiteIDs: Set<UUID> = []

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    /// Restored or pre-configured setups skip onboarding but may never have been asked; they get
    /// the same explainer before anything could show the system prompt. Waits for open sheets
    /// (Settings shows its own explainer) so two presentations never compete.
    private var needsPermissionExplainer: Bool {
        viewModel.pushPermission == .notDetermined
            && viewModel.isPushNotificationsEnabled
            && !isShowingSettings && !isShowingAddWorkplace && !isShowingInfo
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    content
                        .frame(maxWidth: isRegularWidth ? 1100 : 640)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background { AtmosphereBackground() }
                .refreshable { await viewModel.refreshAll() }
                .onChange(of: pushRouter.pendingGKZ, initial: true) { _, gkz in
                    guard let gkz else { return }
                    Task { await handleNotificationTap(gkz: gkz, proxy: proxy) }
                }
            }
            .navigationTitle(copy.shortTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $isShowingAddWorkplace) {
                AddWorkplaceView(viewModel: viewModel, copy: copy)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(copy: copy, viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingInfo) {
                InfoView(copy: copy)
            }
        }
        .fullScreenCover(isPresented: Binding(get: { needsPermissionExplainer }, set: { _ in })) {
            OnboardingView(copy: copy, mode: .permissionOnly) {
                await viewModel.requestPermissionFromExplainer()
            }
            .interactiveDismissDisabled()
        }
        .task {
            await viewModel.refreshIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await viewModel.refreshPermissionStatus()
                await viewModel.refreshIfStale()
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(copy.infoButtonLabel, systemImage: "info") {
                isShowingInfo = true
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(copy.settingsTitle, systemImage: "gearshape") {
                isShowingSettings = true
            }
            Button(copy.addWorkplaceButton, systemImage: "plus") {
                isShowingAddWorkplace = true
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let status = viewModel.status
        VStack(spacing: 16) {
            if mockModeController.isEnabled {
                MockModeBanner(copy: copy)
            }

            if viewModel.worksites.isEmpty {
                emptyState
            } else {
                if isRegularWidth {
                    HStack(alignment: .top, spacing: 16) {
                        hero(status)
                        GlanceCard(copy: copy, status: status)
                    }
                } else {
                    hero(status)
                    GlanceCard(copy: copy, status: status)
                }
                worksitesSection
            }

            LegalFooter(copy: copy)
        }
    }

    private func hero(_ status: DashboardStatus) -> some View {
        HeroCard(copy: copy, status: status, worksiteCount: viewModel.worksites.count) {
            Task { await viewModel.refreshAll() }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(copy.noWorkplaces, systemImage: "briefcase")
        } description: {
            Text(copy.noWorkplacesDescription)
        } actions: {
            Button(copy.addWorkplaceButton, systemImage: "plus") {
                isShowingAddWorkplace = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var worksitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(copy.monitoredWorkplacesTitle)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: isRegularWidth
                    ? [GridItem(.adaptive(minimum: 340), spacing: 12, alignment: .top)]
                    : [GridItem(.flexible(), alignment: .top)],
                spacing: 12
            ) {
                ForEach(viewModel.worksites) { worksite in
                    WorksiteCard(
                        copy: copy,
                        worksite: worksite,
                        snapshot: viewModel.snapshots[worksite.id],
                        loadState: viewModel.loadState(for: worksite.id),
                        isHighlighted: highlightedWorksiteIDs.contains(worksite.id),
                        onRetry: { Task { await viewModel.retry(worksiteID: worksite.id) } },
                        onDelete: { Task { await viewModel.deleteWorksite(id: worksite.id) } }
                    )
                    .id(worksite.id)
                }
            }
        }
    }

    private func handleNotificationTap(gkz: String, proxy: ScrollViewProxy) async {
        pushRouter.pendingGKZ = nil
        isShowingAddWorkplace = false
        isShowingSettings = false
        isShowingInfo = false

        var ids = viewModel.worksiteIDs(forMunicipalityID: gkz)
        if ids.isEmpty {
            // Worksites stored by older versions learn their GKZ on the next fetch.
            await viewModel.refreshAll()
            ids = viewModel.worksiteIDs(forMunicipalityID: gkz)
        } else {
            Task { await viewModel.refreshAll() }
        }
        guard let first = viewModel.worksites.first(where: { ids.contains($0.id) })?.id else { return }

        withAnimation {
            proxy.scrollTo(first, anchor: .center)
            highlightedWorksiteIDs = Set(ids)
        }
        try? await Task.sleep(for: .seconds(2.5))
        withAnimation {
            highlightedWorksiteIDs = []
        }
    }
}

#Preview {
    ContentView()
}
