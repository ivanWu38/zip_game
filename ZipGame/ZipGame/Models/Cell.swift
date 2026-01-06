import Foundation

struct Position: Hashable, Equatable {
    let row: Int
    let col: Int

    func isAdjacent(to other: Position) -> Bool {
        let rowDiff = abs(row - other.row)
        let colDiff = abs(col - other.col)
        return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)
    }
}

struct Cell: Identifiable {
    let id = UUID()
    let position: Position
    var checkpointNumber: Int? // nil if not a checkpoint, otherwise 1, 2, 3...

    var isCheckpoint: Bool {
        checkpointNumber != nil
    }
}
