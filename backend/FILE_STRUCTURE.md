# Rosier Backend - Complete File Structure

## Summary

Production-ready FastAPI backend with 41 Python modules, comprehensive database models, RESTful API endpoints, business logic services, and full Docker support.

## File Manifest

### Core Application
- **app/__init__.py** - App package entry point
- **app/main.py** - FastAPI application factory with lifespan management

### Core Configuration (app/core/)
- **app/core/__init__.py** - Core module exports
- **app/core/config.py** - Pydantic Settings (database, Redis, JWT, AWS, Apple, CORS)
- **app/core/database.py** - Async SQLAlchemy engine and session setup
- **app/core/redis.py** - Redis client and cache operations
- **app/core/security.py** - JWT token management, password hashing, Apple Sign-In verification

### Database Models (app/models/)
- **app/models/__init__.py** - Model package exports
- **app/models/user.py** - User model (auth, preferences, settings)
- **app/models/product.py** - Product model (pricing, inventory, images, tags)
- **app/models/brand.py** - Brand model (tier, aesthetics, price range)
- **app/models/retailer.py** - Retailer model (affiliate networks, feeds)
- **app/models/swipe_event.py** - SwipeEvent model (user interactions, analytics)
- **app/models/dresser.py** - DresserDrawer & DresserItem models (closet organization)
- **app/models/refresh_token.py** - RefreshToken model (token revocation)

### Pydantic Schemas (app/schemas/)
- **app/schemas/__init__.py** - Schema package exports
- **app/schemas/user.py** - User request/response schemas
- **app/schemas/product.py** - Product schemas (card, detail, similar)
- **app/schemas/auth.py** - Auth request/response schemas
- **app/schemas/swipe_event.py** - Swipe event schemas (batch submission)
- **app/schemas/dresser.py** - Dresser drawer & item schemas
- **app/schemas/style_dna.py** - Style DNA profile schemas

### API Endpoints (app/api/v1/endpoints/)
- **app/api/v1/endpoints/__init__.py** - Endpoints package marker
- **app/api/v1/endpoints/auth.py** - Authentication endpoints (Apple, email, refresh, logout)
- **app/api/v1/endpoints/onboarding.py** - Onboarding endpoints (quiz, status)
- **app/api/v1/endpoints/cards.py** - Card feed endpoints (next, submit events)
- **app/api/v1/endpoints/dresser.py** - Dresser endpoints (CRUD drawers & items)
- **app/api/v1/endpoints/products.py** - Product endpoints (detail, similar, affiliate)
- **app/api/v1/endpoints/profile.py** - Profile endpoints (user data, Style DNA, settings)

### API Routing
- **app/api/__init__.py** - API package marker
- **app/api/v1/__init__.py** - V1 API package marker
- **app/api/v1/router.py** - V1 router aggregation

### Services (app/services/)
- **app/services/__init__.py** - Services package exports
- **app/services/card_queue.py** - Card queue generation with diversity rules
- **app/services/recommendation.py** - Recommendation engine (Phase 1 tag-based)
- **app/services/price_monitor.py** - Price tracking and change detection
- **app/services/affiliate.py** - Affiliate link construction (Rakuten, Impact, Awin, etc.)

### Middleware (app/middleware/)
- **app/middleware/__init__.py** - Middleware package exports
- **app/middleware/rate_limiter.py** - Redis-based rate limiting middleware

### Project Configuration
- **requirements.txt** - Python dependencies (FastAPI, SQLAlchemy, Redis, etc.)
- **.env.example** - Environment variables template
- **Dockerfile** - Multi-stage Docker build
- **docker-compose.yml** - Local development stack (PostgreSQL, Redis, Elasticsearch, API)
- **alembic.ini** - Alembic migration configuration
- **migrations/env.py** - Alembic async environment setup
- **migrations/script.py.mako** - Alembic migration template
- **migrations/versions/** - Individual migration files (auto-generated)

### Documentation & Scripts
- **README.md** - Comprehensive project documentation
- **FILE_STRUCTURE.md** - This file
- **start.sh** - Development startup script

## Statistics

- **Total Python Files**: 41
- **Total Lines of Code**: ~5,500+
- **Database Models**: 8 (User, Product, Brand, Retailer, SwipeEvent, DresserDrawer, DresserItem, RefreshToken)
- **API Endpoints**: 28+ routes across 6 endpoint modules
- **Services**: 4 business logic service classes
- **Middleware**: 1 rate limiting middleware
- **Pydantic Schemas**: 35+ schema classes

## Technology Stack

- **Framework**: FastAPI 0.109+
- **ORM**: SQLAlchemy 2.0 (async)
- **Database**: PostgreSQL 16 with asyncpg
- **Cache**: Redis 7 with aioredis
- **Authentication**: JWT (HS256), Apple Sign-In
- **Password**: bcrypt via passlib
- **Validation**: Pydantic v2
- **Async**: Python 3.12 with asyncio
- **HTTP Client**: httpx for async requests
- **Serialization**: JSON with Pydantic

## Key Features Implemented

### Authentication
- Apple Sign-In with token verification
- Email/password registration and login
- JWT access tokens (15 min expiry)
- Refresh tokens with revocation tracking
- Account deletion with token invalidation

### Card Feed System
- Dynamic card queue with Redis caching
- Tag-based scoring algorithm
- Diversity rules (brand/retailer limits)
- Exploration cards (10% random)
- Batch swipe event submission

### Closet Management
- Multiple drawers organization
- Price tracking at save time
- Item movement between drawers
- Public shareable closet links
- User-specific access control

### Product Catalog
- Rich product metadata (images, sizes, colors)
- Brand and retailer categorization
- Price monitoring and sale detection
- Similar product recommendations
- Affiliate link generation (4+ networks)

### User Personalization
- Onboarding quiz responses
- Style DNA profile generation
- Preference extraction from history
- Shareable style profiles
- User settings management

### Performance & Scale
- Database indexes on all critical paths
- Redis caching for card queues (1hr TTL)
- Rate limiting per endpoint
- Async database and cache operations
- Connection pooling and recycling

### Error Handling
- Comprehensive validation with detailed errors
- HTTP status codes (200-500)
- Exception handlers for all scenarios
- Graceful failure modes
- Request/response logging ready

## Environment Configuration

All configuration via `.env`:
- Database (PostgreSQL async)
- Cache (Redis)
- Search (Elasticsearch)
- Security (JWT secrets)
- Apple Sign-In (Team ID, Key ID, Private Key)
- AWS (Region, S3 bucket, CloudFront)
- CORS origins
- Feature flags
- Environment (dev/staging/production)

## Database Schema

8 tables with proper relationships:
- users (JSONB preferences, quiz responses)
- products (array fields for images/sizes)
- brands (enum tier)
- retailers (enum affiliate network)
- swipe_events (partitioning-ready)
- dresser_drawers
- dresser_items (unique constraint)
- refresh_tokens (revocation tracking)

## Docker Deployment

Complete local development stack:
- PostgreSQL 16 with persistent volume
- Redis 7 with persistent volume
- Elasticsearch 8 (optional)
- FastAPI service with auto-reload
- Health checks and networking

## Production Ready

- Type hints throughout
- Docstrings on all functions
- Async/await best practices
- Error handling and validation
- Security (CORS, rate limiting, token revocation)
- Database migrations (Alembic)
- Comprehensive README
- Multi-stage Docker build
- Environment-based configuration
- Code organized in logical modules

## Quick Start

```bash
# With Docker
docker-compose up -d
docker-compose exec api alembic upgrade head

# Manual
cp .env.example .env
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload

# Access
# API: http://localhost:8000
# Docs: http://localhost:8000/docs
```

## Next Steps

1. Update `.env` with actual credentials
2. Customize the onboarding quiz in `/api/v1/endpoints/onboarding.py`
3. Integrate with actual product data sources
4. Implement Elasticsearch indexing
5. Add analytics event tracking (Mixpanel)
6. Deploy to production (AWS ECS, Kubernetes, etc.)
7. Set up CI/CD pipeline
8. Configure monitoring (Sentry, DataDog)
