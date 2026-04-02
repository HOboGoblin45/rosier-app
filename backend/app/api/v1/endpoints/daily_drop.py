"""Daily drop API endpoints."""

import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models import DailyDrop

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/daily-drop", tags=["daily-drop"])


class DailyDropResponse(BaseModel):
    """Daily drop response."""

    id: uuid.UUID
    product_ids: list[str]
    generated_at: datetime
    viewed_at: datetime = None
    streak_count: int


class DailyDropViewedRequest(BaseModel):
    """Request to mark daily drop as viewed."""

    pass


class StreakResponse(BaseModel):
    """Streak count response."""

    streak_count: int
    last_view_date: datetime = None


@router.get("")
async def get_daily_drop(
    db: AsyncSession = Depends(get_db),
) -> DailyDropResponse:
    """
    Get today's daily drop (5 curated items).

    Returns:
        Today's daily drop with product IDs
    """
    # In production, extract user_id from authenticated request
    # This is a placeholder implementation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Endpoint requires authentication middleware",
    )


@router.post("/viewed")
async def mark_daily_drop_viewed(
    request: DailyDropViewedRequest,
    db: AsyncSession = Depends(get_db),
) -> DailyDropResponse:
    """
    Mark today's daily drop as viewed and update streak.

    Args:
        request: View confirmation
        db: Database session

    Returns:
        Updated daily drop with new streak
    """
    # In production, extract user_id from authenticated request
    # This is a placeholder implementation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Endpoint requires authentication middleware",
    )


@router.get("/streak")
async def get_streak_count(
    db: AsyncSession = Depends(get_db),
) -> StreakResponse:
    """
    Get user's current daily drop streak.

    Returns:
        Current streak count and last view date
    """
    # In production, extract user_id from authenticated request
    # This is a placeholder implementation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Endpoint requires authentication middleware",
    )


async def generate_daily_drop(
    user_id: uuid.UUID,
    product_ids: list[uuid.UUID],
    db: AsyncSession = Depends(get_db),
) -> DailyDrop:
    """
    Generate a daily drop for a user (internal use).

    Args:
        user_id: User to generate daily drop for
        product_ids: List of product IDs to include
        db: Database session

    Returns:
        Created DailyDrop object
    """
    # Check if daily drop already exists for today
    today = datetime.now(timezone.utc).date()

    stmt = select(DailyDrop).where(
        DailyDrop.user_id == user_id,
        func.date(DailyDrop.generated_at) == today,
    )
    result = await db.execute(stmt)
    existing = result.scalar_one_or_none()

    if existing:
        # Update existing daily drop
        existing.product_ids = [str(pid) for pid in product_ids]
        existing.viewed_at = None
        await db.commit()
        return existing

    # Create new daily drop
    daily_drop = DailyDrop(
        user_id=user_id,
        product_ids=[str(pid) for pid in product_ids],
        streak_count=0,
    )
    db.add(daily_drop)
    await db.commit()
    await db.refresh(daily_drop)

    return daily_drop


async def update_daily_drop_streak(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> DailyDrop:
    """
    Update daily drop streak for a user (internal use).

    Args:
        user_id: User to update streak for
        db: Database session

    Returns:
        Updated DailyDrop object
    """
    today = datetime.now(timezone.utc).date()

    stmt = select(DailyDrop).where(
        DailyDrop.user_id == user_id,
        func.date(DailyDrop.generated_at) == today,
    )
    result = await db.execute(stmt)
    daily_drop = result.scalar_one_or_none()

    if not daily_drop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Daily drop not found for today",
        )

    # Mark as viewed
    daily_drop.viewed_at = datetime.now(timezone.utc)

    # Increment streak (in production, check if viewed yesterday)
    daily_drop.streak_count = (daily_drop.streak_count or 0) + 1

    await db.commit()
    await db.refresh(daily_drop)

    return daily_drop
