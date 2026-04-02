"""Commission tracking model."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Commission(Base):
    """Track commission earnings per brand per sale."""

    __tablename__ = "commissions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )

    # Relationships
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id"), nullable=False, index=True
    )
    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    retailer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("retailers.id"), nullable=False, index=True
    )

    # Commission details
    product_price: Mapped[float] = mapped_column(Float, nullable=False)
    commission_rate: Mapped[float] = mapped_column(
        Float, nullable=False
    )  # As decimal (0.08 = 8%)
    commission_amount: Mapped[float] = mapped_column(Float, nullable=False)

    # Tracking
    affiliate_link_used: Mapped[str] = mapped_column(String(512), nullable=True)
    click_timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    conversion_timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Status
    is_pending: Mapped[bool] = mapped_column(
        Boolean, default=True, index=True
    )  # Awaiting conversion confirmation
    is_confirmed: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    is_rejected: Mapped[bool] = mapped_column(Boolean, default=False, index=True)

    rejection_reason: Mapped[str] = mapped_column(String(512), nullable=True)

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
        Index("idx_commission_user_id", "user_id"),
        Index("idx_commission_brand_id", "brand_id"),
        Index("idx_commission_product_id", "product_id"),
        Index("idx_commission_retailer_id", "retailer_id"),
        Index("idx_commission_is_pending", "is_pending"),
        Index("idx_commission_is_confirmed", "is_confirmed"),
        Index("idx_commission_created_at", "created_at"),
    )
