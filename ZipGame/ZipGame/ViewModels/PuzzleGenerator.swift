import Foundation

class PuzzleGenerator {
    private let difficulty: Difficulty
    private var seededRng: SeededRandomNumberGenerator?

    init(difficulty: Difficulty, seed: UInt64? = nil) {
        self.difficulty = difficulty
        if let seed = seed {
            // Ensure seed is never 0 for xorshift
            self.seededRng = SeededRandomNumberGenerator(seed: seed == 0 ? 1 : seed)
        }
    }

    func generate() -> Puzzle {
        let size = difficulty.gridSize
        let path = generateHamiltonianPath(size: size)
        let checkpointPositions = placeCheckpoints(along: path)

        var cells: [[Cell]] = []
        var checkpoints: [Int: Position] = [:]

        for row in 0..<size {
            var rowCells: [Cell] = []
            for col in 0..<size {
                let position = Position(row: row, col: col)
                let checkpointNumber = checkpointPositions[position]
                let cell = Cell(position: position, checkpointNumber: checkpointNumber)
                rowCells.append(cell)

                if let num = checkpointNumber {
                    checkpoints[num] = position
                }
            }
            cells.append(rowCells)
        }

        return Puzzle(size: size, cells: cells, solution: path, checkpoints: checkpoints)
    }

    private func randomInt(in range: Range<Int>) -> Int {
        if seededRng != nil {
            return Int.random(in: range, using: &seededRng!)
        } else {
            return Int.random(in: range)
        }
    }

    private func randomBool() -> Bool {
        if seededRng != nil {
            return Bool.random(using: &seededRng!)
        } else {
            return Bool.random()
        }
    }

    private func shuffleArray<T>(_ array: inout [T]) {
        if seededRng != nil {
            array.shuffle(using: &seededRng!)
        } else {
            array.shuffle()
        }
    }

    // Generate a Hamiltonian path using randomized DFS with Warnsdorff's heuristic
    private func generateHamiltonianPath(size: Int) -> [Position] {
        var visited = Array(repeating: Array(repeating: false, count: size), count: size)
        var path: [Position] = []
        let totalCells = size * size
        var iterations = 0
        let maxIterations = 10000  // Limit to prevent long searches

        // Start from a corner for more reliable path finding
        let corners = [
            Position(row: 0, col: 0),
            Position(row: 0, col: size - 1),
            Position(row: size - 1, col: 0),
            Position(row: size - 1, col: size - 1)
        ]
        let startIndex = randomInt(in: 0..<corners.count)
        let start = corners[startIndex]

        func getNeighbors(_ pos: Position) -> [Position] {
            let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
            var neighbors: [Position] = []

            for (dr, dc) in directions {
                let newRow = pos.row + dr
                let newCol = pos.col + dc
                if newRow >= 0, newRow < size, newCol >= 0, newCol < size,
                   !visited[newRow][newCol] {
                    neighbors.append(Position(row: newRow, col: newCol))
                }
            }
            return neighbors
        }

        // Count available moves from a position (Warnsdorff's heuristic)
        func countMoves(from pos: Position) -> Int {
            return getNeighbors(pos).count
        }

        func dfs(_ current: Position) -> Bool {
            iterations += 1
            if iterations > maxIterations {
                return false  // Give up and use fallback
            }

            visited[current.row][current.col] = true
            path.append(current)

            if path.count == totalCells {
                return true
            }

            // Get neighbors and sort by Warnsdorff's heuristic (fewer moves first)
            var neighbors = getNeighbors(current)
            neighbors.sort { countMoves(from: $0) < countMoves(from: $1) }

            for neighbor in neighbors {
                if dfs(neighbor) {
                    return true
                }
            }

            // Backtrack
            visited[current.row][current.col] = false
            path.removeLast()
            return false
        }

        // Try to find a Hamiltonian path
        if dfs(start) {
            return path
        }

        // Fallback: generate a simple snake pattern (always valid)
        return generateSnakePath(size: size)
    }

    // Simple snake pattern as fallback
    private func generateSnakePath(size: Int) -> [Position] {
        var path: [Position] = []
        for row in 0..<size {
            if row % 2 == 0 {
                for col in 0..<size {
                    path.append(Position(row: row, col: col))
                }
            } else {
                for col in (0..<size).reversed() {
                    path.append(Position(row: row, col: col))
                }
            }
        }
        return path
    }

    // Place checkpoints along the path
    private func placeCheckpoints(along path: [Position]) -> [Position: Int] {
        var checkpointPositions: [Position: Int] = [:]
        let count = difficulty.checkpointCount
        let totalCells = path.count

        // Always place checkpoint 1 at the start
        checkpointPositions[path[0]] = 1

        // Always place the last checkpoint at the end
        checkpointPositions[path[totalCells - 1]] = count

        // Distribute remaining checkpoints evenly along the path
        let middleCheckpoints = count - 2
        if middleCheckpoints > 0 {
            let spacing = Double(totalCells - 1) / Double(count - 1)

            for i in 1..<(count - 1) {
                let index = Int(Double(i) * spacing)
                checkpointPositions[path[index]] = i + 1
            }
        }

        return checkpointPositions
    }
}

// Seeded random number generator for reproducible daily puzzles
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64 algorithm
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
