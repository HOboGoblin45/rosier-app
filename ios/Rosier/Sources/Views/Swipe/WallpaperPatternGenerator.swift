import UIKit
import RosierCore

/// Generates procedural wallpaper patterns for the card reveal effect.
/// Each pattern is designed to be subtle, elegant, and tileable for background rendering.
final class WallpaperPatternGenerator {
    // MARK: - Pattern Cache

    private static let patternCache = NSCache<NSString, UIImage>()

    // MARK: - Public Methods

    /// Generates a Chinoiserie-style pattern (delicate branches and blossoms).
    /// Inspired by de Gournay luxury wallpaper aesthetic.
    /// - Parameters:
    ///   - size: Pattern tile size (default 200x200pt)
    ///   - tintColor: Color to apply to the pattern
    /// - Returns: Tileable UIImage pattern
    static func generateChinoiserie(size: CGSize = CGSize(width: 200, height: 200), tintColor: UIColor) -> UIImage {
        let cacheKey = "chinoiserie_\(size.width)_\(size.height)_\(tintColor.hashValue)" as NSString
        if let cached = patternCache.object(forKey: cacheKey) {
            return cached
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            // Fill background with white
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))

            // Draw delicate curved branches
            let paths = [
                // Branch 1
                UIBezierPath().with { path in
                    path.move(to: CGPoint(x: 20, y: 150))
                    path.addCurve(to: CGPoint(x: 180, y: 50),
                                 controlPoint1: CGPoint(x: 60, y: 180),
                                 controlPoint2: CGPoint(x: 150, y: 80))
                },
                // Branch 2
                UIBezierPath().with { path in
                    path.move(to: CGPoint(x: 170, y: 140))
                    path.addCurve(to: CGPoint(x: 30, y: 60),
                                 controlPoint1: CGPoint(x: 130, y: 170),
                                 controlPoint2: CGPoint(x: 50, y: 40))
                },
                // Branch 3
                UIBezierPath().with { path in
                    path.move(to: CGPoint(x: 100, y: 180))
                    path.addCurve(to: CGPoint(x: 150, y: 30),
                                 controlPoint1: CGPoint(x: 90, y: 120),
                                 controlPoint2: CGPoint(x: 160, y: 60))
                }
            ]

            tintColor.setStroke()
            cgContext.setLineWidth(0.8)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            cgContext.setAlpha(0.3)

            for path in paths {
                path.stroke()
            }

            // Add small circular blossoms at branch endpoints
            cgContext.setAlpha(0.4)
            cgContext.setFillColor(tintColor.cgColor)

            let blossomPositions = [
                CGPoint(x: 180, y: 50),
                CGPoint(x: 30, y: 60),
                CGPoint(x: 150, y: 30),
                CGPoint(x: 20, y: 150),
                CGPoint(x: 170, y: 140),
                CGPoint(x: 100, y: 180)
            ]

            for position in blossomPositions {
                cgContext.fillEllipse(in: CGRect(
                    x: position.x - 2.5,
                    y: position.y - 2.5,
                    width: 5,
                    height: 5
                ))
            }
        }

        patternCache.setObject(image, forKey: cacheKey)
        return image
    }

    /// Generates a grasscloth-style pattern (woven texture).
    /// Inspired by Phillip Jeffries luxury grasscloth wallpaper.
    /// - Parameters:
    ///   - size: Pattern tile size (default 200x200pt)
    ///   - tintColor: Color to apply to the pattern
    /// - Returns: Tileable UIImage pattern
    static func generateGrasscloth(size: CGSize = CGSize(width: 200, height: 200), tintColor: UIColor) -> UIImage {
        let cacheKey = "grasscloth_\(size.width)_\(size.height)_\(tintColor.hashValue)" as NSString
        if let cached = patternCache.object(forKey: cacheKey) {
            return cached
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            // Fill background with subtle base
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))

            // Draw horizontal woven strands
            tintColor.setStroke()
            cgContext.setLineWidth(1.2)
            cgContext.setAlpha(0.15)

            let strandSpacing: CGFloat = 3.5
            var y: CGFloat = 0

            while y < size.height {
                cgContext.move(to: CGPoint(x: 0, y: y))
                cgContext.addLine(to: CGPoint(x: size.width, y: y))
                cgContext.strokePath()
                y += strandSpacing
            }

            // Add slight vertical variation for texture
            cgContext.setAlpha(0.1)
            cgContext.setLineWidth(0.6)

            var x: CGFloat = 0
            while x < size.width {
                let yOffset = sin((x / size.width) * CGFloat.pi * 2) * 1.5
                cgContext.move(to: CGPoint(x: x, y: 0 + yOffset))
                cgContext.addLine(to: CGPoint(x: x, y: size.height + yOffset))
                cgContext.strokePath()
                x += 8
            }
        }

        patternCache.setObject(image, forKey: cacheKey)
        return image
    }

    /// Generates a bold geometric print pattern.
    /// Inspired by Schumacher luxury wallpaper with large-scale motifs.
    /// - Parameters:
    ///   - size: Pattern tile size (default 200x200pt)
    ///   - tintColor: Color to apply to the pattern
    /// - Returns: Tileable UIImage pattern
    static func generateBoldPrint(size: CGSize = CGSize(width: 200, height: 200), tintColor: UIColor) -> UIImage {
        let cacheKey = "boldprint_\(size.width)_\(size.height)_\(tintColor.hashValue)" as NSString
        if let cached = patternCache.object(forKey: cacheKey) {
            return cached
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            // Fill background
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))

            // Draw large-scale diamond lattice
            cgContext.setAlpha(0.25)
            cgContext.setFillColor(tintColor.cgColor)
            cgContext.setStrokeColor(tintColor.cgColor)
            cgContext.setLineWidth(1.0)

            let diamondSize: CGFloat = 45
            var yOffset: CGFloat = 0

            while yOffset < size.height + diamondSize {
                var xOffset: CGFloat = 0
                while xOffset < size.width + diamondSize {
                    let centerX = xOffset + diamondSize / 2
                    let centerY = yOffset + diamondSize / 2

                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: centerX, y: centerY - diamondSize / 2))
                    path.addLine(to: CGPoint(x: centerX + diamondSize / 2, y: centerY))
                    path.addLine(to: CGPoint(x: centerX, y: centerY + diamondSize / 2))
                    path.addLine(to: CGPoint(x: centerX - diamondSize / 2, y: centerY))
                    path.close()

                    // Alternate filled and outlined
                    if Int((xOffset + yOffset) / diamondSize) % 2 == 0 {
                        cgContext.setAlpha(0.2)
                        path.fill()
                    } else {
                        cgContext.setAlpha(0.12)
                        path.stroke()
                    }

                    xOffset += diamondSize
                }
                yOffset += diamondSize
            }
        }

        patternCache.setObject(image, forKey: cacheKey)
        return image
    }

    /// Generates a zoological pattern with stylized animal silhouettes.
    /// Inspired by Scalamandr é luxury animal wallpaper.
    /// - Parameters:
    ///   - size: Pattern tile size (default 200x200pt)
    ///   - tintColor: Color to apply to the pattern
    /// - Returns: Tileable UIImage pattern
    static func generateZoological(size: CGSize = CGSize(width: 200, height: 200), tintColor: UIColor) -> UIImage {
        let cacheKey = "zoological_\(size.width)_\(size.height)_\(tintColor.hashValue)" as NSString
        if let cached = patternCache.object(forKey: cacheKey) {
            return cached
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            // Fill background
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))

            cgContext.setFillColor(tintColor.cgColor)
            cgContext.setAlpha(0.28)

            // Draw stylized bird silhouettes
            let positions = [
                CGPoint(x: 50, y: 40),
                CGPoint(x: 150, y: 70),
                CGPoint(x: 80, y: 140),
                CGPoint(x: 160, y: 160)
            ]

            for position in positions {
                drawBirdSilhouette(in: cgContext, at: position)
            }

            // Draw decorative circular elements
            cgContext.setAlpha(0.15)
            cgContext.setLineWidth(1.2)
            cgContext.setStrokeColor(tintColor.cgColor)

            let circlePositions = [
                CGPoint(x: 30, y: 120),
                CGPoint(x: 170, y: 50),
                CGPoint(x: 100, y: 180)
            ]

            for position in circlePositions {
                cgContext.addEllipse(in: CGRect(
                    x: position.x - 15,
                    y: position.y - 15,
                    width: 30,
                    height: 30
                ))
                cgContext.strokePath()
            }
        }

        patternCache.setObject(image, forKey: cacheKey)
        return image
    }

    // MARK: - Private Helper Methods

    /// Draws a stylized bird silhouette using Bezier curves.
    private static func drawBirdSilhouette(in cgContext: CGContext, at position: CGPoint) {
        let path = UIBezierPath()

        // Simple bird shape: body, head, tail
        // Body (ellipse)
        path.addEllipse(in: CGRect(x: position.x - 8, y: position.y - 4, width: 10, height: 6))

        // Head (small circle)
        path.addEllipse(in: CGRect(x: position.x + 3, y: position.y - 5, width: 5, height: 5))

        // Tail feathers (curved lines)
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: position.x - 8, y: position.y))
        tailPath.addCurve(to: CGPoint(x: position.x - 16, y: position.y + 2),
                         controlPoint1: CGPoint(x: position.x - 10, y: position.y - 3),
                         controlPoint2: CGPoint(x: position.x - 14, y: position.y + 2))

        path.append(tailPath)
        path.fill()
    }

    /// Clears the pattern cache (useful for memory management).
    static func clearCache() {
        patternCache.removeAllObjects()
    }
}

// MARK: - UIBezierPath Extension

extension UIBezierPath {
    /// Convenience method for creating paths with a closure.
    func with(_ closure: (UIBezierPath) -> Void) -> UIBezierPath {
        closure(self)
        return self
    }
}
