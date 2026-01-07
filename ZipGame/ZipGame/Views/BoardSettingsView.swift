import SwiftUI

enum BoardSettingsTab: String, CaseIterable {
    case colors = "Colors"
    case font = "Font"
}

struct BoardSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeService = ThemeService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedTab: BoardSettingsTab = .colors
    @State private var showSubscription = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Premium Banner (if not premium)
                    if !subscriptionService.isPremium {
                        premiumBanner
                    }

                    // Preview Section
                    previewSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Tab Selector
                    tabSelector
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Content based on tab
                    ScrollView(showsIndicators: false) {
                        switch selectedTab {
                        case .colors:
                            colorsContent
                        case .font:
                            fontContent
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.zipTextSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.zipPrimary)
                }
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
        }
    }

    // MARK: - Premium Banner
    private var premiumBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.zipPrimary.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.zipPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Unlock Premium Features")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.zipTextPrimary)
                Text("Customize colors, fonts & create your perfect theme")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color.zipTextTertiary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: { showSubscription = true }) {
                Text("Upgrade")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.zipPrimary))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.zipCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.zipPrimary.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 12) {
            // Mini grid preview
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { row in
                    VStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col
                            let isPath = [0, 1, 4, 7, 8].contains(index)
                            let number = index == 0 ? 1 : (index == 8 ? 5 : nil)

                            PreviewCellView(
                                number: number,
                                isPath: isPath,
                                theme: themeService.selectedBoardTheme,
                                font: themeService.selectedFontTheme
                            )
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.zipCardBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(BoardSettingsTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .white : Color.zipTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.zipPrimary : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.zipCardBackground)
                .overlay(
                    Capsule()
                        .stroke(Color.zipCardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Colors Content
    private var colorsContent: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(BoardTheme.allCases) { theme in
                ThemeCard(
                    theme: theme,
                    isSelected: themeService.selectedBoardTheme == theme,
                    isPremium: subscriptionService.isPremium
                ) {
                    if theme.isPremium && !subscriptionService.isPremium {
                        showSubscription = true
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            themeService.selectedBoardTheme = theme
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }

    // MARK: - Font Content
    private var fontContent: some View {
        VStack(spacing: 12) {
            ForEach(FontTheme.allCases) { font in
                FontRow(
                    font: font,
                    isSelected: themeService.selectedFontTheme == font,
                    isPremium: subscriptionService.isPremium
                ) {
                    if font.isPremium && !subscriptionService.isPremium {
                        showSubscription = true
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            themeService.selectedFontTheme = font
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
}

// MARK: - Preview Cell View
struct PreviewCellView: View {
    let number: Int?
    let isPath: Bool
    let theme: BoardTheme
    let font: FontTheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isPath ? theme.pathColor : theme.emptyColor)
                .frame(width: 50, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isPath ? Color.white.opacity(0.3) : Color.zipCardBorder, lineWidth: 1)
                )

            if let num = number {
                Text("\(num)")
                    .font(font.font(size: 22, weight: .bold))
                    .foregroundColor(isPath ? .white : Color.zipTextPrimary)
            } else if isPath {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 12, height: 12)
            }
        }
    }
}

// MARK: - Theme Card
struct ThemeCard: View {
    let theme: BoardTheme
    let isSelected: Bool
    let isPremium: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Mini preview grid
                HStack(spacing: 4) {
                    VStack(spacing: 4) {
                        miniCell(color: theme.pathColor, hasNumber: true)
                        miniCell(color: theme.emptyColor, hasNumber: false)
                    }
                    VStack(spacing: 4) {
                        miniCell(color: theme.emptyColor, hasNumber: false)
                        miniCell(color: theme.pathColor, hasNumber: true)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.zipCardBackground.opacity(0.5))
                )

                // Theme name
                Text(theme.displayName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.zipTextPrimary)
                    .lineLimit(1)

                // Lock icon for premium themes
                if theme.isPremium && !isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.zipTextTertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.zipPrimary : Color.zipCardBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func miniCell(color: Color, hasNumber: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 28, height: 28)

            if hasNumber {
                Text("1")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(color == theme.pathColor ? .white : Color.zipTextPrimary)
            }
        }
    }
}

// MARK: - Font Row
struct FontRow: View {
    let font: FontTheme
    let isSelected: Bool
    let isPremium: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(font.displayName)
                    .font(font.font(size: 20, weight: .medium))
                    .foregroundColor(Color.zipTextPrimary)

                Spacer()

                if font.isPremium && !isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.zipTextTertiary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.zipPrimary)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.zipPrimary : Color.zipCardBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BoardSettingsView()
}
