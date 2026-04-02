import Foundation
import SwiftUI

/// ViewModel managing the onboarding quiz state and submission.
@Observable final class OnboardingViewModel {
    // MARK: - Published Properties

    var currentQuestion: Int = 0
    var quizAnswers: [Int: [Int]] = [:] // question index -> selected image indices
    var isSubmitting = false
    var submissionError: String?
    var quizStartTime: Date = Date()
    var hasCompletedQuiz = false

    // MARK: - Private Properties

    private let networkService = NetworkService.shared
    private let authService = AuthService.shared

    // MARK: - Quiz Configuration

    let totalQuestions = 5

    struct QuizQuestion {
        let id: Int
        let label: String
        let images: [String] // Placeholder image names or URLs
        let allowMultiple: Bool
    }

    let questions: [QuizQuestion] = [
        QuizQuestion(
            id: 0,
            label: "What catches your eye?",
            images: [
                "silhouette-fitted",
                "silhouette-oversized",
                "silhouette-minimalist",
                "silhouette-structured"
            ],
            allowMultiple: true
        ),
        QuizQuestion(
            id: 1,
            label: "Your color world",
            images: [
                "palette-earth",
                "palette-jewel",
                "palette-neutral",
                "palette-vibrant"
            ],
            allowMultiple: true
        ),
        QuizQuestion(
            id: 2,
            label: "Your sweet spot",
            images: [
                "price-budget",
                "price-moderate",
                "price-premium",
                "price-luxury"
            ],
            allowMultiple: true
        ),
        QuizQuestion(
            id: 3,
            label: "What do you reach for first?",
            images: [
                "category-clothing",
                "category-shoes",
                "category-bags",
                "category-accessories"
            ],
            allowMultiple: true
        ),
        QuizQuestion(
            id: 4,
            label: "Pick your mood",
            images: [
                "aesthetic-minimalist",
                "aesthetic-romantic",
                "aesthetic-edgy",
                "aesthetic-classic"
            ],
            allowMultiple: true
        )
    ]

    // MARK: - Computed Properties

    var isCurrentQuestionAnswered: Bool {
        (quizAnswers[currentQuestion]?.count ?? 0) > 0
    }

    var progress: Double {
        Double(currentQuestion) / Double(totalQuestions)
    }

    var timeElapsed: Int {
        Int(Date().timeIntervalSince(quizStartTime))
    }

    var shouldShowTimerWarning: Bool {
        timeElapsed > 60 && !hasCompletedQuiz
    }

    // MARK: - Public Methods

    func selectImage(at index: Int, for questionIndex: Int) {
        let question = questions[questionIndex]

        if question.allowMultiple {
            if quizAnswers[questionIndex] == nil {
                quizAnswers[questionIndex] = []
            }

            if let selectedIndex = quizAnswers[questionIndex]?.firstIndex(of: index) {
                quizAnswers[questionIndex]?.remove(at: selectedIndex)
            } else {
                quizAnswers[questionIndex]?.append(index)
            }
        } else {
            quizAnswers[questionIndex] = [index]
        }
    }

    func isImageSelected(at index: Int, for questionIndex: Int) -> Bool {
        quizAnswers[questionIndex]?.contains(index) ?? false
    }

    func nextQuestion() {
        guard isCurrentQuestionAnswered else { return }

        if currentQuestion < totalQuestions - 1 {
            currentQuestion += 1
        } else {
            submitQuiz()
        }
    }

    func previousQuestion() {
        if currentQuestion > 0 {
            currentQuestion -= 1
        }
    }

    func resetQuiz() {
        currentQuestion = 0
        quizAnswers = [:]
        submissionError = nil
        hasCompletedQuiz = false
        quizStartTime = Date()
        isSubmitting = false
    }

    func submitQuiz() {
        isSubmitting = true
        submissionError = nil

        Task {
            do {
                // Convert quiz answers to style preferences
                let quizResponse = QuizResponses(
                    styleArchetypes: mapAnswersToArchetypes(),
                    colorPreferences: mapAnswersToColors(),
                    fitPreferences: mapAnswersToFits(),
                    sustainabilityFocus: false,
                    preferIndependentBrands: false,
                    customResponses: [:]
                )

                let request = SubmitQuizRequest(
                    responses: quizResponse,
                    completedAt: Date(),
                    timeSpentSeconds: timeElapsed
                )

                try await networkService.requestEmpty(
                    "onboarding/quiz",
                    method: .post,
                    body: request
                )

                DispatchQueue.main.async {
                    self.hasCompletedQuiz = true
                    self.isSubmitting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.submissionError = error.localizedDescription
                    self.isSubmitting = false
                }
            }
        }
    }

    // MARK: - Private Methods

    private func mapAnswersToArchetypes() -> [String] {
        let archetypeAnswers = quizAnswers[4] ?? []
        let archetypes = [
            "Minimalist with Edge",
            "Romantic",
            "Edgy",
            "Classic"
        ]
        return archetypeAnswers.map { archetypes[$0] }
    }

    private func mapAnswersToColors() -> [String] {
        let colorAnswers = quizAnswers[1] ?? []
        let colors = [
            "Earth Tones",
            "Jewel Tones",
            "Neutrals",
            "Vibrant"
        ]
        return colorAnswers.map { colors[$0] }
    }

    private func mapAnswersToFits() -> [String] {
        let fitAnswers = quizAnswers[0] ?? []
        let fits = [
            "Fitted",
            "Oversized",
            "Minimalist",
            "Structured"
        ]
        return fitAnswers.map { fits[$0] }
    }
}

// MARK: - Request Models

struct SubmitQuizRequest: Codable {
    let responses: QuizResponses
    let completedAt: Date
    let timeSpentSeconds: Int
}
