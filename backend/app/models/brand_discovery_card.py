"""Brand discovery card model."""

import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum as SQLEnum,
    Float,
    ForeignKey,
    Index,
    JSON,
    String,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class BrandDiscoveryCardStatus(str, Enum):
    """Status enumeration for brand discovery cards."""

    ACTIVE = "active"
    FLAGGED_FOR_REVIEW = "flagged_for_review"
    PAUSED = "paused"


class BrandDiscoveryCard(Base):
    """Brand discovery card model - shows a brand, not a product."""

    __tablename__ = "brand_discovery_cards"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )

    # Card content
    brand_name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(String(1024), nullable=True)
    logo_url: Mapped[str] = mapped_column(String(512), nullable=True)
    aesthetic_tags: Mapped[list[str]] = mapped_column(JSON, nullable=True, default=[])
    price_range_low: Mapped[float] = mapped_column(Float, nullable=True)
    price_range_high: Mapped[float] = mapped_column(Float, nullable=True)

    # Ambassador program details
    ambassador_program_url: Mapped[str] = mapped_column(String(512), nullable=True)
    has_ambassador_program: Mapped[bool] = mapped_column(Boolean, default=False)

    # Performance metrics
    total_views: Mapped[int] = mapped_column(default=0)
    total_likes: Mapped[int] = mapped_column(default=0)
    total_dislikes: Mapped[int] = mapped_column(default=0)
    total_skips: Mapped[int] = mapped_column(default=0)

    # Status tracking
    status: Mapped[BrandDiscoveryCardStatus] = mapped_column(
        SQLEnum(BrandDiscoveryCardStatus),
        default=BrandDiscoveryCardStatus.ACTIVE,
        index=True,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        Index("idx_brand_discovery_card_brand_id", "brand_id"),
        Index("idx_brand_discovery_card_status", "status"),
        Index("idx_brand_discovery_card_is_active", "is_active"),
        Index("idx_brand_discovery_card_created_at", "created_at"),
    )


class BrandDiscoverySwipe(Base):
    """Track user reactions to brand discovery cards."""

    __tablename__ = "brand_discovery_swipes"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    card_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("brand_discovery_cards.id"),
        nullable=False,
        index=True,
    )
    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )

    # Reaction types: 'like', 'dislike', 'skip'
    action: Mapped[str] = mapped_column(String(50), nullable=False, index=True)

    # Optional metadata
    dwell_time_ms: Mapped[int] = mapped_column(default=0)  # How long user viewed card
    session_id: Mapped[str] = mapped_column(String(255), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        Index("idx_brand_discovery_swipe_user_id", "user_id"),
        Index("idx_brand_discovery_swipe_card_id", "card_id"),
        Index("idx_brand_discovery_swipe_brand_id", "brand_id"),
        Index("idx_brand_discovery_swipe_action", "action"),
        Index("idx_brand_discovery_swipe_created_at", "created_at"),
    )
