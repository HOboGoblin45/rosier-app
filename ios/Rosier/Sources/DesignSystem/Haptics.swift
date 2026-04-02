import UIKit

/// Centralized haptic feedback manager using UIImpactFeedbackGenerator and UINotificationFeedbackGenerator.
public final class HapticsManager {
    public static let shared = HapticsManager()

    private init() {}

    // MARK: - Haptic Feedback Methods

    /// Light impact feedback for swipe left.
    public func swipeLeft() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact feedback for swipe right.
    public func swipeRight() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact combined with success notification for super like.
    public func superLike() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    /// Soft impact feedback for undo action.
    public func undo() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Light impact feedback for button press.
    public func buttonPress() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Selection feedback for list item selection.
    public func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Warning notification feedback.
    public func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error notification feedback.
    public func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Success notification feedback.
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
