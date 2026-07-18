import UIKit

enum HapticFeedback {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        lightImpact.prepare()
        softImpact.prepare()
        notification.prepare()
    }

    static func lightTap() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    static func softTap() {
        softImpact.impactOccurred()
        softImpact.prepare()
    }

    static func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    static func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }
}
