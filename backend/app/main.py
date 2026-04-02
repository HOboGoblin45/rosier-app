"""FastAPI application factory with full service wiring."""
import logging
from contextlib import asynccontextmanager

import sentry_sdk
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pythonjsonlogger import jsonlogger

from app.api.v1.router import router as api_v1_router
from app.core import get_settings, init_db, get_engine
from app.core.redis import RedisClient
from app.core.elasticsearch import (
    get_elasticsearch,
    close_elasticsearch,
    create_products_index,
    health_check as es_health_check,
)
from app.middleware import RateLimitMiddleware

# Configure structured logging
_log_handler = logging.StreamHandler()
_formatter = jsonlogger.JsonFormatter(
    fmt="%(timestamp)s %(level)s %(name)s %(message)s",
    timestamp=True,
)
_log_handler.setFormatter(_formatter)

logger = logging.getLogger(__name__)
logger.addHandler(_log_handler)
logger.setLevel(logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan context manager for startup and shutdown."""
    # Startup
    settings = get_settings()
    logger.info("Starting Rosier API", extra={"service": "rosier"})

    try:
        # Initialize database
        engine = get_engine()
        await init_db(engine)
        logger.info("Database initialized")

        # Initialize Redis
        try:
            redis_client = await RedisClient.get_client()
            await redis_client.ping()
            logger.info("Redis connection established")
        except Exception as e:
            logger.warning(f"Redis connection failed: {e}")

        # Initialize Elasticsearch
        try:
            es_client = await get_elasticsearch()
            if await es_health_check():
                await create_products_index()
                logger.info("Elasticsearch initialized with products index")
            else:
                logger.warning("Elasticsearch health check failed")
        except Exception as e:
            logger.warning(f"Elasticsearch initialization failed: {e}")

        logger.info("Rosier API started successfully")
    except Exception as e:
        logger.error(f"Startup error: {e}")
        raise

    yield

    # Shutdown
    logger.info("Rosier API shutdown starting")
    try:
        await engine.dispose()
        await RedisClient.close()
        await close_elasticsearch()
        logger.info("Rosier API stopped successfully")
    except Exception as e:
        logger.error(f"Shutdown error: {e}")


def create_app() -> FastAPI:
    """Create and configure FastAPI application with all services."""
    settings = get_settings()

    # Initialize Sentry SDK if DSN is provided
    if settings.SENTRY_DSN:
        sentry_sdk.init(
            dsn=settings.SENTRY_DSN,
            integrations=[sentry_sdk.integrations.fastapi.FastApiIntegration()],
            traces_sample_rate=0.1 if settings.ENVIRONMENT == "production" else 1.0,
            environment=settings.ENVIRONMENT,
        )
        logger.info("Sentry SDK initialized")

    app = FastAPI(
        title="Rosier API",
        description="Swipe-based niche fashion discovery API with personalized recommendations",
        version="1.0.0",
        lifespan=lifespan,
        openapi_url="/api/v1/openapi.json",
        docs_url="/api/v1/docs",
        redoc_url="/api/v1/redoc",
    )

    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Rate limiting middleware
    app.add_middleware(RateLimitMiddleware)

    # Exception handlers
    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ):
        """Handle validation errors."""
        logger.warning(f"Validation error: {exc.errors()}")
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "detail": exc.errors(),
                "body": str(exc.body),
            },
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception):
        """Handle general exceptions."""
        logger.error(f"Unhandled exception: {exc}", exc_info=True)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"detail": "Internal server error"},
        )

    # Health check endpoint
    @app.get("/health")
    async def health_check() -> dict:
        """
        Health check endpoint with service status.

        Returns:
            Health status including database, Redis, and Elasticsearch
        """
        try:
            engine = get_engine()
            # Simple connection test
            async with engine.connect() as conn:
                await conn.exec_driver_sql("SELECT 1")
            db_status = "healthy"
        except Exception as e:
            logger.warning(f"Database health check failed: {e}")
            db_status = "unhealthy"

        try:
            redis_client = await RedisClient.get_client()
            await redis_client.ping()
            redis_status = "healthy"
        except Exception as e:
            logger.warning(f"Redis health check failed: {e}")
            redis_status = "unhealthy"

        try:
            es_ok = await es_health_check()
            es_status = "healthy" if es_ok else "unhealthy"
        except Exception as e:
            logger.warning(f"Elasticsearch health check failed: {e}")
            es_status = "unhealthy"

        return {
            "status": "healthy" if all([db_status == "healthy", redis_status == "healthy", es_status == "healthy"]) else "degraded",
            "service": settings.APP_NAME,
            "environment": settings.ENVIRONMENT,
            "database": db_status,
            "redis": redis_status,
            "elasticsearch": es_status,
        }

    # Root endpoint
    @app.get("/")
    async def root() -> dict:
        """Root endpoint with API metadata."""
        return {
            "service": settings.APP_NAME,
            "version": "1.0.0",
            "docs": "/api/v1/docs",
            "redoc": "/api/v1/redoc",
        }

    # Include API v1 routers
    app.include_router(api_v1_router)

    return app


# Create app instance
app = create_app()
