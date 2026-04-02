"""Dresser CRUD endpoint tests."""
import pytest
import uuid
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models import DresserDrawer, DresserItem


@pytest.mark.asyncio
async def test_create_drawer_success(
    authenticated_client: AsyncClient,
    db_session: AsyncSession
):
    """Test creating a new drawer."""
    response = await authenticated_client.post(
        "/api/v1/dresser/drawers",
        json={
            "name": "Winter Collection",
            "is_default": False
        }
    )

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Winter Collection"
    assert "id" in data


@pytest.mark.asyncio
async def test_create_default_drawer(
    authenticated_client: AsyncClient,
    db_session: AsyncSession
):
    """Test creating a default drawer."""
    response = await authenticated_client.post(
        "/api/v1/dresser/drawers",
        json={
            "name": "Favorites",
            "is_default": True
        }
    )

    assert response.status_code == 201
    data = response.json()
    assert data["is_default"] is True


@pytest.mark.asyncio
async def test_get_drawers(
    authenticated_client: AsyncClient,
    sample_drawer: DresserDrawer
):
    """Test getting all drawers."""
    response = await authenticated_client.get("/api/v1/dresser/drawers")

    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert data[0]["name"] == sample_drawer.name


@pytest.mark.asyncio
async def test_rename_drawer(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_drawer: DresserDrawer
):
    """Test renaming a drawer."""
    response = await authenticated_client.put(
        f"/api/v1/dresser/drawers/{sample_drawer.id}",
        json={"name": "Updated Name"}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Updated Name"

    # Verify in database
    stmt = select(DresserDrawer).where(DresserDrawer.id == sample_drawer.id)
    result = await db_session.execute(stmt)
    drawer = result.scalar_one()
    assert drawer.name == "Updated Name"


@pytest.mark.asyncio
async def test_delete_drawer(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_drawer: DresserDrawer
):
    """Test deleting a drawer."""
    response = await authenticated_client.delete(
        f"/api/v1/dresser/drawers/{sample_drawer.id}"
    )

    assert response.status_code in [200, 204]

    # Verify deleted
    stmt = select(DresserDrawer).where(DresserDrawer.id == sample_drawer.id)
    result = await db_session.execute(stmt)
    drawer = result.scalar_one_or_none()
    assert drawer is None


@pytest.mark.asyncio
async def test_delete_drawer_moves_items(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_dresser_item: DresserItem,
    sample_drawer: DresserDrawer
):
    """Test that deleting drawer moves items to default."""
    drawer_id = sample_drawer.id
    item_id = sample_dresser_item.id

    response = await authenticated_client.delete(
        f"/api/v1/dresser/drawers/{drawer_id}"
    )

    assert response.status_code in [200, 204]

    # Verify item exists but drawer is moved
    stmt = select(DresserItem).where(DresserItem.id == item_id)
    result = await db_session.execute(stmt)
    item = result.scalar_one_or_none()
    assert item is not None
    # Item should be in a different drawer (default)
    assert item.drawer_id != drawer_id


@pytest.mark.asyncio
async def test_add_item_to_dresser(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_product,
    sample_drawer: DresserDrawer
):
    """Test adding item to dresser."""
    response = await authenticated_client.post(
        "/api/v1/dresser/items",
        json={
            "product_id": str(sample_product.id),
            "drawer_id": str(sample_drawer.id),
            "price_at_save": 450.0
        }
    )

    assert response.status_code == 201
    data = response.json()
    assert data["product_id"] == str(sample_product.id)

    # Verify in database
    stmt = select(DresserItem).where(
        DresserItem.product_id == sample_product.id
    )
    result = await db_session.execute(stmt)
    item = result.scalar_one_or_none()
    assert item is not None


@pytest.mark.asyncio
async def test_add_duplicate_item(
    authenticated_client: AsyncClient,
    sample_dresser_item: DresserItem,
    sample_product
):
    """Test adding duplicate item to same drawer."""
    response = await authenticated_client.post(
        "/api/v1/dresser/items",
        json={
            "product_id": str(sample_product.id),
            "drawer_id": str(sample_dresser_item.drawer_id),
            "price_at_save": 450.0
        }
    )

    assert response.status_code == 409  # Conflict


@pytest.mark.asyncio
async def test_move_item_between_drawers(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    authenticated_user,
    sample_dresser_item: DresserItem,
    sample_product
):
    """Test moving item between drawers."""
    user, _ = authenticated_user

    # Create another drawer
    drawer2 = DresserDrawer(
        id=uuid.uuid4(),
        user_id=user.id,
        name="Another Drawer",
        sort_order=1
    )
    db_session.add(drawer2)
    await db_session.commit()

    response = await authenticated_client.put(
        f"/api/v1/dresser/items/{sample_dresser_item.id}",
        json={"drawer_id": str(drawer2.id)}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["drawer_id"] == str(drawer2.id)

    # Verify in database
    stmt = select(DresserItem).where(DresserItem.id == sample_dresser_item.id)
    result = await db_session.execute(stmt)
    item = result.scalar_one()
    assert item.drawer_id == drawer2.id


@pytest.mark.asyncio
async def test_remove_item(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    sample_dresser_item: DresserItem
):
    """Test removing item from dresser."""
    item_id = sample_dresser_item.id

    response = await authenticated_client.delete(
        f"/api/v1/dresser/items/{item_id}"
    )

    assert response.status_code in [200, 204]

    # Verify deleted
    stmt = select(DresserItem).where(DresserItem.id == item_id)
    result = await db_session.execute(stmt)
    item = result.scalar_one_or_none()
    assert item is None


@pytest.mark.asyncio
async def test_get_full_dresser(
    authenticated_client: AsyncClient,
    sample_drawer: DresserDrawer,
    sample_dresser_item: DresserItem
):
    """Test getting full dresser with all drawers and items."""
    response = await authenticated_client.get("/api/v1/dresser")

    assert response.status_code == 200
    data = response.json()
    assert "drawers" in data
    assert isinstance(data["drawers"], list)
    assert len(data["drawers"]) >= 1


@pytest.mark.asyncio
async def test_get_drawer_items(
    authenticated_client: AsyncClient,
    sample_drawer: DresserDrawer,
    sample_dresser_item: DresserItem
):
    """Test getting items in a specific drawer."""
    response = await authenticated_client.get(
        f"/api/v1/dresser/drawers/{sample_drawer.id}/items"
    )

    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1


@pytest.mark.asyncio
async def test_share_drawer_public(
    authenticated_client: AsyncClient,
    sample_drawer: DresserDrawer
):
    """Test sharing drawer publicly."""
    response = await authenticated_client.post(
        f"/api/v1/dresser/drawers/{sample_drawer.id}/share",
        json={"is_public": True}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["is_public"] is True


@pytest.mark.asyncio
async def test_reorder_drawers(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    authenticated_user
):
    """Test reordering drawers."""
    user, _ = authenticated_user

    # Create multiple drawers
    drawer1 = DresserDrawer(
        id=uuid.uuid4(),
        user_id=user.id,
        name="First",
        sort_order=0
    )
    drawer2 = DresserDrawer(
        id=uuid.uuid4(),
        user_id=user.id,
        name="Second",
        sort_order=1
    )
    db_session.add(drawer1)
    db_session.add(drawer2)
    await db_session.commit()

    # Reorder
    response = await authenticated_client.post(
        "/api/v1/dresser/reorder",
        json={
            "drawer_ids": [str(drawer2.id), str(drawer1.id)]
        }
    )

    assert response.status_code == 200


@pytest.mark.asyncio
async def test_get_item_detail(
    authenticated_client: AsyncClient,
    sample_dresser_item: DresserItem
):
    """Test getting detailed info for a dresser item."""
    response = await authenticated_client.get(
        f"/api/v1/dresser/items/{sample_dresser_item.id}"
    )

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(sample_dresser_item.id)
    assert "product" in data or "product_id" in data


@pytest.mark.asyncio
async def test_update_item_price(
    authenticated_client: AsyncClient,
    sample_dresser_item: DresserItem
):
    """Test updating price tracked for an item."""
    response = await authenticated_client.put(
        f"/api/v1/dresser/items/{sample_dresser_item.id}",
        json={"price_at_save": 399.99}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["price_at_save"] == 399.99
