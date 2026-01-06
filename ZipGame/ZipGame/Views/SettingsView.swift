import SwiftUI

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
        case .light: return "Light"
        case .dark: return "Dark"
        case .auto: return "Auto"
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
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // System Settings
                        systemSection

                        // App Info
                        appInfoSection

                        // Danger Zone
                        dangerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Extra padding for tab bar
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset Statistics", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    stats.resetAllStats()
                }
            } message: {
                Text("This will permanently delete all your statistics, streaks, and achievements. This action cannot be undone.")
            }
        }
    }

    // MARK: - System Section
    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System")
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

                        Text("Appearance")
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
                    label: "Sound Effects",
                    description: "Play sounds during gameplay",
                    isOn: $settings.soundEnabled
                )

                Divider().background(Color.zipCardBorder)

                // Haptics
                SettingsToggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    label: "Haptics",
                    description: "Vibration feedback on actions",
                    isOn: $settings.hapticsEnabled
                )
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

    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zipTextTertiary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 0) {
                InfoRow(icon: "info.circle.fill", label: "Version", value: "1.0.0")
                Divider().background(Color.zipCardBorder)
                InfoRow(icon: "hammer.fill", label: "Build", value: "1")
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
            Text("Data")
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
                        Text("Reset All Statistics")
                            .font(.system(size: 19, weight: .medium, design: .rounded))
                            .foregroundStyle(.red)

                        Text("Clear all progress, streaks, and achievements")
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
}

// MARK: - Appearance Mode Button
struct AppearanceModeButton: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(mode.displayName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : Color.zipTextSecondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
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

#Preview {
    SettingsView()
}
