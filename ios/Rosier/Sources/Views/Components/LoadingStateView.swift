import SwiftUI

/// Reusable loading state view with animated Rosier logo and optional message.
/// Used across the app when content is being fetched or processed.
struct LoadingStateView: View {
    /// Optional loading message to display below the animation.
    var message: String?

    /// Whether to show a skeleton placeholder for the swipe feed.
    var showCardPlaceholder: Bool = false

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            // Animated logo
            VStack(spacing: 16) {
                // Animated circle rings
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.brandAccent.opacity(0.3),
                                    Color.brandAccent.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.3 : 0.8)

                    // Inner rotating ring
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.brandAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .frame(width: 60, height: 60)

                    // Center dot
                    Circle()
                        .fill(Color.brandAccent)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 80, height: 80)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }

                // Loading text
                if let message = message {
                    Text(message)
                        .styleBody()
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }

            // Skeleton placeholder for card
            if showCardPlaceholder {
                VStack(spacing: 12) {
                    // Image placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceCard)
                        .frame(height: 300)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.textTertiary.opacity(0.2), lineWidth: 1)
                        )
                        .shimmer()

                    // Text placeholders
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.surfaceCard)
                            .frame(height: 12)
                            .frame(maxWidth: 120)
                            .shimmer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.surfaceCard)
                            .frame(height: 10)
                            .frame(maxWidth: .infinity)
                            .shimmer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.surfaceCard)
                            .frame(height: 10)
                            .frame(maxWidth: 200)
                            .shimmer()
                    }
                }
                .padding(16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceBackground)
    }
}

// MARK: - Shimmer Modifier

extension View {
    /// Applies a shimmer loading animation to the view.
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var isShimmering = false

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.2),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isShimmering ? 400 : -400)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isShimmering)
                .onAppear {
                    isShimmering = true
                }
            )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        LoadingStateView(message: "Loading your feed...")

        Divider()

        LoadingStateView(
            message: "Generating your Style DNA",
            showCardPlaceholder: true
        )
    }
    .preferredColorScheme(.light)
}
