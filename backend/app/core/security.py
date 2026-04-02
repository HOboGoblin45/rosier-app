"""Security utilities for JWT tokens, password hashing, and Apple Sign-In."""

import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx
from fastapi import HTTPException, status
from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import get_settings

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(user_id: str, expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token."""
    settings = get_settings()
    to_encode = {"sub": user_id, "type": "access"}

    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM
    )
    return encoded_jwt


def create_refresh_token(user_id: str) -> str:
    """Create a refresh token (opaque token stored in database)."""
    settings = get_settings()
    to_encode = {"sub": user_id, "type": "refresh"}
    expire = datetime.now(timezone.utc) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM
    )
    return encoded_jwt


def verify_access_token(token: str) -> Optional[str]:
    """Verify JWT access token and return user_id."""
    settings = get_settings()
    try:
        payload = jwt.decode(
            token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")

        if user_id is None or token_type != "access":
            return None
        return user_id
    except JWTError:
        return None


def verify_refresh_token(token: str) -> Optional[str]:
    """Verify JWT refresh token and return user_id."""
    settings = get_settings()
    try:
        payload = jwt.decode(
            token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")

        if user_id is None or token_type != "refresh":
            return None
        return user_id
    except JWTError:
        return None


async def verify_apple_token(identity_token: str) -> Optional[dict]:
    """
    Verify Apple Sign-In identity token.
    Returns decoded token claims or None if verification fails.
    """
    settings = get_settings()

    try:
        # Get Apple's public keys
        async with httpx.AsyncClient() as client:
            response = await client.get("https://appleid.apple.com/auth/keys")
            keys_data = response.json()

        # Find the key matching the token's kid header
        from jose import get_unverified_header

        token_header = get_unverified_header(identity_token)
        kid = token_header.get("kid")

        key = next((k for k in keys_data["keys"] if k["kid"] == kid), None)
        if not key:
            return None

        # Verify the token signature
        payload = jwt.decode(
            identity_token,
            key,
            algorithms=["RS256"],
            audience=settings.APPLE_APP_ID,
        )

        # Validate the token subject (user ID)
        if "sub" not in payload:
            return None

        return payload
    except Exception:
        return None


def generate_secure_token(length: int = 32) -> str:
    """Generate a cryptographically secure random token."""
    return secrets.token_urlsafe(length)


def hash_token(token: str) -> str:
    """Hash a token for storage."""
    return hashlib.sha256(token.encode()).hexdigest()


def verify_token_signature(token: str, expected_hash: str) -> bool:
    """Verify a token against its hash."""
    return hmac.compare_digest(hash_token(token), expected_hash)


def extract_bearer_token(authorization: Optional[str]) -> str:
    """
    Extract Bearer token from Authorization header.

    Args:
        authorization: The Authorization header value (e.g., "Bearer <token>")

    Returns:
        The extracted token

    Raises:
        HTTPException: If token is missing or invalid format
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    parts = authorization.split()

    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format. Use: Bearer <token>",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return parts[1]
