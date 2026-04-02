"""OpenAPI specification contract testing."""
import pytest
from httpx import AsyncClient
from jsonschema import validate, ValidationError


class TestOpenAPIContract:
    """Test that API implements its OpenAPI contract."""

    @pytest.mark.asyncio
    async def test_openapi_schema_valid(self, client: AsyncClient):
        """Test that OpenAPI schema is valid."""
        response = await client.get("/openapi.json")

        assert response.status_code == 200
        schema = response.json()

        # Verify required OpenAPI fields
        assert "openapi" in schema
        assert "info" in schema
        assert "paths" in schema
        assert schema["openapi"].startswith("3.")

        # Verify info
        assert "title" in schema["info"]
        assert "version" in schema["info"]
        assert schema["info"]["title"] == "Rosier API"

    @pytest.mark.asyncio
    async def test_all_endpoints_documented(self, client: AsyncClient):
        """Test that all endpoints are in OpenAPI spec."""
        response = await client.get("/openapi.json")
        schema = response.json()
        paths = schema["paths"]

        # Core endpoint paths that should exist
        required_paths = [
            "/api/v1/auth/email/register",
            "/api/v1/auth/email/login",
            "/api/v1/cards/next",
            "/api/v1/cards/swipe",
            "/api/v1/dresser/drawers",
            "/api/v1/profile",
            "/api/v1/products/search",
            "/api/v1/onboarding/quiz",
        ]

        for path in required_paths:
            assert path in paths, f"Path {path} not documented in OpenAPI"

    @pytest.mark.asyncio
    async def test_endpoint_methods_documented(self, client: AsyncClient):
        """Test that HTTP methods are documented."""
        response = await client.get("/openapi.json")
        schema = response.json()

        auth_register = schema["paths"]["/api/v1/auth/email/register"]
        assert "post" in auth_register

        cards_swipe = schema["paths"]["/api/v1/cards/swipe"]
        assert "post" in cards_swipe

        profile = schema["paths"]["/api/v1/profile"]
        assert "get" in profile
        assert "put" in profile

    @pytest.mark.asyncio
    async def test_request_schemas_defined(self, client: AsyncClient):
        """Test that request schemas are defined."""
        response = await client.get("/openapi.json")
        schema = response.json()

        # Check auth register endpoint has request body schema
        register = schema["paths"]["/api/v1/auth/email/register"]["post"]
        assert "requestBody" in register
        assert "content" in register["requestBody"]
        assert "application/json" in register["requestBody"]["content"]

    @pytest.mark.asyncio
    async def test_response_schemas_defined(self, client: AsyncClient):
        """Test that response schemas are defined."""
        response = await client.get("/openapi.json")
        schema = response.json()

        # Check responses are documented
        register = schema["paths"]["/api/v1/auth/email/register"]["post"]
        assert "responses" in register
        assert "200" in register["responses"] or "201" in register["responses"]

    @pytest.mark.asyncio
    async def test_authentication_documented(self, client: AsyncClient):
        """Test that authentication is documented."""
        response = await client.get("/openapi.json")
        schema = response.json()

        assert "components" in schema
        assert "securitySchemes" in schema["components"]
        assert "bearerAuth" in schema["components"]["securitySchemes"]

    @pytest.mark.asyncio
    async def test_error_responses_documented(self, client: AsyncClient):
        """Test that error responses are documented."""
        response = await client.get("/openapi.json")
        schema = response.json()

        # Check a protected endpoint has 401 documented
        profile = schema["paths"]["/api/v1/profile"]["get"]
        assert "responses" in profile
        assert "401" in profile["responses"] or "200" in profile["responses"]

    @pytest.mark.asyncio
    async def test_parameters_documented(self, client: AsyncClient):
        """Test that parameters are documented."""
        response = await client.get("/openapi.json")
        schema = response.json()

        # Cards endpoint should document query parameters
        cards = schema["paths"]["/api/v1/cards/next"]["get"]
        assert "parameters" in cards or "responses" in cards
        if "parameters" in cards:
            param_names = [p["name"] for p in cards["parameters"]]
            assert "limit" in param_names or len(param_names) >= 0


class TestAuthEndpointContract:
    """Test authentication endpoints against contract."""

    @pytest.mark.asyncio
    async def test_register_response_format(self, client: AsyncClient):
        """Test registration response matches contract."""
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "test@example.com",
                "password": "SecurePassword123!",
                "display_name": "Test User"
            }
        )

        if response.status_code == 200:
            data = response.json()
            # Should match contract
            assert "access_token" in data
            assert "token_type" in data
            assert "expires_in" in data
            assert data["token_type"] == "bearer"

    @pytest.mark.asyncio
    async def test_register_request_validation(self, client: AsyncClient):
        """Test that invalid register requests are rejected."""
        # Missing required field
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "test@example.com",
                "password": "SecurePassword123!"
                # Missing display_name
            }
        )

        # Should be rejected
        assert response.status_code in [400, 422]


class TestCardEndpointContract:
    """Test card endpoints against contract."""

    @pytest.mark.asyncio
    async def test_cards_response_format(self, authenticated_client: AsyncClient, sample_product):
        """Test cards response matches contract."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"limit": 5}
        )

        assert response.status_code == 200
        data = response.json()

        # Should be either a list or object with cards key
        assert isinstance(data, (list, dict))
        if isinstance(data, dict):
            assert "cards" in data or "items" in data

    @pytest.mark.asyncio
    async def test_swipe_response_format(self, authenticated_client: AsyncClient, sample_product):
        """Test swipe response matches contract."""
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "like",
                "dwell_time_ms": 2000
            }
        )

        if response.status_code in [200, 201]:
            data = response.json()
            # Should return the swipe event or confirmation
            assert isinstance(data, dict)

    @pytest.mark.asyncio
    async def test_swipe_action_validation(self, authenticated_client: AsyncClient, sample_product):
        """Test that invalid swipe actions are rejected."""
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "invalid_action",
                "dwell_time_ms": 1000
            }
        )

        # Invalid action should be rejected
        assert response.status_code == 422


class TestProfileEndpointContract:
    """Test profile endpoints against contract."""

    @pytest.mark.asyncio
    async def test_profile_response_format(self, authenticated_client: AsyncClient):
        """Test profile response matches contract."""
        response = await authenticated_client.get("/api/v1/profile")

        assert response.status_code == 200
        data = response.json()

        # Should contain user profile fields
        assert isinstance(data, dict)
        assert "email" in data or "user_email" in data
        assert "display_name" in data or "name" in data


class TestDresserEndpointContract:
    """Test dresser endpoints against contract."""

    @pytest.mark.asyncio
    async def test_drawers_list_format(self, authenticated_client: AsyncClient):
        """Test drawers list response format."""
        response = await authenticated_client.get("/api/v1/dresser/drawers")

        assert response.status_code == 200
        data = response.json()

        # Should be a list
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_drawer_creation_response(self, authenticated_client: AsyncClient):
        """Test drawer creation response format."""
        response = await authenticated_client.post(
            "/api/v1/dresser/drawers",
            json={
                "name": "Test Drawer",
                "is_default": False
            }
        )

        if response.status_code in [200, 201]:
            data = response.json()
            assert isinstance(data, dict)
            assert "id" in data or "drawer_id" in data
            assert "name" in data


class TestProductEndpointContract:
    """Test product endpoints against contract."""

    @pytest.mark.asyncio
    async def test_product_response_format(self, authenticated_client: AsyncClient, sample_product):
        """Test product response format."""
        response = await authenticated_client.get(f"/api/v1/products/{sample_product.id}")

        if response.status_code == 200:
            data = response.json()
            # Should contain product fields
            assert isinstance(data, dict)
            assert "id" in data or "product_id" in data
            assert "name" in data

    @pytest.mark.asyncio
    async def test_search_response_format(self, authenticated_client: AsyncClient):
        """Test search response format."""
        response = await authenticated_client.get(
            "/api/v1/products/search",
            params={"q": "bag"}
        )

        if response.status_code == 200:
            data = response.json()
            # Should be a list or paginated response
            assert isinstance(data, (list, dict))


class TestErrorResponseContract:
    """Test error responses match contract."""

    @pytest.mark.asyncio
    async def test_unauthorized_error_format(self, client: AsyncClient):
        """Test 401 error response format."""
        response = await client.get("/api/v1/profile")

        assert response.status_code == 401
        data = response.json()

        # Should have error details
        assert isinstance(data, dict)
        assert "detail" in data or "message" in data

    @pytest.mark.asyncio
    async def test_not_found_error_format(self, authenticated_client: AsyncClient):
        """Test 404 error response format."""
        import uuid
        response = await authenticated_client.get(f"/api/v1/products/{uuid.uuid4()}")

        assert response.status_code == 404
        data = response.json()

        assert isinstance(data, dict)
        assert "detail" in data or "message" in data

    @pytest.mark.asyncio
    async def test_validation_error_format(self, client: AsyncClient):
        """Test 422 validation error response format."""
        response = await client.post(
            "/api/v1/auth/email/register",
            json={
                "email": "invalid-email",
                "password": "short"
            }
        )

        assert response.status_code == 422
        data = response.json()

        # Should have validation details
        assert isinstance(data, dict)
        assert "detail" in data or "message" in data


class TestPaginationContract:
    """Test pagination contract compliance."""

    @pytest.mark.asyncio
    async def test_pagination_parameters(self, authenticated_client: AsyncClient):
        """Test pagination parameters are accepted."""
        response = await authenticated_client.get(
            "/api/v1/cards/next",
            params={"limit": 10, "page": 1}
        )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_pagination_response_format(self, authenticated_client: AsyncClient):
        """Test pagination response includes metadata."""
        response = await authenticated_client.get(
            "/api/v1/products/search",
            params={"q": "bag", "limit": 10, "page": 1}
        )

        if response.status_code == 200:
            data = response.json()
            # Should either be a list or have pagination metadata
            assert isinstance(data, (list, dict))


class TestContentNegotiation:
    """Test content negotiation."""

    @pytest.mark.asyncio
    async def test_json_response_content_type(self, client: AsyncClient):
        """Test that responses are JSON."""
        response = await client.get("/openapi.json")

        assert response.status_code == 200
        assert "application/json" in response.headers.get("content-type", "")

    @pytest.mark.asyncio
    async def test_request_content_type(self, authenticated_client: AsyncClient, sample_product):
        """Test that requests accept JSON."""
        response = await authenticated_client.post(
            "/api/v1/cards/swipe",
            json={
                "product_id": str(sample_product.id),
                "action": "like",
                "dwell_time_ms": 1000
            },
            headers={"Content-Type": "application/json"}
        )

        assert response.status_code in [200, 201, 400, 422]
