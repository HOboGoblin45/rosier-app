"""Seed wallpaper houses and patterns."""
import asyncio
import uuid
from datetime import datetime, timezone, timedelta

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.core.config import get_settings
from app.models.wallpaper import (
    WallpaperHouse, WallpaperPattern, PartnershipStatus, PatternType
)


# Define wallpaper houses
WALLPAPER_HOUSES = [
    {
        "name": "de Gournay",
        "slug": "de-gournay",
        "description": "French luxury wallpaper manufacturer specializing in hand-painted chinoiserie and botanical designs.",
        "website_url": "https://www.degournay.com",
        "logo_url": "https://www.degournay.com/logo.png",
        "partnership_status": PartnershipStatus.ACTIVE,
        "monthly_fee": 25000.0,
        "contract_start": datetime.now(timezone.utc),
        "contract_end": datetime.now(timezone.utc) + timedelta(days=365),
    },
    {
        "name": "Phillip Jeffries",
        "slug": "phillip-jeffries",
        "description": "Luxury textural wallcoverings featuring natural fibers and innovative textures from around the world.",
        "website_url": "https://www.phillipjeffries.com",
        "logo_url": "https://www.phillipjeffries.com/logo.png",
        "partnership_status": PartnershipStatus.PROSPECT,
        "monthly_fee": 15000.0,
        "contract_start": None,
        "contract_end": None,
    },
    {
        "name": "Schumacher",
        "slug": "schumacher",
        "description": "American design house producing bold prints and classic patterns since 1889.",
        "website_url": "https://www.fschumacher.com",
        "logo_url": "https://www.fschumacher.com/logo.png",
        "partnership_status": PartnershipStatus.PROSPECT,
        "monthly_fee": 20000.0,
        "contract_start": None,
        "contract_end": None,
    },
    {
        "name": "Scalamandr é",
        "slug": "scalamandre",
        "description": "Premium Italian wallcovering manufacturer known for zoological patterns and luxury designs.",
        "website_url": "https://www.scalamandre.com",
        "logo_url": "https://www.scalamandre.com/logo.png",
        "partnership_status": PartnershipStatus.ACTIVE,
        "monthly_fee": 30000.0,
        "contract_start": datetime.now(timezone.utc),
        "contract_end": datetime.now(timezone.utc) + timedelta(days=365),
    },
]

# Define wallpaper patterns
WALLPAPER_PATTERNS = [
    # de Gournay - Chinoiserie
    {
        "house_slug": "de-gournay",
        "name": "Bamboo Garden",
        "slug": "de-gournay-bamboo-garden",
        "description": "Hand-painted chinoiserie with delicate bamboo motifs and flowering branches.",
        "pattern_type": PatternType.CHINOISERIE,
        "primary_color_light": "#F5F1E8",
        "secondary_color_light": "#2C3E50",
        "primary_color_dark": "#1A1A1A",
        "secondary_color_dark": "#D4AF37",
        "opacity_light": 0.20,
        "opacity_dark": 0.12,
        "style_archetypes": ["Classic Refined", "Romantic Bohemian"],
        "asset_key": "wallpaper/de-gournay/bamboo-garden.png",
        "display_priority": 100,
    },
    {
        "house_slug": "de-gournay",
        "name": "Kyoto Birds",
        "slug": "de-gournay-kyoto-birds",
        "description": "Exquisite hand-painted birds amongst flowering cherry blossoms in authentic chinoiserie style.",
        "pattern_type": PatternType.CHINOISERIE,
        "primary_color_light": "#FFF9F0",
        "secondary_color_light": "#C64B4B",
        "primary_color_dark": "#2A2A2A",
        "secondary_color_dark": "#E8C547",
        "opacity_light": 0.18,
        "opacity_dark": 0.10,
        "style_archetypes": ["Classic Refined", "Vintage Inspired"],
        "asset_key": "wallpaper/de-gournay/kyoto-birds.png",
        "display_priority": 95,
    },
    {
        "house_slug": "de-gournay",
        "name": "Peacock Paradise",
        "slug": "de-gournay-peacock-paradise",
        "description": "Hand-painted peacocks and tropical foliage in the signature de Gournay chinoiserie aesthetic.",
        "pattern_type": PatternType.ZOOLOGICAL,
        "primary_color_light": "#EAE4D8",
        "secondary_color_light": "#1B4D3E",
        "primary_color_dark": "#1F1F1F",
        "secondary_color_dark": "#2E8B9E",
        "opacity_light": 0.22,
        "opacity_dark": 0.14,
        "style_archetypes": ["Classic Refined", "Eclectic Creative"],
        "asset_key": "wallpaper/de-gournay/peacock-paradise.png",
        "display_priority": 90,
    },
    {
        "house_slug": "de-gournay",
        "name": "Silk Route",
        "slug": "de-gournay-silk-route",
        "description": "Inspired by historic trade routes, combining floral and geometric patterns.",
        "pattern_type": PatternType.GEOMETRIC,
        "primary_color_light": "#F0EBE3",
        "secondary_color_light": "#4A6B5E",
        "primary_color_dark": "#262626",
        "secondary_color_dark": "#D4A574",
        "opacity_light": 0.16,
        "opacity_dark": 0.11,
        "style_archetypes": ["Classic Refined"],
        "asset_key": "wallpaper/de-gournay/silk-route.png",
        "display_priority": 85,
    },
    # Phillip Jeffries - Textural
    {
        "house_slug": "phillip-jeffries",
        "name": "Grass Cloth Natural",
        "slug": "phillip-jeffries-grass-cloth-natural",
        "description": "Authentic grass cloth woven from natural fibers creating organic warmth.",
        "pattern_type": PatternType.TEXTURAL,
        "primary_color_light": "#D4C4B0",
        "secondary_color_light": "#A89070",
        "primary_color_dark": "#3A3A3A",
        "secondary_color_dark": "#8B7355",
        "opacity_light": 0.25,
        "opacity_dark": 0.15,
        "style_archetypes": ["Minimalist Modern", "Relaxed Natural"],
        "asset_key": "wallpaper/phillip-jeffries/grass-cloth-natural.png",
        "display_priority": 88,
    },
    {
        "house_slug": "phillip-jeffries",
        "name": "Linen Weave",
        "slug": "phillip-jeffries-linen-weave",
        "description": "Fine linen weave providing subtle texture and sophisticated neutrality.",
        "pattern_type": PatternType.TEXTURAL,
        "primary_color_light": "#EFEFEF",
        "secondary_color_light": "#C8C8C8",
        "primary_color_dark": "#4A4A4A",
        "secondary_color_dark": "#2C2C2C",
        "opacity_light": 0.12,
        "opacity_dark": 0.08,
        "style_archetypes": ["Minimalist Modern", "Minimalist with Edge"],
        "asset_key": "wallpaper/phillip-jeffries/linen-weave.png",
        "display_priority": 92,
    },
    {
        "house_slug": "phillip-jeffries",
        "name": "Cork Texture",
        "slug": "phillip-jeffries-cork-texture",
        "description": "Sustainable cork with natural variation and earthy appeal.",
        "pattern_type": PatternType.TEXTURAL,
        "primary_color_light": "#D9C9B8",
        "secondary_color_light": "#B8A59A",
        "primary_color_dark": "#474030",
        "secondary_color_dark": "#3A3430",
        "opacity_light": 0.20,
        "opacity_dark": 0.12,
        "style_archetypes": ["Relaxed Natural", "Modern Minimalist"],
        "asset_key": "wallpaper/phillip-jeffries/cork-texture.png",
        "display_priority": 85,
    },
    {
        "house_slug": "phillip-jeffries",
        "name": "Silk Finish",
        "slug": "phillip-jeffries-silk-finish",
        "description": "Silken surface treatment creating luminous quality in neutral tones.",
        "pattern_type": PatternType.TEXTURAL,
        "primary_color_light": "#F5F2ED",
        "secondary_color_light": "#E0DDD5",
        "primary_color_dark": "#3E3E3E",
        "secondary_color_dark": "#2C2C2C",
        "opacity_light": 0.15,
        "opacity_dark": 0.09,
        "style_archetypes": ["Quiet Luxury", "Minimalist Modern"],
        "asset_key": "wallpaper/phillip-jeffries/silk-finish.png",
        "display_priority": 90,
    },
    # Schumacher - Bold Prints
    {
        "house_slug": "schumacher",
        "name": "Zebras Forever",
        "slug": "schumacher-zebras-forever",
        "description": "Bold geometric zebra stripe pattern in classic black and white.",
        "pattern_type": PatternType.BOLD_PRINT,
        "primary_color_light": "#FFFFFF",
        "secondary_color_light": "#000000",
        "primary_color_dark": "#2A2A2A",
        "secondary_color_dark": "#E8E8E8",
        "opacity_light": 0.30,
        "opacity_dark": 0.18,
        "style_archetypes": ["Bold Avant-Garde", "Eclectic Creative"],
        "asset_key": "wallpaper/schumacher/zebras-forever.png",
        "display_priority": 95,
    },
    {
        "house_slug": "schumacher",
        "name": "Chiang Mai Dragons",
        "slug": "schumacher-chiang-mai-dragons",
        "description": "Vibrant Thai-inspired pattern with stylized dragons and botanical elements.",
        "pattern_type": PatternType.BOLD_PRINT,
        "primary_color_light": "#FFF8DC",
        "secondary_color_light": "#C1272D",
        "primary_color_dark": "#1A1A1A",
        "secondary_color_dark": "#FFD700",
        "opacity_light": 0.28,
        "opacity_dark": 0.16,
        "style_archetypes": ["Eclectic Creative", "Eclectic Maximalist"],
        "asset_key": "wallpaper/schumacher/chiang-mai-dragons.png",
        "display_priority": 98,
    },
    {
        "house_slug": "schumacher",
        "name": "Summer Chintz",
        "slug": "schumacher-summer-chintz",
        "description": "Cheerful floral chintz with botanical florals and period-inspired color palette.",
        "pattern_type": PatternType.FLORAL,
        "primary_color_light": "#FFFAF0",
        "secondary_color_light": "#D2691E",
        "primary_color_dark": "#2F1F0F",
        "secondary_color_dark": "#C9A877",
        "opacity_light": 0.25,
        "opacity_dark": 0.14,
        "style_archetypes": ["Romantic Bohemian", "Eclectic Creative"],
        "asset_key": "wallpaper/schumacher/summer-chintz.png",
        "display_priority": 88,
    },
    {
        "house_slug": "schumacher",
        "name": "Lacework",
        "slug": "schumacher-lacework",
        "description": "Intricate lacework pattern with art deco inspired geometric design.",
        "pattern_type": PatternType.GEOMETRIC,
        "primary_color_light": "#EAEAEA",
        "secondary_color_light": "#696969",
        "primary_color_dark": "#3A3A3A",
        "secondary_color_dark": "#B0B0B0",
        "opacity_light": 0.20,
        "opacity_dark": 0.12,
        "style_archetypes": ["Bold Avant-Garde", "Eclectic Creative"],
        "asset_key": "wallpaper/schumacher/lacework.png",
        "display_priority": 92,
    },
    # Scalamandr é - Zoological
    {
        "house_slug": "scalamandre",
        "name": "Imperial Lions",
        "slug": "scalamandre-imperial-lions",
        "description": "Majestic lions and ornate detailing in rich jewel tones, quintessential luxury.",
        "pattern_type": PatternType.ZOOLOGICAL,
        "primary_color_light": "#E8D9C3",
        "secondary_color_light": "#8B4513",
        "primary_color_dark": "#1A1410",
        "secondary_color_dark": "#C4A577",
        "opacity_light": 0.28,
        "opacity_dark": 0.16,
        "style_archetypes": ["Bold Avant-Garde", "Eclectic Creative"],
        "asset_key": "wallpaper/scalamandre/imperial-lions.png",
        "display_priority": 100,
    },
    {
        "house_slug": "scalamandre",
        "name": "Jungle Fauna",
        "slug": "scalamandre-jungle-fauna",
        "description": "Exotic jungle animals interspersed with lush vegetation in saturated colors.",
        "pattern_type": PatternType.ZOOLOGICAL,
        "primary_color_light": "#F0E6D2",
        "secondary_color_light": "#2D5016",
        "primary_color_dark": "#2A2A2A",
        "secondary_color_dark": "#8FBC8F",
        "opacity_light": 0.26,
        "opacity_dark": 0.15,
        "style_archetypes": ["Eclectic Maximalist", "Bold Avant-Garde"],
        "asset_key": "wallpaper/scalamandre/jungle-fauna.png",
        "display_priority": 96,
    },
    {
        "house_slug": "scalamandre",
        "name": "Audubon Birds",
        "slug": "scalamandre-audubon-birds",
        "description": "Hand-colored Audubon-style bird illustrations with botanical backgrounds.",
        "pattern_type": PatternType.ZOOLOGICAL,
        "primary_color_light": "#FFFEF7",
        "secondary_color_light": "#6B5B4F",
        "primary_color_dark": "#2B2B2B",
        "secondary_color_dark": "#D4B896",
        "opacity_light": 0.24,
        "opacity_dark": 0.13,
        "style_archetypes": ["Classic Refined", "Vintage Inspired"],
        "asset_key": "wallpaper/scalamandre/audubon-birds.png",
        "display_priority": 94,
    },
    {
        "house_slug": "scalamandre",
        "name": "Malachite Dreams",
        "slug": "scalamandre-malachite-dreams",
        "description": "Luxurious malachite-inspired pattern with abstract organic forms.",
        "pattern_type": PatternType.GEOMETRIC,
        "primary_color_light": "#E8F4F8",
        "secondary_color_light": "#1B6E6E",
        "primary_color_dark": "#1F1F1F",
        "secondary_color_dark": "#4A9BA8",
        "opacity_light": 0.22,
        "opacity_dark": 0.12,
        "style_archetypes": ["Bold Avant-Garde", "Quiet Luxury"],
        "asset_key": "wallpaper/scalamandre/malachite-dreams.png",
        "display_priority": 91,
    },
]


async def seed_wallpaper_data():
    """Seed the database with wallpaper houses and patterns."""
    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    # Create session factory
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Create wallpaper houses
        house_map = {}  # For pattern reference
        for house_data in WALLPAPER_HOUSES:
            house = WallpaperHouse(
                id=uuid.uuid4(),
                name=house_data["name"],
                slug=house_data["slug"],
                description=house_data["description"],
                website_url=house_data["website_url"],
                logo_url=house_data["logo_url"],
                partnership_status=house_data["partnership_status"],
                monthly_fee=house_data["monthly_fee"],
                contract_start=house_data["contract_start"],
                contract_end=house_data["contract_end"],
                is_active=True,
            )
            session.add(house)
            house_map[house_data["slug"]] = house
            print(f"Created house: {house.name}")

        await session.flush()

        # Create wallpaper patterns
        for pattern_data in WALLPAPER_PATTERNS:
            house_slug = pattern_data.pop("house_slug")
            house = house_map[house_slug]

            pattern = WallpaperPattern(
                id=uuid.uuid4(),
                house_id=house.id,
                name=pattern_data["name"],
                slug=pattern_data["slug"],
                description=pattern_data["description"],
                pattern_type=pattern_data["pattern_type"],
                primary_color_light=pattern_data["primary_color_light"],
                secondary_color_light=pattern_data["secondary_color_light"],
                primary_color_dark=pattern_data["primary_color_dark"],
                secondary_color_dark=pattern_data["secondary_color_dark"],
                opacity_light=pattern_data["opacity_light"],
                opacity_dark=pattern_data["opacity_dark"],
                style_archetypes=pattern_data["style_archetypes"],
                asset_key=pattern_data["asset_key"],
                display_priority=pattern_data["display_priority"],
                is_active=True,
            )
            session.add(pattern)
            print(f"Created pattern: {pattern.name} ({house.name})")

        await session.commit()
        print("\nWallpaper seed data completed successfully!")


if __name__ == "__main__":
    asyncio.run(seed_wallpaper_data())
