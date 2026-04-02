"""Database configuration and session management."""
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, create_async_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.core.config import get_settings

# Declarative base for all models
Base = declarative_base()


def get_engine() -> AsyncEngine:
    """Create async SQLAlchemy engine."""
    settings = get_settings()
    return create_async_engine(
        settings.DATABASE_URL,
        echo=settings.ENVIRONMENT == "development",
        future=True,
        pool_size=20,
        max_overflow=0,
        pool_pre_ping=True,
        pool_recycle=3600,
    )


def get_session_factory(engine: AsyncEngine):
    """Create async sessionmaker factory."""
    return sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False, autocommit=False
    )


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to get database session."""
    engine = get_engine()
    async_session = get_session_factory(engine)

    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db(engine: AsyncEngine) -> None:
    """Create all tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def drop_db(engine: AsyncEngine) -> None:
    """Drop all tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
