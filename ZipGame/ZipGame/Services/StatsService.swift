import Foundation
import SwiftUI

class StatsService: ObservableObject {
    static let shared = StatsService()

    private let defaults = UserDefaults.standard

    // MARK: - Published Properties
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalPuzzlesCompleted: Int = 0
    @Published var totalPlayTime: TimeInterval = 0

    // Best times per difficulty
    @Published var bestTimeEasy: TimeInterval?
    @Published var bestTimeMedium: TimeInterval?
    @Published var bestTimeHard: TimeInterval?

    // Completion counts per difficulty
    @Published var completedEasy: Int = 0
    @Published var completedMedium: Int = 0
    @Published var completedHard: Int = 0

    // Daily tracking
    @Published var lastPlayedDate: Date?
    @Published var completedDates: Set<String> = []

    // MARK: - Keys
    private enum Keys {
        static let currentStreak = "zip_currentStreak"
        static let longestStreak = "zip_longestStreak"
        static let totalPuzzlesCompleted = "zip_totalPuzzlesCompleted"
        static let totalPlayTime = "zip_totalPlayTime"
        static let bestTimeEasy = "zip_bestTimeEasy"
        static let bestTimeMedium = "zip_bestTimeMedium"
        static let bestTimeHard = "zip_bestTimeHard"
        static let completedEasy = "zip_completedEasy"
        static let completedMedium = "zip_completedMedium"
        static let completedHard = "zip_completedHard"
        static let lastPlayedDate = "zip_lastPlayedDate"
        static let completedDates = "zip_completedDates"
    }

    // MARK: - Initialization
    private init() {
        loadStats()
        checkStreakContinuity()
    }

    // MARK: - Load/Save
    private func loadStats() {
        currentStreak = defaults.integer(forKey: Keys.currentStreak)
        longestStreak = defaults.integer(forKey: Keys.longestStreak)
        totalPuzzlesCompleted = defaults.integer(forKey: Keys.totalPuzzlesCompleted)
        totalPlayTime = defaults.double(forKey: Keys.totalPlayTime)

        if defaults.object(forKey: Keys.bestTimeEasy) != nil {
            bestTimeEasy = defaults.double(forKey: Keys.bestTimeEasy)
        }
        if defaults.object(forKey: Keys.bestTimeMedium) != nil {
            bestTimeMedium = defaults.double(forKey: Keys.bestTimeMedium)
        }
        if defaults.object(forKey: Keys.bestTimeHard) != nil {
            bestTimeHard = defaults.double(forKey: Keys.bestTimeHard)
        }

        completedEasy = defaults.integer(forKey: Keys.completedEasy)
        completedMedium = defaults.integer(forKey: Keys.completedMedium)
        completedHard = defaults.integer(forKey: Keys.completedHard)

        if let date = defaults.object(forKey: Keys.lastPlayedDate) as? Date {
            lastPlayedDate = date
        }

        if let dates = defaults.array(forKey: Keys.completedDates) as? [String] {
            completedDates = Set(dates)
        }
    }

    private func saveStats() {
        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(longestStreak, forKey: Keys.longestStreak)
        defaults.set(totalPuzzlesCompleted, forKey: Keys.totalPuzzlesCompleted)
        defaults.set(totalPlayTime, forKey: Keys.totalPlayTime)

        if let time = bestTimeEasy {
            defaults.set(time, forKey: Keys.bestTimeEasy)
        }
        if let time = bestTimeMedium {
            defaults.set(time, forKey: Keys.bestTimeMedium)
        }
        if let time = bestTimeHard {
            defaults.set(time, forKey: Keys.bestTimeHard)
        }

        defaults.set(completedEasy, forKey: Keys.completedEasy)
        defaults.set(completedMedium, forKey: Keys.completedMedium)
        defaults.set(completedHard, forKey: Keys.completedHard)

        defaults.set(lastPlayedDate, forKey: Keys.lastPlayedDate)
        defaults.set(Array(completedDates), forKey: Keys.completedDates)
    }

    // MARK: - Streak Management
    private func checkStreakContinuity() {
        guard let lastPlayed = lastPlayedDate else {
            currentStreak = 0
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastPlayedDay = calendar.startOfDay(for: lastPlayed)

        let daysDifference = calendar.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0

        // If more than 1 day has passed, reset streak
        if daysDifference > 1 {
            currentStreak = 0
            saveStats()
        }
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Record Completion
    func recordCompletion(difficulty: Difficulty, time: TimeInterval, isDaily: Bool) {
        let today = Date()
        let todayString = dateString(for: today)

        // Update totals
        totalPuzzlesCompleted += 1
        totalPlayTime += time

        // Update difficulty-specific stats
        switch difficulty {
        case .easy:
            completedEasy += 1
            if bestTimeEasy == nil || time < bestTimeEasy! {
                bestTimeEasy = time
            }
        case .medium:
            completedMedium += 1
            if bestTimeMedium == nil || time < bestTimeMedium! {
                bestTimeMedium = time
            }
        case .hard:
            completedHard += 1
            if bestTimeHard == nil || time < bestTimeHard! {
                bestTimeHard = time
            }
        }

        // Update streak (only for daily puzzles)
        if isDaily && !completedDates.contains(todayString) {
            completedDates.insert(todayString)

            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: today)

            if let lastPlayed = lastPlayedDate {
                let lastPlayedStart = calendar.startOfDay(for: lastPlayed)
                let daysDifference = calendar.dateComponents([.day], from: lastPlayedStart, to: todayStart).day ?? 0

                if daysDifference == 1 {
                    // Consecutive day
                    currentStreak += 1
                } else if daysDifference == 0 {
                    // Same day, streak unchanged
                } else {
                    // Streak broken, start new
                    currentStreak = 1
                }
            } else {
                // First time playing
                currentStreak = 1
            }

            // Update longest streak
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }

            lastPlayedDate = today
        }

        saveStats()
    }

    // MARK: - Formatted Strings
    func formatTime(_ time: TimeInterval?) -> String {
        guard let time = time else { return "—" }  // Em-dash for no record
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func formatTotalTime() -> String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Achievements
    var achievements: [Achievement] {
        var list: [Achievement] = []

        // Streak achievements
        if currentStreak >= 3 {
            list.append(Achievement(id: "streak_3", title: "3 Day Streak", icon: "flame.fill", color: .orange, isUnlocked: true))
        }
        if currentStreak >= 7 {
            list.append(Achievement(id: "streak_7", title: "Week Warrior", icon: "flame.fill", color: .red, isUnlocked: true))
        }
        if currentStreak >= 30 {
            list.append(Achievement(id: "streak_30", title: "Monthly Master", icon: "flame.fill", color: .purple, isUnlocked: true))
        }

        // Completion achievements
        if totalPuzzlesCompleted >= 10 {
            list.append(Achievement(id: "complete_10", title: "Puzzle Novice", icon: "puzzlepiece.fill", color: .blue, isUnlocked: true))
        }
        if totalPuzzlesCompleted >= 50 {
            list.append(Achievement(id: "complete_50", title: "Puzzle Expert", icon: "puzzlepiece.fill", color: .green, isUnlocked: true))
        }
        if totalPuzzlesCompleted >= 100 {
            list.append(Achievement(id: "complete_100", title: "Puzzle Master", icon: "crown.fill", color: .yellow, isUnlocked: true))
        }

        // Difficulty achievements
        if completedHard >= 10 {
            list.append(Achievement(id: "hard_10", title: "Hard Mode Hero", icon: "star.fill", color: .pink, isUnlocked: true))
        }

        // Speed achievements
        if let easy = bestTimeEasy, easy < 30 {
            list.append(Achievement(id: "speed_easy", title: "Speed Demon (Easy)", icon: "bolt.fill", color: .cyan, isUnlocked: true))
        }
        if let medium = bestTimeMedium, medium < 60 {
            list.append(Achievement(id: "speed_medium", title: "Speed Demon (Medium)", icon: "bolt.fill", color: .mint, isUnlocked: true))
        }

        return list
    }

    // All possible achievements (for showing locked ones)
    var allAchievements: [Achievement] {
        return [
            Achievement(id: "streak_3", title: "3 Day Streak", icon: "flame.fill", color: .orange, isUnlocked: currentStreak >= 3),
            Achievement(id: "streak_7", title: "Week Warrior", icon: "flame.fill", color: .red, isUnlocked: currentStreak >= 7),
            Achievement(id: "streak_30", title: "Monthly Master", icon: "flame.fill", color: .purple, isUnlocked: longestStreak >= 30),
            Achievement(id: "complete_10", title: "Puzzle Novice", icon: "puzzlepiece.fill", color: .blue, isUnlocked: totalPuzzlesCompleted >= 10),
            Achievement(id: "complete_50", title: "Puzzle Expert", icon: "puzzlepiece.fill", color: .green, isUnlocked: totalPuzzlesCompleted >= 50),
            Achievement(id: "complete_100", title: "Puzzle Master", icon: "crown.fill", color: .yellow, isUnlocked: totalPuzzlesCompleted >= 100),
            Achievement(id: "hard_10", title: "Hard Mode Hero", icon: "star.fill", color: .pink, isUnlocked: completedHard >= 10),
            Achievement(id: "speed_easy", title: "Speed Demon (Easy)", icon: "bolt.fill", color: .cyan, isUnlocked: bestTimeEasy != nil && bestTimeEasy! < 30),
            Achievement(id: "speed_medium", title: "Speed Demon (Medium)", icon: "bolt.fill", color: .mint, isUnlocked: bestTimeMedium != nil && bestTimeMedium! < 60),
        ]
    }

    // MARK: - Reset
    func resetAllStats() {
        currentStreak = 0
        longestStreak = 0
        totalPuzzlesCompleted = 0
        totalPlayTime = 0
        bestTimeEasy = nil
        bestTimeMedium = nil
        bestTimeHard = nil
        completedEasy = 0
        completedMedium = 0
        completedHard = 0
        lastPlayedDate = nil
        completedDates = []

        // Clear UserDefaults
        let keys = [
            Keys.currentStreak, Keys.longestStreak, Keys.totalPuzzlesCompleted,
            Keys.totalPlayTime, Keys.bestTimeEasy, Keys.bestTimeMedium,
            Keys.bestTimeHard, Keys.completedEasy, Keys.completedMedium,
            Keys.completedHard, Keys.lastPlayedDate, Keys.completedDates
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}
