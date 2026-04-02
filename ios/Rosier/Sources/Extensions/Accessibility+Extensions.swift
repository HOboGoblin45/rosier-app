import SwiftUI
import Accessibility

// MARK: - Card Accessibility

extension View {
    /// Applies accessibility labels and hints for product cards.
    /// Creates a comprehensive VoiceOver description for product information.
    ///
    /// - Parameters:
    ///   - brand: Brand name of the product
    ///   - product: Product name or description
    ///   - price: Product price string
    /// - Returns: View with applied accessibility modifiers
    func accessibleCard(
        brand: String,
        product: String,
        price: String
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(brand), \(product)")
            .accessibilityValue("\(price)")
            .accessibilityHint("Double tap to expand product details. Swipe right to like, left to pass.")
    }

    /// Applies accessibility labels for dresser items.
    ///
    /// - Parameters:
    ///   - brand: Brand name
    ///   - product: Product name
    ///   - price: Current price
    ///   - priceDropped: Whether the price has dropped since saving
    /// - Returns: View with applied accessibility modifiers
    func accessibleDresserItem(
        brand: String,
        product: String,
        price: String,
        priceDropped: Bool = false
    ) -> some View {
        let priceDroppedText = priceDropped ? ", Price dropped!" : ""
        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(brand), \(product)")
            .accessibilityValue("\(price)\(priceDroppedText)")
            .accessibilityHint("Double tap to view in detail. Swipe to move to another drawer.")
    }

    /// Applies accessibility labels for sale badges.
    ///
    /// - Parameters:
    ///   - discount: Discount percentage
    ///   - endsIn: Human-readable time until sale ends (e.g., "2 days")
    /// - Returns: View with applied accessibility modifiers
    func accessibleSaleBadge(
        discount: Int,
        endsIn: String
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sale")
            .accessibilityValue("\(discount)% off, ends in \(endsIn)")
    }

    /// Provides a swipe hint for the swipe feed.
    /// - Returns: View with applied accessibility hint
    func accessibleSwipeHint() -> some View {
        self
            .accessibilityHint("Swipe right to like and save, left to pass. Swipe up to super like. Swipe down to undo. Double tap to expand details.")
    }
}

// MARK: - Button Accessibility

extension View {
    /// Applies custom accessibility label to buttons, improving clarity.
    ///
    /// - Parameters:
    ///   - action: Description of the button's action
    ///   - hint: Optional hint about what happens when tapped
    /// - Returns: View with accessibility labels
    func accessibleButton(
        action: String,
        hint: String? = nil
    ) -> some View {
        var view = self
            .accessibilityLabel(action)

        if let hint = hint {
            view = view.accessibilityHint(hint)
        }

        return view
    }
}

// MARK: - Dynamic Type Scaling

extension View {
    /// Ensures text scales appropriately for Dynamic Type and doesn't break layout.
    /// Limits scaling to prevent UI distortion while respecting accessibility needs.
    ///
    /// - Parameter maxScale: Maximum scaling factor (default: 1.5, meaning up to 150% of original)
    /// - Returns: View with constrained Dynamic Type scaling
    func constrainedDynamicType(maxScale: CGFloat = 1.5) -> some View {
        self
            .lineLimit(nil)
            .dynamicTypeSize(.medium...(.xxxLarge))
    }

    /// Ensures minimum touch target size of 44x44 points per Apple's accessibility guidelines.
    /// - Returns: View with enlarged hit area if needed
    func accessibleMinimumTouchTarget(_ minSize: CGFloat = 44) -> some View {
        self
            .frame(minWidth: minSize, minHeight: minSize)
    }
}

// MARK: - Reduced Motion Support

extension View {
    /// Wraps animations to respect user's Reduce Motion setting.
    /// When Reduce Motion is enabled, uses instant or fade animations instead of spring animations.
    ///
    /// - Parameter animation: The animation to apply (will be replaced if Reduce Motion is on)
    /// - Returns: View with motion-safe animation
    func reduceMotionAnimation(_ animation: Animation = .default) -> some View {
        modifier(ReduceMotionAnimationModifier(animation: animation))
    }

    /// Applies a fade transition instead of complex transitions when Reduce Motion is enabled.
    /// - Returns: View with motion-safe transition
    func reduceMotionTransition() -> some View {
        modifier(ReduceMotionTransitionModifier())
    }

    /// Hides animated elements when Reduce Motion is enabled, showing static versions instead.
    /// - Returns: View that respects Reduce Motion setting
    func hideWhenReducedMotion() -> some View {
        modifier(HideWhenReducedMotionModifier())
    }
}

// MARK: - Reduced Motion Modifiers

struct ReduceMotionAnimationModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let animation: Animation

    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(.none)
        } else {
            content.animation(animation)
        }
    }
}

struct ReduceMotionTransitionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content.transition(.opacity)
        } else {
            content.transition(.scale.combined(with: .opacity))
        }
    }
}

struct HideWhenReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(0)
        } else {
            content
        }
    }
}

// MARK: - Color Contrast Verification

extension Color {
    /// Calculates luminance for WCAG contrast ratio calculation.
    /// Based on WCAG 2.1 luminance formula.
    var luminance: Double {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Convert RGB to linear values
        let rLinear = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let gLinear = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let bLinear = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)

        // Calculate relative luminance
        return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear
    }

    /// Calculates WCAG contrast ratio against another color.
    /// - Parameter otherColor: Color to compare against
    /// - Returns: Contrast ratio (4.5:1 is minimum for AA, 7:1 for AAA)
    func contrastRatio(against otherColor: Color) -> Double {
        let l1 = luminance
        let l2 = otherColor.luminance

        let lighter = max(l1, l2)
        let darker = min(l1, l2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Checks if contrast ratio meets WCAG AA standard (4.5:1 for normal text).
    /// - Parameter otherColor: Background color
    /// - Returns: True if contrast is sufficient
    func meetsWCAGAA(against otherColor: Color) -> Bool {
        contrastRatio(against: otherColor) >= 4.5
    }

    /// Checks if contrast ratio meets WCAG AAA standard (7:1 for normal text).
    /// - Parameter otherColor: Background color
    /// - Returns: True if contrast is sufficient
    func meetsWCAGAAA(against otherColor: Color) -> Bool {
        contrastRatio(against: otherColor) >= 7.0
    }
}

// MARK: - Text Accessibility Helpers

extension View {
    /// Ensures text has sufficient contrast against background.
    /// Adjusts text color if contrast is insufficient.
    ///
    /// - Parameters:
    ///   - textColor: Proposed text color
    ///   - backgroundColor: Background color
    /// - Returns: View with accessibility-compliant colors
    func accessibleTextColor(
        _ textColor: Color,
        against backgroundColor: Color
    ) -> some View {
        let hasContrast = textColor.meetsWCAGAA(against: backgroundColor)
        return self.foregroundColor(hasContrast ? textColor : .textPrimary)
    }

    /// Adds additional padding for text to prevent truncation in larger Dynamic Type sizes.
    /// - Returns: View with accessibility-friendly padding
    func accessibleTextPadding() -> some View {
        self.padding(.vertical, 8)
    }
}

// MARK: - Image Accessibility

extension View {
    /// Makes decorative images hidden from VoiceOver to reduce noise.
    /// - Returns: View marked as decorative for accessibility
    func decorativeImage() -> some View {
        self
            .accessibilityLabel("")
            .accessibilityHidden(true)
    }

    /// Provides a detailed description for meaningful images.
    ///
    /// - Parameter description: Detailed description of the image content
    /// - Returns: View with proper accessibility label
    func accessibleImage(_ description: String) -> some View {
        self
            .accessibilityLabel(description)
    }
}

// MARK: - Form Accessibility

extension View {
    /// Properly associates text labels with form inputs for accessibility.
    /// Ensures VoiceOver announces the label when the field is focused.
    ///
    /// - Parameters:
    ///   - label: Label text to announce
    ///   - isRequired: Whether the field is required
    /// - Returns: View with proper accessibility associations
    func accessibleFormField(
        label: String,
        isRequired: Bool = false
    ) -> some View {
        let requiredText = isRequired ? ", required" : ""
        return self
            .accessibilityLabel("\(label)\(requiredText)")
    }
}

// MARK: - Status Indicators

extension View {
    /// Announces status changes for loading, errors, or success states.
    ///
    /// - Parameters:
    ///   - message: Status message to announce
    ///   - announcement: The type of announcement
    /// - Returns: View with accessibility announcements
    func accessibleStatus(
        _ message: String,
        announcement: UIAccessibility.Announcement = .layoutChanged
    ) -> some View {
        self.onAppear {
            // Announce status change to VoiceOver
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIAccessibility.post(notification: announcement, argument: message)
            }
        }
    }
}

// MARK: - List Accessibility

extension View {
    /// Marks a view as a list container and announces item count to VoiceOver.
    ///
    /// - Parameters:
    ///   - itemCount: Number of items in the list
    ///   - description: Optional description of the list
    /// - Returns: View with list semantics
    func accessibleList(
        itemCount: Int,
        description: String? = nil
    ) -> some View {
        let hint = itemCount == 1 ? "1 item" : "\(itemCount) items"
        var view = self
            .accessibilityElement(children: .contain)
            .accessibilityLabel(description ?? "List")

        if itemCount > 0 {
            view = view.accessibilityHint(hint)
        }

        return view
    }
}

// MARK: - Semantic HTML-like Accessibility

extension View {
    /// Marks important content as a heading for navigation purposes.
    ///
    /// - Parameter level: Heading level (1 = most important, 6 = least important)
    /// - Returns: View marked as heading
    func accessibilityHeading(level: Int = 1) -> some View {
        self.accessibilityAddTraits(.isHeader)
    }

    /// Marks a button that triggers important actions (like delete or submit).
    /// - Returns: View marked as important button
    func accessibilityImportantButton() -> some View {
        self
            .accessibilityTraits(.isButton)
            .accessibilityAddTraits(.startsMediaSession)
    }
}

// MARK: - Focus Management

extension View {
    /// Announces to VoiceOver when focus moves to this element.
    ///
    /// - Parameter message: Message to announce when focused
    /// - Returns: View that announces focus changes
    func announceFocusChange(_ message: String) -> some View {
        self
            .accessibilityFocused(.constant(true))
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.focusedElementDidChangeNotification)) { _ in
                UIAccessibility.post(notification: .announcement, argument: message)
            }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            // Accessible card example
            VStack(spacing: 12) {
                Text("Accessible Product Card")
                    .styleTitleMedium()

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceCard)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Text("Product Image")
                                .styleCaption()
                                .foregroundColor(.textTertiary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lemaire")
                                    .styleBodyBold()
                                Text("Wool Blazer")
                                    .styleCaption()
                                Text("$325")
                                    .styleTitleMedium()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                            .padding(16)
                    )
                    .accessibleCard(
                        brand: "Lemaire",
                        product: "Oversized Wool Blazer",
                        price: "$325"
                    )
            }
            .padding(16)

            Divider()

            // Status announcement example
            VStack(spacing: 12) {
                Text("Status Updates")
                    .styleTitleMedium()

                HStack {
                    Circle()
                        .fill(Color.successGreen)
                        .frame(width: 12, height: 12)

                    Text("Successfully saved to Dresser")
                        .styleCaption()
                }
                .padding(12)
                .background(Color.surfaceCard)
                .cornerRadius(8)
                .accessibleStatus("Item added to your Dresser")
            }
            .padding(16)
        }
    }
    .background(Color.surfaceBackground)
    .preferredColorScheme(.light)
}
