"""Product endpoint tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_get_product_detail(
    authenticated_client: AsyncClient,
    sample_product
):
    """Test getting product detail."""
    response = await authenticated_client.get(
        f"/api/v1/products/{sample_product.id}"
    )

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(sample_product.id)
    assert data["name"] == sample_product.name
    assert data["current_price"] == sample_product.current_price


@pytest.mark.asyncio
async def test_get_product_detail_nonexistent(authenticated_client: AsyncClient):
    """Test getting nonexistent product."""
    import uuid
    response = await authenticated_client.get(
        f"/api/v1/products/{uuid.uuid4()}"
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_get_product_with_related_info(
    authenticated_client: AsyncClient,
    sample_product
):
    """Test product response includes brand, retailer info."""
    response = await authenticated_client.get(
        f"/api/v1/products/{sample_product.id}"
    )

    assert response.status_code == 200
    data = response.json()
    assert "brand" in data or "brand_id" in data
    assert "retailer" in data or "retailer_id" in data


@pytest.mark.asyncio
async def test_get_similar_products(
    authenticated_client: AsyncClient,
    sample_product,
    db_session: AsyncSession,
    sample_retailer,
    sample_brand
):
    """Test getting similar products."""
    from app.models import Product

    # Create a similar product
    similar = Product(
        external_id="similar_prod",
        retailer_id=sample_retailer.id,
        brand_id=sample_brand.id,
        name="Similar Bag",
        category=sample_product.category,
        current_price=500.0,
        product_url="https://example.com/similar"
    )
    db_session.add(similar)
    await db_session.commit()

    response = await authenticated_client.get(
        f"/api/v1/products/{sample_product.id}/similar"
    )

    assert response.status_code == 200
    data = response.json()
    assert "products" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_get_affiliate_link(
    authenticated_client: AsyncClient,
    sample_product
):
    """Test getting affiliate link for product."""
    response = await authenticated_client.get(
        f"/api/v1/products/{sample_product.id}/affiliate-link"
    )

    assert response.status_code == 200
    data = response.json()
    assert "url" in data or "affiliate_url" in data


@pytest.mark.asyncio
async def test_search_products(authenticated_client: AsyncClient):
    """Test searching products."""
    response = await authenticated_client.get(
        "/api/v1/products/search",
        params={"q": "bag"}
    )

    assert response.status_code == 200
    data = response.json()
    assert "products" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_filter_products_by_category(
    authenticated_client: AsyncClient,
    sample_product
):
    """Test filtering products by category."""
    response = await authenticated_client.get(
        "/api/v1/products",
        params={"category": "Bags"}
    )

    assert response.status_code == 200
    data = response.json()
    assert "products" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_filter_products_by_brand(
    authenticated_client: AsyncClient,
    sample_product,
    sample_brand
):
    """Test filtering products by brand."""
    response = await authenticated_client.get(
        "/api/v1/products",
        params={"brand_id": str(sample_brand.id)}
    )

    assert response.status_code == 200
    data = response.json()
    assert "products" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_filter_products_by_price_range(authenticated_client: AsyncClient):
    """Test filtering products by price range."""
    response = await authenticated_client.get(
        "/api/v1/products",
        params={"price_min": 100, "price_max": 500}
    )

    assert response.status_code == 200
    data = response.json()
    assert "products" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_get_on_sale_products(
    authenticated_client: AsyncClient,
    sample_product
):
    """Test getting products on sale."""
    response = await authenticated_client.get(
        "/api/v1/products",
        params={"on_sale": True}
    )

    assert response.status_code == 200
    data = response.json()
    assert "products" in data or isinstance(data, list)
    # sample_product is on sale, so should be included
    if isinstance(data, dict) and "products" in data:
        product_ids = [p.get("id") for p in data["products"]]
        assert str(sample_product.id) in product_ids
