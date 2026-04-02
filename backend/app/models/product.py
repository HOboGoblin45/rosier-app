"""Product model."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, Index, JSON, String, UniqueConstraint, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Product(Base):
    """Product model."""

    __tablename__ = "products"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    external_id: Mapped[str] = mapped_column(String(255), nullable=False)
    retailer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("retailers.id"), nullable=False, index=True
    )
    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=True, index=True
    )

    name: Mapped[str] = mapped_column(String(512), nullable=False)
    description: Mapped[str] = mapped_column(String(2048), nullable=True)
    category: Mapped[str] = mapped_column(String(128), nullable=True, index=True)
    subcategory: Mapped[str] = mapped_column(String(128), nullable=True, index=True)

    current_price: Mapped[float] = mapped_column(Float, nullable=False)
    original_price: Mapped[float] = mapped_column(Float, nullable=True)
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    is_on_sale: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    sale_end_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)

    sizes_available: Mapped[dict] = mapped_column(JSON, nullable=True)
    colors: Mapped[dict] = mapped_column(JSON, nullable=True)
    materials: Mapped[dict] = mapped_column(JSON, nullable=True)

    image_urls: Mapped[list[str]] = mapped_column(JSON, nullable=True)
    product_url: Mapped[str] = mapped_column(String(512), nullable=False)
    affiliate_url: Mapped[str] = mapped_column(String(512), nullable=True)

    tags: Mapped[dict] = mapped_column(JSON, nullable=True)
    visual_embedding: Mapped[list[float]] = mapped_column(JSON, nullable=True)
    image_quality_score: Mapped[float] = mapped_column(Float, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    last_price_check: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)

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
        UniqueConstraint("external_id", "retailer_id", name="uq_product_external_id_retailer"),
        Index("idx_product_category", "category"),
        Index("idx_product_subcategory", "subcategory"),
        Index("idx_product_is_active", "is_active"),
        Index("idx_product_is_on_sale", "is_on_sale"),
        Index("idx_product_brand_id", "brand_id"),
        Index("idx_product_created_at", "created_at"),
    )
