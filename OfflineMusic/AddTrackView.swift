import SwiftUI

// MARK: - Add Track manually by URL

struct AddTrackView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var title = ""
    @State private var artist = ""
    @State private var urlText = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bg.ignoresSafeArea()

                Form {
                    Section("Track Info") {
                        TextField("Title", text: $title)
                            .foregroundStyle(AppColor.primaryText)
                        TextField("Artist (optional)", text: $artist)
                            .foregroundStyle(AppColor.primaryText)
                    }

                    Section("MP3 URL") {
                        TextField("https://example.com/song.mp3", text: $urlText)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .textContentType(.URL)
                            .foregroundStyle(AppColor.primaryText)
                        Text("Must be a direct link to an .mp3 file.")
                            .font(.caption)
                            .foregroundStyle(AppColor.mutedText)
                    }

                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(AppColor.error)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add MP3")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { add() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .toolbarBackground(AppColor.bgElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func add() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), !trimmed.isEmpty else {
            errorMessage = "Invalid URL"
            return
        }

        // Strict MP3 enforcement
        guard AudioFormat.isAllowed(url) else {
            errorMessage = "Only .mp3 files are supported."
            return
        }

        let track = library.addTrack(title: title, artist: artist, url: url)
        Task {
            _ = try? await downloadManager.download(track: track, into: library.downloadDirectory())
        }
        dismiss()
    }
}