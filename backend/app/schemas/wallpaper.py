"""Pydantic schemas for wallpaper API endpoints."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class WallpaperHouseBase(BaseModel):
    """Base schema for wallpaper house."""

    name: str = Field(..., min_length=1, max_length=255)
    slug: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=1000)
    website_url: Optional[str] = Field(None, max_length=500)
    logo_url: Optional[str] = Field(None, max_length=500)


class WallpaperHouseCreate(WallpaperHouseBase):
    """Schema for creating a wallpaper house."""

    partnership_status: str = Field(default="prospect")
    monthly_fee: float = Field(default=0.0, ge=0.0)
    contract_start: Optional[datetime] = None
    contract_end: Optional[datetime] = None
    is_active: bool = Field(default=True)


class WallpaperHouseUpdate(BaseModel):
    """Schema for updating a wallpaper house."""

    partnership_status: Optional[str] = None
    monthly_fee: Optional[float] = Field(None, ge=0.0)
    contract_start: Optional[datetime] = None
    contract_end: Optional[datetime] = None
    is_active: Optional[bool] = None


class WallpaperHouseResponse(WallpaperHouseBase):
    """Response schema for wallpaper house."""

    id: UUID
    partnership_status: str
    monthly_fee: float
    contract_start: Optional[datetime] = None
    contract_end: Optional[datetime] = None
    impression_count: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class WallpaperPatternBase(BaseModel):
    """Base schema for wallpaper pattern."""

    name: str = Field(..., min_length=1, max_length=255)
    slug: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=1000)
    pattern_type: str
    primary_color_light: str = Field(default="#FFFFFF")
    secondary_color_light: Optional[str] = None
    primary_color_dark: str = Field(default="#000000")
    secondary_color_dark: Optional[str] = None
    opacity_light: float = Field(default=0.15, ge=0.0, le=1.0)
    opacity_dark: float = Field(default=0.1, ge=0.0, le=1.0)
    style_archetypes: list[str] = Field(default_factory=list)
    asset_key: str = Field(..., min_length=1, max_length=500)
    display_priority: int = Field(default=0, ge=0)


class WallpaperPatternCreate(WallpaperPatternBase):
    """Schema for creating a wallpaper pattern."""

    house_id: UUID
    is_active: bool = Field(default=True)


class WallpaperPatternUpdate(BaseModel):
    """Schema for updating a wallpaper pattern."""

    description: Optional[str] = None
    primary_color_light: Optional[str] = None
    secondary_color_light: Optional[str] = None
    primary_color_dark: Optional[str] = None
    secondary_color_dark: Optional[str] = None
    opacity_light: Optional[float] = Field(None, ge=0.0, le=1.0)
    opacity_dark: Optional[float] = Field(None, ge=0.0, le=1.0)
    style_archetypes: Optional[list[str]] = None
    display_priority: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None


class WallpaperPatternResponse(WallpaperPatternBase):
    """Response schema for wallpaper pattern."""

    id: UUID
    house_id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class WallpaperPatternDetailResponse(WallpaperPatternResponse):
    """Detailed response schema including house information."""

    house: WallpaperHouseResponse


class WallpaperCurrentResponse(BaseModel):
    """Response schema for current wallpaper pattern for user."""

    pattern_id: str
    pattern_name: str
    pattern_type: str
    house_id: str
    house_name: str
    description: Optional[str] = None
    primary_color: str
    secondary_color: Optional[str] = None
    opacity: float
    asset_key: str
    website_url: Optional[str] = None
    logo_url: Optional[str] = None


class WallpaperImpressionRequest(BaseModel):
    """Request schema for recording wallpaper impression."""

    pattern_id: UUID
    dwell_ms: int = Field(..., ge=0)
    session_id: Optional[str] = None
    swipe_position: int = Field(default=0, ge=0)


class WallpaperHouseAnalyticsResponse(BaseModel):
    """Response schema for house-level analytics."""

    house_id: str
    house_name: str
    total_impressions: int
    unique_viewers: int
    avg_dwell_ms: float
    partnership_status: str
    monthly_fee: float
    period_days: int


class WallpaperPatternAnalyticsResponse(BaseModel):
    """Response schema for pattern-level analytics."""

    pattern_id: str
    pattern_name: str
    house_id: str
    house_name: str
    total_impressions: int
    unique_viewers: int
    avg_dwell_ms: float
    pattern_type: str
    period_days: int
