import Foundation

enum MetricKey: String, CaseIterable, Identifiable, Codable {
    case hrv
    case rhr
    case sleepTotal
    case sleepDeep
    case sleepREM
    case weight
    case bodyFat
    case stepCount
    case activeEnergy
    case restingEnergy
    case exerciseMinutes
    case workouts
    case trainingLoad
    case caloriesConsumed
    case proteinG
    case carbsG
    case fatG
    case waterLiters
    case alcoholicBeveragesCount

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hrv: return "HRV"
        case .rhr: return "RHR"
        case .sleepTotal: return "Total Sleep"
        case .sleepDeep: return "Deep Sleep"
        case .sleepREM: return "REM Sleep"
        case .weight: return "Weight"
        case .bodyFat: return "Body Fat"
        case .stepCount: return "Step Count"
        case .activeEnergy: return "Active Energy"
        case .restingEnergy: return "Resting Energy"
        case .exerciseMinutes: return "Exercise Minutes"
        case .workouts: return "Workouts"
        case .trainingLoad: return "Training Load"
        case .caloriesConsumed: return "Calories"
        case .proteinG: return "Protein"
        case .carbsG: return "Carbs"
        case .fatG: return "Fat"
        case .waterLiters: return "Water"
        case .alcoholicBeveragesCount: return "Alcoholic Beverages"
        }
    }

    func isEnabled(in inclusion: MetricInclusion) -> Bool {
        switch self {
        case .hrv: return inclusion.hrvToday
        case .rhr: return inclusion.rhrToday
        case .sleepTotal: return inclusion.sleepTotal
        case .sleepDeep: return inclusion.sleepDeep
        case .sleepREM: return inclusion.sleepREM
        case .weight: return inclusion.weight
        case .bodyFat: return inclusion.bodyFat
        case .stepCount: return inclusion.stepCount
        case .activeEnergy: return inclusion.activeEnergy
        case .restingEnergy: return inclusion.restingEnergy
        case .exerciseMinutes: return inclusion.exerciseMinutes
        case .workouts: return inclusion.workouts
        case .trainingLoad: return inclusion.trainingLoad
        case .caloriesConsumed: return inclusion.caloriesConsumed
        case .proteinG: return inclusion.proteinG
        case .carbsG: return inclusion.carbsG
        case .fatG: return inclusion.fatG
        case .waterLiters: return inclusion.waterLiters
        case .alcoholicBeveragesCount: return inclusion.alcoholicBeveragesCount
        }
    }

    func setEnabled(_ enabled: Bool, in inclusion: inout MetricInclusion) {
        switch self {
        case .hrv: inclusion.hrvToday = enabled
        case .rhr: inclusion.rhrToday = enabled
        case .sleepTotal: inclusion.sleepTotal = enabled
        case .sleepDeep: inclusion.sleepDeep = enabled
        case .sleepREM: inclusion.sleepREM = enabled
        case .weight: inclusion.weight = enabled
        case .bodyFat: inclusion.bodyFat = enabled
        case .stepCount: inclusion.stepCount = enabled
        case .activeEnergy: inclusion.activeEnergy = enabled
        case .restingEnergy: inclusion.restingEnergy = enabled
        case .exerciseMinutes: inclusion.exerciseMinutes = enabled
        case .workouts: inclusion.workouts = enabled
        case .trainingLoad: inclusion.trainingLoad = enabled
        case .caloriesConsumed: inclusion.caloriesConsumed = enabled
        case .proteinG: inclusion.proteinG = enabled
        case .carbsG: inclusion.carbsG = enabled
        case .fatG: inclusion.fatG = enabled
        case .waterLiters: inclusion.waterLiters = enabled
        case .alcoholicBeveragesCount: inclusion.alcoholicBeveragesCount = enabled
        }
    }

    func hasData(on log: DailyLog) -> Bool {
        switch self {
        case .hrv: return log.cnsAndCardio.hrvSdnn != nil
        case .rhr: return log.cnsAndCardio.restingHeartRate != nil
        case .sleepTotal: return log.sleepAndRecovery.sleepTotalMinutes != nil
        case .sleepDeep: return log.sleepAndRecovery.deepSleepMinutes != nil
        case .sleepREM: return log.sleepAndRecovery.remSleepMinutes != nil
        case .weight: return log.bodyComposition.bodyWeightKg != nil
        case .bodyFat: return log.bodyComposition.bodyFatPercent != nil
        case .stepCount: return log.activityAndStrain.stepCount != nil
        case .activeEnergy: return log.activityAndStrain.activeEnergyKcal != nil
        case .restingEnergy: return log.activityAndStrain.restingEnergyKcal != nil
        case .exerciseMinutes: return log.activityAndStrain.exerciseMinutes != nil
        case .workouts: return !log.activityAndStrain.workouts.isEmpty
        case .trainingLoad: return log.activityAndStrain.trainingLoadContribution != nil
        case .caloriesConsumed: return log.nutritionAndToxicity.caloriesConsumedKcal != nil
        case .proteinG: return log.nutritionAndToxicity.proteinG != nil
        case .carbsG: return log.nutritionAndToxicity.carbsG != nil
        case .fatG: return log.nutritionAndToxicity.fatG != nil
        case .waterLiters: return log.nutritionAndToxicity.waterLiters != nil
        case .alcoholicBeveragesCount: return log.nutritionAndToxicity.alcoholicBeveragesCount != nil
        }
    }
}

struct MetricCoverage: Identifiable, Equatable {
    let key: MetricKey
    let displayName: String
    let daysWithData: Int
    let totalDays: Int

    var id: String { key.rawValue }

    var hasAnyData: Bool { daysWithData > 0 }

    var summaryText: String {
        if totalDays == 0 || daysWithData == 0 {
            return "No data"
        }
        return "\(daysWithData)/\(totalDays) days"
    }

    var toggleHintText: String? {
        guard totalDays > 0 else { return nil }
        return "\(daysWithData)/\(totalDays)"
    }

    static func compute(from logs: [DailyLog], inclusion: MetricInclusion) -> [MetricCoverage] {
        let totalDays = logs.count
        return MetricKey.allCases.compactMap { key in
            guard key.isEnabled(in: inclusion) else { return nil }
            let daysWithData = logs.reduce(into: 0) { count, log in
                if key.hasData(on: log) { count += 1 }
            }
            return MetricCoverage(
                key: key,
                displayName: key.displayName,
                daysWithData: daysWithData,
                totalDays: totalDays
            )
        }
    }

    static func metricsWithDataCount(in coverage: [MetricCoverage]) -> Int {
        coverage.filter(\.hasAnyData).count
    }

    static func emptyMetrics(in coverage: [MetricCoverage]) -> [MetricCoverage] {
        coverage.filter { !$0.hasAnyData }
    }
}

extension MetricInclusion {
    mutating func hideEmptyMetrics(from coverage: [MetricCoverage]) {
        for item in coverage where !item.hasAnyData {
            item.key.setEnabled(false, in: &self)
        }
    }

    func coverageHint(for key: MetricKey, in coverage: [MetricCoverage]) -> String? {
        coverage.first(where: { $0.key == key })?.toggleHintText
    }
}
