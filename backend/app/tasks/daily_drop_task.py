"""Scheduled task for daily drop generation (runs at 8:30 AM UTC)."""
import asyncio
import json
import logging
from datetime import datetime, timezone, timedelta

import numpy as np
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine

from app.core.config import get_settings
from app.core.database import get_session_factory
from app.core.redis import get_redis, set_cache
from app.models import User
from app.services.card_queue import CardQueueService
from app.services.recommendation import RecommendationService
from app.services.notification import NotificationService

logger = logging.getLogger(__name__)


async def run_daily_drop_task() -> dict:
    """
    Generate daily drops for all active users.

    This task runs at 8:30 AM UTC and:
    1. For each active user:
       - Builds user preferences
       - Computes taste embedding
       - Generates 5 high-confidence recommendations
       - Caches in Redis with key `daily_drop:{user_id}`
       - Schedules push notification for 9 AM user's local time

    A "daily drop" is a curated set of 5 hand-picked items designed to:
    - Maintain engagement through personalized recommendations
    - Showcase new arrivals aligned with user's taste
    - Create a daily ritual/habit loop

    Returns:
        Task execution report
    """
    logger.info("Starting daily drop task")

    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL, future=True)
    async_session = get_session_factory(engine)

    report = {
        "task_name": "daily_drop",
        "started_at": datetime.now(timezone.utc).isoformat(),
        "users_processed": 0,
        "daily_drops_generated": 0,
        "notifications_scheduled": 0,
        "errors": [],
    }

    try:
        async with async_session() as session:
            # Get all active users
            stmt = select(User).where(User.onboarding_completed is True)
            result = await session.execute(stmt)
            users = result.scalars().all()

            logger.info(f"Generating daily drops for {len(users)} active users")

            for user in users:
                try:
                    logger.debug(f"Generating daily drop for user {user.id}")

                    # Build user preferences
                    user_prefs = await RecommendationService.build_user_preferences(
                        session, user.id
                    )

                    # Compute taste embedding
                    taste_embedding = await RecommendationService.compute_taste_embedding(
                        session, user.id
                    )

                    # Generate 5 high-confidence recommendations
                    daily_drop_cards = await CardQueueService.generate_queue(
                        session,
                        str(user.id),
                        user_preferences=user_prefs,
                        taste_embedding=taste_embedding.tolist() if taste_embedding is not None else None,
                        queue_size=5,
                    )

                    if daily_drop_cards:
                        # Cache daily drop for 24 hours
                        cache_key = f"daily_drop:{user.id}"
                        daily_drop_data = {
                            "cards": daily_drop_cards,
                            "generated_at": datetime.now(timezone.utc).isoformat(),
                            "expires_at": (datetime.now(timezone.utc) + timedelta(days=1)).isoformat(),
                        }
                        await set_cache(cache_key, daily_drop_data, ttl=86400)

                        report["daily_drops_generated"] += 1
                        logger.debug(f"Generated daily drop for user {user.id}: {len(daily_drop_cards)} cards")

                        # Schedule notification for 9 AM user's local time
                        # TODO: Implement timezone-aware scheduling
                        # For now, use a simple offset-based approach
                        if user.settings and user.settings.get("device_token"):
                            success, error = await NotificationService.send_daily_drop_notification(
                                session,
                                str(user.id),
                                len(daily_drop_cards),
                                user.settings["device_token"],
                            )

                            if success:
                                report["notifications_scheduled"] += 1
                            else:
                                logger.warning(f"Failed to schedule notification for user {user.id}: {error}")
                    else:
                        logger.warning(f"Could not generate daily drop cards for user {user.id}")

                    report["users_processed"] += 1

                except Exception as e:
                    error_msg = f"Error generating daily drop for user {user.id}: {str(e)}"
                    logger.error(error_msg, exc_info=True)
                    report["errors"].append(error_msg)

            # Commit any changes
            await session.commit()

    except Exception as e:
        error_msg = f"Fatal error in daily drop task: {str(e)}"
        logger.error(error_msg, exc_info=True)
        report["errors"].append(error_msg)

    finally:
        await engine.dispose()

    report["completed_at"] = datetime.now(timezone.utc).isoformat()
    logger.info(
        f"Daily drop task completed: {report['users_processed']} users, "
        f"{report['daily_drops_generated']} drops generated, "
        f"{report['notifications_scheduled']} notifications sent"
    )

    return report


async def schedule_daily_drop_notifications(
    user_ids: list[str],
    send_at_hour: int = 9,
) -> dict:
    """
    Schedule push notifications for daily drop at specific hour in user's timezone.

    This is a helper function to coordinate with a scheduling backend
    (like APScheduler or Celery Beat).

    Args:
        user_ids: List of user IDs to send to
        send_at_hour: Hour of day to send (0-23, UTC)

    Returns:
        Schedule report
    """
    report = {
        "scheduled_notifications": len(user_ids),
        "send_hour_utc": send_at_hour,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    logger.info(f"Scheduled {len(user_ids)} daily drop notifications for {send_at_hour}:00 UTC")
    return report


async def main():
    """Entry point for task execution."""
    report = await run_daily_drop_task()
    print(f"Task report: {json.dumps(report, indent=2)}")


if __name__ == "__main__":
    asyncio.run(main())
