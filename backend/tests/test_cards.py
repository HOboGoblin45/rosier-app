"""Card endpoint tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models import SwipeEvent, Product, Brand, Retailer
from app.models.swipe_event import SwipeAction


@pytest.mark.asyncio
async def test_get_next_cards_authenticated(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_product: Product
):
    """Test fetching next cards when authenticated."""
    response = await authenticated_client.get(
        "/api/v1/cards/next",
        params={"limit": 10}
    )

    assert response.status_code == 200
    data = response.json()
    assert "cards" in data or isinstance(data, list)
    # Should contain at least the sample product
    if isinstance(data, list):
        assert len(data) <= 10
    else:
        assert len(data["cards"]) <= 10


@pytest.mark.asyncio
async def test_get_next_cards_unauthenticated(client: AsyncClient):
    """Test fetching next cards without authentication."""
    response = await client.get("/api/v1/cards/next")

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_next_cards_with_filters(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_product: Product
):
    """Test fetching cards with category filter."""
    response = await authenticated_client.get(
        "/api/v1/cards/next",
        params={"category": "Bags", "limit": 5}
    )

    assert response.status_code == 200
    data = response.json()
    assert "cards" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_get_next_cards_pagination(authenticated_client: AsyncClient):
    """Test card pagination."""
    response = await authenticated_client.get(
        "/api/v1/cards/next",
        params={"limit": 5, "offset": 0}
    )

    assert response.status_code == 200
    data = response.json()
    assert "cards" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_submit_single_swipe_event(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_product: Product
):
    """Test submitting a single swipe event."""
    response = await authenticated_client.post(
        "/api/v1/cards/swipe",
        json={
            "product_id": str(sample_product.id),
            "action": "like",
            "dwell_time_ms": 2500,
            "session_position": 1,
            "expanded": False,
            "session_id": "session_123"
        }
    )

    assert response.status_code == 201
    data = response.json()
    assert "id" in data

    # Verify event was saved
    stmt = select(SwipeEvent).where(SwipeEvent.product_id == sample_product.id)
    result = await db_session.execute(stmt)
    event = result.scalar_one_or_none()
    assert event is not None
    assert event.action == SwipeAction.LIKE


@pytest.mark.asyncio
async def test_submit_swipe_events_batch(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_product: Product,
    sample_brand: Brand,
    sample_retailer: Retailer
):
    """Test submitting multiple swipe events in batch."""
    # Create additional product
    product2 = Product(
        external_id="prod_456",
        retailer_id=sample_retailer.id,
        brand_id=sample_brand.id,
        name="Test Dress",
        category="Clothing",
        current_price=250.0,
        product_url="https://example.com/dress"
    )
    db_session.add(product2)
    await db_session.commit()

    response = await authenticated_client.post(
        "/api/v1/cards/swipes",
        json={
            "events": [
                {
                    "product_id": str(sample_product.id),
                    "action": "like",
                    "dwell_time_ms": 2500
                },
                {
                    "product_id": str(product2.id),
                    "action": "reject",
                    "dwell_time_ms": 800
                }
            ]
        }
    )

    assert response.status_code == 201
    data = response.json()
    assert "count" in data or "events" in data

    # Verify both events were saved
    stmt = select(SwipeEvent).where(SwipeEvent.action == SwipeAction.LIKE)
    result = await db_session.execute(stmt)
    like_events = result.scalars().all()
    assert len(like_events) >= 1

    stmt = select(SwipeEvent).where(SwipeEvent.action == SwipeAction.REJECT)
    result = await db_session.execute(stmt)
    reject_events = result.scalars().all()
    assert len(reject_events) >= 1


@pytest.mark.asyncio
async def test_submit_swipe_invalid_product(authenticated_client: AsyncClient):
    """Test submitting swipe for nonexistent product."""
    import uuid
    response = await authenticated_client.post(
        "/api/v1/cards/swipe",
        json={
            "product_id": str(uuid.uuid4()),
            "action": "like",
            "dwell_time_ms": 1000
        }
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_submit_swipe_invalid_action(
    authenticated_client: AsyncClient,
    sample_product: Product
):
    """Test submitting swipe with invalid action."""
    response = await authenticated_client.post(
        "/api/v1/cards/swipe",
        json={
            "product_id": str(sample_product.id),
            "action": "invalid_action",
            "dwell_time_ms": 1000
        }
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_card_queue_excludes_swiped_products(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    authenticated_user: tuple,
    sample_product: Product
):
    """Test that swiped products don't appear in queue again."""
    user, _ = authenticated_user

    # First swipe on product
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

    # Verify product doesn't appear again
    product_ids = [str(card.get("id")) for card in cards]
    assert str(sample_product.id) not in product_ids


@pytest.mark.asyncio
async def test_card_queue_respects_category_filter(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_product: Product,
    sample_retailer: Retailer,
    sample_brand: Brand
):
    """Test that category filter is respected in queue."""
    # Create product in different category
    from app.models import Product
    product2 = Product(
        external_id="prod_999",
        retailer_id=sample_retailer.id,
        brand_id=sample_brand.id,
        name="Test Shoe",
        category="Shoes",
        current_price=120.0,
        product_url="https://example.com/shoe"
    )
    db_session.add(product2)
    await db_session.commit()

    # Request only bags
    response = await authenticated_client.get(
        "/api/v1/cards/next",
        params={"category": "Bags", "limit": 10}
    )

    assert response.status_code == 200
    data = response.json()
    cards = data.get("cards", data if isinstance(data, list) else [])

    # All returned cards should be bags
    for card in cards:
        if isinstance(card, dict):
            assert card.get("category") == "Bags"


@pytest.mark.asyncio
async def test_swipe_event_with_all_fields(
    authenticated_client: AsyncClient,
    sample_product: Product
):
    """Test swipe event with all optional fields."""
    response = await authenticated_client.post(
        "/api/v1/cards/swipe",
        json={
            "product_id": str(sample_product.id),
            "action": "super_like",
            "dwell_time_ms": 5000,
            "session_position": 3,
            "expanded": True,
            "session_id": "detailed_session_456"
        }
    )

    assert response.status_code == 201


@pytest.mark.asyncio
async def test_get_cards_pagination(authenticated_client: AsyncClient):
    """Test pagination parameters for getting cards."""
    response = await authenticated_client.get(
        "/api/v1/cards/next",
        params={"limit": 5, "offset": 5}
    )

    assert response.status_code == 200
    data = response.json()
    assert "cards" in data or isinstance(data, list)


# Import needed fixtures
from conftest import sample_brand, sample_retailer, Retailer, Brand
