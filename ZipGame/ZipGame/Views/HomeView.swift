import SwiftUI

struct HomeView: View {
    @StateObject private var dailyService = DailyPuzzleService()
    @State private var selectedMode: GameMode = .daily
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var showingGame = false
    @State private var generatedPuzzle: Puzzle?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Logo/Title
                        titleSection

                        // Mode Selection
                        modeSelectionSection

                        // Difficulty Selection (for unlimited mode)
                        if selectedMode == .unlimited {
                            difficultySection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Daily puzzle info
                        if selectedMode == .daily {
                            dailyInfoSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Play Button
                        playButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 100) // Extra padding for tab bar
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingGame) {
                if let puzzle = generatedPuzzle {
                    let difficulty = selectedMode == .daily ? Difficulty.medium : selectedDifficulty
                    GameView(
                        viewModel: GameViewModel(puzzle: puzzle, mode: selectedMode, difficulty: difficulty)
                    )
                } else {
                    Text("Loading...")
                }
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: 18) {
            // Logo
            ZStack {
                Circle()
                    .fill(Color.zipPrimary.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.zipPrimary)
                    .shadow(color: Color.zipPrimary.opacity(0.5), radius: 10)
            }

            // Title
            Text("Zip")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)

            // Subtitle
            Text("Draw a path through every cell")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(Color.zipTextSecondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Game Mode")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 14) {
                ForEach(GameMode.allCases) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        dailyCompleted: mode == .daily && dailyService.isTodayCompleted
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                    }
                }
            }
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Difficulty")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 14) {
                ForEach(Difficulty.allCases) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
        }
    }

    private var dailyInfoSection: some View {
        VStack(spacing: 16) {
            if dailyService.isTodayCompleted {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.zipSuccess)

                    Text("Completed today!")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.zipSuccess)
                }

                if let time = dailyService.todayCompletionTime {
                    Text("Time: \(formatTime(time))")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.zipTextSecondary)
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                    Text("Next puzzle in \(dailyService.timeUntilNextPuzzle)")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.zipTextTertiary)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                    Text("Puzzle #\(dailyService.currentPuzzleNumber)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.zipTextSecondary)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.zipCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.zipCardBorder, lineWidth: 1)
                )
        )
    }

    private var playButton: some View {
        Button {
            startGame()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedMode == .daily && dailyService.isTodayCompleted ? "arrow.clockwise" : "play.fill")
                    .font(.system(size: 22, weight: .semibold))
                Text(selectedMode == .daily && dailyService.isTodayCompleted ? "Play Again" : "Play")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(LinearGradient.zipButtonGradient)
            .cornerRadius(18)
            .shadow(color: Color.zipPrimary.opacity(0.4), radius: 15, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, 8)
    }

    private func startGame() {
        let difficulty = selectedMode == .daily ? Difficulty.medium : selectedDifficulty
        let puzzle: Puzzle

        if selectedMode == .daily {
            let seed = dailyService.todaySeed
            let generator = PuzzleGenerator(difficulty: difficulty, seed: seed)
            puzzle = generator.generate()
        } else {
            let generator = PuzzleGenerator(difficulty: difficulty)
            puzzle = generator.generate()
        }

        generatedPuzzle = puzzle
        showingGame = true
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ModeCard: View {
    let mode: GameMode
    let isSelected: Bool
    let dailyCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.zipPrimary : Color.zipCardBackground)
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.clear : Color.zipCardBorder, lineWidth: 1)
                        )

                    Image(systemName: mode.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : Color.zipTextSecondary)
                }

                // Text content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Text(mode.rawValue)
                            .font(.system(size: 21, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)

                        if dailyCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.zipSuccess)
                        }
                    }

                    Text(mode.description)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.zipTextTertiary)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.zipPrimary : Color.zipCardBorder, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Circle()
                            .fill(Color.zipPrimary)
                            .frame(width: 18, height: 18)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Color.zipPrimary.opacity(0.5) : Color.zipCardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct DifficultyButton: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(difficulty.rawValue)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : Color.zipTextSecondary)

                Text("\(difficulty.gridSize)×\(difficulty.gridSize)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : Color.zipTextTertiary)
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.zipPrimary.opacity(0.3) : Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.zipPrimary.opacity(0.6) : Color.zipCardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    HomeView()
}
