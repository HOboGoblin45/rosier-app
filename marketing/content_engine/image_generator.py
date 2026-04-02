"""
Rosier Image Generator - Branded Social Media Graphics

Generates high-quality, branded social media images using PIL (Pillow).
Maintains consistent aesthetic: luxury, minimal, sophisticated.

Design specs:
- Instagram Feed: 1080x1080px
- Stories/Reels: 1080x1920px
- TikTok: 1080x1920px
- Colors: Primary #1A1A2E, Accent #C4A77D, Surface #F8F6F3
- Typography: Clean, minimal, serif headers
"""

import io
from typing import Dict, List, Optional, Tuple
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path


class RosierImageGenerator:
    """Generates branded graphics for social media content"""

    # Rosier brand colors
    COLORS = {
        'primary': '#1A1A2E',      # Dark navy
        'accent': '#C4A77D',       # Gold
        'surface': '#F8F6F3',      # Off-white
        'text': '#FFFFFF',         # White
        'text_dark': '#1A1A2E',    # Dark text
        'divider': '#E8E6E1',      # Light gray
    }

    # Standard dimensions
    DIMENSIONS = {
        'instagram_square': (1080, 1080),
        'instagram_reel': (1080, 1920),
        'tiktok': (1080, 1920),
        'stories': (1080, 1920),
    }

    def __init__(self):
        """Initialize image generator with brand assets"""
        self.font_large = self._get_font('bold', 72)
        self.font_medium = self._get_font('bold', 48)
        self.font_body = self._get_font('regular', 36)
        self.font_small = self._get_font('regular', 28)

    def _get_font(self, weight: str = 'regular', size: int = 36) -> ImageFont.FreeTypeFont:
        """
        Get system font or fallback to default.

        In production, would use downloadable free fonts like:
        - Helvetica Neue / Arial for sans-serif
        - Georgia / Garamond for serif headers
        """
        try:
            # Try system fonts (macOS/Linux)
            font_paths = [
                f"/System/Library/Fonts/Helvetica.ttc",  # macOS
                f"/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",  # Linux
                f"C:\\Windows\\Fonts\\arial.ttf",  # Windows
            ]

            for path in font_paths:
                try:
                    return ImageFont.truetype(path, size)
                except:
                    continue

            # Fallback to default
            return ImageFont.load_default()
        except:
            return ImageFont.load_default()

    def create_trending_card(self, brands: List[str], scores: List[int]) -> bytes:
        """
        Creates 1080x1080 branded card showing trending brands.

        Args:
            brands: List of brand names (top 3)
            scores: List of affinity scores (0-100)

        Returns:
            bytes: PNG image data
        """
        brands = brands[:3]
        scores = scores[:3]

        img = Image.new('RGB', self.DIMENSIONS['instagram_square'], self.COLORS['surface'])
        draw = ImageDraw.Draw(img)

        # Header
        draw.text((540, 80), "TRENDING ON ROSIER", fill=self.COLORS['primary'],
                 font=self.font_medium, anchor='mm')
        draw.text((540, 140), "This Week", fill=self.COLORS['accent'],
                 font=self.font_small, anchor='mm')

        # Divider
        draw.line([(150, 200), (930, 200)], fill=self.COLORS['accent'], width=2)

        # Brand rankings
        y_start = 280
        spacing = 200

        for i, (brand, score) in enumerate(zip(brands, scores)):
            y = y_start + (i * spacing)

            # Rank number
            draw.text((100, y), f"#{i+1}", fill=self.COLORS['accent'],
                     font=self.font_large, anchor='lm')

            # Brand name
            draw.text((250, y), brand, fill=self.COLORS['text_dark'],
                     font=self.font_medium, anchor='lm')

            # Score bar background
            bar_width = 500
            bar_height = 12
            bar_x = 250
            bar_y = y + 60

            draw.rectangle(
                [(bar_x, bar_y), (bar_x + bar_width, bar_y + bar_height)],
                fill=self.COLORS['divider']
            )

            # Score bar fill
            fill_width = int((score / 100) * bar_width)
            draw.rectangle(
                [(bar_x, bar_y), (bar_x + fill_width, bar_y + bar_height)],
                fill=self.COLORS['accent']
            )

            # Score percentage
            draw.text((bar_x + bar_width + 50, bar_y + bar_height // 2), f"{score}%",
                     fill=self.COLORS['text_dark'], font=self.font_small, anchor='lm')

        # Footer CTA
        draw.line([(150, 1000), (930, 1000)], fill=self.COLORS['accent'], width=2)
        draw.text((540, 1050), "Swipe your style on Rosier", fill=self.COLORS['primary'],
                 font=self.font_body, anchor='mm')

        # Convert to bytes
        return self._image_to_bytes(img)

    def create_brand_spotlight(self, brand_name: str, stats: Dict) -> bytes:
        """
        Creates brand spotlight graphic.

        Args:
            brand_name: Name of brand
            stats: {'growth': int, 'position': int, 'description': str}

        Returns:
            bytes: PNG image data
        """
        img = Image.new('RGB', self.DIMENSIONS['instagram_square'], self.COLORS['primary'])
        draw = ImageDraw.Draw(img)

        # Large brand name
        draw.text((540, 300), brand_name, fill=self.COLORS['accent'],
                 font=self.font_large, anchor='mm')

        # Stats boxes
        stats_y = 500

        # Growth box
        growth = stats.get('growth', 15)
        draw.rectangle([(150, stats_y), (450, stats_y + 200)],
                      fill=self.COLORS['accent'])
        draw.text((300, stats_y + 100), f"+{growth}%", fill=self.COLORS['surface'],
                 font=self.font_large, anchor='mm')
        draw.text((300, stats_y + 160), "Growth This Week", fill=self.COLORS['surface'],
                 font=self.font_small, anchor='mm')

        # Position box
        position = stats.get('position', 5)
        draw.rectangle([(630, stats_y), (930, stats_y + 200)],
                      fill=self.COLORS['surface'], outline=self.COLORS['accent'], width=2)
        draw.text((780, stats_y + 100), f"#{position}", fill=self.COLORS['primary'],
                 font=self.font_large, anchor='mm')
        draw.text((780, stats_y + 160), "Trending", fill=self.COLORS['primary'],
                 font=self.font_small, anchor='mm')

        # Description
        description = stats.get('description', 'Contemporary + Emerging')
        draw.text((540, 850), description, fill=self.COLORS['surface'],
                 font=self.font_body, anchor='mm')

        # CTA
        draw.text((540, 950), "Discover on Rosier", fill=self.COLORS['accent'],
                 font=self.font_body, anchor='mm')

        return self._image_to_bytes(img)

    def create_style_archetype_card(self, archetype: str, stats: Dict) -> bytes:
        """
        Creates shareable Style DNA card (Instagram Stories format).

        Args:
            archetype: Style name (e.g., 'Dark Academia')
            stats: {'percentage': int, 'related_archetypes': List[str]}

        Returns:
            bytes: PNG image data
        """
        img = Image.new('RGB', self.DIMENSIONS['instagram_reel'], self.COLORS['surface'])
        draw = ImageDraw.Draw(img)

        # Header
        draw.text((540, 200), "YOUR STYLE DNA", fill=self.COLORS['primary'],
                 font=self.font_medium, anchor='mm')

        # Large archetype name
        draw.text((540, 600), archetype, fill=self.COLORS['accent'],
                 font=self.font_large, anchor='mm')

        # Percentage circle simulation
        percentage = stats.get('percentage', 45)
        draw.text((540, 800), f"{percentage}% of your swipes", fill=self.COLORS['text_dark'],
                 font=self.font_body, anchor='mm')

        # Related archetypes
        related = stats.get('related_archetypes', [])
        if related:
            draw.text((540, 950), "Also you:", fill=self.COLORS['text_dark'],
                     font=self.font_small, anchor='mm')
            y = 1020
            for style in related[:2]:
                draw.text((540, y), f"+ {style}", fill=self.COLORS['accent'],
                         font=self.font_body, anchor='mm')
                y += 80

        # Footer
        draw.text((540, 1800), "Share your Style DNA", fill=self.COLORS['primary'],
                 font=self.font_small, anchor='mm')
        draw.text((540, 1880), "#MyRosierStyle", fill=self.COLORS['accent'],
                 font=self.font_body, anchor='mm')

        return self._image_to_bytes(img)

    def create_weekly_roundup(self, top_brands: List[str], top_categories: List[str]) -> bytes:
        """
        Creates weekly trend summary graphic.

        Args:
            top_brands: List of top brand names
            top_categories: List of top categories/styles

        Returns:
            bytes: PNG image data
        """
        img = Image.new('RGB', self.DIMENSIONS['instagram_square'], self.COLORS['primary'])
        draw = ImageDraw.Draw(img)

        # Title
        draw.text((540, 100), "WEEKLY ROUNDUP", fill=self.COLORS['accent'],
                 font=self.font_large, anchor='mm')
        draw.text((540, 170), "April 1-7", fill=self.COLORS['surface'],
                 font=self.font_small, anchor='mm')

        # Section 1: Top Brands
        draw.text((540, 280), "YOUR TOP BRANDS", fill=self.COLORS['surface'],
                 font=self.font_medium, anchor='mm')

        y = 380
        for i, brand in enumerate(top_brands[:3]):
            draw.text((140, y), f"{i+1}. {brand}", fill=self.COLORS['accent'],
                     font=self.font_body, anchor='lm')
            y += 100

        # Section 2: Emerging
        draw.text((540, 750), "EMERGING", fill=self.COLORS['surface'],
                 font=self.font_medium, anchor='mm')

        y = 850
        for category in top_categories[:2]:
            draw.text((140, y), f"→ {category}", fill=self.COLORS['surface'],
                     font=self.font_body, anchor='lm')
            y += 100

        # Footer
        draw.text((540, 1050), "See full report on Rosier", fill=self.COLORS['accent'],
                 font=self.font_small, anchor='mm')

        return self._image_to_bytes(img)

    def create_price_drop_card(self, product: Dict, savings: int) -> bytes:
        """
        Creates price drop alert graphic.

        Args:
            product: {'brand': str, 'name': str, 'old_price': str, 'new_price': str}
            savings: Percentage saved (e.g., 33)

        Returns:
            bytes: PNG image data
        """
        img = Image.new('RGB', self.DIMENSIONS['instagram_reel'], self.COLORS['surface'])
        draw = ImageDraw.Draw(img)

        # Price drop banner (red/urgent)
        draw.rectangle([(0, 0), (1080, 200)], fill=self.COLORS['primary'])

        draw.text((540, 100), "PRICE DROP ALERT", fill=self.COLORS['accent'],
                 font=self.font_medium, anchor='mm')

        # Brand name
        draw.text((540, 400), product.get('brand', 'Brand'), fill=self.COLORS['primary'],
                 font=self.font_medium, anchor='mm')

        # Product name (wrapped)
        product_name = product.get('name', 'Product')
        draw.text((540, 550), product_name, fill=self.COLORS['text_dark'],
                 font=self.font_body, anchor='mm')

        # Price comparison
        old_price = product.get('old_price', '$500')
        new_price = product.get('new_price', '$250')

        # Old price (strikethrough effect with line)
        draw.text((350, 750), old_price, fill=self.COLORS['divider'],
                 font=self.font_body, anchor='mm')
        draw.line([(250, 750), (450, 750)], fill=self.COLORS['divider'], width=2)

        # New price (large, accent color)
        draw.text((750, 750), new_price, fill=self.COLORS['accent'],
                 font=self.font_large, anchor='mm')

        # Savings badge
        draw.rectangle([(300, 950), (780, 1100)], fill=self.COLORS['accent'])
        draw.text((540, 1025), f"SAVE {savings}%", fill=self.COLORS['surface'],
                 font=self.font_large, anchor='mm')

        # CTA
        draw.text((540, 1300), "Get price alerts on Rosier", fill=self.COLORS['primary'],
                 font=self.font_body, anchor='mm')

        draw.text((540, 1850), "Link in bio", fill=self.COLORS['accent'],
                 font=self.font_small, anchor='mm')

        return self._image_to_bytes(img)

    def create_daily_drop_preview(self, brands: List[str], count: int = 5) -> bytes:
        """
        Creates Daily Drop teaser card.

        Args:
            brands: List of brands in today's drop
            count: Number of items (usually 5)

        Returns:
            bytes: PNG image data
        """
        img = Image.new('RGB', self.DIMENSIONS['instagram_reel'], self.COLORS['primary'])
        draw = ImageDraw.Draw(img)

        # Header
        draw.text((540, 200), "DAILY DROP", fill=self.COLORS['accent'],
                 font=self.font_large, anchor='mm')
        draw.text((540, 290), f"{count} New Brands Today", fill=self.COLORS['surface'],
                 font=self.font_medium, anchor='mm')

        # Divider
        draw.line([(150, 400), (930, 400)], fill=self.COLORS['accent'], width=2)

        # Brand list
        y = 550
        spacing = 160

        for i, brand in enumerate(brands[:5]):
            draw.text((540, y + (i * spacing)), brand, fill=self.COLORS['surface'],
                     font=self.font_body, anchor='mm')

        # Bottom CTA
        draw.line([(150, 1750), (930, 1750)], fill=self.COLORS['accent'], width=2)
        draw.text((540, 1850), "Swipe First", fill=self.COLORS['accent'],
                 font=self.font_medium, anchor='mm')

        return self._image_to_bytes(img)

    def _image_to_bytes(self, img: Image.Image) -> bytes:
        """Convert PIL Image to PNG bytes"""
        img_io = io.BytesIO()
        img.save(img_io, 'PNG', quality=95)
        img_io.seek(0)
        return img_io.getvalue()

    def save_image(self, image_bytes: bytes, filepath: str) -> None:
        """Save image bytes to file"""
        Path(filepath).parent.mkdir(parents=True, exist_ok=True)
        with open(filepath, 'wb') as f:
            f.write(image_bytes)


if __name__ == '__main__':
    # Test the image generator
    generator = RosierImageGenerator()

    # Test trending card
    trending = generator.create_trending_card(
        brands=['Ganni', 'Deiji Studios', 'Khaite'],
        scores=[85, 78, 72]
    )
    generator.save_image(trending, '/tmp/trending_test.png')
    print("Created trending card: /tmp/trending_test.png")

    # Test brand spotlight
    spotlight = generator.create_brand_spotlight(
        'GANNI',
        {'growth': 23, 'position': 1, 'description': 'Contemporary Luxury'}
    )
    generator.save_image(spotlight, '/tmp/spotlight_test.png')
    print("Created spotlight: /tmp/spotlight_test.png")

    # Test style DNA card
    style_card = generator.create_style_archetype_card(
        'Dark Academia',
        {'percentage': 45, 'related_archetypes': ['Quiet Luxury', '90s Minimalism']}
    )
    generator.save_image(style_card, '/tmp/style_dna_test.png')
    print("Created style DNA card: /tmp/style_dna_test.png")

    print("\nAll test images created successfully!")
