# Rosier Marketing Stack Integration Guide

This guide explains how the self-hosted marketing automation stack integrates with the Rosier backend and the data flow between systems.

## Architecture Overview

```
Rosier Backend (FastAPI)
    ↓
n8n Workflows (Automation Hub)
    ↓
├── Listmonk (Email)
├── Mixpost (Social Media)
└── Plausible Analytics (Tracking)

Data Flow:
1. Backend events → n8n webhooks
2. n8n processes and triggers actions
3. Actions sent to email/social/analytics services
4. Results logged back to analytics
```

## Backend Webhook Endpoints Required

The Rosier backend must expose these webhook endpoints for n8n to trigger marketing workflows:

### 1. User Signup Webhook
**When:** New user completes onboarding

```
POST /webhooks/marketing/user-signup
Content-Type: application/json

{
  "user_id": "uuid",
  "email": "user@example.com",
  "name": "First Last",
  "created_at": "2026-04-01T10:00:00Z",
  "style_preferences": {
    "primary_style": "minimalist",
    "budget_range": "mid-tier",
    "brands": ["brand_1", "brand_2"]
  }
}
```

**Response Expected:**
- n8n will add user to Listmonk "Users" list
- Send welcome email sequence
- Log signup event to analytics

---

### 2. Referral Success Webhook
**When:** User successfully refers another user

```
POST /webhooks/marketing/referral-success
Content-Type: application/json

{
  "referrer_id": "uuid",
  "referrer_email": "referrer@example.com",
  "referrer_name": "John Doe",
  "referred_email": "friend@example.com",
  "referred_name": "Jane Smith",
  "referral_code": "JOHNDOE_ABC123"
}
```

**Response Expected:**
- n8n updates referrer's Listmonk record with referral count
- Sends confirmation email to referrer
- Sends welcome email to referred user
- Checks for milestone rewards (5, 10+ referrals)
- Unlocks in-app rewards if milestone reached
- Logs referral event to analytics

---

### 3. Purchase/Conversion Webhook (Optional, for future)
**When:** User makes a purchase

```
POST /webhooks/marketing/conversion
Content-Type: application/json

{
  "user_id": "uuid",
  "email": "user@example.com",
  "order_id": "order_123",
  "amount": 149.99,
  "items": ["product_id_1", "product_id_2"],
  "timestamp": "2026-04-01T12:00:00Z"
}
```

---

## n8n Workflow Requirements

### Workflow Triggers & Actions

#### Webhook Triggers
n8n listens on these endpoints (automatically configured):

- `http://n8n:5678/webhook/user-signup`
- `http://n8n:5678/webhook/referral-success`
- `http://n8n:5678/webhook/conversion` (optional)

#### Cron/Schedule Triggers
- **Daily:** 8am - Daily content scheduler
- **Weekly:** Sunday 10am - Weekly style digest

#### Credentials Required in n8n

1. **Rosier API Token**
   - For calling backend endpoints
   - Set in n8n: `Settings → Credentials → HTTP Bearer Token`
   - Value: Backend JWT/API token

2. **Listmonk API Key**
   - Already configured via environment variables
   - Endpoint: `http://listmonk:9000/api`

3. **Mixpost API Key**
   - Already configured via environment variables
   - Endpoint: `http://mixpost:80/api`

4. **Plausible API Key**
   - Already configured via environment variables
   - Endpoint: `http://plausible:8000/api`

---

## Data Flow Diagrams

### Signup Flow
```
User completes onboarding in app
    ↓
Backend POST /webhooks/marketing/user-signup
    ↓
n8n webhook trigger (user_signup_flow.json)
    ↓
├─ Add to Listmonk "Users" list
├─ Send welcome email via Listmonk
├─ Schedule automated onboarding sequence
└─ Log signup event to Plausible
```

### Referral Flow
```
User submits referral in app
    ↓
Backend POST /webhooks/marketing/referral-success
    ↓
n8n webhook trigger (referral_reward.json)
    ↓
├─ Get referrer's total referral count
├─ Update Listmonk contact data
├─ Send referrer confirmation email
├─ Add referred user to Waitlist
├─ Send referred user welcome email
├─ Check for milestone (5, 10 referrals)
├─ If milestone: unlock in-app reward
└─ Log event to Plausible with metadata
```

### Weekly Digest Flow
```
Cron trigger: Sunday 10am
    ↓
n8n scheduled trigger (weekly_style_digest.json)
    ↓
├─ Call Rosier API: GET /api/v1/trending/brands?period=week
├─ Call Rosier API: GET /api/v1/trending/products?period=week
├─ Generate HTML email content from data
├─ Send campaign via Listmonk to "Style Digest" list
├─ Schedule social post via Mixpost
└─ Log event to Plausible
```

### Daily Content Scheduler Flow
```
Cron trigger: Daily 8am
    ↓
n8n scheduled trigger (daily_content_scheduler.json)
    ↓
├─ Call Rosier API: GET /api/v1/trending/products?period=day
├─ Generate Instagram + TikTok captions (using function node)
├─ Schedule Instagram post via Mixpost
├─ Schedule TikTok post via Mixpost
└─ Log event to Plausible
```

---

## Backend API Endpoints Required

For workflows to function properly, the Rosier backend must expose:

### Trending Data Endpoints

```
GET /api/v1/trending/brands?limit=5&period=week
Response: {
  "status": "success",
  "data": [
    {
      "id": "brand_123",
      "name": "Brand Name",
      "mentions": 45,
      "engagement_rate": 0.78
    }
  ]
}

GET /api/v1/trending/products?limit=10&period=day&sort=trending
Response: {
  "status": "success",
  "data": [
    {
      "id": "product_123",
      "name": "Product Name",
      "brand": "Brand Name",
      "brand_id": "brand_123",
      "description": "...",
      "image_url": "...",
      "trend_score": 85,
      "vibe": "minimalist",
      "category": "dresses",
      "style_dna_match": "85%"
    }
  ]
}

GET /api/v1/users/{user_id}/referral-count
Response: {
  "status": "success",
  "data": {
    "user_id": "uuid",
    "count": 3,
    "total_earned_rewards": ["early_access_basic", "...]
  }
}
```

### User Update Endpoints

```
POST /api/v1/users/{user_id}/unlocks/early-access
Body: { "reward": "daily_drop_early_access" }
Response: { "status": "success", "reward_unlocked": "..." }

PUT /api/v1/users/{user_id}
Body: {
  "custom_fields": {
    "referral_count": 5,
    "last_email_engagement": "2026-04-01"
  }
}
Response: { "status": "success" }
```

---

## Listmonk Lists Setup

Create these lists in Listmonk (via admin dashboard or API):

### Lists

| Name | Purpose | Use Case |
|------|---------|----------|
| Waitlist | Pre-launch signups | Welcome sequence |
| Users | Active users | Style digests, re-engagement |
| Style Digest Subscribers | Weekly digest opt-ins | Weekly style digest campaign |
| Sale Alerts | Price drop notifications | Abandoned items, price drops |

### Segments (Optional)

Can be created for advanced targeting:

- **High Engagers:** Users with >50% open rate
- **Inactive:** No opens in 30 days
- **Referrers:** Users with 3+ referrals
- **Style DNA:** Users grouped by style type (minimalist, maximalist, etc.)

---

## Email Campaign Setup in Listmonk

### Welcome Sequence

1. **Template ID 1:** Welcome email (sent immediately)
   - File: `email_templates/welcome.html`
   - Subject: "Welcome to Rosier - Your Personal Style Awaits"

2. Automated sequence (configure in Listmonk):
   - Day 0: Welcome email
   - Day 1: "Get Started" email (style quiz reminder)
   - Day 3: "Your Style DNA" email (when they complete 20 swipes)
   - Day 7: "Exclusive Access" email (showcase early features)

### Recurring Campaigns

- **Weekly Style Digest**
  - List: Style Digest Subscribers
  - Schedule: Every Sunday 10am
  - Template ID: 2 (`email_templates/weekly_digest.html`)

- **Price Drop Alerts**
  - List: Sale Alerts
  - Trigger: When product in favorites drops price
  - Template ID: 3 (`email_templates/sale_alert.html`)

- **Re-engagement**
  - List: Users (with filter: inactive 30+ days)
  - Schedule: Monthly
  - Template ID: 4 (`email_templates/reengagement.html`)

---

## Mixpost Social Integration

### Connected Accounts

Mixpost should be connected to:

- Instagram (@rosier.app)
- TikTok (@rosier.app)
- Twitter/X (optional)
- Facebook (optional)

### Content Calendar

n8n workflows automatically schedule:

- **Daily:** Instagram + TikTok posts (8am local time)
- **Weekly:** Trending brands/products highlight (Sunday, post to all channels)

---

## Analytics & Tracking

### Plausible Events

The stack logs these events to Plausible for tracking:

```javascript
// User signup
{ name: "signup", url: "https://rosier.app", props: { source: "email|app|referral" } }

// Weekly digest sent
{ name: "weekly_digest_sent", props: { brands_featured: 5, products_featured: 10 } }

// Referral success
{ name: "referral_success", props: { referrer_id: "...", total_referrals: 3 } }

// Daily posts scheduled
{ name: "daily_posts_scheduled", props: { posts_scheduled: 2, products_featured: 3 } }
```

### Metrics to Track

In Plausible dashboard, create goals for:

- Signup conversion rate
- Email open rate (via click tracking)
- Referral conversion
- Content engagement (social post clicks)

---

## Error Handling & Retries

### n8n Retry Logic

Each workflow node has retry configuration:

- **HTTP Requests:** 3 retries on 5xx errors
- **Database writes:** 2 retries
- **Email sends:** 3 retries with exponential backoff

### Failure Notifications

Configure n8n to send alerts (via email or Slack):

- If more than 2 consecutive workflow failures
- If Listmonk API is unreachable
- If Rosier backend API is unreachable

---

## Security & Authentication

### API Authentication

- **n8n to Rosier API:** Bearer token (JWT from backend)
- **n8n to Listmonk:** Basic auth + API key
- **n8n to Mixpost:** Bearer token
- **n8n to Plausible:** API key

All stored in n8n credentials (encrypted).

### Network Security

- All services communicate via Docker internal network
- Only exposed ports: 9000 (Listmonk), 5678 (n8n), 9001 (Mixpost), 8100 (Plausible)
- PostgreSQL and Redis not exposed to internet

---

## Troubleshooting

### Workflow Not Triggering

1. Check webhook logs in n8n: UI → Executions
2. Verify backend is sending POST requests to correct n8n endpoint
3. Check n8n container logs: `docker-compose logs n8n`

### Emails Not Sending

1. Verify SMTP credentials in .env file
2. Check Listmonk: Admin → Campaigns → Logs
3. Look for bounce errors in Listmonk database

### Social Posts Not Appearing

1. Check Mixpost: Admin → Posts → Check scheduled posts
2. Verify social media accounts are connected
3. Check for rate limits on Instagram/TikTok APIs

### Analytics Events Not Appearing

1. Verify Plausible is running: `curl http://localhost:8100/api/health`
2. Check event format matches Plausible API spec
3. Verify domain is registered in Plausible: Settings → Sites

---

## Maintenance

### Weekly Tasks

- Monitor n8n workflow executions for errors
- Check Listmonk bounce rate (aim for <2%)
- Review Mixpost scheduling (ensure posts are going out)

### Monthly Tasks

- Review Plausible analytics dashboard
- Check email unsubscribe rates
- Verify SMTP quota (if using paid SMTP service)
- Rotate API keys (if using external services)

### Quarterly Tasks

- Review workflow performance and optimize
- Audit email templates for engagement
- Update email list segments based on behavior

---

## Future Enhancements

Planned integrations:

1. **SMS Marketing** — Twilio integration for SMS alerts
2. **Push Notifications** — Firebase integration for app notifications
3. **Slack Integration** — Real-time alerts to team Slack
4. **Webhooks Out** — Allow backend to receive events from marketing stack
5. **Advanced A/B Testing** — GrowthBook integration for email testing
6. **Customer Support** — Zendesk integration for support tickets via email

---

## Support & Questions

For issues with:

- **n8n workflows:** Check UI logs, restart container
- **Listmonk emails:** Check SMTP credentials, review logs
- **Mixpost social:** Verify API credentials, check rate limits
- **Plausible analytics:** Check JavaScript snippet is loaded, verify domain
- **General stack:** Review `docker-compose logs` for all services

Contact: dev@rosier.app
