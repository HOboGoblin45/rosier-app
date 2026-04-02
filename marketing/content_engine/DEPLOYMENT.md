# Rosier Content Engine - Deployment & Operations Guide

Complete guide for deploying the content engine to production and maintaining daily operations.

---

## System Architecture

```
Content Engine Pipeline
├── Daily Cron Trigger (6 AM EST)
│   └── auto_post.py
│       ├── 1. Fetch App Data (Rosier API)
│       ├── 2. Generate Content (Templates)
│       ├── 3. Create Images (Pillow)
│       ├── 4. Schedule Posts (Calendar)
│       └── 5. Export to Mixpost/Files
│
├── Content Storage
│   ├── /rosier/content/staging/       (Daily output)
│   ├── /rosier/content/archive/       (Backup)
│   └── /rosier/content/logs/          (Execution logs)
│
├── Scheduling System
│   ├── Mixpost (API Publishing)
│   └── Manual Review (Staging folder)
│
└── Monitoring
    ├── Analytics Tracker
    ├── Daily Reports
    └── Performance Insights
```

---

## Production Deployment

### Phase 1: Setup (Day 1)

1. **Install on Production Server**:
```bash
cd /opt/rosier/marketing
git clone <repo> content_engine
cd content_engine
pip install -r requirements.txt --break-system-packages
```

2. **Configure Production Environment**:
```bash
cat > .env << 'EOF'
ROSIER_API_BASE=https://api.rosier.app
ROSIER_API_KEY=production_key_here
MIXPOST_URL=https://content.rosier.app:8000
MIXPOST_ENABLED=true
LOG_LEVEL=INFO
LOG_FILE=/var/log/rosier/content_engine.log
EOF
```

3. **Create Output Directories**:
```bash
mkdir -p /data/rosier/content/{staging,archive,logs,assets}
chmod 755 /data/rosier/content/{staging,archive,logs}
chown rosier:rosier /data/rosier/content/*
```

4. **Test Locally**:
```bash
python3 auto_post.py --dry-run
# Should output: "Pipeline ready. No posts published (dry-run mode)"
```

### Phase 2: Cron Setup (Day 1)

1. **Create System User** (if not exists):
```bash
useradd -r -s /bin/bash rosier_content
```

2. **Setup Cron Job**:
```bash
# As root or with sudo
cat > /etc/cron.d/rosier-content-engine << 'EOF'
# Rosier Content Engine - Daily Post Generation
# Runs at 6 AM EST (11 AM UTC)
0 6 * * * rosier_content /usr/bin/python3 /opt/rosier/marketing/content_engine/auto_post.py >> /var/log/rosier/content_engine.log 2>&1
EOF

chmod 644 /etc/cron.d/rosier-content-engine
```

3. **Verify Cron**:
```bash
# Check it was added
cat /etc/cron.d/rosier-content-engine

# Check cron service is running
systemctl status cron
```

### Phase 3: Monitoring Setup (Day 2)

1. **Setup Log Rotation**:
```bash
cat > /etc/logrotate.d/rosier-content << 'EOF'
/var/log/rosier/content_engine.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 rosier_content rosier
    sharedscripts
}
EOF
```

2. **Setup Alert on Failure**:
```bash
# Add to cron job:
0 7 * * * rosier_content \
  grep -q "completed successfully" /var/log/rosier/content_engine.log || \
  mail -s "Rosier Content Engine Failed" dev@rosier.app
```

3. **Monitor Generated Content**:
```bash
# Create daily check
cat > /opt/rosier/marketing/content_engine/health_check.py << 'EOF'
#!/usr/bin/env python3
import os
from datetime import datetime, timedelta

output_dir = '/data/rosier/content/staging'
today = datetime.now().date()

# Check if today's images exist
images = [f for f in os.listdir(output_dir) if str(today) in f and f.endswith('.png')]

if len(images) >= 4:
    print("✓ Daily content generated successfully")
    exit(0)
else:
    print(f"✗ Missing content: Found {len(images)} images, expected 4+")
    exit(1)
EOF

chmod +x /opt/rosier/marketing/content_engine/health_check.py
```

---

## Daily Operations

### 6 AM EST - Automated Execution

**What happens**:
1. Cron triggers `auto_post.py`
2. Fetches trending data from Rosier API
3. Generates 4-5 pieces of content
4. Creates branded images
5. Schedules posts for the day
6. Exports to Mixpost or staging folder
7. Logs execution

### 9 AM - 8 PM EST - Posts Go Live

**Instagram Reels**:
- 11 AM: Trending post
- 2 PM: Brand spotlight
- 7 PM: Style DNA engagement

**TikTok**:
- 7 AM: App demo
- 12 PM: Trending sounds
- 7 PM: Creator testimonial
- 10 PM: Engagement prompt

**Stories**:
- 8 AM, 12 PM, 5 PM, 9 PM: Tactical engagement

### End of Day (8-9 PM) - Manual Engagement

**30-minute community engagement window**:
- Respond to all comments
- Engage with 10-15 related accounts
- Monitor brand mentions
- Send 5-10 DMs to micro-influencers

---

## Mixpost Integration

### Setup API Connection

1. **Get Mixpost Credentials**:
```bash
# SSH into Mixpost server
ssh mixpost.rosier.app
cd /var/www/mixpost

# Create API token
php artisan tinker
>>> $user = App\Models\User::first();
>>> $token = $user->createToken('content-engine')->plainTextToken;
>>> echo $token;
```

2. **Update Environment**:
```bash
echo "MIXPOST_API_TOKEN=your_token_here" >> /opt/rosier/marketing/content_engine/.env
```

3. **Test Connection**:
```bash
python3 -c "
import requests
response = requests.post(
    'https://content.rosier.app/api/posts',
    headers={'Authorization': 'Bearer YOUR_TOKEN'},
    json={'content': 'Test post'}
)
print(f'Status: {response.status_code}')
"
```

### Manual Import Workflow

**If Mixpost API isn't ready**:

1. Run `auto_post.py` daily at 6 AM (automated)
2. Check staging folder: `/data/rosier/content/staging/`
3. In Mixpost UI:
   - Dashboard → New Post
   - Import from file: `schedule_today.json`
   - Review captions and images
   - Schedule for optimal times
4. Publish at 9 AM

---

## Performance Tracking

### Daily Check (9 PM)

```bash
python3 << 'EOF'
from analytics_tracker import AnalyticsTracker

tracker = AnalyticsTracker()
report = tracker.generate_daily_report()

print(f"Posts published: {report['posts_published']}")
print(f"Total reach: {report['total_impressions']:,}")
print(f"Engagement rate: {report['avg_engagement_rate']:.1f}%")
EOF
```

### Weekly Analysis (Friday 5 PM)

```bash
python3 << 'EOF'
from analytics_tracker import AnalyticsTracker

tracker = AnalyticsTracker()

# Get insights
top_types = tracker.get_top_performing_content_types(days=7)
platform_perf = tracker.get_platform_performance(days=7)
report = tracker.generate_weekly_report()

# Print insights
print("Top performing content:")
for content_type, stats in list(top_types.items())[:3]:
    print(f"  {content_type}: {stats['avg_engagement_rate']:.1f}% engagement")

print(f"\nRecommendation: {report['recommendation']}")
EOF
```

### Export to Spreadsheet

```bash
python3 -c "
from analytics_tracker import AnalyticsTracker
tracker = AnalyticsTracker()
tracker.export_to_csv('/data/rosier/reports/weekly_metrics.csv')
print('Exported to CSV')
"
```

---

## Troubleshooting

### Content Not Generated

**Check 1: Logs**
```bash
tail -100 /var/log/rosier/content_engine.log
```

**Check 2: API Connection**
```bash
curl -H "Authorization: Bearer YOUR_KEY" \
  https://api.rosier.app/api/trending/brands
# Should return 200 OK with brand data
```

**Check 3: Disk Space**
```bash
df -h /data/rosier/content/
# Should have >1GB free
```

**Check 4: Run Manually**
```bash
python3 /opt/rosier/marketing/content_engine/auto_post.py
# Check for error messages
```

### Images Look Bad

**Check Pillow installation**:
```bash
python3 -c "from PIL import Image; print(Image.__file__)"
# Should return path to PIL library
```

**Reinstall Pillow**:
```bash
pip install --force-reinstall --no-cache-dir Pillow --break-system-packages
```

### Mixpost Not Receiving Posts

**Check 1: API Token Valid**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://content.rosier.app/api/profile
# Should return 200 with user info
```

**Check 2: Network Connectivity**
```bash
curl -I https://content.rosier.app
# Should return 200 OK
```

**Check 3: Mixpost Logs**
```bash
# SSH to Mixpost server
tail -50 /var/www/mixpost/storage/logs/laravel.log
```

### Cron Not Running

**Check 1: Cron Service**
```bash
systemctl status cron
systemctl restart cron
```

**Check 2: User Permissions**
```bash
ls -la /opt/rosier/marketing/content_engine/auto_post.py
# Should be executable by rosier_content user
```

**Check 3: User PATH**
```bash
# Run as the user cron runs as:
sudo -u rosier_content /usr/bin/python3 /opt/rosier/marketing/content_engine/auto_post.py
```

---

## Maintenance Tasks

### Weekly (Friday 5 PM)

- [ ] Review analytics report
- [ ] Update content strategy based on insights
- [ ] Check disk usage
- [ ] Verify cron job still running
- [ ] Update content templates if needed

### Monthly (1st of month)

- [ ] Archive old generated content
- [ ] Review top performing content types
- [ ] Update brand roster if needed
- [ ] Check Pillow/dependencies for updates
- [ ] Audit Mixpost API quota usage

### Quarterly (Seasonal)

- [ ] Update seasonal hashtags
- [ ] Refresh brand roster
- [ ] Review color scheme
- [ ] Audit templates for freshness
- [ ] Plan Q next strategy

---

## Backup & Disaster Recovery

### Backup Strategy

```bash
# Daily backup of output (to S3/cloud)
0 8 * * * rsync -av /data/rosier/content/staging \
  s3://rosier-backups/content_engine/$(date +\%Y\%m\%d)/

# Monthly full backup
0 0 1 * * tar -czf /backups/rosier_content_$(date +\%Y\%m).tar.gz \
  /opt/rosier/marketing/content_engine \
  /data/rosier/content/archive
```

### Recovery Procedure

```bash
# If content engine breaks:
1. Copy latest working version from backup
2. Restore cron job
3. Test with `python3 auto_post.py --dry-run`
4. Verify API connection
5. Resume normal operation

# Full recovery (from scratch):
1. Install Python 3.10+
2. Install dependencies: pip install -r requirements.txt
3. Create directories: mkdir -p /data/rosier/content/{staging,archive}
4. Setup cron job
5. Configure API connection
6. Test and deploy
```

---

## Scaling Considerations

### As Content Grows

**Month 1-2** (5-7 posts/day):
- Current setup is sufficient
- Focus: Quality and engagement

**Month 3-4** (10-14 posts/day):
- Consider generating multiple variants
- Split by platform scheduling
- Add A/B testing framework

**Month 5-6** (15-25 posts/day):
- Migrate to queue system (Bull.js/Celery)
- Use parallel image generation
- Add database for content versioning

### Performance Optimization

```python
# For high volume, implement:
1. Parallel image generation (multiprocessing)
2. Batch API requests
3. Template caching
4. Image compression pipeline
5. Database-backed scheduling

# Expected timings:
- Current: 30-45 seconds per run
- Optimized: 15-20 seconds per run
```

---

## Security Considerations

### API Key Management

```bash
# Never commit API keys
echo "ROSIER_API_KEY=*" >> .gitignore

# Store in environment or secrets manager
# Good options: HashiCorp Vault, AWS Secrets Manager, 1Password
```

### Permissions

```bash
# Run as non-root user
useradd -r -s /bin/false rosier_content

# Restrict directory access
chmod 700 /data/rosier/content/
chown rosier_content:rosier_content /data/rosier/content/

# Audit log access
# Use fail2ban to monitor failed runs
```

### Monitoring

```bash
# Alert on unusual activity
# 1. Multiple failures in a row
# 2. Sudden spike in generated image sizes
# 3. API errors from Rosier backend
# 4. Disk space issues
```

---

## Success Metrics

### Daily

- ✓ Pipeline runs at 6 AM EST
- ✓ 4-5 pieces of content generated
- ✓ All images created successfully
- ✓ Posts scheduled on time

### Weekly

- ✓ 25-35 posts published
- ✓ Average engagement rate: 8-12%
- ✓ Top content type identified
- ✓ No failed jobs

### Monthly

- ✓ 100+ pieces of content generated
- ✓ Total reach: 300K+ impressions
- ✓ App downloads driven: 50-100/month
- ✓ Zero infrastructure issues

---

## Contacts & Support

**Slack Channel**: #content-engine
**On-Call**: Dev 2, Dev 3
**Escalation**: Growth Lead

---

**Deployment Status**: ✓ Ready for production
**Last Updated**: April 1, 2026
**Next Review**: April 8, 2026
