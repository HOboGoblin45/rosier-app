import SwiftUI

/// Main app entry point for Rosier.
@main
struct RosierApp: App {
    // MARK: - Properties

    @StateObject private var appCoordinator = AppCoordinator()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appCoordinator.authState {
                case .checking:
                    SplashScreenView()

                case .unauthenticated:
                    AuthFlowContainer(coordinator: appCoordinator)

                case .authenticating:
                    SplashScreenView()

                case .authenticated:
                    MainTabView(coordinator: appCoordinator)

                case .onboarding:
                    OnboardingFlowContainer(coordinator: appCoordinator)
                }
            }
            .preferredColorScheme(nil) // Respect system dark mode
            .onOpenURL { url in
                _ = appCoordinator.deepLinkService.handleURL(url)
            }
        }
    }
}

// MARK: - Auth Flow Container

struct AuthFlowContainer: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            // Auth flow UI here
            VStack {
                Text("Sign In or Create Account")
                    .styleTitleLarge()
                    .foregroundColor(.textPrimary)

                Button(action: {
                    coordinator.showAuthentication()
                }) {
                    Text("Continue")
                        .styleTitleMedium()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .background(Color.surfaceBackground)
        .ignoresSafeArea()
    }
}

// MARK: - Onboarding Flow Container

struct OnboardingFlowContainer: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var onboardingCoordinator = OnboardingCoordinator(
        onComplete: {}
    )

    var body: some View {
        ZStack {
            // Onboarding flow UI here
            VStack {
                Text("Complete Your Style Profile")
                    .styleTitleLarge()
                    .foregroundColor(.textPrimary)

                Button(action: {
                    coordinator.completeOnboarding()
                }) {
                    Text("Get Started")
                        .styleTitleMedium()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .background(Color.surfaceBackground)
        .ignoresSafeArea()
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Swipe Tab
            Text("Swipe View")
                .tabItem {
                    Label(
                        MainCoordinator.Tab.swipe.displayName,
                        systemImage: MainCoordinator.Tab.swipe.systemImage
                    )
                }
                .tag(MainCoordinator.Tab.swipe)

            // Dresser Tab
            Text("Dresser View")
                .tabItem {
                    Label(
                        MainCoordinator.Tab.dresser.displayName,
                        systemImage: MainCoordinator.Tab.dresser.systemImage
                    )
                }
                .tag(MainCoordinator.Tab.dresser)

            // Profile Tab
            Text("Profile View")
                .tabItem {
                    Label(
                        MainCoordinator.Tab.profile.displayName,
                        systemImage: MainCoordinator.Tab.profile.systemImage
                    )
                }
                .tag(MainCoordinator.Tab.profile)
        }
        .background(Color.surfaceBackground)
    }
}

// MARK: - Splash Screen

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.brandAccent)

                Text("Rosier")
                    .styleDisplayLarge()
                    .foregroundColor(.textPrimary)

                ProgressView()
                    .tint(.brandAccent)
            }
        }
    }
}

// MARK: - Extension for Deep Link Service Access

extension AppCoordinator {
    var deepLinkService: DeepLinkService {
        DeepLinkService.shared
    }
}

// Note: The extension for AppCoordinator to access NetworkService
extension AuthService {
    var networkService: NetworkService {
        NetworkService.shared
    }
}
