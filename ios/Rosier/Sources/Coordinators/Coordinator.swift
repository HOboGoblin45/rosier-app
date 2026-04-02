import Foundation
import SwiftUI

/// Base protocol for coordinators in the app.
public protocol Coordinator: AnyObject, ObservableObject {
    associatedtype Screen: Hashable
    associatedtype Sheet: Hashable
    associatedtype FullScreenCover: Hashable

    var navigationPath: NavigationPath { get set }
    var sheet: Sheet? { get set }
    var fullScreenCover: FullScreenCover? { get set }

    func push(_ screen: Screen)
    func pop()
    func popToRoot()
    func presentSheet(_ sheet: Sheet)
    func dismissSheet()
    func presentFullScreenCover(_ cover: FullScreenCover)
    func dismissFullScreenCover()
    func handle(deepLink: DeepLink)
}

/// Default implementation of Coordinator protocol.
public class BaseCoordinator<Screen: Hashable, Sheet: Hashable, FullScreenCover: Hashable>: Coordinator {
    @Published var navigationPath = NavigationPath()
    @Published var sheet: Sheet?
    @Published var fullScreenCover: FullScreenCover?

    func push(_ screen: Screen) {
        navigationPath.append(screen)
    }

    func pop() {
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }

    func presentSheet(_ sheet: Sheet) {
        self.sheet = sheet
    }

    func dismissSheet() {
        self.sheet = nil
    }

    func presentFullScreenCover(_ cover: FullScreenCover) {
        self.fullScreenCover = cover
    }

    func dismissFullScreenCover() {
        self.fullScreenCover = nil
    }

    func handle(deepLink: DeepLink) {
        // Override in subclasses for specific handling
    }
}

// MARK: - Navigation Screen Definitions

public enum OnboardingScreen: Hashable {
    case welcome
    case styleQuiz
    case styleQuizResults
}

public enum MainScreen: Hashable {
    case swipe
    case dresser
    case profile
    case productDetail(productId: UUID)
    case drawerDetail(drawerId: UUID)
}

public enum SheetType: Hashable {
    case productDetail(product: Product)
    case filterOptions
    case sortOptions
    case drawerCreation
    case shareProduct(product: Product)
    case webView(url: URL, title: String)
}

public enum FullScreenCoverType: Hashable {
    case authentication
    case onboarding
    case styleQuiz
}
