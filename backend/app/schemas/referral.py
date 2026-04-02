"""Referral system schemas."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ReferralCodeResponse(BaseModel):
    """Referral code response."""

    code: str = Field(..., description="Unique referral code")
    total_referrals: int = Field(default=0, description="Total invites sent")
    successful_referrals: int = Field(default=0, description="Successful conversions")
    current_tier: str = Field(default="none", description="Current reward tier")
    next_tier: Optional[str] = Field(default=None, description="Next tier to unlock")
    referrals_to_next: int = Field(default=0, description="Referrals needed for next tier")
    created_at: datetime

    class Config:
        from_attributes = True


class ReferralStatsResponse(BaseModel):
    """User's referral statistics."""

    code: str
    total_referrals: int
    successful_referrals: int
    current_tier: str
    next_tier: Optional[str]
    referrals_to_next: int


class ApplyReferralCodeRequest(BaseModel):
    """Request to apply referral code during signup."""

    code: str = Field(..., description="Referral code to apply")
    source: str = Field(default="link", description="Source of referral")


class CompleteReferralRequest(BaseModel):
    """Request to mark referral complete."""

    referred_user_id: str = Field(..., description="ID of user who completed onboarding")


class ReferralRewardResponse(BaseModel):
    """Referral reward details."""

    id: str
    user_id: str
    reward_type: str
    milestone_count: int
    granted_at: datetime
    is_active: bool

    class Config:
        from_attributes = True


class LeaderboardEntry(BaseModel):
    """Leaderboard entry."""

    rank: int
    user_id: str
    name: str
    invites: int
    tier: str


class LeaderboardResponse(BaseModel):
    """Leaderboard response."""

    month: Optional[str]
    leaderboard: list[LeaderboardEntry]
    your_rank: Optional[int] = None
    your_invites: Optional[int] = None


class ReferralLinkResponse(BaseModel):
    """Referral shareable link."""

    code: str
    link: str = Field(..., description="Deep link to share")
    qr_code: Optional[str] = Field(default=None, description="QR code as data URI")


class ShareTrackingRequest(BaseModel):
    """Track share event."""

    platform: str = Field(..., description="Platform shared to (instagram, imessage, whatsapp, etc)")


class ReferralResponse(BaseModel):
    """Referral details."""

    id: str
    referrer_id: str
    referred_id: str
    status: str
    referred_completed_onboarding: bool
    source: str
    created_at: datetime
    completed_at: Optional[datetime]

    class Config:
        from_attributes = True


class RewardMilestoneResponse(BaseModel):
    """Reward milestone details."""

    milestone: int = Field(..., description="Number of referrals")
    tier: str = Field(..., description="Tier name")
    reward_type: str = Field(..., description="Type of reward")
    description: str = Field(..., description="Reward description")


MILESTONES = [
    RewardMilestoneResponse(
        milestone=1,
        tier="style_dna",
        reward_type="style_dna_share",
        description="Unlock Style DNA shareable card",
    ),
    RewardMilestoneResponse(
        milestone=3,
        tier="daily_drop",
        reward_type="daily_drop_early",
        description="Early access to Daily Drop (30 min before everyone else)",
    ),
    RewardMilestoneResponse(
        milestone=5,
        tier="founding_member",
        reward_type="founding_member",
        description="Founding Member badge + profile flair",
    ),
    RewardMilestoneResponse(
        milestone=10,
        tier="vip_dresser",
        reward_type="vip_dresser",
        description="VIP Dresser (unlimited drawers, priority notifications)",
    ),
    RewardMilestoneResponse(
        milestone=25,
        tier="ambassador",
        reward_type="ambassador",
        description="Ambassador status (early brand access, exclusive content)",
    ),
]
