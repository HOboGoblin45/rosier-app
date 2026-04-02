"""Scheduled task for product ingestion from affiliate networks (runs hourly)."""
import asyncio
import logging
from datetime import datetime, timezone

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import create_async_engine

from app.core.config import get_settings
from app.core.database import get_session_factory
from app.models import Retailer
from app.services.ingestion import IngestionService

logger = logging.getLogger(__name__)


async def run_ingestion_task() -> dict:
    """
    Run product ingestion for all active retailers.

    This task:
    1. Fetches product feeds from each active retailer
    2. Normalizes product data
    3. Applies quality gates
    4. Upserts to database
    5. Invalidates affected card queues

    Returns:
        Task execution report
    """
    logger.info("Starting ingestion task")

    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL, future=True)
    async_session = get_session_factory(engine)

    report = {
        "task_name": "ingestion",
        "started_at": datetime.now(timezone.utc).isoformat(),
        "retailers_processed": 0,
        "total_products_added": 0,
        "total_products_updated": 0,
        "total_products_rejected": 0,
        "errors": [],
        "retailer_reports": [],
    }

    try:
        async with async_session() as session:
            # Get all active retailers with feed configuration
            stmt = select(Retailer).where(
                and_(
                    Retailer.is_active is True,
                    Retailer.product_feed_url.isnot(None),
                )
            )
            result = await session.execute(stmt)
            retailers = result.scalars().all()

            logger.info(f"Found {len(retailers)} active retailers with feeds")

            # Process each retailer
            for retailer in retailers:
                try:
                    logger.info(f"Ingesting products from {retailer.name}")

                    ingestion_report = await IngestionService.ingest_feed(
                        session, retailer
                    )

                    report["retailers_processed"] += 1
                    report["total_products_added"] += ingestion_report["products_added"]
                    report["total_products_updated"] += ingestion_report["products_updated"]
                    report["total_products_rejected"] += ingestion_report["products_rejected"]
                    report["retailer_reports"].append(ingestion_report)

                    logger.info(
                        f"Completed ingestion for {retailer.name}: "
                        f"+{ingestion_report['products_added']} new, "
                        f"+{ingestion_report['products_updated']} updated"
                    )

                except Exception as e:
                    error_msg = f"Error ingesting {retailer.name}: {str(e)}"
                    logger.error(error_msg, exc_info=True)
                    report["errors"].append(error_msg)

            # Commit all changes
            await session.commit()

    except Exception as e:
        error_msg = f"Fatal error in ingestion task: {str(e)}"
        logger.error(error_msg, exc_info=True)
        report["errors"].append(error_msg)

    finally:
        await engine.dispose()

    report["completed_at"] = datetime.now(timezone.utc).isoformat()
    logger.info(f"Ingestion task completed: {report['retailers_processed']} retailers, "
                f"{report['total_products_added']} products added")

    return report


async def main():
    """Entry point for task execution."""
    report = await run_ingestion_task()
    print(f"Task report: {report}")


if __name__ == "__main__":
    asyncio.run(main())
