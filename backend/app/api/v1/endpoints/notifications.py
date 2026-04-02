"""Notifications API endpoints."""

import logging
import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import verify_access_token
from app.models import DeviceToken, NotificationLog

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/notifications", tags=["notifications"])


class DeviceTokenRequest(BaseModel):
    """Request to register a device token."""

    token: str
    platform: str  # e.g., "ios", "android"


class NotificationPreference(BaseModel):
    """Notification preferences."""

    price_drops: bool = True
    daily_drops: bool = True
    dresser_updates: bool = True
    sale_events: bool = True


class NotificationHistoryResponse(BaseModel):
    """Notification history item."""

    id: uuid.UUID
    type: str
    title: str
    body: str
    product_id: Optional[uuid.UUID]
    sent_at: datetime
    tapped_at: Optional[datetime]
    dismissed_at: Optional[datetime]


def get_current_user_id(authorization: str = Depends(lambda: None)) -> str:
    """Extract and verify user ID from authorization header."""
    # This is a placeholder - in real implementation, use FastAPI dependencies
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Not authenticated",
    )


async def get_user_id_from_request(request) -> uuid.UUID:
    """Extract user ID from request headers."""
    # In real implementation, this would be injected via Depends
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
        )
    token = auth_header[7:]
    user_id_str = verify_access_token(token)
    if not user_id_str:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )
    try:
        return uuid.UUID(user_id_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user ID format",
        )


@router.post("/device_token")
async def register_device_token(
    request: DeviceTokenRequest,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Register a device token for push notifications.

    Args:
        request: Device token and platform info
        db: Database session

    Returns:
        Success response
    """
    # In production, extract user_id from authenticated request
    # For now, this is a placeholder
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Endpoint requires authentication middleware",
    )


@router.delete("/device_token/{token}")
async def unregister_device_token(
    token: str,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Unregister a device token.

    Args:
        token: Device token to remove
        db: Database session

    Returns:
        Success response
    """
    stmt = select(DeviceToken).where(DeviceToken.token == token)
    result = await db.execute(stmt)
    device_token = result.scalar_one_or_none()

    if not device_token:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device token not found",
        )

    await db.delete(device_token)
    await db.commit()

    return {"message": "Device token unregistered"}


@router.get("/preferences")
async def get_notification_preferences(
    db: AsyncSession = Depends(get_db),
) -> NotificationPreference:
    """
    Get user's notification preferences.

    Returns:
        Current notification preferences
    """
    # Placeholder - requires authentication middleware
    return NotificationPreference()


@router.put("/preferences")
async def update_notification_preferences(
    preferences: NotificationPreference,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Update user's notification preferences.

    Args:
        preferences: Updated preferences
        db: Database session

    Returns:
        Updated preferences
    """
    # Placeholder - requires authentication middleware
    return {"preferences": preferences}


@router.get("/history")
async def get_notification_history(
    page: int = 1,
    size: int = 20,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Get user's notification history.

    Args:
        page: Page number (1-indexed)
        size: Results per page
        db: Database session

    Returns:
        Paginated notification history
    """
    if page < 1 or size < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Page and size must be positive integers",
        )

    offset = (page - 1) * size

    # Placeholder - requires authentication to get user_id
    stmt = select(NotificationLog).offset(offset).limit(size)
    result = await db.execute(stmt)
    notifications = result.scalars().all()

    return {
        "notifications": [
            {
                "id": n.id,
                "type": n.type,
                "title": n.title,
                "body": n.body,
                "product_id": n.product_id,
                "sent_at": n.sent_at,
                "tapped_at": n.tapped_at,
                "dismissed_at": n.dismissed_at,
            }
            for n in notifications
        ],
        "page": page,
        "size": size,
    }


@router.post("/notification/{notification_id}/tap")
async def tap_notification(
    notification_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Mark a notification as tapped.

    Args:
        notification_id: Notification to mark as tapped
        db: Database session

    Returns:
        Updated notification
    """
    stmt = select(NotificationLog).where(NotificationLog.id == notification_id)
    result = await db.execute(stmt)
    notification = result.scalar_one_or_none()

    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    notification.tapped_at = datetime.now(timezone.utc)
    await db.commit()

    return {
        "id": notification.id,
        "type": notification.type,
        "tapped_at": notification.tapped_at,
    }


@router.post("/notification/{notification_id}/dismiss")
async def dismiss_notification(
    notification_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Mark a notification as dismissed.

    Args:
        notification_id: Notification to dismiss
        db: Database session

    Returns:
        Updated notification
    """
    stmt = select(NotificationLog).where(NotificationLog.id == notification_id)
    result = await db.execute(stmt)
    notification = result.scalar_one_or_none()

    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    notification.dismissed_at = datetime.now(timezone.utc)
    await db.commit()

    return {
        "id": notification.id,
        "type": notification.type,
        "dismissed_at": notification.dismissed_at,
    }
