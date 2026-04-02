"""Onboarding endpoints."""
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import get_db, verify_access_token, extract_bearer_token
from app.models import User
from app.schemas import QuizSubmission, UserResponse
from app.services import CardQueueService

router = APIRouter(prefix="/onboarding", tags=["onboarding"])


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


@router.post("/quiz")
async def submit_quiz(
    submission: QuizSubmission,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Submit onboarding quiz and generate initial card queue."""
    # Store quiz responses
    user.quiz_responses = submission.responses
    user.onboarding_completed = True

    await db.flush()

    # Generate initial card queue
    preferences = {
        "preferred_categories": submission.responses.get("preferred_categories", []),
        "preferred_subcategories": submission.responses.get("preferred_subcategories", []),
        "preferred_tags": submission.responses.get("preferred_tags", {}),
        "price_point": submission.responses.get("price_point", 50.0),
    }

    queue = await CardQueueService.get_or_generate_queue(
        db,
        str(user.id),
        user_preferences=preferences,
        force_regenerate=True,
    )

    await db.commit()

    return {
        "message": "Quiz submitted successfully",
        "onboarding_completed": True,
        "queue_size": len(queue),
    }


@router.get("/status")
async def onboarding_status(
    user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """Get user's onboarding status."""
    return {
        "user_id": str(user.id),
        "onboarding_completed": user.onboarding_completed,
        "quiz_responses": user.quiz_responses,
    }
