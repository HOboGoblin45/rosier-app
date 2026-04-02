"""User profile endpoints."""
from typing import Annotated, Optional
import secrets

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import get_db, verify_access_token, extract_bearer_token
from app.models import User, SwipeEvent, SwipeAction
from app.schemas import UserDetail, UserUpdate, UserSettings, StyleDNAResponse, StyleDNAShareResponse
from app.services import RecommendationService

router = APIRouter(prefix="/profile", tags=["profile"])


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


@router.get("", response_model=UserDetail)
async def get_profile(
    user: Annotated[User, Depends(get_current_user)],
) -> UserDetail:
    """Get current user's profile."""
    return UserDetail.from_orm(user)


@router.put("", response_model=UserDetail)
async def update_profile(
    update: UserUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserDetail:
    """Update user profile."""
    if update.display_name:
        user.display_name = update.display_name

    if update.email:
        # Check if email is already taken
        stmt = select(User).where(
            User.email == update.email,
            User.id != user.id,
        )
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already in use",
            )

        user.email = update.email

    if update.settings:
        user.settings = update.settings.model_dump()

    await db.commit()
    await db.refresh(user)

    return UserDetail.from_orm(user)


@router.put("/settings", response_model=dict)
async def update_settings(
    settings: UserSettings,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Update user settings."""
    user.settings = settings.model_dump()
    await db.commit()

    return {
        "message": "Settings updated",
        "settings": user.settings,
    }


@router.get("/style_dna", response_model=StyleDNAResponse)
async def get_style_dna(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> StyleDNAResponse:
    """Get user's Style DNA (preference profile)."""
    # Extract preferences from history
    preferences = await RecommendationService.get_user_preferences_from_history(
        db, str(user.id)
    )

    # Get swipe statistics
    stmt = select(SwipeEvent).where(SwipeEvent.user_id == user.id)
    result = await db.execute(stmt)
    events = result.scalars().all()

    likes = [e for e in events if e.action == SwipeAction.LIKE]
    super_likes = [e for e in events if e.action == SwipeAction.SUPER_LIKE]

    # Extract brands and colors from preferences
    top_brands = [cat[0] for cat in preferences.get("preferred_categories", [])][:3]
    top_tags = list(preferences.get("preferred_tags", {}).keys())[:5]

    return StyleDNAResponse(
        user_id=user.id,
        archetype="Fashion Enthusiast",  # Could be calculated from data
        top_brands=top_brands,
        palette=top_tags,
        price_range={
            "min": preferences.get("price_point", 50) * 0.7,
            "max": preferences.get("price_point", 50) * 1.5,
            "avg": preferences.get("price_point", 50),
        },
        stats={
            "total_swipes": len(events),
            "likes_count": len(likes) + len(super_likes),
            "avg_price_point": preferences.get("price_point", 50),
            "top_categories": [cat[0] for cat in preferences.get("preferred_categories", [])][:5],
            "top_colors": top_tags,
        },
    )


@router.post("/style_dna/share")
async def share_style_dna(
    user: Annotated[User, Depends(get_current_user)],
) -> StyleDNAShareResponse:
    """Generate shareable Style DNA link."""
    share_token = secrets.token_urlsafe(32)

    return StyleDNAShareResponse(
        share_token=share_token,
        share_url=f"https://rosierapp.com/style/{share_token}",
        expires_at="2025-04-01T00:00:00Z",
    )
