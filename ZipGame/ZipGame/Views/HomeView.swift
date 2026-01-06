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
                    VStack(spacing: 28) {
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
                    .padding(.top, 20)
                    .padding(.bottom, 40)
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
        VStack(spacing: 16) {
            // Logo
            ZStack {
                Circle()
                    .fill(Color.zipPrimary.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.zipPrimary)
                    .shadow(color: Color.zipPrimary.opacity(0.5), radius: 10)
            }

            // Title
            Text("Zip")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Subtitle
            Text("Draw a path through every cell")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 30)
        .padding(.bottom, 10)
    }

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Game Mode")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 14) {
            Text("Difficulty")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 12) {
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
        VStack(spacing: 14) {
            if dailyService.isTodayCompleted {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.zipSuccess)

                    Text("Completed today!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.zipSuccess)
                }

                if let time = dailyService.todayCompletionTime {
                    Text("Time: \(formatTime(time))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Next puzzle in \(dailyService.timeUntilNextPuzzle)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.4))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                    Text("Puzzle #\(dailyService.currentPuzzleNumber)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var playButton: some View {
        Button {
            startGame()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: selectedMode == .daily && dailyService.isTodayCompleted ? "arrow.clockwise" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text(selectedMode == .daily && dailyService.isTodayCompleted ? "Play Again" : "Play")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(LinearGradient.zipButtonGradient)
            .cornerRadius(16)
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
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.zipPrimary : Color.white.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: mode.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(mode.rawValue)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        if dailyCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.zipSuccess)
                        }
                    }

                    Text(mode.description)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.zipPrimary : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.zipPrimary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.zipPrimary.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
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
            VStack(spacing: 6) {
                Text(difficulty.rawValue)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                Text("\(difficulty.gridSize)×\(difficulty.gridSize)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .white.opacity(0.4))
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.zipPrimary.opacity(0.3) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.zipPrimary.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    HomeView()
}
