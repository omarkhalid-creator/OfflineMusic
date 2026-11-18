import Foundation
import Combine

// MARK: - Download state
enum DownloadState {
    case idle
    case downloading(progress: Double)   // 0.0 ... 1.0
    case completed
    case failed(String)
}

/// Downloads MP3 files from a URL, saves to the app's Documents folder,
/// and publishes progress for the UI.
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var states: [UUID: DownloadState] = [:]

    private let session: URLSession
    private var tasks: [UUID: URLSessionDownloadTask] = [:]
    private var delegates: [UUID: DownloadDelegate] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.sessionSendsEvents = true
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 60
        session = URLSession(configuration: config)
    }

    /// Starts a download for the given track.
    /// - Parameters:
    ///   - track: the Track to download (must have an .mp3 URL)
    ///   - directory: destination directory (usually Documents)
    /// - Returns: a publisher emitting the updated track on success.
    func download(track: Track, into directory: URL) -> AnyPublisher<Track, Error> {
        // Enforce MP3 extension before starting
        guard AudioFormat.isAllowed(track.url) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        let id = track.id
        states[id] = .downloading(progress: 0)

        return Future<Track, Error> { [weak self] promise in
            guard let self else { return }

            let delegate = DownloadDelegate { progress in
                DispatchQueue.main.async { self.states[id] = .downloading(progress: progress) }
            } completion: { result in
                switch result {
                case .success(let url):
                    do {
                        let fileName = Self.sanitizedFileName(for: track, url: url)
                        let dest = directory.appendingPathComponent(fileName)
                        if FileManager.default.fileExists(atPath: dest.path) {
                            try FileManager.default.removeItem(at: dest)
                        }
                        try FileManager.default.moveItem(at: url, to: dest)
                        var t = track
                        t.localFileName = fileName
                        DispatchQueue.main.async {
                            self.states[id] = .completed
                            promise(.success(t))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.states[id] = .failed(error.localizedDescription)
                            promise(.failure(error))
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.states[id] = .failed(error.localizedDescription)
                        promise(.failure(error))
                    }
                }
            }

            let task = self.session.downloadTask(with: track.url)
            task.taskDescription = id.uuidString
            self.delegates[id] = delegate
            self.tasks[id] = task
            self.session.addDelegate(delegate, for: task)
            task.resume()
        }
        .eraseToAnyPublisher()
    }

    func cancel(_ id: UUID) {
        tasks[id]?.cancel()
        states[id] = .idle
    }

    /// Builds a safe, unique filename for the downloaded MP3.
    static func sanitizedFileName(for track: Track, url: URL) -> String {
        let base = track.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (url.lastPathComponent as NSString).deletingPathExtension
            : track.title
        let safe = base
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
        let ext = AudioFormat.mp3.rawValue
        return "\(safe).\(ext)"
    }
}

// MARK: - Delegate handling progress and completion
private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private let onProgress: (Double) -> Void
    private let completion: (Result<URL, Error>) -> Void
    private var total: Int64 = 0

    init(onProgress: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        self.onProgress = onProgress
        self.completion = completion
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if total == 0 { total = max(totalBytesExpectedToWrite, 1) }
        let p = Double(totalBytesWritten) / Double(total)
        onProgress(min(max(p, 0), 1))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error { completion(.failure(error)); return }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, writeFileAtURL fileURL: URL) {
        completion(.success(fileURL))
    }
}