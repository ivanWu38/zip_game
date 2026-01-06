import SwiftUI

struct GridView: View {
    @ObservedObject var viewModel: GameViewModel
    let cellSize: CGFloat
    let spacing: CGFloat = 4

    var body: some View {
        let puzzle = viewModel.puzzle

        GeometryReader { geometry in
            // Guard against invalid geometry
            let validWidth = max(geometry.size.width, 1)
            let validHeight = max(geometry.size.height, 1)

            let totalSize = CGFloat(puzzle.size) * cellSize + CGFloat(puzzle.size - 1) * spacing
            let offsetX = (validWidth - totalSize) / 2
            let offsetY = (validHeight - totalSize) / 2

            ZStack {
                // Path lines connecting cells
                PathLinesView(
                    path: viewModel.currentPath,
                    cellSize: cellSize,
                    spacing: spacing,
                    offset: CGPoint(x: max(offsetX, 0), y: max(offsetY, 0))
                )

                // Grid of cells
                VStack(spacing: spacing) {
                    ForEach(0..<puzzle.size, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<puzzle.size, id: \.self) { col in
                                let position = Position(row: row, col: col)
                                if let cell = puzzle.cell(at: position) {
                                    let pathIndex = viewModel.pathIndex(for: position)
                                    CellView(
                                        cell: cell,
                                        isInPath: pathIndex != nil,
                                        isCurrentEnd: position == viewModel.currentPath.last,
                                        pathIndex: pathIndex,
                                        cellSize: cellSize
                                    )
                                }
                            }
                        }
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(at: value.location, in: geometry.size, offset: CGPoint(x: max(offsetX, 0), y: max(offsetY, 0)))
                    }
                    .onEnded { _ in
                        // Path stays as is when drag ends
                    }
            )
        }
    }

    private func handleDrag(at location: CGPoint, in size: CGSize, offset: CGPoint) {
        let puzzle = viewModel.puzzle
        let totalSize = CGFloat(puzzle.size) * cellSize + CGFloat(puzzle.size - 1) * spacing

        // Calculate which cell the touch is in
        let adjustedX = location.x - offset.x
        let adjustedY = location.y - offset.y

        guard adjustedX >= 0, adjustedY >= 0,
              adjustedX < totalSize, adjustedY < totalSize else {
            return
        }

        let cellWithSpacing = cellSize + spacing
        let col = Int(adjustedX / cellWithSpacing)
        let row = Int(adjustedY / cellWithSpacing)

        guard row >= 0, row < puzzle.size, col >= 0, col < puzzle.size else {
            return
        }

        let position = Position(row: row, col: col)
        viewModel.handleCellTouch(at: position)
    }
}

struct PathLinesView: View {
    let path: [Position]
    let cellSize: CGFloat
    let spacing: CGFloat
    let offset: CGPoint

    var body: some View {
        Canvas { context, size in
            // Guard against invalid states
            guard path.count >= 2, cellSize > 0 else { return }

            var pathShape = Path()

            for (index, position) in path.enumerated() {
                let point = centerPoint(for: position)

                // Skip invalid points
                guard point.x.isFinite, point.y.isFinite else { continue }

                if index == 0 {
                    pathShape.move(to: point)
                } else {
                    pathShape.addLine(to: point)
                }
            }

            let lineWidth = max(cellSize * 0.3, 1)
            context.stroke(
                pathShape,
                with: .color(.blue.opacity(0.5)),
                lineWidth: lineWidth
            )
        }
    }

    private func centerPoint(for position: Position) -> CGPoint {
        let cellWithSpacing = cellSize + spacing
        let x = offset.x + CGFloat(position.col) * cellWithSpacing + cellSize / 2
        let y = offset.y + CGFloat(position.row) * cellWithSpacing + cellSize / 2
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    let generator = PuzzleGenerator(difficulty: .easy)
    let puzzle = generator.generate()
    let viewModel = GameViewModel(puzzle: puzzle, mode: .unlimited, difficulty: .easy)

    GridView(viewModel: viewModel, cellSize: 60)
        .frame(height: 400)
        .padding()
}
