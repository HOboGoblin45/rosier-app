import SwiftUI

/// Welcome screen with parallax product collage and entry actions.
struct WelcomeView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var onGetStarted: () -> Void
    var onSignIn: () -> Void

    @State private var scrollOffset: CGFloat = 0
    @State private var parallaxImages: [String] = [
        "silhouette-fitted",
        "silhouette-oversized",
        "silhouette-minimalist",
        "silhouette-structured",
        "palette-earth",
        "palette-jewel",
        "palette-neutral",
        "palette-vibrant"
    ]

    var body: some View {
        ZStack {
            // Parallax collage background
            VStack(spacing: 0) {
                // Top half with parallax effect
                ZStack(alignment: .center) {
                    // Solid color backdrop (replaced gradient)
                    Color.brandPrimary.opacity(0.08)
                        .ignoresSafeArea()

                    // Product collage with parallax (0.3x speed)
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.surfaceCard)
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                )

                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.surfaceCard)
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                )
                        }

                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.surfaceCard)
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                )

                            VStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.surfaceCard)
                                    .frame(height: 54)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                    )

                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.surfaceCard)
                                    .frame(height: 54)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(20)
                    .offset(y: scrollOffset * 0.3)

                    // 60% opacity scrim
                    Color.black
                        .opacity(0.6)
                        .ignoresSafeArea()
                }
                .frame(maxHeight: .infinity)

                // Content section
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    // Headline
                    Text("Your taste. Your brands. Your feed.")
                        .styleDisplayLarge()
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                    // Subheadline
                    Text("Swipe to discover niche fashion from 50+ curated retailers.")
                        .font(Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    Spacer()
                        .frame(height: 40)

                    // Get Started button
                    Button(action: onGetStarted) {
                        Text("Get Started")
                            .font(Typography.bodyBold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.brandAccent)
                            .foregroundColor(.brandPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 16)

                    // Sign In button
                    Button(action: onSignIn) {
                        Text("Already have an account? Sign In")
                            .font(Typography.caption)
                            .foregroundColor(.brandAccent)
                    }
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
                .background(Color.surfaceBackground)
            }

            // Parallax scroll tracking
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
            }
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        .coordinateSpace(name: "scroll")
    }
}

// MARK: - Helper Types

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(
        onGetStarted: {},
        onSignIn: {}
    )
}
