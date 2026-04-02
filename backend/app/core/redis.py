"""Redis client and cache operations."""
from typing import Any, Optional

import redis.asyncio as redis

from app.core.config import get_settings


class RedisClient:
    """Async Redis client wrapper."""

    _instance: Optional[redis.Redis] = None

    @classmethod
    async def get_client(cls) -> redis.Redis:
        """Get or create Redis client."""
        if cls._instance is None:
            settings = get_settings()
            cls._instance = await redis.from_url(
                settings.REDIS_URL, encoding="utf-8", decode_responses=True
            )
        return cls._instance

    @classmethod
    async def close(cls) -> None:
        """Close Redis connection."""
        if cls._instance:
            await cls._instance.close()
            cls._instance = None


async def get_redis() -> redis.Redis:
    """Dependency to get Redis client."""
    return await RedisClient.get_client()


async def set_cache(
    key: str, value: Any, ttl: int = 3600, client: Optional[redis.Redis] = None
) -> None:
    """Set value in Redis cache with TTL."""
    if client is None:
        client = await get_redis()

    if isinstance(value, (dict, list)):
        import json

        value = json.dumps(value)

    await client.setex(key, ttl, value)


async def get_cache(key: str, client: Optional[redis.Redis] = None) -> Optional[Any]:
    """Get value from Redis cache."""
    if client is None:
        client = await get_redis()

    value = await client.get(key)
    if value is None:
        return None

    # Try to parse as JSON
    try:
        import json

        return json.loads(value)
    except (json.JSONDecodeError, TypeError):
        return value


async def delete_cache(key: str, client: Optional[redis.Redis] = None) -> None:
    """Delete key from Redis cache."""
    if client is None:
        client = await get_redis()

    await client.delete(key)


async def incr_rate_limit(
    key: str, limit: int, window: int, client: Optional[redis.Redis] = None
) -> tuple[int, int]:
    """
    Increment rate limit counter.
    Returns (current_count, reset_time_seconds).
    """
    if client is None:
        client = await get_redis()

    pipe = client.pipeline()
    await pipe.incr(key).expire(key, window).execute()

    current = await client.get(key)
    ttl = await client.ttl(key)

    return int(current), ttl if ttl > 0 else window


async def get_card_queue(user_id: str, client: Optional[redis.Redis] = None) -> list:
    """Get user's card queue from Redis."""
    if client is None:
        client = await get_redis()

    queue_key = f"card_queue:{user_id}"
    queue_json = await client.get(queue_key)

    if queue_json is None:
        return []

    import json

    return json.loads(queue_json)


async def set_card_queue(
    user_id: str, cards: list, ttl: int = 3600, client: Optional[redis.Redis] = None
) -> None:
    """Set user's card queue in Redis."""
    if client is None:
        client = await get_redis()

    import json

    queue_key = f"card_queue:{user_id}"
    await client.setex(queue_key, ttl, json.dumps(cards))


async def clear_card_queue(user_id: str, client: Optional[redis.Redis] = None) -> None:
    """Clear user's card queue."""
    if client is None:
        client = await get_redis()

    queue_key = f"card_queue:{user_id}"
    await client.delete(queue_key)


async def add_to_queue(
    user_id: str, card: dict, client: Optional[redis.Redis] = None
) -> None:
    """Add a card to user's queue."""
    if client is None:
        client = await get_redis()

    queue = await get_card_queue(user_id, client)
    queue.append(card)
    await set_card_queue(user_id, queue, client=client)


async def remove_from_queue(
    user_id: str, product_id: str, client: Optional[redis.Redis] = None
) -> None:
    """Remove a card from user's queue by product_id."""
    if client is None:
        client = await get_redis()

    queue = await get_card_queue(user_id, client)
    queue = [card for card in queue if card.get("product_id") != product_id]
    await set_card_queue(user_id, queue, client=client)
