import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case en = "en"
    case zhHant = "zh-Hant"
    case zhHans = "zh-Hans"
    case ja = "ja"
    case ko = "ko"
    case th = "th"
    case vi = "vi"
    case id = "id"
    case ms = "ms"
    case de = "de"
    case fr = "fr"
    case es = "es"
    case it = "it"
    case pt = "pt"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .en: return "English"
        case .zhHant: return "繁體中文"
        case .zhHans: return "简体中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .th: return "ไทย"
        case .vi: return "Tiếng Việt"
        case .id: return "Bahasa Indonesia"
        case .ms: return "Bahasa Melayu"
        case .de: return "Deutsch"
        case .fr: return "Français"
        case .es: return "Español"
        case .it: return "Italiano"
        case .pt: return "Português"
        }
    }

    var languageCode: String? {
        switch self {
        case .system: return nil
        default: return rawValue
        }
    }
}

class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    private let defaults = UserDefaults.standard
    private let languageKey = "zip_selectedLanguage"

    @Published var currentLanguage: AppLanguage {
        didSet {
            defaults.set(currentLanguage.rawValue, forKey: languageKey)
            updateBundle()
            objectWillChange.send()
        }
    }

    private var bundle: Bundle = .main

    private init() {
        let savedLanguage = defaults.string(forKey: languageKey) ?? "system"
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .system
        updateBundle()
    }

    private func updateBundle() {
        if let languageCode = currentLanguage.languageCode,
           let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            // Use system language
            if let preferredLanguage = Locale.preferredLanguages.first {
                let languageCode = String(preferredLanguage.prefix(while: { $0 != "-" && $0 != "_" }))
                if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
                   let bundle = Bundle(path: path) {
                    self.bundle = bundle
                } else if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
                          let bundle = Bundle(path: path) {
                    self.bundle = bundle
                } else {
                    self.bundle = .main
                }
            } else {
                self.bundle = .main
            }
        }
    }

    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    func localizedString(_ key: String, _ arguments: CVarArg...) -> String {
        let format = bundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, arguments: arguments)
    }
}
