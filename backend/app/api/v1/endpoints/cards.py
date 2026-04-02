"""Card feed endpoints."""

from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import get_db, verify_access_token, extract_bearer_token
from app.core.redis import clear_card_queue, remove_from_queue
from app.models import User, SwipeEvent
from app.schemas import SwipeEventBatch
from app.services import CardQueueService

router = APIRouter(prefix="/cards", tags=["cards"])


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


@router.get("/next")
async def get_next_cards(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    count: int = Query(20, ge=1, le=100),
) -> dict:
    """Fetch next N cards from the queue."""
    user_id = str(user.id)

    # Get user preferences from quiz responses
    preferences = None
    if user.quiz_responses:
        preferences = {
            "preferred_categories": user.quiz_responses.get("preferred_categories", []),
            "preferred_subcategories": user.quiz_responses.get(
                "preferred_subcategories", []
            ),
            "preferred_tags": user.quiz_responses.get("preferred_tags", {}),
            "price_point": user.quiz_responses.get("price_point", 50.0),
        }

    # Get or generate queue
    queue = await CardQueueService.get_or_generate_queue(
        db,
        user_id,
        user_preferences=preferences,
    )

    # Return requested number of cards
    cards = queue[:count]
    remaining = queue[count:]

    # Update queue in Redis
    if remaining:
        await CardQueueService._CardQueueService__class__.set_card_queue(
            user_id, remaining
        )
    else:
        await clear_card_queue(user_id)

    return {
        "cards": cards,
        "count": len(cards),
        "queue_remaining": len(remaining),
    }


@router.post("/events")
async def submit_swipe_events(
    batch: SwipeEventBatch,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Batch submit swipe events."""
    user_id = user.id
    created_events = []

    # Create swipe events
    for event_data in batch.events:
        event = SwipeEvent(
            user_id=user_id,
            product_id=event_data.product_id,
            action=event_data.action,
            dwell_time_ms=event_data.dwell_time_ms,
            session_position=event_data.session_position,
            expanded=event_data.expanded,
            session_id=event_data.session_id or batch.session_id,
        )
        db.add(event)
        created_events.append(event)

    await db.flush()

    # Remove viewed products from queue
    for event_data in batch.events:
        await remove_from_queue(str(user_id), str(event_data.product_id))

    # Commit
    await db.commit()

    return {
        "events_received": len(batch.events),
        "events_created": len(created_events),
    }


@router.get("/events")
async def get_swipe_events(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
) -> dict:
    """Get user's swipe event history."""
    stmt = (
        select(SwipeEvent)
        .where(SwipeEvent.user_id == user.id)
        .order_by(SwipeEvent.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await db.execute(stmt)
    events = result.scalars().all()

    return {
        "events": [
            {
                "id": str(e.id),
                "product_id": str(e.product_id),
                "action": e.action.value,
                "dwell_time_ms": e.dwell_time_ms,
                "created_at": e.created_at.isoformat(),
            }
            for e in events
        ],
        "count": len(events),
        "offset": offset,
    }


@router.delete("/queue")
async def clear_queue(
    user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """Clear user's card queue (forces regeneration on next request)."""
    await clear_card_queue(str(user.id))
    return {"message": "Queue cleared"}
