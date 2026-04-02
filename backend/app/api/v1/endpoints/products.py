"""Product endpoints."""
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import get_db
from app.models import Product, Brand, Retailer
from app.schemas import ProductDetail, SimilarProduct
from app.services import RecommendationService, AffiliateService

router = APIRouter(prefix="/products", tags=["products"])


@router.get("/{product_id}", response_model=ProductDetail)
async def get_product(
    product_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ProductDetail:
    """Get product details."""
    stmt = select(Product).where(Product.id == product_id)
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    return ProductDetail.from_orm(product)


@router.get("/{product_id}/similar")
async def get_similar_products(
    product_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    count: int = Query(4, ge=1, le=20),
) -> dict:
    """Get similar products for recommendations."""
    # Verify product exists
    stmt = select(Product).where(Product.id == product_id)
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    # Get similar products
    similar = await RecommendationService.get_similar_products(
        db, str(product_id), limit=count
    )

    return {
        "product_id": str(product_id),
        "similar_products": similar,
        "count": len(similar),
    }


@router.get("/{product_id}/affiliate_link")
async def get_affiliate_link(
    product_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user_id: str = Query(None),
) -> dict:
    """Get affiliate link for a product."""
    # Verify product exists
    stmt = select(Product).where(Product.id == product_id)
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    # Get affiliate link
    affiliate_link = await AffiliateService.get_affiliate_link(
        db, str(product_id), user_id
    )

    if not affiliate_link:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No affiliate link available for this product",
        )

    return {
        "product_id": str(product_id),
        "affiliate_link": affiliate_link,
        "direct_link": product.product_url,
    }
