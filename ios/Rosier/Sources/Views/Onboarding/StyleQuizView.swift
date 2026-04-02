import SwiftUI

/// Interactive style quiz with 5 visual questions.
struct StyleQuizView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onCompletion: () -> Void

    @State private var showCompletion = false

    var body: some View {
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress and navigation
                VStack(spacing: 16) {
                    HStack {
                        Button(action: { viewModel.previousQuestion() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                            }
                            .foregroundColor(.brandAccent)
                            .frame(height: 44)
                        }

                        Spacer()

                        Text("Question \(viewModel.currentQuestion + 1) of \(viewModel.totalQuestions)")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .frame(height: 44)
                        }
                    }

                    // Progress bar
                    ProgressView(value: viewModel.progress)
                        .tint(.brandAccent)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
                .padding(16)

                // Question content
                ScrollView {
                    VStack(spacing: 24) {
                        // Question title
                        Text(viewModel.questions[viewModel.currentQuestion].label)
                            .styleTitleLarge()
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)

                        // Image grid (2x2)
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            let question = viewModel.questions[viewModel.currentQuestion]

                            ForEach(Array(question.images.enumerated()), id: \.offset) { index, imageName in
                                QuizImageCard(
                                    isSelected: viewModel.isImageSelected(
                                        at: index,
                                        for: viewModel.currentQuestion
                                    ),
                                    imageName: imageName
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        viewModel.selectImage(
                                            at: index,
                                            for: viewModel.currentQuestion
                                        )
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Timer warning (if over 60 seconds)
                        if viewModel.shouldShowTimerWarning {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Complete within 90 seconds for bonus points")
                                    .font(Typography.caption)
                            }
                            .foregroundColor(.saleRed)
                            .padding(12)
                            .background(Color.saleRed.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                        }

                        Spacer()
                            .frame(height: 16)
                    }
                    .padding(.vertical, 24)
                }

                Spacer()

                // Next button
                VStack(spacing: 12) {
                    Button(action: { viewModel.nextQuestion() }) {
                        if viewModel.currentQuestion == viewModel.totalQuestions - 1 {
                            HStack(spacing: 8) {
                                Text("Complete Quiz")
                                    .font(Typography.bodyBold)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        } else {
                            Text("Next")
                                .font(Typography.bodyBold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.isCurrentQuestionAnswered ? Color.brandAccent : Color.textTertiary.opacity(0.2))
                    .foregroundColor(.brandPrimary)
                    .cornerRadius(12)
                    .disabled(!viewModel.isCurrentQuestionAnswered || viewModel.isSubmitting)
                    .opacity(viewModel.isCurrentQuestionAnswered ? 1.0 : 0.6)

                    if let error = viewModel.submissionError {
                        Text(error)
                            .font(Typography.caption)
                            .foregroundColor(.destructiveRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
        }
        .onChange(of: viewModel.hasCompletedQuiz) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCompletion = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onCompletion()
                }
            }
        }
    }
}

// MARK: - Quiz Image Card Component

struct QuizImageCard: View {
    let isSelected: Bool
    let imageName: String

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.brandAccent : Color.textTertiary.opacity(0.1),
                            lineWidth: isSelected ? 3 : 1
                        )
                )

            // Placeholder image content
            VStack(spacing: 12) {
                // Image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.surfaceBackground)
                    .frame(height: 80)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.textTertiary)
                    )

                // Label
                Text(imageName.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(Typography.footnote)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(12)

            // Checkmark overlay
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.brandAccent)
                    .padding(8)
                    .background(Color.surfaceCard)
                    .clipShape(Circle())
                    .padding(8)
            }
        }
        .background(Color.surfaceCard)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    @State var viewModel = OnboardingViewModel()
    return StyleQuizView(viewModel: viewModel) {}
}
