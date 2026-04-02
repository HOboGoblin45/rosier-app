import SwiftUI

/// Animation constants and timing curves for consistent app behavior.
enum Animations {
    // MARK: - Spring Animations

    /// Card spring animation: response 0.35, damping 0.8
    static var cardSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.8)
    }

    /// Sheet presentation animation: response 0.4, damping 0.85
    static var sheetPresentation: Animation {
        .spring(response: 0.4, dampingFraction: 0.85)
    }

    /// Button press animation: response 0.2, damping 0.6
    static var buttonPress: Animation {
        .spring(response: 0.2, dampingFraction: 0.6)
    }

    /// Badge pulse animation: response 0.2, damping 0.5
    static var badgePulse: Animation {
        .spring(response: 0.2, dampingFraction: 0.5)
    }

    // MARK: - Duration-Based Animations

    /// Card exit duration: 0.25 seconds
    static var cardExitDuration: TimeInterval {
        0.25
    }

    /// Dresser fold animation duration: 0.8 seconds
    static var dresserFoldDuration: TimeInterval {
        0.8
    }

    // MARK: - Wallpaper Reveal Animation Parameters

    /// Wallpaper reveal fade-in duration: 0.2 seconds
    static var wallpaperRevealDuration: TimeInterval {
        0.2
    }

    /// Wallpaper dismiss fade-out duration: 0.3 seconds
    static var wallpaperDismissDuration: TimeInterval {
        0.3
    }

    /// Wallpaper parallax motion factor: 0.15 (inverse motion multiplier)
    /// As the card moves 1pt, the wallpaper shifts 0.15pt in opposite direction
    static var wallpaperParallaxFactor: CGFloat {
        0.15
    }

    /// Maximum wallpaper opacity in light mode: 0.06
    static var wallpaperMaxOpacityLight: CGFloat {
        0.06
    }

    /// Maximum wallpaper opacity in dark mode: 0.08
    static var wallpaperMaxOpacityDark: CGFloat {
        0.08
    }

    /// Gaussian blur radius for wallpaper pattern: 2.0 points
    static var wallpaperBlurRadius: CGFloat {
        2.0
    }

    // MARK: - Reduced Motion Animations

    /// Fade animation for reduced motion: 0.3 seconds
    static var reducedMotionFade: TimeInterval {
        0.3
    }

    /// Scale animation for reduced motion: 0.2 seconds
    static var reducedMotionScale: TimeInterval {
        0.2
    }

    // MARK: - Easing Functions

    /// Linear easing
    static var linear: Animation {
        .linear
    }

    /// Ease in out
    static var easeInOut: Animation {
        .easeInOut
    }

    /// Ease in
    static var easeIn: Animation {
        .easeIn
    }

    /// Ease out
    static var easeOut: Animation {
        .easeOut
    }

    // MARK: - Convenience Methods

    /// Create a custom spring animation with specified parameters.
    /// - Parameters:
    ///   - response: Spring response time in seconds
    ///   - dampingFraction: Damping fraction (0-1)
    /// - Returns: Configured spring animation
    static func customSpring(response: Double, dampingFraction: Double) -> Animation {
        .spring(response: response, dampingFraction: dampingFraction)
    }

    /// Create a timed animation.
    /// - Parameter duration: Animation duration in seconds
    /// - Returns: Configured timed animation
    static func timed(duration: TimeInterval) -> Animation {
        .easeInOut(duration: duration)
    }

    /// Create a delay followed by an animation.
    /// - Parameters:
    ///   - delay: Delay before animation starts in seconds
    ///   - animation: Animation to apply after delay
    /// - Returns: Combined animation with delay
    static func withDelay(_ delay: TimeInterval, _ animation: Animation = .default) -> Animation {
        animation.delay(delay)
    }
}

// MARK: - View Extensions for Common Animations

extension View {
    /// Applies card spring animation with default spring parameters.
    func withCardSpringAnimation() -> some View {
        animation(Animations.cardSpring)
    }

    /// Applies sheet presentation animation.
    func withSheetPresentation() -> some View {
        animation(Animations.sheetPresentation)
    }

    /// Applies button press animation.
    func withButtonPressAnimation() -> some View {
        animation(Animations.buttonPress)
    }

    /// Applies a fade transition.
    func withFadeTransition() -> some View {
        transition(.opacity)
    }

    /// Applies a scale transition.
    func withScaleTransition() -> some View {
        transition(.scale)
    }

    /// Applies a combined fade and scale transition.
    func withFadeAndScaleTransition() -> some View {
        transition(.scale.combined(with: .opacity))
    }
}
