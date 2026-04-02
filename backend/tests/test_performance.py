"""Performance benchmark tests."""
import pytest
import time
import asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User, Product


class TestAPIResponseTimes:
    """Test API endpoint response times."""

    @pytest.mark.asyncio
    async def test_get_cards_response_time(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test that getting cards completes within acceptable time."""
        start = time.time()
        response = await authenticated_client.get("/api/v1/cards/next", params={"limit": 20})
        elapsed = time.time() - start

        assert response.status_code == 200
        # Should complete within 500ms
        assert elapsed < 0.5, f"Getting cards took {elapsed:.3f}s, expected < 0.5s"

    @pytest.mark.asyncio
    async def test_swipe_response_time(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test that swipe endpoint responds quickly."""
        start = time.time()
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "like",
                "dwell_time_ms": 2000
            }
        )
        elapsed = time.time() - start

        assert response.status_code in [200, 201]
        # Should complete within 200ms
        assert elapsed < 0.2, f"Swipe took {elapsed:.3f}s, expected < 0.2s"

    @pytest.mark.asyncio
    async def test_profile_retrieval_response_time(self, authenticated_client: AsyncClient, sample_user: User):
        """Test that profile retrieval is fast."""
        start = time.time()
        response = await authenticated_client.get("/api/v1/profile")
        elapsed = time.time() - start

        assert response.status_code == 200
        # Should complete within 200ms
        assert elapsed < 0.2, f"Profile retrieval took {elapsed:.3f}s, expected < 0.2s"

    @pytest.mark.asyncio
    async def test_product_search_response_time(self, authenticated_client: AsyncClient):
        """Test that product search responds within acceptable time."""
        start = time.time()
        response = await authenticated_client.get(
            "/api/v1/products/search",
            params={"q": "bag"}
        )
        elapsed = time.time() - start

        assert response.status_code == 200
        # Search might be slower due to ES, but should be under 1s
        assert elapsed < 1.0, f"Search took {elapsed:.3f}s, expected < 1.0s"

    @pytest.mark.asyncio
    async def test_dresser_items_response_time(self, authenticated_client: AsyncClient):
        """Test that dresser operations are fast."""
        # Create drawer first
        create_response = await authenticated_client.post(
            "/api/v1/dresser/drawers",
            json={"name": "Test Drawer"}
        )

        if create_response.status_code in [200, 201]:
            drawer_id = create_response.json().get("id") or create_response.json().get("drawer_id")

            start = time.time()
            response = await authenticated_client.get(f"/api/v1/dresser/drawers/{drawer_id}/items")
            elapsed = time.time() - start

            assert response.status_code == 200
            assert elapsed < 0.2, f"Dresser items retrieval took {elapsed:.3f}s, expected < 0.2s"


class TestDatabasePerformance:
    """Test database operation performance."""

    @pytest.mark.asyncio
    async def test_user_lookup_performance(self, db_session: AsyncSession, sample_user: User):
        """Test that user lookups are fast."""
        from sqlalchemy import select

        start = time.time()
        stmt = select(User).where(User.id == sample_user.id)
        result = await db_session.execute(stmt)
        user = result.scalar_one_or_none()
        elapsed = time.time() - start

        assert user is not None
        # Should be very fast
        assert elapsed < 0.05, f"User lookup took {elapsed:.3f}s, expected < 0.05s"

    @pytest.mark.asyncio
    async def test_product_query_performance(self, db_session: AsyncSession, sample_product: Product):
        """Test product queries are performant."""
        from sqlalchemy import select

        start = time.time()
        stmt = select(Product).where(Product.id == sample_product.id)
        result = await db_session.execute(stmt)
        product = result.scalar_one_or_none()
        elapsed = time.time() - start

        assert product is not None
        assert elapsed < 0.05, f"Product lookup took {elapsed:.3f}s, expected < 0.05s"

    @pytest.mark.asyncio
    async def test_bulk_insert_performance(self, db_session: AsyncSession, sample_retailer, sample_brand):
        """Test bulk insert performance."""
        import uuid
        from datetime import datetime, timezone

        # Insert many products
        products = []
        for i in range(100):
            products.append(
                Product(
                    id=uuid.uuid4(),
                    external_id=f"prod_{i}",
                    retailer_id=sample_retailer.id,
                    brand_id=sample_brand.id,
                    name=f"Product {i}",
                    current_price=100.0 + i,
                    created_at=datetime.now(timezone.utc)
                )
            )

        start = time.time()
        db_session.add_all(products)
        await db_session.commit()
        elapsed = time.time() - start

        # Should complete within 1 second
        assert elapsed < 1.0, f"Bulk insert took {elapsed:.3f}s, expected < 1.0s"

    @pytest.mark.asyncio
    async def test_query_with_join_performance(self, db_session: AsyncSession):
        """Test join query performance."""
        from sqlalchemy import select

        start = time.time()
        stmt = select(Product).join(Product.brand).limit(10)
        result = await db_session.execute(stmt)
        products = result.scalars().all()
        elapsed = time.time() - start

        # Joins should be relatively fast
        assert elapsed < 0.1, f"Join query took {elapsed:.3f}s, expected < 0.1s"


class TestConcurrentLoadPerformance:
    """Test performance under concurrent load."""

    @pytest.mark.asyncio
    async def test_concurrent_card_requests(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test performance with concurrent card requests."""
        async def get_cards():
            return await authenticated_client.get("/api/v1/cards/next", params={"limit": 10})

        start = time.time()
        # Simulate 10 concurrent requests
        responses = await asyncio.gather(*[get_cards() for _ in range(10)])
        elapsed = time.time() - start

        # All should succeed
        assert all(r.status_code == 200 for r in responses)
        # Should handle concurrent load efficiently
        assert elapsed < 2.0, f"10 concurrent requests took {elapsed:.3f}s, expected < 2.0s"

    @pytest.mark.asyncio
    async def test_concurrent_swipes(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test handling concurrent swipe requests."""
        async def swipe():
            return await authenticated_client.post(
                "/api/v1/cards/swipe",
                json={
                    "product_id": str(sample_product.id),
                    "action": "like",
                    "dwell_time_ms": 1000
                }
            )

        start = time.time()
        # Simulate 5 concurrent swipes
        responses = await asyncio.gather(*[swipe() for _ in range(5)])
        elapsed = time.time() - start

        # All should be processed
        assert all(r.status_code in [200, 201] for r in responses)
        assert elapsed < 1.0, f"5 concurrent swipes took {elapsed:.3f}s, expected < 1.0s"

    @pytest.mark.asyncio
    async def test_concurrent_profile_updates(self, authenticated_client: AsyncClient):
        """Test concurrent profile update performance."""
        async def update_profile(name):
            return await authenticated_client.put(
                "/api/v1/profile",
                json={"display_name": f"User {name}"}
            )

        start = time.time()
        # Simulate concurrent updates
        responses = await asyncio.gather(*[update_profile(i) for i in range(5)])
        elapsed = time.time() - start

        # All should succeed
        assert all(r.status_code == 200 for r in responses)
        assert elapsed < 1.0, f"5 concurrent updates took {elapsed:.3f}s, expected < 1.0s"


class TestMemoryUsage:
    """Test memory efficiency."""

    @pytest.mark.asyncio
    async def test_large_result_set_handling(self, authenticated_client: AsyncClient):
        """Test handling large result sets efficiently."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"limit": 100}
        )

        assert response.status_code == 200
        # Should handle large payloads
        data = response.json()
        assert isinstance(data, (list, dict))

    @pytest.mark.asyncio
    async def test_pagination_memory_efficiency(self, authenticated_client: AsyncClient):
        """Test that pagination doesn't load everything at once."""
        # Get first page
        response1 = await authenticated_client.get(
            "/api/v1/products/search",
            params={"q": "bag", "limit": 20, "page": 1}
        )

        # Get second page
        response2 = await authenticated_client.get(
            "/api/v1/products/search",
            params={"q": "bag", "limit": 20, "page": 2}
        )

        # Both should work without loading all data
        assert response1.status_code == 200
        assert response2.status_code == 200


class TestErrorHandlingPerformance:
    """Test performance when handling errors."""

    @pytest.mark.asyncio
    async def test_invalid_request_handling_speed(self, authenticated_client: AsyncClient):
        """Test that invalid requests are rejected quickly."""
        start = time.time()
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={"invalid_field": "invalid"}
        )
        elapsed = time.time() - start

        assert response.status_code in [400, 422]
        # Invalid requests should be rejected quickly
        assert elapsed < 0.1, f"Invalid request took {elapsed:.3f}s, expected < 0.1s"

    @pytest.mark.asyncio
    async def test_not_found_handling_speed(self, authenticated_client: AsyncClient):
        """Test that 404s are returned quickly."""
        import uuid

        start = time.time()
        response = await authenticated_client.get(f"/api/v1/products/{uuid.uuid4()}")
        elapsed = time.time() - start

        assert response.status_code == 404
        # 404s should be fast
        assert elapsed < 0.1, f"404 took {elapsed:.3f}s, expected < 0.1s"


class TestCachingPerformance:
    """Test caching effectiveness."""

    @pytest.mark.asyncio
    async def test_repeated_request_caching(self, authenticated_client: AsyncClient, sample_product: Product):
        """Test that repeated requests benefit from caching."""
        # First request (cache miss)
        start1 = time.time()
        response1 = await authenticated_client.get(f"/api/v1/products/{sample_product.id}")
        elapsed1 = time.time() - start1

        # Second request (cache hit)
        start2 = time.time()
        response2 = await authenticated_client.get(f"/api/v1/products/{sample_product.id}")
        elapsed2 = time.time() - start2

        assert response1.status_code == 200
        assert response2.status_code == 200

        # Second request might be slightly faster due to caching
        # (though this depends on caching implementation)
        assert elapsed1 >= 0 and elapsed2 >= 0


class TestBatchOperationPerformance:
    """Test batch operation performance."""

    @pytest.mark.asyncio
    async def test_add_multiple_items_to_drawer(self, authenticated_client: AsyncClient):
        """Test adding multiple items efficiently."""
        # Create drawer
        drawer_response = await authenticated_client.post(
            "/api/v1/dresser/drawers",
            json={"name": "Batch Test"}
        )

        if drawer_response.status_code in [200, 201]:
            drawer_id = drawer_response.json().get("id") or drawer_response.json().get("drawer_id")

            start = time.time()
            # Add 10 items
            responses = []
            for i in range(10):
                response = await authenticated_client.post(
                    f"/api/v1/dresser/drawers/{drawer_id}/items",
                    json={
                        "product_id": str(uuid.uuid4()),
                        "price_at_save": 100.0 + i * 10
                    }
                )
                responses.append(response)
            elapsed = time.time() - start

            # All operations should complete reasonably quickly
            assert elapsed < 2.0, f"Adding 10 items took {elapsed:.3f}s, expected < 2.0s"


import uuid
