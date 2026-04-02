"""WebSocket connection manager for real-time events."""

import logging
from typing import Any, Optional

from fastapi import WebSocket
import asyncio

logger = logging.getLogger(__name__)


class WebSocketConnectionManager:
    """Manager for WebSocket connections with thread-safe operations."""

    def __init__(self):
        """Initialize the connection manager."""
        self.active_connections: dict[str, list[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket, user_id: str) -> None:
        """
        Add a new WebSocket connection for a user.

        Args:
            websocket: WebSocket connection
            user_id: User ID associated with this connection
        """
        await websocket.accept()
        async with self._lock:
            if user_id not in self.active_connections:
                self.active_connections[user_id] = []
            self.active_connections[user_id].append(websocket)
        logger.info(
            f"User {user_id} connected. Active connections: {len(self.active_connections[user_id])}"
        )

    async def disconnect(self, websocket: WebSocket, user_id: str) -> None:
        """
        Remove a WebSocket connection for a user.

        Args:
            websocket: WebSocket connection to remove
            user_id: User ID associated with this connection
        """
        async with self._lock:
            if user_id in self.active_connections:
                try:
                    self.active_connections[user_id].remove(websocket)
                    if not self.active_connections[user_id]:
                        del self.active_connections[user_id]
                except ValueError:
                    pass
        logger.info(f"User {user_id} disconnected.")

    async def send_to_user(self, user_id: str, message: dict[str, Any]) -> None:
        """
        Send a message to all connections for a specific user.

        Args:
            user_id: Target user ID
            message: Message dict to send (will be JSON-encoded)
        """
        async with self._lock:
            connections = self.active_connections.get(user_id, []).copy()

        disconnected = []
        for connection in connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.warning(f"Error sending message to user {user_id}: {e}")
                disconnected.append(connection)

        # Clean up disconnected connections
        if disconnected:
            async with self._lock:
                if user_id in self.active_connections:
                    for conn in disconnected:
                        try:
                            self.active_connections[user_id].remove(conn)
                        except ValueError:
                            pass
                    if not self.active_connections[user_id]:
                        del self.active_connections[user_id]

    async def broadcast(self, message: dict[str, Any]) -> None:
        """
        Send a message to all connected users.

        Args:
            message: Message dict to send (will be JSON-encoded)
        """
        async with self._lock:
            user_ids = list(self.active_connections.keys())

        for user_id in user_ids:
            await self.send_to_user(user_id, message)

    async def get_connection_count(self, user_id: Optional[str] = None) -> int:
        """
        Get the number of active connections.

        Args:
            user_id: If provided, get count for this user only. Otherwise get total.
        """
        async with self._lock:
            if user_id:
                return len(self.active_connections.get(user_id, []))
            return sum(len(conns) for conns in self.active_connections.values())

    async def get_active_users(self) -> list[str]:
        """Get list of user IDs with active connections."""
        async with self._lock:
            return list(self.active_connections.keys())


# Global connection manager instance
manager = WebSocketConnectionManager()


async def get_websocket_manager() -> WebSocketConnectionManager:
    """Get the global WebSocket connection manager."""
    return manager
