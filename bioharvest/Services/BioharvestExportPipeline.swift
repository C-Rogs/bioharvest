import Foundation

enum BioharvestExportError: LocalizedError {
    case invalidWindow
    case encodingFailed
    case timedOut
    case exportTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidWindow:
            return "Export window end must be on or after start."
        case .encodingFailed:
            return "Failed to encode JSON."
        case .timedOut:
            return "Export took too long. Try a shorter date range or fewer metrics."
        case .exportTooLarge:
            return "Export is too large. Try a shorter date range or fewer metrics."
        }
    }
}

actor BioharvestExportPipeline {
    static let shared = BioharvestExportPipeline()

    private let healthKit = HealthKitManager.shared

    func buildPayload(
        window: ExportWindow,
        inclusion: MetricInclusion,
        encoding: ExportJSONEncoding = .humanReadable,
        progress: ExportProgressHandler? = nil
    ) async throws -> (ExportPayload, Data) {
        guard window.isValid else {
            throw BioharvestExportError.invalidWindow
        }

        try Task.checkCancellation()
        await Task.yield()
        await progress?(ExportProgress.requestingAccess)
        try Task.checkCancellation()
        let authResult = await healthKit.requestAuthorization()
        try Task.checkCancellation()
        let dailyLogs = try await healthKit.fetchDailyLogs(
            window: window,
            inclusion: inclusion,
            progress: progress
        )
        try Task.checkCancellation()
        await progress?(ExportProgress.assembling)
        let status = resolveHealthKitStatus(authResult: authResult, logs: dailyLogs, inclusion: inclusion)
        let exportRange = makeExportRange(from: dailyLogs, window: window)

        let payload = ExportPayload(
            schemaVersion: ExportPayload.currentSchemaVersion,
            app: "bioharvest",
            purpose: "time_series_coach_export",
            exportDate: Date(),
            healthKitStatus: status,
            exportRange: exportRange,
            logs: dailyLogs
        )

        await progress?(ExportProgress.encoding)
        let encoder = JSONEncoder()
        encoding.configure(encoder)

        let data = try encoder.encode(payload)
        await progress?(ExportProgress.complete)
        return (payload, data)
    }

    private func resolveHealthKitStatus(
        authResult: HealthKitAuthResult,
        logs: [DailyLog],
        inclusion: MetricInclusion
    ) -> HealthKitStatus {
        if logs.hasAnyValue(for: inclusion) {
            return .liveAuthorized
        }

        switch authResult {
        case .unavailable: return .unavailable
        case .error: return .error
        case .notDetermined: return .notDetermined
        case .liveAuthorized, .denied: return .denied
        }
    }

    private func makeExportRange(from logs: [DailyLog], window: ExportWindow) -> ExportRange {
        if let first = logs.first?.date, let last = logs.last?.date {
            return ExportRange(startDate: first, endDate: last)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return ExportRange(
            startDate: formatter.string(from: window.start),
            endDate: formatter.string(from: window.end)
        )
    }
}
