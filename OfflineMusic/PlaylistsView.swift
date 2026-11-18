import SwiftUI

struct PlaylistsView: View {
    @ObservedObject var library: LibraryManager
    @ObservedObject var player: PlayerManager
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if library.playlists.isEmpty {
                    ContentUnavailableView {
                        Label("No playlists", systemImage: "folder")
                    } description: {
                        Text("Create a playlist to group your tracks.")
                    }
                } else {
                    List(library.playlists) { playlist in
                        NavigationLink {
                            PlaylistView(playlist: playlist, library: library, player: player)
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill").foregroundStyle(.purple)
                                VStack(alignment: .leading) {
                                    Text(playlist.name).font(.headline)
                                    Text("\(playlist.trackIDs.count) tracks").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .navigationTitle("Playlists")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreatePlaylistView(library: library)
            }
        }
    }
}

struct CreatePlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: LibraryManager
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Playlist name", text: $name)
            }
            .navigationTitle("New Playlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        library.createPlaylist(name: name)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}