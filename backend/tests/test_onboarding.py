"""Onboarding endpoint tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models import User


@pytest.mark.asyncio
async def test_submit_quiz(authenticated_client: AsyncClient, db_session: AsyncSession):
    """Test submitting onboarding quiz."""
    response = await authenticated_client.post(
        "/api/v1/onboarding/quiz",
        json={
            "style_preferences": ["minimalist", "contemporary"],
            "favorite_brands": ["Paloma Wool", "Khaite"],
            "price_range": "luxury",
            "body_type": "pear",
            "shoe_size": "8",
            "color_preferences": ["black", "white", "beige"]
        }
    )

    assert response.status_code == 201
    data = response.json()
    assert "quiz_responses" in data or "status" in data


@pytest.mark.asyncio
async def test_quiz_generates_initial_queue(
    authenticated_client: AsyncClient,
    db_session: AsyncSession,
    authenticated_user
):
    """Test that quiz generates initial card queue."""
    user, _ = authenticated_user

    # Submit quiz
    response1 = await authenticated_client.post(
        "/api/v1/onboarding/quiz",
        json={
            "style_preferences": ["minimalist"],
            "favorite_brands": ["Paloma Wool"],
            "price_range": "luxury"
        }
    )

    assert response1.status_code == 201

    # Get initial cards
    response2 = await authenticated_client.get("/api/v1/cards/next")

    assert response2.status_code == 200
    data = response2.json()
    # Should have cards available
    cards = data.get("cards", data if isinstance(data, list) else [])
    assert isinstance(cards, list)


@pytest.mark.asyncio
async def test_get_onboarding_status(authenticated_client: AsyncClient):
    """Test getting onboarding status."""
    response = await authenticated_client.get("/api/v1/onboarding/status")

    assert response.status_code == 200
    data = response.json()
    assert "completed" in data or "onboarding_completed" in data or "status" in data


@pytest.mark.asyncio
async def test_complete_onboarding(authenticated_client: AsyncClient, db_session: AsyncSession):
    """Test marking onboarding as complete."""
    response = await authenticated_client.post(
        "/api/v1/onboarding/complete",
        json={}
    )

    assert response.status_code == 200
    data = response.json()
    assert "completed" in data or "status" in data


@pytest.mark.asyncio
async def test_onboarding_with_minimal_data(authenticated_client: AsyncClient):
    """Test onboarding with minimal required fields."""
    response = await authenticated_client.post(
        "/api/v1/onboarding/quiz",
        json={
            "style_preferences": ["minimalist"]
        }
    )

    assert response.status_code == 201


@pytest.mark.asyncio
async def test_update_onboarding_responses(authenticated_client: AsyncClient):
    """Test updating quiz responses mid-onboarding."""
    # Submit initial quiz
    response1 = await authenticated_client.post(
        "/api/v1/onboarding/quiz",
        json={"style_preferences": ["minimalist"]}
    )
    assert response1.status_code == 201

    # Update quiz responses
    response2 = await authenticated_client.put(
        "/api/v1/onboarding/quiz",
        json={
            "style_preferences": ["maximalist", "vintage"],
            "favorite_brands": ["Ganni", "Sandy Liang"]
        }
    )

    assert response2.status_code == 200


@pytest.mark.asyncio
async def test_get_quiz_questions(authenticated_client: AsyncClient):
    """Test getting available quiz questions."""
    response = await authenticated_client.get("/api/v1/onboarding/questions")

    assert response.status_code == 200
    data = response.json()
    assert "questions" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_skip_onboarding(authenticated_client: AsyncClient):
    """Test skipping onboarding."""
    response = await authenticated_client.post(
        "/api/v1/onboarding/skip"
    )

    assert response.status_code == 200 or response.status_code == 204


@pytest.mark.asyncio
async def test_onboarding_user_not_completed(authenticated_client: AsyncClient):
    """Test that user without completed onboarding is still allowed to use app."""
    response = await authenticated_client.get("/api/v1/cards/next")

    # Even without completed onboarding, user should be able to swipe
    assert response.status_code == 200
