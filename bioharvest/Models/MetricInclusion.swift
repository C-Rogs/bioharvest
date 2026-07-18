import Foundation

struct MetricInclusion: Codable, Equatable {
    var hrvToday = true
    var rhrToday = true
    var sleepTotal = true
    var sleepDeep = true
    var sleepREM = true
    var weight = true
    var bodyFat = true
    var stepCount = true
    var activeEnergy = true
    var restingEnergy = true
    var exerciseMinutes = true
    var workouts = true
    var trainingLoad = true
    var caloriesConsumed = true
    var proteinG = true
    var carbsG = true
    var fatG = true
    var waterLiters = true
    var alcoholicBeveragesCount = true

    var needsHRV: Bool { hrvToday }
    var needsRHR: Bool { rhrToday }
    var needsSleep: Bool {
        sleepTotal || sleepDeep || sleepREM
    }
    var needsBody: Bool { weight || bodyFat }
    var needsActivity: Bool {
        stepCount || activeEnergy || restingEnergy || exerciseMinutes || workouts || trainingLoad
    }
    var needsNutrition: Bool {
        caloriesConsumed || proteinG || carbsG || fatG || waterLiters || alcoholicBeveragesCount
    }

    static func load() -> MetricInclusion {
        guard let data = UserDefaults.standard.data(forKey: BioharvestStorage.metricInclusionKey),
              let decoded = try? JSONDecoder().decode(MetricInclusion.self, from: data)
        else {
            return MetricInclusion()
        }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: BioharvestStorage.metricInclusionKey)
    }
}
