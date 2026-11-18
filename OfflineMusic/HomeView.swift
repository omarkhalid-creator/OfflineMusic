import SwiftUI

// MARK: - Root view with bottom tab bar and persistent mini-player

struct HomeView: View {
    @StateObject var library = LibraryManager.shared
    @StateObject var player = PlayerManager.shared
    @StateObject var downloadManager = DownloadManager.shared
    @StateObject var resolverManager = ResolverManager.shared

    @State private var selectedTab = 0
    @State private var showAddTrack = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Background
            AppColor.bg.ignoresSafeArea()

            // Tab content
            TabView(selection: $selectedTab) {
                HomeTabView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)

                BrowserTabView()
                    .tabItem { Label("Browser", systemImage: "safari.fill") }
                    .tag(1)

                LibraryTabView()
                    .tabItem { Label("Library", systemImage: "music.note.list") }
                    .tag(2)
            }
            .tint(AppColor.accent)
            .accentColor(AppColor.accent)
            .toolbarBackground(AppColor.bgElevated, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)

            // Persistent Mini-Player overlay
            if player.currentTrack != nil {
                VStack {
                    Spacer()
                    MiniPlayerView()
                        .padding(.bottom, 49) // tab bar height
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: player.currentTrack != nil)
                }
            }
        }
        .environmentObject(library)
        .environmentObject(player)
        .environmentObject(downloadManager)
        .environmentObject(resolverManager)
        .sheet(isPresented: $showAddTrack) {
            AddTrackView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Tab content views

private struct HomeTabView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var player: PlayerManager
    @State private var showAddTrack = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bg.ignoresSafeArea()

                if library.tracks.isEmpty {
                    ContentUnavailableView {
                        Label("No Music Yet", systemImage: "music.note")
                    } description: {
                        VStack(spacing: 12) {
                            Text("Add your first MP3 to start listening offline.")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppColor.secondaryText)
                            Button("Add MP3") { showAddTrack = true }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColor.accent)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            Section(header: sectionHeader("Recently Added")) {
                                recentlyAddedCarousel()
                            }

                            Section(header: sectionHeader("Your Library")) {
                                ForEach(library.tracks) { track in
                                    TrackRow(track: track)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // space for mini-player
                    }
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppColor.primaryText)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddTrack = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppColor.primaryText)
                    }
                }
            }
            .toolbarBackground(AppColor.bgElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showAddTrack) { AddTrackView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private func recentlyAddedCarousel() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(library.tracks.suffix(5).reversed()) { track in
                    VStack(alignment: .leading, spacing: 8) {
                        Rectangle()
                            .fill(AppColor.bgHover)
                            .frame(width: 160, height: 160)
                            .cornerRadius(8)
                            .overlay(artworkPlaceholder())
                        Text(track.title).font(.headline).lineLimit(1).frame(width: 160)
                        Text(track.artist ?? "Unknown").font(.caption).foregroundStyle(AppColor.secondaryText).lineLimit(1).frame(width: 160)
                    }
                    .onTapGesture { player.play(track: track, in: library.tracks) }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).font(.title3).bold().foregroundStyle(AppColor.primaryText)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColor.bg)
    }

    private func artworkPlaceholder() -> some View {
        Image(systemName: "music.note")
            .font(.system(size: 40))
            .foregroundStyle(AppColor.mutedText)
    }
}

private struct LibraryTabView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var player: PlayerManager

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bg.ignoresSafeArea()

                if library.tracks.isEmpty {
                    ContentUnavailableView {
                        Label("No Tracks", systemImage: "music.note")
                    } description: {
                        Text("Add MP3s from Home or Browser.")
                            .foregroundStyle(AppColor.secondaryText)
                    }
                } else {
                    List {
                        ForEach(library.tracks) { track in
                            TrackRow(track: track)
                                .listRowBackground(AppColor.bgElevated)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            indexSet.map { library.tracks[$0].id }.forEach(library.deleteTrack)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Library")
            .toolbarBackground(AppColor.bgElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Shared track row

struct TrackRow: View {
    let track: Track
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var player: PlayerManager
    @EnvironmentObject var downloadManager: DownloadManager

    var body: some View {
        Button {
            if track.isDownloaded {
                player.play(track: track, in: library.tracks)
            } else {
                Task { _ = try? await downloadManager.download(track: track, into: library.downloadDirectory()) }
            }
        } label: {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(AppColor.bgHover)
                    .frame(width: 56, height: 56)
                    .cornerRadius(8)
                    .overlay(artworkIcon)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(.subheadline).bold().foregroundStyle(AppColor.primaryText).lineLimit(1)
                    Text(track.artist ?? "Unknown").font(.caption).foregroundStyle(AppColor.secondaryText).lineLimit(1)
                }

                Spacer()

                statusView
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var artworkIcon: some View {
        Image(systemName: "music.note")
            .font(.title2)
            .foregroundStyle(AppColor.mutedText)
    }

    @ViewBuilder
    private var statusView: some View {
        switch downloadManager.states[track.id] {
        case .downloading(let p):
            HStack(spacing: 6) {
                ProgressView(value: p, total: 1).frame(width: 40)
                Text("\(Int(p * 100))%").font(.caption2).foregroundStyle(AppColor.secondaryText)
            }
        case .completed, .none where track.isDownloaded:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColor.accent)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppColor.warning)
        case .idle, .none:
            Image(systemName: "arrow.down.circle").foregroundStyle(AppColor.mutedText)
        }
    }
}