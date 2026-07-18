import Foundation

struct ExportProgress: Sendable, Equatable {
    let phase: String
    /// 0…1
    let fraction: Double

    static let requestingAccess = ExportProgress(phase: "Requesting Health access…", fraction: 0.02)
    static let assembling = ExportProgress(phase: "Assembling daily logs…", fraction: 0.92)
    static let encoding = ExportProgress(phase: "Encoding JSON…", fraction: 0.97)
    static let transmitting = ExportProgress(phase: "Transmitting…", fraction: 0.99)
    static let complete = ExportProgress(phase: "Complete", fraction: 1)

    static func fetchingMetric(_ name: String, completed: Int, total: Int) -> ExportProgress {
        let base = 0.05
        let span = 0.85
        let fraction = total > 0 ? base + span * (Double(completed) / Double(total)) : base
        return ExportProgress(phase: "Fetching \(name)…", fraction: min(0.9, fraction))
    }
}

typealias ExportProgressHandler = @Sendable (ExportProgress) async -> Void
