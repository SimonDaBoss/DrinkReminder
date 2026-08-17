import Foundation

struct StreakStatistics: Equatable {
    let current: Int
    let longest: Int
    let successfulDays: Int

    static let empty = StreakStatistics(current: 0, longest: 0, successfulDays: 0)
}

struct PetProgress: Equatable {
    let totalXP: Int
    let level: Int
    let evolutionStage: EvolutionStage
    let xpIntoLevel: Int
    let xpNeededForNextLevel: Int

    var levelProgress: Double {
        guard xpNeededForNextLevel > 0 else { return 1 }
        return min(max(Double(xpIntoLevel) / Double(xpNeededForNextLevel), 0), 1)
    }
}

struct ProgressionSnapshot: Equatable {
    let streak: StreakStatistics
    let pet: PetProgress
}

struct ProgressionUpdate: Equatable {
    let snapshot: ProgressionSnapshot
    let earnedXP: Int
}
