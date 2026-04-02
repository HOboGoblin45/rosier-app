"""Scheduled task for price monitoring (runs every 4 hours)."""

import asyncio
import logging
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import create_async_engine

from app.core.config import get_settings
from app.core.database import get_session_factory
from app.services.price_monitor import PriceMonitorService

logger = logging.getLogger(__name__)


async def run_price_check_task() -> dict:
    """
    Run price monitoring and send notifications for price drops.

    This task:
    1. Gets list of products to monitor (in dressers or liked)
    2. Checks current prices
    3. Detects significant price drops (>= 10%)
    4. Sends push notifications for drops
    5. Updates product records

    Returns:
        Task execution report
    """
    logger.info("Starting price check task")

    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL, future=True)
    async_session = get_session_factory(engine)

    report = {
        "task_name": "price_check",
        "started_at": datetime.now(timezone.utc).isoformat(),
        "products_checked": 0,
        "price_drops_detected": 0,
        "notifications_sent": 0,
        "notifications_failed": 0,
        "errors": [],
    }

    if not settings.ENABLE_PRICE_MONITORING:
        report["skipped"] = True
        report["reason"] = "Price monitoring disabled in configuration"
        logger.info("Price monitoring disabled, skipping task")
        return report

    try:
        async with async_session() as session:
            # Get products to check (monitored by users)
            price_changes = await PriceMonitorService.check_prices(
                session,
                limit=PriceMonitorService.RATE_LIMIT_PER_BATCH,
            )

            report["products_checked"] = len(price_changes)
            logger.info(f"Checked prices for {len(price_changes)} products")

            # Process price drops
            for change in price_changes:
                if change.get("price_drop_notification_needed"):
                    report["price_drops_detected"] += 1
                    logger.info(
                        f"Price drop detected: {change['name']} "
                        f"${change['previous_price']:.2f} -> ${change['current_price']:.2f}"
                    )

                    # TODO: Find affected users and send notifications
                    # This requires querying DresserItem and SwipeEvent tables
                    # to find users who have this product saved/liked

            # Update product records with new prices
            # (In production, would call external APIs to get latest prices first)
            await session.commit()

    except Exception as e:
        error_msg = f"Fatal error in price check task: {str(e)}"
        logger.error(error_msg, exc_info=True)
        report["errors"].append(error_msg)

    finally:
        await engine.dispose()

    report["completed_at"] = datetime.now(timezone.utc).isoformat()
    logger.info(
        f"Price check task completed: {report['products_checked']} checked, "
        f"{report['price_drops_detected']} drops detected"
    )

    return report


async def main():
    """Entry point for task execution."""
    report = await run_price_check_task()
    print(f"Task report: {report}")


if __name__ == "__main__":
    asyncio.run(main())
