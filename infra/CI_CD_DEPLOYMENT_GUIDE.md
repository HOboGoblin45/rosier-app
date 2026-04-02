# Rosier CI/CD & Deployment Guide

Complete guide for Rosier's end-to-end CI/CD pipeline and production deployment.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [GitHub Actions Workflows](#github-actions-workflows)
4. [GitHub Secrets Setup](#github-secrets-setup)
5. [Deployment Methods](#deployment-methods)
6. [Production Deployment](#production-deployment)
7. [Monitoring & Rollback](#monitoring--rollback)
8. [Troubleshooting](#troubleshooting)

## Overview

Rosier has a complete CI/CD pipeline that automates:

- **iOS App:** Building, testing, and releasing to TestFlight and App Store
- **Backend API:** Testing, building Docker images, and deploying to EC2
- **Marketing Stack:** Deploying Listmonk, n8n, Mixpost, and Plausible services
- **Infrastructure:** Database migrations, SSL setup, and Nginx configuration

All workflows are triggered automatically on git push or can be triggered manually.

## Architecture

### Services & Deployment Targets

```
┌─────────────────────────────────────────────────────────┐
│                   GitHub Repository                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │         .github/workflows/                        │   │
│  │  • ios.yml          - iOS builds & releases      │   │
│  │  • backend.yml      - API testing & deployment   │   │
│  │  • marketing.yml    - Marketing stack deploy     │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
         │                    │                      │
         ▼                    ▼                      ▼
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │   App Store  │    │     ECR      │    │     EC2      │
  │   TestFlight │    │  Docker Hub  │    │ (Production) │
  │              │    │              │    │              │
  │ iOS App 17.0 │    │ Backend API  │    │ Backend API  │
  └──────────────┘    └──────────────┘    │ Marketing    │
                                           │ Nginx        │
                                           └──────────────┘
```

### Environment Setup

```
Development  →  Staging (develop branch)  →  Production (main branch)
     ↓                     ↓                          ↓
  Local Dev          Staging EC2                Prod EC2
  docker-compose     Auto-deploy           Manual approval
```

## GitHub Actions Workflows

### 1. iOS CI/CD (.github/workflows/ios.yml)

Builds and releases the iOS app.

**Trigger Conditions:**
- Push to `main` or `develop` branches (paths: `ios/**`)
- Manual workflow dispatch with build type selection

**Jobs:**
1. **build-and-test** - Compiles for simulator, runs unit tests
2. **snapshot-tests** - Runs snapshot tests for UI changes
3. **deploy-testflight** - Uploads to TestFlight on version tags
4. **deploy-app-store** - Submits to App Store on manual trigger

**How to Release iOS App:**

```bash
# 1. Update version in ios/Rosier/Sources/App/BUILD_SETTINGS.xcconfig
# 2. Create and push tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 3. Automatically triggers TestFlight upload
# 4. To release to App Store, manually trigger workflow with build_type=appstore
```

### 2. Backend CI/CD (.github/workflows/backend.yml)

Tests and deploys the FastAPI backend.

**Trigger Conditions:**
- Push to `main` or `develop` branches (paths: `backend/**`)
- Pull requests to `develop`

**Jobs:**
1. **lint** - Python linting with ruff and mypy type checking
2. **test** - Unit tests with pytest, coverage reports
3. **build** - Docker image build with layer caching
4. **deploy-staging** - Deploys to staging EC2 on develop push
5. **deploy-production** - Deploys to production EC2 on main push

**Automatic Deployment Flow:**

```
develop branch pushed
    ↓
[Lint + Type Check] → [Unit Tests] → [Docker Build]
    ↓
    └─→ [Deploy to Staging EC2]
            ↓
            Database migrations
            Health checks
            Smoke tests

main branch pushed
    ↓
[Lint + Type Check] → [Unit Tests] → [Docker Build]
    ↓
    └─→ [Deploy to Production EC2]
            ↓
            Database backup
            Database migrations
            Health checks
            Smoke tests
```

### 3. Marketing Stack (.github/workflows/marketing.yml)

Deploys marketing infrastructure.

**Trigger Conditions:**
- Manual workflow dispatch (workflow_dispatch)
- Can target staging or production

**Process:**
1. Connects to EC2 via SSH
2. Pulls latest code
3. Starts Docker Compose for marketing services
4. Waits for service health checks
5. Verifies service availability

**How to Deploy Marketing Stack:**

```bash
# Go to GitHub repo Actions → Marketing Stack Deploy
# Click "Run workflow"
# Select environment (production or staging)
# Confirm

# Services will be available at:
# - mail.rosier.app           (Listmonk)
# - n8n.rosier.app            (n8n automation)
# - social.rosier.app         (Mixpost)
# - analytics.rosier.app      (Plausible)
```

## GitHub Secrets Setup

All CI/CD workflows require GitHub Secrets to be configured.

### Quick Setup

```bash
# 1. Install GitHub CLI: https://cli.github.com
# 2. Navigate to repository
# 3. Run: gh secret set SECRET_NAME --body "value"

# AWS Credentials
gh secret set AWS_ACCESS_KEY_ID --body "AKIA..."
gh secret set AWS_SECRET_ACCESS_KEY --body "wJalr..."

# EC2 SSH Access
gh secret set EC2_SSH_KEY --body "$(cat /path/to/rosier-key.pem)"
gh secret set EC2_HOST --body "12.34.56.78"

# See infra/setup-github-secrets.md for complete list
```

### Required Secrets by Workflow

| Workflow | Required Secrets |
|----------|-----------------|
| **ios.yml** | APPLE_DEVELOPER_ID, IOS_CERTIFICATE_BASE64, IOS_CERT_PASSWORD, IOS_PROVISIONING_PROFILE_BASE64, APP_STORE_CONNECT_* |
| **backend.yml** | AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, EC2_SSH_KEY, DATABASE_URL, REDIS_URL, JWT_SECRET_KEY |
| **marketing.yml** | AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, EC2_SSH_KEY |

**Full Setup Instructions:** See `infra/setup-github-secrets.md`

## Deployment Methods

### Method 1: Automatic (Git Push) - Recommended

Push code to trigger automatic deployment:

```bash
# Deploy to staging (automatic)
git commit -m "Update API endpoints"
git push origin develop

# Automatic workflow:
# 1. Runs tests
# 2. Builds Docker image
# 3. Deploys to staging EC2
# 4. Runs health checks

# Deploy to production (automatic)
git commit -m "Release v1.1.0"
git push origin main

# Automatic workflow:
# 1. Runs all tests
# 2. Builds Docker image
# 3. Backs up database
# 4. Deploys to production EC2
# 5. Runs migrations
# 6. Runs health checks
```

### Method 2: Manual GitHub Actions Trigger

Trigger workflows manually from GitHub UI:

```bash
# Go to: GitHub repo → Actions → [Workflow Name] → Run workflow

# iOS App Release to App Store
# 1. Click "Deploy to App Store"
# 2. Confirm
# 3. Workflow builds and submits app

# Marketing Stack Deploy
# 1. Click "Marketing Stack Deploy"
# 2. Select environment (staging/production)
# 3. Confirm
# 4. Services deploy via SSH
```

### Method 3: Manual SSH Deployment

Deploy directly to EC2:

```bash
# 1. SSH to EC2
ssh -i rosier-key.pem ec2-user@api.rosier.app

# 2. Navigate to repo
cd /home/ec2-user/rosier

# 3. Pull latest code
git pull origin main

# 4. Run deployment script
./infra/deploy.sh production --init

# Options:
# --init   Initialize database (migrations + seeds)
# --ssl    Configure SSL certificates
```

### Method 4: Docker Compose Commands

Direct Docker Compose commands:

```bash
# From EC2 instance or local machine with docker-compose

# Start all services
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# View logs
docker-compose -f infra/docker/docker-compose-prod.yml logs -f api

# Scale services
docker-compose -f infra/docker/docker-compose-prod.yml up -d --scale api=2

# Stop all services
docker-compose -f infra/docker/docker-compose-prod.yml down

# Remove volumes (destructive!)
docker-compose -f infra/docker/docker-compose-prod.yml down -v
```

## Production Deployment

### Prerequisites

Before first production deployment:

```bash
# 1. Infrastructure created (EC2, RDS, ElastiCache)
# See infra/deploy-to-aws.sh

# 2. GitHub Secrets configured
# See infra/setup-github-secrets.md

# 3. SSH key available
# Store EC2_SSH_KEY in GitHub Secrets

# 4. Environment variables set
# Create .env file in repository root
```

### Step-by-Step Production Deployment

**Option A: Automatic (Git Push)**

```bash
# 1. Commit and push to main
git add .
git commit -m "Release v1.1.0 - Bug fixes and new features"
git push origin main

# 2. GitHub Actions automatically:
#    - Runs all tests
#    - Builds Docker image
#    - Backs up database
#    - Deploys to EC2
#    - Runs migrations
#    - Verifies health

# 3. Monitor deployment
# Go to GitHub → Actions → Backend CI/CD → Latest run
# Watch logs in real-time

# 4. Verify deployment
# Test API: curl https://api.rosier.app/health
# Check logs: ssh into EC2 and run docker logs
```

**Option B: Manual Deployment Script**

```bash
# 1. SSH to EC2
ssh -i rosier-key.pem ec2-user@api.rosier.app

# 2. Pull latest code
cd /home/ec2-user/rosier
git pull origin main

# 3. Run deployment script
./infra/deploy.sh production --init

# 4. Script will:
#    - Check prerequisites
#    - Build and start backend
#    - Deploy marketing stack
#    - Run migrations
#    - Configure SSL/Nginx
#    - Run health checks
```

### Database Migrations

```bash
# Migrations run automatically during deployment
# But can also run manually:

# SSH to EC2
ssh -i rosier-key.pem ec2-user@api.rosier.app
cd /home/ec2-user/rosier

# Run migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head

# Rollback last migration
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic downgrade -1

# Check migration status
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic current
```

### SSL Configuration

```bash
# On EC2 instance (one-time setup):

# Install certbot
sudo yum install -y certbot

# Generate certificates for all domains
sudo certbot certonly --standalone \
  -d rosier.app \
  -d api.rosier.app \
  -d mail.rosier.app \
  -d social.rosier.app \
  -d analytics.rosier.app \
  -d n8n.rosier.app

# Auto-renewal (every 60 days)
sudo systemctl enable certbot-renew.timer
sudo systemctl start certbot-renew.timer

# Verify certificate renewal
sudo certbot renew --dry-run
```

### Health Checks

```bash
# Check all services
curl https://api.rosier.app/health
curl https://mail.rosier.app
curl https://n8n.rosier.app
curl https://social.rosier.app
curl https://analytics.rosier.app

# SSH health checks
ssh -i rosier-key.pem ec2-user@api.rosier.app

# View container status
docker ps
docker-compose -f infra/docker/docker-compose-prod.yml ps

# View logs
docker logs rosier-api
docker logs rosier-nginx
docker logs rosier-listmonk

# View resource usage
docker stats
```

## Monitoring & Rollback

### View Deployment Status

```bash
# GitHub Actions page
# https://github.com/YOUR_ORG/rosier/actions

# View specific workflow run
# Click on the latest run to see logs and status

# View deployment history
# Actions → Backend CI/CD → View all runs
```

### Monitoring

```bash
# SSH to EC2
ssh -i rosier-key.pem ec2-user@api.rosier.app

# View logs in real-time
docker-compose -f infra/docker/docker-compose-prod.yml logs -f api

# View Nginx logs
tail -f /var/log/nginx/api.rosier.app.access.log

# Monitor resource usage
watch docker stats

# View database connections
docker-compose -f infra/docker/docker-compose-prod.yml exec api \
  psql $DATABASE_URL -c "SELECT count(*) FROM pg_stat_activity;"
```

### Rollback Procedure

If deployment fails or has issues:

```bash
# Option 1: Rollback to previous commit
git revert HEAD
git push origin main
# Triggers automatic redeployment with previous version

# Option 2: Manually revert on EC2
ssh -i rosier-key.pem ec2-user@api.rosier.app
cd /home/ec2-user/rosier
git checkout HEAD~1
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Option 3: Use database backup
ssh -i rosier-key.pem ec2-user@api.rosier.app
cd /home/ec2-user/rosier

# List available backups
ls -la /tmp/backup-*.sql

# Restore from backup
docker-compose -f infra/docker/docker-compose-prod.yml exec api \
  psql $DATABASE_URL < /tmp/backup-TIMESTAMP.sql
```

## Troubleshooting

### Common Issues

**Deployment fails: "Secrets not found"**
- Ensure all required secrets are in GitHub Settings → Secrets
- Secret names are case-sensitive
- Verify secret is in correct repository

**SSH connection timeout**
- Check EC2 security group allows SSH (port 22)
- Verify EC2_SSH_KEY secret is correct
- Test: `ssh -i rosier-key.pem ec2-user@PUBLIC_IP`

**Database migration fails**
- Check database is running: `docker ps | grep postgres`
- View migration logs: `docker logs rosier-api`
- Manual rollback: `docker-compose exec api alembic downgrade -1`

**Services not starting**
- Check logs: `docker-compose logs -f`
- Verify environment variables: `docker-compose exec api env | grep DATABASE`
- Check disk space: `df -h`
- Check memory: `free -h`

**Health check fails**
- Check service is running: `docker ps`
- View logs: `docker logs SERVICE_NAME`
- Test endpoint: `curl http://localhost:8000/health`
- Check network: `docker network ls`

### Debug Commands

```bash
# SSH to EC2
ssh -i rosier-key.pem ec2-user@api.rosier.app

# Get into running container
docker-compose -f infra/docker/docker-compose-prod.yml exec api bash

# Check environment variables
docker-compose -f infra/docker/docker-compose-prod.yml exec api env

# Test database connection
docker-compose -f infra/docker/docker-compose-prod.yml exec api \
  psql $DATABASE_URL -c "SELECT version();"

# View Docker Compose configuration
docker-compose -f infra/docker/docker-compose-prod.yml config

# View service dependencies
docker-compose -f infra/docker/docker-compose-prod.yml ps --services

# Validate YAML syntax
docker-compose -f infra/docker/docker-compose-prod.yml config --quiet
```

### Performance Tuning

For t2.micro instances:

```bash
# Monitor resource usage
watch -n 1 'docker stats --no-stream'

# Adjust container limits in docker-compose-prod.yml
# Current: 800MB for API, 256MB for nginx

# If out of memory, reduce logging verbosity
docker-compose -f infra/docker/docker-compose-prod.yml exec api \
  sed -i 's/LOG_LEVEL=.*/LOG_LEVEL=warning/' .env

# Restart services
docker-compose -f infra/docker/docker-compose-prod.yml restart api
```

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Alembic (Database Migrations)](https://alembic.sqlalchemy.org/)

## Support

For issues or questions:
1. Check logs: `docker-compose logs -f`
2. Review GitHub Actions run logs
3. Check AWS CloudTrail for infrastructure issues
4. Contact DevOps team for infrastructure support
