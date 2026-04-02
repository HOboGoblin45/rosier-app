"""Wallpaper pattern assignment, rotation, and analytics service."""
import logging
import random
import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import and_, func, select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User
from app.models.wallpaper import WallpaperHouse, WallpaperPattern, WallpaperImpression, PartnershipStatus
from app.services.style_dna import StyleDNAService

logger = logging.getLogger(__name__)


class WallpaperService:
    """Service for managing wallpaper patterns and partnerships."""

    # Mapping of user style archetypes to preferred wallpaper houses
    ARCHETYPE_TO_HOUSES = {
        "Minimalist with Edge": ["Phillip Jeffries"],
        "Quiet Luxury": ["de Gournay"],
        "Eclectic Maximalist": ["Schumacher"],
        "Street-Meets-Runway": ["Scalamandr é"],
        "Romantic Bohemian": ["de Gournay"],
        "Modern Minimalist": ["Phillip Jeffries"],
        "Vintage Inspired": ["de Gournay"],
        "Sporty Chic": ["Phillip Jeffries"],
        # Fallback mappings for additional archetypes
        "Minimalist Modern": ["Phillip Jeffries"],
        "Eclectic Creative": ["Schumacher"],
        "Classic Refined": ["de Gournay"],
        "Bold Avant-Garde": ["Scalamandr é"],
        "Relaxed Natural": ["Phillip Jeffries"],
    }

    # Discovery rotation for new users (cycles through all houses)
    DISCOVERY_HOUSES = ["de Gournay", "Phillip Jeffries", "Schumacher", "Scalamandr é"]

    # Pattern rotation threshold (swipes between pattern changes)
    PATTERN_ROTATION_THRESHOLD = 50

    @staticmethod
    async def get_pattern_for_user(
        session: AsyncSession,
        user_id: uuid.UUID,
    ) -> Optional[dict]:
        """
        Get the current wallpaper pattern for a user based on style archetype.

        If user has no archetype yet (new user), use discovery rotation.
        Pattern selection is weighted by display_priority and sponsorship status.

        Args:
            session: SQLAlchemy async session
            user_id: User ID

        Returns:
            Dictionary with pattern config (pattern, house, colors, opacity, asset_key)
            or None if no active patterns available
        """
        # Get user's style DNA
        user = await session.get(User, user_id)
        if not user:
            logger.warning(f"User {user_id} not found")
            return None

        # Try to get cached style DNA or compute it
        style_dna = await StyleDNAService.get_or_compute_style_dna(session, str(user_id))
        archetype = style_dna.get("archetype")

        # Determine house(s) to select from
        if archetype and archetype in WallpaperService.ARCHETYPE_TO_HOUSES:
            preferred_houses = WallpaperService.ARCHETYPE_TO_HOUSES[archetype]
        else:
            # New user: use discovery rotation
            logger.debug(f"No archetype for user {user_id}, using discovery rotation")
            preferred_houses = WallpaperService.DISCOVERY_HOUSES

        # Get active patterns from preferred houses
        house_names = preferred_houses if preferred_houses else WallpaperService.DISCOVERY_HOUSES
        stmt = (
            select(WallpaperPattern)
            .join(WallpaperHouse, WallpaperPattern.house_id == WallpaperHouse.id)
            .where(
                and_(
                    WallpaperHouse.name.in_(house_names),
                    WallpaperPattern.is_active.is_(True),
                    WallpaperHouse.is_active.is_(True),
                )
            )
            .order_by(
                # Boost display_priority for active partners
                desc(WallpaperHouse.partnership_status == PartnershipStatus.ACTIVE),
                desc(WallpaperPattern.display_priority),
            )
        )
        result = await session.execute(stmt)
        patterns = result.scalars().all()

        if not patterns:
            logger.warning(f"No active wallpaper patterns for user {user_id}")
            return None

        # Weighted random selection by display_priority
        weights = [p.display_priority + 1 for p in patterns]  # +1 to avoid 0 weights
        selected_pattern = random.choices(patterns, weights=weights, k=1)[0]

        # Build response
        theme = "dark"  # Could be computed from user settings
        if theme == "light":
            primary_color = selected_pattern.primary_color_light
            secondary_color = selected_pattern.secondary_color_light
            opacity = selected_pattern.opacity_light
        else:
            primary_color = selected_pattern.primary_color_dark
            secondary_color = selected_pattern.secondary_color_dark
            opacity = selected_pattern.opacity_dark

        return {
            "pattern_id": str(selected_pattern.id),
            "pattern_name": selected_pattern.name,
            "pattern_type": selected_pattern.pattern_type.value,
            "house_id": str(selected_pattern.house_id),
            "house_name": selected_pattern.house.name,
            "description": selected_pattern.description,
            "primary_color": primary_color,
            "secondary_color": secondary_color,
            "opacity": opacity,
            "asset_key": selected_pattern.asset_key,
            "website_url": selected_pattern.house.website_url,
            "logo_url": selected_pattern.house.logo_url,
        }

    @staticmethod
    async def rotate_pattern(
        session: AsyncSession,
        user_id: uuid.UUID,
    ) -> Optional[dict]:
        """
        Rotate to next wallpaper pattern for user (called every ~50 swipes).

        Selects a different pattern from the user's assigned house.

        Args:
            session: SQLAlchemy async session
            user_id: User ID

        Returns:
            New pattern config dictionary
        """
        # Get current pattern
        current_pattern = await WallpaperService.get_pattern_for_user(session, user_id)
        if not current_pattern:
            return None

        house_id = current_pattern["house_id"]

        # Get all active patterns from same house, excluding current
        stmt = (
            select(WallpaperPattern)
            .where(
                and_(
                    WallpaperPattern.house_id == uuid.UUID(house_id),
                    WallpaperPattern.is_active.is_(True),
                    WallpaperPattern.id != uuid.UUID(current_pattern["pattern_id"]),
                )
            )
            .order_by(desc(WallpaperPattern.display_priority))
        )
        result = await session.execute(stmt)
        available_patterns = result.scalars().all()

        if not available_patterns:
            logger.debug(f"No alternative patterns for house {house_id}, returning current")
            return current_pattern

        # Select next pattern
        next_pattern = random.choice(available_patterns)

        # Build response
        theme = "dark"
        if theme == "light":
            primary_color = next_pattern.primary_color_light
            secondary_color = next_pattern.secondary_color_light
            opacity = next_pattern.opacity_light
        else:
            primary_color = next_pattern.primary_color_dark
            secondary_color = next_pattern.secondary_color_dark
            opacity = next_pattern.opacity_dark

        return {
            "pattern_id": str(next_pattern.id),
            "pattern_name": next_pattern.name,
            "pattern_type": next_pattern.pattern_type.value,
            "house_id": str(next_pattern.house_id),
            "house_name": next_pattern.house.name,
            "description": next_pattern.description,
            "primary_color": primary_color,
            "secondary_color": secondary_color,
            "opacity": opacity,
            "asset_key": next_pattern.asset_key,
            "website_url": next_pattern.house.website_url,
            "logo_url": next_pattern.house.logo_url,
        }

    @staticmethod
    async def record_impression(
        session: AsyncSession,
        user_id: uuid.UUID,
        pattern_id: uuid.UUID,
        dwell_ms: int,
        session_id: Optional[str] = None,
        swipe_position: int = 0,
    ) -> WallpaperImpression:
        """
        Record a wallpaper view impression for billing and analytics.

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            pattern_id: Pattern ID
            dwell_ms: Time spent viewing in milliseconds
            session_id: Optional session ID for grouping
            swipe_position: Position in card queue where wallpaper was seen

        Returns:
            WallpaperImpression record
        """
        # Get pattern to find associated house
        pattern = await session.get(WallpaperPattern, pattern_id)
        if not pattern:
            raise ValueError(f"Pattern {pattern_id} not found")

        # Create impression record
        impression = WallpaperImpression(
            user_id=user_id,
            pattern_id=pattern_id,
            house_id=pattern.house_id,
            session_id=session_id,
            swipe_position=swipe_position,
            dwell_ms=dwell_ms,
        )

        session.add(impression)

        # Update house impression count
        pattern.house.impression_count += 1

        await session.commit()
        logger.debug(f"Recorded impression for pattern {pattern_id} by user {user_id}")

        return impression

    @staticmethod
    async def get_house_analytics(
        session: AsyncSession,
        house_id: uuid.UUID,
        days: int = 30,
    ) -> dict:
        """
        Get analytics for a wallpaper house for billing and performance.

        Args:
            session: SQLAlchemy async session
            house_id: House ID
            days: Number of days to look back (default 30)

        Returns:
            Analytics dictionary with impression count, unique viewers, avg dwell time
        """
        # Get house
        house = await session.get(WallpaperHouse, house_id)
        if not house:
            raise ValueError(f"House {house_id} not found")

        # Date threshold
        cutoff_date = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
        from datetime import timedelta
        cutoff_date = cutoff_date - timedelta(days=days)

        # Total impressions in period
        stmt_impressions = (
            select(func.count(WallpaperImpression.id))
            .where(
                and_(
                    WallpaperImpression.house_id == house_id,
                    WallpaperImpression.created_at >= cutoff_date,
                )
            )
        )
        result = await session.execute(stmt_impressions)
        total_impressions = result.scalar() or 0

        # Unique viewers
        stmt_unique = (
            select(func.count(func.distinct(WallpaperImpression.user_id)))
            .where(
                and_(
                    WallpaperImpression.house_id == house_id,
                    WallpaperImpression.created_at >= cutoff_date,
                )
            )
        )
        result = await session.execute(stmt_unique)
        unique_viewers = result.scalar() or 0

        # Average dwell time
        stmt_dwell = (
            select(func.avg(WallpaperImpression.dwell_ms))
            .where(
                and_(
                    WallpaperImpression.house_id == house_id,
                    WallpaperImpression.created_at >= cutoff_date,
                )
            )
        )
        result = await session.execute(stmt_dwell)
        avg_dwell_ms = result.scalar() or 0

        return {
            "house_id": str(house_id),
            "house_name": house.name,
            "total_impressions": total_impressions,
            "unique_viewers": unique_viewers,
            "avg_dwell_ms": float(avg_dwell_ms),
            "partnership_status": house.partnership_status.value,
            "monthly_fee": house.monthly_fee,
            "period_days": days,
        }

    @staticmethod
    async def get_pattern_analytics(
        session: AsyncSession,
        pattern_id: uuid.UUID,
        days: int = 30,
    ) -> dict:
        """
        Get analytics for a specific wallpaper pattern.

        Args:
            session: SQLAlchemy async session
            pattern_id: Pattern ID
            days: Number of days to look back (default 30)

        Returns:
            Analytics dictionary
        """
        # Get pattern
        pattern = await session.get(WallpaperPattern, pattern_id)
        if not pattern:
            raise ValueError(f"Pattern {pattern_id} not found")

        # Date threshold
        cutoff_date = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
        from datetime import timedelta
        cutoff_date = cutoff_date - timedelta(days=days)

        # Impressions
        stmt_impressions = (
            select(func.count(WallpaperImpression.id))
            .where(
                and_(
                    WallpaperImpression.pattern_id == pattern_id,
                    WallpaperImpression.created_at >= cutoff_date,
                )
            )
        )
        result = await session.execute(stmt_impressions)
        total_impressions = result.scalar() or 0

        # Unique viewers
        stmt_unique = (
            select(func.count(func.distinct(WallpaperImpression.user_id)))
            .where(
                and_(
                    WallpaperImpression.pattern_id == pattern_id,
                    WallpaperImpression.created_at >= cutoff_date,
                )
            )
        )
        result = await session.execute(stmt_unique)
        unique_viewers = result.scalar() or 0

        # Average dwell time
        stmt_dwell = (
            select(func.avg(WallpaperImpression.dwell_ms))
            .where(
                and_(
                    WallpaperImpression.pattern_id == pattern_id,
                    WallpaperImpression.created_at >= cutoff_date,
                )
            )
        )
        result = await session.execute(stmt_dwell)
        avg_dwell_ms = result.scalar() or 0

        return {
            "pattern_id": str(pattern_id),
            "pattern_name": pattern.name,
            "house_id": str(pattern.house_id),
            "house_name": pattern.house.name,
            "total_impressions": total_impressions,
            "unique_viewers": unique_viewers,
            "avg_dwell_ms": float(avg_dwell_ms),
            "pattern_type": pattern.pattern_type.value,
            "period_days": days,
        }
