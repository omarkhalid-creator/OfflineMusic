import Foundation

// MARK: - Library persistence
//
// Persists tracks and playlists to `library.json` in the Documents folder.
// Also provides the download directory and a helper to open local files.

final class LibraryManager: ObservableObject {
    static let shared = LibraryManager()

    @Published var tracks: [Track] = []
    @Published var playlists: [Playlist] = []

    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private var libraryURL: URL { documentsURL.appendingPathComponent("library.json") }

    private init() {
        load()
    }

    // MARK: - Tracks

    func addTrack(title: String, artist: String?, url: URL) -> Track {
        var t = Track(title: title, artist: artist, url: url)
        tracks.append(t)
        save()
        return t
    }

    func deleteTrack(_ id: UUID) {
        if let i = tracks.firstIndex(where: { $0.id == id }) {
            if let fn = tracks[i].localFileName {
                try? fileManager.removeItem(at: documentsURL.appendingPathComponent(fn))
            }
            tracks.remove(at: i)
            playlists.indices.forEach { playlists[$0].trackIDs.removeAll { $0 == id } }
            save()
        }
    }

    func updateTrack(_ track: Track) {
        if let i = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks[i] = track
            save()
        }
    }

    // MARK: - Playlists

    func createPlaylist(name: String) {
        playlists.append(Playlist(name: name))
        save()
    }

    func deletePlaylist(_ id: UUID) {
        playlists.removeAll { $0.id == id }
        save()
    }

    func addTrack(_ trackID: UUID, to playlistID: UUID) {
        if let i = playlists.firstIndex(where: { $0.id == playlistID }),
           !playlists[i].trackIDs.contains(trackID) {
            playlists[i].trackIDs.append(trackID)
            save()
        }
    }

    func removeTrack(_ trackID: UUID, from playlistID: UUID) {
        if let i = playlists.firstIndex(where: { $0.id == playlistID }) {
            playlists[i].trackIDs.removeAll { $0 == trackID }
            save()
        }
    }

    // MARK: - File system

    func downloadDirectory() -> URL { documentsURL }

    func localFileURL(for track: Track) -> URL? {
        guard let fn = track.localFileName else { return nil }
        let url = documentsURL.appendingPathComponent(fn)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Persistence

    private func save() {
        let data = try? JSONEncoder().encode(LibraryData(tracks: tracks, playlists: playlists))
        try? data?.write(to: libraryURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: libraryURL),
              let lib = try? JSONDecoder().decode(LibraryData.self, from: data) else { return }
        tracks = lib.tracks
        playlists = lib.playlists
    }
}

private struct LibraryData: Codable {
    let tracks: [Track]
    let playlists: [Playlist]
}