import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .today

    enum Tab: String, CaseIterable {
        case today = "Today"
        case journey = "Journey"
        case settings = "My"

        var icon: String {
            switch self {
            case .today: return "calendar"
            case .journey: return "safari"
            case .settings: return "person"
            }
        }

        var selectedIcon: String {
            switch self {
            case .today: return "calendar"
            case .journey: return "safari.fill"
            case .settings: return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.today)

                JourneyView()
                    .tag(Tab.journey)

                SettingsView()
                    .tag(Tab.settings)
            }

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(Color.zipBackgroundEnd)
                .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
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
                    .foregroundStyle(selectedTab == tab ? Color.zipPrimary : .white.opacity(0.4))

                Text(tab.rawValue)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(selectedTab == tab ? Color.zipPrimary : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
}
