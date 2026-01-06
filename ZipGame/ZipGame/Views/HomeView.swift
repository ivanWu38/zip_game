import SwiftUI

struct HomeView: View {
    @StateObject private var dailyService = DailyPuzzleService()
    @State private var selectedMode: GameMode = .daily
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var showingGame = false
    @State private var generatedPuzzle: Puzzle?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo/Title
                    titleSection

                    // Mode Selection
                    modeSelectionSection

                    // Difficulty Selection (for unlimited mode)
                    if selectedMode == .unlimited {
                        difficultySection
                    }

                    // Daily puzzle info
                    if selectedMode == .daily {
                        dailyInfoSection
                    }

                    // Play Button
                    playButton
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Zip")
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
        VStack(spacing: 8) {
            Image(systemName: "line.diagonal")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
                .rotationEffect(.degrees(45))

            Text("Draw a path through every cell")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Mode")
                .font(.headline)
                .foregroundStyle(.primary)

            ForEach(GameMode.allCases) { mode in
                ModeCard(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    dailyCompleted: mode == .daily && dailyService.isTodayCompleted
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMode = mode
                    }
                }
            }
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                ForEach(Difficulty.allCases) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
        }
    }

    private var dailyInfoSection: some View {
        VStack(spacing: 8) {
            if dailyService.isTodayCompleted {
                Label("Completed today!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                if let time = dailyService.todayCompletionTime {
                    Text("Time: \(formatTime(time))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Next puzzle in \(dailyService.timeUntilNextPuzzle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Puzzle #\(dailyService.currentPuzzleNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var playButton: some View {
        Button {
            startGame()
        } label: {
            HStack {
                Image(systemName: selectedMode == .daily && dailyService.isTodayCompleted ? "arrow.clockwise" : "play.fill")
                Text(selectedMode == .daily && dailyService.isTodayCompleted ? "Play Again" : "Play")
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
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
            HStack {
                Image(systemName: mode.iconName)
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.rawValue)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if dailyCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }

                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DifficultyButton: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(difficulty.rawValue)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(difficulty.gridSize)×\(difficulty.gridSize)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
