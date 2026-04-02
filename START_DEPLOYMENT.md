# START HERE: Rosier CI/CD Deployment Guide

Welcome! This document guides you through finalizing the CI/CD pipeline and deploying Rosier to production.

## What's New (April 2026)

Complete end-to-end CI/CD pipeline has been implemented and is ready for production use.

### New Files (8 total)

1. **GitHub Actions Workflows**
   - `.github/workflows/marketing.yml` - Deploy marketing stack
   - `.github/workflows/backend.yml` - Updated with EC2 deployment

2. **Infrastructure & Deployment**
   - `infra/deploy.sh` - Unified deployment script
   - `infra/nginx/nginx.conf` - Production Nginx config

3. **Configuration & Secrets**
   - `infra/setup-github-secrets.md` - Complete secrets guide

4. **Documentation**
   - `DEPLOYMENT.md` - Quick reference guide
   - `infra/CI_CD_DEPLOYMENT_GUIDE.md` - Technical documentation
   - `CI_CD_IMPLEMENTATION.md` - Implementation summary

## Quick Start (30 minutes to production)

### Phase 1: Prepare (5 minutes)
```bash
# 1. Read the quick reference
cat DEPLOYMENT.md

# 2. Review secrets requirements
cat infra/setup-github-secrets.md
```

### Phase 2: Infrastructure (10 minutes)
```bash
# 3. Create AWS infrastructure (one-time only)
bash infra/deploy-to-aws.sh

# Saves credentials to: rosier-deployment-info.txt
```

### Phase 3: Configure (10 minutes)
```bash
# 4. Configure GitHub Secrets
# Go to: GitHub repo → Settings → Secrets and variables → Actions
# Add all secrets from infra/setup-github-secrets.md

# Or use GitHub CLI:
gh secret set AWS_ACCESS_KEY_ID --body "YOUR_KEY"
gh secret set AWS_SECRET_ACCESS_KEY --body "YOUR_SECRET"
gh secret set EC2_SSH_KEY --body "$(cat rosier-key.pem)"
# ... repeat for all secrets
```

### Phase 4: Deploy (5 minutes)
```bash
# 5. Deploy to production
git push origin main

# GitHub Actions automatically:
# - Runs tests
# - Builds Docker image
# - Backs up database
# - Deploys to EC2
# - Runs migrations
# - Verifies health

# Or manually:
bash infra/deploy.sh production --init
```

## Documentation Map

| Document | Purpose | Read Time |
|----------|---------|-----------|
| **DEPLOYMENT.md** | Quick reference, daily ops | 5 min |
| **infra/setup-github-secrets.md** | GitHub Secrets configuration | 10 min |
| **infra/CI_CD_DEPLOYMENT_GUIDE.md** | Technical deep-dive, troubleshooting | 20 min |
| **CI_CD_IMPLEMENTATION.md** | Implementation summary | 5 min |
| **START_DEPLOYMENT.md** | This file | 2 min |

## File Reference

### GitHub Actions
- `.github/workflows/ios.yml` - iOS builds & App Store releases
- `.github/workflows/backend.yml` - API tests, builds & deployment
- `.github/workflows/marketing.yml` - Marketing stack deployment

### Configuration
- `infra/nginx/nginx.conf` - Production Nginx reverse proxy
- `infra/docker/docker-compose-prod.yml` - Updated with Nginx service
- `.env` - Environment variables (create from template)

### Deployment
- `infra/deploy.sh` - Main deployment script (executable)
- `infra/deploy-to-aws.sh` - AWS infrastructure setup
- `infra/one_click_deploy.sh` - Alternative automated deployment

## Deployment Flow

### Automatic (Git Push)
```
Developer commits
    ↓
git push origin develop  →  Auto-deploy to Staging EC2
                or
git push origin main     →  Auto-deploy to Production EC2
                            (with DB backup & migrations)
```

### Manual (GitHub Actions UI)
```
GitHub repo → Actions → [Workflow Name] → Run workflow
```

### Manual (SSH Script)
```
ssh -i rosier-key.pem ec2-user@IP
cd /home/ec2-user/rosier
bash infra/deploy.sh production --init
```

## Services & URLs

### Development (localhost)
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Email: http://localhost:9000
- Automation: http://localhost:5678
- Social: http://localhost:9001
- Analytics: http://localhost:8100

### Production
- API: https://api.rosier.app
- Email: https://mail.rosier.app
- Automation: https://n8n.rosier.app
- Social: https://social.rosier.app
- Analytics: https://analytics.rosier.app

## Critical Secrets Required

All of these MUST be set in GitHub before deployment:

### AWS (for all workflows)
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### EC2 SSH (for backend & marketing deployment)
- `EC2_SSH_KEY` (full PEM file)
- `EC2_HOST` (IP address, optional)

### Backend Database (required for API deployment)
- `DATABASE_URL` (RDS endpoint)
- `REDIS_URL` (ElastiCache endpoint)
- `JWT_SECRET_KEY` (32+ char random string)
- `SECRET_KEY` (32+ char random string)

### iOS Release (for App Store)
- `APPLE_DEVELOPER_ID`
- `IOS_CERTIFICATE_BASE64`
- `IOS_CERT_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

**Full list:** See `infra/setup-github-secrets.md`

## Before First Deployment

- [ ] **AWS Infrastructure**
  - [ ] Run `infra/deploy-to-aws.sh`
  - [ ] Save `rosier-deployment-info.txt`
  - [ ] Verify EC2, RDS, ElastiCache are running

- [ ] **GitHub Secrets**
  - [ ] Set all required secrets
  - [ ] Run `gh secret list` to verify
  - [ ] Test SSH key connection locally

- [ ] **Code & Configuration**
  - [ ] Create `.env` file with production values
  - [ ] Update `DATABASE_URL` with RDS endpoint
  - [ ] Update `REDIS_URL` with ElastiCache endpoint
  - [ ] Test Docker Compose locally: `docker-compose -f infra/docker/docker-compose-prod.yml up -d`

- [ ] **SSL/TLS**
  - [ ] Request certificates: `sudo certbot certonly --standalone -d api.rosier.app -d rosier.app`
  - [ ] Configure auto-renewal: `sudo systemctl enable certbot-renew.timer`

- [ ] **Database**
  - [ ] Verify PostgreSQL version 16+
  - [ ] Test connection: `psql $DATABASE_URL -c "SELECT version();"`
  - [ ] Configure backups (RDS automated snapshots)

- [ ] **Monitoring**
  - [ ] Enable CloudWatch for RDS
  - [ ] Configure Sentry (optional)
  - [ ] Setup log aggregation

## Troubleshooting

### "Secrets not found" error
```bash
# Verify secrets are set
gh secret list

# Verify exact names (case-sensitive)
# Compare with: infra/setup-github-secrets.md
```

### SSH connection fails
```bash
# Test SSH key locally
ssh -i rosier-key.pem ec2-user@PUBLIC_IP

# If fails:
# 1. Check EC2 security group allows port 22
# 2. Verify EC2_SSH_KEY secret is correct PEM format
# 3. Confirm instance is running: aws ec2 describe-instances
```

### Deployment fails
```bash
# SSH to EC2 and check logs
ssh -i rosier-key.pem ec2-user@PUBLIC_IP
cd /home/ec2-user/rosier

# View recent logs
docker-compose -f infra/docker/docker-compose-prod.yml logs -f api

# View GitHub Actions logs
# GitHub repo → Actions → [Failed workflow] → View full logs
```

### Services not responding
```bash
# Check all containers are running
docker ps

# Check service health
curl http://localhost:8000/health
curl http://localhost:9000
curl http://localhost:5678

# View logs
docker logs rosier-api
docker logs rosier-nginx
docker logs rosier-listmonk
```

## Workflow Details

### iOS Workflow (`.github/workflows/ios.yml`)
- **Trigger:** Push to main/develop with ios/** changes, or workflow dispatch
- **Steps:** Build → Test → Screenshots → Upload to TestFlight/App Store
- **Status:** Already configured and working

### Backend Workflow (`.github/workflows/backend.yml`)
- **Trigger:** Push to main/develop with backend/** changes
- **Steps:** Lint → Test → Build → Deploy to Staging/Production
- **New:** Auto-deploys to EC2 via SSH
- **Status:** Ready for production

### Marketing Workflow (`.github/workflows/marketing.yml`)
- **Trigger:** Manual workflow dispatch from GitHub Actions
- **Steps:** Connect to EC2 → Deploy Listmonk, n8n, Mixpost, Plausible
- **Status:** Ready to use
- **How to deploy:** GitHub repo → Actions → Marketing Stack Deploy → Run workflow

## Success Criteria

After deployment, verify:

```bash
# 1. API is responding
curl https://api.rosier.app/health
# Expected: {"status":"ok"}

# 2. Database is accessible
curl https://api.rosier.app/api/health/db
# Expected: Database connection successful

# 3. Services are running
ssh -i rosier-key.pem ec2-user@IP
docker ps
# Expected: rosier-api, rosier-nginx, all marketing services running

# 4. Logs are healthy
docker logs rosier-api
# Expected: No errors, API listening on port 8000

# 5. Nginx is routing correctly
curl -I https://api.rosier.app/health
# Expected: HTTP/2 200
```

## Daily Operations

### Deploy code changes
```bash
git commit -m "Feature: new endpoint"
git push origin develop  # Deploy to staging
# Test on staging...
git push origin main     # Deploy to production
```

### View deployment status
```bash
# GitHub Actions UI
# repo → Actions → Backend CI/CD → Latest run

# Or command line
gh run list --workflow backend.yml
gh run view RUN_ID
```

### Check service health
```bash
ssh -i rosier-key.pem ec2-user@IP
docker-compose -f infra/docker/docker-compose-prod.yml ps
docker stats
```

### View logs
```bash
ssh -i rosier-key.pem ec2-user@IP
docker-compose -f infra/docker/docker-compose-prod.yml logs -f api
tail -f /var/log/nginx/api.rosier.app.access.log
```

### Rollback deployment
```bash
# If something breaks:
git revert HEAD
git push origin main

# Or manually on EC2:
ssh -i rosier-key.pem ec2-user@IP
cd /home/ec2-user/rosier
git checkout HEAD~1
docker-compose -f infra/docker/docker-compose-prod.yml up -d
```

## Next Steps

1. **Right now:** Read `DEPLOYMENT.md` (5 min)
2. **Next:** Setup GitHub Secrets using `infra/setup-github-secrets.md` (10 min)
3. **Then:** Run `infra/deploy-to-aws.sh` (15 min)
4. **Finally:** Push to main branch to trigger deployment (5 min)
5. **Verify:** Check services are running and healthy

## Support

For detailed information, see:
- **Quick Reference:** `DEPLOYMENT.md`
- **GitHub Secrets:** `infra/setup-github-secrets.md`
- **Technical Details:** `infra/CI_CD_DEPLOYMENT_GUIDE.md`
- **Nginx Config:** `infra/nginx/nginx.conf` (comments included)
- **Deploy Script:** `infra/deploy.sh` (comments included)

## Summary

You now have:

✓ Automated CI/CD pipelines for iOS, Backend, and Marketing
✓ End-to-end deployment automation
✓ Production-grade Nginx reverse proxy
✓ Database migrations and backups
✓ Health checks and monitoring
✓ Comprehensive documentation
✓ Easy rollback procedures

Everything is ready for production deployment. Push code to main branch and watch the magic happen!

---

**Start:** Read `DEPLOYMENT.md` →  Setup Secrets → Deploy AWS → Push Code → Done!

**Time to Production:** ~30 minutes for initial setup, then instant on every push.

**Questions?** Check the troubleshooting section or review the detailed documentation files.
