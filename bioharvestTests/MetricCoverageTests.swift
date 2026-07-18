import XCTest
@testable import bioharvest

final class MetricCoverageTests: XCTestCase {

    private func makeLog(
        date: String,
        hrv: Double? = nil,
        steps: Int? = nil
    ) -> DailyLog {
        DailyLog(
            date: date,
            timezone: "Europe/London",
            cnsAndCardio: CNSAndCardioMetrics(
                restingHeartRate: nil,
                hrvSdnn: hrv.flatMap { RoundedDouble($0) }
            ),
            sleepAndRecovery: SleepAndRecoveryMetrics(
                sleepTotalMinutes: nil,
                deepSleepMinutes: nil,
                remSleepMinutes: nil
            ),
            nutritionAndToxicity: NutritionAndToxicityMetrics(
                caloriesConsumedKcal: nil,
                proteinG: nil,
                carbsG: nil,
                fatG: nil,
                waterLiters: nil,
                alcoholicBeveragesCount: nil
            ),
            activityAndStrain: ActivityAndStrainMetrics(
                stepCount: steps,
                activeEnergyKcal: nil,
                restingEnergyKcal: nil,
                exerciseMinutes: nil,
                trainingLoadContribution: nil,
                workouts: []
            ),
            bodyComposition: BodyCompositionMetrics(
                bodyWeightKg: nil,
                bodyFatPercent: nil
            )
        )
    }

    func testComputeCountsDaysWithData() {
        let logs = [
            makeLog(date: "2026-01-01", hrv: 45.0),
            makeLog(date: "2026-01-02", hrv: 50.0),
            makeLog(date: "2026-01-03"),
        ]
        var inclusion = MetricInclusion()
        inclusion.hrvToday = true
        inclusion.stepCount = true

        let coverage = MetricCoverage.compute(from: logs, inclusion: inclusion)

        let hrv = coverage.first { $0.key == .hrv }
        XCTAssertEqual(hrv?.daysWithData, 2)
        XCTAssertEqual(hrv?.totalDays, 3)
        XCTAssertEqual(hrv?.summaryText, "2/3 days")

        let steps = coverage.first { $0.key == .stepCount }
        XCTAssertEqual(steps?.daysWithData, 0)
        XCTAssertEqual(steps?.summaryText, "No data")
    }

    func testComputeOnlyIncludesEnabledMetrics() {
        let logs = [makeLog(date: "2026-01-01", hrv: 40.0)]
        var inclusion = MetricInclusion()
        inclusion.hrvToday = true
        inclusion.rhrToday = false
        inclusion.sleepTotal = false
        inclusion.sleepDeep = false
        inclusion.sleepREM = false
        inclusion.weight = false
        inclusion.bodyFat = false
        inclusion.stepCount = false
        inclusion.activeEnergy = false
        inclusion.restingEnergy = false
        inclusion.exerciseMinutes = false
        inclusion.workouts = false
        inclusion.trainingLoad = false
        inclusion.caloriesConsumed = false
        inclusion.proteinG = false
        inclusion.carbsG = false
        inclusion.fatG = false
        inclusion.waterLiters = false
        inclusion.alcoholicBeveragesCount = false

        let coverage = MetricCoverage.compute(from: logs, inclusion: inclusion)
        XCTAssertEqual(coverage.count, 1)
        XCTAssertEqual(coverage.first?.key, .hrv)
    }

    func testEmptyMetricsFilter() {
        let items = [
            MetricCoverage(key: .hrv, displayName: "HRV", daysWithData: 2, totalDays: 7),
            MetricCoverage(key: .proteinG, displayName: "Protein", daysWithData: 0, totalDays: 7),
        ]
        XCTAssertEqual(MetricCoverage.emptyMetrics(in: items).count, 1)
        XCTAssertEqual(MetricCoverage.metricsWithDataCount(in: items), 1)
    }

    func testHideEmptyMetricsUpdatesInclusion() {
        var inclusion = MetricInclusion()
        inclusion.hrvToday = true
        inclusion.proteinG = true
        let coverage = [
            MetricCoverage(key: .hrv, displayName: "HRV", daysWithData: 3, totalDays: 7),
            MetricCoverage(key: .proteinG, displayName: "Protein", daysWithData: 0, totalDays: 7),
        ]
        inclusion.hideEmptyMetrics(from: coverage)
        XCTAssertTrue(inclusion.hrvToday)
        XCTAssertFalse(inclusion.proteinG)
    }
}
