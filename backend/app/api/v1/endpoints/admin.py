"""Admin dashboard API endpoints."""
from typing import Annotated, Optional
from datetime import datetime, timedelta, timezone
import uuid

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import get_db, verify_access_token
from app.models import Brand, Product, Retailer, SwipeEvent, User, BrandCandidate, BrandDiscoveryCard, Commission
from app.models.brand import BrandTier
from app.models.brand_candidate import BrandCandidateStatus
from app.models.swipe_event import SwipeAction
from app.schemas.user import UserResponse
from app.services import BrandDiscoveryService, AmbassadorTrackerService

router = APIRouter(prefix="/admin", tags=["admin"])


async def get_current_admin_user(
    authorization: str = None,
    db: AsyncSession = Depends(get_db)
) -> str:
    """Verify admin user from JWT token."""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )

    try:
        token = authorization.split(" ")[1]
    except IndexError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token format",
        )

    user_id = verify_access_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )

    # TODO: Check if user has admin role in actual implementation
    # For now, accept any authenticated user
    return user_id


# Brand Candidate Pipeline Management Endpoints

@router.get("/brand-candidates", response_model=dict)
async def list_brand_candidates(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    status_filter: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
) -> dict:
    """List brand candidates with filtering."""
    query = select(BrandCandidate)

    if status_filter:
        query = query.where(BrandCandidate.status == status_filter)

    query = query.order_by(BrandCandidate.fit_score.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    candidates = result.scalars().all()

    # Count total
    count_query = select(func.count(BrandCandidate.id))
    if status_filter:
        count_query = count_query.where(BrandCandidate.status == status_filter)
    count_result = await db.execute(count_query)
    total = count_result.scalar()

    return {
        "candidates": [
            {
                "id": str(c.id),
                "name": c.name,
                "website": c.website,
                "instagram": c.instagram,
                "price_range": {"low": c.price_range_low, "high": c.price_range_high},
                "status": c.status.value,
                "fit_score": c.fit_score,
                "commission_rate": c.commission_rate,
                "has_ambassador_program": c.has_ambassador_program,
                "created_at": c.created_at.isoformat(),
            }
            for c in candidates
        ],
        "total": total,
        "skip": skip,
        "limit": limit,
    }


@router.post("/brand-candidates", response_model=dict, status_code=201)
async def create_brand_candidate(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    name: str = None,
    website: Optional[str] = None,
    instagram: Optional[str] = None,
    price_range_low: Optional[float] = None,
    price_range_high: Optional[float] = None,
    aesthetic_tags: Optional[list[str]] = None,
    affiliate_network: Optional[str] = None,
    commission_rate: Optional[float] = None,
    has_ambassador_program: bool = False,
    ambassador_program_url: Optional[str] = None,
) -> dict:
    """Create a new brand candidate."""
    candidate = await BrandDiscoveryService.get_or_create_brand_candidate(
        db,
        name=name,
        website=website,
        instagram=instagram,
        price_range_low=price_range_low,
        price_range_high=price_range_high,
        aesthetic_tags=aesthetic_tags,
        affiliate_network=affiliate_network,
        commission_rate=commission_rate,
        has_ambassador_program=has_ambassador_program,
        ambassador_program_url=ambassador_program_url,
    )
    await db.commit()

    return {
        "id": str(candidate.id),
        "name": candidate.name,
        "status": candidate.status.value,
        "fit_score": candidate.fit_score,
    }


@router.post("/brand-candidates/{candidate_id}/approve", response_model=dict)
async def approve_brand_candidate(
    candidate_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    notes: Optional[str] = None,
) -> dict:
    """Approve a brand candidate for activation."""
    try:
        candidate = await BrandDiscoveryService.approve_brand_candidate(
            db, candidate_id, evaluation_notes=notes
        )
        await db.commit()

        return {
            "status": "approved",
            "candidate_id": candidate_id,
            "name": candidate.name,
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/brand-candidates/{candidate_id}/reject", response_model=dict)
async def reject_brand_candidate(
    candidate_id: str,
    reason: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Reject a brand candidate."""
    try:
        candidate = await BrandDiscoveryService.reject_brand_candidate(
            db, candidate_id, reason=reason
        )
        await db.commit()

        return {
            "status": "rejected",
            "candidate_id": candidate_id,
            "name": candidate.name,
            "reason": reason,
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/brand-candidates/{candidate_id}/activate", response_model=dict)
async def activate_brand_candidate(
    candidate_id: str,
    brand_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Activate a brand candidate (create discovery card and brand)."""
    try:
        candidate = await BrandDiscoveryService.activate_brand_candidate(
            db, candidate_id, brand_id=brand_id
        )
        await db.commit()

        return {
            "status": "activated",
            "candidate_id": candidate_id,
            "name": candidate.name,
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


# Brand Discovery Card Management

@router.get("/brand-discovery-cards", response_model=dict)
async def list_brand_discovery_cards(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    status_filter: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
) -> dict:
    """List brand discovery cards."""
    query = select(BrandDiscoveryCard)

    if status_filter:
        query = query.where(BrandDiscoveryCard.status == status_filter)

    query = query.order_by(BrandDiscoveryCard.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    cards = result.scalars().all()

    count_query = select(func.count(BrandDiscoveryCard.id))
    if status_filter:
        count_query = count_query.where(BrandDiscoveryCard.status == status_filter)
    count_result = await db.execute(count_query)
    total = count_result.scalar()

    return {
        "cards": [
            {
                "id": str(c.id),
                "brand_name": c.brand_name,
                "status": c.status.value,
                "views": c.total_views,
                "likes": c.total_likes,
                "dislikes": c.total_dislikes,
                "skips": c.total_skips,
                "like_rate": (c.total_likes / (c.total_views + 1)) if c.total_views > 0 else 0,
                "created_at": c.created_at.isoformat(),
            }
            for c in cards
        ],
        "total": total,
        "skip": skip,
        "limit": limit,
    }


@router.post("/brand-discovery-cards/{card_id}/pause", response_model=dict)
async def pause_brand_discovery_card(
    card_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Pause a brand discovery card."""
    from app.models import BrandDiscoveryCardStatus

    card = await db.get(BrandDiscoveryCard, uuid.UUID(card_id))
    if not card:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Card not found")

    card.is_active = False
    card.status = BrandDiscoveryCardStatus.PAUSED
    await db.commit()

    return {"status": "paused", "card_id": card_id}


@router.post("/brand-discovery-cards/{card_id}/activate", response_model=dict)
async def activate_brand_discovery_card(
    card_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Activate a brand discovery card."""
    from app.models import BrandDiscoveryCardStatus

    card = await db.get(BrandDiscoveryCard, uuid.UUID(card_id))
    if not card:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Card not found")

    card.is_active = True
    card.status = BrandDiscoveryCardStatus.ACTIVE
    await db.commit()

    return {"status": "activated", "card_id": card_id}


# Brand Management Endpoints

@router.get("/brands", response_model=dict)
async def list_brands(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    tier: Optional[str] = None,
    active_only: bool = True,
) -> dict:
    """List all brands with pagination and filtering."""
    query = select(Brand)

    if tier:
        query = query.where(Brand.tier == tier)

    if active_only:
        query = query.where(Brand.is_active == True)

    query = query.offset(skip).limit(limit)
    result = await db.execute(query)
    brands = result.scalars().all()

    # Count total
    count_query = select(func.count(Brand.id))
    if tier:
        count_query = count_query.where(Brand.tier == tier)
    if active_only:
        count_query = count_query.where(Brand.is_active == True)

    count_result = await db.execute(count_query)
    total = count_result.scalar()

    return {
        "brands": [
            {
                "id": str(brand.id),
                "name": brand.name,
                "tier": brand.tier,
                "is_active": brand.is_active,
                "price_range": {
                    "low": brand.price_range_low,
                    "high": brand.price_range_high,
                },
                "created_at": brand.created_at.isoformat(),
            }
            for brand in brands
        ],
        "total": total,
        "skip": skip,
        "limit": limit,
    }


@router.post("/brands", response_model=dict, status_code=201)
async def create_brand(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    name: str = None,
    slug: str = None,
    tier: str = None,
    price_range_low: float = None,
    price_range_high: float = None,
    aesthetics: dict = None,
) -> dict:
    """Create a new brand."""
    # Check if brand exists
    stmt = select(Brand).where(Brand.name == name)
    result = await db.execute(stmt)
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Brand already exists",
        )

    brand = Brand(
        name=name,
        slug=slug or name.lower().replace(" ", "-"),
        tier=tier or BrandTier.CONTEMPORARY,
        price_range_low=price_range_low,
        price_range_high=price_range_high,
        aesthetics=aesthetics or {},
        is_active=True,
    )
    db.add(brand)
    await db.commit()
    await db.refresh(brand)

    return {
        "id": str(brand.id),
        "name": brand.name,
        "tier": brand.tier,
        "is_active": brand.is_active,
    }


@router.put("/brands/{brand_id}", response_model=dict)
async def update_brand(
    brand_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    name: Optional[str] = None,
    tier: Optional[str] = None,
    is_active: Optional[bool] = None,
) -> dict:
    """Update brand details."""
    import uuid

    stmt = select(Brand).where(Brand.id == uuid.UUID(brand_id))
    result = await db.execute(stmt)
    brand = result.scalar_one_or_none()

    if not brand:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Brand not found",
        )

    if name:
        brand.name = name
    if tier:
        brand.tier = tier
    if is_active is not None:
        brand.is_active = is_active

    await db.commit()
    await db.refresh(brand)

    return {
        "id": str(brand.id),
        "name": brand.name,
        "tier": brand.tier,
        "is_active": brand.is_active,
    }


@router.get("/brands/{brand_id}/products", response_model=dict)
async def get_brand_products(
    brand_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    limit: int = Query(50, ge=1, le=100),
) -> dict:
    """Get all products for a specific brand."""
    import uuid

    stmt = select(Product).where(Product.brand_id == uuid.UUID(brand_id)).limit(limit)
    result = await db.execute(stmt)
    products = result.scalars().all()

    return {
        "brand_id": brand_id,
        "product_count": len(products),
        "products": [
            {
                "id": str(p.id),
                "name": p.name,
                "price": p.current_price,
                "is_active": p.is_active,
            }
            for p in products
        ],
    }


@router.post("/brands/{brand_id}/activate", status_code=200)
async def activate_brand(
    brand_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Activate a brand."""
    import uuid

    stmt = select(Brand).where(Brand.id == uuid.UUID(brand_id))
    result = await db.execute(stmt)
    brand = result.scalar_one_or_none()

    if not brand:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Brand not found",
        )

    brand.is_active = True
    await db.commit()

    return {"status": "activated", "brand_id": brand_id}


@router.post("/brands/{brand_id}/pause", status_code=200)
async def pause_brand(
    brand_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Pause a brand."""
    import uuid

    stmt = select(Brand).where(Brand.id == uuid.UUID(brand_id))
    result = await db.execute(stmt)
    brand = result.scalar_one_or_none()

    if not brand:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Brand not found",
        )

    brand.is_active = False
    await db.commit()

    return {"status": "paused", "brand_id": brand_id}


# Product Curation Endpoints

@router.get("/products", response_model=dict)
async def list_products(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    brand_id: Optional[str] = None,
    category: Optional[str] = None,
    min_quality: Optional[float] = None,
    active_only: bool = True,
) -> dict:
    """List products with filtering."""
    query = select(Product)

    if brand_id:
        import uuid
        query = query.where(Product.brand_id == uuid.UUID(brand_id))

    if category:
        query = query.where(Product.category == category)

    if min_quality is not None:
        query = query.where(Product.image_quality_score >= min_quality)

    if active_only:
        query = query.where(Product.is_active == True)

    query = query.offset(skip).limit(limit)
    result = await db.execute(query)
    products = result.scalars().all()

    return {
        "products": [
            {
                "id": str(p.id),
                "name": p.name,
                "brand_id": str(p.brand_id),
                "category": p.category,
                "price": p.current_price,
                "quality_score": p.image_quality_score,
                "is_active": p.is_active,
            }
            for p in products
        ],
        "total": len(products),
        "skip": skip,
        "limit": limit,
    }


@router.get("/products/review-queue", response_model=dict)
async def get_review_queue(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    limit: int = Query(20, ge=1, le=50),
) -> dict:
    """Get products that need manual review (quality score 0.5-0.7)."""
    stmt = select(Product).where(
        and_(
            Product.image_quality_score >= 0.5,
            Product.image_quality_score <= 0.7,
            Product.is_active == True
        )
    ).limit(limit)

    result = await db.execute(stmt)
    products = result.scalars().all()

    return {
        "review_queue": [
            {
                "id": str(p.id),
                "name": p.name,
                "quality_score": p.image_quality_score,
                "category": p.category,
            }
            for p in products
        ],
        "count": len(products),
    }


@router.post("/products/{product_id}/approve", status_code=200)
async def approve_product(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Approve a product for the feed."""
    import uuid

    stmt = select(Product).where(Product.id == uuid.UUID(product_id))
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    product.is_active = True
    if product.image_quality_score and product.image_quality_score < 0.7:
        product.image_quality_score = 0.75

    await db.commit()

    return {"status": "approved", "product_id": product_id}


@router.post("/products/{product_id}/reject", status_code=200)
async def reject_product(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Reject a product from the feed."""
    import uuid

    stmt = select(Product).where(Product.id == uuid.UUID(product_id))
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    product.is_active = False
    await db.commit()

    return {"status": "rejected", "product_id": product_id}


@router.post("/products/{product_id}/boost", status_code=200)
async def boost_product(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    boost_amount: float = Query(2.0, ge=0.1, le=5.0),
) -> dict:
    """Boost product quality score."""
    import uuid

    stmt = select(Product).where(Product.id == uuid.UUID(product_id))
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    current_score = product.image_quality_score or 0.5
    product.image_quality_score = min(current_score + boost_amount, 1.0)

    await db.commit()

    return {
        "status": "boosted",
        "product_id": product_id,
        "new_score": product.image_quality_score,
    }


@router.post("/products/{product_id}/bury", status_code=200)
async def bury_product(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Remove product from all recommendation queues."""
    import uuid

    stmt = select(Product).where(Product.id == uuid.UUID(product_id))
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found",
        )

    product.is_active = False
    product.image_quality_score = 0.0

    await db.commit()

    return {"status": "buried", "product_id": product_id}


# Feed Health Endpoints

@router.get("/feed/health", response_model=dict)
async def get_feed_health(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Get dashboard data about feed health."""
    # Active products count
    active_count = await db.execute(
        select(func.count(Product.id)).where(Product.is_active == True)
    )
    total_active = active_count.scalar()

    # Products added in last 24h
    one_day_ago = datetime.now(timezone.utc) - timedelta(days=1)
    recent_count = await db.execute(
        select(func.count(Product.id)).where(
            and_(Product.is_active == True, Product.created_at >= one_day_ago)
        )
    )
    added_24h = recent_count.scalar()

    # Out of stock products (on sale past end date)
    out_of_stock = await db.execute(
        select(func.count(Product.id)).where(
            and_(
                Product.is_on_sale == True,
                Product.sale_end_date < datetime.now(timezone.utc)
            )
        )
    )
    out_of_stock_count = out_of_stock.scalar()

    # Category distribution
    category_dist = await db.execute(
        select(Product.category, func.count(Product.id)).where(
            Product.is_active == True
        ).group_by(Product.category)
    )
    categories = {row[0]: row[1] for row in category_dist}

    # Brand distribution
    brand_dist = await db.execute(
        select(Brand.name, func.count(Product.id)).where(
            Product.is_active == True
        ).join(Brand).group_by(Brand.id, Brand.name)
    )
    brands = {row[0]: row[1] for row in brand_dist}

    # Price distribution
    price_buckets = {
        "under_100": 0,
        "100_250": 0,
        "250_500": 0,
        "500_1000": 0,
        "over_1000": 0,
    }

    price_dist = await db.execute(
        select(func.count(Product.id)).where(Product.is_active == True)
    )

    return {
        "total_active_products": total_active,
        "added_last_24h": added_24h,
        "out_of_stock": out_of_stock_count,
        "categories": categories,
        "brands_count": len(brands),
        "top_brands": sorted(brands.items(), key=lambda x: x[1], reverse=True)[:10],
        "status": "healthy" if total_active > 100 else "warning",
    }


@router.get("/feed/alerts", response_model=dict)
async def get_feed_alerts(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    min_category_products: int = Query(50),
) -> dict:
    """Get alerts about feed issues."""
    alerts = []

    # Check for categories below threshold
    category_dist = await db.execute(
        select(Product.category, func.count(Product.id)).where(
            Product.is_active == True
        ).group_by(Product.category)
    )

    for category, count in category_dist:
        if count < min_category_products:
            alerts.append({
                "type": "low_inventory",
                "category": category,
                "count": count,
                "threshold": min_category_products,
            })

    # Check for brands with zero products
    brand_count = await db.execute(
        select(Brand.id, Brand.name).where(Brand.is_active == True)
    )
    brands = brand_count.scalars().all()

    for brand in brands:
        product_count = await db.execute(
            select(func.count(Product.id)).where(
                and_(Product.brand_id == brand.id, Product.is_active == True)
            )
        )
        if product_count.scalar() == 0:
            alerts.append({
                "type": "brand_no_products",
                "brand_id": str(brand.id),
                "brand_name": brand.name,
            })

    return {
        "alerts": alerts,
        "alert_count": len(alerts),
        "severity": "critical" if len(alerts) > 5 else "warning" if len(alerts) > 0 else "none",
    }


# Trend Insights Endpoints

@router.get("/trends/brands", response_model=dict)
async def get_trending_brands(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    days: int = Query(7, ge=1, le=30),
) -> dict:
    """Get trending brands based on like rate increase."""
    # Get likes in the specified period
    period_start = datetime.now(timezone.utc) - timedelta(days=days)

    like_stmt = select(
        Brand.id, Brand.name, func.count(SwipeEvent.id).label("like_count")
    ).join(Product).join(SwipeEvent).where(
        and_(
            SwipeEvent.action == SwipeAction.LIKE,
            SwipeEvent.created_at >= period_start,
            Product.is_active == True
        )
    ).group_by(Brand.id, Brand.name).order_by(
        func.count(SwipeEvent.id).desc()
    ).limit(10)

    result = await db.execute(like_stmt)
    trends = result.all()

    return {
        "period_days": days,
        "trending_brands": [
            {
                "brand_id": str(brand_id),
                "name": name,
                "likes": like_count,
            }
            for brand_id, name, like_count in trends
        ],
    }


@router.get("/trends/categories", response_model=dict)
async def get_trending_categories(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    days: int = Query(7, ge=1, le=30),
) -> dict:
    """Get rising categories by engagement."""
    period_start = datetime.now(timezone.utc) - timedelta(days=days)

    category_stmt = select(
        Product.category, func.count(SwipeEvent.id).label("engagement")
    ).join(SwipeEvent).where(
        and_(
            SwipeEvent.created_at >= period_start,
            Product.is_active == True
        )
    ).group_by(Product.category).order_by(
        func.count(SwipeEvent.id).desc()
    )

    result = await db.execute(category_stmt)
    trends = result.all()

    return {
        "period_days": days,
        "trending_categories": [
            {
                "category": category,
                "engagement": engagement,
            }
            for category, engagement in trends
        ],
    }


@router.get("/trends/colors", response_model=dict)
async def get_trending_colors(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    days: int = Query(7, ge=1, le=30),
    limit: int = Query(10, ge=1, le=20),
) -> dict:
    """Get dominant colors in liked products."""
    period_start = datetime.now(timezone.utc) - timedelta(days=days)

    # Get liked products in period
    liked_products = await db.execute(
        select(Product.id).join(SwipeEvent).where(
            and_(
                SwipeEvent.action == SwipeAction.LIKE,
                SwipeEvent.created_at >= period_start
            )
        ).distinct()
    )

    product_ids = liked_products.scalars().all()

    # Count colors from liked products
    color_counts = {}
    for product_id in product_ids:
        product = await db.get(Product, product_id)
        if product and product.colors:
            colors = product.colors.get("colors", [])
            for color in colors:
                color_counts[color] = color_counts.get(color, 0) + 1

    sorted_colors = sorted(color_counts.items(), key=lambda x: x[1], reverse=True)[:limit]

    return {
        "period_days": days,
        "trending_colors": [
            {"color": color, "count": count}
            for color, count in sorted_colors
        ],
    }


# Commission & Ambassador Performance Endpoints

@router.get("/commissions/brand/{brand_id}", response_model=dict)
async def get_brand_commission_stats(
    brand_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    days: int = Query(30, ge=1, le=365),
) -> dict:
    """Get commission statistics for a specific brand."""
    stats = await AmbassadorTrackerService.get_brand_commission_stats(
        db, brand_id, days=days
    )
    return stats


@router.get("/commissions/underperforming", response_model=dict)
async def get_underperforming_brands(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    min_conversion_rate: float = Query(0.20, ge=0, le=1),
    min_commission: float = Query(10.0, ge=0),
    days: int = Query(30, ge=1, le=365),
) -> dict:
    """Get brands with low conversion rates or commission earnings."""
    underperforming = await AmbassadorTrackerService.get_underperforming_brands(
        db,
        min_conversion_rate=min_conversion_rate,
        min_commission=min_commission,
        days=days,
    )
    return {
        "underperforming_brands": underperforming,
        "count": len(underperforming),
        "threshold_conversion_rate": min_conversion_rate,
        "threshold_commission": min_commission,
    }


@router.get("/commissions/top-brands", response_model=dict)
async def get_top_performing_brands(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    days: int = Query(30, ge=1, le=365),
    limit: int = Query(10, ge=1, le=50),
) -> dict:
    """Get top performing brands by commission revenue."""
    top_brands = await AmbassadorTrackerService.get_top_performing_brands(
        db, days=days, limit=limit
    )
    return {
        "top_brands": top_brands,
        "count": len(top_brands),
        "period_days": days,
    }


@router.get("/commissions/retailer-performance", response_model=dict)
async def get_retailer_performance(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
    days: int = Query(30, ge=1, le=365),
) -> dict:
    """Get performance metrics by retailer/affiliate network."""
    retailer_perf = await AmbassadorTrackerService.get_retailer_performance(
        db, days=days
    )
    return {
        "retailers": retailer_perf,
        "count": len(retailer_perf),
        "period_days": days,
    }


@router.post("/commissions/{commission_id}/confirm", response_model=dict)
async def confirm_commission(
    commission_id: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Mark a commission as confirmed/converted."""
    try:
        commission = await AmbassadorTrackerService.record_conversion(db, commission_id)
        await db.commit()

        return {
            "status": "confirmed",
            "commission_id": commission_id,
            "amount": commission.commission_amount,
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/commissions/{commission_id}/reject", response_model=dict)
async def reject_commission(
    commission_id: str,
    reason: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    admin_user: str = Depends(get_current_admin_user),
) -> dict:
    """Reject a commission."""
    try:
        commission = await AmbassadorTrackerService.reject_commission(
            db, commission_id, reason=reason
        )
        await db.commit()

        return {
            "status": "rejected",
            "commission_id": commission_id,
            "reason": reason,
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
