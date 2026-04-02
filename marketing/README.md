# Rosier Marketing Automation Stack

**Self-hosted, open-source marketing infrastructure for the Rosier fashion app**

This directory contains a complete marketing automation stack that runs alongside the Rosier backend. Zero vendor lock-in, full data ownership, minimal cost (~$0-5/month hosting only).

## What's Included

### Core Services

1. **Listmonk** (Email Marketing)
   - Unlimited subscribers and sends
   - Beautiful web UI for campaign creation
   - Segmentation, automation, analytics
   - Self-hosted, no vendor lock-in

2. **n8n** (Workflow Automation)
   - The brain of the system
   - Connects all services together
   - Webhook-triggered workflows
   - Cron-scheduled automations
   - Visual workflow builder

3. **Mixpost** (Social Media Scheduling)
   - Schedule posts to Instagram, TikTok, Twitter, Facebook
   - Content calendar and team collaboration
   - Post analytics
   - Self-hosted alternative to Buffer/Later

4. **Plausible Analytics** (Privacy-First Analytics)
   - GDPR-compliant website/app analytics
   - No cookies, no tracking pixels
   - Lightweight JavaScript integration
   - Beautiful dashboards

### Supporting Infrastructure

- **PostgreSQL** — Shared database for all services
- **Redis** — Cache and queue for Mixpost/n8n
- **ClickHouse** — Analytics database for Plausible

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- EC2 instance or server (t2.micro or better)
- Basic knowledge of environment variables

### 1. Setup (5 minutes)

```bash
cd marketing/

# Run one-click setup script
./setup.sh
```

The script will:
- Check Docker installation
- Generate secure credentials
- Create .env file
- Start all services
- Print access URLs and credentials

### 2. Configure SMTP (2 minutes)

Edit `.env` file and update:

```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-specific-password
```

**Gmail example:** Generate app-specific password at myaccount.google.com/apppasswords

**SendGrid example:** Use `apikey` as username, your API key as password

**Amazon SES:** Use AWS access key + secret key

### 3. Access Services

Once running:

- **Listmonk:** http://localhost:9000/admin
  - Username: admin
  - Password: (check .env file)

- **n8n:** http://localhost:5678
  - Setup on first visit

- **Mixpost:** http://localhost:9001
  - Setup on first visit

- **Plausible:** http://localhost:8100
  - Email: admin@rosier.app
  - Password: (check .env file)

## Directory Structure

```
marketing/
├── docker-compose.marketing.yml    # Main Docker Compose file
├── setup.sh                        # One-click setup script
├── .env.example                    # Environment template
├── .env                            # (auto-generated, do not commit)
├── scripts/
│   └── init-marketing-db.sql      # Database initialization
├── workflows/
│   ├── user_signup_flow.json      # Welcome sequence trigger
│   ├── weekly_style_digest.json   # Weekly email + social
│   ├── referral_reward.json       # Referral automation
│   └── daily_content_scheduler.json # Daily social posts
├── email_templates/
│   ├── welcome.html               # Onboarding email
│   ├── weekly_digest.html         # Weekly digest template
│   ├── referral_invite.html       # Referral invitation
│   ├── sale_alert.html            # Price drop alert
│   └── reengagement.html          # Win-back email
├── INTEGRATION_GUIDE.md           # Backend integration docs
├── README.md                      # This file
└── .credentials                   # (auto-generated, keep secure!)
```

## Key Workflows

### 1. User Signup Flow
**Triggered:** When new user completes onboarding

```
User signs up → n8n webhook
  ↓
  ├─ Add to Listmonk "Users" list
  ├─ Send welcome email
  ├─ Schedule automated onboarding sequence
  └─ Log signup event to analytics
```

### 2. Weekly Style Digest
**Triggered:** Every Sunday 10am

```
Cron trigger → Get trending brands/products from API
  ↓
  ├─ Generate beautiful email with trending items
  ├─ Send via Listmonk to "Style Digest" subscribers
  ├─ Create social media post
  └─ Schedule to Instagram + TikTok via Mixpost
```

### 3. Referral Rewards
**Triggered:** When user successfully refers someone

```
Referral success → n8n webhook
  ↓
  ├─ Update referral count
  ├─ Send confirmation emails (referrer + referred)
  ├─ Check for milestone rewards (5, 10+ referrals)
  ├─ Unlock in-app rewards if milestone hit
  └─ Log event to analytics
```

### 4. Daily Content Scheduler
**Triggered:** Every morning 8am

```
Cron trigger → Get today's trending products
  ↓
  ├─ Generate Instagram captions
  ├─ Generate TikTok captions
  ├─ Schedule posts via Mixpost
  └─ Log to analytics
```

## Common Tasks

### Create a New Email Campaign

1. Log into Listmonk: http://localhost:9000/admin
2. Go to Campaigns → New Campaign
3. Select a list (Users, Waitlist, Style Digest Subscribers, etc.)
4. Use an email template from `email_templates/` or create new
5. Schedule or send immediately

### Schedule a Social Media Post

1. Log into Mixpost: http://localhost:9001
2. Go to Posts → Create Post
3. Write content, add media
4. Select accounts (Instagram, TikTok, etc.)
5. Schedule date/time
6. Post goes out automatically

### View Analytics

1. Log into Plausible: http://localhost:8100
2. Check dashboard for:
   - Page views
   - Custom events (signups, referrals)
   - Visitor trends
   - Funnel conversions

### Edit a Workflow

1. Log into n8n: http://localhost:5678
2. Find workflow in sidebar
3. Edit nodes and connections
4. Test with "Test workflow"
5. Activate when ready

## Email Templates

All templates are responsive and match Rosier's brand (colors: #1A1A2E, #C4A77D):

- **welcome.html** — First impression, onboarding call-to-action
- **weekly_digest.html** — Trending items, style recommendations
- **referral_invite.html** — Invite a friend with unique referral code
- **sale_alert.html** — Price drops on favorited items
- **reengagement.html** — Win-back campaign for inactive users

Edit HTML directly or use Listmonk's template editor. Update brand colors and links in the `<style>` sections.

## Deployment Notes

### On EC2 t2.micro

- Allocate 800MB RAM to API container
- Database gets 256MB
- Redis gets 128MB
- Leave 100MB for OS

Monitor with: `docker stats`

### Backup Strategy

**Database:**
```bash
docker-compose exec marketing-db pg_dump -U postgres > backup.sql
```

**Workflows:**
```bash
docker cp rosier-n8n:/home/node/.n8n/workflows ./workflows-backup
```

**Email Templates:**
Export from Listmonk UI (Settings → Data Import/Export)

### SSL/HTTPS

To add SSL in production:

1. Get certificate (Let's Encrypt or AWS ACM)
2. Mount cert in docker-compose.yml
3. Configure Nginx reverse proxy
4. Update .env with https URLs

See existing Nginx config in main `docker-compose-prod.yml` as reference.

## Troubleshooting

### Services won't start

```bash
# Check Docker daemon
docker ps

# View logs
docker-compose -f docker-compose.marketing.yml logs

# Check specific service
docker-compose -f docker-compose.marketing.yml logs listmonk
```

### Emails not sending

1. Verify SMTP credentials in .env
2. Check Listmonk logs: Admin → Logs
3. Test SMTP connection:
   ```bash
   docker-compose exec marketing-db psql -U listmonk -c "SELECT * FROM smtp_logs LIMIT 5;"
   ```

### Workflows not triggering

1. Check n8n executions: UI → Executions
2. Verify backend is posting to correct webhook URL
3. Check n8n logs: `docker-compose logs n8n`

### High memory usage

1. Check which service: `docker stats`
2. Scale down if needed in docker-compose.yml
3. Increase EC2 instance size

## Cost Breakdown

| Component | Cost |
|-----------|------|
| EC2 t2.micro | $8-12/month |
| RDS/Database (if separate) | $0-10/month |
| SMTP (if third-party) | $0-30/month |
| Domain name | $10-15/year |
| **Total** | **$20-60/month** |

*All software is open-source and free. Costs are hosting + optional third-party services.*

## Future Enhancements

Planned additions:

- [ ] SMS marketing (Twilio)
- [ ] Push notifications (Firebase)
- [ ] Slack integration
- [ ] Advanced A/B testing (GrowthBook)
- [ ] Zendesk support integration
- [ ] Advanced segmentation
- [ ] Predictive analytics

## Contributing

For improvements or issues:

1. Edit workflows in `workflows/`
2. Edit email templates in `email_templates/`
3. Update `.env.example` if adding new services
4. Test with `docker-compose up -d`
5. Document changes in INTEGRATION_GUIDE.md

## Security

### Best Practices

- Never commit `.env` file with real credentials
- Use strong passwords (setup.sh generates them)
- Rotate SMTP password monthly
- Restrict security group to EC2 only
- Enable VPC Flow Logs
- Monitor n8n for failed executions

### Credentials Storage

- `.env` — Auto-generated, contains passwords
- `.credentials` — Auto-generated, backup of passwords (keep secure!)
- N8n UI — Encrypts credentials via N8N_ENCRYPTION_KEY

## Getting Help

### Documentation

- **INTEGRATION_GUIDE.md** — Backend integration details
- **docker-compose.marketing.yml** — Service configuration
- **Email templates** — Customize in HTML
- **Workflow JSON** — Edit in n8n UI (easier than JSON)

### Support Resources

- Listmonk docs: https://listmonk.app
- n8n docs: https://docs.n8n.io
- Mixpost docs: https://docs.mixpost.app
- Plausible docs: https://plausible.io/docs

### Contact

Issues with the stack? Check INTEGRATION_GUIDE.md first, then reach out to dev@rosier.app

---

## License

All configuration and templates in this directory are part of Rosier.

Third-party software:
- Listmonk: MIT License
- n8n: Sustainable Use License
- Mixpost: MIT License
- Plausible: AGPL-3.0 License

---

**Last Updated:** April 1, 2026

**Rosier Marketing Stack v1.0**

*Built for founders who want control over their marketing infrastructure.*
