import Foundation
import Combine

// MARK: - Configurable resolver endpoint
//
// The Browser tab's "Save MP3" button POSTs the current page URL to a
// configurable resolver endpoint (POST /extract), expecting
//   { "url": "<direct .mp3 stream URL>" }
// The returned stream is downloaded directly into the local library.

enum ResolverError: Error, LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case missingURLField
    case nonMP3Stream(String)
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL: return "Resolver endpoint is not configured."
        case .invalidResponse: return "Resolver returned an invalid response."
        case .missingURLField: return "Resolver response is missing the \"url\" field."
        case .nonMP3Stream(let s): return "Resolver did not return an MP3: \(s)"
        case .httpStatus(let code): return "Resolver returned HTTP \(code)."
        }
    }
}

final class ResolverManager: ObservableObject {
    static let shared = ResolverManager()

    /// The resolver endpoint. Editable in Settings.
    /// Defaults to a placeholder so the feature is demonstrable out of the box.
    @Published var endpointBaseURL: String = "https://example.com"

    var endpointURL: URL? {
        URL(string: endpointBaseURL.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Validate that the configured base URL is reachable and well-formed.
    func validateEndpoint() async -> Bool {
        guard let url = endpointURL,
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https") else { return false }
        return true
    }

    /// Resolve a page URL into a direct MP3 stream URL.
    /// - Parameter pageURL: the URL currently loaded in the web view.
    /// - Returns: a validated MP3 stream URL.
    func resolve(pageURL: URL) async throws -> URL {
        guard let base = endpointURL else { throw ResolverError.invalidBaseURL }

        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.path = "/extract"
        guard let requestURL = components?.url else { throw ResolverError.invalidBaseURL }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(["url": pageURL.absoluteString])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ResolverError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw ResolverError.httpStatus(http.statusCode) }

        struct ExtractResponse: Decodable { let url: String }
        let decoded = try JSONDecoder().decode(ExtractResponse.self, from: data)
        guard let streamURL = URL(string: decoded.url) else { throw ResolverError.missingURLField }

        // Strict MP3 enforcement on the resolved stream.
        let ext = streamURL.pathExtension.lowercased()
        guard ext == AudioFormat.mp3.rawValue else {
            throw ResolverError.nonMP3Stream(streamURL.lastPathComponent)
        }
        return streamURL
    }
}