import Foundation
import UIKit

/// Writes bioharvest exports into Coach's App Group and opens the Coach app.
/// Constants must stay in sync with Coach `AppGroupExportStore`.
enum CoachHandoff {
    static let appGroupID = "group.com.cameronro.coach"
    static let latestExportFilename = "latest_export.json"
    static let importURLString = "coach://import/latest"
    private static let pendingImportKey = "pending_share_import"
    private static let coachBundleFragment = "com.cameronro.coach"

    static var importURL: URL? {
        URL(string: importURLString)
    }

    static func isCoachShareActivity(_ activityType: UIActivity.ActivityType?) -> Bool {
        guard let raw = activityType?.rawValue.lowercased() else { return false }
        return raw.contains(coachBundleFragment)
    }

    static func writeExport(_ data: Data) throws {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw CoachHandoffError.containerUnavailable
        }

        let fileURL = containerURL.appendingPathComponent(latestExportFilename)
        try data.write(to: fileURL, options: .atomic)
        UserDefaults(suiteName: appGroupID)?.set(true, forKey: pendingImportKey)
    }

    @discardableResult
    static func openCoachApp() -> Bool {
        guard let url = importURL else { return false }
        UIApplication.shared.open(url)
        return true
    }

    enum CoachHandoffError: LocalizedError {
        case containerUnavailable

        var errorDescription: String? {
            switch self {
            case .containerUnavailable:
                return "Could not access Coach shared storage. Reinstall bioharvest and Coach, then try again."
            }
        }
    }
}
