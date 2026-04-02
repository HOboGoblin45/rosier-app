"""Brand discovery and onboarding service."""

import logging
from typing import Optional
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    BrandCandidate,
    BrandCandidateStatus,
    BrandDiscoveryCard,
    Brand,
)

logger = logging.getLogger(__name__)


class BrandDiscoveryService:
    """Service for discovering, evaluating, and onboarding brands."""

    # Rosier-eligible brand criteria
    MIN_PRICE = 50.0
    MAX_PRICE = 500.0
    MIN_FIT_SCORE = 60.0  # Out of 100

    @staticmethod
    async def evaluate_brand_fit(
        session: AsyncSession,
        brand_candidate: BrandCandidate,
        user_preference_aesthetics: Optional[list[str]] = None,
    ) -> float:
        """
        Calculate fit score (0-100) for a brand candidate.

        Factors considered:
        - Price range alignment with Rosier users
        - Aesthetic alignment with user preferences
        - Affiliate network availability
        - Ambassador program availability

        Args:
            session: SQLAlchemy async session
            brand_candidate: BrandCandidate to evaluate
            user_preference_aesthetics: Optional aesthetic tags from user base

        Returns:
            Fit score between 0 and 100
        """
        score = 0.0

        # Price range check (max 40 points)
        if brand_candidate.price_range_low and brand_candidate.price_range_high:
            price_low = brand_candidate.price_range_low
            price_high = brand_candidate.price_range_high

            # Ideal range: $50-$500
            if (
                BrandDiscoveryService.MIN_PRICE
                <= price_low
                <= BrandDiscoveryService.MAX_PRICE
            ):
                score += 20.0
            if (
                BrandDiscoveryService.MIN_PRICE
                <= price_high
                <= BrandDiscoveryService.MAX_PRICE
            ):
                score += 20.0

        # Aesthetic alignment (max 30 points)
        if brand_candidate.aesthetic_tags:
            if user_preference_aesthetics:
                matching_tags = set(brand_candidate.aesthetic_tags) & set(
                    user_preference_aesthetics
                )
                tag_score = (
                    len(matching_tags) / len(brand_candidate.aesthetic_tags)
                ) * 30
                score += min(tag_score, 30.0)
            else:
                # If no user prefs, give partial credit for having aesthetics defined
                score += 15.0

        # Affiliate network availability (max 20 points)
        if (
            brand_candidate.affiliate_network
            and brand_candidate.affiliate_network != "direct"
        ):
            score += 20.0
        elif brand_candidate.commission_rate:
            score += 15.0

        # Ambassador program bonus (max 10 points)
        if brand_candidate.has_ambassador_program:
            score += 10.0

        return min(score, 100.0)

    @staticmethod
    async def get_or_create_brand_candidate(
        session: AsyncSession,
        name: str,
        website: Optional[str] = None,
        instagram: Optional[str] = None,
        price_range_low: Optional[float] = None,
        price_range_high: Optional[float] = None,
        aesthetic_tags: Optional[list[str]] = None,
        affiliate_network: Optional[str] = None,
        commission_rate: Optional[float] = None,
        has_ambassador_program: bool = False,
        ambassador_program_url: Optional[str] = None,
    ) -> BrandCandidate:
        """
        Create or get a brand candidate.

        Args:
            session: SQLAlchemy async session
            name: Brand name
            website: Brand website URL
            instagram: Instagram handle
            price_range_low: Low end of price range
            price_range_high: High end of price range
            aesthetic_tags: List of aesthetic tags
            affiliate_network: Affiliate network type
            commission_rate: Commission rate as decimal
            has_ambassador_program: Whether brand has ambassador program
            ambassador_program_url: URL to ambassador program

        Returns:
            BrandCandidate instance
        """
        # Check if exists
        stmt = select(BrandCandidate).where(BrandCandidate.name == name)
        result = await session.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            logger.info(f"Brand candidate {name} already exists")
            return existing

        # Create new candidate
        candidate = BrandCandidate(
            name=name,
            website=website,
            instagram=instagram,
            price_range_low=price_range_low,
            price_range_high=price_range_high,
            aesthetic_tags=aesthetic_tags or [],
            affiliate_network=affiliate_network,
            commission_rate=commission_rate,
            has_ambassador_program=has_ambassador_program,
            ambassador_program_url=ambassador_program_url,
        )

        # Calculate fit score
        candidate.fit_score = await BrandDiscoveryService.evaluate_brand_fit(
            session, candidate
        )

        session.add(candidate)
        await session.flush()
        logger.info(
            f"Created brand candidate {name} with fit score {candidate.fit_score}"
        )

        return candidate

    @staticmethod
    async def approve_brand_candidate(
        session: AsyncSession,
        candidate_id: str,
        evaluation_notes: Optional[str] = None,
    ) -> BrandCandidate:
        """
        Approve a brand candidate for activation.

        Args:
            session: SQLAlchemy async session
            candidate_id: Brand candidate ID
            evaluation_notes: Optional notes from reviewer

        Returns:
            Updated BrandCandidate
        """
        candidate = await session.get(BrandCandidate, uuid.UUID(candidate_id))
        if not candidate:
            raise ValueError(f"Brand candidate {candidate_id} not found")

        candidate.status = BrandCandidateStatus.APPROVED
        candidate.evaluation_notes = evaluation_notes
        candidate.evaluated_at = BrandDiscoveryService._now()

        await session.flush()
        logger.info(f"Approved brand candidate {candidate.name}")

        return candidate

    @staticmethod
    async def reject_brand_candidate(
        session: AsyncSession,
        candidate_id: str,
        reason: str,
    ) -> BrandCandidate:
        """
        Reject a brand candidate.

        Args:
            session: SQLAlchemy async session
            candidate_id: Brand candidate ID
            reason: Reason for rejection

        Returns:
            Updated BrandCandidate
        """
        candidate = await session.get(BrandCandidate, uuid.UUID(candidate_id))
        if not candidate:
            raise ValueError(f"Brand candidate {candidate_id} not found")

        candidate.status = BrandCandidateStatus.REJECTED
        candidate.evaluation_notes = reason
        candidate.evaluated_at = BrandDiscoveryService._now()

        await session.flush()
        logger.info(f"Rejected brand candidate {candidate.name}: {reason}")

        return candidate

    @staticmethod
    async def activate_brand_candidate(
        session: AsyncSession,
        candidate_id: str,
        brand_id: str,
    ) -> BrandCandidate:
        """
        Activate a brand candidate (move to active, create discovery card).

        Args:
            session: SQLAlchemy async session
            candidate_id: Brand candidate ID
            brand_id: Associated Brand ID

        Returns:
            Updated BrandCandidate
        """
        candidate = await session.get(BrandCandidate, uuid.UUID(candidate_id))
        if not candidate:
            raise ValueError(f"Brand candidate {candidate_id} not found")

        if candidate.status != BrandCandidateStatus.APPROVED:
            raise ValueError(
                f"Brand candidate {candidate.name} must be approved before activation"
            )

        candidate.status = BrandCandidateStatus.ACTIVE
        candidate.activated_at = BrandDiscoveryService._now()

        # Create discovery card
        brand = await session.get(Brand, uuid.UUID(brand_id))
        if not brand:
            raise ValueError(f"Brand {brand_id} not found")

        discovery_card = BrandDiscoveryCard(
            brand_id=brand.id,
            brand_name=brand.name,
            description=candidate.description,
            logo_url=brand.logo_url,
            aesthetic_tags=candidate.aesthetic_tags or [],
            price_range_low=candidate.price_range_low,
            price_range_high=candidate.price_range_high,
            ambassador_program_url=candidate.ambassador_program_url,
            has_ambassador_program=candidate.has_ambassador_program,
        )

        session.add(discovery_card)
        await session.flush()
        logger.info(
            f"Activated brand candidate {candidate.name}, created discovery card"
        )

        return candidate

    @staticmethod
    async def get_pending_candidates(
        session: AsyncSession,
        limit: int = 20,
    ) -> list[BrandCandidate]:
        """
        Get pending brand candidates for review.

        Args:
            session: SQLAlchemy async session
            limit: Maximum candidates to return

        Returns:
            List of BrandCandidate instances
        """
        stmt = (
            select(BrandCandidate)
            .where(BrandCandidate.status == BrandCandidateStatus.PENDING)
            .order_by(BrandCandidate.fit_score.desc())
            .limit(limit)
        )
        result = await session.execute(stmt)
        return result.scalars().all()

    @staticmethod
    async def check_brand_card_health(
        session: AsyncSession,
        card_id: str,
    ) -> bool:
        """
        Check if a brand discovery card should be flagged for review.

        Flag if:
        - Disliked by >60% of viewers
        - Skipped by >80% of viewers

        Args:
            session: SQLAlchemy async session
            card_id: Brand discovery card ID

        Returns:
            True if should be flagged, False otherwise
        """
        card = await session.get(BrandDiscoveryCard, uuid.UUID(card_id))
        if not card:
            return False

        total_reactions = card.total_likes + card.total_dislikes + card.total_skips
        if total_reactions < 10:  # Need minimum sample size
            return False

        dislike_rate = card.total_dislikes / total_reactions
        skip_rate = card.total_skips / total_reactions

        if dislike_rate > 0.60:
            logger.warning(
                f"Brand card {card.brand_name} flagged: {dislike_rate:.1%} dislike rate"
            )
            return True

        if skip_rate > 0.80:
            logger.warning(
                f"Brand card {card.brand_name} flagged: {skip_rate:.1%} skip rate"
            )
            return True

        return False

    @staticmethod
    async def flag_brand_card_for_review(
        session: AsyncSession,
        card_id: str,
    ) -> BrandDiscoveryCard:
        """
        Flag a brand discovery card for manual review.

        Args:
            session: SQLAlchemy async session
            card_id: Brand discovery card ID

        Returns:
            Updated BrandDiscoveryCard
        """
        from app.models import BrandDiscoveryCardStatus

        card = await session.get(BrandDiscoveryCard, uuid.UUID(card_id))
        if not card:
            raise ValueError(f"Brand card {card_id} not found")

        card.status = BrandDiscoveryCardStatus.FLAGGED_FOR_REVIEW
        await session.flush()
        logger.warning(f"Flagged brand card {card.brand_name} for review")

        return card

    @staticmethod
    async def boost_brand_card(
        session: AsyncSession,
        card_id: str,
    ) -> BrandDiscoveryCard:
        """
        Boost a brand discovery card (increase its visibility if >70% like rate).

        Args:
            session: SQLAlchemy async session
            card_id: Brand discovery card ID

        Returns:
            Updated BrandDiscoveryCard
        """
        card = await session.get(BrandDiscoveryCard, uuid.UUID(card_id))
        if not card:
            raise ValueError(f"Brand card {card_id} not found")

        total_reactions = card.total_likes + card.total_dislikes
        if total_reactions < 10:
            return card

        like_rate = card.total_likes / total_reactions
        if like_rate > 0.70:
            logger.info(
                f"Brand card {card.brand_name} boosted: {like_rate:.1%} like rate"
            )
            # This will be used by recommendation service to boost products from this brand

        return card

    @staticmethod
    def _now():
        """Get current UTC datetime."""
        from datetime import datetime, timezone

        return datetime.now(timezone.utc)
