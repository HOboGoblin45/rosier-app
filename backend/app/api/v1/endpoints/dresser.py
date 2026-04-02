"""Dresser (closet) endpoints."""
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import get_db, verify_access_token, extract_bearer_token
from app.models import User, DresserDrawer, DresserItem, Product
from app.schemas import (
    DrawerCreate,
    DrawerResponse,
    DrawerUpdate,
    DresserItemAdd,
    DresserItemMove,
    DresserItemResponse,
    DresserResponse,
    SharedDrawerResponse,
)

router = APIRouter(prefix="/dresser", tags=["dresser"])


async def get_current_user(
    db: Annotated[AsyncSession, Depends(get_db)],
    authorization: Annotated[Optional[str], Header()] = None,
) -> User:
    """Get current authenticated user from Bearer token."""
    # Extract and verify bearer token
    token = extract_bearer_token(authorization)
    user_id = verify_access_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    return user


@router.get("")
async def get_dresser(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DresserResponse:
    """Get user's complete dresser (all drawers and items)."""
    # Get drawers
    drawers_stmt = (
        select(DresserDrawer)
        .where(DresserDrawer.user_id == user.id)
        .order_by(DresserDrawer.sort_order)
    )
    drawers_result = await db.execute(drawers_stmt)
    drawers = drawers_result.scalars().all()

    # Get items
    items_stmt = select(DresserItem).where(DresserItem.user_id == user.id)
    items_result = await db.execute(items_stmt)
    items = items_result.scalars().all()

    return DresserResponse(
        drawers=[
            DrawerResponse.from_orm(d) for d in drawers
        ],
        items=[
            DresserItemResponse.from_orm(i) for i in items
        ],
    )


@router.post("/drawers", response_model=DrawerResponse)
async def create_drawer(
    drawer_create: DrawerCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DrawerResponse:
    """Create a new dresser drawer."""
    # Get max sort order
    stmt = select(DresserDrawer).where(DresserDrawer.user_id == user.id)
    result = await db.execute(stmt)
    existing = result.scalars().all()
    max_order = max([d.sort_order for d in existing], default=-1)

    drawer = DresserDrawer(
        user_id=user.id,
        name=drawer_create.name,
        is_default=drawer_create.is_default,
        sort_order=max_order + 1,
    )
    db.add(drawer)
    await db.commit()
    await db.refresh(drawer)

    return DrawerResponse.from_orm(drawer)


@router.put("/drawers/{drawer_id}", response_model=DrawerResponse)
async def update_drawer(
    drawer_id: UUID,
    drawer_update: DrawerUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DrawerResponse:
    """Update a dresser drawer."""
    stmt = select(DresserDrawer).where(
        and_(DresserDrawer.id == drawer_id, DresserDrawer.user_id == user.id)
    )
    result = await db.execute(stmt)
    drawer = result.scalar_one_or_none()

    if not drawer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Drawer not found",
        )

    if drawer_update.name:
        drawer.name = drawer_update.name
    if drawer_update.sort_order is not None:
        drawer.sort_order = drawer_update.sort_order

    await db.commit()
    await db.refresh(drawer)

    return DrawerResponse.from_orm(drawer)


@router.delete("/drawers/{drawer_id}")
async def delete_drawer(
    drawer_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Delete a dresser drawer."""
    stmt = select(DresserDrawer).where(
        and_(DresserDrawer.id == drawer_id, DresserDrawer.user_id == user.id)
    )
    result = await db.execute(stmt)
    drawer = result.scalar_one_or_none()

    if not drawer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Drawer not found",
        )

    # Delete associated items
    items_stmt = select(DresserItem).where(DresserItem.drawer_id == drawer_id)
    items_result = await db.execute(items_stmt)
    items = items_result.scalars().all()

    for item in items:
        await db.delete(item)

    await db.delete(drawer)
    await db.commit()

    return {"message": "Drawer deleted"}


@router.post("/items", response_model=DresserItemResponse)
async def add_dresser_item(
    item_add: DresserItemAdd,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DresserItemResponse:
    """Add an item to a dresser drawer."""
    # Check drawer belongs to user
    drawer_stmt = select(DresserDrawer).where(
        and_(
            DresserDrawer.id == item_add.drawer_id,
            DresserDrawer.user_id == user.id,
        )
    )
    drawer_result = await db.execute(drawer_stmt)
    drawer = drawer_result.scalar_one_or_none()

    if not drawer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Drawer not found",
        )

    # Get product to store price
    product_stmt = select(Product).where(Product.id == item_add.product_id)
    product_result = await db.execute(product_stmt)
    product = product_result.scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    item = DresserItem(
        user_id=user.id,
        product_id=item_add.product_id,
        drawer_id=item_add.drawer_id,
        price_at_save=item_add.price_at_save or product.current_price,
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)

    return DresserItemResponse.from_orm(item)


@router.delete("/items/{item_id}")
async def remove_dresser_item(
    item_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Remove an item from the dresser."""
    stmt = select(DresserItem).where(
        and_(DresserItem.id == item_id, DresserItem.user_id == user.id)
    )
    result = await db.execute(stmt)
    item = result.scalar_one_or_none()

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found",
        )

    await db.delete(item)
    await db.commit()

    return {"message": "Item removed"}


@router.put("/items/{item_id}/move")
async def move_dresser_item(
    item_id: UUID,
    move_request: DresserItemMove,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DresserItemResponse:
    """Move an item to a different drawer."""
    stmt = select(DresserItem).where(
        and_(DresserItem.id == item_id, DresserItem.user_id == user.id)
    )
    result = await db.execute(stmt)
    item = result.scalar_one_or_none()

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found",
        )

    # Verify target drawer belongs to user
    drawer_stmt = select(DresserDrawer).where(
        and_(
            DresserDrawer.id == move_request.drawer_id,
            DresserDrawer.user_id == user.id,
        )
    )
    drawer_result = await db.execute(drawer_stmt)
    drawer = drawer_result.scalar_one_or_none()

    if not drawer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Drawer not found",
        )

    item.drawer_id = move_request.drawer_id
    await db.commit()
    await db.refresh(item)

    return DresserItemResponse.from_orm(item)


@router.get("/share/{drawer_id}")
async def get_shared_drawer(
    drawer_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SharedDrawerResponse:
    """Get a public shared drawer (no authentication required)."""
    drawer_stmt = select(DresserDrawer).where(DresserDrawer.id == drawer_id)
    drawer_result = await db.execute(drawer_stmt)
    drawer = drawer_result.scalar_one_or_none()

    if not drawer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Drawer not found",
        )

    # Get drawer items
    items_stmt = select(DresserItem).where(DresserItem.drawer_id == drawer_id)
    items_result = await db.execute(items_stmt)
    items = items_result.scalars().all()

    # Get user
    user = await db.get(User, drawer.user_id)

    return SharedDrawerResponse(
        drawer_id=drawer.id,
        drawer_name=drawer.name,
        user_display_name=user.display_name if user else None,
        item_count=len(items),
        items=[
            {
                "product_id": str(i.product_id),
                "price_at_save": i.price_at_save,
            }
            for i in items
        ],
    )
