import Foundation

struct Puzzle {
    let size: Int
    let cells: [[Cell]]
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
}
