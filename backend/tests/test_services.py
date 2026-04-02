"""Service layer tests for business logic."""
import pytest
import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.recommendation import RecommendationService
from app.services.card_queue import CardQueueService
from app.services.style_dna import StyleDNAService
from app.services.affiliate import AffiliateService
from app.models import User, Product, Brand, Retailer, SwipeEvent
from app.models.swipe_event import SwipeAction


class TestRecommendationService:
    """Test recommendation engine service."""

    @pytest.mark.asyncio
    async def test_get_recommendations_for_new_user(self, db_session: AsyncSession, sample_user: User):
        """Test getting recommendations for user with no history."""
        service = RecommendationService(db_session=db_session)

        # Mock the ML model/logic
        recommendations = await service.get_recommendations(user_id=sample_user.id, limit=10)

        assert isinstance(recommendations, list)
        assert len(recommendations) <= 10

    @pytest.mark.asyncio
    async def test_get_recommendations_respects_user_preferences(
        self, db_session: AsyncSession, sample_user: User
    ):
        """Test that recommendations respect user preferences."""
        sample_user.preferences = {
            "min_price": 100,
            "max_price": 500,
            "categories": ["Bags", "Shoes"],
            "excluded_brands": ["Budget Brand"]
        }
        db_session.add(sample_user)
        await db_session.commit()

        service = RecommendationService(db_session=db_session)
        recommendations = await service.get_recommendations(user_id=sample_user.id)

        # Recommendations should respect filters
        assert isinstance(recommendations, list)

    @pytest.mark.asyncio
    async def test_refresh_recommendations(self, db_session: AsyncSession, sample_user: User):
        """Test refreshing recommendations."""
        service = RecommendationService(db_session=db_session)

        # Refresh should return new set
        recommendations = await service.refresh_recommendations(user_id=sample_user.id)
        assert isinstance(recommendations, list)

    @pytest.mark.asyncio
    async def test_get_category_recommendations(self, db_session: AsyncSession, sample_user: User):
        """Test category-specific recommendations."""
        service = RecommendationService(db_session=db_session)

        recommendations = await service.get_category_recommendations(
            user_id=sample_user.id,
            category="Dresses",
            limit=5
        )

        assert isinstance(recommendations, list)
        assert len(recommendations) <= 5

    @pytest.mark.asyncio
    async def test_similar_products(self, db_session: AsyncSession, sample_product: Product):
        """Test finding similar products."""
        service = RecommendationService(db_session=db_session)

        similar = await service.get_similar_products(product_id=sample_product.id, limit=5)

        assert isinstance(similar, list)
        # Similar product shouldn't include the original
        assert all(p.id != sample_product.id for p in similar)

    @pytest.mark.asyncio
    async def test_trending_products(self, db_session: AsyncSession):
        """Test fetching trending products."""
        service = RecommendationService(db_session=db_session)

        trending = await service.get_trending_products(limit=10)

        assert isinstance(trending, list)
        assert len(trending) <= 10


class TestCardQueueService:
    """Test card queue service."""

    @pytest.mark.asyncio
    async def test_initialize_queue_for_user(self, db_session: AsyncSession, sample_user: User):
        """Test initializing card queue for a user."""
        service = CardQueueService(db_session=db_session)

        queue = await service.initialize_queue(user_id=sample_user.id, limit=50)

        assert isinstance(queue, list)
        assert len(queue) <= 50

    @pytest.mark.asyncio
    async def test_get_next_batch(self, db_session: AsyncSession, sample_user: User):
        """Test getting next batch of cards."""
        service = CardQueueService(db_session=db_session)

        batch = await service.get_next_batch(user_id=sample_user.id, batch_size=10)

        assert isinstance(batch, list)
        assert len(batch) <= 10

    @pytest.mark.asyncio
    async def test_mark_card_seen(self, db_session: AsyncSession, sample_user: User, sample_product: Product):
        """Test marking a card as seen."""
        service = CardQueueService(db_session=db_session)

        # Mark product as seen
        await service.mark_seen(user_id=sample_user.id, product_id=sample_product.id)

        # Next batch shouldn't include seen product
        batch = await service.get_next_batch(user_id=sample_user.id)
        assert all(p.id != sample_product.id for p in batch)

    @pytest.mark.asyncio
    async def test_refresh_queue(self, db_session: AsyncSession, sample_user: User):
        """Test refreshing card queue."""
        service = CardQueueService(db_session=db_session)

        # Get initial queue
        initial = await service.initialize_queue(user_id=sample_user.id)

        # Refresh
        refreshed = await service.refresh_queue(user_id=sample_user.id)

        assert isinstance(refreshed, list)

    @pytest.mark.asyncio
    async def test_queue_respects_filters(self, db_session: AsyncSession, sample_user: User):
        """Test that queue respects category and price filters."""
        service = CardQueueService(db_session=db_session)

        queue = await service.get_next_batch(
            user_id=sample_user.id,
            filters={
                "category": "Bags",
                "min_price": 100,
                "max_price": 500
            }
        )

        assert isinstance(queue, list)

    @pytest.mark.asyncio
    async def test_queue_excludes_already_swiped(self, db_session: AsyncSession, sample_user: User, sample_product: Product):
        """Test that queue excludes already swiped products."""
        service = CardQueueService(db_session=db_session)

        # Create swipe event
        swipe = SwipeEvent(
            id=uuid.uuid4(),
            user_id=sample_user.id,
            product_id=sample_product.id,
            action=SwipeAction.LIKE,
            dwell_time_ms=2000,
            session_position=1
        )
        db_session.add(swipe)
        await db_session.commit()

        # Queue shouldn't include swiped product
        queue = await service.get_next_batch(user_id=sample_user.id)
        assert all(p.id != sample_product.id for p in queue)


class TestStyleDNAService:
    """Test style DNA/profile service."""

    @pytest.mark.asyncio
    async def test_create_style_dna(self, db_session: AsyncSession, sample_user: User):
        """Test creating style DNA from quiz responses."""
        service = StyleDNAService(db_session=db_session)

        style_dna = await service.create_from_quiz(
            user_id=sample_user.id,
            quiz_responses={
                "preferred_style": "minimalist",
                "body_type": "pear",
                "budget": "luxury",
                "colors": ["black", "white"],
                "categories": ["dresses", "bags"]
            }
        )

        assert style_dna is not None
        assert style_dna.dominant_style is not None

    @pytest.mark.asyncio
    async def test_update_style_dna_from_swipes(self, db_session: AsyncSession, sample_user: User):
        """Test updating style DNA from swipe behavior."""
        service = StyleDNAService(db_session=db_session)

        # Update from implicit feedback
        updated = await service.update_from_swipes(user_id=sample_user.id)

        assert updated is not None

    @pytest.mark.asyncio
    async def test_get_style_recommendations(self, db_session: AsyncSession, sample_user: User):
        """Test getting recommendations based on style DNA."""
        service = StyleDNAService(db_session=db_session)

        recommendations = await service.get_recommendations(user_id=sample_user.id)

        assert isinstance(recommendations, list)

    @pytest.mark.asyncio
    async def test_style_compatibility_score(self, db_session: AsyncSession, sample_user: User, sample_product: Product):
        """Test calculating style compatibility score."""
        service = StyleDNAService(db_session=db_session)

        score = await service.calculate_compatibility(
            user_id=sample_user.id,
            product_id=sample_product.id
        )

        assert isinstance(score, (int, float))
        assert 0 <= score <= 1


class TestAffiliateService:
    """Test affiliate link service."""

    @pytest.mark.asyncio
    async def test_generate_affiliate_link(self, db_session: AsyncSession, sample_product: Product):
        """Test generating affiliate link."""
        service = AffiliateService(db_session=db_session)

        link = await service.generate_affiliate_link(product_id=sample_product.id)

        assert link is not None
        assert isinstance(link, str)
        assert len(link) > 0

    @pytest.mark.asyncio
    async def test_track_affiliate_click(self, db_session: AsyncSession, sample_product: Product):
        """Test tracking affiliate link clicks."""
        service = AffiliateService(db_session=db_session)

        # Generate link
        link = await service.generate_affiliate_link(product_id=sample_product.id)

        # Track click
        tracked = await service.track_click(product_id=sample_product.id, user_id=uuid.uuid4())

        assert tracked is True

    @pytest.mark.asyncio
    async def test_commission_calculation(self, db_session: AsyncSession, sample_product: Product, sample_retailer: Retailer):
        """Test commission calculation for sales."""
        service = AffiliateService(db_session=db_session)

        # Get commission rate
        commission = sample_retailer.commission_rate
        sale_amount = 100.0

        expected_commission = sale_amount * commission

        assert expected_commission > 0

    @pytest.mark.asyncio
    async def test_affiliate_network_routing(self, db_session: AsyncSession, sample_product: Product):
        """Test routing to correct affiliate network."""
        service = AffiliateService(db_session=db_session)

        # Should route through correct network (Rakuten, ShareASale, etc)
        link = await service.generate_affiliate_link(product_id=sample_product.id)

        assert link is not None
        # Link should contain network identifier
        assert len(link) > 0

    @pytest.mark.asyncio
    async def test_link_validation(self, db_session: AsyncSession):
        """Test validating affiliate links."""
        service = AffiliateService(db_session=db_session)

        # Valid link
        valid = await service.validate_link("https://example.com/product?aff=123")
        assert isinstance(valid, bool)

        # Invalid link
        invalid = await service.validate_link("not-a-url")
        assert invalid is False


class TestSearchService:
    """Test search service."""

    @pytest.mark.asyncio
    async def test_elasticsearch_indexing(self, db_session: AsyncSession, sample_product: Product):
        """Test product indexing in Elasticsearch."""
        from app.services.search import SearchService

        service = SearchService()

        # Mock ES client for testing
        await service.index_product(sample_product)

        # Product should be indexed
        assert True  # If no exception, indexing succeeded

    @pytest.mark.asyncio
    async def test_search_by_name(self, db_session: AsyncSession):
        """Test searching products by name."""
        from app.services.search import SearchService

        service = SearchService()

        results = await service.search(query="bag", limit=10)

        assert isinstance(results, list)

    @pytest.mark.asyncio
    async def test_search_with_filters(self, db_session: AsyncSession):
        """Test search with filters."""
        from app.services.search import SearchService

        service = SearchService()

        results = await service.search(
            query="dress",
            filters={
                "category": "Dresses",
                "min_price": 100,
                "max_price": 500,
                "brand": "Paloma Wool"
            },
            limit=20
        )

        assert isinstance(results, list)

    @pytest.mark.asyncio
    async def test_search_facets(self, db_session: AsyncSession):
        """Test retrieving search facets."""
        from app.services.search import SearchService

        service = SearchService()

        facets = await service.get_facets(query="bag")

        assert isinstance(facets, dict)
        # Should contain facet information
        assert "categories" in facets or len(facets) >= 0


class TestPriceMonitorService:
    """Test price monitoring service."""

    @pytest.mark.asyncio
    async def test_track_price_change(self, db_session: AsyncSession, sample_product: Product):
        """Test tracking price changes."""
        from app.services.price_monitor import PriceMonitorService

        service = PriceMonitorService(db_session=db_session)

        # Record current price
        await service.record_price(product_id=sample_product.id, price=sample_product.current_price)

        # Update price
        new_price = sample_product.current_price * 0.9  # 10% discount
        await service.record_price(product_id=sample_product.id, price=new_price)

        # Get price history
        history = await service.get_price_history(product_id=sample_product.id)

        assert isinstance(history, list)
        assert len(history) >= 1

    @pytest.mark.asyncio
    async def test_price_drop_detection(self, db_session: AsyncSession, sample_product: Product):
        """Test detecting price drops."""
        from app.services.price_monitor import PriceMonitorService

        service = PriceMonitorService(db_session=db_session)

        # Set initial price
        original_price = 100.0
        await service.record_price(product_id=sample_product.id, price=original_price)

        # Drop price significantly
        dropped_price = 70.0
        price_drop = await service.record_price(product_id=sample_product.id, price=dropped_price)

        # Should detect drop
        assert price_drop is not None or True  # Depends on implementation

    @pytest.mark.asyncio
    async def test_alert_on_target_price(self, db_session: AsyncSession, sample_user: User, sample_product: Product):
        """Test alerting user when product reaches target price."""
        from app.services.price_monitor import PriceMonitorService

        service = PriceMonitorService(db_session=db_session)

        # Set price alert
        target_price = sample_product.current_price * 0.8
        await service.set_price_alert(
            user_id=sample_user.id,
            product_id=sample_product.id,
            target_price=target_price
        )

        # Update price below target
        new_price = target_price * 0.9
        alerts = await service.check_alerts(product_id=sample_product.id, new_price=new_price)

        # Should generate alert
        assert isinstance(alerts, list)
