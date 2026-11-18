import SwiftUI
import WebKit

// MARK: - Browser tab with WKWebView and floating Save MP3 button

struct BrowserTabView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var resolverManager: ResolverManager
    @StateObject private var webViewModel = WebViewModel()

    @State private var showSaveAlert = false
    @State private var saveStatus: SaveStatus = .idle

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bg.ignoresSafeArea()

                // Web view
                WebView(url: $webViewModel.currentURL, webViewModel: webViewModel)
                    .ignoresSafeArea(edges: .bottom)

                // Floating Save MP3 button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        saveButton
                            .padding(.trailing, 16)
                            .padding(.bottom, 100) // above mini-player / tab bar
                    }
                }

                // Save status overlay
                if case .downloading(let progress) = saveStatus {
                    downloadingOverlay(progress)
                }
            }
            .navigationTitle("Browser")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        webViewModel.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(webViewModel.canGoBack ? AppColor.primaryText : AppColor.mutedText)
                    }
                    .disabled(!webViewModel.canGoBack)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        webViewModel.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(webViewModel.canGoForward ? AppColor.primaryText : AppColor.mutedText)
                    }
                    .disabled(!webViewModel.canGoForward)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        webViewModel.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(AppColor.primaryText)
                    }
                }
                ToolbarItem(placement: .principal) {
                    URLBarView(url: $webViewModel.currentURL, onSubmit: { url in webViewModel.navigate(to: url) })
                        .frame(maxWidth: .infinity)
                }
            }
            .toolbarBackground(AppColor.bgElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Save MP3", isPresented: $showSaveAlert) {
                Button("OK") { }
            } message: {
                Text(saveStatus.alertMessage)
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await saveCurrentPage() }
        } label: {
            ZStack {
                Circle()
                    .fill(AppColor.accent)
                    .frame(width: 56, height: 56)
                    .shadow(radius: 8)
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColor.bg)
            }
        }
        .disabled(saveStatus.isDownloading || webViewModel.currentURL == nil)
        .opacity(saveStatus.isDownloading || webViewModel.currentURL == nil ? 0.5 : 1.0)
    }

    private func downloadingOverlay(_ progress: Double) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(AppColor.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resolving & Downloading…")
                            .font(.subheadline).bold().foregroundStyle(AppColor.primaryText)
                        Text("This may take a moment")
                            .font(.caption).foregroundStyle(AppColor.secondaryText)
                    }
                    Spacer()
                }
                ProgressView(value: progress, total: 1)
                    .tint(AppColor.accent)
            }
            .padding(20)
            .background(AppColor.bgElevated)
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: saveStatus)
    }

    private func saveCurrentPage() async {
        guard let url = webViewModel.currentURL else { return }
        await MainActor.run { saveStatus = .downloading(0) }

        do {
            // 1. Resolve the page URL to a direct MP3 stream
            let streamURL = try await resolverManager.resolve(pageURL: url)

            // 2. Create a track entry
            let title = streamURL.deletingPathExtension().lastPathComponent
            let track = library.addTrack(title: title, artist: nil, url: streamURL)

            // 3. Download with progress
            let _ = try await downloadManager.download(track: track, into: library.downloadDirectory())

            await MainActor.run {
                saveStatus = .completed
                showSaveAlert = true
            }
        } catch ResolverError.invalidBaseURL {
            await MainActor.run {
                saveStatus = .failed("Resolver endpoint not configured. Open Settings to set it.")
                showSaveAlert = true
            }
        } catch ResolverError.nonMP3Stream(let detail) {
            await MainActor.run {
                saveStatus = .failed("Resolver did not return an MP3: \(detail)")
                showSaveAlert = true
            }
        } catch {
            await MainActor.run {
                saveStatus = .failed(error.localizedDescription)
                showSaveAlert = true
            }
        }
    }
}

// MARK: - Save status

enum SaveStatus: Equatable {
    case idle
    case downloading(Double)
    case completed
    case failed(String)

    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }

    var alertMessage: String {
        switch self {
        case .idle: return ""
        case .downloading: return "Downloading…"
        case .completed: return "MP3 saved to your library!"
        case .failed(let msg): return "Failed: \(msg)"
        }
    }
}

// MARK: - URL bar in navigation bar

struct URLBarView: View {
    @Binding var url: URL?
    let onSubmit: (URL) -> Void

    @State private var text = ""

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColor.mutedText)
            TextField("Search or enter URL", text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(AppColor.primaryText)
                .autocapitalization(.none)
                .keyboardType(.URL)
                .onSubmit {
                    if let u = URL(string: text.hasPrefix("http") ? text : "https://\(text)") {
                        onSubmit(u)
                    }
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColor.bgHover)
        .cornerRadius(20)
        .onChange(of: url) { newURL in
            text = newURL?.absoluteString ?? ""
        }
    }
}

// MARK: - WKWebView wrapper

final class WebViewModel: ObservableObject {
    @Published var currentURL: URL? = URL(string: "https://archive.org/details/audio")
    @Published var canGoBack = false
    @Published var canGoForward = false
    private var webView: WKWebView?

    func attach(_ webView: WKWebView) {
        self.webView = webView
        updateNavigationState()
    }

    func navigate(to url: URL) {
        let request = URLRequest(url: url)
        webView?.load(request)
    }

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }

    func updateNavigationState() {
        canGoBack = webView?.canGoBack ?? false
        canGoForward = webView?.canGoForward ?? false
        if let url = webView?.url { currentURL = url }
    }
}

struct WebView: UIViewRepresentable {
    @Binding var url: URL?
    @ObservedObject var webViewModel: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        if let url = url {
            webView.load(URLRequest(url: url))
        }
        DispatchQueue.main.async { webViewModel.attach(webView) }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // URL changes are handled by WebViewModel.navigate(to:)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebView

        init(_ parent: WebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.webViewModel.updateNavigationState()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.webViewModel.updateNavigationState()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.webViewModel.updateNavigationState()
        }
    }
}