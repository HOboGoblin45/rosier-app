"""API v1 router aggregation."""

from fastapi import APIRouter

from app.api.v1.endpoints import (
    auth,
    brand_discovery,
    cards,
    dresser,
    onboarding,
    products,
    profile,
    admin,
    websocket,
    notifications,
    daily_drop,
    referral,
    sale_events,
    wallpaper,
)

router = APIRouter(prefix="/api/v1")

# Include all endpoint routers
router.include_router(auth.router)
router.include_router(onboarding.router)
router.include_router(cards.router)
router.include_router(brand_discovery.router)
router.include_router(dresser.router)
router.include_router(products.router)
router.include_router(profile.router)
router.include_router(referral.router)
router.include_router(admin.router)
router.include_router(notifications.router)
router.include_router(daily_drop.router)
router.include_router(sale_events.router)
router.include_router(wallpaper.router)
router.include_router(websocket.router)

__all__ = ["router"]
