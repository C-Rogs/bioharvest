import Foundation

enum HealthKitStatus: String, Codable {
    case liveAuthorized = "live_authorized"
    case notDetermined = "not_determined"
    case denied
    case unavailable
    case error
}

struct RoundedDouble: Codable, Equatable {
    let value: Double

    init?(_ raw: Double?) {
        guard let raw else { return nil }
        value = (raw * 100).rounded() / 100
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Double.self)
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeNullOrRoundedDouble(_ value: RoundedDouble?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeNullOrInt(_ value: Int?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }
}

struct ExportRange: Codable, Equatable {
    let startDate: String
    let endDate: String

    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct ExportPayload: Codable {
    static let currentSchemaVersion = 2

    let schemaVersion: Int
    let app: String
    let purpose: String
    let exportDate: Date
    let healthKitStatus: HealthKitStatus
    let exportRange: ExportRange
    let logs: [DailyLog]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case app
        case purpose
        case exportDate = "export_date"
        case healthKitStatus = "healthkit_status"
        case exportRange = "export_range"
        case logs
    }
}

struct DailyLog: Codable, Equatable {
    let date: String
    let timezone: String
    let cnsAndCardio: CNSAndCardioMetrics
    let sleepAndRecovery: SleepAndRecoveryMetrics
    let nutritionAndToxicity: NutritionAndToxicityMetrics
    let activityAndStrain: ActivityAndStrainMetrics
    let bodyComposition: BodyCompositionMetrics

    enum CodingKeys: String, CodingKey {
        case date
        case timezone
        case cnsAndCardio = "cns_and_cardio"
        case sleepAndRecovery = "sleep_and_recovery"
        case nutritionAndToxicity = "nutrition_and_toxicity"
        case activityAndStrain = "activity_and_strain"
        case bodyComposition = "body_composition"
    }

    func hasAnyValue(for inclusion: MetricInclusion) -> Bool {
        cnsAndCardio.hasAnyValue(for: inclusion)
            || sleepAndRecovery.hasAnyValue(for: inclusion)
            || nutritionAndToxicity.hasAnyValue(for: inclusion)
            || activityAndStrain.hasAnyValue(for: inclusion)
            || bodyComposition.hasAnyValue(for: inclusion)
    }
}

struct CNSAndCardioMetrics: Codable, Equatable {
    let restingHeartRate: RoundedDouble?
    let hrvSdnn: RoundedDouble?

    enum CodingKeys: String, CodingKey {
        case restingHeartRate = "resting_heart_rate"
        case hrvSdnn = "hrv_sdnn"
    }

    func hasAnyValue(for inclusion: MetricInclusion) -> Bool {
        if inclusion.hrvToday && hrvSdnn != nil { return true }
        if inclusion.rhrToday && restingHeartRate != nil { return true }
        return false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNullOrRoundedDouble(restingHeartRate, forKey: .restingHeartRate)
        try container.encodeNullOrRoundedDouble(hrvSdnn, forKey: .hrvSdnn)
    }
}

struct SleepAndRecoveryMetrics: Codable, Equatable {
    let sleepTotalMinutes: RoundedDouble?
    let deepSleepMinutes: RoundedDouble?
    let remSleepMinutes: RoundedDouble?

    enum CodingKeys: String, CodingKey {
        case sleepTotalMinutes = "sleep_total_minutes"
        case deepSleepMinutes = "deep_sleep_minutes"
        case remSleepMinutes = "rem_sleep_minutes"
    }

    func hasAnyValue(for inclusion: MetricInclusion) -> Bool {
        if inclusion.sleepTotal && sleepTotalMinutes != nil { return true }
        if inclusion.sleepDeep && deepSleepMinutes != nil { return true }
        if inclusion.sleepREM && remSleepMinutes != nil { return true }
        return false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNullOrRoundedDouble(sleepTotalMinutes, forKey: .sleepTotalMinutes)
        try container.encodeNullOrRoundedDouble(deepSleepMinutes, forKey: .deepSleepMinutes)
        try container.encodeNullOrRoundedDouble(remSleepMinutes, forKey: .remSleepMinutes)
    }
}

struct NutritionAndToxicityMetrics: Codable, Equatable {
    let caloriesConsumedKcal: RoundedDouble?
    let proteinG: RoundedDouble?
    let carbsG: RoundedDouble?
    let fatG: RoundedDouble?
    let waterLiters: RoundedDouble?
    let alcoholicBeveragesCount: Int?

    enum CodingKeys: String, CodingKey {
        case caloriesConsumedKcal = "calories_consumed_kcal"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case waterLiters = "water_liters"
        case alcoholicBeveragesCount = "alcoholic_beverages_count"
    }

    func hasAnyValue(for inclusion: MetricInclusion) -> Bool {
        if inclusion.caloriesConsumed && caloriesConsumedKcal != nil { return true }
        if inclusion.proteinG && proteinG != nil { return true }
        if inclusion.carbsG && carbsG != nil { return true }
        if inclusion.fatG && fatG != nil { return true }
        if inclusion.waterLiters && waterLiters != nil { return true }
        if inclusion.alcoholicBeveragesCount && alcoholicBeveragesCount != nil { return true }
        return false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNullOrRoundedDouble(caloriesConsumedKcal, forKey: .caloriesConsumedKcal)
        try container.encodeNullOrRoundedDouble(proteinG, forKey: .proteinG)
        try container.encodeNullOrRoundedDouble(carbsG, forKey: .carbsG)
        try container.encodeNullOrRoundedDouble(fatG, forKey: .fatG)
        try container.encodeNullOrRoundedDouble(waterLiters, forKey: .waterLiters)
        try container.encodeNullOrInt(alcoholicBeveragesCount, forKey: .alcoholicBeveragesCount)
    }
}

struct WorkoutLog: Codable, Equatable {
    let type: String
    let durationMinutes: RoundedDouble?
    let energyBurnedKcal: RoundedDouble?
    let effortScore: RoundedDouble?
    let trainingLoadContribution: RoundedDouble?

    enum CodingKeys: String, CodingKey {
        case type
        case durationMinutes = "duration_minutes"
        case energyBurnedKcal = "energy_burned_kcal"
        case effortScore = "effort_score"
        case trainingLoadContribution = "training_load_contribution"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeNullOrRoundedDouble(durationMinutes, forKey: .durationMinutes)
        try container.encodeNullOrRoundedDouble(energyBurnedKcal, forKey: .energyBurnedKcal)
        try container.encodeNullOrRoundedDouble(effortScore, forKey: .effortScore)
        try container.encodeNullOrRoundedDouble(trainingLoadContribution, forKey: .trainingLoadContribution)
    }
}

struct ActivityAndStrainMetrics: Codable, Equatable {
    let stepCount: Int?
    let activeEnergyKcal: RoundedDouble?
    let restingEnergyKcal: RoundedDouble?
    let exerciseMinutes: RoundedDouble?
    let trainingLoadContribution: RoundedDouble?
    let workouts: [WorkoutLog]

    enum CodingKeys: String, CodingKey {
        case stepCount = "step_count"
        case activeEnergyKcal = "active_energy_kcal"
        case restingEnergyKcal = "resting_energy_kcal"
        case exerciseMinutes = "exercise_minutes"
        case trainingLoadContribution = "training_load_contribution"
        case workouts
    }

    func hasAnyValue(for inclusion: MetricInclusion) -> Bool {
        if inclusion.stepCount && stepCount != nil { return true }
        if inclusion.activeEnergy && activeEnergyKcal != nil { return true }
        if inclusion.restingEnergy && restingEnergyKcal != nil { return true }
        if inclusion.exerciseMinutes && exerciseMinutes != nil { return true }
        if inclusion.trainingLoad && trainingLoadContribution != nil { return true }
        if inclusion.workouts && !workouts.isEmpty { return true }
        return false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNullOrInt(stepCount, forKey: .stepCount)
        try container.encodeNullOrRoundedDouble(activeEnergyKcal, forKey: .activeEnergyKcal)
        try container.encodeNullOrRoundedDouble(restingEnergyKcal, forKey: .restingEnergyKcal)
        try container.encodeNullOrRoundedDouble(exerciseMinutes, forKey: .exerciseMinutes)
        try container.encodeNullOrRoundedDouble(trainingLoadContribution, forKey: .trainingLoadContribution)
        try container.encode(workouts, forKey: .workouts)
    }
}

struct BodyCompositionMetrics: Codable, Equatable {
    let bodyWeightKg: RoundedDouble?
    let bodyFatPercent: RoundedDouble?

    enum CodingKeys: String, CodingKey {
        case bodyWeightKg = "body_weight_kg"
        case bodyFatPercent = "body_fat_percent"
    }

    func hasAnyValue(for inclusion: MetricInclusion) -> Bool {
        if inclusion.weight && bodyWeightKg != nil { return true }
        if inclusion.bodyFat && bodyFatPercent != nil { return true }
        return false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNullOrRoundedDouble(bodyWeightKg, forKey: .bodyWeightKg)
        try container.encodeNullOrRoundedDouble(bodyFatPercent, forKey: .bodyFatPercent)
    }
}

extension Array where Element == DailyLog {
    func hasAnyValue(for inclusion: MetricInclusion) -> Bool {
        contains { $0.hasAnyValue(for: inclusion) }
    }
}
