"""Brand discovery endpoints."""
from typing import Annotated, Optional
import uuid

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import get_db, verify_access_token, extract_bearer_token
from app.models import User, BrandDiscoveryCard, BrandDiscoverySwipe, Brand
from app.services import BrandDiscoveryService, CardQueueService

router = APIRouter(prefix="/brands", tags=["brand_discovery"])


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


@router.get("/discover")
async def get_next_brand_discovery_card(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Fetch next brand discovery card."""
    user_id = str(user.id)

    # Get a random active brand discovery card
    card = await CardQueueService.get_random_brand_discovery_card(db)

    if not card:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No brand discovery cards available",
        )

    # Track view
    card.total_views += 1
    db.add(card)
    await db.flush()

    return CardQueueService._brand_discovery_card_to_dict(card)


@router.post("/discover/react")
async def submit_brand_discovery_reaction(
    card_id: str,
    action: str,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    dwell_time_ms: int = 0,
    session_id: str = None,
) -> dict:
    """
    Submit a reaction to a brand discovery card.

    Args:
        card_id: Brand discovery card ID
        action: Reaction type - 'like', 'dislike', or 'skip'
        user: Current user
        db: Database session
        dwell_time_ms: How long user viewed card
        session_id: Optional session ID

    Returns:
        Confirmation response
    """
    user_id = user.id

    # Validate action
    if action not in ("like", "dislike", "skip"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid action. Must be 'like', 'dislike', or 'skip'",
        )

    # Get card
    card = await db.get(BrandDiscoveryCard, uuid.UUID(card_id))
    if not card:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Brand discovery card not found",
        )

    # Update card metrics
    if action == "like":
        card.total_likes += 1
    elif action == "dislike":
        card.total_dislikes += 1
    elif action == "skip":
        card.total_skips += 1

    db.add(card)

    # Create swipe record
    swipe = BrandDiscoverySwipe(
        user_id=user_id,
        card_id=card.id,
        brand_id=card.brand_id,
        action=action,
        dwell_time_ms=dwell_time_ms,
        session_id=session_id,
    )
    db.add(swipe)

    await db.flush()

    # Check card health and flag if needed
    should_flag = await BrandDiscoveryService.check_brand_card_health(db, card_id)
    if should_flag:
        await BrandDiscoveryService.flag_brand_card_for_review(db, card_id)

    await db.commit()

    # If liked, boost the brand in recommendations
    if action == "like":
        await BrandDiscoveryService.boost_brand_card(db, card_id)

    return {
        "status": "received",
        "card_id": card_id,
        "action": action,
        "brand_id": str(card.brand_id),
    }


@router.get("/trending")
async def get_trending_brands(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    limit: int = 10,
) -> dict:
    """Get trending brand discovery cards by engagement."""
    # Get top brand cards by like ratio
    stmt = (
        select(BrandDiscoveryCard)
        .where(BrandDiscoveryCard.is_active is True)
        .order_by(
            (BrandDiscoveryCard.total_likes / (BrandDiscoveryCard.total_views + 1)).desc()
        )
        .limit(limit)
    )
    result = await db.execute(stmt)
    cards = result.scalars().all()

    return {
        "trending_brands": [
            CardQueueService._brand_discovery_card_to_dict(card) for card in cards
        ],
        "count": len(cards),
    }


@router.get("/favorites")
async def get_user_favorite_brands(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Get brands the user has liked in discovery cards."""
    # Get all liked swipes for user
    stmt = (
        select(BrandDiscoverySwipe)
        .where(
            (BrandDiscoverySwipe.user_id == user.id)
            & (BrandDiscoverySwipe.action == "like")
        )
        .order_by(BrandDiscoverySwipe.created_at.desc())
    )
    result = await db.execute(stmt)
    swipes = result.scalars().all()

    # Get unique brands
    brand_ids = list(set(str(s.brand_id) for s in swipes))

    # Fetch brand details
    brands = []
    for brand_id in brand_ids:
        brand = await db.get(Brand, uuid.UUID(brand_id))
        if brand:
            brands.append(
                {
                    "id": str(brand.id),
                    "name": brand.name,
                    "tier": brand.tier.value if brand.tier else None,
                    "price_range": {
                        "low": brand.price_range_low,
                        "high": brand.price_range_high,
                    },
                    "logo_url": brand.logo_url,
                }
            )

    return {
        "favorite_brands": brands,
        "count": len(brands),
    }
