import SwiftUI

struct GameView: View {
    @StateObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @State private var showConfetti = false

    var body: some View {
        GeometryReader { geometry in
            let cellSize = calculateCellSize(for: geometry.size)

            ZStack {
                // Background gradient
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    // Compact Header
                    compactHeaderView

                    // Grid - more vertical space
                    GridView(viewModel: viewModel, cellSize: cellSize)
                        .frame(height: CGFloat(viewModel.puzzle.size) * cellSize + CGFloat(viewModel.puzzle.size - 1) * 6 + 20)
                        .padding(.vertical, 8)

                    // Compact Progress bar
                    compactProgressView

                    // Compact Instructions
                    compactInstructionsView

                    // Ad space placeholder
                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)

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
            Text("game.reset".localized)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Color.zipPrimary)
        })
        .onChange(of: viewModel.gameState.isCompleted) { isCompleted in
            if isCompleted {
                showConfetti = true
                // Show interstitial ad (respects frequency control and premium status)
                AdMobManager.shared.onGameCompleted()
            }
        }
    }

    private var compactHeaderView: some View {
        HStack {
            // Difficulty badge
            Text(viewModel.difficulty.rawValue)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.zipCardBackground)
                )

            Spacer()

            // Timer
            Text(viewModel.formattedTime)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)
                .monospacedDigit()
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

    private var compactInstructionsView: some View {
        Group {
            if viewModel.gameState == .ready {
                HStack(spacing: 6) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 14))
                    Text("game.instruction".localized)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.zipTextTertiary)
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
                Text("game.complete.title".localized)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zipTextPrimary)

                // Time
                if case .completed(let time) = viewModel.gameState {
                    VStack(spacing: 8) {
                        Text("game.complete.yourTime".localized)
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
                                Text("game.complete.newPuzzle".localized)
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
                            Text("game.complete.home".localized)
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
        let padding: CGFloat = 24
        let maxWidth = size.width - padding
        // More vertical space for grid (58% of available height)
        let maxHeight = size.height * 0.58

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
