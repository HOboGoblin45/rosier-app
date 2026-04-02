"""Edge case and error handling tests."""
import pytest
import uuid
from datetime import datetime, timedelta, timezone
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User, Product


class TestAuthEdgeCases:
    """Test authentication edge cases."""

    @pytest.mark.asyncio
    async def test_register_with_special_characters_in_name(self, client: AsyncClient):
        """Test registration with special characters in display name."""
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "special@example.com",
                "password": "SecurePassword123!",
                "display_name": "Test™ User®"
            }
        )
        assert response.status_code in [200, 422]

    @pytest.mark.asyncio
    async def test_register_with_very_long_password(self, client: AsyncClient):
        """Test registration with extremely long password."""
        long_password = "P" * 500 + "assword123!"
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "longpass@example.com",
                "password": long_password,
                "display_name": "Test User"
            }
        )
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_login_with_empty_password(self, client: AsyncClient):
        """Test login with empty password."""
        response = await client.post(
            "/api/v1/auth/email/login",
            json={
                "email": "test@example.com",
                "password": ""
            }
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_login_with_empty_email(self, client: AsyncClient):
        """Test login with empty email."""
        response = await client.post(
            "/api/v1/auth/email/login",
            json={
                "email": "",
                "password": "Password123!"
            }
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_register_with_sql_injection_attempt(self, client: AsyncClient):
        """Test registration with SQL injection attempt in email."""
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "test'; DROP TABLE users; --@example.com",
                "password": "SecurePassword123!",
                "display_name": "Hacker"
            }
        )
        # Should either reject or safely handle
        assert response.status_code in [422, 400]

    @pytest.mark.asyncio
    async def test_register_with_xss_attempt_in_name(self, client: AsyncClient):
        """Test registration with XSS attempt in display name."""
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "xss@example.com",
                "password": "SecurePassword123!",
                "display_name": "<script>alert('xss')</script>"
            }
        )
        # Should safely handle XSS attempts
        assert response.status_code in [200, 400, 422]


class TestCardEdgeCases:
    """Test card endpoint edge cases."""

    @pytest.mark.asyncio
    async def test_swipe_with_negative_dwell_time(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test swipe with negative dwell time."""
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "like",
                "dwell_time_ms": -1000
            }
        )
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_swipe_with_extremely_large_dwell_time(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test swipe with extremely large dwell time."""
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "like",
                "dwell_time_ms": 999999999
            }
        )
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_get_cards_with_limit_zero(self, authenticated_client: AsyncClient):
        """Test getting cards with zero limit."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"limit": 0}
        )
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_get_cards_with_negative_limit(self, authenticated_client: AsyncClient):
        """Test getting cards with negative limit."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"limit": -10}
        )
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_get_cards_with_extremely_high_limit(self, authenticated_client: AsyncClient):
        """Test getting cards with extremely high limit."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"limit": 999999}
        )
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_swipe_with_invalid_uuid(self, authenticated_client: AsyncClient):
        """Test swipe with invalid UUID format."""
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": "not-a-uuid",
                "action": "like",
                "dwell_time_ms": 1000
            }
        )
        assert response.status_code in [400, 422]

    @pytest.mark.asyncio
    async def test_duplicate_swipes_same_product(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test swiping same product multiple times."""
        product_id = str(sample_product.id)

        # First swipe
        response1 = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": product_id,
                "action": "like",
                "dwell_time_ms": 2000
            }
        )

        # Second swipe on same product
        response2 = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": product_id,
                "action": "dislike",
                "dwell_time_ms": 1000
            }
        )

        # Both should succeed (last action wins or update is allowed)
        assert response1.status_code in [200, 201]
        assert response2.status_code in [200, 201]


class TestDresserEdgeCases:
    """Test dresser endpoint edge cases."""

    @pytest.mark.asyncio
    async def test_create_drawer_with_empty_name(self, authenticated_client: AsyncClient):
        """Test creating drawer with empty name."""
        response = await authenticated_client.post(
            "/api/v1/dresser/drawers",
            json={
                "name": "",
                "is_default": False
            }
        )
        assert response.status_code in [200, 201, 400, 422]

    @pytest.mark.asyncio
    async def test_create_drawer_with_very_long_name(self, authenticated_client: AsyncClient):
        """Test creating drawer with very long name."""
        response = await authenticated_client.post(
            "/api/v1/dresser/drawers",
            json={
                "name": "A" * 1000,
                "is_default": False
            }
        )
        assert response.status_code in [200, 201, 400, 422]

    @pytest.mark.asyncio
    async def test_add_item_with_invalid_price(self, authenticated_client: AsyncClient, sample_drawer):
        """Test adding item with negative or zero price."""
        fake_product_id = str(uuid.uuid4())

        # Negative price
        response = await authenticated_client.post(
            f"/api/v1/dresser/drawers/{sample_drawer.id}/items",
            json={
                "product_id": fake_product_id,
                "price_at_save": -450.0
            }
        )
        assert response.status_code in [200, 201, 400, 422, 404]

    @pytest.mark.asyncio
    async def test_add_same_item_multiple_times(self, authenticated_client: AsyncClient, sample_drawer, sample_product: Product):
        """Test adding same product multiple times to drawer."""
        product_id = str(sample_product.id)

        response1 = await authenticated_client.post(
            f"/api/v1/dresser/drawers/{sample_drawer.id}/items",
            json={
                "product_id": product_id,
                "price_at_save": 450.0
            }
        )

        response2 = await authenticated_client.post(
            f"/api/v1/dresser/drawers/{sample_drawer.id}/items",
            json={
                "product_id": product_id,
                "price_at_save": 400.0
            }
        )

        # Behavior may vary (duplicate allowed or update)
        assert response1.status_code in [200, 201]
        assert response2.status_code in [200, 201, 409]  # 409 for conflict


class TestProductEdgeCases:
    """Test product endpoint edge cases."""

    @pytest.mark.asyncio
    async def test_search_with_empty_query(self, authenticated_client: AsyncClient):
        """Test search with empty query string."""
        response = await authenticated_client.get(
            "/api/v1/products/search",
            params={"q": ""}
        )
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_search_with_very_long_query(self, authenticated_client: AsyncClient):
        """Test search with extremely long query."""
        response = await authenticated_client.get(
            "/api/v1/products/search",
            params={"q": "A" * 10000}
        )
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_search_with_special_regex_characters(self, authenticated_client: AsyncClient):
        """Test search with regex special characters."""
        response = await authenticated_client.get(
            "/api/v1/products/search",
            params={"q": ".*+?^${}()|[]\\"}
        )
        # Should handle safely (escape or reject)
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_product_with_invalid_price_range(self, authenticated_client: AsyncClient):
        """Test product filtering with invalid price range."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"min_price": 1000, "max_price": 10}  # Inverted range
        )
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_product_with_negative_prices(self, authenticated_client: AsyncClient):
        """Test product filtering with negative prices."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"min_price": -100, "max_price": -50}
        )
        assert response.status_code in [200, 400, 422]


class TestAuthenticationEdgeCases:
    """Test authentication edge cases."""

    @pytest.mark.asyncio
    async def test_access_protected_endpoint_without_token(self, client: AsyncClient):
        """Test accessing protected endpoint without auth token."""
        response = await client.get("/api/v1/profile")
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_access_protected_endpoint_with_malformed_token(self, client: AsyncClient):
        """Test accessing protected endpoint with malformed token."""
        client.headers["Authorization"] = "Bearer malformed_token"
        response = await client.get("/api/v1/profile")
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_access_protected_endpoint_with_expired_token(self, client: AsyncClient):
        """Test accessing protected endpoint with expired token."""
        client.headers["Authorization"] = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        response = await client.get("/api/v1/profile")
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_access_protected_endpoint_with_invalid_token_format(self, client: AsyncClient):
        """Test with invalid Authorization header format."""
        client.headers["Authorization"] = "InvalidBearer token"
        response = await client.get("/api/v1/profile")
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_access_protected_endpoint_with_no_bearer_prefix(self, client: AsyncClient):
        """Test with token but no Bearer prefix."""
        client.headers["Authorization"] = "validtokenbutnobearerprefix"
        response = await client.get("/api/v1/profile")
        assert response.status_code == 401


class TestConcurrencyAndRateLimit:
    """Test concurrent access and rate limiting."""

    @pytest.mark.asyncio
    async def test_concurrent_swipes(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test handling concurrent swipe requests."""
        product_id = str(sample_product.id)

        # Simulate multiple concurrent swipes
        responses = await asyncio.gather(
            authenticated_client.post(
                "/api/v1/cards/swipe",
                json={"product_id": product_id, "action": "like", "dwell_time_ms": 1000}
            ),
            authenticated_client.post(
                "/api/v1/cards/swipe",
                json={"product_id": product_id, "action": "dislike", "dwell_time_ms": 500}
            ),
        )

        # Both should succeed
        for response in responses:
            assert response.status_code in [200, 201]

    @pytest.mark.asyncio
    async def test_rapid_profile_updates(self, authenticated_client: AsyncClient):
        """Test rapid profile update requests."""
        # Simulate rapid updates
        responses = []
        for i in range(5):
            response = await authenticated_client.put(
                "/api/v1/profile",
                json={"display_name": f"User {i}"}
            )
            responses.append(response)

        # Most should succeed, may get rate limited on last ones
        assert all(r.status_code in [200, 429] for r in responses)

    @pytest.mark.asyncio
    async def test_rapid_drawer_creation(self, authenticated_client: AsyncClient):
        """Test rapid drawer creation."""
        responses = []
        for i in range(10):
            response = await authenticated_client.post(
                "/api/v1/dresser/drawers",
                json={"name": f"Drawer {i}"}
            )
            responses.append(response)

        # Should handle gracefully
        assert all(r.status_code in [200, 201, 429] for r in responses)


import asyncio
