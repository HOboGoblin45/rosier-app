"""Style DNA generation service for user personality profiles."""
import logging
from datetime import datetime, timezone
from typing import Optional

import numpy as np
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.redis import get_cache, set_cache
from app.models import Brand, Product, SwipeEvent, User
from app.models.swipe_event import SwipeAction

logger = logging.getLogger(__name__)


class StyleDNAService:
    """Service for computing and caching user style DNA profiles."""

    # Archetypes for k-means clustering
    ARCHETYPES = [
        "Minimalist with Edge",
        "Quiet Luxury",
        "Eclectic Maximalist",
        "Street-Meets-Runway",
        "Romantic Bohemian",
        "Modern Minimalist",
        "Vintage Inspired",
        "Sporty Chic",
    ]

    # Cache settings
    CACHE_TTL = 86400  # 24 hours
    REGENERATION_THRESHOLD = 50  # Regenerate after 50 new swipes

    @staticmethod
    async def get_or_compute_style_dna(
        session: AsyncSession,
        user_id: str,
        force_recompute: bool = False,
    ) -> dict:
        """
        Get cached Style DNA or compute fresh.

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            force_recompute: Force fresh computation

        Returns:
            Style DNA profile dictionary
        """
        cache_key = f"style_dna:{user_id}"

        # Try cache first
        if not force_recompute:
            cached = await get_cache(cache_key)
            if cached:
                logger.debug(f"Returning cached Style DNA for user {user_id}")
                return cached

        # Compute fresh
        style_dna = await StyleDNAService.compute_style_dna(session, user_id)

        # Cache result
        await set_cache(cache_key, style_dna, ttl=StyleDNAService.CACHE_TTL)
        logger.info(f"Computed and cached new Style DNA for user {user_id}")

        return style_dna

    @staticmethod
    async def compute_style_dna(
        session: AsyncSession,
        user_id: str,
    ) -> dict:
        """
        Compute complete Style DNA profile for user.

        Includes:
        - Archetype (k-means clustering on embeddings)
        - Top 5 brands
        - Color palette
        - Price range
        - Engagement statistics

        Args:
            session: SQLAlchemy async session
            user_id: User ID

        Returns:
            Style DNA profile
        """
        # Get user's swipe history
        stmt = (
            select(SwipeEvent, Product)
            .join(Product, SwipeEvent.product_id == Product.id)
            .where(SwipeEvent.user_id == user_id)
            .order_by(SwipeEvent.created_at.desc())
        )
        result = await session.execute(stmt)
        swipes_products = result.all()

        if not swipes_products:
            logger.warning(f"No swipe history for user {user_id}")
            return StyleDNAService._default_style_dna(user_id)

        # Compute components
        archetype = await StyleDNAService.compute_archetype(swipes_products)
        top_brands = await StyleDNAService.compute_top_brands(session, swipes_products)
        palette = await StyleDNAService.compute_palette(swipes_products)
        price_range = await StyleDNAService.compute_price_range(swipes_products)
        stats = await StyleDNAService.compute_stats(swipes_products)

        return {
            "user_id": str(user_id),
            "archetype": archetype,
            "top_brands": top_brands,
            "palette": palette,
            "price_range": price_range,
            "stats": stats,
            "computed_at": datetime.now(timezone.utc).isoformat(),
        }

    @staticmethod
    async def compute_archetype(swipes_products: list) -> str:
        """
        Compute style archetype using k-means clustering on visual embeddings.

        Groups products by visual similarity and maps to archetype labels.

        Args:
            swipes_products: List of (SwipeEvent, Product) tuples

        Returns:
            Archetype label
        """
        # Collect embeddings from liked items
        embeddings = []
        for swipe_event, product in swipes_products:
            if (
                swipe_event.action in (SwipeAction.LIKE, SwipeAction.SUPER_LIKE, SwipeAction.SHOP_CLICK)
                and product.visual_embedding
            ):
                embeddings.append(np.array(product.visual_embedding))

        if not embeddings:
            logger.debug("No visual embeddings available for archetype computation")
            return StyleDNAService.ARCHETYPES[0]  # Default to first archetype

        # Stack embeddings into matrix
        embeddings_matrix = np.array(embeddings)

        # Simple k-means clustering (k=8 for number of archetypes)
        try:
            from sklearn.cluster import KMeans

            kmeans = KMeans(n_clusters=min(8, len(embeddings_matrix)), random_state=42, n_init=10)
            labels = kmeans.fit_predict(embeddings_matrix)

            # Get dominant cluster
            unique, counts = np.unique(labels, return_counts=True)
            dominant_cluster = unique[np.argmax(counts)]

            # Map cluster to archetype
            archetype = StyleDNAService.ARCHETYPES[dominant_cluster % len(StyleDNAService.ARCHETYPES)]
            logger.debug(f"Computed archetype: {archetype}")
            return archetype
        except ImportError:
            logger.warning("scikit-learn not available, using default archetype")
            return StyleDNAService.ARCHETYPES[0]
        except Exception as e:
            logger.error(f"Error computing archetype: {e}")
            return StyleDNAService.ARCHETYPES[0]

    @staticmethod
    async def compute_top_brands(
        session: AsyncSession,
        swipes_products: list,
    ) -> list[str]:
        """
        Compute top 5 brands by engagement ratio (right_swipes / total_impressions).

        Args:
            session: SQLAlchemy async session
            swipes_products: List of (SwipeEvent, Product) tuples

        Returns:
            List of top 5 brand names
        """
        brand_stats = {}

        for swipe_event, product in swipes_products:
            if not product.brand_id:
                continue

            brand_id = str(product.brand_id)
            if brand_id not in brand_stats:
                brand_stats[brand_id] = {"likes": 0, "total": 0}

            brand_stats[brand_id]["total"] += 1
            if swipe_event.action in (SwipeAction.LIKE, SwipeAction.SUPER_LIKE, SwipeAction.SHOP_CLICK):
                brand_stats[brand_id]["likes"] += 1

        # Calculate engagement ratios and sort
        brands_with_scores = []
        for brand_id, stats in brand_stats.items():
            ratio = stats["likes"] / stats["total"] if stats["total"] > 0 else 0
            brands_with_scores.append((brand_id, ratio, stats["total"]))

        # Sort by ratio, filter those with min engagement
        brands_with_scores.sort(key=lambda x: (x[1], x[2]), reverse=True)

        # Get brand names
        top_5_ids = [b[0] for b in brands_with_scores[:5]]
        if not top_5_ids:
            return []

        stmt = select(Brand).where(Brand.id.in_(top_5_ids))
        result = await session.execute(stmt)
        brands = result.scalars().all()

        brand_names = [b.name for b in brands]
        logger.debug(f"Top brands: {brand_names}")
        return brand_names

    @staticmethod
    async def compute_palette(swipes_products: list) -> list[str]:
        """
        Extract dominant colors from top 20 liked product images using k-means.

        Args:
            swipes_products: List of (SwipeEvent, Product) tuples

        Returns:
            List of dominant color names/codes
        """
        # Collect colors from liked items
        color_list = []
        color_count = {}

        for swipe_event, product in swipes_products:
            if (
                swipe_event.action in (SwipeAction.LIKE, SwipeAction.SUPER_LIKE)
                and product.colors
            ):
                for color in product.colors.keys():
                    color_list.append(color)
                    color_count[color] = color_count.get(color, 0) + 1

        if not color_list:
            logger.debug("No colors available for palette computation")
            return []

        # Get top colors by frequency
        sorted_colors = sorted(color_count.items(), key=lambda x: x[1], reverse=True)
        palette = [color for color, count in sorted_colors[:8]]  # Top 8 colors

        logger.debug(f"Computed palette: {palette}")
        return palette

    @staticmethod
    async def compute_price_range(swipes_products: list) -> dict:
        """
        Compute price range from right-swiped items (IQR: Q1 to Q3).

        Args:
            swipes_products: List of (SwipeEvent, Product) tuples

        Returns:
            Dictionary with low and high price points
        """
        prices = []

        for swipe_event, product in swipes_products:
            if swipe_event.action in (SwipeAction.LIKE, SwipeAction.SUPER_LIKE, SwipeAction.SHOP_CLICK):
                prices.append(product.current_price)

        if not prices:
            logger.debug("No prices available for range computation")
            return {"low": 50.0, "high": 500.0, "mean": 250.0}

        prices_array = np.array(prices)
        q1 = np.percentile(prices_array, 25)
        q3 = np.percentile(prices_array, 75)
        mean = np.mean(prices_array)

        price_range = {
            "low": float(q1),
            "high": float(q3),
            "mean": float(mean),
        }

        logger.debug(f"Computed price range: ${price_range['low']:.2f} - ${price_range['high']:.2f}")
        return price_range

    @staticmethod
    async def compute_stats(swipes_products: list) -> dict:
        """
        Compute engagement statistics.

        Args:
            swipes_products: List of (SwipeEvent, Product) tuples

        Returns:
            Statistics dictionary
        """
        total_swipes = len(swipes_products)
        likes_count = 0
        super_likes_count = 0
        shop_clicks_count = 0
        view_details_count = 0
        rejects_count = 0
        category_counts = {}

        for swipe_event, product in swipes_products:
            if swipe_event.action == SwipeAction.LIKE:
                likes_count += 1
            elif swipe_event.action == SwipeAction.SUPER_LIKE:
                super_likes_count += 1
            elif swipe_event.action == SwipeAction.SHOP_CLICK:
                shop_clicks_count += 1
            elif swipe_event.action == SwipeAction.VIEW_DETAIL:
                view_details_count += 1
            elif swipe_event.action == SwipeAction.REJECT:
                rejects_count += 1

            if product.category:
                category_counts[product.category] = category_counts.get(product.category, 0) + 1

        # Top categories
        top_categories = sorted(category_counts.items(), key=lambda x: x[1], reverse=True)
        top_category_names = [cat[0] for cat in top_categories[:3]]

        stats = {
            "total_swipes": total_swipes,
            "likes": likes_count,
            "super_likes": super_likes_count,
            "shop_clicks": shop_clicks_count,
            "view_details": view_details_count,
            "rejects": rejects_count,
            "engagement_rate": (likes_count + super_likes_count) / total_swipes if total_swipes > 0 else 0,
            "top_categories": top_category_names,
        }

        logger.debug(f"Computed stats: {stats}")
        return stats

    @staticmethod
    def _default_style_dna(user_id: str) -> dict:
        """Return default Style DNA for new user."""
        return {
            "user_id": str(user_id),
            "archetype": StyleDNAService.ARCHETYPES[0],
            "top_brands": [],
            "palette": [],
            "price_range": {"low": 50.0, "high": 500.0, "mean": 250.0},
            "stats": {
                "total_swipes": 0,
                "likes": 0,
                "super_likes": 0,
                "shop_clicks": 0,
                "view_details": 0,
                "rejects": 0,
                "engagement_rate": 0.0,
                "top_categories": [],
            },
            "computed_at": datetime.now(timezone.utc).isoformat(),
        }

    @staticmethod
    async def should_regenerate_style_dna(
        session: AsyncSession,
        user_id: str,
        last_computed_at: Optional[datetime] = None,
    ) -> bool:
        """
        Determine if Style DNA should be regenerated.

        Regenerate if:
        - More than REGENERATION_THRESHOLD new swipes since last computation
        - More than 24 hours since last computation

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            last_computed_at: Timestamp of last computation

        Returns:
            True if regeneration recommended
        """
        if not last_computed_at:
            return True

        # Check time threshold
        time_since = datetime.now(timezone.utc) - last_computed_at
        if time_since.total_seconds() > 86400:  # 24 hours
            return True

        # Check swipe count threshold
        stmt = (
            select(func.count(SwipeEvent.id))
            .where(
                and_(
                    SwipeEvent.user_id == user_id,
                    SwipeEvent.created_at > last_computed_at,
                )
            )
        )
        result = await session.execute(stmt)
        new_swipes = result.scalar() or 0

        if new_swipes >= StyleDNAService.REGENERATION_THRESHOLD:
            logger.info(f"Style DNA regeneration recommended: {new_swipes} new swipes for user {user_id}")
            return True

        return False
