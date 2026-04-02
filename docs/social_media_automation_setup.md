# Social Media Automation Setup for Rosier
## Step-by-Step Implementation Guide

**Last Updated**: April 2026
**Target Outcome**: Post 1 Reel + 1 TikTok per day with zero manual scheduling
**Estimated Setup Time**: 2-3 hours
**Ongoing Time Required**: 30 minutes/day content creation + DM outreach

---

## Table of Contents
1. [Account Setup](#account-setup)
2. [Mixpost Deployment](#mixpost-deployment)
3. [Content Workflow](#content-workflow)
4. [Automation Triggers](#automation-triggers)
5. [Monitoring & Alerts](#monitoring--alerts)
6. [Troubleshooting](#troubleshooting)

---

## Account Setup

### Step 1: Instagram Creator Account Setup

1. Convert to Instagram Creator Account:
   - Settings → Account type and tools → Account type
   - Switch to Professional → Creator
   - Add category: "App" or "Lifestyle"

2. Enable two-factor authentication:
   - Settings → Security → Two-factor authentication
   - Use authenticator app (Google Authenticator, not SMS)

3. Set up Business Links:
   - Bio: "Swipe right for your style | Download Rosier 👇"
   - Link in bio: Your app download page or bit.ly short link
   - Add contact button with email

4. Create URL tracking parameter:
   - Link: `https://yourapp.com/download?utm_source=instagram&utm_medium=bio`
   - Shorten via bit.ly: `bit.ly/rosier-instagram`
   - Use same link in all Instagram CTAs

5. Enable branded content tools (if working with micro-influencers):
   - Settings → Creator → Branded content → Turn on

### Step 2: TikTok Pro Account Setup

1. Switch to TikTok Creator Account:
   - Profile → Settings and privacy → Account
   - Account type → Creator account (if not already)

2. Set professional category:
   - Profile → Settings and privacy → Professional dashboard
   - Category: "Fashion" or "Lifestyle"

3. Two-factor authentication:
   - Settings and privacy → Account security → Two-factor authentication
   - Use authenticator app

4. Bio setup:
   - Bio: "Swipe right to discover style | Download the app 👇"
   - Website link: Same bit.ly link as Instagram OR TikTok Shop affiliate link
   - Profile picture: High-quality Rosier logo or founder headshot

5. Enable Creator Fund (optional, but good for future monetization):
   - Profile → Creator tools → Creator Fund
   - Note: Need 10K followers + 100K views in past 30 days

6. Setup affiliate links (important for tracking):
   - TikTok Shop → Create unique code for discount
   - Share code in videos: "Use code ROSIER15 for discount"
   - Track usage in backend analytics

### Step 3: Create Content Creation Directory

Create folder structure for content organization:

```
Rosier_Content/
├── 01_TikTok/
│   ├── Drafts/
│   ├── Ready_to_Upload/
│   ├── Posted/
│   └── Analytics/
├── 02_Instagram_Reels/
│   ├── Drafts/
│   ├── Ready_to_Upload/
│   ├── Posted/
│   └── Analytics/
├── 03_Assets/
│   ├── Audio_Trending/
│   ├── Templates/
│   └── Fonts/
└── 04_Spreadsheets/
    ├── Content_Calendar.csv
    ├── Influencer_Tracking.csv
    └── Analytics_Log.csv
```

---

## Mixpost Deployment

### Option 1: Docker Deployment (Recommended - 30 mins)

**Prerequisites**:
- Docker Desktop installed (https://www.docker.com/products/docker-desktop)
- Docker Hub account (free)
- 2GB RAM available

**Step 1: Create docker-compose.yml**

```yaml
version: '3.8'

services:
  mixpost-db:
    image: mysql:8.0
    container_name: mixpost_db
    environment:
      MYSQL_ROOT_PASSWORD: rosier_secure_password_here
      MYSQL_DATABASE: mixpost
      MYSQL_USER: mixpost_user
      MYSQL_PASSWORD: mixpost_password
    volumes:
      - mixpost_db_data:/var/lib/mysql
    ports:
      - "3306:3306"
    networks:
      - mixpost_network

  mixpost-app:
    image: inovector/mixpost:latest
    container_name: mixpost_app
    environment:
      APP_NAME: "Rosier Social"
      APP_ENV: production
      APP_DEBUG: "false"
      APP_KEY: "base64:YOUR_RANDOM_KEY_HERE"
      LOG_CHANNEL: single
      DB_CONNECTION: mysql
      DB_HOST: mixpost-db
      DB_PORT: 3306
      DB_DATABASE: mixpost
      DB_USERNAME: mixpost_user
      DB_PASSWORD: mixpost_password
      CACHE_DRIVER: file
      QUEUE_CONNECTION: sync
      SESSION_DRIVER: file
    ports:
      - "8000:80"
    depends_on:
      - mixpost-db
    volumes:
      - mixpost_app_data:/var/www/html/storage
    networks:
      - mixpost_network
    command: >
      sh -c "php artisan migrate --force &&
             php artisan serve --host=0.0.0.0"

volumes:
  mixpost_db_data:
  mixpost_app_data:

networks:
  mixpost_network:
```

**Step 2: Deploy**

```bash
# 1. Navigate to your Rosier project directory
cd ~/Rosier_Content

# 2. Create docker-compose.yml file with above content
# Save as: docker-compose.yml

# 3. Generate APP_KEY
# Replace "YOUR_RANDOM_KEY_HERE" with:
docker run --rm inovector/mixpost php artisan key:generate --show

# 4. Update docker-compose.yml with generated key

# 5. Start containers
docker-compose up -d

# 6. Initialize database
docker-compose exec mixpost-app php artisan migrate

# 7. Create admin user
docker-compose exec mixpost-app php artisan tinker
# In tinker shell:
# App\Models\User::create(['email' => 'admin@rosier.com', 'password' => bcrypt('secure_password')])
# exit

# 8. Access Mixpost at http://localhost:8000
```

**Step 3: Connect Instagram & TikTok**

In Mixpost UI (http://localhost:8000):

1. Login with your admin credentials
2. Navigate to **Accounts → Add Account**
3. Select **Instagram**:
   - Authorize via Facebook Login
   - Grant permissions for business account management
   - Account will appear in dashboard
4. Select **TikTok**:
   - Currently requires Business API setup (not available for personal accounts)
   - Workaround: Schedule TikTok content separately, post manually
   - Future: TikTok will add official scheduling API

**Alternative**: Use Railway.app (simpler deployment)

```bash
# 1. Visit https://railway.app
# 2. Create account (free tier available)
# 3. Deploy using this one-click button:
# https://railway.app/new/github/inovector/mixpost

# 4. Configure environment variables in Railway dashboard
# 5. Access via Railway-provided URL

# Cost: Free tier covers hobby projects
# Paid tier: $5/month (includes custom domain)
```

### Option 2: Manual Installation (Advanced)

```bash
# 1. Clone Mixpost repo
git clone https://github.com/inovector/mixpost.git
cd mixpost

# 2. Install dependencies
composer install
npm install

# 3. Setup environment
cp .env.example .env
php artisan key:generate

# 4. Configure database in .env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=mixpost
DB_USERNAME=root
DB_PASSWORD=

# 5. Run migrations
php artisan migrate

# 6. Start local server
php artisan serve
php artisan queue:listen # in separate terminal

# 7. Access at http://localhost:8000
```

### Mixpost Configuration for Rosier

**After deploying Mixpost**:

1. **Setup Workspace**:
   - Settings → Workspace
   - Name: "Rosier Launch"
   - Timezone: Your timezone (algorithm uses this for posting times)
   - Members: Add team members if applicable

2. **Connect Accounts**:
   - Accounts → Add Account → Instagram
   - Select your Rosier Instagram account
   - Grant permissions via Facebook login
   - Note: TikTok scheduling not yet available via Mixpost; use manual uploads or tiktok-uploader

3. **Setup Scheduling Defaults**:
   - Settings → Publishing
   - Default timezone: Match Instagram timezone
   - Auto-publish: On (if using queue, ensure queue worker running)
   - Post versions: Enable
   - Allow scheduling on Sundays: Off (optional)

4. **Create Content Bucket**:
   - Workspace → New Bucket
   - Name: "Rosier_Weekly_Posts"
   - Description: "Main feed posts and Reels"

---

## Content Workflow

### Daily Content Creation Pipeline

```
MORNING (15 mins)
├─ Check TikTok Discover page for trending audio
├─ Check Instagram Reels for trending formats
├─ Note 3-5 trending sounds/hooks
└─ Save to Trending_Audio_Log.txt

AFTERNOON (60 mins) - CONTENT CREATION
├─ Open CapCut desktop
├─ Batch edit 2-3 short videos (30-45 secs each)
├─ Add trending audio from morning research
├─ Generate captions (CapCut AI feature)
├─ Export as:
│  ├─ TikTok format (1080x1920, .mp4)
│  └─ Instagram Reel format (1080x1920, .mp4)
└─ Move to Ready_to_Upload folder

EVENING (30 mins) - SCHEDULING
├─ Open Mixpost dashboard
├─ Create new post:
│  ├─ Upload video
│  ├─ Write caption (platform-specific versions)
│  ├─ Add hashtags
│  │  ├─ Instagram: 8-15 hashtags (mix mega/mid/niche)
│  │  └─ TikTok: 3-5 hashtags (lower importance)
│  ├─ Schedule for next day optimal time
│  │  ├─ Instagram Reels: Tue-Thu 11 AM-1 PM or 7-9 PM
│  │  └─ TikTok: Wed-Fri 6-9 AM or 6-9 PM
│  └─ Save as draft → Review tomorrow
├─ Respond to comments on previous posts (30 mins)
└─ Send 5-10 influencer DMs (quick outreach)
```

### Weekly Content Batching

**Monday (2 hours)**:
- Plan week's content themes
- Identify 10-15 trending sounds (check TikTok + Instagram)
- Create content calendar (7 posts minimum: 1 per day)
- Identify 5-7 micro-influencers to reach out to

**Tuesday-Wednesday (90 mins)**:
- Batch create content
- Film 10-15 short clips (phone vertical format)
- Edit in CapCut (group similar edits)
- Export to Ready_to_Upload folder

**Thursday (60 mins)**:
- Schedule posts in Mixpost
- Write captions (platform-specific)
- Add hashtags
- Set optimal posting times

**Friday (45 mins)**:
- Monitor engagement on posts
- Respond to comments
- Analyze performance (which content resonated?)

**Weekend (30 mins)**:
- Influencer DM follow-ups
- Community engagement (like/comment on related accounts)
- Planning for next week

### Content Calendar Spreadsheet

Create in Google Sheets (shared with team):

| Date | Platform | Content Type | Concept | Hashtags | Posting Time | Posted? | Engagement |
|------|----------|--------------|---------|----------|--------------|---------|------------|
| Mon 4/1 | Reel | App demo | "Swipe right for style" | #FashionApp #StyleDiscovery | 11 AM | ✓ | 1200 likes |
| Mon 4/1 | TikTok | Founder intro | "Why I built Rosier" | #FashionApp | 6 PM | ✓ | 3500 views |
| Tue 4/2 | Reel | Trending sound | "Can't find outfit?" | #FashionApp | 1 PM | ⏳ | - |
| Tue 4/2 | TikTok | Try-on | "Styling Rosier styles" | #StyleTok | 8 AM | ⏳ | - |

**Tracking metrics**:
- Reach (impressions)
- Engagement rate (% of impressions = engagement)
- Saves (Reels algorithm weight these heavily)
- Shares (highest algorithm value)
- Click-throughs to app (track via bit.ly links)

---

## Automation Triggers

### Instagram Reels Automation via Mixpost

**Scheduled Posts** (Built-in):

1. Create post in Mixpost
2. Schedule for specific date/time
3. Mixpost publishes automatically via Instagram Graph API
4. No action blocks (official API)

**Workflow**:
```
Content Ready → Mixpost Draft → Schedule Time → Auto-Publish
```

### TikTok Upload Automation (Advanced)

⚠️ **WARNING**: TikTok actively detects automation. Use with extreme caution.

**Option 1: Manual Daily Upload (RECOMMENDED)**

```
CapCut Export → TikTok App Upload → Manual post
Time: 5 minutes per video
Risk: Zero
```

**Option 2: tiktok-uploader CLI (MODERATE RISK)**

Setup (one-time):

```bash
# 1. Install Python 3.10+
# https://www.python.org/downloads/

# 2. Install tiktok-uploader
pip install tiktok-uploader

# 3. Install Playwright
python -m playwright install

# 4. Create video list file (videos.txt)
# Format: /path/to/video1.mp4|Caption for video 1
# Example:
# /Users/rosier/Content/video1.mp4|Found my style in Rosier! #FashionApp #StyleDiscovery
# /Users/rosier/Content/video2.mp4|Outfit of the day using Rosier swipe feature
```

**First-time login**:

```bash
# 1. Run uploader (first time)
python -m TikTokApi upload --videos videos.txt --email your@email.com --password yourpassword

# 2. Complete TikTok login in browser window
# 3. Authorize device
# 4. System saves auth cookies for future use
```

**Daily automated upload** (create cron job):

```bash
# macOS/Linux: Create daily upload script
# Save as ~/upload_tiktok.sh

#!/bin/bash
cd ~/Rosier_Content
# Only upload if video is ready (modified in last 24 hours)
find ./02_TikTok/Ready_to_Upload -name "*.mp4" -type f -mtime -1 | while read video; do
  caption=$(head -n 1 "${video}.txt")  # Read caption from .txt file
  python -m TikTokApi upload --videos "$video|$caption"
  sleep 86400  # Wait 24 hours between uploads
done

# Make executable
chmod +x ~/upload_tiktok.sh

# Add to crontab for daily execution
crontab -e
# Add line: 0 20 * * * ~/upload_tiktok.sh
# (Runs at 8 PM daily)
```

**Windows alternative** (Task Scheduler):

```powershell
# 1. Create PowerShell script: upload_tiktok.ps1

$videoFolder = "C:\Users\YourName\Rosier_Content\02_TikTok\Ready_to_Upload"
$readyVideos = Get-ChildItem -Path $videoFolder -Filter "*.mp4" | Where-Object { (Get-Date) - $_.LastWriteTime -lt 1 }

foreach ($video in $readyVideos) {
  $caption = Get-Content -Path "$($video.FullName).txt" -First 1
  python -m TikTokApi upload --videos "$($video.FullName)|$caption"
  Start-Sleep -Seconds 86400  # 24 hour delay
}

# 2. Open Task Scheduler
# 3. Create task:
#    - Trigger: Daily at 8 PM
#    - Action: Run PowerShell script
```

**IMPORTANT SAFETY RULES**:
- [ ] Max 1 upload per 24 hours
- [ ] Never upload during account's peak hours (avoid detection)
- [ ] Use established account (30+ days old, 100+ followers)
- [ ] Phone number verified on account
- [ ] Geographic consistency (upload from same location IP)
- [ ] Space uploads evenly (not back-to-back)
- [ ] Stop immediately if account gets action block warning

### n8n Workflow Automation (Advanced Optional)

For sophisticated workflows (trending audio → auto-schedule):

**Setup**:

```bash
# 1. Self-host n8n
docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n

# 2. Access at http://localhost:5678

# 3. Create workflow:
#    Trigger: Daily (2 PM)
#    ├─ Get TikTok trending sounds (HTTP request)
#    ├─ Filter for fashion niche
#    ├─ Alert you via email/Slack: "Trending sound detected"
#    └─ Store in Google Sheets
```

**Node setup** (visual workflow):

```
Daily Trigger
  ↓
[HTTP] Call TikTok API for trending
  ↓
[Code] Filter sounds by engagement/niche
  ↓
[Email] Send alert with sound info
  ↓
[Google Sheets] Log trending sounds
  ↓
[Manual Step] You create content using sounds
  ↓
[Mixpost] Schedule post when ready
```

This saves 30 minutes daily on trend research.

---

## Monitoring & Alerts

### Daily Metrics Tracking

Create Google Sheets dashboard:

```
Sheet 1: Daily Metrics
┌─────────┬────────┬───────────┬──────────┬─────────┐
│ Date    │ Reach  │ Engagement│ Saves    │ DM Rate │
├─────────┼────────┼───────────┼──────────┼─────────┤
│ 4/1 Reel│ 12,500 │ 1,200 (9%)│ 450      │ 35      │
│ 4/1 TT  │ 8,300  │ 3,500 (42%)│ 1,200   │ 62      │
└─────────┴────────┴───────────┴──────────┴─────────┘

Sheet 2: Weekly Analysis
├─ Total Reach
├─ Avg Engagement Rate
├─ Best Performing Content (by saves/shares)
├─ Influencer Outreach Response Rate
└─ Estimated App Downloads (via UTM tracking)

Sheet 3: Content Performance
├─ Content Type | Format | Hook | Engagement Rate | Saves
├─ Trending Audio | Reel | "POV" | 12% | 450
├─ Try-On | TikTok | "Unboxing" | 28% | 1,200
└─ App Demo | Reel | "Problem-Solution" | 8% | 320
```

### Weekly Check-In

**Every Friday (30 mins)**:

1. Download analytics from Instagram Insights + TikTok Creator Center
2. Update Google Sheets
3. Identify top 3 performing content types
4. Note: What hooks, audio, and timing worked best?
5. Plan next week emphasizing winners
6. Check for action blocks or warnings

### Monthly Deep Dive

**First Friday of month (1 hour)**:

1. Calculate metrics:
   - Total impressions
   - Total engagement rate
   - App downloads (via UTM params in bit.ly)
   - Cost per download ($0 organic, compare to paid benchmarks)
   - Follower growth rate (should be 10-20% monthly at launch)

2. Identify trends:
   - Which content formats convert best?
   - Which hashtags drive reach?
   - What times post best?
   - Which influencers drive actual engagement?

3. Update strategy for next month

---

## Troubleshooting

### Mixpost Issues

**Problem: Docker containers won't start**

```bash
# Check logs
docker-compose logs -f mixpost-app

# Common fixes:
# 1. Port 8000 already in use
docker-compose down
# Change port in docker-compose.yml: "8001:80"

# 2. Database permission error
docker-compose down
docker volume rm mixpost_db_data  # Careful: deletes data
docker-compose up -d

# 3. Out of memory
# Allocate more RAM to Docker Desktop
# Docker icon → Preferences → Resources → Memory: 4GB minimum
```

**Problem: Instagram authorization fails**

```
Error: "Invalid OAuth redirect URI"
→ In Mixpost settings, verify callback URL matches Facebook app settings
→ Facebook App → Settings → Basic → App Domains
→ Add: localhost:8000 (for local) or your-domain.com (for production)
```

**Problem: Posts not publishing automatically**

```bash
# Check queue worker is running
docker-compose logs -f | grep queue

# If missing, manually start:
docker-compose exec mixpost-app php artisan queue:listen

# Or configure cron job to process queued jobs
docker-compose exec mixpost-app php artisan schedule:run
# Run every minute via crontab
```

### Instagram Issues

**Problem: Shadowban suspicion**

Check if posts appear in hashtags:
1. Search 3-5 of your hashtags
2. Look for your recent posts in results
3. If missing: You may be shadowbanned

Recovery:
```
1. Stop all automated activity immediately
2. Switch to 100% manual engagement for 1 week
3. Post only 1-2 times per day (not 2-3 times)
4. Manually like 50-100 posts from relevant accounts daily
5. Leave 5-10 meaningful comments daily
6. Wait 7-14 days; re-check hashtags
```

**Problem: Action block**

Error: "Action Blocked - Please try again later"

Recovery:
```
1. Stop all posting/liking/commenting immediately
2. Don't try to bypass (makes it worse)
3. Wait 24-48 hours
4. Then resume with 50% reduced activity
5. If persists >5 days: Switch to secondary account or contact support
```

### TikTok Issues

**Problem: tiktok-uploader authentication failed**

```bash
# Solution 1: Clear saved credentials
rm -rf ~/.TikTok-Api

# Solution 2: Re-authenticate manually
python -m TikTokApi auth --email your@email.com --password yourpassword

# Solution 3: Update library (may be API change)
pip install --upgrade tiktok-uploader
```

**Problem: Videos fail to upload; "Invalid format"**

```bash
# Ensure video format correct:
# - Codec: H.264
# - Resolution: 1080x1920 (vertical)
# - Frame rate: 30fps
# - Duration: 15 seconds to 10 minutes
# - File size: <287.6 MB

# Re-encode with FFmpeg:
ffmpeg -i input.mp4 -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k -vf scale=1080:1920 -r 30 output.mp4
```

**Problem: TikTok blocks account for automated uploads**

```
⚠️ MANUAL ONLY RECOVERY REQUIRED

1. Stop all automated uploads immediately
2. Don't use tiktok-uploader for 30 days
3. Post manually 1-2 times per week for 1 month
4. After 30 days, try again sparingly (max 1 per week)
5. Better: Accept manual upload (5 mins/day) as safer approach
```

### Email Alerts for Automation Failures

Configure via n8n or Zapier (free tier):

```
If: Mixpost post fails to publish
Then: Send email alert

If: Action block detected on Instagram
Then: Send urgent Slack notification

If: TikTok uploader fails
Then: Send SMS alert (pay close attention to TikTok)
```

---

## Content Posting Checklist

Before every post:

- [ ] Video quality: 1080x1920, no watermarks, clear audio
- [ ] Captions: Keywords in first 3 words, hooks in first 2 seconds
- [ ] Hashtags: Mix mega/mid/niche (Instagram); 3-5 only (TikTok)
- [ ] CTA: Link in bio or DM clear, not pushy
- [ ] Timing: Scheduled for optimal hour (Tue-Thu 11 AM-1 PM for Reels)
- [ ] Trending: Uses trending audio relevant to fashion niche
- [ ] Uniqueness: Not copying competitor content directly
- [ ] Caption tone: Brand voice consistent, not overly promotional
- [ ] Comments prepared: 3-5 replies ready for likely comments
- [ ] Monitoring set: Alert ready if post flops (save as draft, don't publish next one same topic)

---

## Success Metrics

**Week 1-2 (Launch)**:
- 2-3 Reels per day
- 2-3 TikToks per day
- 10-15 influencer DMs sent
- Expected reach: 50K impressions
- Expected app downloads: 100-200

**Week 3-4 (Growth)**:
- Same posting frequency
- 5 micro-influencer partnerships activated
- Expected reach: 150K impressions
- Expected app downloads: 300-500

**Month 2 (Scale)**:
- Increase to 2-3 Reels + 1 carousel post per day
- Increase to 3-4 TikToks per day
- 10-15 active influencer partnerships (ongoing)
- Expected reach: 300K+ impressions
- Expected app downloads: 500-1000/month
- Monthly cost: $0 (all organic)

---

## Quick Command Reference

```bash
# Docker
docker-compose up -d              # Start services
docker-compose down               # Stop services
docker-compose logs -f            # View logs
docker-compose exec mixpost-app php artisan migrate  # Run migrations

# TikTok uploader
python -m TikTokApi upload --videos videos.txt      # Upload from list
pip install --upgrade tiktok-uploader               # Update library

# FFmpeg video encoding
ffmpeg -i input.mp4 -vf scale=1080:1920 -c:v libx264 -c:a aac output.mp4

# Cron job (Mac/Linux daily 8 PM execution)
crontab -e
# Add: 0 20 * * * /usr/local/bin/python /path/to/upload_script.py
```

---

**Document version**: 1.0
**Setup status**: Production-ready
**Last updated**: April 2026
**Questions?** Contact Dev 3 @ Rosier Growth Team
