# Wallpaper Reveal Effect Implementation

## Overview

The wallpaper reveal effect is a luxury design detail that reveals an elegant pattern beneath the card stack as users drag to swipe. The pattern has subtle parallax motion that shifts opposite to the drag direction, creating perceived depth. When the card is dismissed or snaps back, the pattern gracefully fades.

## Architecture

### New Files Created

#### 1. **WallpaperPatternGenerator.swift**
Generates procedural wallpaper patterns using Core Graphics. Each pattern is designed to be subtle, tileable, and elegant—appropriate for a background texture that enhances without overwhelming.

**Patterns:**
- **Chinoiserie** (de Gournay style): Delicate curved branches with small circular blossoms. Subtle, hand-drawn aesthetic.
- **Grasscloth** (Phillip Jeffries style): Horizontal woven texture with vertical variation. Tactile, organic feel.
- **Bold Print** (Schumacher style): Large-scale diamond lattice repeating motif. Geometric, structured elegance.
- **Zoological** (Scalamandr é style): Stylized bird silhouettes with decorative circles. Nature-inspired, refined.

**Features:**
- Pattern caching via `NSCache` to avoid regeneration
- Dynamic color application based on light/dark mode
- Tintable patterns for brand/archetype-specific coloring
- `clearCache()` for memory management

#### 2. **WallpaperRevealView.swift**
A custom UIView that manages the wallpaper rendering and reveals logic.

**Key Features:**
- **Parallax Motion**: Inverse motion relative to card drag (15% factor). Dragging right shifts pattern left slightly, creating depth illusion.
- **Opacity Control**: Fades from 0 → max opacity as displacement increases (0 at 0pt, full at 100pt threshold)
- **Gaussian Blur**: Applies 2pt blur filter for depth and premium feel
- **Accessibility**: Respects `UIAccessibility.isReduceMotionEnabled`; skips parallax when enabled
- **Pattern Switching**: `updatePattern(for:animated:)` method swaps patterns with fade transition
- **Dynamic Tint Colors**: Each archetype has light/dark mode color variants:
  - de Gournay: #A8C4B8 light / #7A9E8E dark (sage green)
  - Phillip Jeffries: #D4C5A9 light / #B8A98D dark (warm sand)
  - Schumacher: #D4A092 light / #C48B7D dark (rich coral)
  - Scalamandr é: #8B9EB5 light / #6B7E95 dark (deep navy)

**Public API:**
- `updatePattern(for archetype: StyleArchetype, animated: Bool)` — Swap pattern
- `updateDisplacement(_ displacement: CGFloat, maxDisplacement: CGFloat)` — Update during drag
- `animateOpacity(to opacity: CGFloat, duration: TimeInterval)` — Fade in/out
- `reset()` — Return to hidden state

#### 3. **StyleArchetype Enum** (in WallpaperRevealView.swift)
Represents the user's style preference, mapping to luxury wallpaper houses:
```swift
enum StyleArchetype {
    case deGournay
    case phillipJeffries
    case schumacher
    case scalamandre
}
```

### Modified Files

#### 1. **CardStackView.swift**
Integrated wallpaper reveal into the card stack gesture flow.

**Changes:**
- Added `wallpaperRevealView` property (instantiated at init)
- Added `setupView()` to insert wallpaper behind card stack (subview at index 0)
- Added `updateWallpaperPattern(for:)` public method for pattern switching
- Updated `layoutSubviews()` to size wallpaper view to bounds
- Updated `.changed` pan handler to call `wallpaperRevealView.updateDisplacement(dx, maxDisplacement: 100)`
- Updated all swipe execution methods to fade wallpaper as card exits:
  - `executeSwipeLeft()`: Fades wallpaper during dismiss
  - `executeSwipeRight()`: Fades wallpaper during dismiss
  - `executeSwipeUp()`: Fades wallpaper during super-like animation
  - `springBackToCenter()`: Fades wallpaper as card returns
- Updated `updateCards()` to reset wallpaper when new card appears

#### 2. **Animations.swift**
Added wallpaper-specific animation parameters in new `MARK: - Wallpaper Reveal Animation Parameters` section:

```swift
wallpaperRevealDuration: 0.2        // Fade-in speed
wallpaperDismissDuration: 0.3       // Fade-out speed
wallpaperParallaxFactor: 0.15       // Inverse motion multiplier
wallpaperMaxOpacityLight: 0.06      // Max opacity in light mode
wallpaperMaxOpacityDark: 0.08       // Max opacity in dark mode
wallpaperBlurRadius: 2.0            // Gaussian blur radius
```

#### 3. **Colors.swift**
Added wallpaper house tint colors with light/dark variants in new `MARK: - Wallpaper House Tint Colors` section:

```swift
Color.wallpaperDeGournay           // Sage green
Color.wallpaperPhillipJeffries     // Warm sand
Color.wallpaperSchumacher          // Rich coral
Color.wallpaperScalamandre         // Deep navy
```

## Design Principles

### Subtlety
- Max opacity is 6% in light mode, 8% in dark mode—barely perceptible but effective
- Patterns are fine-grained and elegant, not bold or distracting
- Gaussian blur softens the texture for premium feel

### Parallax Depth
- 15% inverse motion creates perception of a layered surface beneath the card
- Motion is smooth and responsive, updating every frame via `updateDisplacement()`
- The effect is most noticeable during slower drags; fast swipes maintain speed without visual lag

### Accessibility
- Reduces or eliminates parallax motion when `isReduceMotionEnabled` is true
- Opacity is still visible in reduced motion mode, just without parallax offset
- All gestures remain fully functional

### Performance
- Pattern generation uses procedural Core Graphics, avoiding large image assets
- Pattern cache via `NSCache` prevents regeneration
- CADisplayLink (optional) can be activated for 60fps parallax updates (currently using CATransaction for efficiency)
- Blur filter is applied once during pattern initialization, not per-frame

## Integration Points

### How to Use in SwipeViewModel

The `SwipeViewModel` should call the wallpaper update method when the user's archetype is determined or changes:

```swift
// In SwipeViewModel or SwipeView
let cardStackUIView: CardStackUIView = ...
cardStackUIView.updateWallpaperPattern(for: .deGournay)

// Or via the SwiftUI wrapper if you expose the method:
// Add to CardStackView struct:
var wallpaperArchetype: StyleArchetype = .deGournay
// Then in updateUIView:
uiView.updateWallpaperPattern(for: wallpaperArchetype)
```

### How to Initialize

Currently, `WallpaperRevealView` initializes with a default archetype (de Gournay). To set a different initial pattern:

```swift
// In CardStackUIView.setupView() or after instantiation
wallpaperRevealView.updatePattern(for: .schumacher, animated: false)
```

## Animation Flow

### Drag Sequence
1. **Pan begins**: Wallpaper hidden (opacity = 0)
2. **Pan changes**:
   - `dx` is calculated
   - `wallpaperRevealView.updateDisplacement(dx, maxDisplacement: 100)` is called
   - Parallax offset is updated: `pattern.position.x += -dx * 0.15`
   - Opacity fades in: `progress = min(abs(dx) / 100, 1.0); opacity = progress * maxOpacity`
3. **Pan ends (dismiss)**:
   - `animateOpacity(to: 0, duration: 0.3)` fades wallpaper
   - Card animates off-screen
   - Next card settles, wallpaper is hidden again
4. **Pan ends (snap back)**:
   - `animateOpacity(to: 0, duration: 0.3)` fades wallpaper
   - Card springs back to center
   - Wallpaper is hidden again

## Testing Checklist

- [ ] Drag card right: Wallpaper fades in, pattern shifts left (parallax visible)
- [ ] Drag card left: Wallpaper fades in, pattern shifts right
- [ ] Drag slowly: Parallax motion is smooth, opacity gradient is visible
- [ ] Drag quickly: Effect doesn't jank, swipe completes smoothly
- [ ] Dismiss card (swipe fully): Wallpaper fades out as card leaves
- [ ] Snap back (partial drag): Wallpaper fades out, pattern resets
- [ ] Super-like (swipe up): Wallpaper fades during dresser animation
- [ ] Test in dark mode: Opacity at 0.08, tint colors update correctly
- [ ] Test with Reduce Motion on: Parallax disabled, opacity still visible
- [ ] Test pattern switching: Call `updateWallpaperPattern(for: .schumacher)`, pattern fades and updates
- [ ] Test all archetypes: All four pattern/color combinations render correctly

## Future Enhancements

1. **Dynamic Pattern Selection**: Update pattern every N swipes based on user engagement
2. **Archetype-Specific Patterns**: Pre-generate patterns for each archetype on app launch
3. **CADisplayLink Optimization**: Enable 60fps parallax updates via CADisplayLink for ultra-smooth motion
4. **Pattern Variations**: Generate multiple unique patterns per archetype for visual interest
5. **Haptic Feedback**: Subtle haptic pulse when wallpaper reaches max opacity
6. **Performance Analytics**: Track pattern rendering time and cache hit rates

## File Locations

```
Sources/
├── Views/Swipe/
│   ├── CardStackView.swift (modified)
│   ├── WallpaperRevealView.swift (new)
│   └── WallpaperPatternGenerator.swift (new)
└── DesignSystem/
    ├── Animations.swift (modified)
    └── Colors.swift (modified)
```

## Code Quality

- All code includes comprehensive documentation comments
- Proper memory management with `[weak self]` closures
- Accessibility support throughout
- Performance optimized with caching and minimal allocations
- Follows app's existing patterns and conventions
