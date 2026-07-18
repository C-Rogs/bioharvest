import HealthKit
import XCTest
@testable import bioharvest

final class BioharvestHealthKitMathTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testDailyQueryBoundsHistoricalRangeUsesExclusiveEnd() {
        let startDay = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
        let endDay = calendar.date(from: DateComponents(year: 2026, month: 7, day: 3))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 10, hour: 12))!

        let bounds = BioharvestHealthKitMath.dailyQueryBounds(
            from: startDay,
            through: endDay,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(bounds.start, calendar.startOfDay(for: startDay))
        let expectedInclusiveEnd = BioharvestHealthKitMath.inclusiveEndOfCalendarDay(endDay, calendar: calendar)
        let expectedExclusiveEnd = calendar.date(byAdding: .second, value: 1, to: expectedInclusiveEnd)
        XCTAssertEqual(bounds.end, expectedExclusiveEnd)
    }

    func testDailyQueryBoundsWhenEndIsTodayUsesNow() {
        let startDay = calendar.date(from: DateComponents(year: 2026, month: 7, day: 7))!
        let endDay = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9, hour: 8))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9, hour: 15, minute: 30))!

        let bounds = BioharvestHealthKitMath.dailyQueryBounds(
            from: startDay,
            through: endDay,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(bounds.start, calendar.startOfDay(for: startDay))
        XCTAssertEqual(bounds.end, now)
    }

    func testMergedDurationMinutesCombinesOverlappingIntervals() {
        let base = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9, hour: 22))!
        let intervals: [(Date, Date)] = [
            (base, base.addingTimeInterval(30 * 60)),
            (base.addingTimeInterval(20 * 60), base.addingTimeInterval(70 * 60)),
            (base.addingTimeInterval(120 * 60), base.addingTimeInterval(150 * 60))
        ]

        let minutes = BioharvestHealthKitMath.mergedDurationMinutes(from: intervals)
        XCTAssertEqual(minutes, 100.0)
    }

    func testMergedDurationMinutesReturnsNilForEmptyInput() {
        XCTAssertNil(BioharvestHealthKitMath.mergedDurationMinutes(from: []))
    }

    func testSleepWindowSpansSixPMToSixPM() {
        let day = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9))!
        let windowStart = BioharvestHealthKitMath.sleepWindowStart(for: day, calendar: calendar)
        let windowEnd = BioharvestHealthKitMath.sleepWindowEnd(for: day, calendar: calendar)

        XCTAssertEqual(calendar.component(.hour, from: windowStart), 18)
        XCTAssertEqual(calendar.component(.day, from: windowStart), 8)
        XCTAssertEqual(calendar.component(.hour, from: windowEnd), 18)
        XCTAssertEqual(calendar.component(.day, from: windowEnd), 9)
    }

    func testIndexSleepSamplesByDayBucketsOverlappingSamples() {
        let day = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9))!
        let dayKey = calendar.startOfDay(for: day)
        let windowStart = BioharvestHealthKitMath.sleepWindowStart(for: dayKey, calendar: calendar)
        let insideStart = windowStart.addingTimeInterval(60 * 60)
        let insideEnd = insideStart.addingTimeInterval(7 * 60 * 60)

        let sample = HKCategorySample(
            type: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            start: insideStart,
            end: insideEnd
        )

        let buckets = BioharvestHealthKitMath.indexSleepSamplesByDay(
            samples: [sample],
            dayKeys: [dayKey],
            calendar: calendar
        )

        XCTAssertEqual(buckets[dayKey]?.count, 1)
    }

    func testIndexSleepSamplesByDayIgnoresOutOfRangeSamples() {
        let day = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9))!
        let dayKey = calendar.startOfDay(for: day)
        let windowEnd = BioharvestHealthKitMath.sleepWindowEnd(for: dayKey, calendar: calendar)
        let outsideStart = windowEnd.addingTimeInterval(60 * 60)
        let outsideEnd = outsideStart.addingTimeInterval(30 * 60)

        let sample = HKCategorySample(
            type: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            start: outsideStart,
            end: outsideEnd
        )

        let buckets = BioharvestHealthKitMath.indexSleepSamplesByDay(
            samples: [sample],
            dayKeys: [dayKey],
            calendar: calendar
        )

        XCTAssertTrue(buckets[dayKey]?.isEmpty ?? true)
    }

    func testSampleMatchesWorkoutAllowsFiveMinuteGraceAfterEnd() {
        let workoutStart = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9, hour: 8))!
        let workoutEnd = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9, hour: 9))!

        XCTAssertTrue(
            BioharvestHealthKitMath.sampleMatchesWorkout(
                sampleStart: workoutEnd.addingTimeInterval(120),
                workoutStart: workoutStart,
                workoutEnd: workoutEnd
            )
        )
        XCTAssertFalse(
            BioharvestHealthKitMath.sampleMatchesWorkout(
                sampleStart: workoutEnd.addingTimeInterval(400),
                workoutStart: workoutStart,
                workoutEnd: workoutEnd
            )
        )
    }
}
