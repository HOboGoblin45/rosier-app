"""Sale events API endpoints."""

import logging
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models import SaleEvent, Retailer, Product

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/sales", tags=["sales"])


class SaleEventResponse(BaseModel):
    """Sale event response."""

    id: uuid.UUID
    retailer_id: uuid.UUID
    retailer_name: str
    name: str
    description: str = None
    start_date: datetime
    end_date: datetime
    is_active: bool
    items_in_dresser: int


class SaleEventDetailResponse(SaleEventResponse):
    """Detailed sale event response with products."""

    products: list[dict] = []


class SaleNotificationRequest(BaseModel):
    """Request to opt-in to sale notifications."""

    pass


@router.get("")
async def list_sales(
    page: int = 1,
    size: int = 20,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Get upcoming sale events with item counts.

    Args:
        page: Page number (1-indexed)
        size: Results per page
        db: Database session

    Returns:
        Paginated list of sale events
    """
    if page < 1 or size < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Page and size must be positive integers",
        )

    offset = (page - 1) * size

    # Get active sales
    stmt = (
        select(SaleEvent)
        .where(SaleEvent.is_active)
        .order_by(SaleEvent.start_date)
        .offset(offset)
        .limit(size)
    )
    result = await db.execute(stmt)
    sales = result.scalars().all()

    # For each sale, count items from that retailer in user's dresser
    # In production, filter by authenticated user
    sale_responses = []
    for sale in sales:
        # Get retailer info
        retailer_stmt = select(Retailer).where(Retailer.id == sale.retailer_id)
        retailer_result = await db.execute(retailer_stmt)
        retailer = retailer_result.scalar_one_or_none()

        # Count items in dresser from this retailer (placeholder)
        items_in_dresser = 0

        sale_responses.append(
            {
                "id": sale.id,
                "retailer_id": sale.retailer_id,
                "retailer_name": retailer.name if retailer else "",
                "name": sale.name,
                "description": sale.description,
                "start_date": sale.start_date,
                "end_date": sale.end_date,
                "is_active": sale.is_active,
                "items_in_dresser": items_in_dresser,
            }
        )

    # Get total count
    count_stmt = select(func.count(SaleEvent.id)).where(SaleEvent.is_active)
    count_result = await db.execute(count_stmt)
    total = count_result.scalar()

    return {
        "sales": sale_responses,
        "total": total,
        "page": page,
        "size": size,
    }


@router.get("/{sale_id}")
async def get_sale_detail(
    sale_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> SaleEventDetailResponse:
    """
    Get detailed information about a specific sale event.

    Args:
        sale_id: Sale event ID
        db: Database session

    Returns:
        Detailed sale event with products
    """
    stmt = select(SaleEvent).where(SaleEvent.id == sale_id)
    result = await db.execute(stmt)
    sale = result.scalar_one_or_none()

    if not sale:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sale event not found",
        )

    # Get retailer info
    retailer_stmt = select(Retailer).where(Retailer.id == sale.retailer_id)
    retailer_result = await db.execute(retailer_stmt)
    retailer = retailer_result.scalar_one_or_none()

    # Get products from this retailer (placeholder for filtering by sale)
    products_stmt = select(Product).where(
        Product.retailer_id == sale.retailer_id,
        Product.is_active,
    )
    products_result = await db.execute(products_stmt)
    products = products_result.scalars().all()

    return SaleEventDetailResponse(
        id=sale.id,
        retailer_id=sale.retailer_id,
        retailer_name=retailer.name if retailer else "",
        name=sale.name,
        description=sale.description,
        start_date=sale.start_date,
        end_date=sale.end_date,
        is_active=sale.is_active,
        items_in_dresser=0,
        products=[
            {
                "id": p.id,
                "name": p.name,
                "current_price": p.current_price,
                "original_price": p.original_price,
                "is_on_sale": p.is_on_sale,
                "image_urls": p.image_urls,
            }
            for p in products
        ],
    )


@router.post("/{sale_id}/notify")
async def opt_in_sale_notification(
    sale_id: uuid.UUID,
    request: SaleNotificationRequest,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Opt-in to notifications for a specific sale event.

    Args:
        sale_id: Sale event ID
        request: Opt-in request
        db: Database session

    Returns:
        Confirmation
    """
    stmt = select(SaleEvent).where(SaleEvent.id == sale_id)
    result = await db.execute(stmt)
    sale = result.scalar_one_or_none()

    if not sale:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sale event not found",
        )

    # In production, store user opt-in preference in a user_sale_subscriptions table
    # and queue a notification job

    return {"message": f"Opted in to notifications for {sale.name}"}
