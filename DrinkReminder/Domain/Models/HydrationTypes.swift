import Foundation

enum VolumeUnit: String, CaseIterable, Codable {
    case milliliters
    case ounces

    var symbol: String {
        switch self {
        case .milliliters: return "mL"
        case .ounces: return "oz"
        }
    }
}

enum WaterLogSource: String, Codable {
    case quickAdd
    case custom
    case preset
    case notification
}

struct HydrationSummary: Equatable {
    let dayIdentifier: String
    let totalML: Double
    let goalML: Double
    let goalReachedAt: Date?

    var progress: Double {
        guard goalML > 0 else { return 0 }
        return min(totalML / goalML, 1)
    }

    var isGoalReached: Bool {
        goalReachedAt != nil || totalML >= goalML
    }
}

struct HydrationLogResult: Equatable {
    let summary: HydrationSummary
    let loggedAmountML: Double
    let crossedHalfway: Bool
    let reachedGoal: Bool
}
