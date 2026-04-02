import SwiftUI

/// Coordinator for the main tab-based navigation (Swipe, Dresser, Profile).
final class MainCoordinator: BaseCoordinator<MainScreen, SheetType, FullScreenCoverType> {
    // MARK: - Properties

    @Published var selectedTab: Tab = .swipe
    @Published var cardQueueService = CardQueueService()

    private let authService = AuthService.shared
    private let analyticsService = AnalyticsService.shared

    enum Tab: Int, CaseIterable {
        case swipe = 0
        case dresser = 1
        case profile = 2

        var displayName: String {
            switch self {
            case .swipe:
                return "Discover"
            case .dresser:
                return "Dresser"
            case .profile:
                return "Profile"
            }
        }

        var systemImage: String {
            switch self {
            case .swipe:
                return "sparkles"
            case .dresser:
                return "hanger"
            case .profile:
                return "person.crop.circle"
            }
        }
    }

    // MARK: - Initialization

    override init() {
        super.init()
        setupTabHandling()
    }

    // MARK: - Public Methods

    /// Switches to a specific tab.
    func selectTab(_ tab: Tab) {
        selectedTab = tab
        analyticsService.trackScreenView(tab.displayName)
    }

    /// Shows product detail in sheet.
    func showProductDetail(for product: Product) {
        presentSheet(.productDetail(product: product))
        analyticsService.trackProductViewed(product, source: "sheet")
    }

    /// Shows drawer detail view.
    func showDrawerDetail(drawerId: UUID) {
        push(.drawerDetail(drawerId: drawerId))
    }

    /// Opens a web view with the given URL.
    func openWebView(url: URL, title: String) {
        presentSheet(.webView(url: url, title: title))
    }

    /// Shows filter options.
    func showFilterOptions() {
        presentSheet(.filterOptions)
    }

    /// Shows sort options.
    func showSortOptions() {
        presentSheet(.sortOptions)
    }

    /// Shows drawer creation flow.
    func showCreateDrawer() {
        presentSheet(.drawerCreation)
    }

    /// Shows share options for a product.
    func showShareOptions(for product: Product) {
        presentSheet(.shareProduct(product: product))
    }

    /// Handles profile navigation (sign out, settings, etc).
    func handleProfileAction(_ action: ProfileAction) {
        switch action {
        case .viewSettings:
            push(.profile)
        case .signOut:
            signOut()
        case .viewStyleDNA:
            // Navigate to style DNA view
            break
        case .viewSavedItems:
            selectTab(.dresser)
        }
    }

    /// Signs out and returns to auth flow.
    func signOut() {
        authService.signOut()
        navigationPath = NavigationPath()
        popToRoot()
    }

    override func handle(deepLink: DeepLink) {
        switch deepLink {
        case .product(let id):
            push(.productDetail(productId: id))

        case .dresser(let id):
            selectTab(.dresser)
            push(.drawerDetail(drawerId: id))

        case .styleDNA:
            selectTab(.profile)

        case .invite(let code):
            // Handle invite redirect
            print("Opening invite with code: \(code)")

        case .sale(let id):
            selectTab(.swipe)
            push(.productDetail(productId: id))

        case .dailyDrop:
            selectTab(.swipe)

        case .dresserSaleFilter(let retailerId):
            selectTab(.dresser)

        case .swipeFeed:
            selectTab(.swipe)

        case .unknown:
            break
        }
    }

    // MARK: - Private Methods

    private func setupTabHandling() {
        // Initialize analytics for the initial tab
        analyticsService.trackScreenView(selectedTab.displayName)

        // Set up card queue
        Task {
            await cardQueueService.initializeQueue()
        }
    }
}

// MARK: - Profile Action Enum

enum ProfileAction {
    case viewSettings
    case signOut
    case viewStyleDNA
    case viewSavedItems
}
