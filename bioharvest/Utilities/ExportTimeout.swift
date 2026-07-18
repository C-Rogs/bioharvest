import Foundation

enum ExportTimeout {
    static let defaultSeconds: TimeInterval = 120
    static let maxExportBytes = 50_000_000

    static func withTimeout<T: Sendable>(
        seconds: TimeInterval = defaultSeconds,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw BioharvestExportError.timedOut
            }

            guard let result = try await group.next() else {
                throw BioharvestExportError.timedOut
            }
            group.cancelAll()
            return result
        }
    }
}
