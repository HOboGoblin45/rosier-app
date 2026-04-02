# Rosier Wallpaper Pattern System - Complete Index

## Overview

The Rosier wallpaper pattern system defines a curated collection of 16 patterns across four luxury wallpaper houses. These patterns are revealed as users swipe away product cards, creating a luxury reveal mechanic that reinforces the app's premium positioning in niche fashion discovery.

**Key Metric:** Patterns render at 5-8% opacity as subtle background textures that enhance user experience without overwhelming interface elements.

---

## Documentation Files

### 1. wallpaper_pattern_spec.md
**Purpose:** Comprehensive reference for all 16 patterns with detailed specifications

**Contains:**
- Complete descriptions of all 4 wallpaper houses
- Detailed specs for each of the 16 patterns including:
  - Visual descriptions (30-50 words each)
  - Light and dark mode color palettes (with hex codes)
  - Pattern type classification
  - Mood/aesthetic keywords
  - Archetype associations
  - Color palette summary table
  - Implementation guidelines
  - Research sources

**Usage:** Design handoff document; designer reference during asset creation; QA reference for color accuracy.

**File Size:** ~19 KB
**Location:** `/sessions/busy-tender-goldberg/mnt/Women's fashion app/rosier/docs/wallpaper_pattern_spec.md`

---

### 2. wallpaper_svg_specs.md
**Purpose:** Technical specifications for creating SVG pattern assets

**Contains:**
- SVG rendering standards (200×200 viewBox, seamless tiling)
- Detailed construction specs for each of 4 pattern categories:
  - de Gournay Chinoiserie (Earlham, Portobello, Chatsworth, St. Laurent)
  - Phillip Jeffries Textural (Heritage Hemp, Graceful Grass, Refined Raffia, Natural Jute)
  - Schumacher Bold Prints (Chiang Mai Dragon, Citrus Garden, Josef Frank, Grand Floral)
  - Scalamandré Zoological (Zebras, Leaping Cheetah, Tigre, Tigress Tiger Eye)
- Element counts, stroke specifications, color opacity guidelines
- Example SVG code snippets
- Seamless tiling verification checklist
- Designer delivery format guide
- Preview and testing procedures

**Usage:** SVG designer reference; asset creation specifications; QA testing guide.

**File Size:** ~25 KB
**Location:** `/sessions/busy-tender-goldberg/mnt/Women's fashion app/rosier/docs/wallpaper_svg_specs.md`

---

### 3. WallpaperPatterns.swift
**Purpose:** iOS design system implementation of wallpaper configurations

**Contains:**
- `WallpaperHouse` enum (4 cases: deGournay, phillipJeffries, schumacher, scalamandre)
- `WallpaperPattern` enum (16 cases for all patterns)
- `StyleArchetype` enum (5 user archetypes)
- `ColorPair` struct (light/dark mode color container)
- `WallpaperConfig` struct (complete pattern configuration)
- `WallpaperConfigFactory` class with 16 configuration methods
  - Full color definitions with validated hex codes
  - Opacity specifications (baseOpacity 0.055-0.08)
  - Scale factors (0.85-1.3)
  - Blending modes and asset mappings
- `ArchetypePatternMapper` class for archetype→pattern mapping
- `UIColor` hex extension for color initialization

**Usage:** iOS app implementation; directly imported into SwiftUI/UIKit views; provides type-safe access to all wallpaper configurations.

**File Size:** ~29 KB
**Location:** `/sessions/busy-tender-goldberg/mnt/Women's fashion app/rosier/ios/Rosier/Sources/DesignSystem/WallpaperPatterns.swift`

---

## Pattern Organization Summary

### BY WALLPAPER HOUSE

**de Gournay — Classical Elegance (4 patterns)**
- Earlham — Delicate branches, birds, blossoms
- Portobello — Gnarled branches, flowering vines, bird perches
- Chatsworth — Architectural gardens with pavilions, water references
- St. Laurent — Contemporary abstract branches, sparse composition

**Phillip Jeffries — Artisanal Naturalism (4 patterns)**
- Heritage Hemp — Horizontal woven texture with irregular fibers
- Graceful Grass — Fine vertical striations suggesting dried grass
- Refined Raffia — Thick bundled fibers with basketry-like weave
- Natural Jute — Dense, uniform crosshatch grid structure

**Schumacher — Exuberant Maximalism (4 patterns)**
- Chiang Mai Dragon — Dragon among peonies and chrysanthemums
- Citrus Garden — Orange and lemon trees with flowering vines
- Josef Frank Botanical — Whimsical tropical and temperate flora
- Grand Floral Heritage — Large-scale peonies, roses, dahlias

**Scalamandré — Zoological Drama (4 patterns)**
- The Iconic Zebras — Dynamic zebra silhouettes with striping
- Leaping Cheetah — Playful pouncing cheetahs in mid-leap
- Tigre — Abstract woven ombré with tiger-skin spine lines
- Tigress Tiger Eye — Stylized eye forms and curved stripe elements

---

### BY USER ARCHETYPE

**Classic Refined** → de Gournay
- Users: Heritage craftsmanship appreciation, narrative design preference
- Primary Patterns: Earlham, Portobello, Chatsworth, St. Laurent

**Eclectic Creative** → Schumacher
- Users: Color celebration, pattern layering enthusiasm, artistic expression
- Primary Patterns: Chiang Mai Dragon, Citrus Garden, Josef Frank, Grand Floral

**Minimalist Modern** → Phillip Jeffries
- Users: Understated elegance, organic materials, tactile authenticity
- Primary Patterns: Heritage Hemp, Refined Raffia, Graceful Grass, Natural Jute

**Bold Avant-Garde** → Scalamandré
- Users: Fearless design statements, symbolic animal motifs, prestige
- Primary Patterns: Zebras, Leaping Cheetah, Tigre, Tigress Tiger Eye

**Relaxed Natural** → Phillip Jeffries (Natural Fibers)
- Users: Texture-driven design, refuge in natural materials
- Primary Patterns: Graceful Grass, Natural Jute, Refined Raffia, Heritage Hemp

---

## Color Reference Quick Table

| House | Pattern | Light Primary | Light Secondary | Dark Primary | Dark Secondary |
|-------|---------|---|---|---|---|
| de Gournay | Earlham | #1B3B4D | #D4AF37 | #0F1F2E | #F4D89F |
| de Gournay | Portobello | #4A7C8C | #C9A961 | #2C4D57 | #E5C494 |
| de Gournay | Chatsworth | #2C5F7C | #D9A649 | #1A3A4D | #E8C494 |
| de Gournay | St. Laurent | #3D6A7D | #B8956A | #25404F | #D4B896 |
| Phillip Jeffries | Heritage Hemp | #D4C5B9 | #E8DCC8 | #8B7E6F | #A89680 |
| Phillip Jeffries | Graceful Grass | #D9CFC7 | #E5D9CB | #7A7366 | #9D938B |
| Phillip Jeffries | Refined Raffia | #D8C8B8 | #E8DCC8 | #9B8B7B | #A89680 |
| Phillip Jeffries | Natural Jute | #C9BAA8 | #DDD4C8 | #8B7D70 | #A0957F |
| Schumacher | Chiang Mai Dragon | #2A5C7C | #E8B23D | #1A3C5C | #F0C860 |
| Schumacher | Citrus Garden | #3D6B4C | #F5A623 | #2A4A38 | #F5C66D |
| Schumacher | Josef Frank Botanical | #4A6F5C | #D94C4C | #2A4A3C | #E87070 |
| Schumacher | Grand Floral Heritage | #6B2C4C | #E8B8C8 | #4A1C3C | #F0D4D8 |
| Scalamandré | Iconic Zebras | #1A1A1A | #F5F5F0 | #F5F5F0 | #2A2A2A |
| Scalamandré | Leaping Cheetah | #3D5C4C | #F5E8D4 | #2A3C2C | #E8D4B8 |
| Scalamandré | Tigre | #8B6F47 | #D4B896 | #5A4A3C | #C8A882 |
| Scalamandré | Tigress Tiger Eye | #6B5C4C | #E8D4B8 | #4A3C2C | #D4B896 |

---

## Implementation Timeline

### Phase 1: Asset Creation (Designer)
**Deliverable:** 16 SVG pattern files following `wallpaper_svg_specs.md` guidelines
- Create files in `/ios/Rosier/Assets.xcassets/Wallpaper/`
- Name format: `[house-name]-[pattern-name].svg`
- Verify seamless tiling and opacity specifications
- Test in light and dark mode contexts

### Phase 2: iOS Integration (Engineer)
**Deliverable:** Pattern views and configuration management
- Import WallpaperPatterns.swift (already provided)
- Create WallpaperView component using SVG assets
- Implement opacity and scale transformations
- Map archetype selections to pattern reveals
- Add dynamic light/dark mode switching

### Phase 3: Card Swipe Animation (Engineer)
**Deliverable:** Swipe mechanic with pattern reveal
- Overlay wallpaper pattern beneath product card
- Fade in pattern as card is swiped away
- Apply blending mode (Screen/Multiply based on mode)
- Smooth opacity transition (0% → 5-8% over swipe duration)

### Phase 4: QA & Refinement (Designer + Engineer)
**Focus Areas:**
- Color accuracy verification
- Pattern legibility at target opacity
- Light/dark mode contrast adequacy
- Edge case testing (small screens, extreme zoom)
- Performance profiling (16 concurrent pattern renders)

---

## Key Technical Specifications

**Pattern Rendering:**
- Viewport Size: 200×200px (seamless tile)
- Base Opacity: 5-8% (typically 0.06-0.075)
- Scale Factors: 0.85-1.3x (adjustable per pattern)
- Blending Mode: Screen (light mode), Multiply (dark mode)
- File Format: SVG (vector, scalable, cacheable)

**Color Support:**
- Light Mode: Standard UI hierarchy + pattern colors
- Dark Mode: Inverted primary/secondary colors
- Contrast Ratio: Minimum 4.5:1 for accessibility
- Hex Format: 6-digit (e.g., #1B3B4D)

**Asset Naming Convention:**
```
{house-slug}-{pattern-slug}.svg
Examples:
  de-gournay-earlham.svg
  phillip-jeffries-heritage-hemp.svg
  schumacher-chiang-mai-dragon.svg
  scalamandre-iconic-zebras.svg
```

---

## Swift Usage Examples

### Basic Pattern Configuration
```swift
let pattern = WallpaperPattern.chiangMaiDragon
let config = WallpaperConfigFactory.config(for: pattern)

// Access colors
let primaryColor = config.primaryColor.color(isDarkMode: false)
let secondaryColor = config.secondaryColor.color(isDarkMode: false)

// Rendering hints
let opacity = config.baseOpacity // 0.075
let scale = config.scaleFactor   // 0.9
```

### Archetype-Based Pattern Selection
```swift
let archetype = StyleArchetype.eclecticCreative
let config = ArchetypePatternMapper.recommendedConfig(for: archetype)

// Returns Schumacher's Chiang Mai Dragon for Eclectic Creative users
```

### Trait Collection Support
```swift
let traitCollection = UITraitCollection.current
let color = config.primaryColor.color(for: traitCollection)
// Automatically switches between light/dark mode colors
```

---

## Research Sources

All patterns and specifications are based on official wallpaper house materials:

- [de Gournay Collections](https://degournay.com/design-collections/wallpapers/chinoiserie-collection)
- [Phillip Jeffries Wallcoverings](https://www.phillipjeffries.com/shop/categories)
- [Schumacher Wallpapers](https://schumacher.com/catalog/1)
- [Scalamandré Collections](https://www.scalamandre.com/)

---

## Questions & Support

**For Designers:**
- Start with `wallpaper_svg_specs.md` for construction details
- Reference `wallpaper_pattern_spec.md` for visual descriptions and color accuracy
- Use the color table above for hex code validation

**For Engineers:**
- Use `WallpaperPatterns.swift` for type-safe configuration access
- Reference `wallpaper_pattern_spec.md` for opacity and scale hints
- Check `wallpaper_svg_specs.md` for seamless tiling information

**For Product:**
- Each pattern maps to a user archetype for personalized reveal mechanics
- 16 patterns provide sufficient variety without overwhelming choice
- Patterns function as brand elevation (luxury reveal, heritage association)

---

## File Manifest

```
rosier/
├── docs/
│   ├── WALLPAPER_PATTERNS_INDEX.md (this file)
│   ├── wallpaper_pattern_spec.md (~19 KB)
│   ├── wallpaper_svg_specs.md (~25 KB)
│   └── wallpaper_partnership_pitch.md (existing)
└── ios/Rosier/Sources/
    └── DesignSystem/
        └── WallpaperPatterns.swift (~29 KB)
```

**Total Documentation:** ~73 KB of production-ready specifications
**Total Code:** 1 production-ready Swift file with 16 complete configurations

---

**Last Updated:** April 1, 2026
**Status:** Complete & Ready for Implementation
