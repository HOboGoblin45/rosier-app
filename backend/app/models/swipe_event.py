"""Swipe event model."""
import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import DateTime, Enum as SQLEnum, Float, ForeignKey, Index, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class SwipeAction(str, Enum):
    """Swipe action enumeration."""

    LIKE = "like"
    REJECT = "reject"
    SUPER_LIKE = "super_like"
    UNDO = "undo"
    VIEW_DETAIL = "view_detail"
    SHOP_CLICK = "shop_click"


class SwipeEvent(Base):
    """Swipe event model."""

    __tablename__ = "swipe_events"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id"), nullable=False, index=True
    )

    action: Mapped[SwipeAction] = mapped_column(SQLEnum(SwipeAction), nullable=False, index=True)
    dwell_time_ms: Mapped[int] = mapped_column(Integer, nullable=True)
    session_position: Mapped[int] = mapped_column(Integer, nullable=True)
    expanded: Mapped[bool] = mapped_column(default=False)
    session_id: Mapped[str] = mapped_column(String(255), nullable=True, index=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True
    )

    __table_args__ = (
        Index("idx_swipe_user_created", "user_id", "created_at"),
        Index("idx_swipe_product_action", "product_id", "action"),
        Index("idx_swipe_session_id", "session_id"),
        Index("idx_swipe_action", "action"),
    )
