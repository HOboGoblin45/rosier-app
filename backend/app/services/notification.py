"""Push notification service for APNs and re-engagement campaigns."""

import json
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from enum import Enum
from typing import Optional

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.redis import get_cache, set_cache
from app.models import User

logger = logging.getLogger(__name__)


class NotificationType(str, Enum):
    """Types of notifications."""

    PRICE_DROP = "price_drop"
    DAILY_DROP = "daily_drop"
    RE_ENGAGEMENT = "re_engagement"
    SALE_CALENDAR = "sale_calendar"
    NEW_ITEM = "new_item"
    BRAND_ALERT = "brand_alert"


@dataclass
class PushNotification:
    """Push notification payload."""

    notification_type: NotificationType
    title: str
    body: str
    user_id: str
    badge: Optional[int] = None
    sound: str = "default"
    deep_link: Optional[str] = None
    extra_data: Optional[dict] = None

    def to_apns_payload(self) -> dict:
        """Convert to APNs payload format."""
        aps = {
            "alert": {
                "title": self.title,
                "body": self.body,
            },
            "sound": self.sound,
            "badge": self.badge or 1,
        }

        payload = {
            "aps": aps,
            "notification_type": self.notification_type.value,
            "user_id": self.user_id,
        }

        if self.deep_link:
            payload["deep_link"] = self.deep_link

        if self.extra_data:
            payload.update(self.extra_data)

        return payload


class NotificationService:
    """Service for sending push notifications and managing notification state."""

    # Rate limiting
    MAX_NOTIFICATIONS_PER_DAY = 3
    MAX_NOTIFICATIONS_PER_HOUR = 1

    # Re-engagement schedule (days inactive)
    RE_ENGAGEMENT_MILESTONES = [3, 7, 14, 30]

    # Daily Drop time (9 AM in user's local time, falls back to UTC)
    DAILY_DROP_HOUR = 9

    @staticmethod
    async def send_apns_notification(
        notification: PushNotification,
        device_token: str,
    ) -> tuple[bool, Optional[str]]:
        """
        Send push notification via APNs using HTTP/2.

        Args:
            notification: PushNotification object
            device_token: Device token for target device

        Returns:
            Tuple of (success, error_message)
        """
        settings = get_settings()

        if not settings.APPLE_TEAM_ID or not settings.APPLE_KEY_ID:
            logger.warning("APNs credentials not configured")
            return False, "APNs not configured"

        try:
            # Import jwt for token generation
            try:
                import jwt
            except ImportError:
                logger.error("PyJWT not installed")
                return False, "JWT library not available"

            # Generate APNs authentication token
            now = datetime.now(timezone.utc)
            payload = {
                "iss": settings.APPLE_TEAM_ID,
                "iat": int(now.timestamp()),
            }

            # Use ES256 (ECDSA with SHA-256)
            auth_token = jwt.encode(
                payload,
                settings.APPLE_PRIVATE_KEY,
                algorithm="ES256",
                headers={"kid": settings.APPLE_KEY_ID},
            )

            # Build request
            url = f"https://api.push.apple.com/3/device/{device_token}"
            headers = {
                "apns-topic": settings.APPLE_APP_ID,
                "apns-push-type": "alert",
                "authorization": f"bearer {auth_token}",
            }

            payload_json = json.dumps(notification.to_apns_payload())

            # Send using httpx with HTTP/2
            async with httpx.AsyncClient(http2=True, timeout=10.0) as client:
                response = await client.post(url, headers=headers, content=payload_json)

            if response.status_code == 200:
                logger.info(f"Notification sent successfully to device {device_token}")
                return True, None
            else:
                error_msg = f"APNs error: {response.status_code} {response.text}"
                logger.error(error_msg)
                return False, error_msg

        except Exception as e:
            error_msg = f"Error sending APNs notification: {str(e)}"
            logger.error(error_msg)
            return False, error_msg

    @staticmethod
    async def check_notification_rate_limit(
        user_id: str,
        time_window: str = "day",
    ) -> tuple[bool, int]:
        """
        Check if user has exceeded notification rate limit.

        Args:
            user_id: User ID
            time_window: "hour" or "day"

        Returns:
            Tuple of (allowed, remaining_quota)
        """
        limit_key = f"notif_limit:{user_id}:{time_window}"
        current = await get_cache(limit_key)

        if current is None:
            current = 0
        else:
            current = int(current)

        max_notifications = (
            NotificationService.MAX_NOTIFICATIONS_PER_HOUR
            if time_window == "hour"
            else NotificationService.MAX_NOTIFICATIONS_PER_DAY
        )

        allowed = current < max_notifications
        remaining = max(0, max_notifications - current)

        return allowed, remaining

    @staticmethod
    async def increment_notification_count(
        user_id: str,
        time_window: str = "day",
    ) -> None:
        """Increment notification count for rate limiting."""
        limit_key = f"notif_limit:{user_id}:{time_window}"
        ttl = 3600 if time_window == "hour" else 86400

        current = await get_cache(limit_key)
        count = int(current) if current else 0
        await set_cache(limit_key, count + 1, ttl=ttl)

    @staticmethod
    async def send_price_drop_notification(
        session: AsyncSession,
        user_id: str,
        product_name: str,
        original_price: float,
        current_price: float,
        device_token: Optional[str] = None,
    ) -> tuple[bool, Optional[str]]:
        """
        Send price drop notification for product.

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            product_name: Product name
            original_price: Original price
            current_price: Current price
            device_token: Device token (fetches from DB if not provided)

        Returns:
            Tuple of (success, error_message)
        """
        # Check rate limit
        allowed, remaining = await NotificationService.check_notification_rate_limit(
            user_id
        )
        if not allowed:
            logger.info(f"Rate limit exceeded for user {user_id}")
            return False, f"Rate limited. {remaining} notifications remaining today."

        savings = original_price - current_price
        savings_percent = (savings / original_price * 100) if original_price > 0 else 0

        notification = PushNotification(
            notification_type=NotificationType.PRICE_DROP,
            title="Price Drop Alert",
            body=f"{product_name} is now ${current_price:.2f} (save {savings_percent:.0f}%!)",
            user_id=user_id,
            extra_data={
                "original_price": original_price,
                "current_price": current_price,
                "savings": savings,
                "savings_percent": savings_percent,
            },
        )

        # If device token not provided, fetch from user record
        if not device_token:
            stmt = select(User).where(User.id == user_id)
            result = await session.execute(stmt)
            user = result.scalar_one_or_none()

            if not user or not user.settings or not user.settings.get("device_token"):
                logger.warning(f"No device token for user {user_id}")
                return False, "No device token registered"

            device_token = user.settings["device_token"]

        # Send notification
        success, error = await NotificationService.send_apns_notification(
            notification, device_token
        )

        if success:
            await NotificationService.increment_notification_count(user_id)

        return success, error

    @staticmethod
    async def send_daily_drop_notification(
        session: AsyncSession,
        user_id: str,
        product_count: int,
        device_token: Optional[str] = None,
    ) -> tuple[bool, Optional[str]]:
        """
        Send daily drop notification at 9 AM user's local time.

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            product_count: Number of products in daily drop
            device_token: Device token

        Returns:
            Tuple of (success, error_message)
        """
        allowed, remaining = await NotificationService.check_notification_rate_limit(
            user_id, time_window="day"
        )
        if not allowed:
            return False, f"Rate limited. {remaining} notifications remaining today."

        notification = PushNotification(
            notification_type=NotificationType.DAILY_DROP,
            title="Your Daily Drop is Ready",
            body=f"Check out {product_count} new pieces hand-picked for you",
            user_id=user_id,
            extra_data={"product_count": product_count},
            deep_link="rosier://feed/daily-drop",
        )

        if not device_token:
            stmt = select(User).where(User.id == user_id)
            result = await session.execute(stmt)
            user = result.scalar_one_or_none()

            if not user or not user.settings or not user.settings.get("device_token"):
                return False, "No device token registered"

            device_token = user.settings["device_token"]

        success, error = await NotificationService.send_apns_notification(
            notification, device_token
        )

        if success:
            await NotificationService.increment_notification_count(user_id)

        return success, error

    @staticmethod
    async def send_re_engagement_notification(
        session: AsyncSession,
        user_id: str,
        days_inactive: int,
        device_token: Optional[str] = None,
    ) -> tuple[bool, Optional[str]]:
        """
        Send re-engagement push notification based on inactivity period.

        Messages vary by inactivity duration:
        - 3 days: "We miss you! New items arrived."
        - 7 days: "You've missed some great finds. Come back in!"
        - 14 days: "Fresh styles waiting. Discover what's new."
        - 30+ days: "Your style has evolved. Check out updated picks."

        Args:
            session: SQLAlchemy async session
            user_id: User ID
            days_inactive: Days since last activity
            device_token: Device token

        Returns:
            Tuple of (success, error_message)
        """
        allowed, remaining = await NotificationService.check_notification_rate_limit(
            user_id, time_window="day"
        )
        if not allowed:
            return False, f"Rate limited. {remaining} notifications remaining today."

        # Customize message based on inactivity duration
        if days_inactive < 5:
            title = "We miss you!"
            body = "New items just arrived. Come see what's fresh."
        elif days_inactive < 10:
            title = "You've been missed"
            body = "Check out the pieces you've missed this week."
        elif days_inactive < 20:
            title = "Fresh styles are waiting"
            body = "Discover updated recommendations just for you."
        else:
            title = "Time for a refresh?"
            body = "Your style has evolved. Explore curated picks."

        notification = PushNotification(
            notification_type=NotificationType.RE_ENGAGEMENT,
            title=title,
            body=body,
            user_id=user_id,
            extra_data={"days_inactive": days_inactive},
            deep_link="rosier://feed",
        )

        if not device_token:
            stmt = select(User).where(User.id == user_id)
            result = await session.execute(stmt)
            user = result.scalar_one_or_none()

            if not user or not user.settings or not user.settings.get("device_token"):
                return False, "No device token registered"

            device_token = user.settings["device_token"]

        success, error = await NotificationService.send_apns_notification(
            notification, device_token
        )

        if success:
            await NotificationService.increment_notification_count(user_id)

        return success, error

    @staticmethod
    async def should_send_re_engagement_notification(
        session: AsyncSession,
        user_id: str,
    ) -> tuple[bool, int]:
        """
        Check if user should receive re-engagement notification.

        Returns notification opportunity if user hasn't had one in the past 24 hours
        and is inactive for a milestone duration (3, 7, 14, or 30 days).

        Args:
            session: SQLAlchemy async session
            user_id: User ID

        Returns:
            Tuple of (should_send, days_inactive)
        """
        # Get last activity
        from app.models import SwipeEvent

        stmt = (
            select(SwipeEvent.created_at)
            .where(SwipeEvent.user_id == user_id)
            .order_by(SwipeEvent.created_at.desc())
            .limit(1)
        )
        result = await session.execute(stmt)
        last_activity = result.scalar_one_or_none()

        if not last_activity:
            return False, 0

        now = datetime.now(timezone.utc)
        days_inactive = (now - last_activity).days

        # Check if at a milestone
        is_milestone = days_inactive in NotificationService.RE_ENGAGEMENT_MILESTONES

        if not is_milestone:
            return False, days_inactive

        # Check if already sent notification in past 24 hours
        notification_cache_key = f"re_engagement_sent:{user_id}"
        already_sent = await get_cache(notification_cache_key)

        if already_sent:
            return False, days_inactive

        return True, days_inactive

    @staticmethod
    async def track_notification_sent(
        user_id: str,
        notification_type: NotificationType,
    ) -> None:
        """Track that notification was sent (for rate limiting and deduplication)."""
        cache_key = f"notif_sent:{user_id}:{notification_type.value}"
        await set_cache(cache_key, True, ttl=86400)

    @staticmethod
    async def track_notification_tapped(
        user_id: str,
        notification_type: NotificationType,
    ) -> None:
        """Track that user tapped/opened notification."""
        analytics_key = f"notif_tap:{user_id}:{notification_type.value}"
        await set_cache(
            analytics_key, datetime.now(timezone.utc).isoformat(), ttl=86400
        )
        logger.info(f"User {user_id} tapped {notification_type.value} notification")

    @staticmethod
    async def track_notification_dismissed(
        user_id: str,
        notification_type: NotificationType,
    ) -> None:
        """Track that user dismissed notification."""
        analytics_key = f"notif_dismiss:{user_id}:{notification_type.value}"
        await set_cache(
            analytics_key, datetime.now(timezone.utc).isoformat(), ttl=86400
        )
        logger.info(f"User {user_id} dismissed {notification_type.value} notification")
