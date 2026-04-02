# Rosier Content Engine

Automated content generation pipeline for Rosier's Instagram Reels and TikTok. Generates branded social media content from app data (trending brands, style insights, product drops, price alerts). Zero manual content creation needed after setup.

**Status**: Production-ready | **Last Updated**: April 2026 | **Maintained by**: Dev 2

---

## Overview

The Rosier Content Engine is a Python-based automation system that:

1. **Fetches data** from Rosier backend (trending brands, daily drops, style archetypes, price alerts)
2. **Generates content** (captions, hooks, CTAs) using curated templates
3. **Creates graphics** (Instagram-ready 1080x1080, Stories 1080x1920)
4. **Schedules posts** across platforms with optimal timing
5. **Tracks performance** (engagement, reach, saves) for continuous improvement
6. **Feeds insights back** into content generation (more of what works)

All content maintains Rosier's brand voice:
- Authentic, founder-friendly tone (not corporate)
- Micro-influencer focused (niche > mainstream)
- Luxury minimal aesthetic (sophisticated, never templated)
- Algorithm-optimized (hooks, trending audio, engagement CTAs)

---

## Architecture

```
content_engine/
├── content_generator.py       # Core content generation logic
├── image_generator.py         # PIL/Pillow image creation
├── scheduler.py               # Content scheduling & calendar management
├── analytics_tracker.py       # Performance tracking & insights
├── auto_post.py              # Daily cron-triggered automation
├── templates/
│   ├── instagram_captions.json    # 50+ caption templates
│   ├── tiktok_scripts.json        # 30+ TikTok hook scripts
│   └── hashtag_sets.json          # Optimized hashtag groups
├── requirements.txt           # Python dependencies
└── README.md                  # This file
```

---

## Installation

### 1. Install Python Dependencies

```bash
cd /path/to/rosier/marketing/content_engine

# Install with Pillow (image generation)
pip install -r requirements.txt --break-system-packages

# Test Pillow works
python -c "from PIL import Image; img = Image.new('RGB', (1080,1080), '#1A1A2E'); print('Pillow works')"
```

### 2. Verify Python Environment

```bash
python --version  # Should be 3.10+
python -c "import schedule, jinja2, requests; print('Dependencies OK')"
```

### 3. Configure Rosier API Connection

Edit `auto_post.py` and update the API base URL:

```python
'api_base': 'http://localhost:3000/api',  # Point to your Rosier backend
```

Or create a `config.json`:

```json
{
  "api_base": "https://rosier-api.example.com",
  "output_dir": "/tmp/rosier_content",
  "mixpost_enabled": true,
  "mixpost_url": "http://localhost:8000"
}
```

---

## Core Components

### 1. Content Generator (`content_generator.py`)

Generates captions, hashtags, and CTAs from app data.

**Key Methods**:
- `generate_trending_post()` — "What's trending on Rosier this week"
- `generate_brand_spotlight()` — Feature a specific brand
- `generate_style_dna_post()` — "What's your Style DNA?"
- `generate_daily_drop_teaser()` — New brands/products
- `generate_price_drop_alert()` — Price change notifications
- `generate_weekly_roundup()` — Sunday recap post
- `generate_ugc_prompt()` — User-generated content challenges

**Example Usage**:

```python
from content_generator import RosierContentEngine

engine = RosierContentEngine()

# Generate trending post
post = engine.generate_trending_post({
    'top_brands': [
        {'name': 'Ganni', 'score': 85, 'change': 23},
        {'name': 'Deiji Studios', 'score': 78, 'change': 15},
        {'name': 'Khaite', 'score': 72, 'change': 8}
    ],
    'growth': 23
})

print(post.caption)
print(post.hashtags)
print(post.posting_time)  # '11:00' EST
```

**Caption Templates**:
- 50+ Instagram captions (trending, brand, style, engagement)
- 30+ TikTok scripts (hooks + body + CTAs)
- Hashtag sets organized by content type and platform
- Emoji patterns that match luxury aesthetic

### 2. Image Generator (`image_generator.py`)

Creates branded graphics using PIL/Pillow.

**Key Methods**:
- `create_trending_card()` — 1080x1080 ranking visualization
- `create_brand_spotlight()` — Brand feature card
- `create_style_archetype_card()` — 1080x1920 Style DNA card
- `create_weekly_roundup()` — Weekly trend summary
- `create_price_drop_card()` — Price alert graphic
- `create_daily_drop_preview()` — Daily 5 teaser

**Design Specs**:
- **Colors**: Primary #1A1A2E (dark navy), Accent #C4A77D (gold), Surface #F8F6F3 (off-white)
- **Typography**: Clean, minimal, no generic templates
- **Dimensions**: 1080x1080 (Instagram feed), 1080x1920 (Stories/Reels/TikTok)
- **Aesthetic**: Luxury, sophisticated, professional

**Example Usage**:

```python
from image_generator import RosierImageGenerator

generator = RosierImageGenerator()

# Create trending card
image = generator.create_trending_card(
    brands=['Ganni', 'Deiji Studios', 'Khaite'],
    scores=[85, 78, 72]
)

# Save to file
generator.save_image(image, '/tmp/trending_card.png')
```

### 3. Content Scheduler (`scheduler.py`)

Manages content calendar and optimal posting times.

**Optimal Posting Times** (EST, for women 18-35):
- **Instagram Reels**: 11 AM, 2 PM, 7 PM (Tue-Thu)
- **TikTok**: 7 AM, 12 PM, 7 PM, 10 PM (Wed-Fri)
- **Stories**: 8 AM, 12 PM, 5 PM, 9 PM (Mon-Fri)
- **Feed Posts**: 11 AM, 7 PM (Wed & Fri)

**Key Methods**:
- `get_optimal_times()` — Returns best posting slots for platform
- `create_content_calendar()` — Auto-generates 7-day plan
- `schedule_week()` — Schedules full week of content
- `get_schedule_status()` — Current schedule overview

**Example Usage**:

```python
from scheduler import ContentScheduler

scheduler = ContentScheduler()

# Get next week's optimal times
optimal_times = scheduler.get_optimal_times('instagram_reel', days_ahead=7)
print(optimal_times)  # [datetime, datetime, ...]

# Create content calendar
calendar = scheduler.create_content_calendar(days=7)
for slot in calendar:
    print(f"{slot['date']}: {slot['platform']} - {slot['content_type']}")

# Schedule all posts
scheduler.schedule_week(calendar)
status = scheduler.get_schedule_status()
print(f"Total scheduled: {status['total_scheduled']}")
```

### 4. Analytics Tracker (`analytics_tracker.py`)

Tracks performance and identifies top-performing content.

**Key Methods**:
- `log_post()` — Record newly posted content
- `update_metrics()` — Add engagement data
- `get_top_performing_content_types()` — Content that works
- `get_platform_performance()` — Reach by platform
- `get_optimal_posting_times()` — Best hours by platform
- `generate_daily_report()` — Daily summary
- `generate_weekly_report()` — Weekly deep dive

**Example Usage**:

```python
from analytics_tracker import AnalyticsTracker

tracker = AnalyticsTracker()

# Log a post
tracker.log_post({
    'post_id': '2026-04-01_instagram_reel',
    'platform': 'instagram_reel',
    'content_type': 'trending',
    'caption': 'What\'s trending...'
})

# Update with metrics (next day)
tracker.update_metrics('2026-04-01_instagram_reel', {
    'impressions': 15000,
    'reach': 12500,
    'likes': 1200,
    'comments': 85,
    'shares': 45,
    'saves': 450,
    'clicks': 320
})

# Get insights
top_types = tracker.get_top_performing_content_types(days=7)
report = tracker.generate_weekly_report()
```

### 5. Auto-Posting Script (`auto_post.py`)

Daily cron job that runs the full pipeline.

**Pipeline Flow**:
1. Fetch trending data from Rosier API
2. Generate content (captions, hooks)
3. Create images
4. Schedule posts
5. Export to Mixpost or folder for manual upload
6. Log everything

**Usage**:

```bash
# Run manually (test)
python auto_post.py

# Setup daily cron (6 AM EST)
crontab -e
# Add line:
0 6 * * * /usr/bin/python3 /path/to/auto_post.py >> /tmp/rosier_autopost.log 2>&1

# View logs
tail -f /tmp/rosier_autopost.log
```

---

## Content Types & Examples

### 1. Trending Posts
Shows top 3 trending brands with affinity scores and growth data.

**Example Caption**:
> "What's trending on Rosier this week? Ganni leads with 85% love, followed by Deiji Studios and Khaite. Your taste is showing 👀"

**Image**: Ranking card with brand names, scores, and progress bars

---

### 2. Brand Spotlights
Features a specific brand with growth stats and description.

**Example Caption**:
> "Ganni just hit #1 on Rosier. Here's why: + 23% growth this week, + Favorite among micro-influencers, + Quality over quantity always"

**Image**: Brand name, growth percentage, and stats boxes

---

### 3. Style DNA Posts
Engagement-focused post about personalized style archetypes.

**Example Caption**:
> "Your Style DNA is calling. Swipe through 20 brands in 2 minutes. Watch Rosier learn what you love. Get your personalized Style DNA card. It's disturbingly accurate."

**Image**: 1080x1920 Style DNA card showing archetype + percentage

---

### 4. Daily Drop Teasers
Highlights 5 new products/brands added to app.

**Example Caption**:
> "Daily Drop is live. Today's 5: Ganni — Blazer, Staud — Bag, Nanushka — Jacket, Jacquemus — Top, Reformation — Jean. First 100 to swipe get price alerts."

**Image**: List of brands/products with visual hierarchy

---

### 5. Price Alerts
Urgency-driven posts about price drops on saved items.

**Example Caption**:
> "The Row — Margot Clutch just dropped from $890 to $623. That's 30% off. Rosier users with this saved? Notification just sent. Are you one of them?"

**Image**: Price comparison visual with savings badge

---

### 6. Weekly Roundup
Sunday recap of top trends, brands, and stats.

**Example Caption**:
> "This week on Rosier: 125,400 swipes, 8 new brands discovered, Top brands: Ganni, Deiji Studios, Khaite. Your taste made this. Weekly roundup is live."

**Image**: Stats and top brand list

---

### 7. UGC Prompts
Calls for user-generated content with #MyRosierStyle.

**Example Caption**:
> "Share your Style DNA. Swipe on Rosier. Get your personal style card. Post it to Stories. Tag #MyRosierStyle. Best ones get featured here + in the app."

**Image**: Call-to-action card with hashtag

---

## Template System

### Instagram Captions (`templates/instagram_captions.json`)

```json
{
  "trending": [
    "What's trending on Rosier this week? {brand_1} leads with {score_1}% love...",
    "The brands taking over your Rosier feed right now...",
    ...
  ],
  "brand_spotlight": [...],
  "style_dna": [...],
  "daily_drop": [...],
  "price_alert": [...],
  "engagement": [...],
  "ugc_prompt": [...]
}
```

Each category has 5-7 template variations that randomly select and fill placeholder variables.

### TikTok Scripts (`templates/tiktok_scripts.json`)

```json
{
  "hook_and_reveal": [
    {
      "hook": "This brand is about to take over your feed...",
      "body": "It's {brand}. Rosier data shows...",
      "cta": "Link in bio to discover"
    },
    ...
  ],
  "style_quiz": [...],
  "trend_breakdown": [...],
  "swipe_along": [...],
  "app_demo": [...]
}
```

Each script has hook (first 3 seconds), body (description), and CTA.

### Hashtag Sets (`templates/hashtag_sets.json`)

```json
{
  "core": ["#rosierapp", "#fashiondiscovery", "#swipestyle"],
  "trending": ["#fashiontok", "#outfitinspo", "#stylecheck", ...],
  "brand_spotlight": ["#nichefashion", "#emergingdesigners", ...],
  "style_and_aesthetic": ["#styledna", "#whatsmystyle", ...],
  "engagement": [...],
  "brand_specific": {
    "ganni": ["#ganni", "#gannioutfit", ...],
    "staud": [...],
    ...
  },
  "seasonal": {...},
  "occasion_based": {...}
}
```

Hashtags organized by content type, platform, brand, season, and occasion.

---

## Daily Workflow

### 6 AM EST: Cron Job Runs

```bash
python auto_post.py
```

**Pipeline Output**:
- `/tmp/rosier_content/schedule_today.json` — Scheduled posts (for Mixpost API)
- `/tmp/rosier_content/schedule_today.csv` — Spreadsheet format
- `/tmp/rosier_content/mixpost_schedule.json` — Mixpost API format
- `/tmp/rosier_content/[timestamp]_*.png` — Generated images
- `/tmp/rosier_autopost.log` — Execution log

### 9 AM - 8 PM EST: Posts Go Live

Posts scheduled at optimal times:
- 11 AM: Instagram Reel (trending)
- 12 PM: TikTok (daily demo)
- 2 PM: Instagram Reel (brand spotlight)
- 5 PM: Instagram Story (engagement prompt)
- 7 PM: Instagram Reel (Style DNA)
- 10 PM: TikTok (trending sounds)

### End of Day: Manual Engagement

30 minutes of manual community engagement:
- Respond to comments
- Engage with related accounts
- Monitor brand mentions
- Send micro-influencer DMs

---

## Integration with Mixpost

Rosier Content Engine exports to Mixpost for automatic scheduling.

### Option 1: REST API Integration (Advanced)

```python
import requests

# Get Mixpost auth token
auth = requests.post(
    'http://localhost:8000/api/auth/login',
    json={'email': 'admin@rosier.com', 'password': 'secure_password'}
)

# Schedule post
post_data = {
    'content': 'Caption text',
    'media': ['/path/to/image.png'],
    'platforms': ['instagram_reel'],
    'schedule': '2026-04-01T11:00:00-04:00'
}

requests.post(
    'http://localhost:8000/api/posts',
    headers={'Authorization': f'Bearer {auth.token}'},
    json=post_data
)
```

### Option 2: JSON Import (Simpler)

1. Run `auto_post.py` to generate schedule
2. Export: `schedule_today.json`
3. In Mixpost UI: Dashboard → Import → Select JSON
4. Review and publish

---

## Testing & Quality Assurance

### Test Content Generation

```bash
python content_generator.py
# Output: Sample trending post
```

### Test Image Generation

```bash
python image_generator.py
# Output: Test images at /tmp/*.png
```

### Test Scheduling

```bash
python scheduler.py
# Output: 7-day calendar + schedule metrics
```

### Test Full Pipeline

```bash
python auto_post.py
# Output: Full day's content to /tmp/rosier_content/
```

### Verify Image Quality

```bash
# Check dimensions
identify /tmp/rosier_content/*.png

# View on screen
open /tmp/rosier_content/2026-04-01_*.png
```

---

## Performance Metrics & Optimization

### Track What Works

The `AnalyticsTracker` monitors:
- **Engagement Rate** = (likes + comments + shares) / impressions
- **Save Rate** = saves / impressions (most important for algorithm)
- **Reach Growth** = impressions / followers
- **Click-Through Rate** = clicks to bio / impressions

### Weekly Optimization

Every Friday:

```python
tracker = AnalyticsTracker()
top_types = tracker.get_top_performing_content_types(days=7)
report = tracker.generate_weekly_report()

# Example output:
# "Focus on 'brand_spotlight' content (avg 12.3% engagement).
#  Prioritize instagram_reel for maximum reach."
```

Then adjust next week's content mix based on findings.

### Optimal Times by Analysis

```python
optimal_times = tracker.get_optimal_posting_times('instagram_reel')
# {11: {'avg_engagement': 45, 'engagement_rate': 9.2%},
#  14: {'avg_engagement': 38, 'engagement_rate': 7.8%},
#  19: {'avg_engagement': 52, 'engagement_rate': 10.1%}}
```

---

## Troubleshooting

### Issue: PIL/Pillow Import Error

**Solution**: Reinstall with system packages flag:
```bash
pip install --force-reinstall --no-cache-dir Pillow --break-system-packages
```

### Issue: API Connection Timeout

**Solution**: Check Rosier backend is running:
```bash
curl http://localhost:3000/api/health
# Should return 200 OK
```

### Issue: No Images Generated

**Solution**: Check font availability:
```bash
python -c "from PIL import ImageFont; ImageFont.load_default()"
# Should return without error
```

### Issue: Cron Job Not Running

**Solution**: Check crontab and logs:
```bash
crontab -l  # View all jobs
tail -50 /tmp/rosier_autopost.log  # Check logs
```

### Issue: Mixpost Export Fails

**Solution**: Verify Mixpost is running:
```bash
curl http://localhost:8000
# Should return Mixpost login page
```

---

## Future Enhancements

### Phase 2 (Q2 2026)
- [ ] Dynamic image generation with user photos (brand + user styling)
- [ ] AI-powered caption generation (GPT-4 fine-tuned on Rosier tone)
- [ ] Trending audio auto-integration (fetch trending sounds, match to content)
- [ ] A/B testing framework (split test different captions/images)

### Phase 3 (Q3 2026)
- [ ] Influencer outreach automation (identify micro-influencers, DM templates)
- [ ] UGC aggregation (auto-repost best user content with credit)
- [ ] Real-time sentiment analysis (monitor brand mentions, react to trending conversations)
- [ ] Predictive scheduling (predict best posting times using historical data)

### Phase 4 (Q4 2026)
- [ ] Video generation (auto-create TikTok/Reel videos from product data)
- [ ] Multi-language support (auto-translate captions for other markets)
- [ ] Competitor monitoring (track competitor content, adapt strategy)
- [ ] Attribution modeling (track which content drives most app downloads)

---

## Environment Variables

Create a `.env` file in the project root:

```bash
# Rosier API
ROSIER_API_BASE=http://localhost:3000/api
ROSIER_API_KEY=your_api_key_here

# Mixpost
MIXPOST_URL=http://localhost:8000
MIXPOST_EMAIL=admin@rosier.com
MIXPOST_PASSWORD=secure_password

# Instagram (optional, for advanced features)
INSTAGRAM_USERNAME=rosier_app
INSTAGRAM_PASSWORD=secure_password

# Logging
LOG_LEVEL=INFO
LOG_FILE=/tmp/rosier_content_engine.log
```

---

## Support & Contributions

**Maintainer**: Dev 2 (Rosier Growth Team)
**Questions?** File an issue or contact the growth team Slack channel.

**Contributing**: All PRs welcome. Please test locally with `pytest` before submitting.

```bash
# Run tests
pytest tests/ -v

# Format code
black . && flake8 .
```

---

## License

Proprietary - Rosier Inc. 2026

---

**Last Updated**: April 1, 2026
**Next Review**: April 8, 2026 (post-launch review)
**Version**: 1.0.0-beta
