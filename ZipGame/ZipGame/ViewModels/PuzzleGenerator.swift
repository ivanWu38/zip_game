import Foundation

class PuzzleGenerator {
    private let difficulty: Difficulty
    private var seededRng: SeededRandomNumberGenerator?
    private let size: Int

    init(difficulty: Difficulty, seed: UInt64? = nil) {
        self.difficulty = difficulty
        self.size = difficulty.gridSize
        if let seed = seed {
            self.seededRng = SeededRandomNumberGenerator(seed: seed == 0 ? 1 : seed)
        }
    }

    func generate() -> Puzzle {
        // Step 1: Generate a Hamiltonian path using Warnsdorff's heuristic (O(n²), no backtracking)
        let path = generateWarnsdorffPath()

        // Step 2: Create the set of edges used by the solution path
        var solutionEdges = Set<Edge>()
        for i in 0..<(path.count - 1) {
            let edge = Edge(from: path[i], to: path[i + 1])
            solutionEdges.insert(edge)
        }

        // Step 3: Generate walls on non-solution edges
        let walls = generateWalls(solutionEdges: solutionEdges)

        // Step 4: Place checkpoints at strategic positions along the path
        let checkpointPositions = placeCheckpoints(along: path)

        // Step 5: Build the puzzle
        var cells: [[Cell]] = []
        var checkpoints: [Int: Position] = [:]

        for row in 0..<size {
            var rowCells: [Cell] = []
            for col in 0..<size {
                let position = Position(row: row, col: col)
                let checkpointNumber = checkpointPositions[position]
                let cellWalls = walls[position] ?? Walls()
                let cell = Cell(position: position, checkpointNumber: checkpointNumber, walls: cellWalls)
                rowCells.append(cell)

                if let num = checkpointNumber {
                    checkpoints[num] = position
                }
            }
            cells.append(rowCells)
        }

        return Puzzle(size: size, cells: cells, solution: path, checkpoints: checkpoints)
    }

    // MARK: - Random Helpers

    private func randomInt(in range: Range<Int>) -> Int {
        if seededRng != nil {
            return Int.random(in: range, using: &seededRng!)
        } else {
            return Int.random(in: range)
        }
    }

    private func randomDouble() -> Double {
        if seededRng != nil {
            return Double.random(in: 0..<1, using: &seededRng!)
        } else {
            return Double.random(in: 0..<1)
        }
    }

    private func shuffleArray<T>(_ array: inout [T]) {
        if seededRng != nil {
            array.shuffle(using: &seededRng!)
        } else {
            array.shuffle()
        }
    }

    // MARK: - Warnsdorff's Heuristic Path Generation

    /// Generate a Hamiltonian path using Warnsdorff's heuristic
    /// This runs in O(n²) time without backtracking
    private func generateWarnsdorffPath() -> [Position] {
        var visited = Array(repeating: Array(repeating: false, count: size), count: size)
        var path: [Position] = []
        let totalCells = size * size

        // Try from different starting positions to find a complete path
        let startPositions = generateStartPositions()

        for start in startPositions {
            // Reset state
            visited = Array(repeating: Array(repeating: false, count: size), count: size)
            path = []

            // Try to build path from this start
            var current = start
            visited[current.row][current.col] = true
            path.append(current)

            while path.count < totalCells {
                // Get unvisited neighbors
                let neighbors = getUnvisitedNeighbors(current, visited: visited)

                if neighbors.isEmpty {
                    // Dead end - this starting position doesn't work
                    break
                }

                // Warnsdorff's rule: choose neighbor with minimum degree (fewest onward moves)
                // With random tie-breaking
                let next = chooseByWarnsdorff(neighbors: neighbors, visited: visited)

                visited[next.row][next.col] = true
                path.append(next)
                current = next
            }

            // If we found a complete path, return it
            if path.count == totalCells {
                return path
            }
        }

        // Fallback: if Warnsdorff fails, use a guaranteed snake pattern
        return generateSnakePath()
    }

    /// Generate a list of starting positions to try
    private func generateStartPositions() -> [Position] {
        var positions: [Position] = []

        // Add corners first (they often work well)
        positions.append(Position(row: 0, col: 0))
        positions.append(Position(row: 0, col: size - 1))
        positions.append(Position(row: size - 1, col: 0))
        positions.append(Position(row: size - 1, col: size - 1))

        // Add some random positions
        for _ in 0..<4 {
            let row = randomInt(in: 0..<size)
            let col = randomInt(in: 0..<size)
            positions.append(Position(row: row, col: col))
        }

        // Shuffle to add variety
        shuffleArray(&positions)

        return positions
    }

    /// Get all unvisited neighbors of a position
    private func getUnvisitedNeighbors(_ pos: Position, visited: [[Bool]]) -> [Position] {
        var neighbors: [Position] = []
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]

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

    /// Choose next position using Warnsdorff's heuristic with random tie-breaking
    private func chooseByWarnsdorff(neighbors: [Position], visited: [[Bool]]) -> Position {
        // Calculate degree (number of onward moves) for each neighbor
        var neighborDegrees: [(Position, Int)] = neighbors.map { neighbor in
            let degree = getUnvisitedNeighbors(neighbor, visited: visited).count
            return (neighbor, degree)
        }

        // Find minimum degree
        let minDegree = neighborDegrees.map { $0.1 }.min() ?? 0

        // Get all neighbors with minimum degree
        var candidates = neighborDegrees.filter { $0.1 == minDegree }.map { $0.0 }

        // Random selection among ties
        shuffleArray(&candidates)
        return candidates.first!
    }

    /// Fallback: generate a snake pattern (guaranteed to work)
    private func generateSnakePath() -> [Position] {
        var path: [Position] = []

        // Randomize direction for variety
        let startFromTop = randomDouble() < 0.5
        let startFromLeft = randomDouble() < 0.5

        let rowRange: [Int] = startFromTop ? Array(0..<size) : Array((0..<size).reversed())

        for (index, row) in rowRange.enumerated() {
            let goingRight = startFromLeft ? (index % 2 == 0) : (index % 2 == 1)

            if goingRight {
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

    // MARK: - Wall Generation

    /// Generate walls based on difficulty
    private func generateWalls(solutionEdges: Set<Edge>) -> [Position: Walls] {
        var wallsMap: [Position: Walls] = [:]

        // Initialize empty walls for all positions
        for row in 0..<size {
            for col in 0..<size {
                wallsMap[Position(row: row, col: col)] = Walls()
            }
        }

        // Collect all possible internal edges (not solution edges)
        var candidateEdges: [Edge] = []

        for row in 0..<size {
            for col in 0..<size {
                let pos = Position(row: row, col: col)

                // Check right neighbor
                if col < size - 1 {
                    let rightPos = Position(row: row, col: col + 1)
                    let edge = Edge(from: pos, to: rightPos)
                    if !solutionEdges.contains(edge) {
                        candidateEdges.append(edge)
                    }
                }

                // Check bottom neighbor
                if row < size - 1 {
                    let bottomPos = Position(row: row + 1, col: col)
                    let edge = Edge(from: pos, to: bottomPos)
                    if !solutionEdges.contains(edge) {
                        candidateEdges.append(edge)
                    }
                }
            }
        }

        // Shuffle candidate edges
        shuffleArray(&candidateEdges)

        // Determine wall count based on difficulty
        let wallRatio: Double
        switch difficulty {
        case .easy:
            wallRatio = 0.3
        case .medium:
            wallRatio = 0.4
        case .hard:
            wallRatio = 0.5
        }

        let wallCount = Int(Double(candidateEdges.count) * wallRatio)

        // Add walls
        for i in 0..<min(wallCount, candidateEdges.count) {
            let edge = candidateEdges[i]
            addWall(at: edge, to: &wallsMap)
        }

        return wallsMap
    }

    /// Add a wall between two adjacent positions
    private func addWall(at edge: Edge, to wallsMap: inout [Position: Walls]) {
        let pos1 = edge.pos1
        let pos2 = edge.pos2

        if pos2.col == pos1.col + 1 {
            wallsMap[pos1]?.right = true
            wallsMap[pos2]?.left = true
        } else if pos2.col == pos1.col - 1 {
            wallsMap[pos1]?.left = true
            wallsMap[pos2]?.right = true
        } else if pos2.row == pos1.row + 1 {
            wallsMap[pos1]?.bottom = true
            wallsMap[pos2]?.top = true
        } else if pos2.row == pos1.row - 1 {
            wallsMap[pos1]?.top = true
            wallsMap[pos2]?.bottom = true
        }
    }

    // MARK: - Checkpoint Placement

    /// Place checkpoints at strategic positions (turns and key points)
    private func placeCheckpoints(along path: [Position]) -> [Position: Int] {
        var checkpointPositions: [Position: Int] = [:]
        let count = difficulty.checkpointCount
        let totalCells = path.count

        // Always place checkpoint 1 at the start
        checkpointPositions[path[0]] = 1

        // Always place the last checkpoint at the end
        checkpointPositions[path[totalCells - 1]] = count

        // Find all turn positions in the path
        var turnIndices: [Int] = []
        for i in 1..<(path.count - 1) {
            let prev = path[i - 1]
            let curr = path[i]
            let next = path[i + 1]

            let dir1 = (curr.row - prev.row, curr.col - prev.col)
            let dir2 = (next.row - curr.row, next.col - curr.col)

            if dir1 != dir2 {
                turnIndices.append(i)
            }
        }

        // Place middle checkpoints
        let middleCheckpoints = count - 2
        if middleCheckpoints > 0 && !turnIndices.isEmpty {
            var placedIndices = Set<Int>([0, totalCells - 1])
            var checkpointNum = 2

            // Distribute checkpoints evenly, preferring turn positions
            let spacing = Double(totalCells) / Double(count)

            for i in 1..<count - 1 {
                let targetIndex = Int(Double(i) * spacing)

                // Find the best position near the target
                var bestIndex = targetIndex
                var bestDistance = Int.max

                // Look for a turn position near the target
                for turnIdx in turnIndices {
                    if !placedIndices.contains(turnIdx) {
                        let distance = abs(turnIdx - targetIndex)
                        if distance < bestDistance && distance < Int(spacing * 0.6) {
                            bestDistance = distance
                            bestIndex = turnIdx
                        }
                    }
                }

                // If no good turn found, use target or nearby unplaced position
                if placedIndices.contains(bestIndex) {
                    bestIndex = targetIndex
                    while placedIndices.contains(bestIndex) && bestIndex < totalCells - 1 {
                        bestIndex += 1
                    }
                }

                if !placedIndices.contains(bestIndex) && bestIndex > 0 && bestIndex < totalCells - 1 {
                    checkpointPositions[path[bestIndex]] = checkpointNum
                    placedIndices.insert(bestIndex)
                    checkpointNum += 1
                }
            }

            // Fill any remaining checkpoints
            while checkpointNum < count {
                let targetIndex = Int(Double(checkpointNum - 1) * spacing)
                var idx = targetIndex
                while placedIndices.contains(idx) && idx < totalCells - 1 {
                    idx += 1
                }
                if placedIndices.contains(idx) {
                    idx = targetIndex
                    while placedIndices.contains(idx) && idx > 0 {
                        idx -= 1
                    }
                }
                if !placedIndices.contains(idx) {
                    checkpointPositions[path[idx]] = checkpointNum
                    placedIndices.insert(idx)
                }
                checkpointNum += 1
            }
        }

        return checkpointPositions
    }
}

// MARK: - Edge struct for tracking solution path edges

private struct Edge: Hashable {
    let pos1: Position
    let pos2: Position

    init(from: Position, to: Position) {
        // Normalize edge so (a,b) == (b,a)
        if from.row < to.row || (from.row == to.row && from.col < to.col) {
            pos1 = from
            pos2 = to
        } else {
            pos1 = to
            pos2 = from
        }
    }
}

// MARK: - Seeded Random Number Generator

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
