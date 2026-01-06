import Foundation

class StorageService {
    static let shared = StorageService()

    private let userDefaults = UserDefaults.standard

    private let statsKey = "gameStats"

    private init() {}

    // MARK: - Statistics

    struct GameStats: Codable {
        var gamesPlayed: Int = 0
        var bestTimes: [String: TimeInterval] = [:] // difficulty -> best time

        mutating func recordGame(difficulty: Difficulty, time: TimeInterval) {
            gamesPlayed += 1

            let key = difficulty.rawValue
            if let currentBest = bestTimes[key] {
                if time < currentBest {
                    bestTimes[key] = time
                }
            } else {
                bestTimes[key] = time
            }
        }

        func bestTime(for difficulty: Difficulty) -> TimeInterval? {
            bestTimes[difficulty.rawValue]
        }
    }

    func loadStats() -> GameStats {
        guard let data = userDefaults.data(forKey: statsKey),
              let stats = try? JSONDecoder().decode(GameStats.self, from: data) else {
            return GameStats()
        }
        return stats
    }

    func saveStats(_ stats: GameStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        userDefaults.set(data, forKey: statsKey)
    }

    func recordGame(difficulty: Difficulty, time: TimeInterval) {
        var stats = loadStats()
        stats.recordGame(difficulty: difficulty, time: time)
        saveStats(stats)
    }
}
