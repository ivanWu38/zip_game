import SwiftUI
import StoreKit
import MessageUI

class SettingsService: ObservableObject {
    static let shared = SettingsService()

    private let defaults = UserDefaults.standard

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "zip_soundEnabled") }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: "zip_hapticsEnabled") }
    }
    @Published var appearanceMode: AppearanceMode {
        didSet { defaults.set(appearanceMode.rawValue, forKey: "zip_appearanceMode") }
    }

    private init() {
        self.soundEnabled = defaults.object(forKey: "zip_soundEnabled") as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: "zip_hapticsEnabled") as? Bool ?? true
        let modeRaw = defaults.string(forKey: "zip_appearanceMode") ?? "auto"
        self.appearanceMode = AppearanceMode(rawValue: modeRaw) ?? .auto
    }
}

enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"

    var displayName: String {
        switch self {
        case .light: return "settings.appearance.light".localized
        case .dark: return "settings.appearance.dark".localized
        case .auto: return "settings.appearance.auto".localized
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .auto: return "gearshape.fill"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings = SettingsService.shared
    @ObservedObject var stats = StatsService.shared
    @ObservedObject var localization = LocalizationService.shared
    @StateObject var subscriptionService = SubscriptionService.shared
    @State private var showResetAlert = false
    @State private var showSubscription = false
    @State private var showBoardSettings = false
    @State private var showLanguagePicker = false
    @State private var showMailComposer = false
    @State private var showMailError = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Subscription Section
                        subscriptionSection

                        // System Settings
                        systemSection

                        // Language Section
                        languageSection

                        // Feedback Section
                        feedbackSection

                        // App Info
                        appInfoSection

                        // Danger Zone
                        dangerSection

                        // Legal
                        legalSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .alert("settings.reset.alert.title".localized, isPresented: $showResetAlert) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.reset".localized, role: .destructive) {
                    stats.resetAllStats()
                }
            } message: {
                Text("settings.reset.alert.message".localized)
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $showBoardSettings) {
                BoardSettingsView()
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerView()
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(
                    recipient: "wuyuping38@gmail.com",
                    subject: "Zip Game Feedback",
                    body: ""
                )
            }
            .alert("feedback.mail.unavailable.title".localized, isPresented: $showMailError) {
                Button("common.ok".localized, role: .cancel) { }
            } message: {
                Text("feedback.mail.unavailable.message".localized)
            }
        }
    }

    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.section.premium".localized)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            Button(action: {
                showSubscription = true
            }) {
                HStack(spacing: 14) {
                    Image(systemName: subscriptionService.isPremium ? "checkmark.seal.fill" : "star.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(subscriptionService.isPremium ? Color.green : Color.zipPrimary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(subscriptionService.isPremium ? "settings.premium.active".localized : "settings.premium.playWithoutAds".localized)
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)

                        Text(subscriptionService.isPremium ? "settings.premium.thankyou".localized : "settings.premium.description".localized)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.zipTextTertiary)
                    }

                    Spacer()

                    if !subscriptionService.isPremium {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.zipTextTertiary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.zipCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(subscriptionService.isPremium ? Color.green.opacity(0.5) : Color.zipPrimary.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .disabled(subscriptionService.isPremium)
        }
    }

    // MARK: - System Section
    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.section.system".localized)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 0) {
                // Appearance Mode
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.zipPrimary)
                            .frame(width: 32)

                        Text("settings.appearance".localized)
                            .font(.system(size: 19, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)

                        Spacer()
                    }

                    // Mode Picker
                    HStack(spacing: 10) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            AppearanceModeButton(
                                mode: mode,
                                isSelected: settings.appearanceMode == mode
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    settings.appearanceMode = mode
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 18)

                Divider().background(Color.zipCardBorder)

                // Sound
                SettingsToggleRow(
                    icon: "speaker.wave.2.fill",
                    label: "settings.sound.title".localized,
                    description: "settings.sound.description".localized,
                    isOn: $settings.soundEnabled
                )

                Divider().background(Color.zipCardBorder)

                // Haptics
                SettingsToggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    label: "settings.haptics.title".localized,
                    description: "settings.haptics.description".localized,
                    isOn: $settings.hapticsEnabled
                )

                Divider().background(Color.zipCardBorder)

                // Board Settings
                Button(action: { showBoardSettings = true }) {
                    HStack(spacing: 14) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.zipPrimary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("settings.board.title".localized)
                                .font(.system(size: 19, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.zipTextPrimary)

                            Text("settings.board.description".localized)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.zipTextTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.zipTextTertiary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 18)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.zipCardBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.section.language".localized)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            Button(action: { showLanguagePicker = true }) {
                HStack(spacing: 14) {
                    Image(systemName: "globe")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.zipPrimary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("settings.language.title".localized)
                            .font(.system(size: 19, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)

                        Text(localization.currentLanguage.displayName)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.zipTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.zipTextTertiary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.zipCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.zipCardBorder, lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Feedback Section
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.section.feedback".localized)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 0) {
                // Rate App
                Button(action: {
                    requestAppReview()
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.yellow)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("feedback.rate.title".localized)
                                .font(.system(size: 19, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.zipTextPrimary)

                            Text("feedback.rate.description".localized)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.zipTextTertiary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.zipTextTertiary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 18)
                }

                Divider().background(Color.zipCardBorder)

                // Send Feedback
                Button(action: {
                    if MFMailComposeViewController.canSendMail() {
                        showMailComposer = true
                    } else {
                        showMailError = true
                    }
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.zipPrimary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("feedback.email.title".localized)
                                .font(.system(size: 19, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.zipTextPrimary)

                            Text("feedback.email.description".localized)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.zipTextTertiary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.zipTextTertiary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 18)
                }

                Divider().background(Color.zipCardBorder)

                // Share App
                ShareLink(item: URL(string: "https://apps.apple.com/app/id6757413224")!) {
                    HStack(spacing: 14) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.green)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("feedback.share.title".localized)
                                .font(.system(size: 19, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.zipTextPrimary)

                            Text("feedback.share.description".localized)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.zipTextTertiary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.zipTextTertiary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 18)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.zipCardBorder, lineWidth: 1)
                    )
            )
        }
    }

    // Helper function for App Review
    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.section.about".localized)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 0) {
                InfoRow(icon: "info.circle.fill", label: "settings.about.version".localized, value: "1.0.0")
                Divider().background(Color.zipCardBorder)
                InfoRow(icon: "hammer.fill", label: "settings.about.build".localized, value: "1")
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.zipCardBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Danger Section
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.section.data".localized)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            Button(action: {
                showResetAlert = true
            }) {
                HStack(spacing: 14) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.red)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("settings.reset.title".localized)
                            .font(.system(size: 19, weight: .medium, design: .rounded))
                            .foregroundStyle(.red)

                        Text("settings.reset.description".localized)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.zipTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.zipTextTertiary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.zipCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.section.legal".localized)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 0) {
                // Privacy Policy
                Link(destination: URL(string: "https://ikuheikure.xyz/apps/ZipGame/")!) {
                    HStack(spacing: 14) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.zipPrimary)
                            .frame(width: 28)

                        Text("settings.legal.privacy".localized)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.zipTextTertiary)
                    }
                    .padding(.vertical, 14)
                }

                Divider().background(Color.zipCardBorder)

                // Terms of Use
                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                    HStack(spacing: 14) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.zipPrimary)
                            .frame(width: 28)

                        Text("settings.legal.terms".localized)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.zipTextPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.zipTextTertiary)
                    }
                    .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.zipCardBorder, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Language Picker View
struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var localization = LocalizationService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(AppLanguage.allCases) { language in
                            Button(action: {
                                localization.currentLanguage = language
                                dismiss()
                            }) {
                                HStack {
                                    Text(language.displayName)
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.zipTextPrimary)

                                    Spacer()

                                    if localization.currentLanguage == language {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.zipPrimary)
                                    }
                                }
                                .padding(18)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.zipCardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(localization.currentLanguage == language ? Color.zipPrimary : Color.zipCardBorder, lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("settings.language.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.zipTextTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Appearance Mode Button
struct AppearanceModeButton: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(mode.displayName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(isSelected ? .white : Color.zipTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.zipPrimary : Color.zipCardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.zipCardBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let label: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(Color.zipPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 5) {
                Text(label)
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.zipTextPrimary)

                Text(description)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.zipTextTertiary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.zipPrimary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.zipPrimary)
                .frame(width: 28)

            Text(label)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Color.zipTextPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
}
