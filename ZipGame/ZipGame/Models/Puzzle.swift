import Foundation

struct Puzzle {
    let size: Int
    var cells: [[Cell]]
    let solution: [Position] // The correct path through all cells
    let checkpoints: [Int: Position] // checkpoint number -> position

    var totalCells: Int {
        size * size
    }

    func cell(at position: Position) -> Cell? {
        guard position.row >= 0, position.row < size,
              position.col >= 0, position.col < size else {
            return nil
        }
        return cells[position.row][position.col]
    }

    func checkpointNumber(at position: Position) -> Int? {
        cell(at: position)?.checkpointNumber
    }

    // Get the position of a specific checkpoint number
    func position(forCheckpoint number: Int) -> Position? {
        checkpoints[number]
    }

    // Get the starting position (checkpoint 1)
    var startPosition: Position? {
        checkpoints[1]
    }

    // Get the maximum checkpoint number
    var maxCheckpoint: Int {
        checkpoints.keys.max() ?? 0
    }

    /// Check if there is a wall between two adjacent positions
    func hasWall(from: Position, to: Position) -> Bool {
        guard let direction = from.direction(to: to),
              let fromCell = cell(at: from) else {
            return true // Treat invalid moves as blocked
        }
        return fromCell.walls.hasWall(in: direction)
    }

    /// Check if movement from one position to another is allowed (adjacent and no wall)
    func canMove(from: Position, to: Position) -> Bool {
        // Must be adjacent
        guard from.isAdjacent(to: to) else { return false }
        // Must be within bounds
        guard cell(at: to) != nil else { return false }
        // Must not have wall blocking
        return !hasWall(from: from, to: to)
    }
}
