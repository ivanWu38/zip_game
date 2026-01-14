import SwiftUI

struct PracticeView: View {
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var currentPuzzle: Puzzle?
    @State private var gameViewModel: GameViewModel?
    @State private var showingGame = false
    @State private var puzzleKey = UUID()
    @ObservedObject private var localization = LocalizationService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                if let viewModel = gameViewModel {
                    // Game View
                    VStack(spacing: 0) {
                        // Header with difficulty selector
                        practiceHeader

                        // Game content
                        PracticeGameContent(viewModel: viewModel, onNewPuzzle: generateNewPuzzle)
                            .id(puzzleKey)
                    }
                } else {
                    // Initial state - show difficulty selection
                    initialView
                }
            }
            .navigationTitle("practice.title".localized)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if gameViewModel == nil {
                generateNewPuzzle()
            }
        }
    }

    private var initialView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.zipPrimary.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "infinity")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.zipPrimary)
            }

            VStack(spacing: 12) {
                Text("practice.title".localized)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zipTextPrimary)

                Text("practice.subtitle".localized)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.zipTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Difficulty Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("practice.selectDifficulty".localized)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.zipTextTertiary)
                    .textCase(.uppercase)
                    .tracking(1)

                HStack(spacing: 14) {
                    ForEach(Difficulty.allCases) { difficulty in
                        DifficultyCard(
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
            .padding(.horizontal, 24)

            // Start Button
            Button {
                generateNewPuzzle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("practice.startPractice".localized)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(LinearGradient.zipButtonGradient)
                .cornerRadius(18)
                .shadow(color: Color.zipPrimary.opacity(0.4), radius: 15, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var practiceHeader: some View {
        VStack(spacing: 12) {
            // Difficulty selector pills
            HStack(spacing: 10) {
                ForEach(Difficulty.allCases) { difficulty in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDifficulty = difficulty
                            generateNewPuzzle()
                        }
                    } label: {
                        Text(difficulty.localizedName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedDifficulty == difficulty ? .white : Color.zipTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedDifficulty == difficulty ? Color.zipPrimary : Color.zipCardBackground)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedDifficulty == difficulty ? Color.clear : Color.zipCardBorder, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }

    private func generateNewPuzzle() {
        let generator = PuzzleGenerator(difficulty: selectedDifficulty)
        let puzzle = generator.generate()
        currentPuzzle = puzzle
        gameViewModel = GameViewModel(puzzle: puzzle, mode: .unlimited, difficulty: selectedDifficulty)
        puzzleKey = UUID()
    }
}

// MARK: - Practice Game Content
struct PracticeGameContent: View {
    @ObservedObject var viewModel: GameViewModel
    let onNewPuzzle: () -> Void
    @State private var showConfetti = false

    var body: some View {
        GeometryReader { geometry in
            let cellSize = calculateCellSize(for: geometry.size)

            ZStack {
                VStack(spacing: 12) {
                    // Compact Timer
                    Text(viewModel.formattedTime)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.zipTextPrimary)
                        .monospacedDigit()

                    // Grid - more vertical space
                    GridView(viewModel: viewModel, cellSize: cellSize)
                        .frame(height: CGFloat(viewModel.puzzle.size) * cellSize + CGFloat(viewModel.puzzle.size - 1) * 6 + 20)
                        .padding(.vertical, 8)

                    // Compact Progress + Button row
                    compactProgressView

                    // New Puzzle Button
                    Button {
                        onNewPuzzle()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("practice.newPuzzle".localized)
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.zipPrimary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.zipCardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.zipCardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // Ad space placeholder
                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)

                // Confetti
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }

                // Completion overlay
                if viewModel.gameState.isCompleted {
                    completionOverlay
                }
            }
        }
        .onChange(of: viewModel.gameState) { newState in
            if newState.isCompleted {
                showConfetti = true
                // Show interstitial ad
                AdMobManager.shared.onGameCompleted()
            }
        }
    }

    private var compactProgressView: some View {
        HStack(spacing: 12) {
            // Progress text
            Text("\(viewModel.currentPath.count)/\(viewModel.puzzle.totalCells)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)
                .monospacedDigit()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.zipCardBackground)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient.zipButtonGradient)
                        .frame(width: geo.size.width * progressPercentage)
                        .animation(.spring(response: 0.3), value: viewModel.currentPath.count)
                }
            }
            .frame(height: 6)

            // Percentage
            Text("\(Int(progressPercentage * 100))%")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipPrimary)
                .frame(width: 45, alignment: .trailing)
        }
    }

    private var progressPercentage: CGFloat {
        guard viewModel.puzzle.totalCells > 0 else { return 0 }
        return CGFloat(viewModel.currentPath.count) / CGFloat(viewModel.puzzle.totalCells)
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Trophy
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.zipGold.opacity(0.3), Color.zipGold.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.zipGold)
                }

                Text("game.complete.title".localized)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zipTextPrimary)

                if case .completed(let time) = viewModel.gameState {
                    VStack(spacing: 6) {
                        Text("game.complete.yourTime".localized)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextTertiary)
                        Text(formatTime(time))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)
                            .monospacedDigit()
                    }
                }

                Button {
                    showConfetti = false
                    onNewPuzzle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                        Text("practice.newPuzzle".localized)
                    }
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LinearGradient.zipButtonGradient)
                    .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.zipBackgroundEnd)
                    .shadow(color: .black.opacity(0.5), radius: 30)
            )
            .padding(32)
        }
    }

    private func calculateCellSize(for size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return 50 }

        let puzzleSize = viewModel.puzzle.size
        let spacing: CGFloat = 6
        let padding: CGFloat = 24
        let maxWidth = size.width - padding
        // More vertical space for grid (55% of available height)
        let maxHeight = size.height * 0.55

        let cellSizeFromWidth = (maxWidth - CGFloat(puzzleSize - 1) * spacing) / CGFloat(puzzleSize)
        let cellSizeFromHeight = (maxHeight - CGFloat(puzzleSize - 1) * spacing) / CGFloat(puzzleSize)

        return max(min(cellSizeFromWidth, cellSizeFromHeight, 75), 30)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Difficulty Card
struct DifficultyCard: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(difficulty.localizedName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : Color.zipTextSecondary)

                Text("\(difficulty.gridSize)×\(difficulty.gridSize)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : Color.zipTextTertiary)
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.zipPrimary : Color.zipCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.zipCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    PracticeView()
}
