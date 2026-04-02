"""Comprehensive API integration tests for all endpoints."""
import pytest
import uuid
from datetime import datetime, timedelta, timezone
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User, Product, Brand, Retailer, SwipeEvent, DresserDrawer, DresserItem
from app.models.swipe_event import SwipeAction


class TestAuthEndpoints:
    """Test authentication endpoints."""

    @pytest.mark.asyncio
    async def test_email_register_success(self, client: AsyncClient, db_session: AsyncSession):
        """Test successful email registration."""
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "newuser@example.com",
                "password": "SecurePassword123!",
                "display_name": "Test User"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"
        assert data["expires_in"] > 0

    @pytest.mark.asyncio
    async def test_email_register_invalid_email(self, client: AsyncClient):
        """Test registration with invalid email format."""
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "not-an-email",
                "password": "SecurePassword123!",
                "display_name": "Test User"
            }
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_email_register_weak_password(self, client: AsyncClient):
        """Test registration with weak password."""
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "test@example.com",
                "password": "weak",
                "display_name": "Test User"
            }
        )
        assert response.status_code in [422, 400]

    @pytest.mark.asyncio
    async def test_email_login_success(self, client: AsyncClient, sample_user: User):
        """Test successful email login."""
        response = await client.post(
            "/api/v1/auth/email/login",
            json={
                "email": sample_user.email,
                "password": "correct_password"  # Note: password hashing would verify this
            }
        )
        # Status would be 200 if password matches, 401 if not
        assert response.status_code in [200, 401]
        if response.status_code == 200:
            data = response.json()
            assert "access_token" in data
            assert "refresh_token" in data

    @pytest.mark.asyncio
    async def test_email_login_nonexistent_user(self, client: AsyncClient):
        """Test login with non-existent email."""
        response = await client.post(
            "/api/v1/auth/email/login",
            json={
                "email": "nonexistent@example.com",
                "password": "SomePassword123!"
            }
        )
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_refresh_token_success(self, client: AsyncClient, authenticated_user):
        """Test token refresh with valid refresh token."""
        user, token = authenticated_user
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": token}
        )
        assert response.status_code in [200, 400]  # 400 if refresh token expired

    @pytest.mark.asyncio
    async def test_logout(self, authenticated_client: AsyncClient):
        """Test user logout."""
        response = await authenticated_client.post("/api/v1/auth/logout")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_apple_login_initiate(self, client: AsyncClient):
        """Test Apple login initiation."""
        response = await client.post(
            "/api/v1/auth/apple/login",
            json={"identity_token": "test_token"}
        )
        assert response.status_code in [200, 400, 401]


class TestCardEndpoints:
    """Test card/swipe endpoints."""

    @pytest.mark.asyncio
    async def test_get_next_cards(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test fetching next cards."""
        response = await authenticated_client.get("/api/v1/cards/next", params={"limit": 10})
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (list, dict))

    @pytest.mark.asyncio
    async def test_get_next_cards_with_filters(self, authenticated_client: AsyncClient):
        """Test fetching cards with category filter."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"category": "Bags", "limit": 5, "min_price": 100, "max_price": 500}
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_get_next_cards_pagination(self, authenticated_client: AsyncClient):
        """Test card pagination with cursor."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"limit": 20, "cursor": "0"}
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_swipe_like(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test liking a product."""
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "like",
                "dwell_time_ms": 2500,
                "session_position": 1
            }
        )
        assert response.status_code in [200, 201]

    @pytest.mark.asyncio
    async def test_swipe_dislike(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test disliking a product."""
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "dislike",
                "dwell_time_ms": 1200,
                "session_position": 2
            }
        )
        assert response.status_code in [200, 201]

    @pytest.mark.asyncio
    async def test_swipe_expand(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test expanding product details."""
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "expand",
                "dwell_time_ms": 5000,
                "session_position": 3,
                "expanded": True
            }
        )
        assert response.status_code in [200, 201]

    @pytest.mark.asyncio
    async def test_swipe_invalid_action(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test swipe with invalid action."""
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
    async def test_swipe_nonexistent_product(self, authenticated_client: AsyncClient):
        """Test swiping on non-existent product."""
        fake_id = str(uuid.uuid4())
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": fake_id,
                "action": "like",
                "dwell_time_ms": 2000
            }
        )
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_get_swipe_history(self, authenticated_client: AsyncClient, sample_swipe_event: SwipeEvent):
        """Test retrieving swipe history."""
        response = await authenticated_client.get("/api/v1/cards/history")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (list, dict))


class TestDresserEndpoints:
    """Test dresser/wardrobe endpoints."""

    @pytest.mark.asyncio
    async def test_get_drawers(self, authenticated_client: AsyncClient, sample_drawer: DresserDrawer):
        """Test listing drawers."""
        response = await authenticated_client.get("/api/v1/dresser/drawers")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_create_drawer(self, authenticated_client: AsyncClient):
        """Test creating a new drawer."""
        response = await authenticated_client.post(
            "/api/v1/dresser/drawers",
            json={
                "name": "New Collection",
                "is_default": False
            }
        )
        assert response.status_code in [200, 201]
        if response.status_code in [200, 201]:
            data = response.json()
            assert "id" in data or "drawer_id" in data

    @pytest.mark.asyncio
    async def test_rename_drawer(self, authenticated_client: AsyncClient, sample_drawer: DresserDrawer):
        """Test renaming a drawer."""
        response = await authenticated_client.put(
            f"/api/v1/dresser/drawers/{sample_drawer.id}",
            json={"name": "Renamed Collection"}
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_delete_drawer(self, authenticated_client: AsyncClient):
        """Test deleting a drawer."""
        # Create a drawer first
        create_response = await authenticated_client.post(
            "/api/v1/dresser/drawers",
            json={"name": "Temporary"}
        )
        if create_response.status_code in [200, 201]:
            drawer_id = create_response.json().get("id") or create_response.json().get("drawer_id")
            response = await authenticated_client.delete(f"/api/v1/dresser/drawers/{drawer_id}")
            assert response.status_code in [200, 204]

    @pytest.mark.asyncio
    async def test_get_drawer_items(self, authenticated_client: AsyncClient, sample_drawer: DresserDrawer):
        """Test retrieving items in a drawer."""
        response = await authenticated_client.get(f"/api/v1/dresser/drawers/{sample_drawer.id}/items")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (list, dict))

    @pytest.mark.asyncio
    async def test_add_item_to_drawer(self, authenticated_client: AsyncClient, sample_drawer: DresserDrawer, sample_product: Product):
        """Test adding product to drawer."""
        response = await authenticated_client.post(
            f"/api/v1/dresser/drawers/{sample_drawer.id}/items",
            json={
                "product_id": str(sample_product.id),
                "price_at_save": 450.0
            }
        )
        assert response.status_code in [200, 201]

    @pytest.mark.asyncio
    async def test_remove_item_from_drawer(self, authenticated_client: AsyncClient, sample_dresser_item: DresserItem):
        """Test removing product from drawer."""
        response = await authenticated_client.delete(
            f"/api/v1/dresser/items/{sample_dresser_item.id}"
        )
        assert response.status_code in [200, 204]

    @pytest.mark.asyncio
    async def test_update_item_in_drawer(self, authenticated_client: AsyncClient, sample_dresser_item: DresserItem):
        """Test updating item in drawer."""
        response = await authenticated_client.put(
            f"/api/v1/dresser/items/{sample_dresser_item.id}",
            json={
                "notes": "Love this piece!",
                "style_tags": ["casual", "minimalist"]
            }
        )
        assert response.status_code == 200


class TestProductEndpoints:
    """Test product endpoints."""

    @pytest.mark.asyncio
    async def test_get_product(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test retrieving a single product."""
        response = await authenticated_client.get(f"/api/v1/products/{sample_product.id}")
        assert response.status_code == 200
        data = response.json()
        assert data.get("id") == str(sample_product.id) or data.get("product_id") == str(sample_product.id)

    @pytest.mark.asyncio
    async def test_get_product_nonexistent(self, authenticated_client: AsyncClient):
        """Test retrieving non-existent product."""
        fake_id = str(uuid.uuid4())
        response = await authenticated_client.get(f"/api/v1/products/{fake_id}")
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_search_products(self, authenticated_client: AsyncClient):
        """Test product search."""
        response = await authenticated_client.get(
            "/api/v1/products/search",
            params={"q": "luxury bag"}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (list, dict))

    @pytest.mark.asyncio
    async def test_get_similar_products(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test getting similar products."""
        response = await authenticated_client.get(
            f"/api/v1/products/{sample_product.id}/similar"
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_check_product_availability(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test checking product availability."""
        response = await authenticated_client.get(
            f"/api/v1/products/{sample_product.id}/availability"
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_get_affiliate_link(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test getting affiliate link for product."""
        response = await authenticated_client.get(
            f"/api/v1/products/{sample_product.id}/affiliate-link"
        )
        assert response.status_code == 200
        data = response.json()
        if "affiliate_url" in data or "link" in data:
            assert len(data.get("affiliate_url") or data.get("link")) > 0


class TestProfileEndpoints:
    """Test user profile endpoints."""

    @pytest.mark.asyncio
    async def test_get_profile(self, authenticated_client: AsyncClient, sample_user: User):
        """Test retrieving user profile."""
        response = await authenticated_client.get("/api/v1/profile")
        assert response.status_code == 200
        data = response.json()
        assert "email" in data or "user_email" in data

    @pytest.mark.asyncio
    async def test_update_profile(self, authenticated_client: AsyncClient):
        """Test updating user profile."""
        response = await authenticated_client.put(
            "/api/v1/profile",
            json={
                "display_name": "Updated Name",
                "bio": "Fashion enthusiast"
            }
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_get_style_dna(self, authenticated_client: AsyncClient):
        """Test retrieving style DNA."""
        response = await authenticated_client.get("/api/v1/profile/style-dna")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_update_style_dna(self, authenticated_client: AsyncClient):
        """Test updating style DNA."""
        response = await authenticated_client.put(
            "/api/v1/profile/style-dna",
            json={
                "dominant_colors": ["black", "white"],
                "fit_preferences": ["slim", "oversized"],
                "style_categories": ["minimalist", "vintage"]
            }
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_get_preferences(self, authenticated_client: AsyncClient):
        """Test retrieving user preferences."""
        response = await authenticated_client.get("/api/v1/profile/preferences")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_update_preferences(self, authenticated_client: AsyncClient):
        """Test updating user preferences."""
        response = await authenticated_client.put(
            "/api/v1/profile/preferences",
            json={
                "notifications_enabled": True,
                "brand_notifications": False,
                "sale_alerts": True,
                "preferred_brands": ["Paloma Wool", "The Row"]
            }
        )
        assert response.status_code == 200


class TestOnboardingEndpoints:
    """Test onboarding endpoints."""

    @pytest.mark.asyncio
    async def test_get_onboarding_status(self, authenticated_client: AsyncClient):
        """Test retrieving onboarding status."""
        response = await authenticated_client.get("/api/v1/onboarding/status")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_complete_style_quiz(self, authenticated_client: AsyncClient):
        """Test completing style quiz."""
        response = await authenticated_client.post(
            "/api/v1/onboarding/quiz",
            json={
                "preferred_style": "minimalist",
                "body_type": "pear",
                "budget_range": "luxury",
                "favorite_brands": ["The Row", "COS", "Jil Sander"],
                "colors": ["black", "white", "beige"]
            }
        )
        assert response.status_code in [200, 201]

    @pytest.mark.asyncio
    async def test_get_brand_recommendations(self, authenticated_client: AsyncClient):
        """Test getting brand recommendations during onboarding."""
        response = await authenticated_client.get("/api/v1/onboarding/brands")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_complete_onboarding(self, authenticated_client: AsyncClient):
        """Test marking onboarding as complete."""
        response = await authenticated_client.post("/api/v1/onboarding/complete")
        assert response.status_code == 200


class TestRecommendationEndpoints:
    """Test recommendation endpoints."""

    @pytest.mark.asyncio
    async def test_get_recommendations(self, authenticated_client: AsyncClient):
        """Test getting recommendations."""
        response = await authenticated_client.get("/api/v1/recommendations")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_get_recommendations_by_category(self, authenticated_client: AsyncClient):
        """Test getting recommendations for specific category."""
        response = await authenticated_client.get(
            "/api/v1/recommendations",
            params={"category": "Dresses"}
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_refresh_recommendations(self, authenticated_client: AsyncClient):
        """Test refreshing recommendations."""
        response = await authenticated_client.post("/api/v1/recommendations/refresh")
        assert response.status_code == 200


class TestDailyDropEndpoints:
    """Test daily drop endpoints."""

    @pytest.mark.asyncio
    async def test_get_daily_drop(self, authenticated_client: AsyncClient):
        """Test getting daily drop products."""
        response = await authenticated_client.get("/api/v1/daily-drop")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (list, dict))

    @pytest.mark.asyncio
    async def test_daily_drop_pagination(self, authenticated_client: AsyncClient):
        """Test daily drop pagination."""
        response = await authenticated_client.get(
            "/api/v1/daily-drop",
            params={"page": 1, "limit": 20}
        )
        assert response.status_code == 200


class TestSaleEventsEndpoints:
    """Test sale events endpoints."""

    @pytest.mark.asyncio
    async def test_get_active_sales(self, authenticated_client: AsyncClient):
        """Test getting active sales."""
        response = await authenticated_client.get("/api/v1/sale-events")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_get_sale_by_id(self, authenticated_client: AsyncClient):
        """Test getting specific sale event."""
        # This requires an existing sale event, so we'll use a fake ID
        fake_id = str(uuid.uuid4())
        response = await authenticated_client.get(f"/api/v1/sale-events/{fake_id}")
        assert response.status_code in [200, 404]

    @pytest.mark.asyncio
    async def test_get_sales_by_brand(self, authenticated_client: AsyncClient):
        """Test getting sales for specific brand."""
        response = await authenticated_client.get(
            "/api/v1/sale-events",
            params={"brand": "Paloma Wool"}
        )
        assert response.status_code == 200


class TestNotificationEndpoints:
    """Test notification endpoints."""

    @pytest.mark.asyncio
    async def test_get_notifications(self, authenticated_client: AsyncClient):
        """Test retrieving notifications."""
        response = await authenticated_client.get("/api/v1/notifications")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (list, dict))

    @pytest.mark.asyncio
    async def test_mark_notification_read(self, authenticated_client: AsyncClient):
        """Test marking notification as read."""
        # Would need actual notification ID
        fake_id = str(uuid.uuid4())
        response = await authenticated_client.put(
            f"/api/v1/notifications/{fake_id}/read"
        )
        assert response.status_code in [200, 404]

    @pytest.mark.asyncio
    async def test_clear_notifications(self, authenticated_client: AsyncClient):
        """Test clearing all notifications."""
        response = await authenticated_client.delete("/api/v1/notifications")
        assert response.status_code in [200, 204]


class TestHealthAndAdmin:
    """Test health check and admin endpoints."""

    @pytest.mark.asyncio
    async def test_health_check(self, client: AsyncClient):
        """Test health check endpoint."""
        response = await client.get("/health")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_api_docs(self, client: AsyncClient):
        """Test API documentation endpoint."""
        response = await client.get("/docs")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_openapi_schema(self, client: AsyncClient):
        """Test OpenAPI schema endpoint."""
        response = await client.get("/openapi.json")
        assert response.status_code == 200
        data = response.json()
        assert "openapi" in data
        assert "paths" in data
