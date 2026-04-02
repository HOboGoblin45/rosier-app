import SwiftUI

/// Coordinator managing the onboarding flow (Welcome → StyleQuiz → Confirmation).
public final class OnboardingCoordinator: BaseCoordinator<OnboardingScreen, SheetType, FullScreenCoverType> {
    // MARK: - Properties

    @Published var quizResponses: QuizResponses?
    @Published var selectedArchetype: String?

    private let authService = AuthService.shared
    private var onComplete: (() -> Void)?

    // MARK: - Initialization

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        super.init()
    }

    // MARK: - Public Methods

    /// Starts the onboarding flow.
    func startOnboarding() {
        navigationPath = NavigationPath()
        push(.welcome)
    }

    /// Proceeds to the style quiz.
    func proceedToQuiz() {
        push(.styleQuiz)
    }

    /// Completes the style quiz with responses.
    func completeQuiz(with responses: QuizResponses, archetype: String) {
        self.quizResponses = responses
        self.selectedArchetype = archetype
        push(.styleQuizResults)

        // Track analytics
        AnalyticsService.shared.trackQuizCompleted(archetype: archetype)
    }

    /// Finishes onboarding and returns to main flow.
    func finishOnboarding() {
        // Save quiz responses to user profile
        Task {
            do {
                try await authService.fetchCurrentUser()
                DispatchQueue.main.async {
                    self.onComplete?()
                }
            } catch {
                print("Failed to complete onboarding: \(error)")
            }
        }
    }

    /// Handles skipping steps.
    func skipStep() {
        pop()
    }

    override func handle(deepLink: DeepLink) {
        // Onboarding coordinator doesn't handle deep links
    }
}
