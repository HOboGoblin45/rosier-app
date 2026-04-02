"""Price monitoring service for tracking price changes and notifying on drops."""
import logging
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Product, SwipeEvent, DresserItem
from app.core.redis import set_cache, get_cache

logger = logging.getLogger(__name__)


@dataclass
class PriceDropNotification:
    """Price drop notification record."""

    product_id: str
    user_id: str
    old_price: float
    new_price: float
    savings: float
    savings_percent: float
    created_at: datetime


class PriceMonitorService:
    """Service for comprehensive price monitoring and change detection."""

    PRICE_DROP_THRESHOLD = 0.10  # 10% price drop triggers notification
    RATE_LIMIT_PER_BATCH = 50  # Process max 50 products per call to avoid API hammering
    PRICE_CHECK_INTERVAL_HOURS = 4  # Recheck prices every 4 hours


    @staticmethod
    async def get_monitored_product_ids(
        session: AsyncSession,
    ) -> list[str]:
        """
        Get list of product IDs that should be monitored (in user dressers or liked).

        These are products users have engaged with, so price drops matter to them.

        Args:
            session: SQLAlchemy async session

        Returns:
            List of product IDs to monitor
        """
        # Get products in user dressers
        stmt = (
            select(DresserItem.product_id.distinct())
            .select_from(DresserItem)
        )
        result = await session.execute(stmt)
        dresser_product_ids = result.scalars().all()

        # Get liked/super-liked products
        stmt = (
            select(SwipeEvent.product_id.distinct())
            .select_from(SwipeEvent)
            .where(SwipeEvent.action.in_(["like", "super_like", "shop_click"]))
        )
        result = await session.execute(stmt)
        liked_product_ids = result.scalars().all()

        # Combine and deduplicate
        all_product_ids = set(str(pid) for pid in dresser_product_ids) | set(
            str(pid) for pid in liked_product_ids
        )

        return list(all_product_ids)

    @staticmethod
    async def check_prices(
        session: AsyncSession,
        product_ids: Optional[list[str]] = None,
        limit: int = RATE_LIMIT_PER_BATCH,
    ) -> list[dict]:
        """
        Check current prices and detect changes.

        If product_ids not provided, checks products that haven't been checked recently
        (prioritizing monitored products in dressers/likes).

        Args:
            session: SQLAlchemy async session
            product_ids: Optional specific product IDs to check
            limit: Maximum products to check per call

        Returns:
            List of products with detected price changes
        """
        if product_ids:
            stmt = select(Product).where(
                and_(
                    Product.id.in_(product_ids),
                    Product.is_active is True,
                )
            )
        else:
            # Get products that need price checking
            # Prioritize: not checked recently, monitored by users
            monitored_ids = await PriceMonitorService.get_monitored_product_ids(session)

            cutoff_time = datetime.now(timezone.utc) - timedelta(hours=PriceMonitorService.PRICE_CHECK_INTERVAL_HOURS)

            stmt = (
                select(Product)
                .where(
                    and_(
                        Product.is_active is True,
                        Product.id.in_(monitored_ids) if monitored_ids else True,
                    )
                )
                .order_by(Product.last_price_check.asc())
                .limit(limit)
            )

        result = await session.execute(stmt)
        products = result.scalars().all()

        price_changes = []
        for product in products:
            change_info = {
                "product_id": str(product.id),
                "name": product.name,
                "current_price": float(product.current_price),
                "previous_price": float(product.original_price)
                if product.original_price
                else float(product.current_price),
                "price_change_percent": 0.0,
                "is_price_drop": False,
                "price_drop_notification_needed": False,
                "last_checked": product.last_price_check,
            }

            if product.original_price and product.original_price > 0:
                change_percent = (
                    (product.original_price - product.current_price) / product.original_price
                )
                change_info["price_change_percent"] = float(change_percent)

                # Detect significant price drops
                if (
                    change_percent >= PriceMonitorService.PRICE_DROP_THRESHOLD
                    and product.current_price < product.original_price
                ):
                    change_info["is_price_drop"] = True
                    change_info["price_drop_notification_needed"] = True

            price_changes.append(change_info)

        logger.info(f"Checked {len(price_changes)} products for price changes")
        return price_changes

    @staticmethod
    async def update_product_price(
        session: AsyncSession,
        product_id: str,
        new_price: float,
        new_original_price: Optional[float] = None,
        new_sale_status: Optional[bool] = None,
    ) -> Optional[dict]:
        """
        Update product price and track changes.

        Args:
            session: SQLAlchemy async session
            product_id: Product ID
            new_price: New current price
            new_original_price: Optional new original/list price
            new_sale_status: Optional new sale status

        Returns:
            Dictionary with price update details or None if product not found
        """
        stmt = select(Product).where(Product.id == product_id)
        result = await session.execute(stmt)
        product = result.scalar_one_or_none()

        if not product:
            return None

        old_price = product.current_price
        old_original_price = product.original_price

        product.current_price = new_price
        if new_original_price is not None:
            product.original_price = new_original_price
        product.last_price_check = datetime.now(timezone.utc)

        if new_sale_status is not None:
            product.is_on_sale = new_sale_status

        await session.flush()

        price_change = new_price - old_price
        price_change_percent = (price_change / old_price) if old_price > 0 else 0.0

        result_dict = {
            "product_id": str(product.id),
            "old_price": float(old_price),
            "new_price": float(new_price),
            "price_change": float(price_change),
            "price_change_percent": float(price_change_percent),
            "is_price_drop": price_change < 0 and abs(price_change_percent) >= PriceMonitorService.PRICE_DROP_THRESHOLD,
            "is_on_sale": product.is_on_sale,
        }

        if price_change < 0 and abs(price_change_percent) >= PriceMonitorService.PRICE_DROP_THRESHOLD:
            logger.info(
                f"Price drop detected: {product.name} ${old_price} -> ${new_price} "
                f"({price_change_percent:.1%} off)"
            )

        return result_dict

    @staticmethod
    async def mark_out_of_stock(
        session: AsyncSession,
        product_id: str,
    ) -> Optional[dict]:
        """
        Mark product as out of stock (inactive).

        No notification is sent for out-of-stock items.

        Args:
            session: SQLAlchemy async session
            product_id: Product ID

        Returns:
            Updated product info or None
        """
        stmt = select(Product).where(Product.id == product_id)
        result = await session.execute(stmt)
        product = result.scalar_one_or_none()

        if not product:
            return None

        was_active = product.is_active
        product.is_active = False
        product.last_price_check = datetime.now(timezone.utc)

        await session.flush()

        logger.info(f"Marked {product.name} as out of stock")

        return {
            "product_id": str(product.id),
            "name": product.name,
            "was_active": was_active,
            "now_active": False,
        }

    @staticmethod
    async def get_price_drop_products(
        session: AsyncSession,
        threshold_percent: float = PRICE_DROP_THRESHOLD,
        limit: int = 50,
    ) -> list[dict]:
        """
        Get products with significant price drops (for Daily Drops feature).

        Args:
            session: SQLAlchemy async session
            threshold_percent: Minimum price drop percentage
            limit: Maximum products to return

        Returns:
            List of products with major price drops
        """
        stmt = (
            select(Product)
            .where(
                and_(
                    Product.is_active is True,
                    Product.is_on_sale is True,
                    Product.original_price.isnot(None),
                    Product.current_price < Product.original_price,
                )
            )
            .order_by(Product.updated_at.desc())
            .limit(limit * 2)  # Fetch more to filter
        )

        result = await session.execute(stmt)
        products = result.scalars().all()

        drops = []
        for product in products:
            if product.original_price and product.original_price > 0:
                drop_percent = (
                    product.original_price - product.current_price
                ) / product.original_price

                if drop_percent >= threshold_percent:
                    drops.append(
                        {
                            "product_id": str(product.id),
                            "name": product.name,
                            "category": product.category,
                            "image_urls": product.image_urls or [],
                            "original_price": float(product.original_price),
                            "current_price": float(product.current_price),
                            "savings": float(product.original_price - product.current_price),
                            "savings_percent": float(drop_percent),
                            "updated_at": product.updated_at.isoformat(),
                        }
                    )

        return drops[:limit]

    @staticmethod
    async def get_price_drop_notifications_for_user(
        session: AsyncSession,
        user_id: str,
        limit: int = 10,
    ) -> list[dict]:
        """
        Get recent price drop notifications for a user.

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            limit: Maximum notifications to return

        Returns:
            List of price drop notifications
        """
        # Get from cache
        cache_key = f"price_drops:{user_id}"
        cached = await get_cache(cache_key)
        if cached:
            return cached

        # Query database for products in user's dresser with price drops
        stmt = (
            select(Product)
            .join(DresserItem, Product.id == DresserItem.product_id)
            .where(
                and_(
                    DresserItem.user_id == user_id,
                    Product.is_on_sale is True,
                    Product.original_price.isnot(None),
                    Product.current_price < Product.original_price,
                )
            )
            .order_by(Product.updated_at.desc())
            .limit(limit)
        )

        result = await session.execute(stmt)
        products = result.scalars().all()

        notifications = []
        for product in products:
            if product.original_price and product.original_price > 0:
                drop_percent = (
                    product.original_price - product.current_price
                ) / product.original_price

                if drop_percent >= PriceMonitorService.PRICE_DROP_THRESHOLD:
                    notifications.append(
                        {
                            "product_id": str(product.id),
                            "name": product.name,
                            "image_urls": product.image_urls or [],
                            "original_price": float(product.original_price),
                            "current_price": float(product.current_price),
                            "savings": float(product.original_price - product.current_price),
                            "savings_percent": float(drop_percent),
                        }
                    )

        # Cache for 1 hour
        await set_cache(cache_key, notifications, ttl=3600)

        return notifications
