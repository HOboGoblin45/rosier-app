"""Application configuration using Pydantic Settings."""

from functools import lru_cache
from typing import List

from pydantic import field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # App metadata
    APP_NAME: str = "Rosier"
    API_V1_PREFIX: str = "/api/v1"
    ENVIRONMENT: str = "development"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/rosier"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Elasticsearch
    ELASTICSEARCH_URL: str = "http://localhost:9200"

    # JWT Security
    JWT_SECRET_KEY: str = "your-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    @field_validator("JWT_SECRET_KEY")
    @classmethod
    def validate_jwt_secret(cls, v: str, info) -> str:
        """Ensure JWT secret is strong in production."""
        if info.data.get("ENVIRONMENT") == "production":
            if len(v) < 32:
                raise ValueError(
                    "JWT_SECRET_KEY must be at least 32 characters long in production"
                )
            if v == "your-secret-key-change-in-production":
                raise ValueError(
                    "JWT_SECRET_KEY must not be the default value in production"
                )
        return v

    # Apple Sign-In
    APPLE_TEAM_ID: str = ""
    APPLE_KEY_ID: str = ""
    APPLE_PRIVATE_KEY: str = ""
    APPLE_APP_ID: str = ""

    # AWS/S3
    AWS_REGION: str = "us-east-1"
    S3_BUCKET: str = "rosier-assets"
    CLOUDFRONT_DOMAIN: str = "https://assets.rosierapp.com"

    # Analytics
    MIXPANEL_TOKEN: str = ""

    # Sentry
    SENTRY_DSN: str = ""

    # APNS (Apple Push Notification Service)
    APNS_KEY_ID: str = ""
    APNS_TEAM_ID: str = ""
    APNS_KEY_PATH: str = ""

    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8100",
    ]

    # Feature flags
    ENABLE_PRICE_MONITORING: bool = True
    ENABLE_PERSONALIZATION: bool = True
    ENABLE_ANALYTICS: bool = True

    class Config:
        """Pydantic config."""

        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
