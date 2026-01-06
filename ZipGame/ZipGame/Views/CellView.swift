import SwiftUI

struct CellView: View {
    let cell: Cell
    let isInPath: Bool
    let isCurrentEnd: Bool
    let pathIndex: Int?
    let cellSize: CGFloat

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
                    .fill(Color.zipCellCurrent.opacity(0.3))
                    .blur(radius: 8)
            }

            // Checkpoint number
            if let number = cell.checkpointNumber {
                Text("\(number)")
                    .font(.system(size: cellSize * 0.45, weight: .bold, design: .rounded))
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
        }
        .frame(width: cellSize, height: cellSize)
        .scaleEffect(isCurrentEnd ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isInPath)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isCurrentEnd)
    }

    private var backgroundColor: Color {
        if isCurrentEnd {
            return Color.zipCellCurrent
        } else if isInPath {
            return Color.zipCellPath
        } else if cell.isCheckpoint {
            return Color.zipCellCheckpoint
        } else {
            return Color.zipCellEmpty
        }
    }

    private var borderColor: Color {
        if isCurrentEnd {
            return Color.white.opacity(0.5)
        } else if isInPath {
            return Color.white.opacity(0.3)
        } else if cell.isCheckpoint {
            return Color.zipPrimary.opacity(0.4)
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
            return Color.zipPrimary.opacity(0.6)
        } else if isInPath {
            return Color.zipPrimary.opacity(0.4)
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
                cell: Cell(position: Position(row: 0, col: 0), checkpointNumber: 1),
                isInPath: false,
                isCurrentEnd: false,
                pathIndex: nil,
                cellSize: 60
            )
            CellView(
                cell: Cell(position: Position(row: 0, col: 1), checkpointNumber: nil),
                isInPath: true,
                isCurrentEnd: false,
                pathIndex: 1,
                cellSize: 60
            )
            CellView(
                cell: Cell(position: Position(row: 0, col: 2), checkpointNumber: 2),
                isInPath: true,
                isCurrentEnd: true,
                pathIndex: 2,
                cellSize: 60
            )
        }
        .padding()
    }
}
