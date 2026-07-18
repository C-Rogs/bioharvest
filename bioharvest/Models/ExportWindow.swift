import Foundation

enum ExportWindowPreset: String, CaseIterable, Identifiable {
    case today = "Today"
    case lastTwoDays = "Last 2 Days"
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"

    var id: String { rawValue }

    func makeWindow(calendar: Calendar = ExportWindow.localCalendar()) -> ExportWindow {
        let today = calendar.startOfDay(for: Date())

        switch self {
        case .today:
            return ExportWindow(start: today, end: today)
        case .lastTwoDays:
            let start = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            return ExportWindow(start: start, end: today)
        case .lastWeek:
            let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            return ExportWindow(start: start, end: today)
        case .lastMonth:
            let start = calendar.date(byAdding: .day, value: -29, to: today) ?? today
            return ExportWindow(start: start, end: today)
        }
    }
}

struct ExportWindow: Equatable {
    /// Start of the first local calendar day (midnight in the device timezone).
    var start: Date
    /// Start of the last local calendar day (midnight in the device timezone).
    var end: Date

    var isValid: Bool { start <= end }

    var dayCount: Int {
        let calendar = Self.localCalendar()
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        let components = calendar.dateComponents([.day], from: startDay, to: endDay)
        return (components.day ?? 0) + 1
    }

    var includesToday: Bool {
        Self.localCalendar().isDateInToday(end)
    }

    static func localCalendar() -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }

    static func startOfDay(_ date: Date, calendar: Calendar = localCalendar()) -> Date {
        calendar.startOfDay(for: date)
    }

    static func window(
        from startDate: Date,
        through endDate: Date,
        calendar: Calendar = localCalendar()
    ) -> ExportWindow {
        ExportWindow(
            start: startOfDay(startDate, calendar: calendar),
            end: startOfDay(endDate, calendar: calendar)
        )
    }

    static func preset(_ preset: ExportWindowPreset, calendar: Calendar = localCalendar()) -> ExportWindow {
        preset.makeWindow(calendar: calendar)
    }

    static func defaultWindow(calendar: Calendar = localCalendar()) -> ExportWindow {
        preset(.lastWeek, calendar: calendar)
    }

}
