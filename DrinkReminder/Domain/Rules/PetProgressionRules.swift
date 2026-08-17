import Foundation

enum PetProgressionRules {
    static let waterLogXP = 5
    static let halfwayXP = 10
    static let dailyGoalXP = 25
    static let streakDayXP = 5
    static let xpPerLevel = 100

    static func progress(totalXP: Int) -> PetProgress {
        let safeXP = max(totalXP, 0)
        let level = safeXP / xpPerLevel + 1
        return PetProgress(
            totalXP: safeXP,
            level: level,
            evolutionStage: evolutionStage(for: level),
            xpIntoLevel: safeXP % xpPerLevel,
            xpNeededForNextLevel: xpPerLevel
        )
    }

    static func evolutionStage(for level: Int) -> EvolutionStage {
        switch level {
        case ..<5: return .baby
        case ..<10: return .growing
        case ..<20: return .evolved
        default: return .advanced
        }
    }
}
