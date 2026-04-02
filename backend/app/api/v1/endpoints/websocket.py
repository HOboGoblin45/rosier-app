"""WebSocket endpoint for real-time events."""
import asyncio
import json
import logging
from typing import Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import verify_access_token
from app.core.websocket_manager import get_websocket_manager, WebSocketConnectionManager

logger = logging.getLogger(__name__)

router = APIRouter(tags=["websocket"])


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket) -> None:
    """
    WebSocket endpoint for real-time events.

    Supports authentication via:
    1. Query parameter: ?token=<jwt_token>
    2. First message: {"type": "auth", "token": "<jwt_token>"}

    Events sent by server:
    - price_drop: Price change notification
    - new_daily_drop: New daily 5 available
    - dresser_update: Saved item status change
    - feed_refresh: New cards available
    """
    manager = await get_websocket_manager()
    user_id: Optional[str] = None

    try:
        # Try to get token from query params
        token = None
        if websocket.query_params:
            token = websocket.query_params.get("token")

        # If no token in query, wait for auth message
        if not token:
            await websocket.accept()
            # Set a timeout for authentication
            try:
                auth_msg = await asyncio.wait_for(websocket.receive_text(), timeout=5.0)
                auth_data = json.loads(auth_msg)
                if auth_data.get("type") == "auth":
                    token = auth_data.get("token")
            except asyncio.TimeoutError:
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Authentication timeout")
                return
            except Exception as e:
                logger.error(f"Error receiving auth message: {e}")
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid auth message")
                return

        # Verify token
        if not token:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="No token provided")
            return

        user_id = verify_access_token(token)
        if not user_id:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
            return

        # Accept connection
        if websocket.application_state.value == 0:  # CONNECTING
            await manager.connect(websocket, user_id)
        else:
            await manager.connect(websocket, user_id)

        logger.info(f"WebSocket connection established for user: {user_id}")

        # Start heartbeat task
        heartbeat_task = asyncio.create_task(_heartbeat(websocket, user_id))

        try:
            while True:
                # Receive message with timeout
                try:
                    data = await asyncio.wait_for(websocket.receive_text(), timeout=60.0)
                    message = json.loads(data)

                    # Handle ping/pong
                    if message.get("type") == "ping":
                        await websocket.send_json({"type": "pong"})
                except asyncio.TimeoutError:
                    # No message received for 60 seconds, close connection
                    await websocket.close(code=status.WS_1000_NORMAL_CLOSURE, reason="Idle timeout")
                    break
        except WebSocketDisconnect:
            logger.info(f"WebSocket disconnected for user: {user_id}")
        finally:
            # Cancel heartbeat task
            heartbeat_task.cancel()
            try:
                await heartbeat_task
            except asyncio.CancelledError:
                pass

    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        if user_id:
            await manager.disconnect(websocket, user_id)


async def _heartbeat(websocket: WebSocket, user_id: str) -> None:
    """Send periodic heartbeat pings to keep connection alive."""
    try:
        while True:
            await asyncio.sleep(30)  # Send heartbeat every 30 seconds
            try:
                await websocket.send_json({"type": "ping"})
            except Exception:
                break
    except asyncio.CancelledError:
        pass


async def broadcast_price_drop(
    user_id: str,
    product_id: str,
    old_price: float,
    new_price: float,
    product_name: str,
) -> None:
    """
    Broadcast a price drop event to a user.

    Args:
        user_id: Target user ID
        product_id: Product that had price change
        old_price: Previous price
        new_price: New price
        product_name: Product name
    """
    manager = await get_websocket_manager()
    message = {
        "type": "price_drop",
        "product_id": product_id,
        "product_name": product_name,
        "old_price": old_price,
        "new_price": new_price,
        "discount_percent": round(((old_price - new_price) / old_price) * 100, 1) if old_price > 0 else 0,
    }
    await manager.send_to_user(user_id, message)


async def broadcast_new_daily_drop(
    user_id: str,
    product_ids: list[str],
    generated_at: str,
) -> None:
    """
    Broadcast a new daily drop event to a user.

    Args:
        user_id: Target user ID
        product_ids: List of product IDs in the daily drop
        generated_at: ISO timestamp when daily drop was generated
    """
    manager = await get_websocket_manager()
    message = {
        "type": "new_daily_drop",
        "product_ids": product_ids,
        "generated_at": generated_at,
    }
    await manager.send_to_user(user_id, message)


async def broadcast_dresser_update(
    user_id: str,
    product_id: str,
    status: str,
    message_text: str,
) -> None:
    """
    Broadcast a dresser item update event.

    Args:
        user_id: Target user ID
        product_id: Product that changed
        status: Status of change (e.g., 'out_of_stock', 'discontinued')
        message_text: Human-readable message
    """
    manager = await get_websocket_manager()
    message = {
        "type": "dresser_update",
        "product_id": product_id,
        "status": status,
        "message": message_text,
    }
    await manager.send_to_user(user_id, message)


async def broadcast_feed_refresh(user_id: str) -> None:
    """
    Broadcast a feed refresh event (new cards available).

    Args:
        user_id: Target user ID
    """
    manager = await get_websocket_manager()
    message = {
        "type": "feed_refresh",
        "message": "New cards are available",
    }
    await manager.send_to_user(user_id, message)
