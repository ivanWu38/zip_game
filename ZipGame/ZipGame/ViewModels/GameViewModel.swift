import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var puzzle: Puzzle
    @Published var currentPath: [Position] = []
    @Published var gameState: GameState = .ready
    @Published var elapsedTime: TimeInterval = 0

    let mode: GameMode
    let difficulty: Difficulty

    private var timer: AnyCancellable?
    private var startTime: Date?
    private var pathSet: Set<Position> = []
    private var nextRequiredCheckpoint: Int = 1

    init(puzzle: Puzzle, mode: GameMode, difficulty: Difficulty) {
        self.puzzle = puzzle
        self.mode = mode
        self.difficulty = difficulty
    }

    // MARK: - Path Management

    func handleCellTouch(at position: Position) {
        guard !gameState.isCompleted else { return }

        // Start game on first touch
        if gameState == .ready {
            startGame()
        }

        // If path is empty, only allow starting at checkpoint 1
        if currentPath.isEmpty {
            if puzzle.checkpointNumber(at: position) == 1 {
                addToPath(position)
                nextRequiredCheckpoint = 2  // Next checkpoint to find is 2
            }
            return
        }

        guard let lastPosition = currentPath.last else { return }

        // If touching the previous cell, backtrack
        if currentPath.count >= 2 && position == currentPath[currentPath.count - 2] {
            backtrack()
            return
        }

        // If touching current cell, do nothing
        if position == lastPosition {
            return
        }

        // Check if position is adjacent, not blocked by wall, and not already in path
        if puzzle.canMove(from: lastPosition, to: position) && !pathSet.contains(position) {
            // Check checkpoint order
            if let checkpoint = puzzle.checkpointNumber(at: position) {
                if checkpoint == nextRequiredCheckpoint {
                    addToPath(position)
                    nextRequiredCheckpoint += 1
                    checkWinCondition()
                }
                // If it's the wrong checkpoint, don't allow the move
            } else {
                // Not a checkpoint, allow the move
                addToPath(position)
                // Also check win condition after every move
                checkWinCondition()
            }
        }
    }

    private func addToPath(_ position: Position) {
        currentPath.append(position)
        pathSet.insert(position)
        triggerHaptic(style: .light)
        SoundManager.shared.playTap()
    }

    private func backtrack() {
        guard let removed = currentPath.popLast() else { return }
        pathSet.remove(removed)

        // If we backtracked from a checkpoint, update next required
        if let checkpoint = puzzle.checkpointNumber(at: removed) {
            nextRequiredCheckpoint = checkpoint
        }

        triggerHaptic(style: .soft)
    }

    func pathIndex(for position: Position) -> Int? {
        currentPath.firstIndex(of: position)
    }

    // MARK: - Game State

    private func startGame() {
        gameState = .playing
        startTime = Date()
        startTimer()
    }

    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let startTime = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
    }

    private func checkWinCondition() {
        // Win if path covers all cells and all checkpoints have been visited in order
        let allCellsCovered = currentPath.count == puzzle.totalCells
        let allCheckpointsVisited = nextRequiredCheckpoint > puzzle.maxCheckpoint

        if allCellsCovered && allCheckpointsVisited {
            completeGame()
        }
    }

    private func completeGame() {
        timer?.cancel()
        timer = nil
        gameState = .completed(time: elapsedTime)
        triggerHaptic(style: .success)
        SoundManager.shared.playSuccess()

        // Record stats
        let isDaily = mode == .daily
        StatsService.shared.recordCompletion(difficulty: difficulty, time: elapsedTime, isDaily: isDaily)

        // Also update daily puzzle service if daily mode
        if isDaily {
            DailyPuzzleService().markCompleted(time: elapsedTime)
        }
    }

    func resetGame() {
        currentPath = []
        pathSet = []
        nextRequiredCheckpoint = 1
        gameState = .ready
        elapsedTime = 0
        startTime = nil
        timer?.cancel()
        timer = nil
    }

    func newPuzzle() {
        let generator = PuzzleGenerator(difficulty: difficulty)
        puzzle = generator.generate()
        resetGame()
    }

    // MARK: - Haptics

    private func triggerHaptic(style: HapticStyle) {
        // Check if haptics are enabled
        guard SettingsService.shared.hapticsEnabled else { return }

        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .soft:
            generator = UIImpactFeedbackGenerator(style: .soft)
        case .success:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
            return
        }
        generator.impactOccurred()
    }

    private enum HapticStyle {
        case light, soft, success
    }

    // MARK: - Time Formatting

    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let tenths = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}
