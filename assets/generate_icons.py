#!/usr/bin/env python3
"""
Rosier App Icon Generator
Generates app icon assets in various sizes for iOS and Android.
Requirements: Pillow (PIL)
"""

from PIL import Image, ImageDraw, ImageFont
import os
import sys

# Color palette from Rosier brand guide
ROSE = (232, 180, 184)  # #E8B4B8
CREAM = (255, 248, 240)  # #FFF8F0
SAGE = (168, 196, 184)  # #A8C4B8
CHARCOAL = (44, 44, 44)  # #2C2C2C

# Icon sizes (width, height)
SIZES = [
    (1024, 1024, "icons/app_icon_1024.png"),
    (180, 180, "icons/app_icon_180.png"),    # iPhone App Icon
    (120, 120, "icons/app_icon_120.png"),    # iPhone Notification
    (87, 87, "icons/app_icon_87.png"),       # iPhone Settings
    (80, 80, "icons/app_icon_80.png"),       # iPhone Spotlight
    (60, 60, "icons/app_icon_60.png"),       # iPhone Notification
    (40, 40, "icons/app_icon_40.png"),       # iPhone Spotlight (2x)
]

def create_gradient_background(size, rose_color, cream_color, sage_color):
    """Create a luxury gradient background."""
    img = Image.new('RGB', size, color=CREAM)
    pixels = img.load()

    width, height = size

    # Create a gradient from rose/blush to sage with cream accents
    for y in range(height):
        for x in range(width):
            # Calculate position ratios
            x_ratio = x / width
            y_ratio = y / height

            # Create diagonal gradient from top-left (rose) to bottom-right (sage)
            blend_ratio = (x_ratio + y_ratio) / 2

            if blend_ratio < 0.3:
                # Rose to cream transition
                r = int(ROSE[0] + (CREAM[0] - ROSE[0]) * (blend_ratio / 0.3))
                g = int(ROSE[1] + (CREAM[1] - ROSE[1]) * (blend_ratio / 0.3))
                b = int(ROSE[2] + (CREAM[2] - ROSE[2]) * (blend_ratio / 0.3))
            elif blend_ratio < 0.7:
                # Cream transition
                r = CREAM[0]
                g = CREAM[1]
                b = CREAM[2]
            else:
                # Cream to sage transition
                progress = (blend_ratio - 0.7) / 0.3
                r = int(CREAM[0] + (SAGE[0] - CREAM[0]) * progress)
                g = int(CREAM[1] + (SAGE[1] - CREAM[1]) * progress)
                b = int(CREAM[2] + (SAGE[2] - CREAM[2]) * progress)

            pixels[x, y] = (r, g, b)

    return img

def add_subtle_pattern(img):
    """Add subtle pattern or texture overlay."""
    draw = ImageDraw.Draw(img, 'RGBA')
    size = img.size

    # Add subtle circular elements for luxury feel
    # Small circles with very low opacity
    circle_size = max(size) // 8

    # Top-left area
    draw.ellipse(
        [(circle_size * 0.2, circle_size * 0.2),
         (circle_size * 1.2, circle_size * 1.2)],
        outline=(232, 180, 184, 15),
        width=2
    )

    # Bottom-right area
    x1 = size[0] - circle_size * 1.2
    y1 = size[1] - circle_size * 1.2
    x2 = size[0] - circle_size * 0.2
    y2 = size[1] - circle_size * 0.2
    draw.ellipse(
        [(x1, y1), (x2, y2)],
        outline=(168, 196, 184, 15),
        width=2
    )

    return img

def create_app_icon(size):
    """Create a single app icon of specified size."""
    # Create base gradient background
    img = create_gradient_background(size, ROSE, CREAM, SAGE)

    # Add subtle pattern
    img = add_subtle_pattern(img)

    # Create drawing context
    draw = ImageDraw.Draw(img)

    # Draw elegant "R" lettermark
    # Calculate dimensions
    width, height = size
    center_x = width // 2
    center_y = height // 2

    # Letter size (about 60% of icon)
    letter_size = int(width * 0.5)

    # Try to use a system font, fall back to default
    try:
        # Try multiple font options
        font_path = None
        possible_fonts = [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/Windows/Fonts/arial.ttf",
        ]

        for font_path_candidate in possible_fonts:
            if os.path.exists(font_path_candidate):
                font_path = font_path_candidate
                break

        if font_path:
            font = ImageFont.truetype(font_path, letter_size)
        else:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()

    # Draw the "R" letter
    text = "R"

    # Calculate text bounding box for centering
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Position text in center
    x = center_x - text_width // 2
    y = center_y - text_height // 2

    # Draw with charcoal color
    draw.text((x, y), text, fill=CHARCOAL, font=font)

    # Add subtle decorative element - small dot
    dot_size = max(1, size[0] // 40)
    dot_offset = int(width * 0.15)

    # Top-right dot
    dot_x = width - dot_offset
    dot_y = dot_offset
    draw.ellipse(
        [(dot_x - dot_size, dot_y - dot_size),
         (dot_x + dot_size, dot_y + dot_size)],
        fill=ROSE
    )

    return img

def generate_all_icons():
    """Generate all icon sizes."""
    print("Rosier App Icon Generator")
    print("=" * 50)

    # Ensure output directory exists
    output_dir = "icons"
    os.makedirs(output_dir, exist_ok=True)

    for width, height, filepath in SIZES:
        try:
            print(f"Generating {width}x{height}... ", end="", flush=True)

            icon = create_app_icon((width, height))

            # Convert to RGB (remove alpha if present, as per App Store requirement)
            if icon.mode != 'RGB':
                icon = icon.convert('RGB')

            # Save as PNG
            icon.save(filepath, 'PNG', quality=95)

            print(f"OK -> {filepath}")

        except Exception as e:
            print(f"ERROR: {e}")
            return False

    print("=" * 50)
    print("All icons generated successfully!")
    print("\nIcon files created:")
    for _, _, filepath in SIZES:
        full_path = os.path.abspath(filepath)
        if os.path.exists(filepath):
            size_kb = os.path.getsize(filepath) / 1024
            print(f"  ✓ {filepath} ({size_kb:.1f} KB)")

    print("\nNext steps:")
    print("1. Upload the 1024x1024 icon to App Store Connect")
    print("2. Use the other sizes for iOS app bundle assets")
    print("3. For Android, resize as needed for different densities")

    return True

if __name__ == "__main__":
    try:
        from PIL import Image, ImageDraw
        success = generate_all_icons()
        sys.exit(0 if success else 1)
    except ImportError:
        print("ERROR: Pillow (PIL) is required.")
        print("Install with: pip install Pillow")
        sys.exit(1)
