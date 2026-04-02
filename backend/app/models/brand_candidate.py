"""Brand candidate model for brand discovery pipeline."""

import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import Boolean, DateTime, Enum as SQLEnum, Float, Index, JSON, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class BrandCandidateStatus(str, Enum):
    """Status enumeration for brand candidates."""

    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    ACTIVE = "active"
    PAUSED = "paused"


class AffiliateNetworkType(str, Enum):
    """Types of affiliate networks."""

    RAKUTEN = "rakuten"
    IMPACT = "impact"
    AWIN = "awin"
    SKIMLINKS = "skimlinks"
    DIRECT = "direct"
    CUSTOM = "custom"


class BrandCandidate(Base):
    """Brand candidate for onboarding into Rosier discovery system."""

    __tablename__ = "brand_candidates"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )

    # Basic information
    name: Mapped[str] = mapped_column(
        String(255), nullable=False, unique=True, index=True
    )
    website: Mapped[str] = mapped_column(String(512), nullable=True)
    instagram: Mapped[str] = mapped_column(String(255), nullable=True)
    description: Mapped[str] = mapped_column(String(1024), nullable=True)

    # Brand characteristics
    price_range_low: Mapped[float] = mapped_column(Float, nullable=True)
    price_range_high: Mapped[float] = mapped_column(Float, nullable=True)
    aesthetic_tags: Mapped[list[str]] = mapped_column(JSON, nullable=True, default=[])

    # Affiliate/commission info
    affiliate_network: Mapped[AffiliateNetworkType] = mapped_column(
        SQLEnum(AffiliateNetworkType), nullable=True, index=True
    )
    affiliate_publisher_id: Mapped[str] = mapped_column(String(255), nullable=True)
    affiliate_merchant_id: Mapped[str] = mapped_column(String(255), nullable=True)
    commission_rate: Mapped[float] = mapped_column(
        Float, nullable=True
    )  # As decimal (0.08 = 8%)

    # Ambassador program
    has_ambassador_program: Mapped[bool] = mapped_column(Boolean, default=False)
    ambassador_program_url: Mapped[str] = mapped_column(String(512), nullable=True)

    # Evaluation
    status: Mapped[BrandCandidateStatus] = mapped_column(
        SQLEnum(BrandCandidateStatus), default=BrandCandidateStatus.PENDING, index=True
    )
    fit_score: Mapped[float] = mapped_column(
        Float, nullable=True
    )  # 0-100, auto-calculated
    evaluation_notes: Mapped[str] = mapped_column(String(2048), nullable=True)

    # Metadata
    evaluated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    activated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

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
        Index("idx_brand_candidate_status", "status"),
        Index("idx_brand_candidate_created_at", "created_at"),
        Index("idx_brand_candidate_affiliate_network", "affiliate_network"),
    )
