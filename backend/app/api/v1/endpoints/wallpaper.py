"""Wallpaper house and pattern endpoints."""
import logging
import uuid
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import get_db, verify_access_token, extract_bearer_token
from app.models import User
from app.models.wallpaper import WallpaperHouse, WallpaperPattern
from app.schemas.wallpaper import (
    WallpaperCurrentResponse,
    WallpaperHouseCreate,
    WallpaperHouseResponse,
    WallpaperHouseUpdate,
    WallpaperHouseAnalyticsResponse,
    WallpaperImpressionRequest,
    WallpaperPatternAnalyticsResponse,
)
from app.services.wallpaper_service import WallpaperService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/wallpaper", tags=["wallpaper"])


async def get_current_user(
    db: Annotated[AsyncSession, Depends(get_db)],
    authorization: Annotated[Optional[str], Header()] = None,
) -> User:
    """Get current authenticated user from Bearer token."""
    # Extract and verify bearer token
    token = extract_bearer_token(authorization)
    user_id = verify_access_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    return user


@router.get("/current", response_model=WallpaperCurrentResponse)
async def get_current_wallpaper(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> WallpaperCurrentResponse:
    """Get user's current wallpaper pattern.

    Returns the wallpaper configuration including pattern name, colors, opacity, and asset key.
    """
    pattern_config = await WallpaperService.get_pattern_for_user(db, user.id)

    if not pattern_config:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No active wallpaper patterns available",
        )

    return WallpaperCurrentResponse(**pattern_config)


@router.post("/impression")
async def record_wallpaper_impression(
    impression: WallpaperImpressionRequest,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Record a wallpaper view impression for analytics and billing.

    Called when user sees the wallpaper during a swipe session.
    """
    try:
        await WallpaperService.record_impression(
            db,
            user.id,
            impression.pattern_id,
            impression.dwell_ms,
            session_id=impression.session_id,
            swipe_position=impression.swipe_position,
        )
        return {"status": "recorded"}
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )


# Admin endpoints


@router.get("/admin/houses", response_model=list[WallpaperHouseResponse])
async def list_wallpaper_houses(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[WallpaperHouseResponse]:
    """List all wallpaper houses with partnership status.

    Admin endpoint - get list of all wallpaper brand partners.
    """
    # TODO: Add admin role check
    stmt = select(WallpaperHouse).order_by(WallpaperHouse.name)
    result = await db.execute(stmt)
    houses = result.scalars().all()

    return [WallpaperHouseResponse.from_orm(h) for h in houses]


@router.post("/admin/houses", response_model=WallpaperHouseResponse, status_code=status.HTTP_201_CREATED)
async def create_wallpaper_house(
    house: WallpaperHouseCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> WallpaperHouseResponse:
    """Add a new wallpaper house partnership.

    Admin endpoint - creates a new wallpaper house.
    """
    # TODO: Add admin role check

    # Check if house already exists
    stmt = select(WallpaperHouse).where(WallpaperHouse.slug == house.slug)
    result = await db.execute(stmt)
    existing = result.scalar_one_or_none()

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="House with this slug already exists",
        )

    new_house = WallpaperHouse(**house.model_dump())
    db.add(new_house)
    await db.commit()
    await db.refresh(new_house)

    logger.info(f"Created new wallpaper house: {new_house.name}")
    return WallpaperHouseResponse.from_orm(new_house)


@router.patch("/admin/houses/{house_id}", response_model=WallpaperHouseResponse)
async def update_wallpaper_house(
    house_id: uuid.UUID,
    update: WallpaperHouseUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> WallpaperHouseResponse:
    """Update wallpaper house partnership status, fee, and dates.

    Admin endpoint - modifies partnership terms.
    """
    # TODO: Add admin role check

    house = await db.get(WallpaperHouse, house_id)
    if not house:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="House not found",
        )

    update_data = update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(house, field, value)

    await db.commit()
    await db.refresh(house)

    logger.info(f"Updated wallpaper house: {house.name}")
    return WallpaperHouseResponse.from_orm(house)


@router.get("/admin/analytics/houses/{house_id}", response_model=WallpaperHouseAnalyticsResponse)
async def get_house_analytics(
    house_id: uuid.UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    days: int = 30,
) -> WallpaperHouseAnalyticsResponse:
    """Get impression analytics for a wallpaper house.

    Admin endpoint - returns impression count, unique viewers, and average dwell time.
    Used for billing and partnership performance evaluation.
    """
    # TODO: Add admin role check

    try:
        analytics = await WallpaperService.get_house_analytics(db, house_id, days=days)
        return WallpaperHouseAnalyticsResponse(**analytics)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )


@router.get("/admin/analytics/patterns/{pattern_id}", response_model=WallpaperPatternAnalyticsResponse)
async def get_pattern_analytics(
    pattern_id: uuid.UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    days: int = 30,
) -> WallpaperPatternAnalyticsResponse:
    """Get impression analytics for a specific wallpaper pattern.

    Admin endpoint - returns performance metrics for a pattern.
    """
    # TODO: Add admin role check

    try:
        analytics = await WallpaperService.get_pattern_analytics(db, pattern_id, days=days)
        return WallpaperPatternAnalyticsResponse(**analytics)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )


@router.get("/admin/analytics", response_model=dict)
async def get_wallpaper_analytics_summary(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    days: int = 30,
) -> dict:
    """Get aggregated analytics across all wallpaper houses.

    Admin endpoint - summary of all impression analytics.
    """
    # TODO: Add admin role check

    stmt = select(WallpaperHouse).order_by(WallpaperHouse.name)
    result = await db.execute(stmt)
    houses = result.scalars().all()

    house_analytics = []
    total_impressions = 0
    total_unique_viewers = 0
    avg_dwell_ms = 0

    for house in houses:
        try:
            analytics = await WallpaperService.get_house_analytics(db, house.id, days=days)
            house_analytics.append(analytics)
            total_impressions += analytics["total_impressions"]
            total_unique_viewers += analytics["unique_viewers"]
            if analytics["avg_dwell_ms"] > 0:
                avg_dwell_ms += analytics["avg_dwell_ms"]
        except ValueError:
            pass

    avg_dwell_ms = avg_dwell_ms / len(house_analytics) if house_analytics else 0

    return {
        "period_days": days,
        "total_impressions": total_impressions,
        "total_unique_viewers": total_unique_viewers,
        "avg_dwell_ms": avg_dwell_ms,
        "house_count": len(houses),
        "houses": house_analytics,
    }
