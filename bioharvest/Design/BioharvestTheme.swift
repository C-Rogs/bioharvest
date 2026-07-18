import SwiftUI

enum BioharvestTheme {
    static let harvestGreen = Color(red: 0.18, green: 0.65, blue: 0.35)
    static let forestDeep = Color(red: 0.08, green: 0.32, blue: 0.22)
    static let leafMint = Color(red: 0.45, green: 0.88, blue: 0.62)
    static let warmCream = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let duskTeal = Color(red: 0.12, green: 0.48, blue: 0.52)

    static let cardCornerRadius: CGFloat = 18
    static let chipCornerRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 20

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [forestDeep, harvestGreen, duskTeal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                harvestGreen.opacity(0.08),
                Color.clear,
                duskTeal.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [harvestGreen, forestDeep],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var coachButtonGradient: LinearGradient {
        LinearGradient(
            colors: [duskTeal, forestDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum MetricCategory: String, CaseIterable, Identifiable {
    case cardiovascular
    case sleep
    case body
    case activity
    case nutrition

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cardiovascular: return "Cardiovascular"
        case .sleep: return "Sleep"
        case .body: return "Body"
        case .activity: return "Activity & Energy"
        case .nutrition: return "Nutrition"
        }
    }

    var icon: String {
        switch self {
        case .cardiovascular: return "heart.fill"
        case .sleep: return "moon.zzz.fill"
        case .body: return "figure.stand"
        case .activity: return "flame.fill"
        case .nutrition: return "leaf.fill"
        }
    }

    var accent: Color {
        switch self {
        case .cardiovascular: return Color(red: 0.92, green: 0.28, blue: 0.35)
        case .sleep: return Color(red: 0.45, green: 0.38, blue: 0.92)
        case .body: return Color(red: 0.25, green: 0.62, blue: 0.88)
        case .activity: return Color(red: 0.95, green: 0.55, blue: 0.18)
        case .nutrition: return BioharvestTheme.harvestGreen
        }
    }

    var metrics: [(key: MetricKey, title: String)] {
        switch self {
        case .cardiovascular:
            return [(.hrv, "HRV"), (.rhr, "RHR")]
        case .sleep:
            return [(.sleepTotal, "Total Sleep"), (.sleepDeep, "Deep Sleep"), (.sleepREM, "REM Sleep")]
        case .body:
            return [(.weight, "Weight"), (.bodyFat, "Body Fat")]
        case .activity:
            return [
                (.stepCount, "Step Count"),
                (.activeEnergy, "Active Energy"),
                (.restingEnergy, "Resting Energy"),
                (.exerciseMinutes, "Exercise Minutes"),
                (.workouts, "Workouts"),
                (.trainingLoad, "Training Load")
            ]
        case .nutrition:
            return [
                (.caloriesConsumed, "Calories (kcal)"),
                (.proteinG, "Protein (g)"),
                (.carbsG, "Carbs (g)"),
                (.fatG, "Fat (g)"),
                (.waterLiters, "Water (liters)"),
                (.alcoholicBeveragesCount, "Alcoholic Beverages")
            ]
        }
    }
}

extension MetricKey {
    var category: MetricCategory {
        switch self {
        case .hrv, .rhr: return .cardiovascular
        case .sleepTotal, .sleepDeep, .sleepREM: return .sleep
        case .weight, .bodyFat: return .body
        case .stepCount, .activeEnergy, .restingEnergy, .exerciseMinutes, .workouts, .trainingLoad:
            return .activity
        case .caloriesConsumed, .proteinG, .carbsG, .fatG, .waterLiters, .alcoholicBeveragesCount:
            return .nutrition
        }
    }
}
