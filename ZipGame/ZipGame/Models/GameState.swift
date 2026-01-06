import Foundation

enum GameState: Equatable {
    case ready
    case playing
    case completed(time: TimeInterval)

    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }

    var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }
}

enum GameMode: String, CaseIterable, Identifiable {
    case daily = "Daily Puzzle"
    case unlimited = "Unlimited"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .daily:
            return "One new puzzle every day"
        case .unlimited:
            return "Practice with unlimited puzzles"
        }
    }

    var iconName: String {
        switch self {
        case .daily: return "calendar"
        case .unlimited: return "infinity"
        }
    }
}
