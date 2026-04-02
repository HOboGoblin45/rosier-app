import SwiftUI


/// Main tab navigation shell with Swipe, Dresser, and Profile tabs.
struct MainTabView: View {
    @Bindable var coordinator: MainCoordinator

    var body: some View {
        ZStack {
            // Tab content
            Group {
                switch coordinator.selectedTab {
                case .swipe:
                    SwipeTabView(coordinator: coordinator)

                case .dresser:
                    DresserTabView(coordinator: coordinator)

                case .profile:
                    ProfileTabView(coordinator: coordinator)
                }
            }

            // Tab bar
            VStack(spacing: 0) {
                Spacer()

                Divider()

                HStack(spacing: 0) {
                    ForEach(MainCoordinator.Tab.allCases, id: \.self) { tab in
                        TabBarItemView(
                            tab: tab,
                            isSelected: coordinator.selectedTab == tab,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    coordinator.selectTab(tab)
                                }
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 60)
                .background(Color.surfaceCard)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - Tab Bar Item

struct TabBarItemView: View {
    let tab: MainCoordinator.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(height: 24)

                Text(tab.displayName)
                    .font(Typography.micro)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(isSelected ? .brandAccent : .textSecondary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Swipe Tab Container

struct SwipeTabView: View {
    @Bindable var coordinator: MainCoordinator

    var body: some View {
        // This would contain the SwipeView from the existing swipe feature
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            VStack {
                Text("Swipe Feed")
                    .styleTitleLarge()
                    .foregroundColor(.textPrimary)
                    .padding()

                Spacer()

                // Placeholder for SwipeView
                Text("Product card swipe feed would render here")
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)

                Spacer()
            }
        }
    }
}

// MARK: - Dresser Tab Container

struct DresserTabView: View {
    @Bindable var coordinator: MainCoordinator
    @State private var dresserViewModel = DresserViewModel()
    @State private var showDresserModal = true

    var body: some View {
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            DresserView(viewModel: dresserViewModel)
        }
    }
}

// MARK: - Profile Tab Container

struct ProfileTabView: View {
    @Bindable var coordinator: MainCoordinator
    @State private var profileViewModel = ProfileViewModel()

    var body: some View {
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            ProfileView(viewModel: profileViewModel)
        }
    }
}

// MARK: - Preview

#Preview {
    @State var coordinator = MainCoordinator()
    return MainTabView(coordinator: coordinator)
        .preferredColorScheme(.light)
}
