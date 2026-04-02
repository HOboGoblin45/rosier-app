# Rosier Deployment Guide

Complete end-to-end CI/CD and deployment automation for Rosier's iOS app, FastAPI backend, and marketing infrastructure.

## Quick Start

### For Developers: Deploy Code Changes

```bash
# Automatic deployment to staging
git commit -m "New feature"
git push origin develop
# → Tests run → Builds → Auto-deploys to staging

# Automatic deployment to production
git commit -m "Release v1.1.0"
git push origin main
# → Tests run → Builds → Database backup → Auto-deploys to production
```

### For Operations: Initial Setup

```bash
# 1. Configure AWS infrastructure
bash infra/deploy-to-aws.sh
# Creates: EC2, RDS, ElastiCache, Security Groups

# 2. Configure GitHub Secrets
cat infra/setup-github-secrets.md
# Set AWS keys, SSH keys, Apple credentials, etc.

# 3. Deploy to production
bash infra/deploy.sh production --init
# Deploys all services, runs migrations, configures SSL

# 4. Monitor deployment
tail -f /var/log/nginx/api.rosier.app.access.log
```

## What's New

### Files Created

| File | Purpose |
|------|---------|
| `.github/workflows/marketing.yml` | Deploy marketing stack (Listmonk, n8n, Mixpost, Plausible) |
| `.github/workflows/backend.yml` | Updated with EC2 SSH deployment |
| `infra/deploy.sh` | Unified deployment script for backend, marketing, SSL, migrations |
| `infra/nginx/nginx.conf` | Production Nginx config with SSL, rate limiting, routing |
| `infra/setup-github-secrets.md` | Complete GitHub Secrets configuration guide |
| `infra/CI_CD_DEPLOYMENT_GUIDE.md` | Comprehensive CI/CD and deployment documentation |
| `DEPLOYMENT.md` | This file |

### Updated Files

- `infra/docker/docker-compose-prod.yml` - Added Nginx service with proper volumes and resource limits

## Deployment Architecture

```
GitHub Repository
    ├── Push to develop
    │   └── Backend CI/CD workflow
    │       ├── Lint + Type Check
    │       ├── Unit Tests
    │       ├── Docker Build
    │       └── Deploy to Staging EC2
    │
    └── Push to main
        └── Backend CI/CD workflow
            ├── Lint + Type Check
            ├── Unit Tests
            ├── Docker Build
            └── Deploy to Production EC2
                ├── Database Backup
                ├── Database Migration
                └── Health Checks

iOS App
    └── Version tag (v1.0.0)
        └── iOS CI/CD workflow
            ├── Build for Simulator
            ├── Unit Tests
            ├── Snapshot Tests
            └── Upload to TestFlight
                └── (Manual) Submit to App Store

Manual Trigger
    └── Marketing Stack Deploy
        ├── Connect via SSH
        ├── Pull Docker images
        ├── Start services
        └── Health checks
```

## Service URLs

### Development (localhost)
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Listmonk: http://localhost:9000
- n8n: http://localhost:5678
- Mixpost: http://localhost:9001
- Plausible: http://localhost:8100

### Production (rosier.app)
- API: https://api.rosier.app
- Email: https://mail.rosier.app
- Automation: https://n8n.rosier.app
- Social: https://social.rosier.app
- Analytics: https://analytics.rosier.app

## Workflows

### iOS App (.github/workflows/ios.yml)

**Triggers:**
- Push to main/develop with ios/** changes
- Workflow dispatch (manual)
- Version tag creation (v*)

**Process:**
1. Build for iOS Simulator
2. Run unit tests
3. Run snapshot tests
4. Upload to TestFlight (on version tags)
5. Submit to App Store (manual dispatch)

**Secrets Required:**
- APPLE_DEVELOPER_ID
- IOS_CERTIFICATE_BASE64
- IOS_CERT_PASSWORD
- IOS_PROVISIONING_PROFILE_BASE64
- APP_STORE_CONNECT_KEY_ID
- APP_STORE_CONNECT_ISSUER_ID
- APP_STORE_CONNECT_PRIVATE_KEY

### Backend CI/CD (.github/workflows/backend.yml)

**Triggers:**
- Push to main/develop with backend/** changes
- Pull requests to develop

**Process:**
1. Lint (ruff, mypy)
2. Unit tests (pytest with coverage)
3. Docker build
4. Deploy to staging (develop branch)
5. Deploy to production (main branch)

**Staging Deployment:**
- SSH to staging EC2
- Pull latest code
- Restart services
- Health checks

**Production Deployment:**
- Database backup
- SSH to production EC2
- Pull latest code
- Restart services
- Run migrations
- Health checks

**Secrets Required:**
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- EC2_SSH_KEY
- DATABASE_URL
- REDIS_URL
- JWT_SECRET_KEY
- SECRET_KEY

### Marketing Stack (.github/workflows/marketing.yml)

**Triggers:**
- Manual workflow dispatch

**Process:**
1. Connect to EC2 via SSH
2. Pull latest code
3. Start Docker Compose for marketing services
4. Initialize databases
5. Health checks
6. Verify service availability

**Deployed Services:**
- Listmonk (Email marketing)
- n8n (Workflow automation)
- Mixpost (Social media scheduling)
- Plausible (Analytics)
- ClickHouse (Analytics database)

**Secrets Required:**
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- EC2_SSH_KEY

## Deployment Steps

### 1. Initial Infrastructure Setup (One-time)

```bash
# Create AWS infrastructure
bash infra/deploy-to-aws.sh

# This creates:
# - EC2 instance (t2.micro)
# - RDS PostgreSQL (db.t3.micro)
# - ElastiCache Redis (cache.t3.micro)
# - Security groups
# - SSH key pair

# Output: rosier-deployment-info.txt with credentials
```

### 2. Configure GitHub Secrets

```bash
# Review required secrets
cat infra/setup-github-secrets.md

# Set all secrets (use GitHub CLI or Web UI)
# Required for all workflows:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - EC2_SSH_KEY

# Required for iOS workflows:
# - APPLE_DEVELOPER_ID
# - IOS_CERTIFICATE_BASE64
# - IOS_CERT_PASSWORD
# - IOS_PROVISIONING_PROFILE_BASE64
# - APP_STORE_CONNECT_KEY_ID
# - APP_STORE_CONNECT_ISSUER_ID
# - APP_STORE_CONNECT_PRIVATE_KEY

# Required for backend deployment:
# - DATABASE_URL (from RDS)
# - REDIS_URL (from ElastiCache)
# - JWT_SECRET_KEY (generate: openssl rand -base64 32)
# - SECRET_KEY (generate: openssl rand -base64 32)
```

### 3. Initial Deployment

```bash
# Option A: Automatic deployment (recommended)
git push origin main
# GitHub Actions automatically deploys

# Option B: Manual deployment
ssh -i rosier-key.pem ec2-user@PUBLIC_IP
cd /home/ec2-user/rosier
git pull origin main
bash infra/deploy.sh production --init

# Option C: One-line deployment
bash infra/deploy.sh production --init --ssl
```

### 4. Verify Deployment

```bash
# Check services are running
curl https://api.rosier.app/health
curl https://mail.rosier.app
curl https://n8n.rosier.app

# SSH to EC2 and check logs
ssh -i rosier-key.pem ec2-user@PUBLIC_IP
docker-compose -f infra/docker/docker-compose-prod.yml ps
docker-compose -f infra/docker/docker-compose-prod.yml logs -f api
```

## Daily Operations

### Deploy a Code Change

```bash
# Feature branch workflow
git checkout -b feature/new-endpoint
# ... make changes ...
git commit -m "Add new endpoint"
git push origin feature/new-endpoint
# Create PR on GitHub

# Automated checks run (tests, lint, type check)
# Once approved and merged to develop:
git merge feature/new-endpoint

# Automatically deploys to staging
# Test on staging: https://api-staging.rosier.app

# When ready for production:
git merge develop main
git push origin main

# Automatically deploys to production!
```

### Deploy Marketing Stack

```bash
# Go to GitHub repository
# Actions → Marketing Stack Deploy → Run workflow

# Or via command line:
ssh -i rosier-key.pem ec2-user@PUBLIC_IP
cd /home/ec2-user/rosier
docker-compose -f marketing/docker-compose.marketing.yml up -d
```

### Monitor Deployment

```bash
# GitHub Actions logs
# Go to: GitHub repo → Actions → [Workflow name] → Latest run

# EC2 logs
ssh -i rosier-key.pem ec2-user@PUBLIC_IP
docker-compose -f infra/docker/docker-compose-prod.yml logs -f

# Nginx logs
tail -f /var/log/nginx/api.rosier.app.access.log
tail -f /var/log/nginx/api.rosier.app.error.log
```

### Rollback Deployment

```bash
# If there's a problem, rollback to previous version:

git revert HEAD
git push origin main

# OR manually on EC2:
ssh -i rosier-key.pem ec2-user@PUBLIC_IP
cd /home/ec2-user/rosier
git checkout HEAD~1
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# With database rollback:
docker-compose -f infra/docker/docker-compose-prod.yml exec api \
  psql $DATABASE_URL < /tmp/backup-TIMESTAMP.sql
```

## Production Checklist

Before going live:

- [ ] All GitHub Secrets configured (run: `gh secret list`)
- [ ] AWS infrastructure created (EC2, RDS, ElastiCache)
- [ ] .env file configured with production secrets
- [ ] SSL certificates generated (certbot)
- [ ] Database migrations tested
- [ ] Health checks passing (curl endpoints)
- [ ] Monitoring set up (CloudWatch, Sentry)
- [ ] Backups configured (RDS snapshots)
- [ ] DNS pointing to correct IP/domain
- [ ] SSL renewal automation enabled

## Troubleshooting

### Deployment fails in GitHub Actions

**Check logs:**
1. Go to GitHub repo → Actions
2. Click failed workflow run
3. Review error output
4. Check GitHub Secrets are correct

**Common errors:**
- `Secrets not found` - Check secret names are exact (case-sensitive)
- `SSH connection timeout` - Check EC2 security group allows SSH
- `Database migration failed` - Check DATABASE_URL is correct

### Services not starting

```bash
# SSH to EC2
ssh -i rosier-key.pem ec2-user@PUBLIC_IP

# Check containers
docker ps

# View logs
docker logs rosier-api
docker logs rosier-nginx

# Check environment variables
docker-compose -f infra/docker/docker-compose-prod.yml exec api env

# Check disk space
df -h

# Check memory
free -h
```

### Nginx not routing traffic

```bash
# Test Nginx config
sudo nginx -t

# View Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Reload Nginx
sudo systemctl reload nginx
```

## Documentation

For detailed information:

- **GitHub Secrets Setup:** See `infra/setup-github-secrets.md`
- **CI/CD Pipeline Details:** See `infra/CI_CD_DEPLOYMENT_GUIDE.md`
- **Nginx Configuration:** See `infra/nginx/nginx.conf` (comments)
- **Docker Compose:** See `infra/docker/docker-compose-prod.yml` (comments)
- **Deployment Script:** See `infra/deploy.sh` (comments and functions)

## Support

### Debug Commands

```bash
# View all services
docker-compose -f infra/docker/docker-compose-prod.yml ps

# View service logs
docker-compose -f infra/docker/docker-compose-prod.yml logs SERVICE_NAME

# Execute commands in container
docker-compose -f infra/docker/docker-compose-prod.yml exec api bash

# Check resource usage
docker stats

# View database status
docker-compose -f infra/docker/docker-compose-prod.yml exec api \
  psql $DATABASE_URL -c "SELECT version();"

# Check Redis connection
docker-compose -f infra/docker/docker-compose-prod.yml exec api \
  redis-cli -u $REDIS_URL ping
```

### Key Contacts

- **Infrastructure:** DevOps team
- **iOS Releases:** Charlie (Founder)
- **Database Issues:** Backend team
- **Marketing Stack:** Marketing team

## Next Steps

1. Review `infra/setup-github-secrets.md` for GitHub Secrets setup
2. Review `infra/CI_CD_DEPLOYMENT_GUIDE.md` for detailed documentation
3. Run `infra/deploy-to-aws.sh` to create AWS infrastructure
4. Configure GitHub Secrets
5. Test deployment: `git push origin develop`
6. Monitor: GitHub Actions → Backend CI/CD
7. Verify services running: `curl https://api.rosier.app/health`

---

**Last Updated:** April 1, 2026
**Created for:** Rosier Fashion App
**Status:** Production-ready
