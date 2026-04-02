# Rosier Backend API

Production-ready FastAPI backend for Rosier, a swipe-based niche fashion discovery app.

## Tech Stack

- **Framework**: FastAPI 0.109+
- **Database**: PostgreSQL 16 with async SQLAlchemy 2.0
- **Cache**: Redis 7
- **Search**: Elasticsearch 8 (optional)
- **Authentication**: JWT with RS256, Apple Sign-In
- **Async**: Python 3.12+, asyncpg, aioredis

## Project Structure

```
backend/
├── app/
│   ├── api/v1/endpoints/          # API route handlers
│   │   ├── auth.py                # Authentication endpoints
│   │   ├── cards.py               # Card feed endpoints
│   │   ├── dresser.py             # Dresser/closet endpoints
│   │   ├── onboarding.py          # Onboarding endpoints
│   │   ├── products.py            # Product detail endpoints
│   │   └── profile.py             # User profile endpoints
│   ├── core/                       # Core configuration
│   │   ├── config.py              # Pydantic Settings
│   │   ├── database.py            # SQLAlchemy async setup
│   │   ├── redis.py               # Redis client
│   │   └── security.py            # JWT, passwords, Apple Sign-In
│   ├── middleware/                # Custom middleware
│   │   └── rate_limiter.py        # Redis-based rate limiting
│   ├── models/                    # SQLAlchemy ORM models
│   │   ├── user.py
│   │   ├── product.py
│   │   ├── brand.py
│   │   ├── retailer.py
│   │   ├── swipe_event.py
│   │   ├── dresser.py
│   │   └── refresh_token.py
│   ├── schemas/                   # Pydantic request/response schemas
│   │   ├── auth.py
│   │   ├── user.py
│   │   ├── product.py
│   │   ├── swipe_event.py
│   │   ├── dresser.py
│   │   └── style_dna.py
│   ├── services/                  # Business logic services
│   │   ├── card_queue.py          # Card queue generation
│   │   ├── recommendation.py      # Recommendation engine (Phase 1)
│   │   ├── price_monitor.py       # Price tracking
│   │   └── affiliate.py           # Affiliate link construction
│   └── main.py                    # FastAPI application factory
├── migrations/                    # Alembic database migrations
├── requirements.txt               # Python dependencies
├── .env.example                   # Environment variables example
├── Dockerfile                     # Docker build configuration
├── docker-compose.yml             # Local development stack
└── README.md                      # This file
```

## Setup & Installation

### Using Docker (Recommended)

```bash
# Start all services (PostgreSQL, Redis, Elasticsearch, API)
docker-compose up -d

# Run database migrations
docker-compose exec api alembic upgrade head

# API available at http://localhost:8000
```

### Manual Setup

#### Prerequisites
- Python 3.12+
- PostgreSQL 16
- Redis 7
- Elasticsearch 8 (optional)

#### Installation

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Update .env with your configuration
# Edit .env and update:
# - DATABASE_URL
# - REDIS_URL
# - JWT_SECRET_KEY
# - Apple Sign-In credentials
# - AWS credentials
```

#### Run Migrations

```bash
alembic upgrade head
```

#### Start Development Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server available at http://localhost:8000

## API Documentation

Interactive API documentation available at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## API Endpoints

### Authentication
- `POST /api/v1/auth/apple` - Apple Sign-In
- `POST /api/v1/auth/email/register` - Email registration
- `POST /api/v1/auth/email/login` - Email login
- `POST /api/v1/auth/refresh` - Refresh access token
- `DELETE /api/v1/auth/account` - Delete account

### Onboarding
- `POST /api/v1/onboarding/quiz` - Submit onboarding quiz
- `GET /api/v1/onboarding/status` - Get onboarding status

### Card Feed
- `GET /api/v1/cards/next` - Get next N cards
- `POST /api/v1/cards/events` - Submit batch swipe events
- `GET /api/v1/cards/events` - Get swipe event history
- `DELETE /api/v1/cards/queue` - Clear card queue

### Dresser (Closet)
- `GET /api/v1/dresser` - Get complete dresser
- `POST /api/v1/dresser/drawers` - Create drawer
- `PUT /api/v1/dresser/drawers/{id}` - Update drawer
- `DELETE /api/v1/dresser/drawers/{id}` - Delete drawer
- `POST /api/v1/dresser/items` - Add item
- `DELETE /api/v1/dresser/items/{id}` - Remove item
- `PUT /api/v1/dresser/items/{id}/move` - Move item
- `GET /api/v1/dresser/share/{drawer_id}` - Get shared drawer

### Products
- `GET /api/v1/products/{id}` - Get product details
- `GET /api/v1/products/{id}/similar` - Get similar products
- `GET /api/v1/products/{id}/affiliate_link` - Get affiliate link

### Profile
- `GET /api/v1/profile` - Get user profile
- `PUT /api/v1/profile` - Update profile
- `PUT /api/v1/profile/settings` - Update settings
- `GET /api/v1/profile/style_dna` - Get Style DNA profile
- `POST /api/v1/profile/style_dna/share` - Share Style DNA

## Authentication

### JWT Access Token

Include in request headers:
```
Authorization: Bearer <access_token>
```

Token expiry: 15 minutes (configurable)

### Refresh Token

Exchange expired access token:
```bash
POST /api/v1/auth/refresh
{
  "refresh_token": "<refresh_token>"
}
```

## Database Schema

### Tables

- **users** - User accounts (email, Apple ID, settings)
- **products** - Fashion products with pricing and metadata
- **brands** - Brand information (tier, aesthetics, price range)
- **retailers** - Retail partners (affiliate networks, feeds)
- **swipe_events** - User interaction data (likes, rejects, views)
- **dresser_drawers** - User's closet organization
- **dresser_items** - Saved products in drawers
- **refresh_tokens** - Token revocation tracking

### Indexes

Optimized indexes on:
- User queries (id, email, apple_id, created_at)
- Product queries (category, brand, retailer, is_active)
- Swipe analytics (user_id, product_id, action, created_at)
- Performance critical paths

## Card Queue Algorithm

### Phase 1 Implementation

Tag-based scoring system:

```
Score = BaseScore(50) +
         PriceScore(0-20) +
         CategoryMatch(15) +
         SubcategoryMatch(10) +
         TagWeightMatch(0-100) +
         SaleBoost(5)
```

### Diversity Rules

- Max 2 products from same brand per 20 cards
- Max 3 products from same retailer
- 10% exploration cards (random selection)

### Caching

- Redis TTL: 1 hour
- Regenerates on expiry or manual clear

## Rate Limiting

Configured per endpoint:

- `/cards/next`: 60 req/min
- `/cards/events`: 30 req/min
- `/auth/*`: 10 req/min

Returns `429 Too Many Requests` when exceeded.

## Error Handling

### Standard Error Responses

```json
{
  "detail": "Error message"
}
```

### HTTP Status Codes

- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Permission denied
- `404 Not Found` - Resource not found
- `409 Conflict` - Duplicate resource
- `422 Unprocessable Entity` - Validation error
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

## Environment Configuration

See `.env.example` for all configuration options:

```env
# Core
APP_NAME=Rosier
ENVIRONMENT=development

# Database
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/rosier

# Redis
REDIS_URL=redis://localhost:6379/0

# Security
JWT_SECRET_KEY=your-secret-key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=30

# Apple Sign-In
APPLE_TEAM_ID=...
APPLE_KEY_ID=...
APPLE_PRIVATE_KEY=...
APPLE_APP_ID=com.rosierapp.ios

# AWS
AWS_REGION=us-east-1
S3_BUCKET=rosier-assets
CLOUDFRONT_DOMAIN=https://assets.rosierapp.com
```

## Development

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio pytest-cov httpx

# Run all tests
pytest

# With coverage
pytest --cov=app
```

### Code Style

Uses PEP 8 with type hints throughout.

```bash
# Format code
black app

# Lint
flake8 app

# Type check
mypy app
```

### Database Migrations

```bash
# Create migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

## Deployment

### Production Checklist

- [ ] Update `JWT_SECRET_KEY` with strong random value
- [ ] Set `ENVIRONMENT=production`
- [ ] Configure CORS_ORIGINS with production domains
- [ ] Enable HTTPS only
- [ ] Set up PostgreSQL backups
- [ ] Configure Redis persistence
- [ ] Set up monitoring (Sentry, DataDog, New Relic)
- [ ] Configure error logging
- [ ] Scale database connections
- [ ] Enable query logging and analysis
- [ ] Set up CI/CD pipeline
- [ ] Configure rate limiting thresholds

### Docker Deployment

```bash
# Build image
docker build -t rosier-api:latest .

# Run container
docker run -d \
  --name rosier-api \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://... \
  -e REDIS_URL=redis://... \
  rosier-api:latest
```

### Kubernetes (Example)

See `k8s/` directory for Kubernetes manifests (deployment, service, configmap, secrets).

## Monitoring & Logging

### Health Check

```bash
curl http://localhost:8000/health
```

### Metrics

Prometheus metrics available at `/metrics` (when enabled).

### Logging

Structured logging to stdout/stderr. Configure log level in `.env`:

```env
LOG_LEVEL=INFO
```

## Support & Documentation

- API Docs: http://localhost:8000/docs
- Code Documentation: See docstrings in source
- Database Schema: See `app/models/`
- Error Messages: Detailed validation errors in responses

## License

Proprietary - Rosier Fashion Inc.

## Contributing

See CONTRIBUTING.md for guidelines.
# Backend CI/CD validated

