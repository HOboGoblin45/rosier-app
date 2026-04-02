"""Authentication schemas."""
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class AppleSignInRequest(BaseModel):
    """Apple Sign-In request schema."""

    identity_token: str = Field(..., description="Apple identity token from Sign in with Apple")
    user_email: Optional[str] = None
    user_name: Optional[str] = None


class EmailRegisterRequest(BaseModel):
    """Email registration request schema."""

    email: EmailStr
    password: str = Field(..., min_length=8, description="Password minimum 8 characters")
    display_name: Optional[str] = None


class EmailLoginRequest(BaseModel):
    """Email login request schema."""

    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """Token response schema."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshRequest(BaseModel):
    """Token refresh request schema."""

    refresh_token: str


class SignOutRequest(BaseModel):
    """Sign out request schema."""

    refresh_token: Optional[str] = None
