import SwiftUI
import AVFoundation

// MARK: - Adaptive Color Theme
extension Color {
    // Primary colors (same in both modes)
    static let zipPrimary = Color(red: 0.4, green: 0.5, blue: 1.0)
    static let zipSecondary = Color(red: 0.6, green: 0.4, blue: 1.0)

    // Accent colors (same in both modes)
    static let zipSuccess = Color(red: 0.3, green: 0.85, blue: 0.5)
    static let zipGold = Color(red: 1.0, green: 0.8, blue: 0.3)

    // Adaptive Background colors
    static let zipBackgroundStart = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
            : UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1)
    })

    static let zipBackgroundEnd = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.10, blue: 0.18, alpha: 1)
            : UIColor(red: 0.90, green: 0.92, blue: 0.96, alpha: 1)
    })

    // Adaptive Cell colors
    static let zipCellEmpty = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.22, alpha: 1)
            : UIColor(red: 0.92, green: 0.93, blue: 0.96, alpha: 1)
    })

    static let zipCellCheckpoint = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1)
            : UIColor(red: 0.85, green: 0.87, blue: 0.92, alpha: 1)
    })

    static let zipCellPath = Color(red: 0.4, green: 0.5, blue: 1.0)
    static let zipCellCurrent = Color(red: 0.5, green: 0.6, blue: 1.0)

    // Adaptive Card background
    static let zipCardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.06)
            : UIColor(white: 1.0, alpha: 0.9)
    })

    static let zipCardBorder = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.08)
            : UIColor(red: 0.85, green: 0.87, blue: 0.90, alpha: 1)
    })

    // Adaptive Text colors
    static let zipTextPrimary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 1.0)
            : UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)
    })

    static let zipTextSecondary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.6)
            : UIColor(red: 0.4, green: 0.42, blue: 0.48, alpha: 1)
    })

    static let zipTextTertiary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.4)
            : UIColor(red: 0.55, green: 0.58, blue: 0.65, alpha: 1)
    })

    // Tab bar background
    static let zipTabBarBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.10, blue: 0.18, alpha: 1)
            : UIColor(white: 1.0, alpha: 0.98)
    })

    // Tab icon inactive
    static let zipTabInactive = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.4)
            : UIColor(red: 0.6, green: 0.62, blue: 0.68, alpha: 1)
    })
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

// MARK: - Sound Manager
class SoundManager {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?

    private init() {}

    enum SoundType {
        case tap
        case success
        case error

        var systemSoundID: SystemSoundID {
            switch self {
            case .tap: return 1104      // Soft tap
            case .success: return 1025  // Success sound
            case .error: return 1053    // Error sound
            }
        }
    }

    func playSound(_ type: SoundType) {
        guard SettingsService.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(type.systemSoundID)
    }

    func playTap() {
        playSound(.tap)
    }

    func playSuccess() {
        playSound(.success)
    }

    func playError() {
        playSound(.error)
    }
}
