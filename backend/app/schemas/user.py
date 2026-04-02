"""User schemas."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class QuizSubmission(BaseModel):
    """Quiz submission schema."""

    responses: dict = Field(..., description="Quiz responses object")


class UserSettings(BaseModel):
    """User settings schema."""

    notifications_enabled: bool = True
    marketing_emails: bool = False
    theme: str = "light"
    currency: str = "USD"


class UserCreate(BaseModel):
    """User creation schema."""

    email: Optional[EmailStr] = None
    password: Optional[str] = None
    display_name: Optional[str] = None
    apple_id: Optional[str] = None


class UserResponse(BaseModel):
    """User response schema."""

    id: UUID
    email: Optional[str] = None
    display_name: Optional[str] = None
    onboarding_completed: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    """User update schema."""

    display_name: Optional[str] = None
    email: Optional[EmailStr] = None
    settings: Optional[UserSettings] = None


class UserDetail(UserResponse):
    """Detailed user schema with additional fields."""

    quiz_responses: Optional[dict] = None
    settings: Optional[UserSettings] = None
