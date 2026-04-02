"""Retailer model."""
import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import Boolean, DateTime, Enum as SQLEnum, Index, String, Float
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class AffiliateNetwork(str, Enum):
    """Affiliate network enumeration."""

    RAKUTEN = "rakuten"
    IMPACT = "impact"
    AWIN = "awin"
    SKIMLINKS = "skimlinks"
    DIRECT = "direct"


class ProductFeedFormat(str, Enum):
    """Product feed format enumeration."""

    CSV = "csv"
    JSON = "json"
    XML = "xml"
    TSV = "tsv"


class Retailer(Base):
    """Retailer model."""

    __tablename__ = "retailers"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    slug: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)

    affiliate_network: Mapped[AffiliateNetwork] = mapped_column(
        SQLEnum(AffiliateNetwork), nullable=False
    )
    affiliate_publisher_id: Mapped[str] = mapped_column(String(255), nullable=True)
    commission_rate: Mapped[float] = mapped_column(Float, nullable=True)
    cookie_window_days: Mapped[int] = mapped_column(default=30)

    product_feed_url: Mapped[str] = mapped_column(String(512), nullable=True)
    product_feed_format: Mapped[ProductFeedFormat] = mapped_column(
        SQLEnum(ProductFeedFormat), nullable=True
    )

    favicon_url: Mapped[str] = mapped_column(String(512), nullable=True)
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
        Index("idx_retailer_slug", "slug"),
        Index("idx_retailer_is_active", "is_active"),
        Index("idx_retailer_affiliate_network", "affiliate_network"),
    )
