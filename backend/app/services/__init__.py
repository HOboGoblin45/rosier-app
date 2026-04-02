"""Services."""

from app.services.affiliate import AffiliateService
from app.services.ambassador_tracker import AmbassadorTrackerService
from app.services.brand_discovery import BrandDiscoveryService
from app.services.card_queue import CardQueueService
from app.services.email_sequences import EmailSequenceService
from app.services.price_monitor import PriceMonitorService
from app.services.recommendation import RecommendationService
from app.services.referral_service import ReferralService
from app.services.wallpaper_service import WallpaperService

__all__ = [
    "CardQueueService",
    "RecommendationService",
    "PriceMonitorService",
    "AffiliateService",
    "BrandDiscoveryService",
    "AmbassadorTrackerService",
    "WallpaperService",
    "ReferralService",
    "EmailSequenceService",
]
