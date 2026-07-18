import Foundation
import HealthKit

/// Pure calendar and sleep-interval helpers shared by HealthKitManager and unit tests.
enum BioharvestHealthKitMath {
    static func startOfCalendarDay(_ date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Last instant of the local calendar day (23:59:59).
    static func inclusiveEndOfCalendarDay(_ date: Date, calendar: Calendar) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dayStart)
            ?? dayStart.addingTimeInterval(86_399)
    }

    /// HealthKit sample predicates treat `end` as exclusive; use start of the next local calendar day.
    static func exclusiveEndOfCalendarDay(_ date: Date, calendar: Calendar) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: dayStart)
            ?? dayStart.addingTimeInterval(86_400)
    }

    /// Predicate span: local midnight on the first day through the last day.
    /// When the last day is today, the end is `Date()` so partial-day data is included.
    /// HealthKit treats `end` as exclusive, so non-today ranges end one second after 23:59:59.
    static func dailyQueryBounds(
        from rangeStartDay: Date,
        through rangeEndDay: Date,
        calendar: Calendar,
        now: Date = Date()
    ) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: rangeStartDay)

        if calendar.isDate(rangeEndDay, inSameDayAs: now) {
            return (start, now)
        }

        let inclusiveEnd = inclusiveEndOfCalendarDay(rangeEndDay, calendar: calendar)
        let exclusiveEnd = calendar.date(byAdding: .second, value: 1, to: inclusiveEnd)
            ?? calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: rangeEndDay))
            ?? inclusiveEnd.addingTimeInterval(1)
        return (start, exclusiveEnd)
    }

    static func sleepWindowStart(for day: Date, calendar: Calendar) -> Date {
        let dayStart = calendar.startOfDay(for: day)
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dayStart) else {
            return dayStart
        }
        return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: previousDay) ?? previousDay
    }

    static func sleepWindowEnd(for day: Date, calendar: Calendar) -> Date {
        let dayStart = calendar.startOfDay(for: day)
        return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayStart) ?? dayStart
    }

    /// Maps each sleep-analysis sample to the export day keys whose 18:00–18:00 window it overlaps.
    static func indexSleepSamplesByDay(
        samples: [HKCategorySample],
        dayKeys: [Date],
        calendar: Calendar
    ) -> [Date: [HKCategorySample]] {
        var buckets = Dictionary(uniqueKeysWithValues: dayKeys.map { ($0, [HKCategorySample]()) })
        guard !samples.isEmpty, !dayKeys.isEmpty else { return buckets }

        for sample in samples {
            for dayKey in dayKeys {
                let windowStart = sleepWindowStart(for: dayKey, calendar: calendar)
                let windowEnd = sleepWindowEnd(for: dayKey, calendar: calendar)
                guard sample.endDate > windowStart, sample.startDate < windowEnd else { continue }
                buckets[dayKey, default: []].append(sample)
            }
        }
        return buckets
    }

    static func mergedDurationMinutes(
        from intervals: [(start: Date, end: Date)]
    ) -> Double? {
        let valid = intervals.filter { $0.end > $0.start }
        guard !valid.isEmpty else { return nil }

        let sorted = valid.sorted { $0.start < $1.start }
        var merged: [(start: Date, end: Date)] = []

        for interval in sorted {
            if var last = merged.popLast() {
                if interval.start <= last.end {
                    last.end = max(last.end, interval.end)
                    merged.append(last)
                } else {
                    merged.append(last)
                    merged.append(interval)
                }
            } else {
                merged.append(interval)
            }
        }

        let totalSeconds = merged.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
        return totalSeconds / 60.0
    }

    static func mergedDurationMinutes(
        from samples: [HKCategorySample],
        matching values: Set<Int>,
        windowStart: Date,
        windowEnd: Date
    ) -> Double? {
        let intervals: [(start: Date, end: Date)] = samples
            .filter { values.contains($0.value) }
            .map { sample in
                let start = max(sample.startDate, windowStart)
                let end = min(sample.endDate, windowEnd)
                return (start, end)
            }
        return mergedDurationMinutes(from: intervals)
    }

    static func sampleMatchesWorkout(
        sampleStart: Date,
        workoutStart: Date,
        workoutEnd: Date,
        graceAfterEnd: TimeInterval = 300
    ) -> Bool {
        sampleStart >= workoutStart && sampleStart <= workoutEnd.addingTimeInterval(graceAfterEnd)
    }

    static func matchWorkout(for sample: HKQuantitySample, in workouts: [HKWorkout]) -> HKWorkout? {
        workouts.first { workout in
            sampleMatchesWorkout(
                sampleStart: sample.startDate,
                workoutStart: workout.startDate,
                workoutEnd: workout.endDate
            )
        }
    }
}
