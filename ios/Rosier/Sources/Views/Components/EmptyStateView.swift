import SwiftUI

/// Reusable empty state view for various scenarios throughout the app.
/// Supports custom icons, titles, subtitles, and optional action buttons.
struct EmptyStateView: View {
    // MARK: - Types

    enum EmptyStateType {
        case emptyDresser
        case emptyDrawer
        case feedEnd
        case noStyleDNA
        case custom(icon: String, title: String, subtitle: String)

        var icon: String {
            switch self {
            case .emptyDresser:
                return "archivebox"
            case .emptyDrawer:
                return "hanger"
            case .feedEnd:
                return "checkmark.circle"
            case .noStyleDNA:
                return "sparkles"
            case let .custom(icon, _, _):
                return icon
            }
        }

        var title: String {
            switch self {
            case .emptyDresser:
                return "Your Dresser is Empty"
            case .emptyDrawer:
                return "No Items Yet"
            case .feedEnd:
                return "You're All Caught Up"
            case .noStyleDNA:
                return "Unlock Your Style DNA"
            case let .custom(_, title, _):
                return title
            }
        }

        var subtitle: String {
            switch self {
            case .emptyDresser:
                return "Swipe right on items you love to add them to your Dresser"
            case .emptyDrawer:
                return "Swipe up on items in the feed to save them to this drawer"
            case .feedEnd:
                return "You've seen everything! Come back tomorrow for fresh styles"
            case .noStyleDNA:
                return "Swipe 100+ items to discover your unique style profile"
            case let .custom(_, _, subtitle):
                return subtitle
            }
        }

        var actions: [EmptyStateAction] {
            switch self {
            case .emptyDresser:
                return [
                    EmptyStateAction(
                        label: "Start Swiping",
                        action: {}
                    )
                ]
            case .emptyDrawer:
                return []
            case .feedEnd:
                return [
                    EmptyStateAction(
                        label: "Change Filters",
                        action: {}
                    ),
                    EmptyStateAction(
                        label: "Browse Dresser",
                        action: {},
                        style: .secondary
                    )
                ]
            case .noStyleDNA:
                return []
            case .custom:
                return []
            }
        }

        var showProgressRing: Bool {
            switch self {
            case .noStyleDNA:
                return true
            default:
                return false
            }
        }

        var progressValue: Double {
            switch self {
            case .noStyleDNA:
                return 0.7
            default:
                return 0.0
            }
        }
    }

    // MARK: - Properties

    let type: EmptyStateType
    var actions: [EmptyStateAction]?

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
                    .fill(Color.brandAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .opacity(isAnimating ? 0.5 : 0.3)

                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.brandAccent)
            }
            .frame(width: 120, height: 120)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }

            // Text content
            VStack(spacing: 8) {
                Text(type.title)
                    .styleTitleMedium()
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(type.subtitle)
                    .styleCaption()
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .frame(maxWidth: 280)

            // Progress ring for Style DNA
            if type.showProgressRing {
                VStack(spacing: 12) {
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.textTertiary.opacity(0.2), lineWidth: 3)

                        // Progress circle
                        Circle()
                            .trim(from: 0, to: type.progressValue)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.brandAccent,
                                        Color.saleRed.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        // Center text
                        VStack(spacing: 2) {
                            Text("\(Int(type.progressValue * 100))")
                                .styleDisplayMedium()
                                .foregroundColor(.textPrimary)

                            Text("of 100+ swipes")
                                .styleCaption()
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .frame(width: 100, height: 100)

                    Text("Keep swiping to unlock")
                        .styleCaption()
                        .foregroundColor(.textTertiary)
                }
            }

            Spacer()

            // Action buttons
            let buttonActions = actions ?? type.actions
            if !buttonActions.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(buttonActions.enumerated()), id: \.offset) { _, action in
                        EmptyStateButton(action: action)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceBackground)
    }
}

// MARK: - Empty State Action

struct EmptyStateAction {
    enum Style {
        case primary
        case secondary

        var backgroundColor: Color {
            switch self {
            case .primary:
                return Color.brandAccent
            case .secondary:
                return Color.surfaceCard
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary:
                return Color.brandPrimary
            case .secondary:
                return Color.brandAccent
            }
        }

        var borderColor: Color? {
            switch self {
            case .primary:
                return nil
            case .secondary:
                return Color.brandAccent
            }
        }
    }

    let label: String
    let action: () -> Void
    var style: Style = .primary
}

// MARK: - Empty State Button

struct EmptyStateButton: View {
    let action: EmptyStateAction

    var body: some View {
        Button(action: action.action) {
            Text(action.label)
                .styleBodyBold()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(action.style.foregroundColor)
                .background(action.style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(action.style.borderColor ?? .clear, lineWidth: 1)
                )
                .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        EmptyStateView(type: .emptyDresser)

        Divider()

        EmptyStateView(type: .feedEnd)

        Divider()

        EmptyStateView(type: .noStyleDNA)
    }
    .preferredColorScheme(.light)
}
