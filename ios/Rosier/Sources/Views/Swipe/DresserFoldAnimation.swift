import UIKit
import SwiftUI

/// Handles the signature dresser fold animation for super-like swipe-up gesture.
final class DresserFoldAnimationController {
    // MARK: - Animation Parameters

    private let totalDuration = 0.8
    private let phase1Duration = 0.3 // Lift and shrink (0-0.3s)
    private let phase2Duration = 0.3 // Fold (0.3-0.6s)
    private let phase3Duration = 0.2 // Fly to dresser (0.6-0.8s)

    // MARK: - Public Methods

    /// Executes the dresser fold animation.
    /// - Parameters:
    ///   - cardView: The card view to animate
    ///   - dresserPosition: The final position for the dresser icon
    ///   - completion: Called when animation completes
    func animate(
        cardView: UIView,
        dresserPosition: CGPoint,
        completion: @escaping () -> Void
    ) {
        // Check for reduced motion
        if UIAccessibility.isReduceMotionEnabled {
            animateReducedMotion(cardView: cardView, dresserPosition: dresserPosition, completion: completion)
            return
        }

        // Create snapshot before animation
        guard let snapshot = cardView.snapshotImage() else {
            completion()
            return
        }

        // Container for animation
        let animationContainer = UIView()
        animationContainer.frame = cardView.frame
        cardView.superview?.insertSubview(animationContainer, belowSubview: cardView)

        // Hide original card
        cardView.alpha = 0

        // Phase 1: Lift and shrink (0-0.3s)
        phase1Lift(snapshot: snapshot, container: animationContainer) { [weak self] in
            guard let self = self else { return }

            // Phase 2: Fold (0.3-0.6s)
            self.phase2Fold(snapshot: snapshot, container: animationContainer) { [weak self] in
                guard let self = self else { return }

                // Phase 3: Fly to dresser (0.6-0.8s)
                self.phase3Fly(
                    snapshot: snapshot,
                    container: animationContainer,
                    dresserPosition: dresserPosition
                ) {
                    animationContainer.removeFromSuperview()
                    completion()
                }
            }
        }
    }

    // MARK: - Animation Phases

    /// Phase 1: Lift and shrink the card (0-0.3s).
    private func phase1Lift(
        snapshot: UIImage,
        container: UIView,
        completion: @escaping () -> Void
    ) {
        let imageView = UIImageView(image: snapshot)
        imageView.frame = container.bounds
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        container.addSubview(imageView)

        // Increase shadow
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.3
        imageView.layer.shadowOffset = CGSize(width: 0, height: 12)
        imageView.layer.shadowRadius = 16

        // Animate scale and position
        let startFrame = imageView.frame
        let endFrame = CGRect(
            x: startFrame.midX - (startFrame.width * 0.7) / 2,
            y: startFrame.midY - (startFrame.height * 0.7) / 2 - 80,
            width: startFrame.width * 0.7,
            height: startFrame.height * 0.7
        )

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)

        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = imageView.layer.position
        animation.toValue = CGPoint(x: endFrame.midX, y: endFrame.midY)
        animation.duration = phase1Duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        imageView.layer.add(animation, forKey: "phase1Position")

        let scaleAnimation = CABasicAnimation(keyPath: "bounds")
        scaleAnimation.fromValue = imageView.layer.bounds
        scaleAnimation.toValue = CGRect(
            x: 0,
            y: 0,
            width: startFrame.width * 0.7,
            height: startFrame.height * 0.7
        )
        scaleAnimation.duration = phase1Duration
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        imageView.layer.add(scaleAnimation, forKey: "phase1Scale")

        imageView.layer.position = CGPoint(x: endFrame.midX, y: endFrame.midY)
        imageView.layer.bounds = CGRect(
            x: 0,
            y: 0,
            width: startFrame.width * 0.7,
            height: startFrame.height * 0.7
        )

        CATransaction.commit()
    }

    /// Phase 2: Fold the card like a garment (0.3-0.6s).
    private func phase2Fold(
        snapshot: UIImage,
        container: UIView,
        completion: @escaping () -> Void
    ) {
        // Find the imageview from phase 1
        guard let imageView = container.subviews.first(where: { $0 is UIImageView }) as? UIImageView else {
            completion()
            return
        }

        // Create top and bottom halves
        let fullFrame = imageView.bounds
        let halfHeight = fullFrame.height / 2

        let topHalf = UIImage.slice(image: snapshot, rect: CGRect(
            x: 0,
            y: 0,
            width: fullFrame.width,
            height: halfHeight
        ))

        let bottomHalf = UIImage.slice(image: snapshot, rect: CGRect(
            x: 0,
            y: halfHeight,
            width: fullFrame.width,
            height: halfHeight
        ))

        let topView = UIImageView(image: topHalf)
        topView.frame = CGRect(
            x: fullFrame.minX,
            y: fullFrame.minY,
            width: fullFrame.width,
            height: halfHeight
        )
        topView.layer.cornerRadius = 20
        topView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        topView.clipsToBounds = true
        container.addSubview(topView)

        let bottomView = UIImageView(image: bottomHalf)
        bottomView.frame = CGRect(
            x: fullFrame.minX,
            y: fullFrame.minY + halfHeight,
            width: fullFrame.width,
            height: halfHeight
        )
        bottomView.layer.cornerRadius = 20
        bottomView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        bottomView.clipsToBounds = true
        container.addSubview(bottomView)

        // Hide original
        imageView.alpha = 0

        // Animate top half fold (rotate down)
        var perspective = CATransform3D()
        perspective.m34 = -1.0 / 500.0

        topView.layer.transform = perspective
        topView.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        topView.layer.position = CGPoint(
            x: topView.layer.position.x,
            y: topView.layer.position.y + halfHeight / 2
        )

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            imageView.removeFromSuperview()
            completion()
        }

        let foldAnimation = CABasicAnimation(keyPath: "transform")
        foldAnimation.fromValue = CATransform3D()
        foldAnimation.toValue = CATransform3DMakeRotation(CGFloat.pi / 2, 1, 0, 0)
        foldAnimation.duration = phase2Duration
        foldAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        topView.layer.add(foldAnimation, forKey: "fold")

        topView.layer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 1, 0, 0)

        CATransaction.commit()
    }

    /// Phase 3: Fly to dresser icon with arc (0.6-0.8s).
    private func phase3Fly(
        snapshot: UIImage,
        container: UIView,
        dresserPosition: CGPoint,
        completion: @escaping () -> Void
    ) {
        guard let topView = container.subviews.first(where: { $0 is UIImageView }) as? UIImageView else {
            completion()
            return
        }

        let startPosition = topView.layer.position
        let endPosition = dresserPosition

        // Create bezier arc path
        let path = UIBezierPath()
        path.move(to: startPosition)

        let controlPoint = CGPoint(
            x: (startPosition.x + endPosition.x) / 2,
            y: startPosition.y - 100
        )
        path.addQuadCurve(to: endPosition, controlPoint: controlPoint)

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            topView.removeFromSuperview()
            completion()
        }

        let pathAnimation = CAKeyframeAnimation(keyPath: "position")
        pathAnimation.path = path.cgPath
        pathAnimation.duration = phase3Duration
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        topView.layer.add(pathAnimation, forKey: "fly")

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 0.3
        scaleAnimation.duration = phase3Duration
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        topView.layer.add(scaleAnimation, forKey: "scale")

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = phase3Duration
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        topView.layer.add(opacityAnimation, forKey: "opacity")

        topView.layer.position = endPosition
        topView.layer.transform = CATransform3DMakeScale(0.3, 0.3, 0.3)
        topView.layer.opacity = 0

        CATransaction.commit()
    }

    /// Reduced motion animation: simple fade and scale to dresser.
    private func animateReducedMotion(
        cardView: UIView,
        dresserPosition: CGPoint,
        completion: @escaping () -> Void
    ) {
        guard let snapshot = cardView.snapshotImage() else {
            completion()
            return
        }

        let animationContainer = UIView()
        animationContainer.frame = cardView.frame
        cardView.superview?.insertSubview(animationContainer, belowSubview: cardView)

        cardView.alpha = 0

        let imageView = UIImageView(image: snapshot)
        imageView.frame = animationContainer.bounds
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        animationContainer.addSubview(imageView)

        UIView.animate(
            withDuration: 0.4,
            animations: {
                imageView.alpha = 0
                imageView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                imageView.center = dresserPosition
            },
            completion: { _ in
                animationContainer.removeFromSuperview()
                completion()
            }
        )
    }
}

// MARK: - UIView Extension for Snapshots

extension UIView {
    /// Creates a snapshot image of the view.
    func snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        drawHierarchy(in: bounds, afterScreenUpdates: false)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - UIImage Extension for Slicing

extension UIImage {
    /// Slices a portion of the image.
    static func slice(image: UIImage, rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let scaledRect = CGRect(
            x: rect.origin.x * image.scale,
            y: rect.origin.y * image.scale,
            width: rect.width * image.scale,
            height: rect.height * image.scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
