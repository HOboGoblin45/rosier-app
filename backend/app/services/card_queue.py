"""Card queue generation and management service."""

import logging
import random
from typing import Optional

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.redis import get_card_queue, set_card_queue, delete_cache
from app.models import Product, SwipeEvent, BrandDiscoveryCard
from app.services.recommendation import RecommendationService, UserPreferences

logger = logging.getLogger(__name__)


class CardQueueService:
    """Service for managing card queues and generating personalized card feeds."""

    QUEUE_TTL = 3600  # 1 hour
    QUEUE_SIZE = 100
    MAX_SAME_BRAND_PER_20 = 2
    BRAND_WINDOW = 20
    MAX_SAME_RETAILER = 3
    BRAND_DISCOVERY_POSITION = 25  # Insert brand discovery card every 25th position

    # Queue composition
    EXPLOITATION_RATE = 0.85  # 85% ranked by model
    EXPLORATION_RATE = 0.10  # 10% exploration (underexplored areas)
    TRENDING_RATE = 0.05  # 5% trending products

    @staticmethod
    async def invalidate_queue(user_id: str) -> None:
        """Invalidate cached queue for user."""
        queue_key = f"card_queue:{user_id}"
        await delete_cache(queue_key)
        logger.info(f"Invalidated queue for user {user_id}")

    @staticmethod
    async def get_viewed_product_ids(
        session: AsyncSession,
        user_id: str,
    ) -> set[str]:
        """
        Get set of product IDs already viewed by user.

        Args:
            session: SQLAlchemy async session
            user_id: User ID

        Returns:
            Set of viewed product IDs
        """
        stmt = select(SwipeEvent.product_id).where(SwipeEvent.user_id == user_id)
        result = await session.execute(stmt)
        product_ids = result.scalars().all()
        return {str(pid) for pid in product_ids}

    @staticmethod
    async def get_eligible_products(
        session: AsyncSession,
        user_prefs: UserPreferences,
        viewed_product_ids: set[str],
        limit: int = 500,
    ) -> list[Product]:
        """
        Get all active products matching user's price range and not previously viewed.

        Args:
            session: SQLAlchemy async session
            user_prefs: User preferences
            viewed_product_ids: Set of viewed product IDs
            limit: Maximum products to fetch

        Returns:
            List of eligible Product objects
        """
        stmt = (
            select(Product)
            .where(
                and_(
                    Product.is_active is True,
                    Product.current_price >= user_prefs.price_range_low,
                    Product.current_price <= user_prefs.price_range_high,
                    Product.id.not_in(viewed_product_ids)
                    if viewed_product_ids
                    else True,
                )
            )
            .order_by(Product.created_at.desc())
            .limit(limit)
        )
        result = await session.execute(stmt)
        return result.scalars().all()

    @staticmethod
    async def get_trending_products(
        session: AsyncSession,
        limit: int = 20,
    ) -> list[Product]:
        """
        Get trending products based on recent swipes and engagement.

        Args:
            session: SQLAlchemy async session
            limit: Maximum products to return

        Returns:
            List of trending Product objects
        """
        # Products with most likes in last 7 days
        stmt = (
            select(Product, func.count(SwipeEvent.id).label("like_count"))
            .join(SwipeEvent, Product.id == SwipeEvent.product_id)
            .where(
                and_(
                    Product.is_active is True,
                    SwipeEvent.action.in_(["like", "super_like"]),
                )
            )
            .group_by(Product.id)
            .order_by(func.count(SwipeEvent.id).desc())
            .limit(limit)
        )
        result = await session.execute(stmt)
        products = [row[0] for row in result.all()]
        return products

    @staticmethod
    async def score_product(
        product: Product,
        user_prefs: UserPreferences,
        taste_embedding: Optional[list] = None,
        viewed_product_ids: Optional[set[str]] = None,
    ) -> float:
        """
        Score a product using Phase 1 + Phase 2 hybrid scoring.

        Args:
            product: Product to score
            user_prefs: User preferences
            taste_embedding: User's taste embedding for Phase 2 scoring
            viewed_product_ids: Set of already viewed product IDs

        Returns:
            Score between 0 and 1
        """
        if viewed_product_ids and str(product.id) in viewed_product_ids:
            return 0.0

        # Convert taste embedding list back to numpy if needed
        taste_emb_array = None
        if taste_embedding:
            import numpy as np

            taste_emb_array = np.array(taste_embedding)

        # Use hybrid scoring
        score = await RecommendationService.score_product_hybrid(
            product, user_prefs, taste_emb_array, viewed_product_ids
        )

        return score

    @staticmethod
    async def apply_diversity_rules(
        queue: list[dict],
        max_queue_size: int = QUEUE_SIZE,
    ) -> list[dict]:
        """
        Apply diversity rules to ensure varied queue composition.

        Rules:
        - Max 2 from same brand per 20 cards
        - Max 3 from same retailer across entire queue
        - Mix of categories

        Args:
            queue: Preliminary queue with scored products
            max_queue_size: Maximum queue size

        Returns:
            Diversified queue
        """
        diverse_queue = []
        retailer_counts = {}
        category_counts = {}

        for card in queue:
            if len(diverse_queue) >= max_queue_size:
                break

            brand_id = card.get("brand_id")
            retailer_id = card.get("retailer_id")
            category = card.get("category")

            # Check brand diversity: max 2 per 20 cards
            if len(diverse_queue) >= CardQueueService.BRAND_WINDOW:
                recent_20 = diverse_queue[-CardQueueService.BRAND_WINDOW :]
                brand_count_recent = sum(
                    1 for c in recent_20 if c.get("brand_id") == brand_id
                )
                if brand_count_recent >= CardQueueService.MAX_SAME_BRAND_PER_20:
                    continue

            # Check retailer diversity: max 3 total
            retailer_count = retailer_counts.get(retailer_id, 0)
            if retailer_count >= CardQueueService.MAX_SAME_RETAILER:
                continue

            # Add card to queue
            diverse_queue.append(card)

            # Update counts
            retailer_counts[retailer_id] = retailer_counts.get(retailer_id, 0) + 1
            if category:
                category_counts[category] = category_counts.get(category, 0) + 1

        return diverse_queue

    @staticmethod
    async def generate_queue(
        session: AsyncSession,
        user_id: str,
        user_preferences: Optional[UserPreferences] = None,
        viewed_product_ids: Optional[set[str]] = None,
        taste_embedding: Optional[list] = None,
        queue_size: int = QUEUE_SIZE,
    ) -> list[dict]:
        """
        Generate a diverse, personalized card queue for the user.

        Composition:
        - 85% exploitation: products ranked by hybrid scoring model
        - 10% exploration: random from underexplored categories
        - 5% trending: popular products from recent engagement

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            user_preferences: User preference profile (builds if not provided)
            viewed_product_ids: Set of already viewed product IDs
            taste_embedding: User's visual embedding
            queue_size: Desired queue size

        Returns:
            List of product card dictionaries
        """
        if not viewed_product_ids:
            viewed_product_ids = await CardQueueService.get_viewed_product_ids(
                session, user_id
            )

        if not user_preferences:
            user_preferences = await RecommendationService.build_user_preferences(
                session, user_id
            )

        # Build queue components
        exploitation_cards = []
        exploration_cards = []
        trending_cards = []

        # Get eligible products
        eligible_products = await CardQueueService.get_eligible_products(
            session, user_preferences, viewed_product_ids, limit=500
        )

        if not eligible_products:
            logger.warning(f"No eligible products found for user {user_id}")
            return []

        # Score all products for exploitation
        scored_products = []
        for product in eligible_products:
            score = await CardQueueService.score_product(
                product, user_preferences, taste_embedding, viewed_product_ids
            )
            if score > 0:
                scored_products.append((product, score))

        # Sort by score descending
        scored_products.sort(key=lambda x: x[1], reverse=True)

        # Exploitation: top-ranked products (85% of queue)
        exploitation_target = int(queue_size * CardQueueService.EXPLOITATION_RATE)
        for product, score in scored_products[:exploitation_target]:
            card = CardQueueService._product_to_card(product, score)
            exploitation_cards.append(card)

        # Exploration: random selection from medium-scored products (10% of queue)
        exploration_target = int(queue_size * CardQueueService.EXPLORATION_RATE)
        if len(scored_products) > exploitation_target:
            exploration_candidates = scored_products[
                exploitation_target : exploitation_target * 2
            ]
            random_sample = random.sample(
                exploration_candidates,
                min(exploration_target, len(exploration_candidates)),
            )
            for product, score in random_sample:
                card = CardQueueService._product_to_card(product, score)
                exploration_cards.append(card)

        # Trending: popular products (5% of queue)
        trending_target = int(queue_size * CardQueueService.TRENDING_RATE)
        trending_products = await CardQueueService.get_trending_products(
            session, limit=trending_target * 2
        )
        trending_sample = random.sample(
            trending_products,
            min(trending_target, len(trending_products)),
        )
        for product in trending_sample:
            score = await CardQueueService.score_product(
                product, user_preferences, taste_embedding, viewed_product_ids
            )
            if score > 0:
                card = CardQueueService._product_to_card(product, score)
                trending_cards.append(card)

        # Combine and shuffle components slightly for natural feel
        combined = exploitation_cards + exploration_cards + trending_cards

        # Apply diversity rules
        diverse_queue = await CardQueueService.apply_diversity_rules(
            combined, max_queue_size=queue_size
        )

        logger.info(
            f"Generated queue for user {user_id}: {len(diverse_queue)} cards "
            f"(exploitation={len(exploitation_cards)}, exploration={len(exploration_cards)}, trending={len(trending_cards)})"
        )

        return diverse_queue[:queue_size]

    @staticmethod
    def _product_to_card(product: Product, score: float) -> dict:
        """Convert Product model to card dictionary."""
        return {
            "type": "product",
            "product_id": str(product.id),
            "name": product.name,
            "current_price": float(product.current_price),
            "original_price": float(product.original_price)
            if product.original_price
            else None,
            "is_on_sale": product.is_on_sale,
            "image_urls": product.image_urls or [],
            "category": product.category,
            "subcategory": product.subcategory,
            "brand_id": str(product.brand_id) if product.brand_id else None,
            "retailer_id": str(product.retailer_id),
            "score": float(score),
        }

    @staticmethod
    def _brand_discovery_card_to_dict(card: BrandDiscoveryCard) -> dict:
        """Convert BrandDiscoveryCard model to card dictionary."""
        return {
            "type": "brand_discovery",
            "card_id": str(card.id),
            "brand_id": str(card.brand_id),
            "brand_name": card.brand_name,
            "description": card.description,
            "logo_url": card.logo_url,
            "aesthetic_tags": card.aesthetic_tags or [],
            "price_range": {
                "low": card.price_range_low,
                "high": card.price_range_high,
            },
            "ambassador_program_url": card.ambassador_program_url,
            "has_ambassador_program": card.has_ambassador_program,
        }

    @staticmethod
    async def get_random_brand_discovery_card(
        session: AsyncSession,
    ) -> Optional[BrandDiscoveryCard]:
        """
        Get a random active brand discovery card.

        Args:
            session: SQLAlchemy async session

        Returns:
            BrandDiscoveryCard or None if none available
        """
        stmt = (
            select(BrandDiscoveryCard)
            .where(BrandDiscoveryCard.is_active is True)
            .order_by(func.random())
            .limit(1)
        )
        result = await session.execute(stmt)
        return result.scalar_one_or_none()

    @staticmethod
    async def inject_brand_discovery_cards(
        session: AsyncSession,
        queue: list[dict],
        position_step: int = 25,
    ) -> list[dict]:
        """
        Inject brand discovery cards into queue at specified positions.

        Inserts a brand discovery card at positions 25, 50, 75, etc.

        Args:
            session: SQLAlchemy async session
            queue: Product card queue
            position_step: Position interval (default every 25th card)

        Returns:
            Queue with brand discovery cards injected
        """
        if not queue:
            return queue

        # Collect brand cards to inject
        brand_cards = []
        for i in range(0, len(queue), position_step):
            if i > 0 and i < len(queue):  # Don't inject at position 0
                card = await CardQueueService.get_random_brand_discovery_card(session)
                if card:
                    brand_cards.append(
                        (i, CardQueueService._brand_discovery_card_to_dict(card))
                    )

        # Inject cards in reverse order to maintain indices
        for index, brand_card in reversed(brand_cards):
            queue.insert(index, brand_card)

        logger.info(
            f"Injected {len(brand_cards)} brand discovery cards into queue of size {len(queue)}"
        )

        return queue

    @staticmethod
    async def get_or_generate_queue(
        session: AsyncSession,
        user_id: str,
        user_preferences: Optional[UserPreferences] = None,
        viewed_product_ids: Optional[set[str]] = None,
        taste_embedding: Optional[list] = None,
        force_regenerate: bool = False,
    ) -> list[dict]:
        """
        Get cached queue or generate a new one.

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            user_preferences: User preference profile
            viewed_product_ids: Set of already viewed product IDs
            taste_embedding: User's taste embedding
            force_regenerate: Force queue regeneration

        Returns:
            Queue of product and brand discovery cards
        """
        # Try to get from cache
        if not force_regenerate:
            cached_queue = await get_card_queue(user_id)
            if cached_queue and len(cached_queue) > 0:
                logger.debug(
                    f"Returning cached queue for user {user_id}: {len(cached_queue)} cards"
                )
                return cached_queue

        # Generate new queue
        queue = await CardQueueService.generate_queue(
            session,
            user_id,
            user_preferences=user_preferences,
            viewed_product_ids=viewed_product_ids,
            taste_embedding=taste_embedding,
            queue_size=CardQueueService.QUEUE_SIZE,
        )

        if not queue:
            logger.warning(
                f"Generated empty queue for user {user_id}, returning discovery picks"
            )
            # Return some discovery cards if generation fails
            stmt = select(Product).where(Product.is_active is True).limit(20)
            result = await session.execute(stmt)
            fallback_products = result.scalars().all()
            queue = [
                CardQueueService._product_to_card(p, 0.5) for p in fallback_products
            ]

        # Inject brand discovery cards at regular intervals
        queue = await CardQueueService.inject_brand_discovery_cards(
            session,
            queue,
            position_step=CardQueueService.BRAND_DISCOVERY_POSITION,
        )

        # Cache the queue
        await set_card_queue(user_id, queue, ttl=CardQueueService.QUEUE_TTL)
        logger.info(
            f"Generated and cached new queue for user {user_id}: {len(queue)} cards"
        )

        return queue
