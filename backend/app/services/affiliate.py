"""
Affiliate link construction and management service for all supported networks.

Supported Networks & Programs:
- Rakuten Advertising (LinkSynergy)
  * SSENSE, NET-A-PORTER, Shopbop, Matches Fashion, Browns Fashion, 100+ others
  * Commission: 5-12%
  * Cookie: 30-60 days

- Skimlinks
  * SSENSE, NET-A-PORTER, Farfetch, 48,500+ merchants
  * Commission: 5-15%
  * Cookie: 30-90 days

- Awin (Daisycon)
  * Multiple retailers, 100K+ merchants globally
  * Commission: 5-15%
  * Cookie: 30-90 days

- Impact (formerly Impact Radius)
  * Luxury/fashion focused programs
  * Commission: 5-15%
  * Cookie: 30-90 days

- Direct Programs (Non-Network)
  * Reformation: 2.8-5% direct
  * FWRD/Revolve: 6-15%
  * Others via retailers
"""
import logging
from typing import Optional
from urllib.parse import quote, urlencode

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Product, Retailer, AffiliateNetwork

logger = logging.getLogger(__name__)

# Retailer Affiliate Configuration
# Maps retailer names to network and program details
RETAILER_AFFILIATE_CONFIG = {
    # Primary Retailers (via Rakuten)
    "ssense": {
        "network": "rakuten",
        "merchant_id": "SSENSE_RAKUTEN_MID",  # TODO: Update with actual merchant ID
        "program_name": "SSENSE Affiliate Program",
        "commission_rate": 0.10,  # 10% average
        "cookie_duration_days": 30,
        "apply_url": "https://www.ssense.com/en-us/affiliates",
        "contact": "affiliates@ssense.com",
    },
    "net-a-porter": {
        "network": "rakuten",
        "merchant_id": "NETAPORTER_RAKUTEN_MID",  # TODO: Update with actual merchant ID
        "program_name": "NET-A-PORTER Affiliate Program",
        "commission_rate": 0.06,
        "cookie_duration_days": 30,
        "apply_url": "https://www.net-a-porter.com/en-us/content/affiliates/",
        "contact": "affiliates@net-a-porter.com",
    },
    "farfetch": {
        "network": "skimlinks",
        "merchant_id": "FARFETCH_SKIMLINKS_MID",  # TODO: Update with actual merchant ID
        "program_name": "Farfetch Affiliate Program",
        "commission_rate": 0.07,
        "cookie_duration_days": 30,
        "apply_url": "https://www.farfetch.com/pag1987.aspx",
        "contact": "affiliates@farfetch.com",
    },
    "fwrd": {
        "network": "impact",
        "campaign_id": "FWRD_IMPACT_CAMPAIGN_ID",  # TODO: Update with actual campaign ID
        "program_name": "FWRD Affiliate Program",
        "commission_rate": 0.06,
        "cookie_duration_days": 30,
        "apply_url": "https://www.fwrd.com/fw/content/customercare/affiliate/",
        "contact": "affiliates@fwrd.com",
        "notes": "Also available as Brand Ambassador Program (8-15% commission)",
    },
    "shopbop": {
        "network": "rakuten",
        "merchant_id": "SHOPBOP_RAKUTEN_MID",  # TODO: Update with actual merchant ID
        "program_name": "Shopbop Affiliate Program",
        "commission_rate": 0.05,  # Variable, typically 0.9-6%
        "cookie_duration_days": 30,
        "apply_url": "https://www.shopbop.com/ci/v2/shopbop_affiliate_program.html",
        "contact": "affiliates@shopbop.com",
        "notes": "Also has Campus Program via ShopMy for influencers (3+ posts/month required)",
    },
    "matchesfashion": {
        "network": "rakuten",
        "merchant_id": "MATCHESFASHION_RAKUTEN_MID",  # TODO: Update with actual merchant ID
        "program_name": "Matches Fashion Affiliate Program",
        "commission_rate": 0.05,  # 4-7% range
        "cookie_duration_days": 30,
        "apply_url": "https://www.matchesfashion.com/us/affiliates",
        "contact": "affiliates@matchesfashion.com",
    },
    "browns-fashion": {
        "network": "awin",
        "merchant_id": "BROWNS_AWIN_MID",  # TODO: Update with actual merchant ID
        "program_name": "Browns Fashion Affiliate Program",
        "commission_rate": 0.07,
        "cookie_duration_days": 30,
        "apply_url": "https://brownsfashion.com/pages/affiliates",
        "contact": "affiliates@brownsfashion.com",
    },
    # Direct Brand Programs
    "reformation": {
        "network": "direct",
        "program_name": "Reformation Affiliate Program",
        "commission_rate": 0.028,  # 2.8% direct, higher via networks
        "cookie_duration_days": 30,
        "apply_url": "https://www.thereformation.com/ref-affiliates.html",
        "contact": "affiliates@reformation.com",
    },
}


class AffiliateService:
    """Service for constructing affiliate links across all affiliate networks."""

    @staticmethod
    def get_retailer_config(retailer_name: str) -> Optional[dict]:
        """
        Get affiliate configuration for a retailer.

        Args:
            retailer_name: Retailer key (lowercase, dash-separated)

        Returns:
            Configuration dict with network, commission rate, and contact info
        """
        return RETAILER_AFFILIATE_CONFIG.get(retailer_name.lower())

    @staticmethod
    def list_all_retailers() -> dict:
        """Return all configured retailers and their affiliate details."""
        return RETAILER_AFFILIATE_CONFIG

    @staticmethod
    async def get_affiliate_link(
        session: AsyncSession,
        product_id: str,
        user_id: Optional[str] = None,
    ) -> Optional[str]:
        """
        Get affiliate link for a product based on retailer's affiliate network.

        Args:
            session: SQLAlchemy async session
            product_id: Product ID
            user_id: Optional user ID for tracking clicks

        Returns:
            Fully-formed affiliate link or None if unable to construct
        """
        # Get product
        stmt = select(Product).where(Product.id == product_id)
        result = await session.execute(stmt)
        product = result.scalar_one_or_none()

        if not product:
            logger.warning(f"Product {product_id} not found")
            return None

        # Get retailer
        retailer = await session.get(Retailer, product.retailer_id)
        if not retailer:
            logger.warning(f"Retailer {product.retailer_id} not found for product {product_id}")
            return None

        # Use affiliate_url if set, otherwise product_url
        target_url = product.affiliate_url or product.product_url
        if not target_url:
            logger.warning(f"No URL available for product {product_id}")
            return None

        # Build appropriate affiliate link based on network
        if retailer.affiliate_network == AffiliateNetwork.RAKUTEN:
            return AffiliateService._build_rakuten_link(
                target_url,
                retailer.affiliate_publisher_id,
                retailer.id,
                user_id,
            )
        elif retailer.affiliate_network == AffiliateNetwork.IMPACT:
            return AffiliateService._build_impact_link(
                target_url,
                retailer.affiliate_publisher_id,
                user_id,
            )
        elif retailer.affiliate_network == AffiliateNetwork.AWIN:
            return AffiliateService._build_awin_link(
                target_url,
                retailer.affiliate_publisher_id,
                user_id,
            )
        elif retailer.affiliate_network == AffiliateNetwork.SKIMLINKS:
            return AffiliateService._build_skimlinks_link(
                target_url,
                retailer.affiliate_publisher_id,
                user_id,
            )
        else:
            # Direct link with UTM parameters
            return AffiliateService._build_direct_link(target_url, user_id)

    @staticmethod
    def _build_rakuten_link(
        product_url: str,
        publisher_id: Optional[str],
        merchant_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> str:
        """
        Build Rakuten Advertising (LinkSynergy) affiliate link.

        Format: https://click.linksynergy.com/deeplink?id={publisher_id}&mid={merchant_id}&murl={encoded_product_url}

        Args:
            product_url: Direct product URL
            publisher_id: Rakuten publisher ID
            merchant_id: Rakuten merchant ID
            user_id: Optional user ID for tracking

        Returns:
            Rakuten affiliate link
        """
        if not publisher_id:
            logger.warning("No publisher_id for Rakuten link")
            return product_url

        # URL encode the product URL
        encoded_url = quote(product_url, safe="")

        params = {
            "id": publisher_id,
            "murl": encoded_url,
        }

        if merchant_id:
            params["mid"] = str(merchant_id)

        if user_id:
            params["u1"] = user_id  # Custom parameter for user tracking

        query_string = urlencode(params)
        link = f"https://click.linksynergy.com/deeplink?{query_string}"
        logger.debug(f"Built Rakuten link for {product_url}")
        return link

    @staticmethod
    def _build_impact_link(
        product_url: str,
        publisher_id: Optional[str],
        user_id: Optional[str] = None,
    ) -> str:
        """
        Build Impact (formerly Impact Radius) affiliate link.

        Format: https://goto.{domain}/c/{publisher_id}/{campaign_id}/2?u={encoded_product_url}

        Args:
            product_url: Direct product URL
            publisher_id: Impact publisher ID (campaign ID)
            user_id: Optional user ID for tracking

        Returns:
            Impact affiliate link
        """
        if not publisher_id:
            logger.warning("No publisher_id for Impact link")
            return product_url

        # URL encode the product URL
        encoded_url = quote(product_url, safe="")

        params = {
            "u": encoded_url,
        }

        if user_id:
            params["ref"] = user_id

        query_string = urlencode(params)
        link = f"https://api.impactradius.com/click?click_id={publisher_id}&{query_string}"
        logger.debug(f"Built Impact link for {product_url}")
        return link

    @staticmethod
    def _build_awin_link(
        product_url: str,
        publisher_id: Optional[str],
        user_id: Optional[str] = None,
    ) -> str:
        """
        Build Awin (Daisycon) affiliate link.

        Format: https://www.awin1.com/cread.php?awinmid={merchant_id}&awinaffid={publisher_id}&ued={encoded_product_url}

        Args:
            product_url: Direct product URL
            publisher_id: Awin publisher/affiliate ID
            user_id: Optional user ID for tracking (clickref)

        Returns:
            Awin affiliate link
        """
        if not publisher_id:
            logger.warning("No publisher_id for Awin link")
            return product_url

        # URL encode the product URL
        encoded_url = quote(product_url, safe="")

        params = {
            "awinaffid": publisher_id,
            "ued": encoded_url,
        }

        if user_id:
            params["clickref"] = user_id

        query_string = urlencode(params)
        link = f"https://www.awin1.com/cread.php?{query_string}"
        logger.debug(f"Built Awin link for {product_url}")
        return link

    @staticmethod
    def _build_skimlinks_link(
        product_url: str,
        publisher_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> str:
        """
        Build Skimlinks affiliate link.

        Format: https://go.skimresources.com?id={publisher_id}&url={encoded_product_url}

        Args:
            product_url: Direct product URL
            publisher_id: Skimlinks publisher/site ID
            user_id: Optional user ID for tracking (xid)

        Returns:
            Skimlinks affiliate link
        """
        # URL encode the product URL
        encoded_url = quote(product_url, safe="")

        params = {
            "url": encoded_url,
        }

        if publisher_id:
            params["id"] = publisher_id

        if user_id:
            params["xid"] = user_id

        query_string = urlencode(params)
        link = f"https://go.skimresources.com?{query_string}"
        logger.debug(f"Built Skimlinks link for {product_url}")
        return link

    @staticmethod
    def _build_direct_link(
        product_url: str,
        user_id: Optional[str] = None,
    ) -> str:
        """
        Build direct link with UTM parameters for tracking.

        Used for retailers not part of affiliate networks.

        Args:
            product_url: Direct product URL
            user_id: Optional user ID to track in UTM parameters

        Returns:
            Direct link with UTM parameters
        """
        params = {
            "utm_source": "rosier",
            "utm_medium": "app",
            "utm_campaign": "swipe",
        }

        if user_id:
            params["utm_content"] = user_id

        query_string = urlencode(params)

        # Append UTM params to product URL
        separator = "&" if "?" in product_url else "?"
        link = f"{product_url}{separator}{query_string}"
        logger.debug(f"Built direct link for {product_url}")
        return link

    @staticmethod
    async def build_affiliate_links_batch(
        session: AsyncSession,
        product_ids: list[str],
        user_id: Optional[str] = None,
    ) -> dict[str, str]:
        """
        Build affiliate links for multiple products in batch.

        Args:
            session: SQLAlchemy async session
            product_ids: List of product IDs
            user_id: Optional user ID for tracking

        Returns:
            Dictionary mapping product_id to affiliate_link
        """
        links = {}
        for product_id in product_ids:
            try:
                link = await AffiliateService.get_affiliate_link(
                    session, product_id, user_id
                )
                if link:
                    links[product_id] = link
            except Exception as e:
                logger.error(f"Error building affiliate link for product {product_id}: {e}")

        return links
