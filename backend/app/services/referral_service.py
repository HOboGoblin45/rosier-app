"""Referral system service."""
import logging
import random
import string
from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import and_, desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.models import User, ReferralCode, Referral, ReferralReward, ReferralShare
from app.models.referral import ReferralTier, ReferralStatus, RewardType, ReferralSource

logger = logging.getLogger(__name__)

# Milestone thresholds
TIER_THRESHOLDS = {
    1: ReferralTier.STYLE_DNA,
    3: ReferralTier.DAILY_DROP,
    5: ReferralTier.FOUNDING_MEMBER,
    10: ReferralTier.VIP_DRESSER,
    25: ReferralTier.AMBASSADOR,
}

# Reward type mapping
TIER_TO_REWARD = {
    ReferralTier.STYLE_DNA: RewardType.STYLE_DNA_SHARE,
    ReferralTier.DAILY_DROP: RewardType.DAILY_DROP_EARLY,
    ReferralTier.FOUNDING_MEMBER: RewardType.FOUNDING_MEMBER,
    ReferralTier.VIP_DRESSER: RewardType.VIP_DRESSER,
    ReferralTier.AMBASSADOR: RewardType.AMBASSADOR,
}


class ReferralService:
    """Service for managing referral codes, tracking, and rewards."""

    # Rate limiting
    MAX_REFERRAL_COMPLETIONS_PER_DAY = 5
    REFERRAL_CODE_VALIDITY_DAYS = 90

    @staticmethod
    def _generate_code() -> str:
        """Generate unique 8-char referral code (ROSIE-XXXX format)."""
        chars = string.ascii_uppercase + string.digits
        random_part = "".join(random.choices(chars, k=4))
        return f"ROSIE-{random_part}"

    @staticmethod
    async def create_referral_code(
        db: AsyncSession,
        user_id: UUID,
    ) -> ReferralCode:
        """Generate or retrieve user's referral code.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            ReferralCode object
        """
        # Check if user already has active code
        stmt = select(ReferralCode).where(
            and_(
                ReferralCode.user_id == user_id,
                ReferralCode.is_active is True,
            )
        )
        result = await db.execute(stmt)
        existing_code = result.scalar_one_or_none()

        if existing_code:
            return existing_code

        # Generate unique code
        max_attempts = 10
        code = None
        for _ in range(max_attempts):
            candidate = ReferralService._generate_code()
            stmt = select(ReferralCode).where(ReferralCode.code == candidate)
            result = await db.execute(stmt)
            if not result.scalar_one_or_none():
                code = candidate
                break

        if not code:
            raise RuntimeError("Failed to generate unique referral code")

        # Create new code
        referral_code = ReferralCode(
            user_id=user_id,
            code=code,
        )
        db.add(referral_code)
        await db.commit()
        await db.refresh(referral_code)

        logger.info(f"Created referral code {code} for user {user_id}")
        return referral_code

    @staticmethod
    async def get_referral_stats(
        db: AsyncSession,
        user_id: UUID,
    ) -> dict:
        """Get user's referral statistics.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            Dict with code, count stats, tier, and progress
        """
        # Get referral code
        stmt = select(ReferralCode).where(
            and_(
                ReferralCode.user_id == user_id,
                ReferralCode.is_active is True,
            )
        )
        result = await db.execute(stmt)
        referral_code = result.scalar_one_or_none()

        if not referral_code:
            referral_code = await ReferralService.create_referral_code(db, user_id)

        # Count successful referrals
        stmt = select(func.count(Referral.id)).where(
            and_(
                Referral.referrer_id == user_id,
                Referral.status == ReferralStatus.COMPLETED.value,
                Referral.referred_completed_onboarding is True,
            )
        )
        result = await db.execute(stmt)
        successful_referrals = result.scalar() or 0

        # Calculate current tier
        current_tier = ReferralTier.NONE.value
        for threshold in sorted(TIER_THRESHOLDS.keys(), reverse=True):
            if successful_referrals >= threshold:
                current_tier = TIER_THRESHOLDS[threshold].value
                break

        # Find next tier
        next_tier = None
        next_threshold = None
        for threshold in sorted(TIER_THRESHOLDS.keys()):
            if threshold > successful_referrals:
                next_tier = TIER_THRESHOLDS[threshold].value
                next_threshold = threshold
                break

        referrals_to_next = next_threshold - successful_referrals if next_threshold else 0

        return {
            "code": referral_code.code,
            "total_referrals": referral_code.total_referrals,
            "successful_referrals": successful_referrals,
            "current_tier": current_tier,
            "next_tier": next_tier,
            "referrals_to_next": referrals_to_next,
        }

    @staticmethod
    async def process_referral(
        db: AsyncSession,
        referred_user_id: UUID,
        referral_code: str,
        source: str = ReferralSource.OTHER.value,
    ) -> Optional[Referral]:
        """Process referral when new user signs up with code.

        Args:
            db: Database session
            referred_user_id: ID of user being referred
            referral_code: The referral code used
            source: Where the code was shared from

        Returns:
            Referral object or None if code invalid
        """
        # Validate code
        stmt = select(ReferralCode).where(ReferralCode.code == referral_code)
        result = await db.execute(stmt)
        code_record = result.scalar_one_or_none()

        if not code_record or not code_record.is_active:
            logger.warning(f"Invalid or inactive referral code: {referral_code}")
            return None

        # Check expiry
        if code_record.created_at + timedelta(days=ReferralService.REFERRAL_CODE_VALIDITY_DAYS) < datetime.now(timezone.utc):
            logger.warning(f"Referral code expired: {referral_code}")
            code_record.is_active = False
            await db.commit()
            return None

        referrer_id = code_record.user_id

        # Prevent self-referral
        if referrer_id == referred_user_id:
            logger.warning(f"Self-referral attempt: {referred_user_id}")
            return None

        # Prevent duplicate referrals
        stmt = select(Referral).where(
            and_(
                Referral.referrer_id == referrer_id,
                Referral.referred_id == referred_user_id,
                Referral.status != ReferralStatus.EXPIRED.value,
            )
        )
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            logger.warning(f"Duplicate referral: {referrer_id} -> {referred_user_id}")
            return None

        # Create referral record
        expires_at = datetime.now(timezone.utc) + timedelta(days=ReferralService.REFERRAL_CODE_VALIDITY_DAYS)
        referral = Referral(
            referrer_id=referrer_id,
            referred_id=referred_user_id,
            referral_code_id=code_record.id,
            source=source,
            expires_at=expires_at,
        )
        db.add(referral)

        # Increment total referrals on code
        code_record.total_referrals += 1

        await db.commit()
        await db.refresh(referral)

        logger.info(f"Created referral: {referrer_id} -> {referred_user_id} via {referral_code}")
        return referral

    @staticmethod
    async def complete_referral(
        db: AsyncSession,
        referred_user_id: UUID,
    ) -> Optional[ReferralReward]:
        """Mark referral as complete when referred user finishes onboarding.

        Args:
            db: Database session
            referred_user_id: ID of referred user who completed onboarding

        Returns:
            ReferralReward if new tier unlocked, else None
        """
        # Find pending referral
        stmt = select(Referral).where(
            and_(
                Referral.referred_id == referred_user_id,
                Referral.status == ReferralStatus.PENDING.value,
            )
        )
        result = await db.execute(stmt)
        referral = result.scalar_one_or_none()

        if not referral:
            logger.warning(f"No pending referral found for user {referred_user_id}")
            return None

        # Mark referral complete
        referral.status = ReferralStatus.COMPLETED.value
        referral.referred_completed_onboarding = True
        referral.completed_at = datetime.now(timezone.utc)
        await db.commit()

        logger.info(f"Completed referral: {referral.referrer_id} -> {referred_user_id}")

        # Check for reward
        return await ReferralService.check_and_grant_rewards(db, referral.referrer_id)

    @staticmethod
    async def check_and_grant_rewards(
        db: AsyncSession,
        user_id: UUID,
    ) -> Optional[ReferralReward]:
        """Check if user reached new milestone and grant reward.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            ReferralReward if new reward granted, else None
        """
        # Count successful referrals
        stmt = select(func.count(Referral.id)).where(
            and_(
                Referral.referrer_id == user_id,
                Referral.status == ReferralStatus.COMPLETED.value,
                Referral.referred_completed_onboarding is True,
            )
        )
        result = await db.execute(stmt)
        successful_referrals = result.scalar() or 0

        # Check which rewards are already granted
        stmt = select(ReferralReward).where(ReferralReward.user_id == user_id)
        result = await db.execute(stmt)
        existing_rewards = result.scalars().all()
        granted_milestones = {r.milestone_count for r in existing_rewards}

        # Find new milestones reached
        new_reward = None
        for threshold, tier in TIER_THRESHOLDS.items():
            if successful_referrals >= threshold and threshold not in granted_milestones:
                reward_type = TIER_TO_REWARD[tier]
                new_reward = ReferralReward(
                    user_id=user_id,
                    reward_type=reward_type.value,
                    milestone_count=threshold,
                )
                db.add(new_reward)

                # Update referral code tier
                stmt = select(ReferralCode).where(
                    and_(
                        ReferralCode.user_id == user_id,
                        ReferralCode.is_active is True,
                    )
                )
                result = await db.execute(stmt)
                code = result.scalar_one_or_none()
                if code:
                    code.current_tier = tier.value
                    code.successful_referrals = successful_referrals

                logger.info(f"Granted reward {reward_type.value} to user {user_id} at {threshold} referrals")

        if new_reward:
            await db.commit()
            await db.refresh(new_reward)

        return new_reward

    @staticmethod
    async def get_leaderboard(
        db: AsyncSession,
        limit: int = 20,
        month: Optional[str] = None,
    ) -> list[dict]:
        """Get top referrers leaderboard.

        Args:
            db: Database session
            limit: Number of top referrers to return
            month: Optional month filter (YYYY-MM format)

        Returns:
            List of leaderboard entries
        """
        # Get top referrers by successful referral count
        stmt = (
            select(
                Referral.referrer_id,
                func.count(Referral.id).label("referral_count"),
            )
            .where(
                and_(
                    Referral.status == ReferralStatus.COMPLETED.value,
                    Referral.referred_completed_onboarding is True,
                )
            )
            .group_by(Referral.referrer_id)
            .order_by(desc("referral_count"))
            .limit(limit)
        )
        result = await db.execute(stmt)
        top_referrers = result.all()

        leaderboard = []
        for rank, (referrer_id, referral_count) in enumerate(top_referrers, 1):
            # Get user info
            stmt = select(User).where(User.id == referrer_id)
            result = await db.execute(stmt)
            user = result.scalar_one_or_none()

            if not user:
                continue

            # Get user's current tier
            stmt = select(ReferralCode).where(
                and_(
                    ReferralCode.user_id == referrer_id,
                    ReferralCode.is_active is True,
                )
            )
            result = await db.execute(stmt)
            code = result.scalar_one_or_none()

            tier = code.current_tier if code else ReferralTier.NONE.value

            leaderboard.append({
                "rank": rank,
                "user_id": str(referrer_id),
                "name": user.display_name,
                "invites": referral_count,
                "tier": tier,
            })

        return leaderboard

    @staticmethod
    async def get_referral_link(
        user_id: UUID,
    ) -> str:
        """Get shareable deep link for referral code.

        Args:
            user_id: User ID

        Returns:
            Deep link URL
        """
        settings = get_settings()
        # Link will be generated once we have the code
        # This is a template that gets filled in by the endpoint
        return f"{settings.DEEP_LINK_BASE}/invite"

    @staticmethod
    async def track_share(
        db: AsyncSession,
        user_id: UUID,
        platform: str,
    ) -> None:
        """Track when user shares their referral link.

        Args:
            db: Database session
            user_id: User ID
            platform: Platform shared to (instagram, imessage, etc)
        """
        # Get user's active referral code
        stmt = select(ReferralCode).where(
            and_(
                ReferralCode.user_id == user_id,
                ReferralCode.is_active is True,
            )
        )
        result = await db.execute(stmt)
        code = result.scalar_one_or_none()

        if not code:
            logger.warning(f"No active referral code for user {user_id}")
            return

        # Create share record
        share = ReferralShare(
            user_id=user_id,
            referral_code_id=code.id,
            platform=platform,
        )
        db.add(share)
        await db.commit()

        logger.info(f"Tracked share: user {user_id} shared via {platform}")

    @staticmethod
    async def check_rate_limit(
        db: AsyncSession,
        referrer_id: UUID,
    ) -> tuple[bool, int]:
        """Check if referrer exceeded daily completion limit.

        Args:
            db: Database session
            referrer_id: Referrer user ID

        Returns:
            Tuple of (allowed, remaining_quota)
        """
        # Count completions in last 24 hours
        cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
        stmt = select(func.count(Referral.id)).where(
            and_(
                Referral.referrer_id == referrer_id,
                Referral.status == ReferralStatus.COMPLETED.value,
                Referral.completed_at >= cutoff,
            )
        )
        result = await db.execute(stmt)
        completed_today = result.scalar() or 0

        allowed = completed_today < ReferralService.MAX_REFERRAL_COMPLETIONS_PER_DAY
        remaining = max(0, ReferralService.MAX_REFERRAL_COMPLETIONS_PER_DAY - completed_today)

        return allowed, remaining
