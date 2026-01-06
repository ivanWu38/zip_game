import SwiftUI

struct JourneyView: View {
    @ObservedObject var statsService = StatsService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Streak Cards
                        streakSection

                        // Statistics Section
                        statisticsSection

                        // Best Times Section
                        bestTimesSection

                        // Achievements Section
                        achievementsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 100) // Extra padding for tab bar
                }
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Streak Section
    private var streakSection: some View {
        HStack(spacing: 16) {
            // Current Streak
            StreakCard(
                value: statsService.currentStreak,
                label: "Current streak",
                icon: "flame.fill",
                iconColor: .orange
            )

            // Longest Streak
            StreakCard(
                value: statsService.longestStreak,
                label: "Longest streak",
                icon: "trophy.fill",
                iconColor: .yellow
            )
        }
    }

    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Statistics")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 0) {
                StatRow(icon: "checkmark.circle.fill", label: "Total Completed", value: "\(statsService.totalPuzzlesCompleted)")
                Divider().background(Color.zipCardBorder)
                StatRow(icon: "clock.fill", label: "Total Play Time", value: statsService.formatTotalTime())
                Divider().background(Color.zipCardBorder)
                StatRow(icon: "square.grid.3x3.fill", label: "Easy Completed", value: "\(statsService.completedEasy)")
                Divider().background(Color.zipCardBorder)
                StatRow(icon: "square.grid.3x3.fill", label: "Medium Completed", value: "\(statsService.completedMedium)")
                Divider().background(Color.zipCardBorder)
                StatRow(icon: "square.grid.3x3.fill", label: "Hard Completed", value: "\(statsService.completedHard)")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.zipCardBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Best Times Section
    private var bestTimesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Best Times")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 12) {
                BestTimeCard(difficulty: "Easy", time: statsService.formatTime(statsService.bestTimeEasy), color: .green)
                BestTimeCard(difficulty: "Medium", time: statsService.formatTime(statsService.bestTimeMedium), color: .orange)
                BestTimeCard(difficulty: "Hard", time: statsService.formatTime(statsService.bestTimeHard), color: .red)
            }
        }
    }

    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.zipTextTertiary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Text("\(statsService.achievements.count)/\(statsService.allAchievements.count)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.zipPrimary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(statsService.allAchievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let value: Int
    let label: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 64, height: 64)

                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(iconColor)
            }

            // Value
            Text("\(value)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)

            // Label
            Text(value == 1 ? label.replacingOccurrences(of: "streak", with: "day") : label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.zipTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.zipCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.zipCardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.zipPrimary)
                .frame(width: 28)

            Text(label)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Best Time Card
struct BestTimeCard: View {
    let difficulty: String
    let time: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(difficulty)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(color)

            Text(time)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.zipCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.2) : Color.zipCardBackground)
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(achievement.isUnlocked ? achievement.color : Color.zipTextTertiary)
            }

            Text(achievement.title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(achievement.isUnlocked ? Color.zipTextPrimary : Color.zipTextTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 36)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.zipCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.zipCardBorder, lineWidth: 1)
                )
        )
    }
}

#Preview {
    JourneyView()
}
