# Rosier

**Swipe-based niche fashion discovery for iOS.**

Rosier aggregates inventory from curated, culture-forward retailers and uses machine learning to build a personalized style model with every swipe. Think Tinder for fashion — but with taste.

## Repository Structure

```
rosier/
├── ios/                    # Native iOS app (Swift/SwiftUI)
│   └── Rosier/
│       ├── Sources/        # App source code (MVVM + Coordinators)
│       └── Tests/          # Unit and UI tests
├── backend/                # Python API + ML services
│   ├── app/                # FastAPI application
│   │   ├── api/            # API routes (v1)
│   │   ├── core/           # Config, security, database
│   │   ├── models/         # SQLAlchemy ORM models
│   │   ├── schemas/        # Pydantic request/response schemas
│   │   ├── services/       # Business logic
│   │   ├── ml/             # Recommendation engine
│   │   └── tasks/          # Background tasks (ingestion, price monitoring)
│   ├── tests/              # pytest test suite
│   └── migrations/         # Alembic database migrations
├── infra/                  # Infrastructure as code
│   ├── terraform/          # AWS provisioning
│   └── docker/             # Docker configurations
├── docs/                   # Documentation
└── .github/workflows/      # CI/CD pipelines
```

## Tech Stack

- **iOS:** Swift 5.9+ / SwiftUI / UIKit (iOS 17+)
- **Backend:** Python 3.12 / FastAPI / SQLAlchemy
- **Database:** PostgreSQL 16 + Redis 7 + Elasticsearch 8
- **ML:** FashionCLIP, LightGBM, scikit-learn
- **Infrastructure:** AWS (ECS Fargate, RDS, ElastiCache, S3, CloudFront)
- **CI/CD:** GitHub Actions + Fastlane (iOS)

## Getting Started

### Backend (Local Development)

```bash
cd backend
docker compose up -d          # Start Postgres, Redis, Elasticsearch
cp .env.example .env          # Configure environment
pip install -r requirements.txt
alembic upgrade head          # Run migrations
uvicorn app.main:app --reload # Start API server
```

### iOS

Open `ios/Rosier/Rosier.xcodeproj` in Xcode 16+ and build.

## Team

Confidential — Seed Stage — $2M Funded
