import SwiftUI

/// Design system color tokens with light/dark variants.
extension Color {
    // MARK: - Brand Colors

    /// Primary brand color - light pink/lavender in light mode, dark variant in dark mode.
    public static var brandPrimary: Color {
        Color(light: 0xF3CBF0, dark: 0xE8B5E0)
    }

    /// Secondary brand color - deep navy.
    public static var brandSecondary: Color {
        Color(light: 0x1A1A2E, dark: 0x2D2D4D)
    }

    /// Brand accent color - coral/salmon red.
    public static var brandAccent: Color {
        Color(light: 0xFE6F6F, dark: 0xFF9999)
    }

    /// Tertiary brand color - coral/salmon red (alias for accent).
    public static var brandTertiary: Color {
        Color(light: 0xFE6F6F, dark: 0xFF9999)
    }

    /// Neutral color - light gray.
    public static var brandNeutral: Color {
        Color(light: 0xF3F3F3, dark: 0x2A2A2A)
    }

    // MARK: - Surface Colors

    /// Card/component background.
    public static var surfaceCard: Color {
        Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    }

    /// App background.
    public static var surfaceBackground: Color {
        Color(light: 0xF5F5F5, dark: 0x000000)
    }

    // MARK: - Text Colors

    /// Primary text color.
    public static var textPrimary: Color {
        Color(light: 0x1A1A1A, dark: 0xF5F5F5)
    }

    /// Secondary text color.
    public static var textSecondary: Color {
        Color(light: 0x6B6B6B, dark: 0xA0A0A0)
    }

    /// Tertiary text color.
    public static var textTertiary: Color {
        Color(light: 0x9B9B9B, dark: 0x6B6B6B)
    }

    // MARK: - Status Colors

    /// Sale/discount indicator color.
    public static var saleRed: Color {
        Color(light: 0xE53935, dark: 0xFF5252)
    }

    /// Success state color.
    public static var successGreen: Color {
        Color(light: 0x43A047, dark: 0x66BB6A)
    }

    /// Destructive action color.
    public static var destructiveRed: Color {
        Color(light: 0xD32F2F, dark: 0xEF5350)
    }

    // MARK: - Wallpaper House Tint Colors

    /// de Gournay wallpaper tint: soft sage green
    public static var wallpaperDeGournay: Color {
        Color(light: 0xA8C4B8, dark: 0x7A9E8E)
    }

    /// Phillip Jeffries grasscloth tint: warm sand
    public static var wallpaperPhillipJeffries: Color {
        Color(light: 0xD4C5A9, dark: 0xB8A98D)
    }

    /// Schumacher bold print tint: rich coral
    public static var wallpaperSchumacher: Color {
        Color(light: 0xD4A092, dark: 0xC48B7D)
    }

    /// Scalamandr é zoological tint: deep navy
    public static var wallpaperScalamandre: Color {
        Color(light: 0x8B9EB5, dark: 0x6B7E95)
    }

    // MARK: - Convenience Initializer

    /// Creates a color with separate light and dark mode variants.
    /// - Parameters:
    ///   - light: Hex color value for light mode (e.g., 0x1A1A2E)
    ///   - dark: Hex color value for dark mode (e.g., 0xE8E8F0)
    public init(light: UInt32, dark: UInt32) {
        self.init(
            UIColor { traitCollection in
                let hex = traitCollection.userInterfaceStyle == .dark ? dark : light
                return UIColor(hex: hex)
            }
        )
    }
}

// MARK: - UIColor Extension for Hex Initialization

extension UIColor {
    /// Creates a UIColor from a hex value.
    /// - Parameter hex: Hex color value (e.g., 0x1A1A2E)
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
