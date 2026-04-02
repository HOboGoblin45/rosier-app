"""Email sequence service for automated marketing campaigns."""

import logging
from datetime import datetime
from typing import Optional
from uuid import UUID

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings

logger = logging.getLogger(__name__)


class EmailSequenceService:
    """Service for triggering automated email sequences via Listmonk/n8n."""

    # Webhook endpoints (configured in .env)
    LISTMONK_WEBHOOK_BASE = None
    N8N_WEBHOOK_BASE = None

    @staticmethod
    async def _send_webhook(
        event_name: str,
        user_id: str,
        payload: dict,
    ) -> bool:
        """Send webhook trigger to marketing automation.

        Args:
            event_name: Name of event to trigger
            user_id: User ID
            payload: Event payload

        Returns:
            True if webhook sent successfully
        """
        settings = get_settings()

        # Build webhook URL (using n8n or Listmonk)
        webhook_url = f"{settings.N8N_WEBHOOK_BASE}/{event_name}"

        payload["user_id"] = user_id
        payload["timestamp"] = datetime.utcnow().isoformat()

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(webhook_url, json=payload)

            if response.status_code in (200, 201, 202):
                logger.info(f"Webhook sent: {event_name} for user {user_id}")
                return True
            else:
                logger.error(f"Webhook failed: {event_name} {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"Webhook error: {event_name} - {str(e)}")
            return False

    @staticmethod
    async def trigger_welcome_sequence(
        db: AsyncSession,
        user_id: UUID,
    ) -> bool:
        """Trigger welcome email sequence (Days 0, 1, 3, 7).

        Sequence:
        - Day 0: Welcome email
        - Day 1: First swipe tips
        - Day 3: Style DNA explainer
        - Day 7: Invite friends CTA

        Args:
            db: Database session
            user_id: User ID

        Returns:
            True if sequence triggered
        """
        return await EmailSequenceService._send_webhook(
            "user_signup",
            str(user_id),
            {
                "event": "welcome_sequence",
                "user_id": str(user_id),
            },
        )

    @staticmethod
    async def trigger_referral_milestone(
        db: AsyncSession,
        user_id: UUID,
        tier: str,
        referral_count: int,
    ) -> bool:
        """Send congratulations email when user hits referral milestone.

        Args:
            db: Database session
            user_id: User ID
            tier: Tier name (style_dna, daily_drop, etc)
            referral_count: Number of successful referrals

        Returns:
            True if email triggered
        """
        # Map tier to friendly name
        tier_names = {
            "style_dna": "Style DNA Share",
            "daily_drop": "Daily Drop Early Access",
            "founding_member": "Founding Member",
            "vip_dresser": "VIP Dresser",
            "ambassador": "Brand Ambassador",
        }

        return await EmailSequenceService._send_webhook(
            "referral_milestone",
            str(user_id),
            {
                "event": "referral_milestone_reached",
                "tier": tier,
                "tier_display_name": tier_names.get(tier, tier),
                "referral_count": referral_count,
            },
        )

    @staticmethod
    async def trigger_reengagement(
        db: AsyncSession,
        user_id: UUID,
        days_inactive: int,
    ) -> bool:
        """Send re-engagement email based on inactivity period.

        Sequence:
        - Day 3: Gentle nudge
        - Day 7: New brands available
        - Day 14: Miss you
        - Day 30: Final last-chance

        Args:
            db: Database session
            user_id: User ID
            days_inactive: Days since last activity

        Returns:
            True if email triggered
        """
        return await EmailSequenceService._send_webhook(
            "reengagement",
            str(user_id),
            {
                "event": "reengagement_sequence",
                "days_inactive": days_inactive,
            },
        )

    @staticmethod
    async def trigger_weekly_digest(
        db: AsyncSession,
        user_id: UUID,
    ) -> bool:
        """Trigger weekly style digest email.

        Includes:
        - Top 5 new brands matching user's preferences
        - Trending styles in user's niche
        - Referral progress update (if applicable)

        Args:
            db: Database session
            user_id: User ID

        Returns:
            True if email triggered
        """
        return await EmailSequenceService._send_webhook(
            "weekly_digest",
            str(user_id),
            {
                "event": "weekly_digest",
            },
        )

    @staticmethod
    async def trigger_referral_join_notification(
        db: AsyncSession,
        referrer_id: UUID,
        referred_name: str,
        tier_unlocked: Optional[str] = None,
    ) -> bool:
        """Send email when referred friend joins.

        Args:
            db: Database session
            referrer_id: User who referred
            referred_name: Name of friend who joined
            tier_unlocked: Tier unlocked if applicable

        Returns:
            True if email triggered
        """
        return await EmailSequenceService._send_webhook(
            "referral_join",
            str(referrer_id),
            {
                "event": "friend_joined",
                "referred_name": referred_name,
                "tier_unlocked": tier_unlocked,
            },
        )

    @staticmethod
    async def trigger_leaderboard_milestone(
        db: AsyncSession,
        user_id: UUID,
        rank: int,
        referral_count: int,
    ) -> bool:
        """Send notification when user reaches leaderboard milestone.

        Args:
            db: Database session
            user_id: User ID
            rank: Leaderboard rank
            referral_count: Total referrals

        Returns:
            True if email triggered
        """
        return await EmailSequenceService._send_webhook(
            "leaderboard_milestone",
            str(user_id),
            {
                "event": "leaderboard_milestone",
                "rank": rank,
                "referral_count": referral_count,
            },
        )

    @staticmethod
    async def trigger_custom_sequence(
        db: AsyncSession,
        user_id: UUID,
        sequence_name: str,
        payload: dict,
    ) -> bool:
        """Trigger custom email sequence.

        Args:
            db: Database session
            user_id: User ID
            sequence_name: Name of sequence
            payload: Custom payload

        Returns:
            True if sequence triggered
        """
        return await EmailSequenceService._send_webhook(
            sequence_name,
            str(user_id),
            payload,
        )
