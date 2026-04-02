import UIKit
import CoreImage

/// A UIView that renders a luxury wallpaper pattern with parallax effect.
/// As cards are dragged, the pattern beneath is revealed with subtle inverse motion.
/// The view handles reduced motion accessibility and includes Gaussian blur for depth.
final class WallpaperRevealView: UIView {
    // MARK: - Properties

    private let patternImageView = UIImageView()
    private let containerView = UIView()

    private var displayLink: CADisplayLink?
    private var currentDisplacement: CGFloat = 0
    private var targetOpacity: CGFloat = 0

    // Current pattern and tint color
    private var currentPattern: UIImage?
    private var currentTintColor: UIColor = UIColor(hex: 0xA8C4B8)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopParallaxUpdates()
    }

    // MARK: - Public Methods

    /// Updates the wallpaper pattern for a specific style archetype.
    /// - Parameters:
    ///   - archetype: The user's style archetype determining the pattern
    ///   - animated: Whether to fade to the new pattern (default: true)
    func updatePattern(for archetype: StyleArchetype, animated: Bool = true) {
        let (pattern, tintColor) = generatePatternAndColor(for: archetype)

        currentTintColor = tintColor
        currentPattern = pattern

        if animated {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.patternImageView.alpha = 0
                },
                completion: { _ in
                    self.patternImageView.image = pattern
                    self.applyBlurFilter()

                    UIView.animate(withDuration: 0.3) {
                        self.patternImageView.alpha = self.targetOpacity
                    }
                }
            )
        } else {
            patternImageView.image = pattern
            applyBlurFilter()
            patternImageView.alpha = targetOpacity
        }
    }

    /// Updates the wallpaper displacement and opacity based on card drag.
    /// - Parameters:
    ///   - displacement: Horizontal drag distance (positive = right, negative = left)
    ///   - maxDisplacement: Maximum displacement before full opacity (typically ~100pt)
    func updateDisplacement(_ displacement: CGFloat, maxDisplacement: CGFloat = 100) {
        currentDisplacement = displacement

        // Calculate opacity progression: 0 at 0pt, target at maxDisplacement
        let progress = min(abs(displacement) / maxDisplacement, 1.0)
        targetOpacity = progress * maxOpacity()

        // Update parallax offset immediately if not using CADisplayLink
        updateParallaxOffset(displacement)
    }

    /// Animates the wallpaper opacity to a target value.
    /// - Parameters:
    ///   - opacity: Target opacity (0.0 - 1.0)
    ///   - duration: Animation duration in seconds
    func animateOpacity(to opacity: CGFloat, duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            self.patternImageView.alpha = opacity
        }
    }

    /// Resets the wallpaper to fully hidden state.
    func reset() {
        currentDisplacement = 0
        targetOpacity = 0
        patternImageView.alpha = 0

        // Reset parallax offset
        patternImageView.layer.position = CGPoint(
            x: containerView.bounds.midX,
            y: containerView.bounds.midY
        )
    }

    // MARK: - Private Methods

    private func setupView() {
        // Container with mask for card area
        containerView.clipsToBounds = true
        addSubview(containerView)

        // Pattern image view
        patternImageView.contentMode = .scaleAspectFill
        patternImageView.clipsToBounds = true
        patternImageView.alpha = 0
        containerView.addSubview(patternImageView)

        // Set initial pattern
        if let pattern = currentPattern {
            patternImageView.image = pattern
            applyBlurFilter()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.frame = bounds

        // Size pattern view to tile the pattern across the visible area
        let patternSize = CGSize(width: 200, height: 200)
        let tiledWidth = max(bounds.width, bounds.width + abs(currentDisplacement) * 2)
        let tiledHeight = bounds.height

        patternImageView.frame = CGRect(
            x: 0,
            y: 0,
            width: tiledWidth,
            height: tiledHeight
        )
    }

    /// Updates parallax offset based on drag displacement.
    /// Applies inverse motion: dragging right shifts pattern left (and vice versa).
    private func updateParallaxOffset(_ displacement: CGFloat) {
        if UIAccessibility.isReduceMotionEnabled {
            // Skip parallax for reduced motion, keep pattern centered
            return
        }

        // Parallax factor: ~15% inverse motion
        let parallaxOffset = -displacement * Animations.wallpaperParallaxFactor
        let newX = containerView.bounds.midX + parallaxOffset

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        patternImageView.layer.position.x = newX
        CATransaction.commit()
    }

    /// Applies Gaussian blur filter to the pattern for depth.
    private func applyBlurFilter() {
        guard let image = patternImageView.image else { return }

        let context = CIContext(options: nil)
        guard let ciImage = CIImage(image: image) else { return }

        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(Animations.wallpaperBlurRadius, forKey: kCIInputRadiusKey)

        if let output = filter?.outputImage,
           let cgImage = context.createCGImage(output, from: output.extent) {
            patternImageView.image = UIImage(cgImage: cgImage)
        }
    }

    /// Starts smooth 60fps parallax updates using CADisplayLink.
    private func startParallaxUpdates() {
        guard displayLink == nil else { return }

        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateParallaxFrame)
        )
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    /// Stops CADisplayLink updates.
    private func stopParallaxUpdates() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateParallaxFrame() {
        updateParallaxOffset(currentDisplacement)
    }

    /// Determines the maximum opacity for the wallpaper based on light/dark mode.
    private func maxOpacity() -> CGFloat {
        let traitCollection = self.traitCollection
        return traitCollection.userInterfaceStyle == .dark
            ? Animations.wallpaperMaxOpacityDark
            : Animations.wallpaperMaxOpacityLight
    }

    /// Generates the appropriate pattern and tint color for the given archetype.
    private func generatePatternAndColor(for archetype: StyleArchetype) -> (UIImage, UIColor) {
        let (hexLight, hexDark) = wallpaperTintColors(for: archetype)
        let tintColor = UIColor { traitCollection in
            let hex = traitCollection.userInterfaceStyle == .dark ? hexDark : hexLight
            return UIColor(hex: hex)
        }

        let pattern: UIImage
        switch archetype {
        case .deGournay:
            pattern = WallpaperPatternGenerator.generateChinoiserie(tintColor: tintColor)
        case .phillipJeffries:
            pattern = WallpaperPatternGenerator.generateGrasscloth(tintColor: tintColor)
        case .schumacher:
            pattern = WallpaperPatternGenerator.generateBoldPrint(tintColor: tintColor)
        case .scalamandre:
            pattern = WallpaperPatternGenerator.generateZoological(tintColor: tintColor)
        }

        return (pattern, tintColor)
    }

    /// Returns light and dark hex colors for each wallpaper house.
    private func wallpaperTintColors(for archetype: StyleArchetype) -> (light: UInt32, dark: UInt32) {
        switch archetype {
        case .deGournay:
            return (light: 0xA8C4B8, dark: 0x7A9E8E)
        case .phillipJeffries:
            return (light: 0xD4C5A9, dark: 0xB8A98D)
        case .schumacher:
            return (light: 0xD4A092, dark: 0xC48B7D)
        case .scalamandre:
            return (light: 0x8B9EB5, dark: 0x6B7E95)
        }
    }
}

// MARK: - StyleArchetype Enum

/// Represents the user's style archetype, mapping to luxury wallpaper houses.
enum StyleArchetype: String, CaseIterable {
    case deGournay = "de_gournay"
    case phillipJeffries = "phillip_jeffries"
    case schumacher = "schumacher"
    case scalamandre = "scalamandre"
}

// MARK: - UIColor Extension for Hex Initialization

extension UIColor {
    /// Creates a UIColor from a hex value.
    /// - Parameter hex: Hex color value (e.g., 0xA8C4B8)
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
