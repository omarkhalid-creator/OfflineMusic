import SwiftUI

// MARK: - Full-screen Now Playing sheet

struct PlayerView: View {
    @EnvironmentObject var player: PlayerManager
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Drag handle
                    Capsule()
                        .fill(AppColor.mutedText.opacity(0.4))
                        .frame(width: 36, height: 5)
                        .padding(.top, 12)

                    Spacer()

                    // Album artwork
                    artworkView
                        .frame(width: 280, height: 280)
                        .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
                        .padding(.bottom, 32)

                    // Track info
                    VStack(spacing: 8) {
                        Text(player.currentTrack?.title ?? "No Track")
                            .font(.title).bold()
                            .foregroundStyle(AppColor.primaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text(player.currentTrack?.artist ?? "Unknown Artist")
                            .font(.subheadline)
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // Progress bar
                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { player.currentTime },
                            set: { player.seek(to: $0) }
                        ), in: 0...max(player.duration, 0.01))
                        .tint(AppColor.accent)

                        HStack {
                            Text(format(player.currentTime))
                            Spacer()
                            Text(format(max(player.duration, 0)))
                        }
                        .font(.caption)
                        .foregroundStyle(AppColor.mutedText)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)

                    // Playback controls
                    HStack(spacing: 28) {
                        // Shuffle
                        Button {
                            player.isShuffled.toggle()
                        } label: {
                            Image(systemName: "shuffle")
                                .font(.title3)
                                .foregroundStyle(player.isShuffled ? AppColor.accent : AppColor.mutedText)
                        }

                        // Previous
                        Button {
                            player.previous()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title)
                                .foregroundStyle(AppColor.primaryText)
                        }

                        // Play/Pause (prominent)
                        Button {
                            player.togglePlay()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AppColor.accent)
                                    .frame(width: 64, height: 64)
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title)
                                    .foregroundStyle(AppColor.bg)
                                    .offset(x: player.isPlaying ? 0 : 2)
                            }
                        }

                        // Next
                        Button {
                            player.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title)
                                .foregroundStyle(AppColor.primaryText)
                        }

                        // Repeat
                        Button {
                            player.repeatMode = RepeatMode(rawValue: (player.repeatMode.rawValue + 1) % 3) ?? .off
                        } label: {
                            Image(systemName: repeatIcon)
                                .font(.title3)
                                .foregroundStyle(player.repeatMode == .off ? AppColor.mutedText : AppColor.accent)
                        }
                    }
                    .padding(.bottom, 40)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .foregroundStyle(AppColor.primaryText)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .interactiveDismissDisabled(false)
    }

    private var artworkView: some View {
        Rectangle()
            .fill(AppColor.bgHover)
            .cornerRadius(8)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColor.mutedText)
            )
    }

    private var repeatIcon: String {
        switch player.repeatMode {
        case .off: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }

    private func format(_ seconds: Double) -> String {
        let s = max(Int(seconds), 0)
        return "\(s / 60):\(String(format: "%02d", s % 60))"
    }
}