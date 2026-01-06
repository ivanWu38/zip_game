import Foundation
import Combine

class DailyPuzzleService: ObservableObject {
    @Published var isTodayCompleted: Bool = false
    @Published var todayCompletionTime: TimeInterval?

    private let userDefaults = UserDefaults.standard
    private let completedDateKey = "dailyPuzzleCompletedDate"
    private let completionTimeKey = "dailyPuzzleCompletionTime"
    private let baseDate = Date(timeIntervalSince1970: 1704067200) // Jan 1, 2024

    private var timer: AnyCancellable?

    init() {
        loadTodayStatus()
        startMidnightTimer()
    }

    // MARK: - Public Properties

    var todaySeed: UInt64 {
        let days = daysSinceBase(for: Date())
        return UInt64(days)
    }

    var currentPuzzleNumber: Int {
        return daysSinceBase(for: Date()) + 1
    }

    var timeUntilNextPuzzle: String {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else {
            return "--:--:--"
        }

        let remaining = tomorrow.timeIntervalSince(Date())
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Public Methods

    func markCompleted(time: TimeInterval) {
        let todayString = dateString(for: Date())
        userDefaults.set(todayString, forKey: completedDateKey)
        userDefaults.set(time, forKey: completionTimeKey)

        isTodayCompleted = true
        todayCompletionTime = time
    }

    // MARK: - Private Methods

    private func loadTodayStatus() {
        let todayString = dateString(for: Date())

        if let savedDate = userDefaults.string(forKey: completedDateKey), savedDate == todayString {
            isTodayCompleted = true
            todayCompletionTime = userDefaults.double(forKey: completionTimeKey)
        } else {
            isTodayCompleted = false
            todayCompletionTime = nil
        }
    }

    private func startMidnightTimer() {
        // Refresh status every second to update countdown
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.checkMidnightReset()
            }
    }

    private func checkMidnightReset() {
        let todayString = dateString(for: Date())
        if let savedDate = userDefaults.string(forKey: completedDateKey), savedDate != todayString {
            isTodayCompleted = false
            todayCompletionTime = nil
        }
    }

    private func daysSinceBase(for date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: baseDate)
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
