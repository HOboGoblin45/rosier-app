"""Rate limiting middleware."""

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

from app.core.redis import incr_rate_limit, get_redis


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Rate limiting middleware using Redis."""

    # Rate limit configurations: (requests, time_window_seconds)
    RATE_LIMITS = {
        "/api/v1/cards/next": (60, 60),  # 60 req/min
        "/api/v1/cards/events": (30, 60),  # 30 req/min
        "/api/v1/auth": (10, 60),  # 10 req/min
    }

    async def dispatch(self, request: Request, call_next) -> Response:
        """Process request and apply rate limiting."""
        # Skip rate limiting for health check
        if request.url.path == "/health":
            return await call_next(request)

        # Determine rate limit for this path
        limit_config = None
        for path_pattern, config in self.RATE_LIMITS.items():
            if request.url.path.startswith(path_pattern):
                limit_config = config
                break

        if not limit_config:
            return await call_next(request)

        # Get client identifier

        # Try to get user ID from token
        user_id = "anonymous"
        if request.headers.get("Authorization"):
            from app.core.security import verify_access_token

            token = request.headers.get("Authorization", "").replace("Bearer ", "")
            verified_user = verify_access_token(token)
            if verified_user:
                user_id = verified_user

        rate_limit_key = f"rate_limit:{user_id}:{request.url.path}"
        limit, window = limit_config

        try:
            client = await get_redis()
            current, ttl = await incr_rate_limit(rate_limit_key, limit, window, client)

            if current > limit:
                return Response(
                    content='{"detail":"Rate limit exceeded"}',
                    status_code=429,
                    media_type="application/json",
                    headers={"Retry-After": str(ttl)},
                )

            # Add rate limit headers to response
            response = await call_next(request)
            response.headers["X-RateLimit-Limit"] = str(limit)
            response.headers["X-RateLimit-Remaining"] = str(max(0, limit - current))
            response.headers["X-RateLimit-Reset"] = str(int(ttl))

            return response
        except Exception:
            # If Redis fails, allow the request through
            return await call_next(request)
