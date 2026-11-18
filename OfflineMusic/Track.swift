import Foundation

// MARK: - Format enforcement
//
// This app is strictly an MP3 player. Any URL that does not resolve to an
// `.mp3` file is rejected before a download is started.

enum AudioFormat: String {
    case mp3 = "mp3"

    static let allowedExtensions: [String] = [AudioFormat.mp3.rawValue]
    static let allowedMimeTypes: [String] = [
        "audio/mpeg",
        "audio/mp3",
        "audio/x-mpeg",
        "audio/mpeg3"
    ]

    static func isAllowed(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if AudioFormat.allowedExtensions.contains(ext) { return true }
        // Fallback: some hosts serve MP3s without an extension.
        let last = url.lastPathComponent.lowercased()
        if last.isEmpty || last == "/" { return false }
        return false
    }

    static func isAllowed(mimeType: String) -> Bool {
        AudioFormat.allowedMimeTypes.contains(mimeType.lowercased())
    }
}

/// A track in the user's offline library.
struct Track: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var artist: String?
    var url: URL
    var addedAt: Date
    var localFileName: String?
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

/// Result of validating a candidate URL for import.
enum ImportValidation {
    case valid
    case invalidExtension(String)   // human-readable reason
    case unreachable(String)
}