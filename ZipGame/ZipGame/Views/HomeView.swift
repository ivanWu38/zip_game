import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var dailyService = DailyPuzzleService()
    @StateObject private var viewModel: DailyGameViewModel
    @State private var showConfetti = false
    @State private var isReplaying = false

    init() {
        _viewModel = StateObject(wrappedValue: DailyGameViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                if dailyService.isTodayCompleted && !isReplaying {
                    // Show completion view
                    completedView
                } else {
                    // Show game view
                    gameView
                }

                // Confetti
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadDailyPuzzle(service: dailyService)
        }
        .onChange(of: viewModel.gameState) { newState in
            if newState.isCompleted && !isReplaying {
                showConfetti = true
                if let time = viewModel.completionTime {
                    dailyService.markCompleted(time: time)
                }
            }
        }
    }

    // MARK: - Game View
    private var gameView: some View {
        GeometryReader { geometry in
            let cellSize = calculateCellSize(for: geometry.size, puzzleSize: viewModel.puzzle?.size ?? 5)

            ZStack {
                VStack(spacing: 10) {
                    // Compact Header
                    compactDailyHeader

                    // Grid - more vertical space
                    if let puzzle = viewModel.puzzle, let gameVM = viewModel.gameViewModel {
                        GridView(viewModel: gameVM, cellSize: cellSize)
                            .frame(height: CGFloat(puzzle.size) * cellSize + CGFloat(puzzle.size - 1) * 6 + 20)
                            .padding(.vertical, 8)
                    } else {
                        ProgressView()
                            .scaleEffect(1.5)
                    }

                    // Compact Progress
                    if let gameVM = viewModel.gameViewModel {
                        compactProgressView(gameVM: gameVM)
                    }

                    // Instructions or replay indicator (compact)
                    if isReplaying {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                            Text("Replay Mode")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(Color.zipTextTertiary)
                    } else if viewModel.gameViewModel?.gameState == .ready {
                        compactInstructionsView
                    }

                    // Ad space placeholder
                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)

                // Completion overlay for game
                if viewModel.gameState.isCompleted {
                    gameCompletionOverlay
                }
            }
        }
    }

    // MARK: - Completed View (After daily is done)
    private var completedView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.zipSuccess.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.zipSuccess)
                }

                // Title
                VStack(spacing: 8) {
                    Text("Daily Complete!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.zipTextPrimary)

                    Text("Puzzle #\(dailyService.currentPuzzleNumber)")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.zipTextSecondary)
                }

                // Stats Card
                VStack(spacing: 20) {
                    // Time
                    if let time = dailyService.todayCompletionTime {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.zipPrimary)

                            Text("Your Time")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.zipTextSecondary)

                            Spacer()

                            Text(formatTime(time))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.zipTextPrimary)
                                .monospacedDigit()
                        }
                    }

                    Divider().background(Color.zipCardBorder)

                    // Difficulty
                    HStack {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.zipPrimary)

                        Text("Difficulty")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextSecondary)

                        Spacer()

                        Text(dailyService.todayDifficulty.displayName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)
                    }

                    Divider().background(Color.zipCardBorder)

                    // Streak
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.orange)

                        Text("Current Streak")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextSecondary)

                        Spacer()

                        Text("\(StatsService.shared.currentStreak) days")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.zipCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.zipCardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)

                // Next Puzzle Countdown
                VStack(spacing: 12) {
                    Text("Next puzzle in")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.zipTextTertiary)

                    Text(dailyService.timeUntilNextPuzzle)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.zipTextPrimary)
                        .monospacedDigit()
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
                .padding(.horizontal, 24)

                // Replay Button
                Button {
                    isReplaying = true
                    viewModel.resetForReplay()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                        Text("Play Again")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.zipPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.zipCardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.zipPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)

                Spacer().frame(height: 100)
            }
        }
    }

    // MARK: - Compact Daily Header
    private var compactDailyHeader: some View {
        HStack {
            // Puzzle info badge
            HStack(spacing: 6) {
                Text("#\(dailyService.currentPuzzleNumber)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text("•")
                Text(dailyService.todayDifficulty.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color.zipTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.zipCardBackground)
            )

            Spacer()

            // Timer - use viewModel.formattedTime for proper updates
            Text(viewModel.formattedTime)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)
                .monospacedDigit()
        }
    }

    // MARK: - Compact Progress View
    private func compactProgressView(gameVM: GameViewModel) -> some View {
        HStack(spacing: 12) {
            // Progress text
            Text("\(gameVM.currentPath.count)/\(gameVM.puzzle.totalCells)")
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
                        .frame(width: geo.size.width * progressPercentage(gameVM: gameVM))
                        .animation(.spring(response: 0.3), value: gameVM.currentPath.count)
                }
            }
            .frame(height: 6)

            // Percentage
            Text("\(Int(progressPercentage(gameVM: gameVM) * 100))%")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipPrimary)
                .frame(width: 45, alignment: .trailing)
        }
    }

    private func progressPercentage(gameVM: GameViewModel) -> CGFloat {
        guard gameVM.puzzle.totalCells > 0 else { return 0 }
        return CGFloat(gameVM.currentPath.count) / CGFloat(gameVM.puzzle.totalCells)
    }

    // MARK: - Compact Instructions
    private var compactInstructionsView: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw")
                .font(.system(size: 14))
            Text("Start at 1, connect in order")
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        .foregroundStyle(Color.zipTextTertiary)
    }

    // MARK: - Game Completion Overlay
    private var gameCompletionOverlay: some View {
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

                Text(isReplaying ? "Replay Complete!" : "Daily Complete!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zipTextPrimary)

                if let time = viewModel.completionTime {
                    VStack(spacing: 6) {
                        Text("Your Time")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextTertiary)
                        Text(formatTime(time))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)
                            .monospacedDigit()
                    }
                }

                if isReplaying {
                    Button {
                        showConfetti = false
                        viewModel.resetForReplay()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Play Again")
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.zipButtonGradient)
                        .cornerRadius(14)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        showConfetti = false
                        isReplaying = false
                    } label: {
                        Text("Back to Summary")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextSecondary)
                    }
                } else {
                    Button {
                        showConfetti = false
                    } label: {
                        Text("View Summary")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(LinearGradient.zipButtonGradient)
                            .cornerRadius(14)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
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

    // MARK: - Helpers
    private func calculateCellSize(for size: CGSize, puzzleSize: Int) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return 50 }

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

// MARK: - Daily Game ViewModel
class DailyGameViewModel: ObservableObject {
    @Published var puzzle: Puzzle?
    @Published var gameViewModel: GameViewModel?
    @Published var gameState: GameState = .ready
    @Published var formattedTime: String = "0:00.0"

    var completionTime: TimeInterval? {
        if case .completed(let time) = gameViewModel?.gameState {
            return time
        }
        return nil
    }

    private var cancellables = Set<AnyCancellable>()

    func loadDailyPuzzle(service: DailyPuzzleService) {
        let difficulty = service.todayDifficulty
        let seed = service.todaySeed
        let generator = PuzzleGenerator(difficulty: difficulty, seed: seed)
        let puzzle = generator.generate()

        self.puzzle = puzzle
        self.gameViewModel = GameViewModel(puzzle: puzzle, mode: .daily, difficulty: difficulty)

        // Observe game state changes
        gameViewModel?.$gameState
            .sink { [weak self] state in
                self?.gameState = state
            }
            .store(in: &cancellables)

        // Observe timer changes to propagate to view
        gameViewModel?.$elapsedTime
            .sink { [weak self] _ in
                self?.formattedTime = self?.gameViewModel?.formattedTime ?? "0:00.0"
            }
            .store(in: &cancellables)
    }

    func resetForReplay() {
        gameViewModel?.resetGame()
        gameState = .ready
        formattedTime = "0:00.0"
    }
}

#Preview {
    HomeView()
}
