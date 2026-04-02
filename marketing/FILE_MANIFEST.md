# Rosier Marketing Stack - File Manifest

**Created:** April 1, 2026
**Total Files:** 16 core files + supporting directories
**Total Size:** ~145 KB

## Core Docker Infrastructure

### docker-compose.marketing.yml (16 KB)
**Status:** ✓ Complete and production-ready
- Listmonk (email marketing) on port 9000
- n8n (workflow automation) on port 5678
- Mixpost (social scheduling) on port 9001
- Plausible (analytics) on port 8100
- PostgreSQL (shared database)
- Redis (cache/queue)
- ClickHouse (analytics DB)
- All health checks configured
- Resource limits for t2.micro EC2
- Proper networking and volumes

**Features:**
- Environment-based configuration
- Service dependencies
- Volume management
- Logging configuration
- Security groups
- Complete documentation in file

## Setup & Configuration

### setup.sh (13 KB)
**Status:** ✓ Executable and tested
- Docker installation check
- Directory creation
- Secure password generation (32+ chars)
- .env file auto-generation
- Service startup
- Health check polling
- Access URL printing
- Credential backup (.credentials)

**Usage:** `./setup.sh`

### .env.example (3 KB)
**Status:** ✓ Complete template
- All required environment variables
- SMTP configuration examples (Gmail, SendGrid, SES)
- Database credentials placeholders
- Service admin passwords
- API keys and tokens
- CORS origins
- Security settings

### scripts/init-marketing-db.sql (1 KB)
**Status:** ✓ Database initialization
- PostgreSQL user creation
- Database initialization for:
  - Listmonk
  - n8n
  - Mixpost
  - Plausible
- Proper permissions setup

## n8n Workflow Automation

### workflows/user_signup_flow.json (3 KB)
**Status:** ✓ Complete workflow
- Webhook trigger: `/webhook/user-signup`
- Payload: user_id, email, name, style_preferences
- Actions:
  1. Add user to Listmonk "Users" list
  2. Send welcome email
  3. Log event to Plausible analytics
- Error handling configured

### workflows/weekly_style_digest.json (5 KB)
**Status:** ✓ Complete workflow
- Cron trigger: Sunday 10am
- Calls Rosier API:
  - GET /api/v1/trending/brands
  - GET /api/v1/trending/products
- Email generation and sending
- Social media scheduling
- Analytics tracking

### workflows/referral_reward.json (6 KB)
**Status:** ✓ Complete workflow
- Webhook trigger: `/webhook/referral-success`
- Actions:
  1. Get referrer's total count from API
  2. Update Listmonk contact
  3. Send emails (referrer + referred)
  4. Check milestone (5, 10 referrals)
  5. Unlock in-app rewards
  6. Log analytics event

### workflows/daily_content_scheduler.json (4 KB)
**Status:** ✓ Complete workflow
- Cron trigger: Daily 8am
- Gets trending products from API
- Generates Instagram + TikTok captions
- Schedules posts to both platforms
- Logs engagement metrics

## Email Templates

### email_templates/welcome.html (4 KB)
**Status:** ✓ Production-ready
- Rosier branding (#1A1A2E, #C4A77D)
- Mobile-responsive
- Feature highlights
- Download CTA
- Style DNA explanation
- Social links
- Unsubscribe option

### email_templates/weekly_digest.html (6 KB)
**Status:** ✓ Production-ready
- Trending brands section
- Product cards with trending scores
- Responsive grid layout
- Product view CTAs
- Weekly insight highlight
- Invite friends CTA
- Preference management links

### email_templates/referral_invite.html (5 KB)
**Status:** ✓ Production-ready
- Personal message from referrer
- Feature benefits grid
- Unique referral code (highlighted)
- Reward information
- Download CTA
- Responsive design

### email_templates/sale_alert.html (4 KB)
**Status:** ✓ Production-ready
- Price comparison display
- Savings percentage
- Limited-time urgency
- Product description
- Quick buy CTA
- Preference management

### email_templates/reengagement.html (5 KB)
**Status:** ✓ Production-ready
- "We miss you" positioning
- What's new highlights
- Feature benefits list
- Special discount offer
- Dual CTA (open/unsubscribe)
- Responsive design

## Documentation

### DEPLOYMENT_GUIDE.md (8 KB)
**Status:** ✓ Complete
- Step-by-step deployment instructions
- Verification checklist
- SMTP configuration for 3 providers
- Service setup procedures
- Common commands
- Monitoring & alerts
- Troubleshooting guide
- Backup/recovery procedures
- Scaling considerations
- Security best practices

### INTEGRATION_GUIDE.md (12 KB)
**Status:** ✓ Complete
- Architecture overview
- Required webhook endpoints
  - User signup webhook
  - Referral success webhook
  - Conversion webhook (optional)
- n8n workflow requirements
- Data flow diagrams
- Required API endpoints
- Listmonk list setup
- Email campaign configuration
- Mixpost account setup
- Analytics & event tracking
- Error handling & retries
- Security & authentication
- Troubleshooting guide
- Maintenance schedule
- Future enhancements

### README.md (9.9 KB)
**Status:** ✓ Complete
- Quick start guide
- Service overview
- Directory structure
- Workflow descriptions
- Common tasks
- Email template customization
- Deployment notes
- Troubleshooting
- Cost breakdown
- Future enhancements
- License information

### FILE_MANIFEST.md (This file)
**Status:** ✓ Complete inventory

## Directory Structure

```
marketing/
├── docker-compose.marketing.yml     [16 KB] ✓
├── setup.sh                         [13 KB] ✓ (executable)
├── .env.example                     [3 KB]  ✓
├── DEPLOYMENT_GUIDE.md              [8 KB]  ✓
├── INTEGRATION_GUIDE.md             [12 KB] ✓
├── README.md                        [9.9 KB] ✓
├── FILE_MANIFEST.md                 [This file] ✓
│
├── scripts/
│   └── init-marketing-db.sql        [1 KB]  ✓
│
├── workflows/
│   ├── user_signup_flow.json        [3 KB]  ✓
│   ├── weekly_style_digest.json     [5 KB]  ✓
│   ├── referral_reward.json         [6 KB]  ✓
│   └── daily_content_scheduler.json [4 KB]  ✓
│
└── email_templates/
    ├── welcome.html                 [4 KB]  ✓
    ├── weekly_digest.html           [6 KB]  ✓
    ├── referral_invite.html         [5 KB]  ✓
    ├── sale_alert.html              [4 KB]  ✓
    └── reengagement.html            [5 KB]  ✓

(Auto-generated after setup.sh):
├── .env                             [credentials, do not commit]
└── .credentials                     [backup credentials, keep secure]
```

## Usage Instructions

### 1. Initial Setup
```bash
cd marketing/
./setup.sh
# Script will:
# - Generate secure credentials
# - Create .env file
# - Start all services
# - Print access URLs
```

### 2. Post-Setup Configuration
```bash
# Update SMTP in .env (Gmail/SendGrid/SES)
nano .env

# Restart Listmonk to apply SMTP changes
docker-compose -f docker-compose.marketing.yml restart listmonk

# Log into services and configure:
# - Listmonk: Create email lists and import templates
# - n8n: Import workflows
# - Mixpost: Connect social accounts
# - Plausible: Add website and tracking code
```

### 3. Connect Rosier Backend
See INTEGRATION_GUIDE.md for webhook implementations in backend code.

## Service Specifications

### Listmonk
- **Port:** 9000
- **Admin Path:** /admin
- **Database:** listmonk (PostgreSQL)
- **Memory:** 200-250MB
- **Default User:** admin (password in .env)

### n8n
- **Port:** 5678
- **Database:** n8n (PostgreSQL)
- **Memory:** 180-200MB
- **Volumes:** ~/.n8n/workflows (workflow storage)
- **Encryption Key:** N8N_ENCRYPTION_KEY (auto-generated)

### Mixpost
- **Port:** 9001
- **Database:** mixpost (PostgreSQL)
- **Cache:** Redis
- **Memory:** 150-180MB
- **Setup:** First login creates admin account

### Plausible
- **Port:** 8100
- **Database:** plausible (PostgreSQL)
- **Analytics DB:** ClickHouse
- **Memory:** 100-150MB
- **Admin Email:** admin@rosier.app

### PostgreSQL
- **Port:** 5432 (internal only)
- **Memory:** 150-200MB
- **Databases:** listmonk, n8n, mixpost, plausible

### Redis
- **Port:** 6379 (internal only)
- **Memory:** 50-100MB
- **Auth:** REDIS_PASSWORD (auto-generated)

## Resource Requirements

### Minimum Hardware
- **CPU:** 1 vCPU (t2.micro)
- **RAM:** 1 GB (800MB app, 200MB OS)
- **Disk:** 20 GB (Docker images + data)
- **Network:** 1 Mbps

### EC2 t2.micro Allocation
- Listmonk: 256MB
- n8n: 256MB
- Mixpost: 256MB
- Plausible: 192MB
- PostgreSQL: 256MB
- Redis: 128MB
- **Total:** ~1.3 GB (includes OS)

### Upgrade Path
- 10K users: t2.small (2GB RAM)
- 50K users: t2.medium (4GB RAM)
- 100K+ users: Split to multiple instances

## Security Features

- ✓ Auto-generated 32+ character passwords
- ✓ Environment-based configuration
- ✓ No hardcoded credentials
- ✓ n8n encryption key per instance
- ✓ Redis password protection
- ✓ PostgreSQL user isolation
- ✓ Internal Docker network (no exposed DB)
- ✓ Health check monitoring
- ✓ Logging configured
- ✓ Resource limits set

## Testing

### Docker Compose Validation
```bash
docker-compose -f docker-compose.marketing.yml config
# Output: YAML validation
```

### Service Health Check
```bash
# After running setup.sh:
curl http://localhost:9000/admin    # Listmonk
curl http://localhost:5678          # n8n
curl http://localhost:9001          # Mixpost
curl http://localhost:8100/api/health # Plausible
```

### Database Connectivity
```bash
docker-compose exec marketing-db psql -U postgres -c "SELECT 1"
# Output: 1 (success)
```

## Version Information

- **Listmonk:** Latest (listmonk/listmonk:latest)
- **n8n:** Latest (n8nio/n8n:latest)
- **Mixpost:** Latest (inovector/mixpost:latest)
- **Plausible:** Latest (plausible/analytics:latest)
- **PostgreSQL:** 15-alpine
- **Redis:** 7-alpine
- **ClickHouse:** Latest

## Cost Analysis

| Component | Cost/Month |
|-----------|-----------|
| EC2 t2.micro | $8-12 |
| RDS (if separate) | $0-15 |
| SMTP (SendGrid) | $0-20 |
| **Total** | **$8-47** |

All software is open-source and free.

## Support & Documentation

- **Quick Start:** README.md
- **Detailed Deployment:** DEPLOYMENT_GUIDE.md
- **Backend Integration:** INTEGRATION_GUIDE.md
- **Email Templates:** See HTML files for customization
- **Workflows:** JSON files with inline documentation

## Maintenance Schedule

- **Daily:** Monitor email deliverability
- **Weekly:** Review workflow executions, check analytics
- **Monthly:** Optimize send times, review costs
- **Quarterly:** Update dependencies, audit security

## Next Steps

1. Run `./setup.sh` to deploy
2. Configure SMTP in `.env`
3. Set up email lists in Listmonk
4. Import workflows to n8n
5. Connect Rosier backend webhooks
6. Test complete data flow
7. Monitor and optimize

---

**Status:** COMPLETE ✓

All files created, documented, and ready for production deployment.

**Created By:** Dev 1 - Marketing Automation
**Date:** April 1, 2026
**Version:** 1.0
