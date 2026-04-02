import UIKit

/// Centralized haptic feedback manager using UIImpactFeedbackGenerator and UINotificationFeedbackGenerator.
final class HapticsManager {
    static let shared = HapticsManager()

    private init() {}

    // MARK: - Haptic Feedback Methods

    /// Light impact feedback for swipe left.
    func swipeLeft() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact feedback for swipe right.
    func swipeRight() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact combined with success notification for super like.
    func superLike() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    /// Soft impact feedback for undo action.
    func undo() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Light impact feedback for button press.
    func buttonPress() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Selection feedback for list item selection.
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Warning notification feedback.
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error notification feedback.
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Success notification feedback.
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
