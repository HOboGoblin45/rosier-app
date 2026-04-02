"""Product schemas."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, HttpUrl


class ProductCard(BaseModel):
    """Product card for swipe feed."""

    id: UUID
    name: str
    current_price: float
    original_price: Optional[float] = None
    is_on_sale: bool
    image_urls: Optional[list[str]] = None
    category: Optional[str] = None
    brand_name: Optional[str] = None
    retailer_name: Optional[str] = None

    class Config:
        from_attributes = True


class ProductResponse(BaseModel):
    """Basic product response schema."""

    id: UUID
    name: str
    current_price: float
    original_price: Optional[float] = None
    currency: str
    is_on_sale: bool
    category: Optional[str] = None
    subcategory: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class ProductDetail(ProductResponse):
    """Detailed product schema."""

    description: Optional[str] = None
    sizes_available: Optional[dict] = None
    colors: Optional[dict] = None
    materials: Optional[dict] = None
    image_urls: Optional[list[str]] = None
    product_url: str
    affiliate_url: Optional[str] = None
    tags: Optional[dict] = None
    sale_end_date: Optional[datetime] = None
    image_quality_score: Optional[float] = None
    brand_id: Optional[UUID] = None
    retailer_id: UUID


class SimilarProduct(BaseModel):
    """Similar product schema for recommendations."""

    id: UUID
    name: str
    current_price: float
    image_urls: Optional[list[str]] = None
    similarity_score: float = Field(..., ge=0, le=1)

    class Config:
        from_attributes = True
