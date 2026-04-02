"""Authentication endpoints."""
from datetime import datetime, timedelta, timezone
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import (
    create_access_token,
    create_refresh_token,
    extract_bearer_token,
    get_db,
    hash_password,
    verify_access_token,
    verify_apple_token,
    verify_password,
    verify_refresh_token,
    get_settings,
)
from app.models import RefreshToken, User
from app.schemas import (
    AppleSignInRequest,
    EmailLoginRequest,
    EmailRegisterRequest,
    RefreshRequest,
    SignOutRequest,
    TokenResponse,
    UserResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/apple", response_model=TokenResponse)
async def sign_in_with_apple(
    request: AppleSignInRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Sign in or register with Apple Sign-In."""
    # Verify Apple identity token
    apple_user_data = await verify_apple_token(request.identity_token)
    if not apple_user_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Apple token",
        )

    apple_id = apple_user_data.get("sub")
    if not apple_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Apple user ID",
        )

    # Find or create user
    stmt = select(User).where(User.apple_id == apple_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        # Create new user
        user = User(
            apple_id=apple_id,
            email=request.user_email,
            display_name=request.user_name,
        )
        db.add(user)
        await db.flush()

    # Create tokens
    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    # Store refresh token
    settings = get_settings()
    refresh_token_expires = datetime.now(timezone.utc) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )
    refresh_token_obj = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=refresh_token_expires,
    )
    db.add(refresh_token_obj)
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/email/register", response_model=TokenResponse)
async def email_register(
    request: EmailRegisterRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Register with email and password."""
    # Check if user exists
    stmt = select(User).where(User.email == request.email)
    result = await db.execute(stmt)
    existing_user = result.scalar_one_or_none()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    # Create new user
    user = User(
        email=request.email,
        hashed_password=hash_password(request.password),
        display_name=request.display_name or request.email.split("@")[0],
    )
    db.add(user)
    await db.flush()

    # Create tokens
    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    settings = get_settings()
    refresh_token_expires = datetime.now(timezone.utc) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )
    refresh_token_obj = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=refresh_token_expires,
    )
    db.add(refresh_token_obj)
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/email/login", response_model=TokenResponse)
async def email_login(
    request: EmailLoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Login with email and password."""
    # Find user
    stmt = select(User).where(User.email == request.email)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or not user.hashed_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # Verify password
    if not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # Create tokens
    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    settings = get_settings()
    refresh_token_expires = datetime.now(timezone.utc) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )
    refresh_token_obj = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=refresh_token_expires,
    )
    db.add(refresh_token_obj)
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(
    request: RefreshRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Refresh access token using refresh token."""
    # Verify refresh token
    user_id = verify_refresh_token(request.refresh_token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    # Check token in database (for revocation)
    stmt = select(RefreshToken).where(
        RefreshToken.token == request.refresh_token,
        RefreshToken.is_revoked is False,
    )
    result = await db.execute(stmt)
    token_record = result.scalar_one_or_none()

    if not token_record or token_record.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token expired or revoked",
        )

    # Create new access token
    access_token = create_access_token(user_id)
    new_refresh_token = create_refresh_token(user_id)

    # Revoke old token and create new one
    token_record.is_revoked = True

    settings = get_settings()
    refresh_token_expires = datetime.now(timezone.utc) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )
    new_token_record = RefreshToken(
        user_id=token_record.user_id,
        token=new_refresh_token,
        expires_at=refresh_token_expires,
    )
    db.add(new_token_record)
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.delete("/account")
async def delete_account(
    db: Annotated[AsyncSession, Depends(get_db)],
    authorization: Annotated[Optional[str], Header()] = None,
) -> dict:
    """Delete user account (soft delete)."""
    # Extract and verify bearer token
    token = extract_bearer_token(authorization)
    user_id = verify_access_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    # Find user
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Mark as inactive (soft delete)
    user.email = None
    user.hashed_password = None
    user.apple_id = None
    await db.commit()

    # Revoke all refresh tokens
    stmt = select(RefreshToken).where(RefreshToken.user_id == user_id)
    result = await db.execute(stmt)
    tokens = result.scalars().all()

    for token_record in tokens:
        token_record.is_revoked = True

    await db.commit()

    return {"message": "Account deleted successfully"}


@router.post("/merge_session")
async def merge_session(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Merge anonymous session with authenticated user."""
    # This endpoint would handle migrating anonymous user data
    # to a newly authenticated user (after sign-up/sign-in)
    return {"message": "Session merged successfully"}
