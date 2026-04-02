"""Recommendation service for personalized suggestions with Phase 1 and Phase 2 scoring."""

import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional

import numpy as np
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Product, SwipeEvent, SwipeAction, Brand

logger = logging.getLogger(__name__)


@dataclass
class UserPreferences:
    """User preference profile for recommendations."""

    preferred_categories: list[str]
    preferred_subcategories: list[str]
    preferred_tags: dict[str, float]
    price_point: float
    price_range_low: float
    price_range_high: float
    brand_affinity: dict[str, float]
    aesthetic_preferences: dict[str, float]
    color_palette: list[str]
    average_rating: float
    view_detail_rate: float
    super_like_rate: float


class RecommendationService:
    """Service for generating recommendations using Phase 1 (tag-based) + Phase 2 (visual embedding) hybrid scoring."""

    # Phase 1 scoring weights (tag-based)
    CATEGORY_MATCH_WEIGHT = 2.0
    PRICE_RANGE_WEIGHT = 1.5
    BRAND_AFFINITY_WEIGHT = 2.0
    AESTHETIC_MATCH_WEIGHT = 1.0
    COLOR_PALETTE_WEIGHT = 0.5
    POPULARITY_BOOST_WEIGHT = 0.5

    # Phase 2 scoring
    PHASE1_WEIGHT = 0.60
    PHASE2_WEIGHT = 0.40

    # Taste embedding weights for different swipe actions
    EMBEDDING_WEIGHTS = {
        SwipeAction.SHOP_CLICK: 4.0,
        SwipeAction.SUPER_LIKE: 3.0,
        SwipeAction.LIKE: 1.0,
        SwipeAction.VIEW_DETAIL: 0.5,
        SwipeAction.REJECT: -0.5,
    }

    # Time decay for embedding computation (half-life of ~23 days)
    TIME_DECAY_RATE = 0.03

    @staticmethod
    async def score_product_phase1(
        product: Product,
        user_prefs: UserPreferences,
        viewed_product_ids: Optional[set[str]] = None,
    ) -> float:
        """
        Phase 1 tag-based + popularity scoring.

        Scores based on: category match, price range, brand affinity, aesthetic match,
        color palette, and global popularity.

        Args:
            product: Product to score
            user_prefs: User preference profile
            viewed_product_ids: Set of product IDs already viewed

        Returns:
            Score between 0 and 10 (10 = perfect match)
        """
        if viewed_product_ids and str(product.id) in viewed_product_ids:
            return 0.0

        score = 0.0

        # Category match (0-2.0)
        if product.category in user_prefs.preferred_categories:
            score += RecommendationService.CATEGORY_MATCH_WEIGHT

        # Subcategory match (0-1.0)
        if product.subcategory in user_prefs.preferred_subcategories:
            score += 1.0

        # Price range match (0-1.5)
        if (
            user_prefs.price_range_low
            <= product.current_price
            <= user_prefs.price_range_high
        ):
            price_ratio = product.current_price / user_prefs.price_point
            if 0.7 <= price_ratio <= 1.3:
                score += RecommendationService.PRICE_RANGE_WEIGHT
            else:
                # Penalize slightly if outside comfortable range
                score += max(
                    0,
                    RecommendationService.PRICE_RANGE_WEIGHT
                    * (1.0 - abs(price_ratio - 1.0)),
                )

        # Brand affinity (0-2.0)
        if product.brand_id and str(product.brand_id) in user_prefs.brand_affinity:
            brand_score = user_prefs.brand_affinity.get(str(product.brand_id), 0.0)
            score += min(RecommendationService.BRAND_AFFINITY_WEIGHT, brand_score)

        # Aesthetic match via tags (0-1.0)
        if product.tags:
            tag_matches = sum(
                user_prefs.preferred_tags.get(tag, 0) for tag in product.tags.keys()
            )
            aesthetic_score = min(
                RecommendationService.AESTHETIC_MATCH_WEIGHT, tag_matches / 10.0
            )
            score += aesthetic_score

        # Color palette match (0-0.5)
        if product.colors and user_prefs.color_palette:
            product_colors = (
                product.colors.keys() if isinstance(product.colors, dict) else []
            )
            color_matches = sum(
                1 for c in product_colors if c in user_prefs.color_palette
            )
            color_score = min(
                RecommendationService.COLOR_PALETTE_WEIGHT, color_matches / 5.0
            )
            score += color_score

        # Popularity boost (0-0.5)
        if product.image_quality_score:
            popularity = min(1.0, product.image_quality_score)
            score += RecommendationService.POPULARITY_BOOST_WEIGHT * popularity

        return score

    @staticmethod
    async def compute_taste_embedding(
        session: AsyncSession,
        user_id: str,
        embedding_dim: int = 384,
    ) -> Optional[np.ndarray]:
        """
        Compute weighted taste embedding from user's swipe history.

        Combines visual embeddings from liked products with exponential time decay.
        - SHOP_CLICK: 4.0x weight
        - SUPER_LIKE: 3.0x weight
        - LIKE: 1.0x weight
        - VIEW_DETAIL: 0.5x weight
        - REJECT: -0.5x weight

        Time decay: exp(-0.03 * days_ago), half-life ~23 days

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            embedding_dim: Dimension of visual embeddings (default 384 for ViT)

        Returns:
            L2-normalized embedding vector or None if no embeddings available
        """
        # Fetch user's swipe events with product embeddings
        stmt = (
            select(SwipeEvent, Product.visual_embedding)
            .join(Product, SwipeEvent.product_id == Product.id)
            .where(
                and_(
                    SwipeEvent.user_id == user_id,
                    Product.visual_embedding.isnot(None),
                )
            )
            .order_by(SwipeEvent.created_at.desc())
        )
        result = await session.execute(stmt)
        swipes_with_embeddings = result.all()

        if not swipes_with_embeddings:
            return None

        embedding_sum = np.zeros(embedding_dim)
        total_weight = 0.0
        now = datetime.now(timezone.utc)

        for swipe_event, embedding_list in swipes_with_embeddings:
            if not embedding_list:
                continue

            # Get weight for this swipe action
            action_weight = RecommendationService.EMBEDDING_WEIGHTS.get(
                swipe_event.action, 0.0
            )

            # Apply time decay
            days_ago = (now - swipe_event.created_at).days
            time_decay = np.exp(-RecommendationService.TIME_DECAY_RATE * days_ago)

            # Combine weights
            combined_weight = action_weight * time_decay

            # Add to weighted sum
            embedding_array = np.array(embedding_list)
            embedding_sum += embedding_array * combined_weight
            total_weight += combined_weight

        # Normalize
        if total_weight > 0:
            embedding_sum /= total_weight

            # L2 normalize
            norm = np.linalg.norm(embedding_sum)
            if norm > 0:
                embedding_sum /= norm

            return embedding_sum

        return None

    @staticmethod
    def _cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
        """Calculate cosine similarity between two vectors."""
        if vec1 is None or vec2 is None:
            return 0.0

        dot_product = np.dot(vec1, vec2)
        return float(dot_product)

    @staticmethod
    async def score_product_phase2(
        product: Product,
        taste_embedding: Optional[np.ndarray],
    ) -> float:
        """
        Phase 2 visual embedding similarity scoring.

        Computes cosine similarity between product's visual embedding
        and user's taste embedding.

        Args:
            product: Product to score
            taste_embedding: User's computed taste embedding

        Returns:
            Similarity score between 0 and 1
        """
        if not taste_embedding or not product.visual_embedding:
            return 0.0

        product_embedding = np.array(product.visual_embedding)
        norm = np.linalg.norm(product_embedding)
        if norm > 0:
            product_embedding /= norm

        return RecommendationService._cosine_similarity(
            product_embedding, taste_embedding
        )

    @staticmethod
    async def score_product_hybrid(
        product: Product,
        user_prefs: UserPreferences,
        taste_embedding: Optional[np.ndarray],
        viewed_product_ids: Optional[set[str]] = None,
    ) -> float:
        """
        Combined Phase 1 + Phase 2 hybrid scoring.

        Final score = 0.60 * phase1_score + 0.40 * phase2_score

        Args:
            product: Product to score
            user_prefs: User preferences
            taste_embedding: User's taste embedding
            viewed_product_ids: Products already viewed

        Returns:
            Normalized score between 0 and 1
        """
        phase1_score = await RecommendationService.score_product_phase1(
            product, user_prefs, viewed_product_ids
        )

        # Normalize Phase 1 to 0-1 range (max is ~10)
        phase1_normalized = min(1.0, phase1_score / 10.0)

        phase2_score = await RecommendationService.score_product_phase2(
            product, taste_embedding
        )

        # Combine with weights
        hybrid_score = (
            RecommendationService.PHASE1_WEIGHT * phase1_normalized
            + RecommendationService.PHASE2_WEIGHT * phase2_score
        )

        return min(1.0, hybrid_score)

    @staticmethod
    async def get_similar_products(
        session: AsyncSession,
        product_id: str,
        limit: int = 4,
        exclude_product_ids: Optional[list[str]] = None,
    ) -> list[dict]:
        """
        Get similar products based on tags, category, and visual embeddings.

        Args:
            session: SQLAlchemy async session
            product_id: Product ID to find similar products for
            limit: Maximum number of products to return
            exclude_product_ids: Product IDs to exclude from results

        Returns:
            List of similar products with similarity scores
        """
        if not exclude_product_ids:
            exclude_product_ids = []

        # Get the base product
        stmt = select(Product).where(Product.id == product_id)
        result = await session.execute(stmt)
        base_product = result.scalar_one_or_none()

        if not base_product:
            return []

        # Find products in same category/subcategory
        stmt = select(Product).where(
            and_(
                Product.is_active is True,
                Product.id != product_id,
                Product.id.not_in(exclude_product_ids) if exclude_product_ids else True,
                Product.category == base_product.category,
            )
        )
        result = await session.execute(stmt)
        candidates = result.scalars().all()

        # Score and sort by similarity
        scored = []
        base_tags = base_product.tags or {}
        base_embedding = None

        if base_product.visual_embedding:
            base_embedding = np.array(base_product.visual_embedding)
            norm = np.linalg.norm(base_embedding)
            if norm > 0:
                base_embedding /= norm

        for product in candidates:
            # Tag-based similarity
            tag_similarity = RecommendationService._calculate_tag_similarity(
                base_tags, product.tags or {}
            )

            # Visual embedding similarity
            visual_similarity = 0.0
            if base_embedding and product.visual_embedding:
                visual_similarity = RecommendationService._cosine_similarity(
                    base_embedding, np.array(product.visual_embedding)
                )

            # Combine similarities
            combined_similarity = 0.4 * tag_similarity + 0.6 * visual_similarity

            scored.append(
                {
                    "id": str(product.id),
                    "name": product.name,
                    "current_price": float(product.current_price),
                    "image_urls": product.image_urls or [],
                    "similarity_score": combined_similarity,
                }
            )

        # Sort by similarity and return top N
        scored.sort(key=lambda x: x["similarity_score"], reverse=True)
        return scored[:limit]

    @staticmethod
    def _calculate_tag_similarity(tags_a: dict, tags_b: dict) -> float:
        """
        Calculate similarity between two tag dictionaries using Jaccard coefficient.

        Args:
            tags_a: First tag dictionary
            tags_b: Second tag dictionary

        Returns:
            Similarity score 0-1
        """
        if not tags_a or not tags_b:
            return 0.0

        keys_a = set(tags_a.keys())
        keys_b = set(tags_b.keys())

        if not keys_a or not keys_b:
            return 0.0

        intersection = len(keys_a & keys_b)
        union = len(keys_a | keys_b)

        if union == 0:
            return 0.0

        return intersection / union

    @staticmethod
    async def build_user_preferences(
        session: AsyncSession,
        user_id: str,
        limit: int = 100,
    ) -> UserPreferences:
        """
        Build complete UserPreferences profile from user's swipe history.

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            limit: Number of recent swipes to analyze

        Returns:
            UserPreferences dataclass
        """
        # Get recent swipe events
        stmt = (
            select(SwipeEvent, Product)
            .join(Product, SwipeEvent.product_id == Product.id)
            .where(SwipeEvent.user_id == user_id)
            .order_by(SwipeEvent.created_at.desc())
            .limit(limit)
        )
        result = await session.execute(stmt)
        swipe_products = result.all()

        if not swipe_products:
            # Return default preferences
            return UserPreferences(
                preferred_categories=[],
                preferred_subcategories=[],
                preferred_tags={},
                price_point=100.0,
                price_range_low=30.0,
                price_range_high=2000.0,
                brand_affinity={},
                aesthetic_preferences={},
                color_palette=[],
                average_rating=0.5,
                view_detail_rate=0.0,
                super_like_rate=0.0,
            )

        # Aggregate preferences from swipes
        categories = {}
        subcategories = {}
        all_tags = {}
        brand_scores = {}
        prices = []
        total_swipes = len(swipe_products)
        detail_swipes = 0
        super_like_swipes = 0

        for swipe_event, product in swipe_products:
            # Count action types
            if swipe_event.action == SwipeAction.VIEW_DETAIL:
                detail_swipes += 1
            elif swipe_event.action == SwipeAction.SUPER_LIKE:
                super_like_swipes += 1

            # Collect preferences from liked/super-liked items
            if swipe_event.action in (
                SwipeAction.LIKE,
                SwipeAction.SUPER_LIKE,
                SwipeAction.SHOP_CLICK,
            ):
                if product.category:
                    categories[product.category] = (
                        categories.get(product.category, 0) + 1
                    )

                if product.subcategory:
                    subcategories[product.subcategory] = (
                        subcategories.get(product.subcategory, 0) + 1
                    )

                if product.tags:
                    for tag, weight in product.tags.items():
                        all_tags[tag] = all_tags.get(tag, 0) + float(weight)

                if product.brand_id:
                    brand_scores[str(product.brand_id)] = (
                        brand_scores.get(str(product.brand_id), 0) + 1
                    )

                prices.append(product.current_price)

        # Calculate statistics
        avg_price = sum(prices) / len(prices) if prices else 100.0
        price_std = np.std(prices) if prices else 100.0

        # Price range as mean +/- 1.5 sigma
        price_range_low = max(30.0, avg_price - 1.5 * price_std)
        price_range_high = min(2000.0, avg_price + 1.5 * price_std)

        # Get brand names for top brands
        top_brand_ids = sorted(brand_scores.items(), key=lambda x: x[1], reverse=True)[
            :5
        ]
        if top_brand_ids:
            brand_ids = [b[0] for b in top_brand_ids]
            stmt = select(Brand).where(Brand.id.in_(brand_ids))
            result = await session.execute(stmt)
            brands = result.scalars().all()
            brand_dict = {str(b.id): b.name for b in brands}
            brand_affinity = {
                brand_dict.get(bid, bid): score for bid, score in top_brand_ids
            }
        else:
            brand_affinity = {}

        return UserPreferences(
            preferred_categories=sorted(
                categories.items(), key=lambda x: x[1], reverse=True
            )[:5],
            preferred_subcategories=sorted(
                subcategories.items(), key=lambda x: x[1], reverse=True
            )[:5],
            preferred_tags=dict(
                sorted(all_tags.items(), key=lambda x: x[1], reverse=True)[:10]
            ),
            price_point=avg_price,
            price_range_low=price_range_low,
            price_range_high=price_range_high,
            brand_affinity=brand_affinity,
            aesthetic_preferences=dict(
                sorted(all_tags.items(), key=lambda x: x[1], reverse=True)[:15]
            ),
            color_palette=[],  # TODO: Extract from image analysis
            average_rating=0.5,  # TODO: Compute from engagement
            view_detail_rate=detail_swipes / total_swipes if total_swipes > 0 else 0.0,
            super_like_rate=super_like_swipes / total_swipes
            if total_swipes > 0
            else 0.0,
        )
