import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = StudyAppViewModel()
    @State private var selectedTab: AppTab = .home
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView(viewModel: viewModel)
            case .diary:
                DiaryView(viewModel: viewModel)
            case .todo:
                TodoView(viewModel: viewModel)
            case .settings:
                SettingsMenuView(viewModel: viewModel)
            }
        }
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 22)
                .padding(.bottom, 6)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                viewModel.syncTimer()
            }
        }
    }
}

private struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.primaryInk : Color.secondaryInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab
                        ? Color.accentSoft
                        : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.cardBackground.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primaryInk.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.primaryInk.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
