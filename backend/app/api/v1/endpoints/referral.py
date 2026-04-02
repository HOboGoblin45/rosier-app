"""Referral system endpoints."""
import logging
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import get_db, verify_access_token, extract_bearer_token
from app.models import User
from app.schemas.referral import (
    ApplyReferralCodeRequest,
    CompleteReferralRequest,
    LeaderboardResponse,
    LeaderboardEntry,
    ReferralCodeResponse,
    ReferralLinkResponse,
    ReferralRewardResponse,
    ReferralStatsResponse,
    ShareTrackingRequest,
    MILESTONES,
)
from app.services import ReferralService
from app.services.email_sequences import EmailSequenceService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/referral", tags=["referral"])


async def get_current_user(
    db: Annotated[AsyncSession, Depends(get_db)],
    authorization: Annotated[Optional[str], Header()] = None,
) -> User:
    """Get current authenticated user from Bearer token."""
    # Extract and verify bearer token
    token = extract_bearer_token(authorization)
    user_id = verify_access_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    return user


@router.get("/code", response_model=ReferralCodeResponse)
async def get_or_create_referral_code(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReferralCodeResponse:
    """Get or create user's referral code.

    Returns user's referral code and basic stats.
    """
    code = await ReferralService.create_referral_code(db, user.id)

    stats = await ReferralService.get_referral_stats(db, user.id)

    return ReferralCodeResponse(
        code=code.code,
        total_referrals=code.total_referrals,
        successful_referrals=stats["successful_referrals"],
        current_tier=stats["current_tier"],
        next_tier=stats["next_tier"],
        referrals_to_next=stats["referrals_to_next"],
        created_at=code.created_at,
    )


@router.get("/stats", response_model=ReferralStatsResponse)
async def get_referral_stats(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReferralStatsResponse:
    """Get user's referral statistics.

    Returns referral code, counts, current tier, and progress to next tier.
    """
    stats = await ReferralService.get_referral_stats(db, user.id)
    return ReferralStatsResponse(**stats)


@router.post("/apply")
async def apply_referral_code(
    request: ApplyReferralCodeRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    authorization: Annotated[Optional[str], Header()] = None,
) -> dict:
    """Apply referral code during signup.

    Args:
        request: Referral code to apply
        db: Database session
        authorization: Authorization header with Bearer token

    Returns:
        Success status and reward info
    """
    token = extract_bearer_token(authorization)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )

    user_id = verify_access_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )

    # Process referral
    referral = await ReferralService.process_referral(
        db,
        UUID(user_id),
        request.code.upper(),
        source=request.source,
    )

    if not referral:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid referral code",
        )

    return {
        "success": True,
        "message": "Referral code applied successfully",
        "referral_id": str(referral.id),
    }


@router.post("/complete")
async def complete_referral(
    request: CompleteReferralRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Mark referral as complete (backend call).

    Called when referred user completes onboarding.

    Args:
        request: Referred user ID
        db: Database session

    Returns:
        Completion status and any new reward
    """
    try:
        referred_user_id = UUID(request.referred_user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID",
        )

    reward = await ReferralService.complete_referral(db, referred_user_id)

    # Get referred user for email
    stmt = select(User).where(User.id == referred_user_id)
    result = await db.execute(stmt)
    referred_user = result.scalar_one_or_none()

    # Trigger emails if reward granted
    if reward:
        referral = await ReferralService.complete_referral(db, referred_user_id)

        await EmailSequenceService.trigger_referral_milestone(
            db,
            referred_user_id,
            reward.reward_type,
            reward.milestone_count,
        )

    return {
        "success": True,
        "message": "Referral completed",
        "reward_granted": reward is not None,
        "reward": {
            "id": str(reward.id),
            "type": reward.reward_type,
            "milestone": reward.milestone_count,
        } if reward else None,
    }


@router.get("/rewards", response_model=list[ReferralRewardResponse])
async def get_user_rewards(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ReferralRewardResponse]:
    """Get user's earned rewards.

    Returns list of unlocked reward tiers.
    """
    from app.models import ReferralReward

    stmt = select(ReferralReward).where(ReferralReward.user_id == user.id)
    result = await db.execute(stmt)
    rewards = result.scalars().all()

    return [ReferralRewardResponse.from_orm(r) for r in rewards]


@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    limit: int = 20,
    month: Optional[str] = None,
) -> LeaderboardResponse:
    """Get top referrers leaderboard.

    Args:
        user: Current user
        db: Database session
        limit: Number of top referrers to return (default 20)
        month: Optional month filter (YYYY-MM format)

    Returns:
        Leaderboard with user's rank
    """
    leaderboard_entries = await ReferralService.get_leaderboard(db, limit, month)

    # Get user's stats
    user_stats = await ReferralService.get_referral_stats(db, user.id)
    user_rank = None

    # Find user in leaderboard
    for entry in leaderboard_entries:
        if entry["user_id"] == str(user.id):
            user_rank = entry["rank"]
            break

    return LeaderboardResponse(
        month=month,
        leaderboard=[LeaderboardEntry(**entry) for entry in leaderboard_entries],
        your_rank=user_rank,
        your_invites=user_stats["successful_referrals"],
    )


@router.post("/share")
async def track_share(
    request: ShareTrackingRequest,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Track share event for analytics.

    Args:
        request: Platform shared to
        user: Current user
        db: Database session

    Returns:
        Success status
    """
    await ReferralService.track_share(db, user.id, request.platform)

    return {
        "success": True,
        "message": f"Share tracked to {request.platform}",
    }


@router.get("/link", response_model=ReferralLinkResponse)
async def get_referral_link(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReferralLinkResponse:
    """Get shareable referral deep link.

    Returns the referral code and deep link for sharing.
    """
    code = await ReferralService.create_referral_code(db, user.id)

    # Build deep link
    link = f"https://rosier.app/invite/{code.code}"

    return ReferralLinkResponse(
        code=code.code,
        link=link,
    )


@router.get("/milestones")
async def get_reward_milestones() -> dict:
    """Get all reward milestones.

    Returns information about each referral tier and reward.
    """
    return {
        "milestones": MILESTONES,
        "description": "Referral reward tiers - unlock features by inviting friends",
    }


@router.get("/validate/{code}")
async def validate_referral_code(
    code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Validate referral code (public endpoint).

    Used during signup to show referrer info.

    Args:
        code: Referral code to validate
        db: Database session

    Returns:
        Code validity and referrer info
    """
    from app.models import ReferralCode

    stmt = select(ReferralCode).where(ReferralCode.code == code.upper())
    result = await db.execute(stmt)
    referral_code = result.scalar_one_or_none()

    if not referral_code or not referral_code.is_active:
        return {
            "valid": False,
            "message": "Invalid or inactive code",
        }

    # Get referrer info
    stmt = select(User).where(User.id == referral_code.user_id)
    result = await db.execute(stmt)
    referrer = result.scalar_one_or_none()

    if not referrer:
        return {
            "valid": False,
            "message": "Referrer not found",
        }

    return {
        "valid": True,
        "referrer": {
            "id": str(referrer.id),
            "name": referrer.display_name,
        },
        "referral_count": referral_code.successful_referrals,
        "current_tier": referral_code.current_tier,
    }
