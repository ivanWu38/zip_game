import SwiftUI

struct GameView: View {
    @StateObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false

    var body: some View {
        GeometryReader { geometry in
            let cellSize = calculateCellSize(for: geometry.size)

            ZStack {
                // Background gradient
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Header
                    headerView

                    Spacer()

                    // Grid
                    GridView(viewModel: viewModel, cellSize: cellSize)
                        .frame(height: CGFloat(viewModel.puzzle.size) * cellSize + CGFloat(viewModel.puzzle.size - 1) * 6 + 20)

                    Spacer()

                    // Progress bar
                    progressView

                    // Instructions
                    instructionsView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                // Confetti overlay
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: {
            viewModel.resetGame()
        }) {
            Text("Reset")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Color.zipPrimary)
        })
        .onChange(of: viewModel.gameState) { newState in
            if newState.isCompleted {
                showConfetti = true
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 14) {
            // Difficulty badge
            Text(viewModel.difficulty.displayName)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.zipCardBackground)
                )

            // Timer
            Text(viewModel.formattedTime)
                .font(.system(size: 68, weight: .bold, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)
                .monospacedDigit()
                .shadow(color: Color.zipPrimary.opacity(0.5), radius: 10)
        }
        .padding(.top, 10)
    }

    private var progressView: some View {
        VStack(spacing: 10) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))

                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient.zipButtonGradient)
                        .frame(width: geo.size.width * progressPercentage)
                        .animation(.spring(response: 0.3), value: viewModel.currentPath.count)
                }
            }
            .frame(height: 8)

            // Progress text
            HStack {
                Text("\(viewModel.currentPath.count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zipTextPrimary)

                Text("/ \(viewModel.puzzle.totalCells)")
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.zipTextTertiary)

                Spacer()

                Text("\(Int(progressPercentage * 100))%")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.zipPrimary)
            }
        }
        .padding(.horizontal, 4)
    }

    private var progressPercentage: CGFloat {
        guard viewModel.puzzle.totalCells > 0 else { return 0 }
        return CGFloat(viewModel.currentPath.count) / CGFloat(viewModel.puzzle.totalCells)
    }

    private var instructionsView: some View {
        Group {
            if viewModel.gameState == .ready {
                HStack(spacing: 10) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 18))
                    Text("Start at 1 and connect numbers in order")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.zipTextTertiary)
                .padding(.bottom, 10)
            }
        }
    }

    private var completionOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Completion card
            VStack(spacing: 28) {
                // Trophy icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.zipGold.opacity(0.3), Color.zipGold.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 110, height: 110)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.zipGold)
                        .shadow(color: Color.zipGold.opacity(0.5), radius: 10)
                }

                // Title
                Text("Puzzle Complete!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zipTextPrimary)

                // Time
                if case .completed(let time) = viewModel.gameState {
                    VStack(spacing: 8) {
                        Text("Your Time")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextTertiary)
                        Text(formatTime(time))
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)
                            .monospacedDigit()
                    }
                }

                // Buttons
                VStack(spacing: 14) {
                    if viewModel.mode == .unlimited {
                        Button {
                            showConfetti = false
                            viewModel.newPuzzle()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                Text("New Puzzle")
                            }
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(LinearGradient.zipButtonGradient)
                            .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "house")
                            Text("Home")
                        }
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.zipTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.zipCardBackground)
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
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private func calculateCellSize(for size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return 50 }

        let puzzleSize = viewModel.puzzle.size
        let spacing: CGFloat = 6
        let padding: CGFloat = 40
        let maxWidth = size.width - padding
        let maxHeight = size.height * 0.55

        let cellSizeFromWidth = (maxWidth - CGFloat(puzzleSize - 1) * spacing) / CGFloat(puzzleSize)
        let cellSizeFromHeight = (maxHeight - CGFloat(puzzleSize - 1) * spacing) / CGFloat(puzzleSize)

        return max(min(cellSizeFromWidth, cellSizeFromHeight, 65), 20)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

#Preview {
    NavigationStack {
        GameView(
            viewModel: GameViewModel(
                puzzle: PuzzleGenerator(difficulty: .easy).generate(),
                mode: .unlimited,
                difficulty: .easy
            )
        )
    }
}
