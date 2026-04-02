"""Ambassador and affiliate performance tracking service."""

import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Commission, Brand, Retailer

logger = logging.getLogger(__name__)


class AmbassadorTrackerService:
    """Service for tracking ambassador/affiliate performance metrics."""

    @staticmethod
    async def get_brand_commission_stats(
        session: AsyncSession,
        brand_id: str,
        days: int = 30,
    ) -> dict:
        """
        Get commission statistics for a specific brand.

        Args:
            session: SQLAlchemy async session
            brand_id: Brand ID
            days: Number of days to look back

        Returns:
            Dictionary with commission stats
        """
        import uuid

        start_date = datetime.now(timezone.utc) - timedelta(days=days)
        brand_uuid = uuid.UUID(brand_id)

        # Get all commissions for brand in period
        stmt = select(Commission).where(
            and_(
                Commission.brand_id == brand_uuid,
                Commission.created_at >= start_date,
            )
        )
        result = await session.execute(stmt)
        commissions = result.scalars().all()

        if not commissions:
            return {
                "brand_id": brand_id,
                "period_days": days,
                "total_commissions": 0,
                "total_revenue": 0.0,
                "confirmed_revenue": 0.0,
                "conversion_rate": 0.0,
                "average_commission": 0.0,
            }

        # Calculate stats
        total_commissions = len(commissions)
        confirmed = [c for c in commissions if c.is_confirmed]
        confirmed_count = len(confirmed)

        total_revenue = sum(c.commission_amount for c in commissions)
        confirmed_revenue = sum(c.commission_amount for c in confirmed)

        # Conversion rate
        conversion_rate = (
            (confirmed_count / total_commissions * 100)
            if total_commissions > 0
            else 0.0
        )

        # Average commission
        average_commission = (
            total_revenue / total_commissions if total_commissions > 0 else 0.0
        )

        return {
            "brand_id": brand_id,
            "period_days": days,
            "total_commissions": total_commissions,
            "pending_commissions": total_commissions - confirmed_count,
            "confirmed_commissions": confirmed_count,
            "total_revenue": round(total_revenue, 2),
            "confirmed_revenue": round(confirmed_revenue, 2),
            "conversion_rate": round(conversion_rate, 2),
            "average_commission": round(average_commission, 2),
        }

    @staticmethod
    async def get_underperforming_brands(
        session: AsyncSession,
        min_conversion_rate: float = 0.20,  # 20%
        min_commission: float = 10.0,  # $10
        days: int = 30,
        min_sample_size: int = 5,
    ) -> list[dict]:
        """
        Find brands with low conversion rates or commission earnings.

        Args:
            session: SQLAlchemy async session
            min_conversion_rate: Minimum acceptable conversion rate (0-1)
            min_commission: Minimum acceptable total commission amount
            days: Number of days to look back
            min_sample_size: Minimum number of conversions to evaluate

        Returns:
            List of underperforming brand stats
        """
        start_date = datetime.now(timezone.utc) - timedelta(days=days)

        # Get commission stats per brand
        brand_stats = await session.execute(
            select(
                Commission.brand_id,
                func.count(Commission.id).label("total"),
                func.sum(Commission.is_confirmed.cast(type_=int)).label("confirmed"),
                func.sum(Commission.commission_amount).label("total_commission"),
            )
            .where(Commission.created_at >= start_date)
            .group_by(Commission.brand_id)
        )

        results = brand_stats.all()
        underperforming = []

        for brand_id, total, confirmed, total_commission in results:
            if not total or total < min_sample_size:
                continue

            confirmed = confirmed or 0
            total_commission = total_commission or 0.0

            conversion_rate = confirmed / total

            if (
                conversion_rate < min_conversion_rate
                or total_commission < min_commission
            ):
                # Get brand name
                brand = await session.get(Brand, brand_id)
                underperforming.append(
                    {
                        "brand_id": str(brand_id),
                        "brand_name": brand.name if brand else "Unknown",
                        "total_clicks": total,
                        "conversions": confirmed,
                        "conversion_rate": round(conversion_rate, 3),
                        "total_commission": round(total_commission, 2),
                        "reason": (
                            "low_conversion_rate"
                            if conversion_rate < min_conversion_rate
                            else "low_commission"
                        ),
                    }
                )

        return sorted(underperforming, key=lambda x: x["conversion_rate"])

    @staticmethod
    async def get_top_performing_brands(
        session: AsyncSession,
        days: int = 30,
        limit: int = 10,
    ) -> list[dict]:
        """
        Get top performing brands by commission revenue.

        Args:
            session: SQLAlchemy async session
            days: Number of days to look back
            limit: Maximum brands to return

        Returns:
            List of top brand stats
        """
        start_date = datetime.now(timezone.utc) - timedelta(days=days)

        # Get commission stats per brand
        brand_stats = await session.execute(
            select(
                Commission.brand_id,
                func.count(Commission.id).label("total"),
                func.sum(Commission.is_confirmed.cast(type_=int)).label("confirmed"),
                func.sum(Commission.commission_amount).label("total_commission"),
            )
            .where(Commission.created_at >= start_date)
            .group_by(Commission.brand_id)
            .order_by(func.sum(Commission.commission_amount).desc())
            .limit(limit)
        )

        results = brand_stats.all()
        top_brands = []

        for brand_id, total, confirmed, total_commission in results:
            confirmed = confirmed or 0
            total_commission = total_commission or 0.0
            conversion_rate = (confirmed / total) if total > 0 else 0.0

            # Get brand name
            brand = await session.get(Brand, brand_id)
            top_brands.append(
                {
                    "brand_id": str(brand_id),
                    "brand_name": brand.name if brand else "Unknown",
                    "total_clicks": total,
                    "conversions": confirmed,
                    "conversion_rate": round(conversion_rate, 3),
                    "total_commission": round(total_commission, 2),
                }
            )

        return top_brands

    @staticmethod
    async def get_retailer_performance(
        session: AsyncSession,
        days: int = 30,
    ) -> list[dict]:
        """
        Get performance metrics by retailer/affiliate network.

        Args:
            session: SQLAlchemy async session
            days: Number of days to look back

        Returns:
            List of retailer performance stats
        """
        start_date = datetime.now(timezone.utc) - timedelta(days=days)

        # Get commission stats per retailer
        retailer_stats = await session.execute(
            select(
                Commission.retailer_id,
                func.count(Commission.id).label("total"),
                func.sum(Commission.is_confirmed.cast(type_=int)).label("confirmed"),
                func.sum(Commission.commission_amount).label("total_commission"),
                func.avg(Commission.commission_amount).label("avg_commission"),
            )
            .where(Commission.created_at >= start_date)
            .group_by(Commission.retailer_id)
            .order_by(func.sum(Commission.commission_amount).desc())
        )

        results = retailer_stats.all()
        retailer_perf = []

        for retailer_id, total, confirmed, total_commission, avg_commission in results:
            confirmed = confirmed or 0
            total_commission = total_commission or 0.0
            avg_commission = avg_commission or 0.0
            conversion_rate = (confirmed / total) if total > 0 else 0.0

            # Get retailer name
            retailer = await session.get(Retailer, retailer_id)
            retailer_perf.append(
                {
                    "retailer_id": str(retailer_id),
                    "retailer_name": retailer.name if retailer else "Unknown",
                    "affiliate_network": retailer.affiliate_network.value
                    if retailer
                    else "Unknown",
                    "total_clicks": total,
                    "conversions": confirmed,
                    "conversion_rate": round(conversion_rate, 3),
                    "total_commission": round(total_commission, 2),
                    "average_commission": round(avg_commission, 2),
                }
            )

        return retailer_perf

    @staticmethod
    async def record_conversion(
        session: AsyncSession,
        commission_id: str,
    ) -> Commission:
        """
        Mark a commission as confirmed/converted.

        Args:
            session: SQLAlchemy async session
            commission_id: Commission ID

        Returns:
            Updated Commission
        """
        import uuid

        commission = await session.get(Commission, uuid.UUID(commission_id))
        if not commission:
            raise ValueError(f"Commission {commission_id} not found")

        commission.is_pending = False
        commission.is_confirmed = True
        commission.conversion_timestamp = datetime.now(timezone.utc)

        await session.flush()
        logger.info(f"Recorded conversion for commission {commission_id}")

        return commission

    @staticmethod
    async def reject_commission(
        session: AsyncSession,
        commission_id: str,
        reason: str,
    ) -> Commission:
        """
        Reject a commission.

        Args:
            session: SQLAlchemy async session
            commission_id: Commission ID
            reason: Reason for rejection

        Returns:
            Updated Commission
        """
        import uuid

        commission = await session.get(Commission, uuid.UUID(commission_id))
        if not commission:
            raise ValueError(f"Commission {commission_id} not found")

        commission.is_pending = False
        commission.is_rejected = True
        commission.rejection_reason = reason

        await session.flush()
        logger.info(f"Rejected commission {commission_id}: {reason}")

        return commission
