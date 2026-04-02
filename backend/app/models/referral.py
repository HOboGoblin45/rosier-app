"""Referral system models."""
import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import DateTime, String, Boolean, Integer, Index, ForeignKey, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class ReferralTier(str, Enum):
    """Referral reward tiers."""

    NONE = "none"
    STYLE_DNA = "style_dna"  # 1 referral
    DAILY_DROP = "daily_drop"  # 3 referrals
    FOUNDING_MEMBER = "founding_member"  # 5 referrals
    VIP_DRESSER = "vip_dresser"  # 10 referrals
    AMBASSADOR = "ambassador"  # 25 referrals


class ReferralStatus(str, Enum):
    """Status of a referral."""

    PENDING = "pending"
    COMPLETED = "completed"
    EXPIRED = "expired"


class ReferralSource(str, Enum):
    """Source where referral code was shared."""

    IMESSAGE = "imessage"
    WHATSAPP = "whatsapp"
    INSTAGRAM = "instagram"
    EMAIL = "email"
    LINK = "link"
    OTHER = "other"


class RewardType(str, Enum):
    """Types of rewards."""

    STYLE_DNA_SHARE = "style_dna_share"
    DAILY_DROP_EARLY = "daily_drop_early"
    FOUNDING_MEMBER = "founding_member"
    VIP_DRESSER = "vip_dresser"
    AMBASSADOR = "ambassador"


class ReferralCode(Base):
    """User referral code."""

    __tablename__ = "referral_codes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    code: Mapped[str] = mapped_column(String(20), unique=True, nullable=False, index=True)
    total_referrals: Mapped[int] = mapped_column(Integer, default=0)
    successful_referrals: Mapped[int] = mapped_column(Integer, default=0)
    current_tier: Mapped[str] = mapped_column(String(50), default=ReferralTier.NONE.value)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
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
        Index("idx_referral_code_user_id", "user_id"),
        Index("idx_referral_code_code", "code"),
        Index("idx_referral_code_is_active", "is_active"),
    )


class Referral(Base):
    """Individual referral tracking."""

    __tablename__ = "referrals"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    referrer_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    referred_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    referral_code_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("referral_codes.id"), nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(50), default=ReferralStatus.PENDING.value)
    referred_completed_onboarding: Mapped[bool] = mapped_column(Boolean, default=False)
    reward_granted: Mapped[bool] = mapped_column(Boolean, default=False)
    source: Mapped[str] = mapped_column(String(50), default=ReferralSource.OTHER.value)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_referral_referrer_id", "referrer_id"),
        Index("idx_referral_referred_id", "referred_id"),
        Index("idx_referral_status", "status"),
        Index("idx_referral_created_at", "created_at"),
    )


class ReferralReward(Base):
    """Reward unlock tracking."""

    __tablename__ = "referral_rewards"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    reward_type: Mapped[str] = mapped_column(String(50), nullable=False)
    milestone_count: Mapped[int] = mapped_column(Integer, nullable=False)  # 1, 3, 5, 10, 25
    granted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    __table_args__ = (
        Index("idx_referral_reward_user_id", "user_id"),
        Index("idx_referral_reward_type", "reward_type"),
        Index("idx_referral_reward_milestone", "milestone_count"),
    )


class ReferralShare(Base):
    """Track share events for analytics."""

    __tablename__ = "referral_shares"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    referral_code_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("referral_codes.id"), nullable=False, index=True)
    platform: Mapped[str] = mapped_column(String(50), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )

    __table_args__ = (
        Index("idx_referral_share_user_id", "user_id"),
        Index("idx_referral_share_platform", "platform"),
        Index("idx_referral_share_created_at", "created_at"),
    )
