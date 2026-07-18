import Foundation

enum ExportJSONEncoding: Sendable {
    /// Pretty-printed, sorted keys for share sheet, Coach handoff, clipboard.
    case humanReadable
    /// Minimal whitespace for webhook and Shortcut transmission.
    case compact

    func configure(_ encoder: JSONEncoder) {
        encoder.dateEncodingStrategy = .iso8601
        switch self {
        case .humanReadable:
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        case .compact:
            encoder.outputFormatting = []
        }
    }
}
