"""Seed database with realistic test data."""
import asyncio
import uuid
from datetime import datetime, timezone, timedelta
import random

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.core.config import get_settings
from app.models import (
    Retailer, Brand, Product, User, DresserDrawer, DresserItem,
    SwipeEvent, RefreshToken, BrandCandidate, BrandDiscoveryCard, BrandDiscoverySwipe
)
from app.models.retailer import AffiliateNetwork, ProductFeedFormat
from app.models.brand import BrandTier
from app.models.brand_candidate import BrandCandidateStatus, AffiliateNetworkType
from app.models.swipe_event import SwipeAction


# Define retailers
RETAILERS = [
    {
        "name": "SSENSE",
        "slug": "ssense",
        "network": AffiliateNetwork.RAKUTEN,
        "commission": 0.08,
        "favicon": "https://www.ssense.com/favicon.ico"
    },
    {
        "name": "Farfetch",
        "slug": "farfetch",
        "network": AffiliateNetwork.IMPACT,
        "commission": 0.07,
        "favicon": "https://www.farfetch.com/favicon.ico"
    },
    {
        "name": "Mytheresa",
        "slug": "mytheresa",
        "network": AffiliateNetwork.RAKUTEN,
        "commission": 0.08,
        "favicon": "https://www.mytheresa.com/favicon.ico"
    },
    {
        "name": "NET-A-PORTER",
        "slug": "net-a-porter",
        "network": AffiliateNetwork.RAKUTEN,
        "commission": 0.06,
        "favicon": "https://www.net-a-porter.com/favicon.ico"
    },
    {
        "name": "END Clothing",
        "slug": "end-clothing",
        "network": AffiliateNetwork.AWIN,
        "commission": 0.06,
        "favicon": "https://www.endclothing.com/favicon.ico"
    },
    {
        "name": "Moda Operandi",
        "slug": "moda-operandi",
        "network": AffiliateNetwork.RAKUTEN,
        "commission": 0.09,
        "favicon": "https://www.modaoperandi.com/favicon.ico"
    },
    {
        "name": "LuisaViaRoma",
        "slug": "luisaviaroma",
        "network": AffiliateNetwork.AWIN,
        "commission": 0.07,
        "favicon": "https://www.luisaviaroma.com/favicon.ico"
    },
    {
        "name": "Garmentory",
        "slug": "garmentory",
        "network": AffiliateNetwork.DIRECT,
        "commission": 0.10,
        "favicon": "https://www.garmentory.com/favicon.ico"
    },
    {
        "name": "Wolf & Badger",
        "slug": "wolf-badger",
        "network": AffiliateNetwork.DIRECT,
        "commission": 0.12,
        "favicon": "https://www.wolfandbadger.com/favicon.ico"
    },
]

# Define brands with their tiers, aesthetics, price ranges, and affiliate details
BRANDS = [
    # Luxury tier
    {"name": "Paloma Wool", "tier": BrandTier.PREMIUM, "price": (300, 800), "aesthetics": ["minimalist", "luxury", "sustainable"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.10, "ambassador": True},
    {"name": "Lemaire", "tier": BrandTier.PREMIUM, "price": (400, 1200), "aesthetics": ["minimalist", "crafted", "luxury"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.12, "ambassador": True},
    {"name": "The Row", "tier": BrandTier.PREMIUM, "price": (500, 1500), "aesthetics": ["minimalist", "luxury", "timeless"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.08, "ambassador": True},
    {"name": "Khaite", "tier": BrandTier.PREMIUM, "price": (350, 1200), "aesthetics": ["elegant", "luxury", "contemporary"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.10, "ambassador": True},
    {"name": "Jacquemus", "tier": BrandTier.PREMIUM, "price": (300, 900), "aesthetics": ["playful", "contemporary", "luxury"], "affiliate_network": AffiliateNetworkType.AWIN, "commission": 0.12, "ambassador": True},
    {"name": "Peter Do", "tier": BrandTier.PREMIUM, "price": (400, 1000), "aesthetics": ["architectural", "luxury", "crafted"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.10, "ambassador": True},

    # Premium/Contemporary tier
    {"name": "Ganni", "tier": BrandTier.PREMIUM, "price": (100, 400), "aesthetics": ["playful", "contemporary", "sustainable"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.10, "ambassador": True},
    {"name": "Staud", "tier": BrandTier.PREMIUM, "price": (150, 600), "aesthetics": ["playful", "contemporary", "colorful"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.12, "ambassador": True},
    {"name": "Nanushka", "tier": BrandTier.PREMIUM, "price": (150, 600), "aesthetics": ["minimalist", "contemporary", "luxury"], "affiliate_network": AffiliateNetworkType.AWIN, "commission": 0.11, "ambassador": True},
    {"name": "Rachel Comey", "tier": BrandTier.PREMIUM, "price": (200, 800), "aesthetics": ["architectural", "contemporary", "artistic"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.10, "ambassador": True},
    {"name": "Sandy Liang", "tier": BrandTier.PREMIUM, "price": (100, 400), "aesthetics": ["playful", "vintage", "contemporary"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.12, "ambassador": True},
    {"name": "Chopova Lowena", "tier": BrandTier.PREMIUM, "price": (150, 500), "aesthetics": ["colorful", "artistic", "maximalist"], "affiliate_network": AffiliateNetworkType.AWIN, "commission": 0.10, "ambassador": True},
    {"name": "Eckhaus Latta", "tier": BrandTier.CONTEMPORARY, "price": (120, 450), "aesthetics": ["artistic", "colorful", "contemporary"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.11, "ambassador": True},
    {"name": "Dion Lee", "tier": BrandTier.PREMIUM, "price": (200, 800), "aesthetics": ["architectural", "contemporary", "luxury"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.10, "ambassador": True},
    {"name": "Aeron", "tier": BrandTier.PREMIUM, "price": (100, 500), "aesthetics": ["contemporary", "minimalist", "tech"], "affiliate_network": AffiliateNetworkType.DIRECT, "commission": 0.15, "ambassador": False},
    {"name": "Cecilie Bahnsen", "tier": BrandTier.PREMIUM, "price": (150, 700), "aesthetics": ["romantic", "contemporary", "artisanal"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.12, "ambassador": True},

    # Contemporary tier
    {"name": "Molly Goddard", "tier": BrandTier.CONTEMPORARY, "price": (80, 300), "aesthetics": ["playful", "romantic", "tulle"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.12, "ambassador": True},
    {"name": "Danielle Guizio", "tier": BrandTier.CONTEMPORARY, "price": (100, 400), "aesthetics": ["sexy", "contemporary", "playful"], "affiliate_network": AffiliateNetworkType.AWIN, "commission": 0.11, "ambassador": True},
    {"name": "Collina Strada", "tier": BrandTier.CONTEMPORARY, "price": (100, 350), "aesthetics": ["playful", "contemporary", "colorful"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.10, "ambassador": True},
    {"name": "Connor Ives", "tier": BrandTier.CONTEMPORARY, "price": (150, 500), "aesthetics": ["romantic", "contemporary", "crafted"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.11, "ambassador": True},
    {"name": "Anderson Bell", "tier": BrandTier.CONTEMPORARY, "price": (100, 400), "aesthetics": ["playful", "contemporary", "colorful"], "affiliate_network": AffiliateNetworkType.DIRECT, "commission": 0.12, "ambassador": False},
    {"name": "Baserange", "tier": BrandTier.CONTEMPORARY, "price": (70, 250), "aesthetics": ["minimalist", "sustainable", "comfortable"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.10, "ambassador": True},
    {"name": "Low Classic", "tier": BrandTier.CONTEMPORARY, "price": (100, 400), "aesthetics": ["minimalist", "contemporary", "quiet"], "affiliate_network": AffiliateNetworkType.AWIN, "commission": 0.10, "ambassador": False},
    {"name": "Cult Gaia", "tier": BrandTier.CONTEMPORARY, "price": (80, 350), "aesthetics": ["playful", "contemporary", "artisanal"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.12, "ambassador": True},
    {"name": "Marine Serre", "tier": BrandTier.CONTEMPORARY, "price": (150, 600), "aesthetics": ["sustainable", "contemporary", "artistic"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.11, "ambassador": True},
    {"name": "Deiji Studios", "tier": BrandTier.CONTEMPORARY, "price": (80, 300), "aesthetics": ["minimalist", "sustainable", "relaxed", "loungewear"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.11, "ambassador": False},
    {"name": "Rotate", "tier": BrandTier.PREMIUM, "price": (150, 500), "aesthetics": ["playful", "contemporary", "luxury"], "affiliate_network": AffiliateNetworkType.IMPACT, "commission": 0.10, "ambassador": True},
    {"name": "Reformation", "tier": BrandTier.PREMIUM, "price": (100, 500), "aesthetics": ["sustainable", "contemporary", "playful"], "affiliate_network": AffiliateNetworkType.RAKUTEN, "commission": 0.12, "ambassador": True},
]

# Product names by category
PRODUCT_NAMES = {
    "Clothing": [
        "Oversized Wool Blazer",
        "Slip Dress",
        "Tailored Trousers",
        "Cashmere Sweater",
        "Linen Shirt",
        "Ribbed Knit Midi Dress",
        "Cargo Pants",
        "Silk Blouse",
        "Sweatshirt",
        "Wrap Dress",
    ],
    "Bags": [
        "Le Bambino Shoulder Bag",
        "Structured Tote",
        "Crossbody Bag",
        "Clutch",
        "Bucket Bag",
        "Top Handle Bag",
        "Hobo Bag",
        "Leather Backpack",
        "Shoulder Bag",
        "Evening Bag",
    ],
    "Shoes": [
        "Leather Loafers",
        "Ballet Flats",
        "Heeled Pumps",
        "White Sneakers",
        "Ankle Boots",
        "Chelsea Boots",
        "Mules",
        "Platform Sandals",
        "Running Shoes",
        "Pointed-Toe Flats",
    ],
    "Accessories": [
        "Silk Scarf",
        "Gold Necklace",
        "Leather Belt",
        "Sunglasses",
        "Hair Clip",
        "Watch",
        "Bracelet",
        "Ring",
        "Earrings",
        "Gloves",
    ]
}

COLORS = ["Black", "White", "Beige", "Navy", "Cream", "Red", "Green", "Blue", "Gray", "Brown"]
MATERIALS = ["Leather", "Cashmere", "Wool", "Silk", "Linen", "Cotton", "Recycled Polyester", "Organic Cotton"]


async def seed_database():
    """Seed the database with realistic data."""
    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Create session factory
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Create retailers
        retailer_objs = []
        for retailer_data in RETAILERS:
            retailer = Retailer(
                id=uuid.uuid4(),
                name=retailer_data["name"],
                slug=retailer_data["slug"],
                affiliate_network=retailer_data["network"],
                affiliate_publisher_id=f"pub_{uuid.uuid4().hex[:8]}",
                commission_rate=retailer_data["commission"],
                favicon_url=retailer_data["favicon"],
                is_active=True,
            )
            session.add(retailer)
            retailer_objs.append(retailer)

        await session.flush()

        # Create brands
        brand_objs = []
        for brand_data in BRANDS:
            brand = Brand(
                id=uuid.uuid4(),
                name=brand_data["name"],
                slug=brand_data["name"].lower().replace(" ", "-"),
                tier=brand_data["tier"],
                aesthetics={"tags": brand_data["aesthetics"]},
                price_range_low=brand_data["price"][0],
                price_range_high=brand_data["price"][1],
                logo_url=f"https://via.placeholder.com/200?text={brand_data['name']}",
                website_url=f"https://{brand_data['name'].lower().replace(' ', '')}.com",
                is_active=True,
            )
            session.add(brand)
            brand_objs.append(brand)

        await session.flush()

        # Create brand candidates and discovery cards
        for i, brand_data in enumerate(BRANDS):
            brand = brand_objs[i]

            # Create brand candidate
            candidate = BrandCandidate(
                id=uuid.uuid4(),
                name=brand_data["name"],
                website=f"https://{brand_data['name'].lower().replace(' ', '')}.com",
                instagram=f"@{brand_data['name'].lower().replace(' ', '')}",
                description=f"Premium {brand_data['tier'].value} fashion brand with {', '.join(brand_data['aesthetics'])} aesthetic",
                price_range_low=brand_data["price"][0],
                price_range_high=brand_data["price"][1],
                aesthetic_tags=brand_data["aesthetics"],
                affiliate_network=brand_data["affiliate_network"],
                commission_rate=brand_data["commission"],
                has_ambassador_program=brand_data["ambassador"],
                ambassador_program_url=f"https://{brand_data['name'].lower().replace(' ', '')}.com/ambassador" if brand_data["ambassador"] else None,
                status=BrandCandidateStatus.ACTIVE,
                fit_score=75.0 + random.uniform(-10, 15),
                evaluated_at=datetime.now(timezone.utc),
                activated_at=datetime.now(timezone.utc),
            )
            session.add(candidate)

            # Create discovery card for active brands
            discovery_card = BrandDiscoveryCard(
                id=uuid.uuid4(),
                brand_id=brand.id,
                brand_name=brand.name,
                description=f"Discover {brand.name}, a {brand_data['tier'].value} brand known for {', '.join(brand_data['aesthetics'])} style",
                logo_url=brand.logo_url,
                aesthetic_tags=brand_data["aesthetics"],
                price_range_low=brand_data["price"][0],
                price_range_high=brand_data["price"][1],
                ambassador_program_url=f"https://{brand_data['name'].lower().replace(' ', '')}.com/ambassador" if brand_data["ambassador"] else None,
                has_ambassador_program=brand_data["ambassador"],
                total_views=random.randint(10, 100),
                total_likes=random.randint(2, 40),
                total_dislikes=random.randint(1, 15),
                total_skips=random.randint(5, 30),
                is_active=True,
            )
            session.add(discovery_card)

        await session.flush()

        # Create products (200+)
        product_count = 0
        for _ in range(200):
            category = random.choice(["Clothing", "Shoes", "Bags", "Accessories"])
            category_weight = {"Clothing": 0.40, "Shoes": 0.25, "Bags": 0.20, "Accessories": 0.15}

            brand = random.choice(brand_objs)
            retailer = random.choice(retailer_objs)

            product_name = random.choice(PRODUCT_NAMES[category])
            base_price = random.uniform(brand.price_range_low, brand.price_range_high)
            is_on_sale = random.random() < 0.2  # 20% on sale
            current_price = base_price * (1 - random.uniform(0.1, 0.3)) if is_on_sale else base_price

            product = Product(
                id=uuid.uuid4(),
                external_id=f"ext_{uuid.uuid4().hex[:12]}",
                retailer_id=retailer.id,
                brand_id=brand.id,
                name=f"{brand.name} {product_name}",
                description=f"Premium {category.lower()} from {brand.name}. High-quality materials and expert craftsmanship.",
                category=category,
                subcategory=random.choice(["Premium", "Seasonal", "Classic"]),
                current_price=round(current_price, 2),
                original_price=round(base_price, 2) if is_on_sale else None,
                currency="USD",
                is_on_sale=is_on_sale,
                sale_end_date=datetime.now(timezone.utc) + timedelta(days=random.randint(1, 30)) if is_on_sale else None,
                sizes_available={"sizes": ["XS", "S", "M", "L", "XL"]},
                colors={"colors": random.sample(COLORS, k=random.randint(1, 4))},
                materials={"materials": random.sample(MATERIALS, k=random.randint(1, 2))},
                image_urls=[
                    f"https://picsum.photos/400/500?random={uuid.uuid4()}",
                    f"https://picsum.photos/400/500?random={uuid.uuid4()}",
                ],
                product_url=f"https://{retailer.slug}.com/product/{uuid.uuid4().hex[:8]}",
                affiliate_url=f"https://{retailer.slug}.com/product/{uuid.uuid4().hex[:8]}?aff={retailer.affiliate_publisher_id}",
                tags={"aesthetics": brand.aesthetics.get("tags", [])},
                image_quality_score=round(random.uniform(0.6, 1.0), 2),
                is_active=True,
            )
            session.add(product)
            product_count += 1

        await session.flush()

        # Create test users
        user_objs = []
        for i in range(5):
            user = User(
                id=uuid.uuid4(),
                email=f"user{i}@example.com",
                hashed_password="hashed_test_password",
                display_name=f"Test User {i}",
                onboarding_completed=True,
                quiz_responses={"style": "minimalist", "price_preference": "luxury"},
                settings={"notifications": True, "theme": "light"},
            )
            session.add(user)
            user_objs.append(user)

        await session.flush()

        # Create dresser drawers for each user
        drawer_objs = []
        for user in user_objs:
            drawer = DresserDrawer(
                id=uuid.uuid4(),
                user_id=user.id,
                name="Favorites",
                sort_order=0,
                is_default=True,
            )
            session.add(drawer)
            drawer_objs.append(drawer)

        await session.flush()

        # Create some dresser items
        products = await session.execute(
            __import__("sqlalchemy").select(Product).limit(50)
        )
        products = products.scalars().all()

        for user, drawer in zip(user_objs, drawer_objs):
            for product in random.sample(products, k=min(5, len(products))):
                item = DresserItem(
                    id=uuid.uuid4(),
                    user_id=user.id,
                    product_id=product.id,
                    drawer_id=drawer.id,
                    price_at_save=product.current_price,
                )
                session.add(item)

        await session.flush()

        # Create some swipe events
        for user in user_objs:
            for product in random.sample(products, k=min(20, len(products))):
                action = random.choice([SwipeAction.LIKE, SwipeAction.REJECT])
                event = SwipeEvent(
                    id=uuid.uuid4(),
                    user_id=user.id,
                    product_id=product.id,
                    action=action,
                    dwell_time_ms=random.randint(500, 5000),
                    session_position=random.randint(1, 50),
                    expanded=random.random() < 0.3,
                    session_id=f"session_{uuid.uuid4().hex[:8]}",
                )
                session.add(event)

        await session.commit()

        print(f"✓ Created {len(RETAILERS)} retailers")
        print(f"✓ Created {len(BRANDS)} brands")
        print(f"✓ Created {product_count} products")
        print(f"✓ Created {len(user_objs)} test users")
        print("✓ Seed data created successfully!")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(seed_database())
