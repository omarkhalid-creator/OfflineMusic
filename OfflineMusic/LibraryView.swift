import SwiftUI

struct LibraryView: View {
    @ObservedObject var library: LibraryManager
    @ObservedObject var player: PlayerManager

    var body: some View {
        Group {
            if library.tracks.isEmpty {
                ContentUnavailableView {
                    Label("No tracks yet", systemImage: "music.note")
                } description: {
                    Text("Tap + to add an audio file by URL.")
                }
            } else {
                List(library.tracks) { track in
                    Button {
                        player.play(track: track, in: library.tracks)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title).font(.headline)
                                if let a = track.artist { Text(a).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            statusIcon(track)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            library.deleteTrack(track.id)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func statusIcon(_ track: Track) -> some View {
        switch DownloadManager.shared.states[track.id] {
        case .downloading(let p):
            HStack(spacing: 6) {
                ProgressView(value: p, total: 1)
                Text("\(Int(p * 100))%").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(width: 70)
        case .completed, .none where track.isDownloaded:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        case .idle, .none:
            Image(systemName: "arrow.down.circle").foregroundStyle(.secondary)
        }
    }
}