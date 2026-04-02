"""Style DNA schemas."""
from typing import Optional
from uuid import UUID

from pydantic import BaseModel


class StyleDNAStats(BaseModel):
    """Style DNA statistics."""

    total_swipes: int
    likes_count: int
    avg_price_point: float
    top_categories: list[str]
    top_colors: list[str]


class StyleDNAResponse(BaseModel):
    """Style DNA response schema."""

    user_id: UUID
    archetype: Optional[str] = None
    top_brands: Optional[list[str]] = None
    palette: Optional[list[str]] = None
    price_range: Optional[dict] = None
    stats: Optional[StyleDNAStats] = None

    class Config:
        from_attributes = True


class StyleDNAShareResponse(BaseModel):
    """Style DNA share response."""

    share_token: str
    share_url: str
    expires_at: Optional[str] = None
