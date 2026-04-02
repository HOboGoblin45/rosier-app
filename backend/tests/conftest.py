"""Pytest configuration and fixtures for backend tests."""
import asyncio
import uuid
from datetime import datetime, timezone, timedelta
from typing import AsyncGenerator, Generator
from unittest.mock import AsyncMock, MagicMock

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from sqlalchemy import event
from sqlalchemy.dialects.sqlite import base

from app.core.database import Base
from app.core.config import Settings
from app.core.security import create_access_token
from app.main import create_app
from app.models import (
    User, Product, Brand, Retailer, SwipeEvent, RefreshToken,
    DresserDrawer, DresserItem
)
from app.models.swipe_event import SwipeAction
from app.models.brand import BrandTier
from app.models.retailer import AffiliateNetwork, ProductFeedFormat

# Patch SQLite compiler to support UUID
def _register_sqlite_uuid():
    """Register UUID support in SQLite compiler."""
    from sqlalchemy.dialects.sqlite import base as sqlite_dialect
    original_init = sqlite_dialect.SQLiteTypeCompiler.__init__

    def patched_init(self, *args, **kwargs):
        original_init(self, *args, **kwargs)

    sqlite_dialect.SQLiteTypeCompiler.visit_UUID = lambda self, type_, **kw: "GUID"

_register_sqlite_uuid()


# Override settings for testing
class TestSettings(Settings):
    """Test settings."""
    DATABASE_URL: str = "sqlite+aiosqlite:///:memory:?check_same_thread=False"
    REDIS_URL: str = "redis://localhost:6379/0"
    ENVIRONMENT: str = "testing"
    JWT_SECRET_KEY: str = "test-secret-key"


@pytest.fixture
def settings() -> TestSettings:
    """Provide test settings."""
    return TestSettings()


@pytest.fixture
def event_loop() -> Generator:
    """Create event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture
async def test_db_engine(settings: TestSettings):
    """Create test database engine."""
    # Use poolclass for in-memory SQLite to avoid connection issues
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=False,
        future=True,
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )

    # Register UUID handling for SQLite
    from sqlalchemy import event

    @event.listens_for(engine.sync_engine, "connect")
    def receive_connect(dbapi_conn, connection_record):
        """Enable UUID support for SQLite."""
        # SQLite doesn't have native UUID, we convert UUIDs to strings
        pass

    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    # Drop all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest_asyncio.fixture
async def db_session(test_db_engine) -> AsyncGenerator[AsyncSession, None]:
    """Provide database session for tests."""
    async_session = sessionmaker(
        test_db_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False
    )

    async with async_session() as session:
        yield session
        await session.rollback()


@pytest.fixture
def mock_redis():
    """Mock Redis client."""
    redis_mock = AsyncMock()
    redis_mock.get = AsyncMock(return_value=None)
    redis_mock.set = AsyncMock(return_value=True)
    redis_mock.delete = AsyncMock(return_value=1)
    redis_mock.incr = AsyncMock(return_value=1)
    redis_mock.expire = AsyncMock(return_value=True)
    return redis_mock


@pytest_asyncio.fixture
async def app(test_db_engine, mock_redis, monkeypatch):
    """Create FastAPI test app."""
    # Override settings
    def get_test_settings():
        return TestSettings()

    # Monkeypatch settings
    monkeypatch.setenv("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
    monkeypatch.setenv("ENVIRONMENT", "testing")

    app = create_app()

    # Override database
    async def get_test_db() -> AsyncGenerator[AsyncSession, None]:
        async_session = sessionmaker(
            test_db_engine,
            class_=AsyncSession,
            expire_on_commit=False,
        )
        async with async_session() as session:
            yield session

    from app.core.database import get_db
    app.dependency_overrides[get_db] = get_test_db

    yield app

    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def client(app) -> AsyncGenerator[AsyncClient, None]:
    """Provide async HTTP test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest_asyncio.fixture
async def sample_retailer(db_session: AsyncSession) -> Retailer:
    """Create a sample retailer."""
    retailer = Retailer(
        id=uuid.uuid4(),
        name="SSENSE",
        slug="ssense",
        affiliate_network=AffiliateNetwork.RAKUTEN,
        affiliate_publisher_id="pub_123",
        commission_rate=0.08,
        product_feed_url="https://ssense.com/feed.xml",
        product_feed_format=ProductFeedFormat.XML,
        favicon_url="https://ssense.com/favicon.ico",
        is_active=True,
    )
    db_session.add(retailer)
    await db_session.commit()
    return retailer


@pytest_asyncio.fixture
async def sample_brand(db_session: AsyncSession) -> Brand:
    """Create a sample brand."""
    brand = Brand(
        id=uuid.uuid4(),
        name="Paloma Wool",
        slug="paloma-wool",
        tier=BrandTier.LUXURY,
        aesthetics={"style": "minimalist", "vibe": "luxury"},
        price_range_low=150.0,
        price_range_high=800.0,
        logo_url="https://example.com/paloma-wool-logo.png",
        website_url="https://palomawood.com",
        is_active=True,
    )
    db_session.add(brand)
    await db_session.commit()
    return brand


@pytest_asyncio.fixture
async def sample_product(
    db_session: AsyncSession,
    sample_retailer: Retailer,
    sample_brand: Brand
) -> Product:
    """Create a sample product."""
    product = Product(
        id=uuid.uuid4(),
        external_id="prod_123",
        retailer_id=sample_retailer.id,
        brand_id=sample_brand.id,
        name="Le Bambino Shoulder Bag",
        description="Luxury shoulder bag made of premium leather",
        category="Bags",
        subcategory="Shoulder Bags",
        current_price=450.0,
        original_price=600.0,
        currency="USD",
        is_on_sale=True,
        sale_end_date=datetime.now(timezone.utc) + timedelta(days=7),
        sizes_available={"size": ["One Size"]},
        colors={"color": ["Black", "Brown"]},
        materials={"material": ["Leather"]},
        image_urls=["https://example.com/img1.jpg", "https://example.com/img2.jpg"],
        product_url="https://ssense.com/product/bambino",
        affiliate_url="https://ssense.com/product/bambino?aff=123",
        tags={"aesthetic": ["minimalist", "luxury"]},
        image_quality_score=0.85,
        is_active=True,
    )
    db_session.add(product)
    await db_session.commit()
    return product


@pytest_asyncio.fixture
async def sample_user(db_session: AsyncSession) -> User:
    """Create a sample user."""
    user = User(
        id=uuid.uuid4(),
        email="test@example.com",
        hashed_password="hashed_password_123",
        display_name="Test User",
        onboarding_completed=True,
        quiz_responses={"style_preference": "minimalist"},
        settings={"notifications": True},
    )
    db_session.add(user)
    await db_session.commit()
    return user


@pytest_asyncio.fixture
async def authenticated_user(db_session: AsyncSession) -> tuple[User, str]:
    """Create a user with valid JWT token."""
    user = User(
        id=uuid.uuid4(),
        email="authenticated@example.com",
        hashed_password="hashed_password_456",
        display_name="Authenticated User",
        onboarding_completed=True,
    )
    db_session.add(user)
    await db_session.commit()

    access_token = create_access_token(str(user.id))
    return user, access_token


@pytest_asyncio.fixture
async def authenticated_client(client: AsyncClient, authenticated_user: tuple[User, str]) -> AsyncClient:
    """Provide authenticated test client."""
    user, token = authenticated_user
    client.headers["Authorization"] = f"Bearer {token}"
    return client


@pytest_asyncio.fixture
async def sample_swipe_event(
    db_session: AsyncSession,
    sample_user: User,
    sample_product: Product
) -> SwipeEvent:
    """Create a sample swipe event."""
    event = SwipeEvent(
        id=uuid.uuid4(),
        user_id=sample_user.id,
        product_id=sample_product.id,
        action=SwipeAction.LIKE,
        dwell_time_ms=2500,
        session_position=1,
        expanded=False,
        session_id="session_123",
    )
    db_session.add(event)
    await db_session.commit()
    return event


@pytest_asyncio.fixture
async def sample_drawer(
    db_session: AsyncSession,
    sample_user: User
) -> DresserDrawer:
    """Create a sample dresser drawer."""
    drawer = DresserDrawer(
        id=uuid.uuid4(),
        user_id=sample_user.id,
        name="Favorites",
        sort_order=0,
        is_default=True,
    )
    db_session.add(drawer)
    await db_session.commit()
    return drawer


@pytest_asyncio.fixture
async def sample_dresser_item(
    db_session: AsyncSession,
    sample_user: User,
    sample_product: Product,
    sample_drawer: DresserDrawer
) -> DresserItem:
    """Create a sample dresser item."""
    item = DresserItem(
        id=uuid.uuid4(),
        user_id=sample_user.id,
        product_id=sample_product.id,
        drawer_id=sample_drawer.id,
        price_at_save=450.0,
    )
    db_session.add(item)
    await db_session.commit()
    return item


@pytest.fixture
def admin_user() -> tuple[uuid.UUID, str]:
    """Create admin user with token."""
    admin_id = uuid.uuid4()
    # Create token with admin claim
    token = create_access_token(str(admin_id))
    return admin_id, token
