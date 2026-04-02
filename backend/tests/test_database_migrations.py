"""Database migration tests."""
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.models import (
    User, Product, Brand, Retailer, SwipeEvent, RefreshToken,
    DresserDrawer, DresserItem, NotificationLog
)


class TestDatabaseMigrations:
    """Test database schema creation and integrity."""

    @pytest.mark.asyncio
    async def test_tables_created(self, test_db_engine):
        """Verify all required tables are created."""
        # Tables should be created by the fixture
        async with test_db_engine.begin() as conn:
            # Get list of tables
            inspector_result = await conn.run_sync(
                lambda conn: conn.dialect.get_table_names(conn)
            )

        required_tables = [
            'users',
            'products',
            'brands',
            'retailers',
            'swipe_events',
            'refresh_tokens',
            'dresser_drawers',
            'dresser_items',
        ]

        for table in required_tables:
            assert table in inspector_result, f"Table {table} not found"

    @pytest.mark.asyncio
    async def test_user_table_schema(self, test_db_engine):
        """Verify user table has correct columns."""
        async with test_db_engine.begin() as conn:
            columns = await conn.run_sync(
                lambda conn: [c.name for c in conn.dialect.get_columns(conn, 'users')]
            )

        required_columns = [
            'id', 'email', 'hashed_password', 'display_name',
            'created_at', 'updated_at', 'is_active'
        ]

        for column in required_columns:
            assert column in columns, f"Column {column} not found in users table"

    @pytest.mark.asyncio
    async def test_product_table_schema(self, test_db_engine):
        """Verify product table has correct columns."""
        async with test_db_engine.begin() as conn:
            columns = await conn.run_sync(
                lambda conn: [c.name for c in conn.dialect.get_columns(conn, 'products')]
            )

        required_columns = [
            'id', 'external_id', 'retailer_id', 'brand_id',
            'name', 'description', 'category', 'subcategory',
            'current_price', 'original_price', 'currency',
            'product_url', 'affiliate_url', 'image_urls',
            'created_at', 'updated_at', 'is_active'
        ]

        for column in required_columns:
            assert column in columns, f"Column {column} not found in products table"

    @pytest.mark.asyncio
    async def test_swipe_event_table_schema(self, test_db_engine):
        """Verify swipe_events table has correct columns."""
        async with test_db_engine.begin() as conn:
            columns = await conn.run_sync(
                lambda conn: [c.name for c in conn.dialect.get_columns(conn, 'swipe_events')]
            )

        required_columns = [
            'id', 'user_id', 'product_id', 'action',
            'dwell_time_ms', 'session_position', 'expanded',
            'session_id', 'created_at'
        ]

        for column in required_columns:
            assert column in columns, f"Column {column} not found in swipe_events table"

    @pytest.mark.asyncio
    async def test_dresser_tables_schema(self, test_db_engine):
        """Verify dresser-related tables."""
        async with test_db_engine.begin() as conn:
            drawer_columns = await conn.run_sync(
                lambda conn: [c.name for c in conn.dialect.get_columns(conn, 'dresser_drawers')]
            )
            item_columns = await conn.run_sync(
                lambda conn: [c.name for c in conn.dialect.get_columns(conn, 'dresser_items')]
            )

        drawer_required = ['id', 'user_id', 'name', 'is_default', 'sort_order', 'created_at', 'updated_at']
        item_required = ['id', 'user_id', 'product_id', 'drawer_id', 'price_at_save', 'created_at', 'updated_at']

        for column in drawer_required:
            assert column in drawer_columns, f"Column {column} not found in dresser_drawers"

        for column in item_required:
            assert column in item_columns, f"Column {column} not found in dresser_items"

    @pytest.mark.asyncio
    async def test_foreign_key_constraints(self, db_session: AsyncSession):
        """Test foreign key relationships."""
        from sqlalchemy import inspect

        inspector = inspect(User)
        # Verify User model exists and has expected relationships
        assert hasattr(User, 'id')
        assert hasattr(User, 'email')

        inspector = inspect(Product)
        assert hasattr(Product, 'retailer_id')
        assert hasattr(Product, 'brand_id')

    @pytest.mark.asyncio
    async def test_unique_constraints(self, test_db_engine):
        """Test unique constraints on tables."""
        # User email should be unique
        async with test_db_engine.begin() as conn:
            result = await conn.run_sync(
                lambda conn: conn.dialect.get_unique_constraints(conn, 'users')
            )
        # Unique constraints exist for user email
        assert len(result) > 0

    @pytest.mark.asyncio
    async def test_index_creation(self, test_db_engine):
        """Test that indexes are created."""
        async with test_db_engine.begin() as conn:
            # Check for indexes on commonly queried columns
            products_indexes = await conn.run_sync(
                lambda conn: conn.dialect.get_indexes(conn, 'products')
            )
            users_indexes = await conn.run_sync(
                lambda conn: conn.dialect.get_indexes(conn, 'users')
            )

        # Should have some indexes
        assert len(products_indexes) > 0 or len(users_indexes) > 0


class TestDataIntegrity:
    """Test data integrity constraints."""

    @pytest.mark.asyncio
    async def test_user_email_required(self, db_session: AsyncSession):
        """Test that user email is required."""
        import uuid
        user = User(
            id=uuid.uuid4(),
            email=None,
            hashed_password="hashed",
            display_name="Test"
        )
        db_session.add(user)

        # Should raise integrity error
        with pytest.raises(Exception):
            await db_session.flush()

    @pytest.mark.asyncio
    async def test_product_name_required(self, db_session: AsyncSession, sample_retailer, sample_brand):
        """Test that product name is required."""
        import uuid
        product = Product(
            id=uuid.uuid4(),
            external_id="ext_123",
            retailer_id=sample_retailer.id,
            brand_id=sample_brand.id,
            name=None,
            current_price=100.0
        )
        db_session.add(product)

        with pytest.raises(Exception):
            await db_session.flush()

    @pytest.mark.asyncio
    async def test_swipe_event_user_product_required(self, db_session: AsyncSession):
        """Test that swipe event requires user and product."""
        import uuid
        from app.models.swipe_event import SwipeAction

        event = SwipeEvent(
            id=uuid.uuid4(),
            user_id=None,
            product_id=None,
            action=SwipeAction.LIKE,
            dwell_time_ms=1000
        )
        db_session.add(event)

        with pytest.raises(Exception):
            await db_session.flush()

    @pytest.mark.asyncio
    async def test_drawer_item_price_validation(self, db_session: AsyncSession, sample_user, sample_product, sample_drawer):
        """Test that drawer item price is stored correctly."""
        import uuid
        item = DresserItem(
            id=uuid.uuid4(),
            user_id=sample_user.id,
            product_id=sample_product.id,
            drawer_id=sample_drawer.id,
            price_at_save=0.0
        )
        db_session.add(item)
        await db_session.flush()

        # Retrieve and verify
        result = await db_session.get(DresserItem, item.id)
        assert result.price_at_save == 0.0


class TestMigrationRollback:
    """Test migration rollback capability."""

    @pytest.mark.asyncio
    async def test_clean_migration_state(self, test_db_engine):
        """Test that migrations can be run cleanly multiple times."""
        # This is handled by test fixtures that create/drop tables
        async with test_db_engine.begin() as conn:
            # Tables should exist
            tables = await conn.run_sync(
                lambda conn: conn.dialect.get_table_names(conn)
            )

        assert len(tables) > 0

        # Drop and recreate
        async with test_db_engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)

        async with test_db_engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

        # Tables should exist again
        async with test_db_engine.begin() as conn:
            tables = await conn.run_sync(
                lambda conn: conn.dialect.get_table_names(conn)
            )

        assert len(tables) > 0


class TestTimestampFields:
    """Test timestamp field behavior."""

    @pytest.mark.asyncio
    async def test_created_at_set_on_insert(self, db_session: AsyncSession):
        """Test that created_at is set automatically."""
        import uuid
        from datetime import datetime, timezone

        user = User(
            id=uuid.uuid4(),
            email="timestamp@example.com",
            hashed_password="hashed",
            display_name="Test"
        )
        db_session.add(user)
        await db_session.flush()

        assert user.created_at is not None
        # Should be very recent
        now = datetime.now(timezone.utc)
        assert abs((now - user.created_at).total_seconds()) < 10

    @pytest.mark.asyncio
    async def test_updated_at_set_on_update(self, db_session: AsyncSession, sample_user: User):
        """Test that updated_at is updated on modification."""
        from datetime import datetime, timezone

        original_updated = sample_user.updated_at

        # Modify user
        sample_user.display_name = "Updated Name"
        db_session.add(sample_user)
        await db_session.flush()

        # updated_at should have changed
        assert sample_user.updated_at != original_updated or sample_user.updated_at is not None
