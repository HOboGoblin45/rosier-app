"""Wallpaper house and pattern models for brand partnership system."""
import uuid
from datetime import datetime, timezone
from enum import Enum
from typing import Optional

from sqlalchemy import DateTime, String, Text, Boolean, Index, Float, JSON, ForeignKey, Integer, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class PartnershipStatus(str, Enum):
    """Partnership status with wallpaper houses."""

    PROSPECT = "prospect"
    ACTIVE = "active"
    PAUSED = "paused"
    CHURNED = "churned"


class PatternType(str, Enum):
    """Classification of wallpaper pattern aesthetics."""

    CHINOISERIE = "chinoiserie"
    TEXTURAL = "textural"
    BOLD_PRINT = "bold_print"
    ZOOLOGICAL = "zoological"
    FLORAL = "floral"
    GEOMETRIC = "geometric"


class WallpaperHouse(Base):
    """Wallpaper brand/house for partnership and sponsorship."""

    __tablename__ = "wallpaper_houses"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    slug: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    website_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    logo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)

    # Partnership details
    partnership_status: Mapped[PartnershipStatus] = mapped_column(
        SQLEnum(PartnershipStatus), default=PartnershipStatus.PROSPECT, nullable=False
    )
    monthly_fee: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    contract_start: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    contract_end: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    # Analytics
    impression_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Status
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    patterns: Mapped[list["WallpaperPattern"]] = relationship("WallpaperPattern", back_populates="house")
    impressions: Mapped[list["WallpaperImpression"]] = relationship("WallpaperImpression", back_populates="house")

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        Index("idx_wallpaper_house_slug", "slug"),
        Index("idx_wallpaper_house_status", "partnership_status"),
        Index("idx_wallpaper_house_is_active", "is_active"),
    )


class WallpaperPattern(Base):
    """Individual wallpaper pattern from a house."""

    __tablename__ = "wallpaper_patterns"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    house_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("wallpaper_houses.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    slug: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Pattern characteristics
    pattern_type: Mapped[PatternType] = mapped_column(SQLEnum(PatternType), nullable=False)

    # Color palette (light theme)
    primary_color_light: Mapped[str] = mapped_column(String(7), default="#FFFFFF", nullable=False)  # Hex color
    secondary_color_light: Mapped[Optional[str]] = mapped_column(String(7), nullable=True)

    # Color palette (dark theme)
    primary_color_dark: Mapped[str] = mapped_column(String(7), default="#000000", nullable=False)
    secondary_color_dark: Mapped[Optional[str]] = mapped_column(String(7), nullable=True)

    # Opacity settings (0.0 to 1.0)
    opacity_light: Mapped[float] = mapped_column(Float, default=0.15, nullable=False)
    opacity_dark: Mapped[float] = mapped_column(Float, default=0.1, nullable=False)

    # Style archetype mapping (JSON array of archetype names)
    style_archetypes: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)

    # Asset reference (S3 key or local asset name)
    asset_key: Mapped[str] = mapped_column(String(500), nullable=False)

    # Status and display
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    display_priority: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Relationships
    house: Mapped["WallpaperHouse"] = relationship("WallpaperHouse", back_populates="patterns")
    impressions: Mapped[list["WallpaperImpression"]] = relationship("WallpaperImpression", back_populates="pattern")

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        Index("idx_wallpaper_pattern_house_id", "house_id"),
        Index("idx_wallpaper_pattern_slug", "slug"),
        Index("idx_wallpaper_pattern_is_active", "is_active"),
        Index("idx_wallpaper_pattern_priority", "display_priority"),
    )


class WallpaperImpression(Base):
    """Impression tracking for wallpaper views (for billing/analytics)."""

    __tablename__ = "wallpaper_impressions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    pattern_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("wallpaper_patterns.id"), nullable=False)
    house_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("wallpaper_houses.id"), nullable=False)

    # Session info
    session_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    swipe_position: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Engagement
    dwell_ms: Mapped[int] = mapped_column(Integer, default=0, nullable=False)  # Time viewed in milliseconds

    # Relationships
    pattern: Mapped["WallpaperPattern"] = relationship("WallpaperPattern", back_populates="impressions")
    house: Mapped["WallpaperHouse"] = relationship("WallpaperHouse", back_populates="impressions")

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True
    )

    __table_args__ = (
        Index("idx_wallpaper_impression_user_id", "user_id"),
        Index("idx_wallpaper_impression_pattern_id", "pattern_id"),
        Index("idx_wallpaper_impression_house_id", "house_id"),
        Index("idx_wallpaper_impression_created_at", "created_at"),
    )
