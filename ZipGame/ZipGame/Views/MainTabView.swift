import SwiftUI
import GoogleMobileAds

struct MainTabView: View {
    @State private var selectedTab: Tab = .today
    @ObservedObject private var settings = SettingsService.shared

    enum Tab: String, CaseIterable {
        case today = "Today"
        case practice = "Practice"
        case journey = "Journey"
        case settings = "My"

        var icon: String {
            switch self {
            case .today: return "calendar"
            case .practice: return "infinity"
            case .journey: return "chart.line.uptrend.xyaxis"
            case .settings: return "person"
            }
        }

        var selectedIcon: String {
            switch self {
            case .today: return "calendar"
            case .practice: return "infinity"
            case .journey: return "chart.line.uptrend.xyaxis"
            case .settings: return "person.fill"
            }
        }

        // Show ads on these tabs
        var showAds: Bool {
            switch self {
            case .today, .practice, .journey: return true
            case .settings: return false
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.today)

                PracticeView()
                    .tag(Tab.practice)

                JourneyView()
                    .tag(Tab.journey)

                SettingsView()
                    .tag(Tab.settings)
            }

            // Banner Ad + Custom Tab Bar
            VStack(spacing: 0) {
                // Banner Ad (only show on specific tabs)
                if selectedTab.showAds {
                    BannerContainerView()
                }

                // Custom Tab Bar
                customTabBar
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch settings.appearanceMode {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(Color.zipTabBarBackground)
                .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
                .ignoresSafeArea()
        )
    }

    private func tabButton(for tab: Tab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tab ? Color.zipPrimary : Color.zipTabInactive)

                Text(tab.rawValue)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(selectedTab == tab ? Color.zipPrimary : Color.zipTabInactive)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
}
