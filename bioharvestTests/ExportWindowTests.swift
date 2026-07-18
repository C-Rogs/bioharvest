import XCTest
@testable import bioharvest

final class ExportWindowTests: XCTestCase {
    func testDayCountSingleDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let day = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9))!
        let window = ExportWindow(start: day, end: day)

        XCTAssertEqual(window.dayCount, 1)
    }

    func testDayCountLastWeekSpan() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let end = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9))!
        let start = calendar.date(byAdding: .day, value: -6, to: end)!
        let window = ExportWindow(start: start, end: end)

        XCTAssertEqual(window.dayCount, 7)
    }

    func testLastWeekPresetSpansSevenDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = calendar.startOfDay(for: Date())

        let window = ExportWindow.preset(.lastWeek, calendar: calendar)
        XCTAssertEqual(window.end, today)
        XCTAssertEqual(window.dayCount, 7)
    }
}
