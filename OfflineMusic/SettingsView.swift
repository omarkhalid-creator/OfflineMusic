import SwiftUI

// MARK: - Settings: resolver endpoint, about, etc.

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var resolverManager: ResolverManager
    @State private var endpointText = ""
    @State private var showValidation = false
    @State private var validationResult: Bool?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bg.ignoresSafeArea()

                Form {
                    Section("Resolver Endpoint") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The Browser tab uses a resolver to extract direct MP3 URLs from web pages.")
                                .font(.caption)
                                .foregroundStyle(AppColor.secondaryText)

                            TextField("https://your-resolver.example.com", text: $endpointText)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .textContentType(.URL)
                                .foregroundStyle(AppColor.primaryText)

                            Button("Validate") {
                                Task { await validate() }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColor.accent)
                            .disabled(endpointText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            if let result = validationResult {
                                HStack(spacing: 6) {
                                    Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(result ? AppColor.success : AppColor.error)
                                    Text(result ? "Endpoint reachable" : "Endpoint unreachable or invalid")
                                        .font(.caption)
                                        .foregroundStyle(result ? AppColor.success : AppColor.error)
                                }
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        Link("How to set up a resolver", destination: URL(string: "https://github.com/your/repo/wiki/Resolver")!)
                            .foregroundStyle(AppColor.accent)
                    }

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0").foregroundStyle(AppColor.secondaryText)
                        }
                        HStack {
                            Text("Build")
                            Spacer()
                            Text("OfflineMusic").foregroundStyle(AppColor.secondaryText)
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            // Could add library reset here
                        } label: {
                            Text("Reset Library").frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .toolbarBackground(AppColor.bgElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                endpointText = resolverManager.endpointBaseURL
            }
        }
    }

    private func validate() async {
        resolverManager.endpointBaseURL = endpointText.trimmingCharacters(in: .whitespacesAndNewlines)
        let ok = await resolverManager.validateEndpoint()
        await MainActor.run {
            validationResult = ok
        }
    }
}