import SwiftUI
import RosierCore

/// Reusable error state view for displaying user-friendly error messages.
/// Supports optional "Try Again" and "Contact Support" actions.
struct ErrorStateView: View {
    // MARK: - Types

    enum ErrorType {
        case networkError
        case serverError
        case notFound
        case custom(title: String, message: String, icon: String)

        var icon: String {
            switch self {
            case .networkError:
                return "wifi.slash"
            case .serverError:
                return "exclamationmark.circle"
            case .notFound:
                return "magnifyingglass"
            case let .custom(_, _, icon):
                return icon
            }
        }

        var title: String {
            switch self {
            case .networkError:
                return "No Internet Connection"
            case .serverError:
                return "Something Went Wrong"
            case .notFound:
                return "Not Found"
            case let .custom(title, _, _):
                return title
            }
        }

        var message: String {
            switch self {
            case .networkError:
                return "Please check your internet connection and try again."
            case .serverError:
                return "We're having trouble on our end. Please try again in a moment."
            case .notFound:
                return "The item you're looking for couldn't be found."
            case let .custom(_, message, _):
                return message
            }
        }

        var isPersistent: Bool {
            switch self {
            case .serverError, .notFound:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Properties

    let type: ErrorType
    var onRetry: (() -> Void)?
    var onContactSupport: (() -> Void)?
    var errorMessage: String?

    // MARK: - State

    @State private var isAnimating = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with animation
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.saleRed.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)

                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.saleRed)
            }
            .frame(width: 120, height: 120)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }

            // Text content
            VStack(spacing: 8) {
                Text(type.title)
                    .styleTitleMedium()
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 4) {
                    Text(type.message)
                        .styleCaption()
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .styleFootnote()
                            .foregroundColor(.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: 280)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                if let onRetry = onRetry {
                    Button(action: onRetry) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Try Again")
                                .styleBodyBold()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.brandPrimary)
                        .background(Color.brandAccent)
                        .cornerRadius(12)
                    }
                }

                if type.isPersistent || onContactSupport != nil {
                    Button(action: onContactSupport ?? {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Contact Support")
                                .styleBodyBold()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.brandAccent)
                        .background(Color.surfaceCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.brandAccent, lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                }

                // Help text
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .semibold))
                    Text("If this error persists, please contact support")
                        .styleFootnote()
                }
                .foregroundColor(.textTertiary)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceBackground)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ErrorStateView(
            type: .networkError,
            onRetry: {}
        )

        Divider()

        ErrorStateView(
            type: .serverError,
            onRetry: {},
            onContactSupport: {}
        )

        Divider()

        ErrorStateView(
            type: .custom(
                title: "Failed to Load",
                message: "The content couldn't be loaded at this time.",
                icon: "exclamationmark.triangle"
            ),
            onRetry: {}
        )
    }
    .preferredColorScheme(.light)
}
