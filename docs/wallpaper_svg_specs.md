# Rosier Wallpaper SVG Pattern Specifications

## Overview

This document provides detailed technical specifications for creating subtle, abstract SVG pattern interpretations for Rosier's wallpaper reveal mechanic. Patterns are designed to be rendered at 5-8% opacity as background textures, NOT as full wallpaper reproductions.

**Key Principle:** Each pattern should be SUBTLE—a whisper of texture rather than a bold statement. At full opacity, the pattern should be recognizable; at 5-8% opacity, it becomes a sophisticated background accent that enhances without overwhelming.

---

## Pattern Rendering Standards

### Viewport & Tile Size
- **SVG Viewbox:** 200×200 (ensures crisp scaling across all device sizes)
- **Tile Size:** 200px × 200px (seamless repeat)
- **Repeat Pattern:** Horizontal & vertical seamless tiling
- **Background:** Transparent (allows overlay on any card background)

### Stroke & Fill Specifications
- **Stroke Width Range:** 0.5px–2px (fine to medium detail)
- **Opacity Range:** 0.6–1.0 (strokes should be visible at 100% but subtle at 5-8%)
- **Line Type:** Crisp, anti-aliased vectors
- **Color Strategy:** Use the primary/secondary colors from pattern spec; apply 80-100% opacity to lines

### Seamless Tiling
All patterns must tile seamlessly with no visible seams or discontinuities. Design the pattern so that:
- Left/right edges match
- Top/bottom edges match
- Pattern complexity is distributed evenly to avoid visual "dead zones"

---

## SECTION 1: DE GOURNAY — Chinoiserie

### Design Characteristics
- **Scale:** Delicate, fine linework
- **Motifs:** Branches, blossoms, birds, flowing foliate scrollwork
- **Density:** 20-30% coverage (lots of negative space)
- **Approach:** Hand-drawn aesthetic with organic, slightly irregular lines

### Earlham Pattern Spec

**Primary Elements:**
- Thin, winding branches with hairline strokes (0.75px)
- Small clustered blossoms (4-6px diameter circles with petals)
- Small bird silhouettes in flight (simple 8-12px forms)
- Subtle curved stems and scrollwork

**Construction:**
```
1. Start with 3-4 main branch paths that flow diagonally across the 200×200 tile
2. Branch paths should use SVG <path> with smooth Bezier curves
3. Scatter 8-12 small blossom clusters along branches (2-3 flowers per cluster)
4. Distribute 4-5 bird silhouettes across the composition
5. Add subtle leaf forms (simple ellipses, rotated) at sparse intervals
6. Ensure edges tile smoothly by mirroring/offsetting elements near borders
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#1B3B4D` at 90% opacity
- **Light Mode Secondary Accent:** `#D4AF37` at 60% opacity (gold highlights on select blossoms)
- **Dark Mode Primary Stroke:** `#0F1F2E` at 80% opacity
- **Dark Mode Secondary Accent:** `#F4D89F` at 70% opacity

**SVG Structure Example:**
```xml
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <!-- Main branch paths -->
  <path d="M 10,180 Q 50,140 80,100 T 150,40"
        stroke="#1B3B4D" stroke-width="0.75" fill="none" opacity="0.9"/>

  <!-- Blossom clusters -->
  <circle cx="50" cy="140" r="5" fill="#D4AF37" opacity="0.6"/>
  <circle cx="48" cy="138" r="3" fill="#1B3B4D" opacity="0.9"/>

  <!-- Bird silhouettes -->
  <path d="M 120,80 L 130,75 L 125,85 Z" fill="#1B3B4D" opacity="0.9"/>

  <!-- Subtle leaves -->
  <ellipse cx="90" cy="100" rx="4" ry="8" fill="none"
           stroke="#1B3B4D" stroke-width="0.5" opacity="0.7" transform="rotate(30)"/>
</svg>
```

### Portobello Pattern Spec

**Primary Elements:**
- Gnarled, organic branch structures (1px–1.5px strokes)
- Dense flowering vines with clustered small blooms
- More layered composition than Earlham
- Curved, interweaving stems suggesting wind movement

**Construction:**
```
1. Design 2 main branch pathways that interweave and cross
2. Apply slight irregularity to strokes (use svg filters for subtle hand-drawn effect if possible)
3. Layer flowering vine clusters along branches (5-7 clusters)
4. Add 6-8 small bird forms, some perched, some in flight
5. Include leaf clusters (groups of 3-5 leaves) at strategic intersections
6. Tile edges must have partial elements that mirror on opposite side
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#4A7C8C` at 85% opacity
- **Light Mode Secondary Accent:** `#C9A961` at 50% opacity
- **Dark Mode Primary Stroke:** `#2C4D57` at 75% opacity
- **Dark Mode Secondary Accent:** `#E5C494` at 65% opacity

### Chatsworth Pattern Spec

**Primary Elements:**
- Taller, more architectural trees with defined trunks
- Pavilion/building silhouettes rendered minimally (2-3 strokes)
- Water references (curved lines suggesting flowing water)
- More spatial depth through layering and scale variation
- Denser composition than Earlham (35-40% coverage)

**Construction:**
```
1. Create 2-3 tall tree forms with trunk and canopy silhouettes
2. Add minimal pavilion outlines in middle-ground (simple rectangular forms)
3. Suggest water with flowing curved lines at lower third
4. Distribute smaller scaled elements in background (smaller trees, distance marks)
5. Layer elements to suggest landscape depth
6. Maintain tile continuity at all edges
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#2C5F7C` at 90% opacity
- **Light Mode Secondary Accent:** `#D9A649` at 55% opacity
- **Dark Mode Primary Stroke:** `#1A3A4D` at 85% opacity
- **Dark Mode Secondary Accent:** `#E8C494` at 70% opacity

### St. Laurent Pattern Spec

**Primary Elements:**
- Flowing, abstract branches with emphasis on curve over detail
- Minimal blossom representation (just dots or small marks)
- Contemporary, less ornamental than other de Gournay patterns
- Emphasis on white space and flowing lines
- 15-20% coverage (very sparse and modern)

**Construction:**
```
1. Create 2-3 flowing, curved branch paths with graceful arcs
2. Use very fine strokes (0.5px) for delicate appearance
3. Scatter 4-6 small circular blossoms (just 3-4px dots with optional petals)
4. Add occasional leaf marks (minimal, abstract)
5. Allow for generous negative space
6. Use SVG <path> with smooth transitions for organic feel
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#3D6A7D` at 88% opacity
- **Light Mode Secondary Accent:** `#B8956A` at 45% opacity
- **Dark Mode Primary Stroke:** `#25404F` at 80% opacity
- **Dark Mode Secondary Accent:** `#D4B896` at 60% opacity

---

## SECTION 2: PHILLIP JEFFRIES — Textural Naturalism

### Design Characteristics
- **Scale:** Uniform, repeating texture patterns
- **Motifs:** Horizontal/vertical woven lines, fiber bundles, weave intersections
- **Density:** 50-70% coverage (consistent texture field)
- **Approach:** Regular, mathematical patterns suggesting hand-woven materials

### Heritage Hemp Pattern Spec

**Primary Elements:**
- Horizontal parallel lines with 4-6px spacing
- Subtle vertical ribbing creating grid intersection points
- Irregular fiber nodes at intersections (optional, for texture)
- Slight variation in line opacity to suggest natural fiber irregularity

**Construction:**
```
1. Create 12-15 horizontal lines spanning the full 200px width
2. Add 8-10 vertical lines creating a grid structure
3. Vary line opacity slightly (85-100%) to suggest natural variation
4. Add occasional small circle nodes (1-2px) at intersections
5. Offset alternate horizontal lines by 1-2px for subtle irregularity
6. Ensure seamless horizontal and vertical tiling
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#D4C5B9` at 85% opacity
- **Light Mode Secondary Accent:** `#C2B0A0` at 40% opacity (darker fiber nodes)
- **Dark Mode Primary Stroke:** `#8B7E6F` at 75% opacity
- **Dark Mode Secondary Accent:** `#5E564C` at 55% opacity

**SVG Structure Example:**
```xml
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <!-- Horizontal lines -->
  <line x1="0" y1="10" x2="200" y2="10" stroke="#D4C5B9" stroke-width="1" opacity="0.85"/>
  <line x1="0" y1="20" x2="200" y2="20" stroke="#D4C5B9" stroke-width="1" opacity="0.90"/>

  <!-- Vertical lines -->
  <line x1="15" y1="0" x2="15" y2="200" stroke="#D4C5B9" stroke-width="0.75" opacity="0.80"/>

  <!-- Intersection nodes -->
  <circle cx="15" cy="10" r="1.5" fill="#C2B0A0" opacity="0.4"/>
</svg>
```

### Graceful Grass Pattern Spec

**Primary Elements:**
- Fine, parallel vertical striations (0.5–0.75px stroke width)
- Irregular spacing (3-7px) to suggest natural grass bundling
- Occasional thicker accent strokes for visual rhythm
- Minimal horizontal marks at intervals

**Construction:**
```
1. Create 25-35 vertical lines across 200px width with varying spacing
2. Vary line thickness slightly (0.5px–0.75px) for natural look
3. Every 4th-5th line can be slightly thicker (1px) for accent
4. Add sparse horizontal marks (2-3 total, spanning 20-30px) at different heights
5. Ensure bottom lines connect to top lines when tiled vertically
6. Vary opacity slightly (75-90%) for natural variation
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#D9CFC7` at 80% opacity
- **Light Mode Secondary Accent:** `#C7B8A8` at 35% opacity
- **Dark Mode Primary Stroke:** `#7A7366` at 70% opacity
- **Dark Mode Secondary Accent:** `#5A5047` at 50% opacity

### Refined Raffia Pattern Spec

**Primary Elements:**
- Thicker, bundled fiber strokes (1.5–2px)
- Irregular weave pattern suggesting hand-interlacing
- Occasional breaks in grid lines for organic feel
- Denser than hemp, more visible bundle structure

**Construction:**
```
1. Create 8-12 horizontal "bundles" (groups of 2-3 parallel lines close together)
2. Create 6-8 vertical bundle groups
3. Space bundles 15-20px apart for visible structure
4. Occasionally skip intersections (every 6th-8th) to suggest loose weave
5. Vary bundle line count and spacing within each group
6. Ensure seamless edge tiling by mirroring partial bundles
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#D8C8B8` at 82% opacity
- **Light Mode Secondary Accent:** `#BFA892` at 40% opacity
- **Dark Mode Primary Stroke:** `#9B8B7B` at 72% opacity
- **Dark Mode Secondary Accent:** `#6B5F52` at 55% opacity

### Natural Jute Pattern Spec

**Primary Elements:**
- Uniform crosshatch pattern with consistent spacing
- Equal-weight horizontal and vertical lines (0.75–1px)
- Tight grid structure (4-5px spacing) suggesting dense weave
- Regular pattern with minimal irregularity

**Construction:**
```
1. Create 40-50 horizontal lines spanning full width
2. Create 40-50 vertical lines spanning full height
3. Consistent 4-5px spacing throughout
4. All lines same weight (0.75px) for uniform appearance
5. Optional: very subtle opacity variation (90-95%) across some lines
6. Ensure perfect alignment at tile edges for seamless repeat
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#C9BAA8` at 85% opacity
- **Light Mode Secondary Accent:** `#B8A896` at 30% opacity (very subtle)
- **Dark Mode Primary Stroke:** `#8B7D70` at 75% opacity
- **Dark Mode Secondary Accent:** `#5F564A` at 50% opacity

---

## SECTION 3: SCHUMACHER — Bold Exuberant Patterns

### Design Characteristics
- **Scale:** Large-scale, confident motifs (20-40px elements)
- **Motifs:** Dragons, flowers, fruit, botanicals rendered as bold silhouettes
- **Density:** 40-60% coverage
- **Approach:** Bold linework, filled shapes, strong visual contrast

### Chiang Mai Dragon Pattern Spec

**Primary Elements:**
- Dragon silhouette rendered as flowing curves and S-curves (flowing body)
- Large flower forms (peonies, chrysanthemums) as filled or outlined shapes (15-20px)
- Bold, confident strokes (1.5–2.5px)
- Strong color contrast between dragon and flowers

**Construction:**
```
1. Design a stylized dragon form with sinuous body and minimal detail
   - Use flowing curves (SVG <path> with Bezier)
   - Keep dragon silhouette to 30-40px in length
   - Add small head detail and curling tail
2. Position 4-6 large flower blooms (20px diameter) around dragon
3. Render flowers as:
   - Outlined petals (6-8 petals per flower)
   - Or filled circular forms with center detail
4. Add leaf forms (10-15px) interspersed with flowers
5. Distribute across tile to create balanced composition
6. Tile edges should have partial elements that mirror on opposite side
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#2A5C7C` at 95% opacity
- **Light Mode Primary Fill:** `#2A5C7C` at 70% opacity (for dragon body)
- **Light Mode Secondary Accent:** `#E8B23D` at 90% opacity (flowers, accents)
- **Dark Mode Primary Stroke:** `#1A3C5C` at 90% opacity
- **Dark Mode Primary Fill:** `#1A3C5C` at 65% opacity
- **Dark Mode Secondary Accent:** `#F0C860` at 95% opacity

**SVG Structure Example:**
```xml
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <!-- Dragon body (flowing curves) -->
  <path d="M 20,100 Q 60,80 100,90 Q 140,100 160,120"
        stroke="#2A5C7C" stroke-width="2" fill="none" opacity="0.95"/>

  <!-- Flower 1 (peony-like) -->
  <circle cx="80" cy="50" r="15" fill="#E8B23D" opacity="0.9"/>
  <circle cx="75" cy="48" r="8" fill="white" opacity="0.3"/>

  <!-- Leaf form -->
  <path d="M 60,120 Q 65,115 70,125" stroke="#2A5C7C" stroke-width="1.5" fill="none"/>
</svg>
```

### Citrus Garden Pattern Spec

**Primary Elements:**
- Tree forms with canopy and trunk (rendered as simple silhouettes)
- Large fruit clusters (oranges, lemons as 8-12px circles)
- Flowering vine structures (curving lines with small flowers)
- Broad leaf forms interspersed throughout

**Construction:**
```
1. Design 2-3 tree forms:
   - Trunk: simple 1.5px vertical line, 40-50px height
   - Canopy: irregular circular/oval form (30-40px diameter)
2. Distribute 8-12 fruit circles within/around canopy (8px diameter)
3. Create 2-3 flowering vine paths:
   - Curved lines threading through composition
   - Small 4-6px flowers along vine paths
4. Add large leaf forms (12-20px) scattered throughout
5. Vary opacity and color distribution for visual depth
6. Ensure balanced composition across tile with proper edge alignment
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#3D6B4C` at 90% opacity
- **Light Mode Secondary (Fruit):** `#F5A623` at 95% opacity
- **Light Mode Tertiary (Flowers):** `#FDD835` at 85% opacity
- **Dark Mode Primary Stroke:** `#2A4A38` at 85% opacity
- **Dark Mode Secondary (Fruit):** `#F5C66D` at 95% opacity
- **Dark Mode Tertiary (Flowers):** `#FFEB3B` at 90% opacity

### Josef Frank Botanical Pattern Spec

**Primary Elements:**
- Tropical and temperate botanical forms rendered in flowing style
- Large, organic shapes (orchids, monstera leaves, ferns) 20-35px
- Overlapping composition suggesting density
- Mix of filled and outlined forms
- Red coral accents against green base

**Construction:**
```
1. Design 4-5 main botanical forms:
   - Orchid: simple 3-petaled form with center detail
   - Monstera: large heart-shaped leaf (20-25px)
   - Fern: arc-based frond forms with thin strokes
   - Generic flowering stems (curved lines with clustered blooms)
2. Layer forms with overlapping to suggest density
3. Use both filled and outlined approaches for visual variety
4. Vary opacity and colors within form groups
5. Distribute forms across tile with intentional white space preservation
6. Create organic, non-grid composition
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#4A6F5C` at 85% opacity
- **Light Mode Secondary (Flowers/Accents):** `#D94C4C` at 90% opacity
- **Light Mode Tertiary (Details):** `#E8B23D` at 70% opacity
- **Dark Mode Primary Stroke:** `#2A4A3C` at 80% opacity
- **Dark Mode Secondary (Flowers):** `#E87070` at 95% opacity
- **Dark Mode Tertiary (Details):** `#F0C860` at 75% opacity

### Grand Floral Heritage Pattern Spec

**Primary Elements:**
- Large-scale flower blooms (peonies, roses, dahlias) 25-35px diameter
- Intricate leaf detail (outlined leaves, 10-15px)
- Strong color contrast: deep background with bright flowers
- Confident, bold linework (1.5–2px for outlines)

**Construction:**
```
1. Design 2-3 large focal flower blooms:
   - Render as outlined petals (8-12 petals per bloom)
   - Or as filled forms with internal petal detail
   - Blooms should be 25-35px in diameter
2. Fill in negative space with 3-4 secondary flowers (15-20px)
3. Add abundant leaf detail (10-15px leaves, outlined form)
4. Arrange in balanced, not-too-regular pattern
5. Color blocking: primary color background fill + secondary color petals
6. Tile edges should have partial blooms that mirror on opposite side
```

**Color Specification:**
- **Light Mode Primary (Background/Deep Tones):** `#6B2C4C` at 100% (fill)
- **Light Mode Secondary (Flowers):** `#E8B8C8` at 95% opacity
- **Light Mode Accent (Leaves):** `#4A7C3C` at 80% opacity
- **Dark Mode Primary (Background):** `#4A1C3C` at 90% (fill)
- **Dark Mode Secondary (Flowers):** `#F0D4D8` at 100% opacity
- **Dark Mode Accent (Leaves):** `#C8D894` at 85% opacity

---

## SECTION 4: SCALANDR É — Zoological Silhouettes

### Design Characteristics
- **Scale:** Bold animal forms, 30-50px in size
- **Motifs:** Zebra, cheetah, tiger rendered as confident silhouettes
- **Density:** 30-50% coverage
- **Approach:** High-contrast, strong graphic forms, confident linework

### The Iconic Zebras Pattern Spec

**Primary Elements:**
- Zebra silhouettes (stylized, simplified) 30-40px in height
- Bold stripe detail within zebra forms (2-3px strokes)
- Multiple poses suggesting movement and variety
- Simple, graphic rendering emphasizing silhouette over detail

**Construction:**
```
1. Design 3-4 distinct zebra forms in different poses:
   - Walking: profile view, body horizontal
   - Standing: alert posture
   - Leaping: elevated, dynamic pose
   - Each zebra: 30-40px height
2. Fill zebra forms with stripe pattern:
   - Horizontal stripes (3-4px width) within body outline
   - Use primary color fill with secondary color stripes
   - Or: solid color with darker stripe overlay
3. Position zebras across tile for balanced distribution
4. Leave 40-50% white space
5. Ensure seamless tiling at all edges
```

**Color Specification:**
- **Light Mode Primary Fill:** `#1A1A1A` at 100% opacity
- **Light Mode Stripe/Secondary:** `#F5F5F0` at 100% opacity (creates contrast)
- **Light Mode Optional Underlay:** `#4A7C3C` at 8% opacity (if adding jewel tone)
- **Dark Mode Primary Fill:** `#F5F5F0` at 100% opacity (reversed)
- **Dark Mode Stripe/Secondary:** `#2A2A2A` at 100% opacity
- **Dark Mode Optional Underlay:** `#7AA85A` at 10% opacity

**SVG Structure Example:**
```xml
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <!-- Zebra silhouette -->
  <path d="M 30,100 L 50,80 L 60,85 L 70,75 L 75,100 L 70,110 L 55,105 Z"
        fill="#1A1A1A" opacity="1.0"/>

  <!-- Stripes (horizontal lines within body) -->
  <line x1="35" y1="90" x2="70" y2="90" stroke="#F5F5F0" stroke-width="2"/>
  <line x1="35" y1="100" x2="70" y2="100" stroke="#F5F5F0" stroke-width="2"/>

  <!-- Head detail (eye) -->
  <circle cx="28" cy="100" r="2" fill="#F5F5F0"/>
</svg>
```

### Leaping Cheetah Pattern Spec

**Primary Elements:**
- Dynamic cheetah silhouettes in mid-leap (30-40px height)
- Curved body forms suggesting athletic grace
- Minimal internal detail (just silhouette emphasis)
- Multiple poses suggesting joyful movement

**Construction:**
```
1. Design 3-4 cheetah poses in leaping/pouncing motion:
   - Mid-jump: curved body, legs extended
   - Pounce: body low, rear legs compressed, front extended
   - Landing: symmetrical pose
   - Each cheetah: 30-40px in size
2. Render as filled silhouettes with outline stroke (1-1.5px)
3. Optional: add subtle spot pattern within body (very fine, 1-2px circles)
4. Distribute across tile with varied orientation (some left-facing, some right)
5. Maintain 40-50% white space
6. Ensure smooth tiling at edges
```

**Color Specification:**
- **Light Mode Primary Stroke:** `#3D5C4C` at 95% opacity
- **Light Mode Primary Fill:** `#3D5C4C` at 85% opacity
- **Light Mode Secondary (Spots/Accents):** `#8B4513` at 60% opacity
- **Light Mode Highlight (Optional):** `#D4A459` at 40% opacity
- **Dark Mode Primary Stroke:** `#2A3C2C` at 90% opacity
- **Dark Mode Primary Fill:** `#2A3C2C` at 80% opacity
- **Dark Mode Secondary:** `#C9956A` at 70% opacity
- **Dark Mode Highlight:** `#F0C494` at 50% opacity

### Tigre Pattern Spec

**Primary Elements:**
- Woven texture suggestion (crosshatch or ombré pattern)
- Two bold spine lines (2-3px) suggesting tiger presence
- Subtle color gradient or tone variation within field
- Abstract representation emphasizing texture over literal form

**Construction:**
```
1. Create a base woven texture field (similar to Phillip Jeffries):
   - 30-40 horizontal lines with 4-5px spacing
   - 20-30 vertical lines with 6-8px spacing
   - Primary color at 60-70% opacity for base
2. Add 2 prominent spine/stripe elements:
   - Curved lines (S-shaped or gently curved) spanning 60-80% of tile width
   - 2-3px stroke width, primary color at 95% opacity
   - Positioned at upper-middle and lower-middle of tile
3. Optional: apply subtle opacity gradient to suggest ombré effect
4. Ensure smooth tiling with symmetrical edge handling
```

**Color Specification:**
- **Light Mode Base (Woven Field):** `#8B6F47` at 65% opacity
- **Light Mode Spine Strokes:** `#5A4C3C` at 95% opacity
- **Light Mode Highlight (Secondary):** `#D4B896` at 45% opacity
- **Dark Mode Base (Woven Field):** `#5A4A3C` at 60% opacity
- **Dark Mode Spine Strokes:** `#3A3A3A` at 90% opacity
- **Dark Mode Highlight:** `#C8A882` at 70% opacity

### Tigress Tiger Eye Pattern Spec

**Primary Elements:**
- Stylized eye forms (almond-shaped, pointed) 15-25px
- Curved stripe elements suggesting motion and predatory awareness
- Mix of filled and outlined forms
- Abstract but recognizable as feline symbolism

**Construction:**
```
1. Design 3-5 eye forms:
   - Almond-shaped main form (15-20px)
   - Inner iris circle (6-8px)
   - Optional pupil dot (2px) for intensity
   - Use gradient fill or color blocking
2. Create 2-3 curved stripe elements:
   - Flow around eye forms like whiskers or stripes
   - Use flowing curves (SVG <path>)
   - 1-2px stroke width
3. Optional: add small feline mouth forms (inverted V or arc)
4. Distribute forms across tile in organic, non-grid pattern
5. Vary scale slightly (some eyes larger, some smaller)
6. Ensure white space preservation and smooth edge tiling
```

**Color Specification:**
- **Light Mode Primary (Eyes):** `#6B5C4C` at 90% opacity
- **Light Mode Secondary (Iris):** `#4A3C2C` at 100% opacity
- **Light Mode Accent (Highlights/Stripes):** `#8B7A3C` at 75% opacity
- **Dark Mode Primary (Eyes):** `#4A3C2C` at 85% opacity
- **Dark Mode Secondary (Iris):** `#2A2A2A` at 95% opacity
- **Dark Mode Accent (Highlights):** `#F0D89F` at 80% opacity

---

## Technical Implementation Checklist

When creating SVG patterns, ensure:

- [ ] Viewbox is 200×200px
- [ ] Tile is 200×200px
- [ ] All elements tile seamlessly (left/right edges match, top/bottom edges match)
- [ ] Stroke widths are 0.5px–2px
- [ ] Pattern opacity is designed for 5-8% final rendering
- [ ] Colors match hex codes from spec (± 2% tolerance acceptable)
- [ ] No visible seams or discontinuities in seamless tile
- [ ] All SVG code is clean, commented, and optimized
- [ ] Pattern maintains aspect ratio across all device sizes
- [ ] Both light mode and dark mode colors are tested at target opacity
- [ ] Pattern is recognizable at 100% opacity but subtle at 5-8%

---

## Designer Delivery Format

Provide patterns in the following format:

```
rosier/assets/wallpaper-patterns/
├── de-gournay/
│   ├── earlham.svg
│   ├── portobello.svg
│   ├── chatsworth.svg
│   └── st-laurent.svg
├── phillip-jeffries/
│   ├── heritage-hemp.svg
│   ├── graceful-grass.svg
│   ├── refined-raffia.svg
│   └── natural-jute.svg
├── schumacher/
│   ├── chiang-mai-dragon.svg
│   ├── citrus-garden.svg
│   ├── josef-frank-botanical.svg
│   └── grand-floral-heritage.svg
└── scalamandre/
    ├── iconic-zebras.svg
    ├── leaping-cheetah.svg
    ├── tigre.svg
    └── tigress-tiger-eye.svg
```

Each SVG should include:
- Viewbox and tile size metadata as comments
- Named groups for logical organization
- Color hex codes as comments for easy reference
- Brief description of pattern construction
- Seamless tile confirmation note

---

## Preview & Testing

Before finalizing patterns:

1. **Seamless Tile Test:** Open SVG in browser, scale to 300×300px or larger, verify no visible seams
2. **Opacity Test:** Apply pattern with 5-8% opacity overlay on mock product card backgrounds
3. **Contrast Test:** Verify pattern is visible at 100% but subtle at 5-8% opacity
4. **Color Accuracy:** Check hex codes against specifications in light and dark mode contexts
5. **Scaling Test:** Verify pattern quality at various device sizes (320px, 768px, 1200px viewports)

---

## Resources

- [SVG Patterns Tutorial](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/pattern)
- [SVG Path Commands](https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Paths)
- [SVG Color Reference](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/fill)
- [Seamless Tile Generator Tools](https://www.tileable.com/)
