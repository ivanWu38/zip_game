import SwiftUI

struct CellView: View {
    let cell: Cell
    let isInPath: Bool
    let isCurrentEnd: Bool
    let pathIndex: Int? // Position in the current path (for showing direction)
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(borderColor, lineWidth: isCurrentEnd ? 3 : 1)
                )

            // Checkpoint number
            if let number = cell.checkpointNumber {
                Text("\(number)")
                    .font(.system(size: cellSize * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
            }

            // Path indicator dot (for non-checkpoint cells in path)
            if isInPath && cell.checkpointNumber == nil {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: cellSize * 0.2, height: cellSize * 0.2)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .animation(.easeInOut(duration: 0.15), value: isInPath)
    }

    private var backgroundColor: Color {
        if isCurrentEnd {
            return Color.blue
        } else if isInPath {
            return Color.blue.opacity(0.7)
        } else if cell.isCheckpoint {
            return Color(.systemGray5)
        } else {
            return Color(.systemGray6)
        }
    }

    private var borderColor: Color {
        if isCurrentEnd {
            return Color.blue
        } else if cell.isCheckpoint {
            return Color.blue.opacity(0.5)
        } else {
            return Color(.systemGray4)
        }
    }

    private var textColor: Color {
        if isInPath {
            return .white
        } else {
            return .primary
        }
    }
}

#Preview {
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
