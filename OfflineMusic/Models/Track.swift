//  OfflineMusic
//  A local offline music player for iPhone.
//  Downloads audio files from URLs you choose, saves them to the device,
//  and plays them back with no internet connection.
//
//  Build with Xcode on macOS:
//    1. Open Package.swift in Xcode (or drag the OfflineMusic folder into Xcode).
//    2. Set the target device to iPhone 8 (or any iOS device).
//    3. Sign with your Apple Developer team.
//    4. Build & run.

import Foundation

/// A track in the user's offline library.
struct Track: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var artist: String?
    var url: URL
    var addedAt: Date
    var localFileName: String?   // set once downloaded
    var isDownloaded: Bool { localFileName != nil }

    init(title: String, artist: String? = nil, url: URL, localFileName: String? = nil) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.url = url
        self.addedAt = Date()
        self.localFileName = localFileName
    }
}

/// A playlist grouping of tracks.
struct Playlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var trackIDs: [UUID]
    var createdAt: Date

    init(name: String, trackIDs: [UUID] = []) {
        self.id = UUID()
        self.name = name
        self.trackIDs = trackIDs
        self.createdAt = Date()
    }
}