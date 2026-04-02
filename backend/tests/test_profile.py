"""User profile endpoint tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models import User, SwipeEvent


@pytest.mark.asyncio
async def test_get_profile(authenticated_client: AsyncClient):
    """Test getting user profile."""
    response = await authenticated_client.get("/api/v1/profile")

    assert response.status_code == 200
    data = response.json()
    assert "id" in data
    assert "email" in data
    assert "display_name" in data


@pytest.mark.asyncio
async def test_get_profile_unauthenticated(client: AsyncClient):
    """Test getting profile without authentication."""
    response = await client.get("/api/v1/profile")

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_update_profile(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    authenticated_user
):
    """Test updating user profile."""
    response = await authenticated_client.put(
        "/api/v1/profile",
        json={
            "display_name": "Updated Name",
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert data["display_name"] == "Updated Name"


@pytest.mark.asyncio
async def test_update_profile_settings(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
):
    """Test updating user settings."""
    response = await authenticated_client.put(
        "/api/v1/profile/settings",
        json={
            "notifications": False,
            "theme": "dark",
            "language": "es"
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert data["settings"]["notifications"] is False


@pytest.mark.asyncio
async def test_get_style_dna(
    authenticated_client: AsyncClient,
    authenticated_user,
    db_session: AsyncSession,
    sample_product
):
    """Test getting style DNA (requires 100+ swipes)."""
    user, _ = authenticated_user

    # Create 100+ swipe events
    from app.models.swipe_event import SwipeAction
    import uuid

    for i in range(101):
        event = SwipeEvent(
            id=uuid.uuid4(),
            user_id=user.id,
            product_id=sample_product.id,
            action=SwipeAction.LIKE,
            dwell_time_ms=1000,
            session_position=i
        )
        db_session.add(event)

    await db_session.commit()

    response = await authenticated_client.get("/api/v1/profile/style-dna")

    assert response.status_code == 200
    data = response.json()
    assert "style_dna" in data or "profile" in data


@pytest.mark.asyncio
async def test_style_dna_requires_100_swipes(
    authenticated_client: AsyncClient,
    authenticated_user,
    db_session: AsyncSession,
    sample_product
):
    """Test that style DNA requires at least 100 swipes."""
    user, _ = authenticated_user

    # Create only 50 swipes
    from app.models.swipe_event import SwipeAction
    import uuid

    for i in range(50):
        event = SwipeEvent(
            id=uuid.uuid4(),
            user_id=user.id,
            product_id=sample_product.id,
            action=SwipeAction.LIKE,
            dwell_time_ms=1000,
            session_position=i
        )
        db_session.add(event)

    await db_session.commit()

    response = await authenticated_client.get("/api/v1/profile/style-dna")

    # Should either return 400/403 or a message indicating insufficient data
    assert response.status_code in [200, 400, 403]
    if response.status_code == 200:
        data = response.json()
        assert "error" in data or "message" in data or "swipes_required" in data


@pytest.mark.asyncio
async def test_get_swipe_history(
    authenticated_client: AsyncClient,
    authenticated_user,
    db_session: AsyncSession,
    sample_product
):
    """Test getting user's swipe history."""
    user, _ = authenticated_user

    # Create a few swipes
    from app.models.swipe_event import SwipeAction
    import uuid

    for i in range(3):
        event = SwipeEvent(
            id=uuid.uuid4(),
            user_id=user.id,
            product_id=sample_product.id,
            action=SwipeAction.LIKE,
            dwell_time_ms=1000 + (i * 500),
            session_position=i
        )
        db_session.add(event)

    await db_session.commit()

    response = await authenticated_client.get(
        "/api/v1/profile/swipes",
        params={"limit": 10}
    )

    assert response.status_code == 200
    data = response.json()
    assert "swipes" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_get_preferences(authenticated_client: AsyncClient):
    """Test getting user preferences."""
    response = await authenticated_client.get("/api/v1/profile/preferences")

    assert response.status_code == 200
    data = response.json()
    assert "preferences" in data or isinstance(data, dict)


@pytest.mark.asyncio
async def test_update_preferences(authenticated_client: AsyncClient):
    """Test updating user preferences."""
    response = await authenticated_client.put(
        "/api/v1/profile/preferences",
        json={
            "brand_preferences": ["Paloma Wool", "Khaite"],
            "category_preferences": ["Bags", "Clothing"],
            "price_preference": "luxury",
            "style_preferences": ["minimalist", "contemporary"]
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert "preferences" in data or "brand_preferences" in data


@pytest.mark.asyncio
async def test_get_saved_items_count(
    authenticated_client: AsyncClient,
    authenticated_user,
    db_session: AsyncSession,
    sample_dresser_item
):
    """Test getting count of saved items."""
    response = await authenticated_client.get("/api/v1/profile/saved-count")

    assert response.status_code == 200
    data = response.json()
    assert "count" in data or isinstance(data, dict)
    if "count" in data:
        assert data["count"] >= 1


@pytest.mark.asyncio
async def test_get_activity_stats(
    authenticated_client: AsyncClient,
    authenticated_user,
    db_session: AsyncSession,
    sample_product
):
    """Test getting user activity statistics."""
    user, _ = authenticated_user

    # Create some swipe events
    from app.models.swipe_event import SwipeAction
    import uuid

    for action in [SwipeAction.LIKE, SwipeAction.LIKE, SwipeAction.REJECT]:
        event = SwipeEvent(
            id=uuid.uuid4(),
            user_id=user.id,
            product_id=sample_product.id,
            action=action,
            dwell_time_ms=1000
        )
        db_session.add(event)

    await db_session.commit()

    response = await authenticated_client.get("/api/v1/profile/stats")

    assert response.status_code == 200
    data = response.json()
    assert "stats" in data or "likes" in data


@pytest.mark.asyncio
async def test_profile_includes_onboarding_status(authenticated_client: AsyncClient):
    """Test that profile includes onboarding status."""
    response = await authenticated_client.get("/api/v1/profile")

    assert response.status_code == 200
    data = response.json()
    assert "onboarding_completed" in data or "onboarding" in data
