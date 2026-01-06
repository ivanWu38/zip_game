import SwiftUI

struct GameView: View {
    @StateObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            let cellSize = calculateCellSize(for: geometry.size)

            VStack(spacing: 20) {
                // Header
                headerView

                Spacer()

                // Grid
                GridView(viewModel: viewModel, cellSize: cellSize)
                    .frame(height: CGFloat(viewModel.puzzle.size) * cellSize + CGFloat(viewModel.puzzle.size - 1) * 4 + 40)

                Spacer()

                // Controls
                controlsView
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    viewModel.resetGame()
                }
            }
        }
        .overlay {
            if viewModel.gameState.isCompleted {
                completionOverlay
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text(viewModel.difficulty.displayName)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(viewModel.formattedTime)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }

    private var controlsView: some View {
        VStack(spacing: 12) {
            // Progress indicator
            HStack {
                Text("Progress:")
                    .foregroundColor(.secondary)
                Text("\(viewModel.currentPath.count) / \(viewModel.puzzle.totalCells)")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)

            // Instructions
            if viewModel.gameState == .ready {
                Text("Start at 1 and connect all numbers in order")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Completed!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if case .completed(let time) = viewModel.gameState {
                    VStack(spacing: 4) {
                        Text("Your Time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formatTime(time))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                }

                HStack(spacing: 16) {
                    if viewModel.mode == .unlimited {
                        Button {
                            viewModel.newPuzzle()
                        } label: {
                            Label("New Puzzle", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "checkmark")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(40)
        }
    }

    private func calculateCellSize(for size: CGSize) -> CGFloat {
        // Guard against zero or invalid sizes during initial layout
        guard size.width > 0, size.height > 0 else { return 50 }

        let puzzleSize = viewModel.puzzle.size
        let spacing: CGFloat = 4
        let padding: CGFloat = 32
        let maxWidth = size.width - padding
        let maxHeight = size.height * 0.6

        let cellSizeFromWidth = (maxWidth - CGFloat(puzzleSize - 1) * spacing) / CGFloat(puzzleSize)
        let cellSizeFromHeight = (maxHeight - CGFloat(puzzleSize - 1) * spacing) / CGFloat(puzzleSize)

        // Ensure minimum cell size of 20
        return max(min(cellSizeFromWidth, cellSizeFromHeight, 70), 20)
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
