"""Dresser schemas."""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class DrawerCreate(BaseModel):
    """Dresser drawer creation schema."""

    name: str = Field(..., min_length=1, max_length=255)
    is_default: bool = False


class DrawerUpdate(BaseModel):
    """Dresser drawer update schema."""

    name: Optional[str] = Field(None, min_length=1, max_length=255)
    sort_order: Optional[int] = None


class DrawerResponse(BaseModel):
    """Dresser drawer response schema."""

    id: UUID
    user_id: UUID
    name: str
    sort_order: int
    is_default: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DresserItemAdd(BaseModel):
    """Add item to dresser schema."""

    product_id: UUID
    drawer_id: UUID
    price_at_save: Optional[float] = None


class DresserItemMove(BaseModel):
    """Move item between drawers schema."""

    drawer_id: UUID


class DresserItemResponse(BaseModel):
    """Dresser item response schema."""

    id: UUID
    user_id: UUID
    product_id: UUID
    drawer_id: UUID
    price_at_save: Optional[float] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DresserResponse(BaseModel):
    """Complete dresser response schema."""

    drawers: list[DrawerResponse]
    items: list[DresserItemResponse]


class SharedDrawerResponse(BaseModel):
    """Public shared drawer response schema."""

    drawer_id: UUID
    drawer_name: str
    user_display_name: Optional[str] = None
    item_count: int
    items: list[dict]

    class Config:
        from_attributes = True
