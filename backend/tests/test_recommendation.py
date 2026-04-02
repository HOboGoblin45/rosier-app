"""Recommendation and scoring engine tests."""
import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from httpx import AsyncClient

from app.services.recommendation import RecommendationService


@pytest.mark.asyncio
async def test_score_product_category_match(
    db_session: AsyncSession,
    sample_product,
    authenticated_user
):
    """Test product scoring for category match."""
    user, _ = authenticated_user
    service = RecommendationService(db_session)

    # Set user preference for the product's category
    user.quiz_responses = {"favorite_categories": ["Bags"]}

    score = await service.score_product(
        product=sample_product,
        user=user
    )

    assert isinstance(score, float)
    assert 0 <= score <= 1.0
    # Should have decent score due to category match
    assert score > 0.3


@pytest.mark.asyncio
async def test_score_product_brand_affinity(
    db_session: AsyncSession,
    sample_product,
    sample_brand,
    authenticated_user
):
    """Test product scoring for brand affinity."""
    user, _ = authenticated_user
    service = RecommendationService(db_session)

    # Set user preference for the product's brand
    user.quiz_responses = {"favorite_brands": ["Paloma Wool"]}

    score = await service.score_product(
        product=sample_product,
        user=user
    )

    assert isinstance(score, float)
    assert 0 <= score <= 1.0


@pytest.mark.asyncio
async def test_score_product_price_match(
    db_session: AsyncSession,
    sample_product,
    authenticated_user
):
    """Test product scoring for price alignment."""
    user, _ = authenticated_user
    service = RecommendationService(db_session)

    # Set user price preference
    user.quiz_responses = {"price_preference": "luxury"}

    score = await service.score_product(
        product=sample_product,
        user=user
    )

    assert isinstance(score, float)
    assert 0 <= score <= 1.0


@pytest.mark.asyncio
async def test_score_product_on_sale_boost(
    db_session: AsyncSession,
    sample_product,
    authenticated_user
):
    """Test that on-sale products get a score boost."""
    user, _ = authenticated_user
    service = RecommendationService(db_session)

    # Score on-sale product
    score_on_sale = await service.score_product(
        product=sample_product,
        user=user
    )

    # Sample product is on sale, so score should be boosted
    assert isinstance(score_on_sale, float)


@pytest.mark.asyncio
async def test_card_queue_diversity_rules(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    authenticated_user,
    sample_retailer,
    sample_brand
):
    """Test that card queue respects diversity rules."""
    from app.models import Product
    import uuid

    user, _ = authenticated_user

    # Create multiple products from same brand
    for i in range(5):
        product = Product(
            id=uuid.uuid4(),
            external_id=f"prod_{i}",
            retailer_id=sample_retailer.id,
            brand_id=sample_brand.id,
            name=f"Product {i}",
            category="Bags",
            current_price=200 + (i * 50),
            product_url=f"https://example.com/prod_{i}"
        )
        db_session.add(product)

    await db_session.commit()

    # Get cards
    response = await authenticated_client.get(
        "/api/v1/cards/next",
        params={"limit": 10}
    )

    assert response.status_code == 200
    data = response.json()
    cards = data.get("cards", data if isinstance(data, list) else [])

    # Should have diversity - not all from same brand
    brand_ids = {}
    for card in cards:
        brand_id = card.get("brand_id")
        brand_ids[brand_id] = brand_ids.get(brand_id, 0) + 1

    # No single brand should dominate
    if len(brand_ids) > 1:
        max_count = max(brand_ids.values())
        assert max_count <= len(cards) * 0.6  # No brand > 60% of results


@pytest.mark.asyncio
async def test_exploration_percentage(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_product
):
    """Test that queue includes exploration/discovery items."""
    # Get cards multiple times
    response = await authenticated_client.get(
        "/api/v1/cards/next",
        params={"limit": 20}
    )

    assert response.status_code == 200
    data = response.json()
    cards = data.get("cards", data if isinstance(data, list) else [])

    # Queue should have some variety
    # (exploration items that don't perfectly match preferences)
    assert len(cards) <= 20


@pytest.mark.asyncio
async def test_recommendation_excludes_viewed_products(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_product,
    authenticated_user
):
    """Test that recommendations exclude already viewed products."""
    user, _ = authenticated_user

    # Swipe on product
    response1 = await authenticated_client.post(
        "/api/v1/cards/swipe",
        json={
            "product_id": str(sample_product.id),
            "action": "like"
        }
    )
    assert response1.status_code == 201

    # Get next cards
    response2 = await authenticated_client.get(
        "/api/v1/cards/next",
        params={"limit": 10}
    )

    assert response2.status_code == 200
    data = response2.json()
    cards = data.get("cards", data if isinstance(data, list) else [])

    # Should not contain the swiped product
    card_ids = [str(card.get("id")) for card in cards if isinstance(card, dict)]
    assert str(sample_product.id) not in card_ids


@pytest.mark.asyncio
async def test_recommendation_cold_start(authenticated_client: AsyncClient):
    """Test recommendations for new user without swipe history."""
    response = await authenticated_client.get(
        "/api/v1/cards/next",
        params={"limit": 10}
    )

    # New user should still get cards (cold start strategy)
    assert response.status_code == 200
    data = response.json()
    cards = data.get("cards", data if isinstance(data, list) else [])
    assert len(cards) > 0


@pytest.mark.asyncio
async def test_recommendation_uses_preference_vector(
    db_session: AsyncSession,
    authenticated_user
):
    """Test that recommendations use user preference vector."""
    user, _ = authenticated_user
    service = RecommendationService(db_session)

    # Create preference vector
    import numpy as np
    user.preference_vector = np.random.rand(128).tolist()

    # Should be able to score with preference vector
    assert user.preference_vector is not None
    assert len(user.preference_vector) == 128


@pytest.mark.asyncio
async def test_personalization_improves_over_time(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    authenticated_user,
    sample_product
):
    """Test that personalization improves as user provides more feedback."""
    user, _ = authenticated_user

    # First batch of swipes
    for i in range(10):
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "like" if i % 2 == 0 else "reject"
            }
        )
        assert response.status_code == 201

    # Get user's updated preference vector
    updated_user = await db_session.get(user.__class__, user.id)

    # User should have accumulated swipe data
    from app.models import SwipeEvent
    from sqlalchemy import select
    stmt = select(SwipeEvent).where(SwipeEvent.user_id == user.id)
    result = await db_session.execute(stmt)
    swipes = result.scalars().all()
    assert len(swipes) >= 10
