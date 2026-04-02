import SwiftUI
import UIKit

/// SwiftUI wrapper around custom UIView for card stack with gesture handling.
struct CardStackView: UIViewRepresentable {
    let currentCard: CardQueueItem?
    let nextCard: CardQueueItem?
    let thirdCard: CardQueueItem?

    var onSwipeLeft: () -> Void = {}
    var onSwipeRight: () -> Void = {}
    var onSwipeUp: () -> Void = {}
    var onSwipeDown: () -> Void = {}
    var onTap: () -> Void = {}
    var dresserPosition: CGPoint = .zero

    func makeUIView(context: Context) -> CardStackUIView {
        let view = CardStackUIView()
        view.onSwipeLeft = onSwipeLeft
        view.onSwipeRight = onSwipeRight
        view.onSwipeUp = onSwipeUp
        view.onSwipeDown = onSwipeDown
        view.onTap = onTap
        view.dresserPosition = dresserPosition
        return view
    }

    func updateUIView(_ uiView: CardStackUIView, context: Context) {
        uiView.updateCards(current: currentCard, next: nextCard, third: thirdCard)
    }
}

// MARK: - Custom UIView for Card Stack

/// UIView that manages the card stack with pan and tap gesture recognition.
final class CardStackUIView: UIView {
    // MARK: - Properties

    var onSwipeLeft: () -> Void = {}
    var onSwipeRight: () -> Void = {}
    var onSwipeUp: () -> Void = {}
    var onSwipeDown: () -> Void = {}
    var onTap: () -> Void = {}
    var dresserPosition: CGPoint = .zero

    private var cardViews: [UIView] = []
    private var currentCardView: UIView?
    private var nextCardView: UIView?
    private var thirdCardView: UIView?

    private var panGesture: UIPanGestureRecognizer?
    private var tapGesture: UITapGestureRecognizer?

    private var dragStartPoint: CGPoint = .zero
    private var initialCardCenter: CGPoint = .zero
    private var lastMovementDistance: CGFloat = 0

    // Animation controller
    private let dresserFoldAnimator = DresserFoldAnimationController()

    // Wallpaper reveal view
    private let wallpaperRevealView = WallpaperRevealView()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupGestures()
    }

    // MARK: - Setup

    /// Sets up the wallpaper reveal view behind the card stack.
    private func setupView() {
        insertSubview(wallpaperRevealView, at: 0)
    }

    // MARK: - Public Methods

    /// Updates the visible cards in the stack.
    func updateCards(current: CardQueueItem?, next: CardQueueItem?, third: CardQueueItem?) {
        // Remove old card views
        cardViews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()

        // Create new card views
        if let third = third {
            thirdCardView = createCardView(for: third, scale: 0.9, offset: 16)
            if let view = thirdCardView {
                addSubview(view)
                cardViews.append(view)
            }
        }

        if let next = next {
            nextCardView = createCardView(for: next, scale: 0.95, offset: 8)
            if let view = nextCardView {
                addSubview(view)
                cardViews.append(view)
            }
        }

        if let current = current {
            currentCardView = createCardView(for: current, scale: 1.0, offset: 0)
            if let view = currentCardView {
                addSubview(view)
                cardViews.append(view)
            }
        }

        // Reset pan gesture tracking
        dragStartPoint = .zero
        initialCardCenter = .zero
        lastMovementDistance = 0

        // Reset wallpaper when new card appears
        wallpaperRevealView.reset()
    }

    /// Updates the wallpaper pattern for the user's style archetype.
    /// - Parameter archetype: The user's style archetype (de Gournay, Phillip Jeffries, etc.)
    func updateWallpaperPattern(for archetype: StyleArchetype) {
        wallpaperRevealView.updatePattern(for: archetype, animated: true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        wallpaperRevealView.frame = bounds
    }

    // MARK: - Private Methods

    /// Creates a card view for the given queue item.
    private func createCardView(
        for item: CardQueueItem,
        scale: CGFloat,
        offset: CGFloat
    ) -> UIView {
        let hostingController = UIHostingController(
            rootView: ProductCardView(card: item) { [weak self] in
                self?.onTap()
            }
        )

        guard let view = hostingController.view else {
            return UIView()
        }

        // Calculate frame
        let cardWidth = bounds.width - 64 // 32pt padding on each side
        let cardHeight = bounds.height * 0.7

        let x = (bounds.width - cardWidth * scale) / 2
        let y = (bounds.height * 0.7 - cardHeight * scale) / 2 + offset

        view.frame = CGRect(
            x: x,
            y: y,
            width: cardWidth * scale,
            height: cardHeight * scale
        )

        view.layer.cornerRadius = 20
        view.clipsToBounds = true

        return view
    }

    /// Sets up gesture recognizers.
    private func setupGestures() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        if let panGesture = panGesture {
            addGestureRecognizer(panGesture)
        }

        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        if let tapGesture = tapGesture {
            addGestureRecognizer(tapGesture)
        }
    }

    /// Handles pan gesture for swipe detection.
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let cardView = currentCardView else { return }

        let location = gesture.location(in: self)
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)

        switch gesture.state {
        case .began:
            dragStartPoint = location
            initialCardCenter = cardView.center
            lastMovementDistance = 0

        case .changed:
            let dx = translation.x
            let dy = translation.y

            // Check if we've moved more than 20pt to cancel tap
            lastMovementDistance = sqrt(dx * dx + dy * dy)

            // Apply rubber-banding during drag (1:1 follow)
            cardView.center = CGPoint(
                x: initialCardCenter.x + dx,
                y: initialCardCenter.y + dy
            )

            // Update rotation based on horizontal drag
            let rotation = (dx / bounds.width) * 0.3 // Max 0.3 radians
            cardView.transform = CGAffineTransform(rotationAngle: rotation)

            // Update wallpaper reveal effect
            wallpaperRevealView.updateDisplacement(dx, maxDisplacement: 100)

        case .cancelled, .ended:
            handlePanEnd(gesture, cardView: cardView, velocity: velocity, translation: translation)

        default:
            break
        }
    }

    /// Handles the end of pan gesture to determine swipe action.
    private func handlePanEnd(
        _ gesture: UIPanGestureRecognizer,
        cardView: UIView,
        velocity: CGPoint,
        translation: CGPoint
    ) {
        let absX = abs(translation.x)
        let absY = abs(translation.y)

        // Swipe UP: >120pt vertical up, velocity >600pt/s
        if absY > 120 && translation.y < 0 && velocity.y < -600 {
            executeSwipeUp(cardView: cardView)
            return
        }

        // Swipe DOWN / Undo: >80pt down
        if absY > 80 && translation.y > 0 {
            executeSwipeDown(cardView: cardView)
            return
        }

        // Swipe LEFT: >100pt horizontal, velocity >500pt/s leftward
        if absX > 100 && translation.x < 0 && velocity.x < -500 {
            executeSwipeLeft(cardView: cardView)
            return
        }

        // Swipe RIGHT: >100pt horizontal, velocity >500pt/s rightward
        if absX > 100 && translation.x > 0 && velocity.x > 500 {
            executeSwipeRight(cardView: cardView)
            return
        }

        // Partial swipe: spring back to center
        springBackToCenter(cardView: cardView)
    }

    /// Executes left swipe (reject).
    private func executeSwipeLeft(cardView: UIView) {
        HapticsManager.shared.swipeLeft()

        // Fade out wallpaper as card exits
        wallpaperRevealView.animateOpacity(to: 0, duration: Animations.wallpaperDismissDuration)

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                cardView.center.x = self.bounds.width + 200
                cardView.transform = CGAffineTransform(rotationAngle: -.pi / 12)
                cardView.alpha = 0
            },
            completion: { _ in
                self.onSwipeLeft()
                self.animateStackForward()
            }
        )
    }

    /// Executes right swipe (like) with heart pulse overlay.
    private func executeSwipeRight(cardView: UIView) {
        HapticsManager.shared.swipeRight()

        // Fade out wallpaper as card exits
        wallpaperRevealView.animateOpacity(to: 0, duration: Animations.wallpaperDismissDuration)

        // Heart pulse overlay
        let heartPulse = UIView()
        addSubview(heartPulse)

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                cardView.center.x = -200
                cardView.transform = CGAffineTransform(rotationAngle: .pi / 12)
                cardView.alpha = 0
            },
            completion: { _ in
                self.onSwipeRight()
                self.animateStackForward()
            }
        )
    }

    /// Executes up swipe (super like) with dresser fold animation.
    private func executeSwipeUp(cardView: UIView) {
        HapticsManager.shared.superLike()

        // Fade out wallpaper as card exits
        wallpaperRevealView.animateOpacity(to: 0, duration: Animations.wallpaperDismissDuration)

        dresserFoldAnimator.animate(
            cardView: cardView,
            dresserPosition: dresserPosition
        ) { [weak self] in
            self?.onSwipeUp()
            self?.animateStackForward()
        }
    }

    /// Executes down swipe (undo).
    private func executeSwipeDown(cardView: UIView) {
        HapticsManager.shared.undo()
        onSwipeDown()
    }

    /// Springs card back to center for partial swipe.
    private func springBackToCenter(cardView: UIView) {
        let springDamping: CGFloat = 0.75
        let springResponse: TimeInterval = 0.3

        // Fade out wallpaper as card returns
        wallpaperRevealView.animateOpacity(to: 0, duration: springResponse)

        UIView.animate(
            withDuration: springResponse,
            delay: 0,
            usingSpringWithDamping: springDamping,
            initialSpringVelocity: 0.1,
            options: .curveEaseOut,
            animations: {
                cardView.center = self.initialCardCenter
                cardView.transform = .identity
            },
            completion: nil
        )
    }

    /// Animates the stack forward (next card becomes front).
    private func animateStackForward() {
        guard let nextView = nextCardView else { return }

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.1,
            options: .curveEaseOut,
            animations: {
                // Next card moves to front (1.0 scale)
                nextView.transform = CGAffineTransform(scaleX: 1.0 / 0.95, y: 1.0 / 0.95)
                nextView.frame.origin.y -= 8

                // Third card moves up
                if let thirdView = self.thirdCardView {
                    thirdView.transform = CGAffineTransform(scaleX: 0.95 / 0.9, y: 0.95 / 0.9)
                    thirdView.frame.origin.y -= 8
                }
            },
            completion: nil
        )
    }

    /// Handles tap gesture on card.
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // Only trigger tap if movement was minimal (< 20pt)
        if lastMovementDistance < 20 {
            onTap()
        }
    }
}
