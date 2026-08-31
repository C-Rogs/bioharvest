import Foundation
import UIKit

enum FeedbackTransmitter {
    static let webhookURL =
        "https://hook.eu1.make.com/k6qk9fynxciox2gxf8ych7k8quvekpre"

    struct Payload: Encodable {
        let type = "feedback"
        let note: String
        let appVersion: String
        let build: String
        let ios: String
        let device: String
        let timestamp: String

        enum CodingKeys: String, CodingKey {
            case type, note
            case appVersion = "app_version"
            case build, ios, device, timestamp
        }
    }

    static func send(note: String) async -> Result<Void, WebhookError> {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let payload = Payload(
            note: trimmed,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            build: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            ios: UIDevice.current.systemVersion,
            device: deviceModelIdentifier(),
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        let encoder = JSONEncoder()
        ExportJSONEncoding.compact.configure(encoder)

        guard let data = try? encoder.encode(payload) else {
            return .failure(.invalidURL)
        }

        return await WebhookTransmitter.post(json: data, to: webhookURL)
    }

    private static func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? UIDevice.current.model
            }
        }
    }
}
