import Foundation

struct Position: Hashable, Equatable {
    let row: Int
    let col: Int

    func isAdjacent(to other: Position) -> Bool {
        let rowDiff = abs(row - other.row)
        let colDiff = abs(col - other.col)
        return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)
    }

    /// Returns the direction from this position to an adjacent position
    func direction(to other: Position) -> Direction? {
        if other.row == row - 1 && other.col == col { return .top }
        if other.row == row + 1 && other.col == col { return .bottom }
        if other.col == col + 1 && other.row == row { return .right }
        if other.col == col - 1 && other.row == row { return .left }
        return nil
    }
}

/// Direction for walls
enum Direction: CaseIterable {
    case top, right, bottom, left

    var opposite: Direction {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .left: return .right
        case .right: return .left
        }
    }
}

/// Walls for a cell - stores which sides have walls
struct Walls: Equatable {
    var top: Bool = false
    var right: Bool = false
    var bottom: Bool = false
    var left: Bool = false

    func hasWall(in direction: Direction) -> Bool {
        switch direction {
        case .top: return top
        case .right: return right
        case .bottom: return bottom
        case .left: return left
        }
    }

    mutating func setWall(in direction: Direction, value: Bool) {
        switch direction {
        case .top: top = value
        case .right: right = value
        case .bottom: bottom = value
        case .left: left = value
        }
    }
}

struct Cell: Identifiable {
    let id = UUID()
    let position: Position
    var checkpointNumber: Int? // nil if not a checkpoint, otherwise 1, 2, 3...
    var walls: Walls = Walls()

    var isCheckpoint: Bool {
        checkpointNumber != nil
    }
}
