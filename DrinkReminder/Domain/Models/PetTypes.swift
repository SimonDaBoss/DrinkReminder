import Foundation

enum PetSpecies: String, CaseIterable, Codable {
    case axolotl
    case otter
    case droplet
}

enum PetMood: String, CaseIterable, Codable {
    case sleeping
    case idle
    case happy
    case drinking
    case celebrating
    case thirsty
    case excited
}

enum EvolutionStage: String, CaseIterable, Codable {
    case baby
    case growing
    case evolved
    case advanced
}

enum XPAwardReason: String, Codable {
    case waterLog
    case halfway
    case dailyGoal
    case streak
}
