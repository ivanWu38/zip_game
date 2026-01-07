import SwiftUI

struct CellView: View {
    let cell: Cell
    let isInPath: Bool
    let isCurrentEnd: Bool
    let pathIndex: Int?
    let cellSize: CGFloat
    let spacing: CGFloat
    @ObservedObject private var themeService = ThemeService.shared

    init(cell: Cell, isInPath: Bool, isCurrentEnd: Bool, pathIndex: Int?, cellSize: CGFloat, spacing: CGFloat = 6) {
        self.cell = cell
        self.isInPath = isInPath
        self.isCurrentEnd = isCurrentEnd
        self.pathIndex = pathIndex
        self.cellSize = cellSize
        self.spacing = spacing
    }

    private let wallThickness: CGFloat = 4
    private let wallColor = Color.zipTextPrimary

    var body: some View {
        ZStack {
            // Background with gradient for path cells
            RoundedRectangle(cornerRadius: cellSize * 0.2)
                .fill(backgroundColor)
                .shadow(color: shadowColor, radius: isInPath ? 8 : 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: cellSize * 0.2)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )

            // Glow effect for current end
            if isCurrentEnd {
                RoundedRectangle(cornerRadius: cellSize * 0.2)
                    .fill(themeService.currentColor.opacity(0.3))
                    .blur(radius: 8)
            }

            // Checkpoint number
            if let number = cell.checkpointNumber {
                Text("\(number)")
                    .font(themeService.gameFont(size: cellSize * 0.45, weight: .bold))
                    .foregroundStyle(textColor)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }

            // Path dot for non-checkpoint cells
            if isInPath && cell.checkpointNumber == nil {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: cellSize * 0.25, height: cellSize * 0.25)
                    .shadow(color: .white.opacity(0.5), radius: 4)
            }

            // Walls - drawn on edges
            wallsOverlay
        }
        .frame(width: cellSize, height: cellSize)
        .scaleEffect(isCurrentEnd ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isInPath)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isCurrentEnd)
    }

    // MARK: - Walls Overlay
    @ViewBuilder
    private var wallsOverlay: some View {
        GeometryReader { geo in
            let walls = cell.walls
            let extendAmount = spacing / 2 + wallThickness / 2

            // Top wall
            if walls.top {
                Rectangle()
                    .fill(wallColor)
                    .frame(width: cellSize + extendAmount * 2, height: wallThickness)
                    .position(x: geo.size.width / 2, y: 0)
            }

            // Bottom wall
            if walls.bottom {
                Rectangle()
                    .fill(wallColor)
                    .frame(width: cellSize + extendAmount * 2, height: wallThickness)
                    .position(x: geo.size.width / 2, y: geo.size.height)
            }

            // Left wall
            if walls.left {
                Rectangle()
                    .fill(wallColor)
                    .frame(width: wallThickness, height: cellSize + extendAmount * 2)
                    .position(x: 0, y: geo.size.height / 2)
            }

            // Right wall
            if walls.right {
                Rectangle()
                    .fill(wallColor)
                    .frame(width: wallThickness, height: cellSize + extendAmount * 2)
                    .position(x: geo.size.width, y: geo.size.height / 2)
            }
        }
    }

    private var backgroundColor: Color {
        if isCurrentEnd {
            return themeService.currentColor
        } else if isInPath {
            return themeService.pathColor
        } else if cell.isCheckpoint {
            return themeService.checkpointColor
        } else {
            return themeService.emptyColor
        }
    }

    private var borderColor: Color {
        if isCurrentEnd {
            return Color.white.opacity(0.5)
        } else if isInPath {
            return Color.white.opacity(0.3)
        } else if cell.isCheckpoint {
            return themeService.pathColor.opacity(0.4)
        } else {
            return Color.white.opacity(0.05)
        }
    }

    private var borderWidth: CGFloat {
        if isCurrentEnd {
            return 2
        } else if isInPath || cell.isCheckpoint {
            return 1.5
        } else {
            return 1
        }
    }

    private var shadowColor: Color {
        if isCurrentEnd {
            return themeService.pathColor.opacity(0.6)
        } else if isInPath {
            return themeService.pathColor.opacity(0.4)
        } else {
            return Color.black.opacity(0.3)
        }
    }

    private var textColor: Color {
        if isInPath {
            return .white
        } else {
            return Color.zipTextPrimary
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.zipBackground.ignoresSafeArea()

        HStack(spacing: 8) {
            CellView(
                cell: Cell(position: Position(row: 0, col: 0), checkpointNumber: 1, walls: Walls(top: false, right: true, bottom: false, left: false)),
                isInPath: false,
                isCurrentEnd: false,
                pathIndex: nil,
                cellSize: 60,
                spacing: 8
            )
            CellView(
                cell: Cell(position: Position(row: 0, col: 1), checkpointNumber: nil, walls: Walls(top: true, right: false, bottom: true, left: true)),
                isInPath: true,
                isCurrentEnd: false,
                pathIndex: 1,
                cellSize: 60,
                spacing: 8
            )
            CellView(
                cell: Cell(position: Position(row: 0, col: 2), checkpointNumber: 2, walls: Walls(top: false, right: false, bottom: true, left: false)),
                isInPath: true,
                isCurrentEnd: true,
                pathIndex: 2,
                cellSize: 60,
                spacing: 8
            )
        }
        .padding()
    }
}
