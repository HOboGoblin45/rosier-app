"""Brand model."""
import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import Boolean, DateTime, Enum as SQLEnum, Index, JSON, String, Float
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class BrandTier(str, Enum):
    """Brand tier enumeration."""

    LUXURY = "luxury"
    PREMIUM = "premium"
    CONTEMPORARY = "contemporary"
    FAST_FASHION = "fast_fashion"
    INDIE = "indie"


class Brand(Base):
    """Brand model."""

    __tablename__ = "brands"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    slug: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    tier: Mapped[BrandTier] = mapped_column(SQLEnum(BrandTier), nullable=False)

    aesthetics: Mapped[dict] = mapped_column(JSON, nullable=True)
    price_range_low: Mapped[float] = mapped_column(Float, nullable=True)
    price_range_high: Mapped[float] = mapped_column(Float, nullable=True)

    logo_url: Mapped[str] = mapped_column(String(512), nullable=True)
    website_url: Mapped[str] = mapped_column(String(512), nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)

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
        Index("idx_brand_slug", "slug"),
        Index("idx_brand_is_active", "is_active"),
        Index("idx_brand_tier", "tier"),
    )
