import SwiftUI

/// View for new users to enter a referral code during onboarding.
struct ReferralCodeEntryView: View {
    // MARK: - Properties

    @State private var viewModel = ReferralViewModel()
    @State private var enteredCode = ""
    @State private var validationError: String?
    @State private var isApplying = false
    @State private var successMessage: String?
    var onSuccess: (() -> Void)?
    var onSkip: (() -> Void)?

    // MARK: - Computed Properties

    var formattedCode: String {
        let cleaned = enteredCode.uppercased().replacingOccurrences(of: "-", with: "")
        if cleaned.count > 8 {
            return String(cleaned.prefix(8))
        }

        if cleaned.count >= 5 {
            return String(cleaned.prefix(5)) + "-" + String(cleaned.dropFirst(5))
        }

        return cleaned
    }

    var isValidFormat: Bool {
        viewModel.validateReferralCodeFormat(formattedCode)
    }

    var isButtonDisabled: Bool {
        !isValidFormat || isApplying
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.brandAccent)

                    VStack(spacing: 8) {
                        Text("Have a Referral Code?")
                            .styleDisplayMedium()
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Enter the code from a friend to get exclusive rewards")
                            .styleCaption()
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 32)
                .padding(.horizontal, 16)

                Spacer()

                // Input Section
                VStack(spacing: 16) {
                    // Code Input Field
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.brandAccent)
                                .frame(width: 24)

                            TextField("ROSIE-XXXX", text: $enteredCode)
                                .textContentType(.none)
                                .autocorrectionDisabled()
                                .font(Typography.body)
                                .foregroundColor(.textPrimary)
                                .tracking(2)
                                .onChange(of: enteredCode) { _, newValue in
                                    enteredCode = newValue.uppercased()
                                    if !newValue.isEmpty {
                                        validationError = nil
                                    }
                                }

                            if isValidFormat {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.successGreen)
                                    .transition(.scale)
                            }
                        }
                        .padding(14)
                        .background(Color.surfaceCard)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    validationError != nil ? Color.saleRed.opacity(0.5) :
                                    isValidFormat ? Color.successGreen.opacity(0.3) :
                                    Color.textTertiary.opacity(0.2),
                                    lineWidth: 1.5
                                )
                        )

                        // Error Message
                        if let error = validationError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))

                                Text(error)
                                    .styleCaption()
                                    .lineLimit(2)
                            }
                            .foregroundColor(.saleRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity)
                        }
                    }

                    // Info Card
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.brandAccent)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Code Format")
                                    .styleCaption()
                                    .foregroundColor(.textPrimary)
                                    .fontWeight(.semibold)

                                Text("Example: ROSIE-ABC1 (auto-formatted as you type)")
                                    .styleMicro()
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()
                        }
                    }
                    .padding(12)
                    .background(Color.brandAccent.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: submitCode) {
                        if isApplying {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.brandPrimary)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Apply Code")
                                    .styleBodyBold()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.brandPrimary)
                            .background(Color.brandAccent)
                            .cornerRadius(12)
                        }
                    }
                    .disabled(isButtonDisabled)
                    .opacity(isButtonDisabled ? 0.5 : 1.0)

                    Button(action: {
                        onSkip?()
                    }) {
                        Text("Skip for Now")
                            .styleBodyBold()
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.brandAccent)
                            .background(Color.surfaceCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brandAccent, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .alert("Success", isPresented: .constant(successMessage != nil)) {
            Button("Continue") {
                onSuccess?()
            }
        } message: {
            if let message = successMessage {
                Text(message)
            }
        }
    }

    // MARK: - Actions

    private func submitCode() {
        validationError = nil

        guard isValidFormat else {
            validationError = "Invalid code format. Use ROSIE-XXXX"
            return
        }

        isApplying = true

        Task {
            let success = await viewModel.applyReferralCode(formattedCode, source: "onboarding")

            DispatchQueue.main.async {
                isApplying = false

                if success {
                    successMessage = "Great! Your referral code has been applied. You'll start earning rewards immediately."
                } else {
                    validationError = viewModel.error ?? "Failed to apply code. Please try again."
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReferralCodeEntryView(
        onSuccess: { print("Success") },
        onSkip: { print("Skip") }
    )
    .preferredColorScheme(.light)
}
