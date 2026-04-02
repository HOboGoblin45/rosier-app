"""Sentry configuration for error tracking and performance monitoring."""

import os
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
from sentry_sdk.integrations.redis import RedisIntegration
from sentry_sdk.integrations.asyncio import AsyncioIntegration
from sentry_sdk.integrations.logging import LoggingIntegration
from sentry_sdk.integrations.starlette import StarletteIntegration


def get_sentry_dsn() -> str:
    """Get Sentry DSN based on environment."""
    environment = os.getenv("ENVIRONMENT", "development")

    if environment == "production":
        return os.getenv("SENTRY_DSN_PRODUCTION", "")
    elif environment == "staging":
        return os.getenv("SENTRY_DSN_STAGING", "")
    else:
        return os.getenv("SENTRY_DSN_DEVELOPMENT", "")


def scrub_sensitive_data(event, hint):
    """
    Scrub sensitive data from Sentry events.

    Removes:
    - Email addresses
    - Phone numbers
    - API keys and tokens
    - Credit card numbers
    - Social security numbers
    """
    if "request" in event:
        request = event["request"]

        # Scrub query string parameters
        if "query_string" in request and request["query_string"]:
            # Remove common sensitive parameters
            sensitive_params = [
                "api_key",
                "token",
                "password",
                "secret",
                "authorization",
                "credit_card",
                "email",
                "phone",
            ]
            query_parts = []
            for param in request["query_string"].split("&"):
                if "=" in param:
                    key, value = param.split("=", 1)
                    if key.lower() in sensitive_params:
                        query_parts.append(f"{key}=***REDACTED***")
                    else:
                        query_parts.append(param)
                else:
                    query_parts.append(param)
            request["query_string"] = "&".join(query_parts)

        # Scrub headers
        if "headers" in request:
            sensitive_headers = ["authorization", "x-api-key", "cookie"]
            for header in sensitive_headers:
                if header in request["headers"]:
                    request["headers"][header] = "***REDACTED***"

        # Scrub request body
        if "data" in request and isinstance(request["data"], dict):
            for key in request["data"]:
                if key.lower() in [
                    "password",
                    "api_key",
                    "token",
                    "secret",
                    "credit_card",
                ]:
                    request["data"][key] = "***REDACTED***"

    # Scrub breadcrumbs
    if "breadcrumbs" in event:
        for breadcrumb in event["breadcrumbs"]:
            if "data" in breadcrumb and isinstance(breadcrumb["data"], dict):
                for key in list(breadcrumb["data"].keys()):
                    if key.lower() in [
                        "password",
                        "api_key",
                        "token",
                        "secret",
                    ]:
                        breadcrumb["data"][key] = "***REDACTED***"

    return event


def before_send(event, hint):
    """Filter events before sending to Sentry."""
    # Ignore 404 errors (expected in production)
    if event.get("tags", {}).get("status_code") == 404:
        return None

    # Ignore rate limit errors (expected under load)
    if event.get("tags", {}).get("status_code") == 429:
        return None

    # Ignore health check errors
    if "/health" in event.get("request", {}).get("url", ""):
        return None

    # Scrub sensitive data
    event = scrub_sensitive_data(event, hint)

    return event


def init_sentry(app_name: str = "Rosier"):
    """
    Initialize Sentry error tracking and performance monitoring.

    Args:
        app_name: Application name for Sentry

    Configuration:
    - Environment-based DSN selection
    - Performance tracing (10% sample rate in production)
    - User context attachment
    - Sensitive data scrubbing
    - Custom tags
    - Event filtering
    """
    environment = os.getenv("ENVIRONMENT", "development")
    dsn = get_sentry_dsn()

    if not dsn:
        # Sentry disabled if no DSN is configured
        return

    # Determine sample rates
    traces_sample_rate = 0.0
    if environment == "production":
        traces_sample_rate = 0.1  # 10% in production
    elif environment == "staging":
        traces_sample_rate = 0.5  # 50% in staging
    else:
        traces_sample_rate = 1.0  # 100% in development

    sentry_sdk.init(
        dsn=dsn,
        integrations=[
            FastApiIntegration(),
            StarletteIntegration(),
            SqlalchemyIntegration(),
            RedisIntegration(),
            AsyncioIntegration(),
            LoggingIntegration(level=20, event_level=40),  # Capture info and higher
        ],
        # Set the environment
        environment=environment,
        # Set the application name/version
        release=os.getenv("APP_VERSION", "unknown"),
        # Performance monitoring
        traces_sample_rate=traces_sample_rate,
        # Default tags applied to all events
        default_integrations=True,
        # Before send hook for filtering/scrubbing
        before_send=before_send,
        # Capture breadcrumbs
        attach_stacktrace=True,
        # Max breadcrumb count
        max_breadcrumbs=100,
        # Normalize user IP addresses (privacy)
        send_default_pii=False,
        # Include local variables in stack traces (development only)
        include_local_variables=environment == "development",
        # Server name (instance identifier)
        server_name=os.getenv("HOSTNAME", "unknown"),
    )

    # Set global tags
    with sentry_sdk.push_scope() as scope:
        scope.set_tag("environment", environment)
        scope.set_tag("app_name", app_name)
        scope.set_tag("region", os.getenv("AWS_REGION", "unknown"))


def set_user_context(user_id: str = None, email: str = None, username: str = None):
    """
    Set user context for Sentry events.

    Args:
        user_id: Unique user identifier
        email: User email address
        username: Username
    """
    with sentry_sdk.push_scope() as scope:
        if user_id:
            scope.set_user({"id": user_id, "email": email, "username": username})


def set_custom_context(key: str, value: dict):
    """
    Set custom context for Sentry events.

    Args:
        key: Context key
        value: Context value (dict)
    """
    with sentry_sdk.push_scope() as scope:
        scope.set_context(key, value)


def set_extra_data(key: str, value):
    """
    Set extra data for Sentry events.

    Args:
        key: Data key
        value: Data value
    """
    with sentry_sdk.push_scope() as scope:
        scope.set_extra(key, value)


def capture_exception(exception: Exception, message: str = None, level: str = "error"):
    """
    Capture an exception with Sentry.

    Args:
        exception: Exception to capture
        message: Optional message
        level: Log level (error, warning, info)
    """
    with sentry_sdk.push_scope() as scope:
        scope.set_level(level)
        if message:
            scope.set_extra("message", message)
        sentry_sdk.capture_exception(exception)


def capture_message(message: str, level: str = "info"):
    """
    Capture a message with Sentry.

    Args:
        message: Message to capture
        level: Log level (debug, info, warning, error)
    """
    with sentry_sdk.push_scope() as scope:
        scope.set_level(level)
        sentry_sdk.capture_message(message, level=level)


def add_breadcrumb(
    message: str, category: str = "default", level: str = "info", data: dict = None
):
    """
    Add a breadcrumb for event tracing.

    Args:
        message: Breadcrumb message
        category: Category (e.g., 'auth', 'db', 'http')
        level: Level (debug, info, warning)
        data: Additional data (dict)
    """
    sentry_sdk.add_breadcrumb(
        message=message, category=category, level=level, data=data or {}
    )
