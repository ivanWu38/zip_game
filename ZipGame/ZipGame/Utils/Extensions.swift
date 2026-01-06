import SwiftUI

// MARK: - Color Theme
extension Color {
    // Primary colors
    static let zipPrimary = Color(red: 0.4, green: 0.5, blue: 1.0)
    static let zipSecondary = Color(red: 0.6, green: 0.4, blue: 1.0)

    // Background gradients
    static let zipBackgroundStart = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let zipBackgroundEnd = Color(red: 0.12, green: 0.10, blue: 0.18)

    // Cell colors
    static let zipCellEmpty = Color(red: 0.15, green: 0.15, blue: 0.22)
    static let zipCellCheckpoint = Color(red: 0.2, green: 0.2, blue: 0.3)
    static let zipCellPath = Color(red: 0.4, green: 0.5, blue: 1.0)
    static let zipCellCurrent = Color(red: 0.5, green: 0.6, blue: 1.0)

    // Accent colors
    static let zipSuccess = Color(red: 0.3, green: 0.85, blue: 0.5)
    static let zipGold = Color(red: 1.0, green: 0.8, blue: 0.3)
}

// MARK: - Gradient Backgrounds
extension LinearGradient {
    static let zipBackground = LinearGradient(
        colors: [Color.zipBackgroundStart, Color.zipBackgroundEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let zipPathGradient = LinearGradient(
        colors: [Color.zipPrimary, Color.zipSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let zipButtonGradient = LinearGradient(
        colors: [Color.zipPrimary, Color.zipSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - View Modifiers
struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

struct PressableButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func glassBackground() -> some View {
        modifier(GlassBackground())
    }

    func pressableButton() -> some View {
        modifier(PressableButton())
    }
}

// MARK: - Confetti Effect
struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var animate = false
    let colors: [Color] = [.zipPrimary, .zipSecondary, .zipSuccess, .zipGold, .white]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 1.5)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: animate ? geometry.size.height + 50 : piece.y)
                        .opacity(animate ? 0 : 1)
                }
            }
            .onAppear {
                createPieces(in: geometry.size)
                withAnimation(.easeIn(duration: 2.5)) {
                    animate = true
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createPieces(in size: CGSize) {
        pieces = (0..<50).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -100...0),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360)
            )
        }
    }
}
