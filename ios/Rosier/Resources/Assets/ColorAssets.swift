import SwiftUI

/// Rosier Color Design System
///
/// This file defines all color assets used throughout the app.
/// These are programmatically defined colors that mirror the Xcode Asset Catalog.
///
/// **Implementation Note for Team:**
/// To use these colors in Xcode Interface Builder and SwiftUI Previews:
/// 1. Create a new Asset Catalog: File > New > Asset Catalog
/// 2. Name it "Assets.xcassets"
/// 3. Create Color Sets for each color defined below
/// 4. Set light and dark mode variants as needed
/// 5. Match the exact RGB values shown in comments
///
/// For now, these programmatic definitions ensure consistent colors across the app.

// MARK: - Brand Colors

extension Color {
    /// Primary brand color - Deep Navy
    /// RGB: (26, 26, 46) | Hex: #1A1A2E
    static let brandPrimary = Color(red: 26/255, green: 26/255, blue: 46/255)

    /// Secondary brand color - Warm Gold/Tan
    /// RGB: (196, 167, 125) | Hex: #C4A77D
    static let brandAccent = Color(red: 196/255, green: 167/255, blue: 125/255)

    /// Tertiary brand color - Soft Mauve
    /// RGB: (142, 108, 129) | Hex: #8E6C81
    static let brandTertiary = Color(red: 142/255, green: 108/255, blue: 129/255)
}

// MARK: - Surface Colors

extension Color {
    /// Main background color - Off-white
    /// RGB: (250, 250, 250) | Hex: #FAFAFA (Light mode)
    /// RGB: (18, 18, 18) | Hex: #121212 (Dark mode)
    static let surfaceBackground = Color(
        light: Color(red: 250/255, green: 250/255, blue: 250/255),
        dark: Color(red: 18/255, green: 18/255, blue: 18/255)
    )

    /// Card/Container background
    /// RGB: (255, 255, 255) | Hex: #FFFFFF (Light mode)
    /// RGB: (28, 28, 28) | Hex: #1C1C1C (Dark mode)
    static let surfaceCard = Color(
        light: .white,
        dark: Color(red: 28/255, green: 28/255, blue: 28/255)
    )

    /// Overlay/Dialog background
    /// RGB: (255, 255, 255, 0.95) | Hex: #FFFFFF with 95% opacity (Light mode)
    /// RGB: (35, 35, 35, 0.95) | Hex: #232323 with 95% opacity (Dark mode)
    static let surfaceOverlay = Color(
        light: Color(red: 1, green: 1, blue: 1, opacity: 0.95),
        dark: Color(red: 35/255, green: 35/255, blue: 35/255, opacity: 0.95)
    )
}

// MARK: - Text Colors

extension Color {
    /// Primary text color
    /// RGB: (44, 44, 44) | Hex: #2C2C2C (Light mode)
    /// RGB: (229, 229, 229) | Hex: #E5E5E5 (Dark mode)
    static let textPrimary = Color(
        light: Color(red: 44/255, green: 44/255, blue: 44/255),
        dark: Color(red: 229/255, green: 229/255, blue: 229/255)
    )

    /// Secondary text color - Muted
    /// RGB: (108, 108, 108) | Hex: #6C6C6C (Light mode)
    /// RGB: (158, 158, 158) | Hex: #9E9E9E (Dark mode)
    static let textSecondary = Color(
        light: Color(red: 108/255, green: 108/255, blue: 108/255),
        dark: Color(red: 158/255, green: 158/255, blue: 158/255)
    )

    /// Tertiary text color - Faint
    /// RGB: (158, 158, 158) | Hex: #9E9E9E (Light mode)
    /// RGB: (108, 108, 108) | Hex: #6C6C6C (Dark mode)
    static let textTertiary = Color(
        light: Color(red: 158/255, green: 158/255, blue: 158/255),
        dark: Color(red: 108/255, green: 108/255, blue: 108/255)
    )

    /// Disabled text color
    /// RGB: (192, 192, 192) | Hex: #C0C0C0 (Light mode)
    /// RGB: (80, 80, 80) | Hex: #505050 (Dark mode)
    static let textDisabled = Color(
        light: Color(red: 192/255, green: 192/255, blue: 192/255),
        dark: Color(red: 80/255, green: 80/255, blue: 80/255)
    )
}

// MARK: - State Colors

extension Color {
    /// Success state - Green
    /// RGB: (34, 177, 76) | Hex: #22B14C
    static let stateSuccess = Color(red: 34/255, green: 177/255, blue: 76/255)

    /// Error state - Red
    /// RGB: (231, 76, 60) | Hex: #E74C3C
    static let stateError = Color(red: 231/255, green: 76/255, blue: 60/255)

    /// Warning state - Orange
    /// RGB: (241, 196, 15) | Hex: #F1C40F
    static let stateWarning = Color(red: 241/255, green: 196/255, blue: 15/255)

    /// Info state - Blue
    /// RGB: (52, 152, 219) | Hex: #3498DB
    static let stateInfo = Color(red: 52/255, green: 152/255, blue: 219/255)
}

// MARK: - Interactive Colors

extension Color {
    /// Button background - Primary
    /// RGB: (26, 26, 46) | Hex: #1A1A2E
    static let buttonPrimary = Color.brandPrimary

    /// Button background - Secondary
    /// RGB: (196, 167, 125) | Hex: #C4A77D
    static let buttonSecondary = Color.brandAccent

    /// Button disabled state
    /// RGB: (224, 224, 224) | Hex: #E0E0E0
    static let buttonDisabled = Color(red: 224/255, green: 224/255, blue: 224/255)

    /// Link/Interactive element color
    /// RGB: (52, 152, 219) | Hex: #3498DB
    static let interactive = Color(red: 52/255, green: 152/255, blue: 219/255)
}

// MARK: - Divider & Border Colors

extension Color {
    /// Divider line color
    /// RGB: (229, 229, 229) | Hex: #E5E5E5 (Light mode)
    /// RGB: (64, 64, 64) | Hex: #404040 (Dark mode)
    static let divider = Color(
        light: Color(red: 229/255, green: 229/255, blue: 229/255),
        dark: Color(red: 64/255, green: 64/255, blue: 64/255)
    )

    /// Border color - Subtle
    /// RGB: (217, 217, 217) | Hex: #D9D9D9 (Light mode)
    /// RGB: (76, 76, 76) | Hex: #4C4C4C (Dark mode)
    static let borderSubtle = Color(
        light: Color(red: 217/255, green: 217/255, blue: 217/255),
        dark: Color(red: 76/255, green: 76/255, blue: 76/255)
    )

    /// Border color - Emphasized
    /// RGB: (179, 179, 179) | Hex: #B3B3B3 (Light mode)
    /// RGB: (115, 115, 115) | Hex: #737373 (Dark mode)
    static let borderEmphasis = Color(
        light: Color(red: 179/255, green: 179/255, blue: 179/255),
        dark: Color(red: 115/255, green: 115/255, blue: 115/255)
    )
}

// MARK: - Feedback Colors (Fashion-specific)

extension Color {
    /// Like/Favorite color - Rose Pink
    /// RGB: (255, 107, 107) | Hex: #FF6B6B
    static let likeColor = Color(red: 1, green: 107/255, blue: 107/255)

    /// Pass/Dislike color - Muted Gray
    /// RGB: (128, 128, 128) | Hex: #808080
    static let passColor = Color(red: 128/255, green: 128/255, blue: 128/255)

    /// Shop/CTA color - Gold (matches brandAccent)
    /// RGB: (196, 167, 125) | Hex: #C4A77D
    static let shopColor = Color.brandAccent
}

// MARK: - Swipe Interaction Colors

extension Color {
    /// Swipe right indicator - Like
    /// RGB: (76, 175, 80) | Hex: #4CAF50
    static let swipeRight = Color(red: 76/255, green: 175/255, blue: 80/255)

    /// Swipe left indicator - Pass
    /// RGB: (244, 67, 54) | Hex: #F44336
    static let swipeLeft = Color(red: 244/255, green: 67/255, blue: 54/255)

    /// Swipe up indicator - Super like
    /// RGB: (255, 193, 7) | Hex: #FFC107
    static let swipeUp = Color(red: 1, green: 193/255, blue: 7/255)
}

// MARK: - Gradient Colors

extension Color {
    /// Gradient start - Deep Navy
    static let gradientStart = Color.brandPrimary

    /// Gradient end - Warm Gold
    static let gradientEnd = Color.brandAccent

    /// Skeleton loading - Light Gray
    /// RGB: (232, 232, 232) | Hex: #E8E8E8
    static let skeletonBase = Color(red: 232/255, green: 232/255, blue: 232/255)

    /// Skeleton highlight - Lighter Gray
    /// RGB: (242, 242, 242) | Hex: #F2F2F2
    static let skeletonHighlight = Color(red: 242/255, green: 242/255, blue: 242/255)
}

// MARK: - Helper Extension

extension Color {
    /// Creates an adaptive color that responds to light/dark mode
    init(light: Color, dark: Color) {
        self.init(
            UIColor(
                light: UIColor(light),
                dark: UIColor(dark)
            )
        )
    }
}

// MARK: - Asset Catalog Documentation

/*
 IMPLEMENTATION GUIDE FOR XCODE ASSET CATALOG
 ============================================

 To create the Asset Catalog in Xcode:

 1. File → New → Asset Catalog
    - Name: Assets.xcassets

 2. In Assets.xcassets, create Color Sets for:
    - BrandPrimary
    - BrandAccent
    - BrandTertiary
    - SurfaceBackground
    - SurfaceCard
    - SurfaceOverlay
    - TextPrimary
    - TextSecondary
    - TextTertiary
    - TextDisabled
    - StateSuccess
    - StateError
    - StateWarning
    - StateInfo
    - Divider
    - BorderSubtle
    - BorderEmphasis

 3. For each Color Set:
    - Select "Appearances" → "Light, Dark"
    - Set Input Method to "Color Set"
    - Add Light appearance color
    - Add Dark appearance color
    - Use the RGB values provided in comments above

 4. Update Color extension to reference Asset Catalog:

    extension Color {
        static let brandPrimary = Color("BrandPrimary")
        static let brandAccent = Color("BrandAccent")
        // ... etc
    }

 5. Colors will then be available in:
    - SwiftUI code: Color.brandPrimary
    - Interface Builder: Named color picker
    - SwiftUI Previews: Automatically supports light/dark
 */
