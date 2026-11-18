import Foundation
import AVFoundation
import Combine
import MediaPlayer

// MARK: - Repeat / Shuffle modes
enum RepeatMode: Int { case off, one, all }

/// Central audio player with queue management, background playback,
/// and lock-screen integration via MPNowPlayingInfoCenter.
final class PlayerManager: ObservableObject {
    static let shared = PlayerManager()

    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var repeatMode: RepeatMode = .off
    @Published var isShuffled = false

    private let player = AVPlayer()
    private var queue: [Track] = []
    private var currentIndex = -1
    private var timeObserver: Any?
    private var bag = Set<AnyCancellable>()
    private var nowPlayingInfo: [String: Any] = [:]

    private init() {
        configureAudioSession()
        setupNotifications()
        setupRemoteCommandCenter()
    }

    // MARK: - Audio session & background mode

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    // MARK: - Queue management

    func play(track: Track, in list: [Track]) {
        queue = list
        currentIndex = list.firstIndex(where: { $0.id == track.id }) ?? 0
        playCurrent()
    }

    func playPlaylist(_ playlist: Playlist, startingAt track: Track, library: LibraryManager) {
        let list = playlist.trackIDs.compactMap { id in library.tracks.first { $0.id == id } }
        guard !list.isEmpty else { return }
        play(track: track, in: list)
    }

    func appendToQueue(_ tracks: [Track]) {
        queue.append(contentsOf: tracks)
    }

    // MARK: - Playback controls

    func togglePlay() {
        if isPlaying { player.pause() }
        else { player.play() }
        updateNowPlayingPlaybackState()
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1000)
        player.seek(to: time)
    }

    func next() {
        guard !queue.isEmpty else { return }
        if isShuffled {
            currentIndex = Int.random(in: 0..<queue.count)
        } else if currentIndex < queue.count - 1 {
            currentIndex += 1
        } else if repeatMode == .all {
            currentIndex = 0
        } else {
            return // end of queue
        }
        playCurrent()
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all {
            currentIndex = queue.count - 1
        } else {
            return
        }
        playCurrent()
    }

    private func playCurrent() {
        guard queue.indices.contains(currentIndex) else { return }
        currentTrack = queue[currentIndex]
        guard let track = currentTrack,
              let fn = track.localFileName,
              let url = LibraryManager.shared.downloadDirectory().appendingPathComponent(fn).takeIf({ FileManager.default.fileExists(atPath: $0.path) }) else {
            currentTrack = nil
            return
        }

        let item = AVPlayerItem(url: url)
        player.replaceItem(with: item)
        player.play()
        isPlaying = true

        updateNowPlayingInfo(for: track)
        updateNowPlayingPlaybackState()
    }

    // MARK: - Observers

    private func setupNotifications() {
        timeObserver = player.addPeriodicTimeObserver(for: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] t in
            self?.currentTime = t.seconds
            if let dur = self?.player.currentItem?.duration, dur.isValid && dur.isNumeric {
                self?.duration = dur.seconds
            }
        }

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in self?.handleItemDidFinish() }
            .store(in: &bag)
    }

    private func handleItemDidFinish() {
        isPlaying = false
        if repeatMode == .one {
            player.seek(to: .zero)
            player.play()
            isPlaying = true
            return
        }
        if repeatMode == .all || currentIndex < queue.count - 1 {
            next()
        }
        updateNowPlayingPlaybackState()
    }

    // MARK: - Lock-screen / Control Center integration

    private func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.togglePlay()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlay()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: e.positionTime)
            return .success
        }
    }

    private func updateNowPlayingInfo(for track: Track) {
        guard let library = LibraryManager.shared.downloadDirectory().appendingPathComponent(track.localFileName ?? "").takeIf({ FileManager.default.fileExists(atPath: $0.path) }) else { return }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist ?? "",
            MPMediaItemPropertyPlaybackDuration: max(duration, 0.01),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        // Album art placeholder (could be extended to extract ID3 art)
        // info[MPMediaItemPropertyArtwork] = ...

        nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackState() {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

extension URL { func takeIf(_ condition: (URL) -> Bool) -> URL? { condition(self) ? self : nil } }