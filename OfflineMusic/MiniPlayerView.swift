import SwiftUI

// MARK: - Persistent floating Mini-Player above tab bar

struct MiniPlayerView: View {
    @EnvironmentObject var player: PlayerManager
    @State private var showFullPlayer = false

    var body: some View {
        if let track = player.currentTrack {
            Button {
                showFullPlayer = true
            } label: {
                HStack(spacing: 12) {
                    // Artwork placeholder
                    Rectangle()
                        .fill(AppColor.bgHover)
                        .frame(width: 56, height: 56)
                        .cornerRadius(6)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundStyle(AppColor.mutedText)
                        )

                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.subheadline).bold()
                            .foregroundStyle(AppColor.primaryText)
                            .lineLimit(1)
                        Text(track.artist ?? "Unknown")
                            .font(.caption)
                            .foregroundStyle(AppColor.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Play/Pause
                    Button {
                        player.togglePlay()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundStyle(AppColor.primaryText)
                    }
                    .buttonStyle(.plain)

                    // Next
                    Button {
                        player.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColor.bgElevated)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: -2)
                )
                .padding(.horizontal, 12)
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showFullPlayer) {
                PlayerView()
            }
        }
    }
}