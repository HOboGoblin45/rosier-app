"""Swipe event schemas."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.swipe_event import SwipeAction


class SwipeEventCreate(BaseModel):
    """Swipe event creation schema."""

    product_id: UUID
    action: SwipeAction
    dwell_time_ms: Optional[int] = None
    session_position: Optional[int] = None
    expanded: bool = False
    session_id: Optional[str] = None


class SwipeEventBatch(BaseModel):
    """Batch swipe events submission schema."""

    events: list[SwipeEventCreate] = Field(..., min_items=1, max_items=100)
    session_id: Optional[str] = None


class SwipeEventResponse(BaseModel):
    """Swipe event response schema."""

    id: UUID
    user_id: UUID
    product_id: UUID
    action: SwipeAction
    dwell_time_ms: Optional[int] = None
    session_position: Optional[int] = None
    expanded: bool
    session_id: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
