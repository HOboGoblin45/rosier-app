"""Authentication endpoint tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.security import hash_password
from app.models import User, RefreshToken
from app.schemas.auth import EmailRegisterRequest, EmailLoginRequest


@pytest.mark.asyncio
async def test_email_register_success(client: AsyncClient, db_session: AsyncSession):
    """Test successful email registration."""
    response = await client.post(
        "/api/v1/auth/email/register",
        json={
            "email": "newuser@example.com",
            "password": "SecurePassword123!",
            "display_name": "New User"
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["expires_in"] > 0

    # Verify user was created in database
    stmt = select(User).where(User.email == "newuser@example.com")
    result = await db_session.execute(stmt)
    user = result.scalar_one_or_none()
    assert user is not None
    assert user.display_name == "New User"


@pytest.mark.asyncio
async def test_email_register_duplicate(client: AsyncClient, sample_user: User):
    """Test registration with duplicate email."""
    response = await client.post(
        "/api/v1/auth/email/register",
        json={
            "email": sample_user.email,
            "password": "SecurePassword123!",
            "display_name": "Another User"
        }
    )

    assert response.status_code == 400
    data = response.json()
    assert "already registered" in data["detail"].lower() or "email" in data["detail"].lower()


@pytest.mark.asyncio
async def test_email_register_invalid_password(client: AsyncClient):
    """Test registration with invalid password."""
    response = await client.post(
        "/api/v1/auth/email/register",
        json={
            "email": "user@example.com",
            "password": "short",
            "display_name": "User"
        }
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_email_register_invalid_email(client: AsyncClient):
    """Test registration with invalid email."""
    response = await client.post(
        "/api/v1/auth/email/register",
        json={
            "email": "not-an-email",
            "password": "SecurePassword123!",
            "display_name": "User"
        }
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_email_login_success(client: AsyncClient, db_session: AsyncSession):
    """Test successful email login."""
    # Create a user first
    password = "TestPassword123!"
    user = User(
        email="login@example.com",
        hashed_password=hash_password(password),
        display_name="Login User"
    )
    db_session.add(user)
    await db_session.commit()

    # Attempt login
    response = await client.post(
        "/api/v1/auth/email/login",
        json={
            "email": "login@example.com",
            "password": password
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_email_login_wrong_password(client: AsyncClient, db_session: AsyncSession):
    """Test login with wrong password."""
    password = "TestPassword123!"
    user = User(
        email="wrongpass@example.com",
        hashed_password=hash_password(password),
        display_name="Wrong Pass User"
    )
    db_session.add(user)
    await db_session.commit()

    response = await client.post(
        "/api/v1/auth/email/login",
        json={
            "email": "wrongpass@example.com",
            "password": "WrongPassword123!"
        }
    )

    assert response.status_code == 401
    data = response.json()
    assert "invalid" in data["detail"].lower()


@pytest.mark.asyncio
async def test_email_login_nonexistent_user(client: AsyncClient):
    """Test login with nonexistent user."""
    response = await client.post(
        "/api/v1/auth/email/login",
        json={
            "email": "nonexistent@example.com",
            "password": "SomePassword123!"
        }
    )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_refresh_token_success(
    authenticated_user: tuple[User, str],
    db_session: AsyncSession,
    client: AsyncClient
):
    """Test successful token refresh."""
    user, access_token = authenticated_user

    # Create a refresh token in the database
    from app.core.security import create_refresh_token
    from datetime import datetime, timezone, timedelta

    refresh_token = create_refresh_token(str(user.id))
    expires = datetime.now(timezone.utc) + timedelta(days=30)

    token_obj = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=expires,
        is_revoked=False
    )
    db_session.add(token_obj)
    await db_session.commit()

    # Attempt refresh
    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token}
    )

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_refresh_token_revoked(
    authenticated_user: tuple[User, str],
    db_session: AsyncSession,
    client: AsyncClient
):
    """Test refresh with revoked token."""
    user, _ = authenticated_user

    from app.core.security import create_refresh_token
    from datetime import datetime, timezone, timedelta

    refresh_token = create_refresh_token(str(user.id))
    expires = datetime.now(timezone.utc) + timedelta(days=30)

    token_obj = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=expires,
        is_revoked=True
    )
    db_session.add(token_obj)
    await db_session.commit()

    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token}
    )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_refresh_token_expired(
    authenticated_user: tuple[User, str],
    db_session: AsyncSession,
    client: AsyncClient
):
    """Test refresh with expired token."""
    user, _ = authenticated_user

    from app.core.security import create_refresh_token
    from datetime import datetime, timezone, timedelta

    refresh_token = create_refresh_token(str(user.id))
    expires = datetime.now(timezone.utc) - timedelta(days=1)  # Expired

    token_obj = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=expires,
        is_revoked=False
    )
    db_session.add(token_obj)
    await db_session.commit()

    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token}
    )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_delete_account(authenticated_client: AsyncClient, db_session: AsyncSession):
    """Test account deletion."""
    # Get current user from token (requires auth)
    response = await authenticated_client.post(
        "/api/v1/auth/delete-account"
    )

    # Either 204 (no content) or 200
    assert response.status_code in [200, 204]


@pytest.mark.asyncio
async def test_sign_out(authenticated_user: tuple[User, str], db_session: AsyncSession, client: AsyncClient):
    """Test sign out endpoint."""
    user, access_token = authenticated_user

    from app.core.security import create_refresh_token
    from datetime import datetime, timezone, timedelta

    refresh_token = create_refresh_token(str(user.id))
    expires = datetime.now(timezone.utc) + timedelta(days=30)

    token_obj = RefreshToken(
        user_id=user.id,
        token=refresh_token,
        expires_at=expires,
        is_revoked=False
    )
    db_session.add(token_obj)
    await db_session.commit()

    # Sign out
    response = await client.post(
        "/api/v1/auth/sign-out",
        json={"refresh_token": refresh_token},
        headers={"Authorization": f"Bearer {access_token}"}
    )

    assert response.status_code in [200, 204]

    # Verify token is revoked
    stmt = select(RefreshToken).where(RefreshToken.token == refresh_token)
    result = await db_session.execute(stmt)
    token_record = result.scalar_one()
    assert token_record.is_revoked is True
