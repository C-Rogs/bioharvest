import Foundation
import UIKit

enum TransmissionStatus: Equatable {
    case idle
    case transmitting
    case success
    case failed(String)

    var displayText: String? {
        switch self {
        case .idle:
            return nil
        case .transmitting:
            return "Transmitting…"
        case .success:
            return "Transmission Successful"
        case .failed(let message):
            return "Failed: \(message)"
        }
    }
}

enum ExportAlert: Equatable {
    case failed(title: String, message: String, retryable: Bool)
}

enum LastExportOperation: Equatable {
    case generateReport
    case sendToCoach
    case transmitToAgent
}

@MainActor
@Observable
final class BioharvestViewModel {
    var exportWindow = ExportWindow.defaultWindow()
    var metricInclusion = MetricInclusion.load()

    var isExporting = false
    var exportProgress: ExportProgress?
    var showPermissionBanner = false
    var showCopiedBanner = false
    var showShareSheet = false
    var showExportReport = false
    var exportFileURL: URL?
    var exportAlert: ExportAlert?
    var transmissionStatus: TransmissionStatus = .idle

    var lastDailyLogs: [DailyLog] = []
    var lastExportPayload: ExportPayload?
    var metricCoverage: [MetricCoverage] = []

    private(set) var lastExportJSON: String?
    private(set) var lastExportData: Data?
    private var lastOperation: LastExportOperation?

    var windowIsValid: Bool { exportWindow.isValid }

    var summaryLog: DailyLog? { lastDailyLogs.last }

    var hasWebhookURL: Bool {
        let url = UserDefaults.standard.string(forKey: BioharvestStorage.webhookURLKey) ?? ""
        return !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canShare: Bool {
        exportFileURL != nil && lastExportData != nil
    }

    var hasLastReport: Bool {
        lastExportPayload != nil
    }

    func resetWindowToDefault() {
        exportWindow = ExportWindow.defaultWindow()
    }

    func applyPreset(_ preset: ExportWindowPreset) {
        exportWindow = preset.makeWindow()
    }

    func updateExportStart(_ date: Date) {
        let calendar = ExportWindow.localCalendar()
        exportWindow.start = calendar.startOfDay(for: date)
        if exportWindow.start > exportWindow.end {
            exportWindow.end = exportWindow.start
        }
    }

    func updateExportEnd(_ date: Date) {
        let calendar = ExportWindow.localCalendar()
        exportWindow.end = calendar.startOfDay(for: date)
        if exportWindow.end < exportWindow.start {
            exportWindow.start = exportWindow.end
        }
    }

    func viewLastReport() {
        guard hasLastReport else { return }
        showExportReport = true
    }

    func retryLastOperation() async {
        guard let lastOperation else { return }
        switch lastOperation {
        case .generateReport:
            await generateReport()
        case .sendToCoach:
            await sendToCoach()
        case .transmitToAgent:
            await transmitToAgent()
        }
    }

    func transmitToAgent() async {
        lastOperation = .transmitToAgent
        guard exportWindow.isValid else {
            presentExportAlert("Invalid window", "Export window end must be on or after start.", retryable: false)
            return
        }

        let webhookURL = UserDefaults.standard.string(forKey: BioharvestStorage.webhookURLKey) ?? ""
        let trimmedURL = webhookURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            transmissionStatus = .failed("Add a webhook URL in Settings.")
            HapticFeedback.error()
            return
        }

        isExporting = true
        transmissionStatus = .transmitting
        exportProgress = ExportProgress.requestingAccess
        exportAlert = nil
        await Task.yield()
        defer {
            isExporting = false
            exportProgress = nil
        }

        do {
            let (payload, data) = try await buildExportWithGuards()
            try applyExportResult(payload: payload, data: data)

            exportProgress = ExportProgress.transmitting
            switch await WebhookTransmitter.post(json: data, to: trimmedURL) {
            case .success:
                transmissionStatus = .success
                exportProgress = ExportProgress.complete
                HapticFeedback.success()
                showExportReport = true
            case .failure(let error):
                transmissionStatus = .failed(error.localizedDescription)
                HapticFeedback.error()
            }
        } catch is CancellationError {
            transmissionStatus = .idle
            HapticFeedback.softTap()
            return
        } catch {
            transmissionStatus = .failed(error.localizedDescription)
            HapticFeedback.error()
            presentExportAlert("Export Error", error.localizedDescription, retryable: true)
        }
    }

    func generateReport() async {
        lastOperation = .generateReport
        guard exportWindow.isValid else {
            presentExportAlert("Invalid window", "Export window end must be on or after start.", retryable: false)
            return
        }

        isExporting = true
        exportProgress = ExportProgress.requestingAccess
        exportAlert = nil
        await Task.yield()
        defer {
            isExporting = false
            exportProgress = nil
        }

        do {
            let (payload, data) = try await buildExportWithGuards()
            try applyExportResult(payload: payload, data: data)
            try writeExportFile(data)
            HapticFeedback.success()
            showExportReport = true
        } catch is CancellationError {
            HapticFeedback.softTap()
            return
        } catch {
            HapticFeedback.error()
            presentExportAlert("Export Error", error.localizedDescription, retryable: true)
        }
    }

    func sendToCoach() async {
        lastOperation = .sendToCoach
        guard exportWindow.isValid else {
            presentExportAlert("Invalid window", "Export window end must be on or after start.", retryable: false)
            return
        }

        isExporting = true
        exportProgress = ExportProgress.requestingAccess
        exportAlert = nil
        await Task.yield()
        defer {
            isExporting = false
            exportProgress = nil
        }

        do {
            let (payload, data) = try await buildExportWithGuards()
            try applyExportResult(payload: payload, data: data)
            try writeExportFile(data)
            HapticFeedback.success()
            showExportReport = true
        } catch is CancellationError {
            HapticFeedback.softTap()
            return
        } catch {
            HapticFeedback.error()
            presentExportAlert("Export Error", error.localizedDescription, retryable: true)
        }
    }

    func sendToCoachFromReport() throws {
        guard let data = lastExportData else {
            throw CoachHandoff.CoachHandoffError.containerUnavailable
        }
        try CoachHandoff.writeExport(data)
        HapticFeedback.success()
        CoachHandoff.openCoachApp()
    }

    func presentShareSheet() {
        guard canShare else {
            exportAlert = .failed(
                title: "Share Unavailable",
                message: "Export data is missing. Generate the report again.",
                retryable: true
            )
            HapticFeedback.error()
            return
        }
        showShareSheet = true
    }

    func hideEmptyMetrics() {
        metricInclusion.hideEmptyMetrics(from: metricCoverage)
        metricInclusion.save()
        metricCoverage = MetricCoverage.compute(from: lastDailyLogs, inclusion: metricInclusion)
    }

    func copyJSONToClipboard() {
        guard let lastExportJSON else { return }
        UIPasteboard.general.string = lastExportJSON
        showCopiedBanner = true
        HapticFeedback.lightTap()
    }

    func openHealthSettings() {
        guard let url = URL(string: "x-apple-health://") else { return }
        UIApplication.shared.open(url)
    }

    func dismissExportAlert() {
        exportAlert = nil
    }

    private func buildExportWithGuards() async throws -> (ExportPayload, Data) {
        let window = exportWindow
        let inclusion = metricInclusion
        let progressHandler: ExportProgressHandler = { [weak self] progress in
            await self?.updateExportProgress(progress)
        }

        let (payload, data) = try await ExportTimeout.withTimeout {
            try await BioharvestExportPipeline.shared.buildPayload(
                window: window,
                inclusion: inclusion,
                progress: progressHandler
            )
        }

        guard data.count <= ExportTimeout.maxExportBytes else {
            throw BioharvestExportError.exportTooLarge
        }

        return (payload, data)
    }

    private func applyExportResult(payload: ExportPayload, data: Data) throws {
        lastDailyLogs = payload.logs
        lastExportPayload = payload
        metricCoverage = MetricCoverage.compute(from: payload.logs, inclusion: metricInclusion)
        showPermissionBanner = payload.healthKitStatus == .denied

        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Bioharvest", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to encode JSON."
            ])
        }
        lastExportJSON = jsonString
        lastExportData = data
    }

    private func writeExportFile(_ data: Data) throws {
        if let previousURL = exportFileURL {
            try? FileManager.default.removeItem(at: previousURL)
        }

        let fileName = "Bioharvest_Export_\(Date().timeIntervalSince1970).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        exportFileURL = fileURL
    }

    private func updateExportProgress(_ progress: ExportProgress) {
        exportProgress = progress
    }

    private func presentExportAlert(_ title: String, _ message: String, retryable: Bool) {
        exportAlert = .failed(title: title, message: message, retryable: retryable)
    }

}
