import SwiftUI

struct PlaylistView: View {
    var playlist: Playlist
    @ObservedObject var library: LibraryManager
    @ObservedObject var player: PlayerManager

    private var tracks: [Track] {
        playlist.trackIDs.compactMap { id in library.tracks.first { $0.id == id } }
    }

    var body: some View {
        Group {
            if tracks.isEmpty {
                ContentUnavailableView {
                    Label("Empty playlist", systemImage: "folder")
                } description: {
                    Text("Add tracks from your library to this playlist.")
                }
            } else {
                List(tracks) { track in
                    Button {
                        player.play(track: track, in: tracks)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(track.title).font(.headline)
                                if let a = track.artist { Text(a).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Image(systemName: track.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                                .foregroundStyle(track.isDownloaded ? .green : .secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(playlist.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Add") {
                    ForEach(library.tracks) { t in
                        if !playlist.trackIDs.contains(t.id) {
                            Button(t.title) {
                                library.addTrack(t.id, to: playlist.id)
                            }
                        }
                    }
                }
            }
        }
    }
}