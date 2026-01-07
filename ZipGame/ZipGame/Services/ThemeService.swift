import SwiftUI

// MARK: - Board Theme
enum BoardTheme: String, CaseIterable, Identifiable {
    case zipDefault = "default"
    case ocean = "ocean"
    case sunset = "sunset"
    case sakura = "sakura"
    case monochrome = "monochrome"
    case forest = "forest"
    case lavender = "lavender"
    case mint = "mint"
    case coral = "coral"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zipDefault: return "Zip Default"
        case .ocean: return "Deep Ocean"
        case .sunset: return "Sunset"
        case .sakura: return "Sakura"
        case .monochrome: return "Monochrome"
        case .forest: return "Forest"
        case .lavender: return "Lavender"
        case .mint: return "Mint"
        case .coral: return "Coral"
        }
    }

    var isPremium: Bool {
        self != .zipDefault
    }

    // Path/Active cell color
    var pathColor: Color {
        switch self {
        case .zipDefault: return Color(red: 0.4, green: 0.5, blue: 1.0)
        case .ocean: return Color(red: 0.1, green: 0.5, blue: 0.7)
        case .sunset: return Color(red: 0.95, green: 0.5, blue: 0.3)
        case .sakura: return Color(red: 0.95, green: 0.6, blue: 0.7)
        case .monochrome: return Color(red: 0.3, green: 0.3, blue: 0.3)
        case .forest: return Color(red: 0.2, green: 0.6, blue: 0.4)
        case .lavender: return Color(red: 0.6, green: 0.5, blue: 0.8)
        case .mint: return Color(red: 0.4, green: 0.8, blue: 0.7)
        case .coral: return Color(red: 0.9, green: 0.4, blue: 0.5)
        }
    }

    // Current end cell color (slightly brighter)
    var currentColor: Color {
        switch self {
        case .zipDefault: return Color(red: 0.5, green: 0.6, blue: 1.0)
        case .ocean: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .sunset: return Color(red: 1.0, green: 0.6, blue: 0.4)
        case .sakura: return Color(red: 1.0, green: 0.7, blue: 0.8)
        case .monochrome: return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .forest: return Color(red: 0.3, green: 0.7, blue: 0.5)
        case .lavender: return Color(red: 0.7, green: 0.6, blue: 0.9)
        case .mint: return Color(red: 0.5, green: 0.9, blue: 0.8)
        case .coral: return Color(red: 1.0, green: 0.5, blue: 0.6)
        }
    }

    // Preview colors for theme card (4 colors: highlighted, normal, highlighted, normal)
    var previewColors: [Color] {
        [pathColor, emptyColor, pathColor, emptyColor]
    }

    // Empty cell color
    var emptyColor: Color {
        switch self {
        case .zipDefault:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.15, green: 0.15, blue: 0.22, alpha: 1)
                    : UIColor(red: 0.88, green: 0.87, blue: 0.85, alpha: 1)
            })
        case .ocean:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.1, green: 0.15, blue: 0.2, alpha: 1)
                    : UIColor(red: 0.85, green: 0.92, blue: 0.95, alpha: 1)
            })
        case .sunset:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.2, green: 0.12, blue: 0.1, alpha: 1)
                    : UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1)
            })
        case .sakura:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.18, green: 0.12, blue: 0.15, alpha: 1)
                    : UIColor(red: 1.0, green: 0.95, blue: 0.97, alpha: 1)
            })
        case .monochrome:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
                    : UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
            })
        case .forest:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.1, green: 0.15, blue: 0.12, alpha: 1)
                    : UIColor(red: 0.92, green: 0.96, blue: 0.93, alpha: 1)
            })
        case .lavender:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.15, green: 0.12, blue: 0.18, alpha: 1)
                    : UIColor(red: 0.96, green: 0.94, blue: 0.98, alpha: 1)
            })
        case .mint:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.1, green: 0.18, blue: 0.16, alpha: 1)
                    : UIColor(red: 0.92, green: 0.98, blue: 0.96, alpha: 1)
            })
        case .coral:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.2, green: 0.12, blue: 0.12, alpha: 1)
                    : UIColor(red: 1.0, green: 0.95, blue: 0.94, alpha: 1)
            })
        }
    }

    // Checkpoint cell color (slightly darker than empty)
    var checkpointColor: Color {
        switch self {
        case .zipDefault:
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1)
                    : UIColor(red: 0.82, green: 0.81, blue: 0.79, alpha: 1)
            })
        default:
            return emptyColor.opacity(0.85)
        }
    }
}

// MARK: - Font Theme
enum FontTheme: String, CaseIterable, Identifiable {
    case rounded = "rounded"
    case futura = "futura"
    case courier = "courier"
    case chalkduster = "chalkduster"
    case copperplate = "copperplate"
    case marker = "marker"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rounded: return "Rounded"
        case .futura: return "Futura"
        case .courier: return "Typewriter"
        case .chalkduster: return "Chalkboard"
        case .copperplate: return "Copperplate"
        case .marker: return "Marker"
        }
    }

    var isPremium: Bool {
        self != .rounded
    }

    var fontName: String {
        switch self {
        case .rounded: return "AvenirNext-Bold"
        case .futura: return "Futura-Bold"
        case .courier: return "CourierNewPS-BoldMT"
        case .chalkduster: return "Chalkduster"
        case .copperplate: return "Copperplate-Bold"
        case .marker: return "MarkerFelt-Wide"
        }
    }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom(fontName, size: size)
    }
}

// MARK: - Theme Service
@MainActor
class ThemeService: ObservableObject {
    static let shared = ThemeService()

    private let defaults = UserDefaults.standard

    @Published var selectedBoardTheme: BoardTheme {
        didSet {
            defaults.set(selectedBoardTheme.rawValue, forKey: "zip_boardTheme")
        }
    }

    @Published var selectedFontTheme: FontTheme {
        didSet {
            defaults.set(selectedFontTheme.rawValue, forKey: "zip_fontTheme")
        }
    }

    private init() {
        let themeRaw = defaults.string(forKey: "zip_boardTheme") ?? "default"
        self.selectedBoardTheme = BoardTheme(rawValue: themeRaw) ?? .zipDefault

        let fontRaw = defaults.string(forKey: "zip_fontTheme") ?? "rounded"
        self.selectedFontTheme = FontTheme(rawValue: fontRaw) ?? .rounded
    }

    // Get effective theme (respecting premium status)
    var effectiveBoardTheme: BoardTheme {
        if selectedBoardTheme.isPremium && !SubscriptionService.shared.isPremium {
            return .zipDefault
        }
        return selectedBoardTheme
    }

    var effectiveFontTheme: FontTheme {
        if selectedFontTheme.isPremium && !SubscriptionService.shared.isPremium {
            return .rounded
        }
        return selectedFontTheme
    }

    // Current theme colors
    var pathColor: Color {
        effectiveBoardTheme.pathColor
    }

    var currentColor: Color {
        effectiveBoardTheme.currentColor
    }

    var emptyColor: Color {
        effectiveBoardTheme.emptyColor
    }

    var checkpointColor: Color {
        effectiveBoardTheme.checkpointColor
    }

    // Font helper
    func gameFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        effectiveFontTheme.font(size: size, weight: weight)
    }
}
