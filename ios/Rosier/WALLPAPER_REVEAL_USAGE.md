# Wallpaper Reveal Effect — Usage Guide

## Quick Start

The wallpaper reveal effect is automatically integrated into `CardStackView`. No additional setup required beyond what already exists, but you can customize the pattern based on the user's style archetype.

## Basic Usage

### In SwipeView

The wallpaper will automatically display and respond to swipe gestures. To set the initial pattern based on user preferences:

```swift
struct SwipeView: View {
    @State private var viewModel: SwipeViewModel
    @State private var userArchetype: StyleArchetype = .deGournay

    var body: some View {
        ZStack {
            CardStackView(
                currentCard: viewModel.currentCard,
                nextCard: viewModel.nextCard,
                thirdCard: viewModel.thirdCard,
                onSwipeLeft: { viewModel.handleSwipe(.reject) },
                onSwipeRight: { viewModel.handleSwipe(.like) },
                onSwipeUp: { viewModel.handleSwipe(.superLike) },
                onSwipeDown: { viewModel.undo() },
                onTap: { /* ... */ },
                dresserPosition: dresserIconPosition()
            )
            // Wallpaper is automatically rendered beneath
        }
        .onAppear {
            // Load user's archetype from preferences
            // and update the wallpaper pattern
            updateWallpaperForUser()
        }
    }

    private func updateWallpaperForUser() {
        // Example: fetch from UserDefaults or view model
        let archetype = UserDefaults.standard.string(forKey: "styleArchetype")
            .flatMap { StyleArchetype(rawValue: $0) } ?? .deGournay

        // Update would need to be exposed via a reference or binding
        // See "Advanced Integration" below
    }
}
```

### Changing the Pattern

When the user's style archetype is determined or changes (e.g., after a style quiz), update the wallpaper:

```swift
// In your CardStackView or wherever you have access to CardStackUIView
cardStackUIView.updateWallpaperPattern(for: .schumacher)

// The pattern will fade out, switch, and fade in smoothly
```

## Advanced Integration

### Exposing Wallpaper Control in SwiftUI

To allow SwiftUI code to update the wallpaper pattern, you can extend `CardStackView`:

```swift
struct CardStackView: UIViewRepresentable {
    let currentCard: CardQueueItem?
    let nextCard: CardQueueItem?
    let thirdCard: CardQueueItem?

    // Add this property
    var wallpaperArchetype: StyleArchetype = .deGournay

    var onSwipeLeft: () -> Void = {}
    var onSwipeRight: () -> Void = {}
    // ... other callbacks ...

    func makeUIView(context: Context) -> CardStackUIView {
        let view = CardStackUIView()
        // ... existing setup ...
        view.updateWallpaperPattern(for: wallpaperArchetype)
        return view
    }

    func updateUIView(_ uiView: CardStackUIView, context: Context) {
        uiView.updateCards(current: currentCard, next: nextCard, third: thirdCard)
        // Update wallpaper if archetype changes
        if wallpaperArchetype != context.coordinator.lastArchetype {
            uiView.updateWallpaperPattern(for: wallpaperArchetype)
            context.coordinator.lastArchetype = wallpaperArchetype
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var lastArchetype: StyleArchetype = .deGournay
    }
}
```

Then in SwipeView:

```swift
CardStackView(
    currentCard: viewModel.currentCard,
    nextCard: viewModel.nextCard,
    thirdCard: viewModel.thirdCard,
    wallpaperArchetype: viewModel.userArchetype,
    // ... other parameters ...
)
```

### Storing User Preference

Store the user's archetype in UserDefaults or your database:

```swift
// Save
let archetype = StyleArchetype.schumacher
UserDefaults.standard.set(archetype.rawValue, forKey: "styleArchetype")

// Load
let saved = UserDefaults.standard.string(forKey: "styleArchetype")
let archetype = saved.flatMap { StyleArchetype(rawValue: $0) } ?? .deGournay
```

## Understanding the Visual Effect

### What to Expect

When you drag a card:

1. **Drag starts**: Wallpaper is completely hidden (opacity = 0)
2. **Drag progresses** (e.g., 50pt right):
   - Wallpaper becomes visible (opacity ≈ 0.03 in light mode)
   - Pattern shifts slightly left (parallax offset ≈ 7.5pt)
   - Effect creates illusion of a layer beneath the card
3. **Drag continues to threshold** (100pt):
   - Wallpaper reaches max visibility (opacity = 0.06 light / 0.08 dark)
   - Parallax motion proportional to drag distance
4. **Card dismissed**:
   - Wallpaper fades out over 0.3 seconds
   - Next card settles with hidden wallpaper
5. **Drag cancelled** (partial swipe):
   - Card springs back
   - Wallpaper fades out over 0.3 seconds

### Parallax Example

Drag 50pt right:
- Wallpaper pattern shifts 50 × 0.15 = 7.5pt left
- Opacity is 50/100 × maxOpacity = 3% in light mode

Drag 100pt right (maximum before swipe):
- Wallpaper pattern shifts 100 × 0.15 = 15pt left
- Opacity reaches maximum (6% light / 8% dark)

### Pattern Descriptions

- **de Gournay (Chinoiserie)**: Delicate branches with small circular blossoms. Soft sage green tint (#A8C4B8 light / #7A9E8E dark). Most elegant, understated.

- **Phillip Jeffries (Grasscloth)**: Horizontal woven texture with subtle vertical variation. Warm sand tint (#D4C5A9 light / #B8A98D dark). Organic, tactile.

- **Schumacher (Bold Print)**: Large-scale diamond lattice repeating. Rich coral tint (#D4A092 light / #C48B7D dark). Geometric, structured.

- **Scalamandr é (Zoological)**: Stylized bird silhouettes with decorative circles. Deep navy tint (#8B9EB5 light / #6B7E95 dark). Nature-inspired, refined.

## Accessibility Considerations

### Reduce Motion

Users with "Reduce Motion" enabled in Settings → Accessibility will:
- NOT see the parallax offset (pattern stays centered)
- STILL see the opacity fade (wallpaper becomes visible)

This ensures the effect feels subtle and doesn't cause motion sensitivity issues.

### Testing Reduce Motion

In Xcode simulator:
1. Settings → Accessibility → Motion → Reduce Motion → ON
2. Test your swipes—parallax should be disabled but opacity visible
3. Turn off and re-test to see full effect

## Performance Tips

### Pattern Generation

Patterns are cached after first generation. To clear cache (e.g., on app background):

```swift
// Optional: clear pattern cache to free memory
WallpaperPatternGenerator.clearCache()
```

### Blur Filter

The Gaussian blur is applied once during pattern initialization, not per-frame. This ensures smooth 60fps animations without blur recalculation overhead.

### Memory Management

- Pattern view is held as a property of `CardStackUIView` (released when view is deallocated)
- No circular references or memory leaks
- Cache uses `NSCache` which respects memory warnings

## Troubleshooting

### Pattern Not Showing

**Problem**: Wallpaper doesn't appear when dragging.

**Solutions**:
1. Verify `wallpaperRevealView` is inserted as subview at index 0 (behind cards)
2. Check that `updateDisplacement()` is being called during `.changed` pan state
3. Verify max opacity in `Colors.swift` is not 0.0

### Parallax Not Working

**Problem**: Pattern doesn't shift when dragging, just appears/disappears.

**Solutions**:
1. Check that `UIAccessibility.isReduceMotionEnabled` is false (this disables parallax)
2. Verify `wallpaperParallaxFactor` in `Animations.swift` is 0.15 (not 0.0)
3. Ensure pan gesture is updating `dx` correctly

### Performance Issues

**Problem**: Animation jank or frame drops during swipe.

**Solutions**:
1. Verify blur filter is applied once, not per-frame
2. Check that pattern generation is cached (NSCache)
3. Reduce pattern size if using very large tiles (default 200×200 is optimal)

### Colors Not Updating for Dark Mode

**Problem**: Wallpaper color doesn't change when switching dark mode.

**Solutions**:
1. Verify `UIColor { traitCollection in ... }` syntax is used in pattern generator
2. Check that dark hex values are defined in `wallpaperTintColors()` method
3. Force trait collection update with `setNeedsLayout()` after dark mode toggle

## Advanced Customization

### Custom Pattern Colors

To use a custom tint color instead of the archetype default:

```swift
// In WallpaperRevealView, modify generatePatternAndColor:
let tintColor = UIColor(hex: 0xYOURCOLOR) // Your custom hex
let pattern = WallpaperPatternGenerator.generateChinoiserie(tintColor: tintColor)
```

### Pattern Size Adjustment

To change pattern tile size (larger = less repetition, smaller = denser):

```swift
// Default is 200×200, can be adjusted:
let pattern = WallpaperPatternGenerator.generateGrasscloth(
    size: CGSize(width: 300, height: 300), // Larger tiles
    tintColor: tintColor
)
```

### Blur Radius Adjustment

In `Animations.swift`:

```swift
static var wallpaperBlurRadius: CGFloat {
    1.0  // Increase for more blur, decrease for sharper
}
```

## Integration Checklist

- [ ] `WallpaperPatternGenerator.swift` created and building
- [ ] `WallpaperRevealView.swift` created and building
- [ ] `CardStackView.swift` updated with wallpaper integration
- [ ] `Animations.swift` updated with wallpaper parameters
- [ ] `Colors.swift` updated with wallpaper colors
- [ ] All imports compile without errors
- [ ] Tested wallpaper appears during drag
- [ ] Tested parallax motion is visible
- [ ] Tested all four archetypes
- [ ] Tested dark mode colors
- [ ] Tested with Reduce Motion enabled
- [ ] Tested memory doesn't leak (check with Instruments)
