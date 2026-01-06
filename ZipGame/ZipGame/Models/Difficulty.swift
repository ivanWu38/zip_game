import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var gridSize: Int {
        switch self {
        case .easy: return 6
        case .medium: return 7
        case .hard: return 8
        }
    }

    var checkpointCount: Int {
        switch self {
        case .easy: return 7
        case .medium: return 8
        case .hard: return 9
        }
    }

    var displayName: String {
        switch self {
        case .easy: return "Easy (6×6)"
        case .medium: return "Medium (7×7)"
        case .hard: return "Hard (8×8)"
        }
    }
}
