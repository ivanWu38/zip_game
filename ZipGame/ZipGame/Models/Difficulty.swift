import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var gridSize: Int {
        switch self {
        case .easy: return 5
        case .medium: return 7
        case .hard: return 9
        }
    }

    var checkpointCount: Int {
        switch self {
        case .easy: return 5
        case .medium: return 6
        case .hard: return 7
        }
    }

    var displayName: String {
        switch self {
        case .easy: return "Easy (5×5)"
        case .medium: return "Medium (7×7)"
        case .hard: return "Hard (9×9)"
        }
    }
}
