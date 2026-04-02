import SwiftUI
import UIKit

// MARK: - Spacing Enum

enum ViewSpacing: CGFloat {
    case xxSmall = 4
    case xSmall = 8
    case small = 12
    case medium = 16
    case large = 24
    case xLarge = 32
    case xxLarge = 48
}

// MARK: - Conditional Modifiers

extension View {
    /// Applies a modifier only when a condition is true.
    /// - Parameters:
    ///   - condition: The condition to check
    ///   - modifier: The modifier to apply if condition is true
    @ViewBuilder func `if`<Content: View>(
        _ condition: Bool,
        @ViewBuilder transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies one of two modifiers based on a condition.
    /// - Parameters:
    ///   - condition: The condition to check
    ///   - ifTrue: The modifier to apply if condition is true
    ///   - ifFalse: The modifier to apply if condition is false
    @ViewBuilder func ifElse<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        @ViewBuilder ifTrue: (Self) -> TrueContent,
        @ViewBuilder ifFalse: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
}

// MARK: - Accessibility Modifiers

extension View {
    /// Adds accessibility label and hint.
    func withAccessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        accessibility(label: Text(label))
            .if(hint != nil) { view in
                view.accessibility(hint: Text(hint ?? ""))
            }
            .accessibilityElement(children: .ignore)
    }
}

// MARK: - Layout Modifiers

extension View {
    /// Centers the view both horizontally and vertically.
    func center() -> some View {
        ZStack {
            self
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func designSystemPadding(_ amount: ViewSpacing = .medium) -> some View {
        padding(amount.rawValue)
    }

    /// Applies padding only to specific edges.
    func paddingEdges(_ edges: Edge.Set, _ amount: ViewSpacing = .medium) -> some View {
        padding(edges, amount.rawValue)
    }
}

// MARK: - Shape Modifiers

extension View {
    /// Applies a corner radius with optional border.
    func customCornerRadius(
        _ radius: CGFloat,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1
    ) -> some View {
        self
            .cornerRadius(radius)
            .if(borderColor != nil) { view in
                view
                    .border(borderColor ?? .clear, width: borderWidth)
            }
    }

    /// Creates a rounded rectangle container.
    func roundedContainer(
        cornerRadius: CGFloat = 12,
        backgroundColor: Color = .surfaceCard,
        shadowRadius: CGFloat = 4
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(radius: shadowRadius, y: 2)
    }
}

// MARK: - Loading and Error States

extension View {
    /// Shows a loading overlay when the condition is true.
    @ViewBuilder func loadingOverlay(_ isLoading: Bool) -> some View {
        ZStack {
            self

            if isLoading {
                ZStack {
                    Color.black.opacity(0.2)

                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.brandAccent)

                        Text("Loading...")
                            .styleCaption()
                            .foregroundColor(.textSecondary)
                    }
                }
                .ignoresSafeArea()
            }
        }
    }

    /// Shows an error message when present.
    @ViewBuilder func errorAlert(
        title: String = "Error",
        message: Binding<String?>
    ) -> some View {
        self.alert(
            title,
            isPresented: .constant(message.wrappedValue != nil),
            presenting: message.wrappedValue
        ) { _ in
            Button("OK") {
                message.wrappedValue = nil
            }
        } message: { errorMessage in
            Text(errorMessage)
        }
    }
}

// MARK: - Interactive Modifiers

extension View {
    /// Adds a tap-to-dismiss gesture for sheets/modals.
    func dismissOnTap() -> some View {
        self.contentShape(Rectangle()).onTapGesture { }
    }

    /// Adds haptic feedback on interaction.
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.ImpactFeedbackStyle = .light) -> some View {
        self.onTapGesture {
            HapticsManager.shared.buttonPress()
        }
    }
}

// MARK: - Text Selection and Copying

extension View {
    /// Allows text selection and copying in the view.
    func selectableCopy() -> some View {
        self
            .textSelection(.enabled)
            .onLongPressGesture(minimumDuration: 0.5) {
                HapticsManager.shared.selection()
            }
    }

    /// Enables text selection for easy copying (referral codes, etc).
    func selectableText() -> some View {
        self
            .textSelection(.enabled)
    }
}

// MARK: - Visibility Modifiers

extension View {
    /// Hides the view while keeping its space in layout.
    func invisible(_ isHidden: Bool = true) -> some View {
        opacity(isHidden ? 0 : 1)
    }

    /// Removes the view from layout when hidden.
    @ViewBuilder func hidden(_ isHidden: Bool = true) -> some View {
        if !isHidden {
            self
        }
    }
}

// MARK: - Frame Extensions

extension View {
    /// Sets the view to fill available space.
    func fillAvailable() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Creates a square frame with equal width and height.
    func squareFrame(_ size: CGFloat) -> some View {
        frame(width: size, height: size)
    }
}

// MARK: - Debug Modifiers (dev only)

extension View {
    /// Shows the view frame bounds (debug).
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        border(color, width: width)
    }

    /// Prints debug information.
    func debugPrint(_ prefix: String = "") -> Self {
        #if DEBUG
        print("\(prefix): \(type(of: self))")
        #endif
        return self
    }
}
