import SwiftUI

struct SettingsView: View {
    @AppStorage(BioharvestStorage.webhookURLKey) private var webhookURL: String = ""

    private var isWebhookValid: Bool {
        let trimmed = webhookURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return false }
        return url.scheme == "https" && !trimmed.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: BioharvestTheme.sectionSpacing) {
                settingsHero

                BioharvestCard(title: "Webhook URL", icon: "link", accent: BioharvestTheme.duskTeal) {
                    TextField("https://hook.make.com/…", text: $webhookURL)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))

                    HStack {
                        StatusPill(
                            text: isWebhookValid ? "Connected" : "Not configured",
                            color: isWebhookValid ? .green : .orange
                        )
                        Spacer()
                    }

                    Text(
                        "Paste a webhook URL from Make.com, Zapier, or similar. "
                            + "Health data is sent as JSON when you transmit or run the Shortcut."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                BioharvestCard(title: "About", icon: "info.circle", accent: BioharvestTheme.harvestGreen) {
                    VStack(alignment: .leading, spacing: 10) {
                        aboutRow(icon: "leaf.fill", title: "bioharvest", subtitle: "Health data exporter for Coach")
                        Divider()
                        aboutRow(icon: "doc.text", title: "Schema v2", subtitle: "HRV, sleep, activity, nutrition & more")
                        Divider()
                        aboutRow(icon: "lock.shield", title: "Privacy", subtitle: "Data stays on-device until you export")
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var settingsHero: some View {
        HStack(spacing: 14) {
            Image(systemName: "gearshape.2.fill")
                .font(.largeTitle)
                .foregroundStyle(BioharvestTheme.harvestGreen)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 4) {
                Text("Configuration")
                    .font(.title3.weight(.semibold))
                Text("Connect your automation pipeline")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func aboutRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(BioharvestTheme.harvestGreen)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
