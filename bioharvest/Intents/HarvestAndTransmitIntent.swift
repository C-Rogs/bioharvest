import AppIntents
import Foundation

struct HarvestAndTransmitIntent: AppIntent {
    static var title: LocalizedStringResource = "Harvest and Transmit"
    static var description = IntentDescription(
        "Fetches the last 7 days of Health data and sends it to your configured webhook."
    )
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let webhookURL = UserDefaults.standard.string(forKey: BioharvestStorage.webhookURLKey) ?? ""
        let trimmedURL = webhookURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            throw HarvestIntentError.missingWebhook
        }

        let window = ExportWindow.preset(.lastWeek)
        let inclusion = MetricInclusion.load()
        let (payload, data) = try await BioharvestExportPipeline.shared.buildPayload(
            window: window,
            inclusion: inclusion,
            encoding: .compact
        )

        switch await WebhookTransmitter.post(json: data, to: trimmedURL) {
        case .success:
            return .result(
                dialog: "Sent \(payload.logs.count) days of health data to your webhook."
            )
        case .failure(let error):
            throw HarvestIntentError.transmissionFailed(error.localizedDescription)
        }
    }
}

enum HarvestIntentError: LocalizedError {
    case missingWebhook
    case transmissionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingWebhook:
            return "No webhook URL configured. Open bioharvest and add one in Settings."
        case .transmissionFailed(let message):
            return message
        }
    }
}

struct BioharvestShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: HarvestAndTransmitIntent(),
            phrases: [
                "Harvest health data with \(.applicationName)",
                "Transmit health data with \(.applicationName)",
                "Send my health data with \(.applicationName)"
            ],
            shortTitle: "Harvest and Transmit",
            systemImageName: "heart.text.square"
        )
    }
}
