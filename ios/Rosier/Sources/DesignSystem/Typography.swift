import SwiftUI

/// Typography style definitions with Dynamic Type support.
public enum Typography {
    // MARK: - Display Styles

    /// Display Large: 34pt Bold, -0.4pt tracking
    public static var displayLarge: Font {
        .system(size: 34, weight: .bold, design: .default)
    }

    public static var displayLargeMetrics: UIFontMetrics {
        UIFontMetrics(forTextStyle: .largeTitle)
    }

    /// Display Medium: 28pt Bold, -0.2pt tracking
    public static var displayMedium: Font {
        .system(size: 28, weight: .bold, design: .default)
    }

    public static var displayMediumMetrics: UIFontMetrics {
        UIFontMetrics(forTextStyle: .title1)
    }

    // MARK: - Title Styles

    /// Title Large: 22pt Semibold
    public static var titleLarge: Font {
        .system(size: 22, weight: .semibold, design: .default)
    }

    public static var titleLargeMetrics: UIFontMetrics {
        UIFontMetrics(forTextStyle: .title1)
    }

    /// Title Medium: 20pt Semibold
    public static var titleMedium: Font {
        .system(size: 20, weight: .semibold, design: .default)
    }

    public static var titleMediumMetrics: UIFontMetrics {
        UIFontMetrics(forTextStyle: .title2)
    }

    // MARK: - Body Styles

    /// Body: 17pt Regular
    public static var body: Font {
        .system(size: 17, weight: .regular, design: .default)
    }

    /// Body Bold: 17pt Semibold
    public static var bodyBold: Font {
        .system(size: 17, weight: .semibold, design: .default)
    }

    public static var bodyMetrics: UIFontMetrics {
        UIFontMetrics(forTextStyle: .body)
    }

    // MARK: - Caption Styles

    /// Caption: 15pt Regular
    static var caption: Font {
        .system(size: 15, weight: .regular, design: .default)
    }

    static var captionMetrics: UIFontMetrics {
        UIFontMetrics(forTextStyle: .caption1)
    }

    // MARK: - Footnote Style

    /// Footnote: 13pt Regular
    static var footnote: Font {
        .system(size: 13, weight: .regular, design: .default)
    }

    static var footnoteMetrics: UIFontMetrics {
        UIFontMetrics(forTextStyle: .footnote)
    }

    // MARK: - Micro Style

    /// Micro: 11pt Medium, 0.2pt tracking
    static var micro: Font {
        .system(size: 11, weight: .medium, design: .default)
    }

    static var microMetrics: UIFontMetrics {
        UIFontMetrics(forTextStyle: .caption2)
    }

    // MARK: - Tracking Values

    static let displayLargeTracking: CGFloat = -0.4
    static let displayMediumTracking: CGFloat = -0.2
    static let microTracking: CGFloat = 0.2
}

// MARK: - View Modifiers for Typography

extension View {
    /// Applies Display Large style with Dynamic Type.
    func styleDisplayLarge() -> some View {
        self
            .font(Typography.displayLarge)
            .tracking(Typography.displayLargeTracking)
    }

    /// Applies Display Medium style with Dynamic Type.
    func styleDisplayMedium() -> some View {
        self
            .font(Typography.displayMedium)
            .tracking(Typography.displayMediumTracking)
    }

    /// Applies Title Large style with Dynamic Type.
    func styleTitleLarge() -> some View {
        self.font(Typography.titleLarge)
    }

    /// Applies Title Medium style with Dynamic Type.
    func styleTitleMedium() -> some View {
        self.font(Typography.titleMedium)
    }

    /// Applies Body style with Dynamic Type.
    func styleBody() -> some View {
        self.font(Typography.body)
    }

    /// Applies Body Bold style with Dynamic Type.
    func styleBodyBold() -> some View {
        self.font(Typography.bodyBold)
    }

    /// Applies Caption style with Dynamic Type.
    func styleCaption() -> some View {
        self.font(Typography.caption)
    }

    /// Applies Footnote style with Dynamic Type.
    func styleFootnote() -> some View {
        self.font(Typography.footnote)
    }

    /// Applies Micro style with Dynamic Type and tracking.
    func styleMicro() -> some View {
        self
            .font(Typography.micro)
            .tracking(Typography.microTracking)
    }
}
