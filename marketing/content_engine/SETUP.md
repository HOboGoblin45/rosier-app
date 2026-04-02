# Rosier Content Engine - Setup Guide

Complete step-by-step setup for the automated content generation pipeline.

**Estimated setup time**: 15-20 minutes

---

## Prerequisites

- Python 3.10+
- pip package manager
- Rosier backend API running (for live data)
- Mixpost instance (optional, for auto-scheduling)

---

## Installation Steps

### Step 1: Install Python Dependencies

Navigate to the content engine directory:

```bash
cd /path/to/rosier/marketing/content_engine
```

Install all dependencies:

```bash
pip install -r requirements.txt --break-system-packages
```

**Why `--break-system-packages`?**
This flag is needed to install Pillow globally on some systems. If you encounter issues, use a virtual environment instead:

```bash
# Alternative: Use virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Step 2: Verify Installation

Test that all dependencies are working:

```bash
# Test imports
python3 -c "from PIL import Image; print('✓ Pillow')"
python3 -c "import requests; print('✓ Requests')"
python3 -c "import schedule; print('✓ Schedule')"
python3 -c "import jinja2; print('✓ Jinja2')"

# All should print ✓ module_name
```

Test that Pillow can generate images:

```bash
python3 -c "
from PIL import Image
img = Image.new('RGB', (1080,1080), '#1A1A2E')
print('✓ Image generation works')
"
```

### Step 3: Configure Rosier API Connection

Edit `auto_post.py` and update the API base URL to point to your Rosier backend:

```python
def _load_config(self, config_path: Optional[str]) -> Dict:
    """Load configuration from file or use defaults"""
    return {
        'api_base': 'http://localhost:3000/api',  # ← Change this
        'mixpost_url': 'http://localhost:8000',
        ...
    }
```

Or create a `.env` file (recommended):

```bash
cat > .env << 'EOF'
ROSIER_API_BASE=http://localhost:3000/api
ROSIER_API_KEY=your_api_key_here
MIXPOST_URL=http://localhost:8000
MIXPOST_ENABLED=true
EOF
```

### Step 4: Test Content Generation Locally

Run the content generator to verify it works:

```bash
python3 content_generator.py
```

**Expected output**:
```
Platform: instagram
Type: trending
Caption:
Fashion is moving. Here's proof:

Ganni is your #1 most-swiped brand this week
Deiji Studios broke into top 5 overnight
Khaite is the dark horse everyone's sleeping on

Download Rosier. Stay ahead. #rosierapp #fashiondiscovery...

Hashtags: #rosierapp, #fashiondiscovery, #swipestyle...
Posting time: 11:00
```

### Step 5: Test Image Generation

Generate test images:

```bash
python3 image_generator.py
```

**Expected output**:
```
Created trending card: /tmp/trending_test.png
Created spotlight: /tmp/spotlight_test.png
Created style DNA card: /tmp/style_dna_test.png

All test images created successfully!
```

Verify images were created:

```bash
ls -lah /tmp/*test*.png
# Should show 3 PNG files, each 30-50KB
```

### Step 6: Test Content Scheduling

Generate a content calendar:

```bash
python3 scheduler.py
```

**Expected output**:
```
Optimal Instagram Reel times (next 7 days): 7 slots
  - 2026-04-02 11:00:00
  - 2026-04-02 14:00:00
  - ...

Generated 7-day content calendar:
  2026-04-02: instagram_reel - trending
  2026-04-03: tiktok - app_demo
  ...

Exported to /tmp/schedule.json and /tmp/schedule.csv
```

### Step 7: Test Full Pipeline

Run the complete auto-posting pipeline:

```bash
python3 auto_post.py
```

**Expected output**:
```
2026-04-01 23:12:16 - AutoPostingPipeline - INFO - Starting Rosier AutoPosting Pipeline
2026-04-01 23:12:16 - AutoPostingPipeline - INFO - Fetching app data from Rosier API...
2026-04-01 23:12:16 - AutoPostingPipeline - INFO - Generating daily content...
2026-04-01 23:12:16 - AutoPostingPipeline - INFO - Generated 5 posts total
2026-04-01 23:12:16 - AutoPostingPipeline - INFO - Generating images...
2026-04-01 23:12:16 - AutoPostingPipeline - INFO - Generated 5 images
2026-04-01 23:12:16 - AutoPostingPipeline - INFO - Scheduling posts...
2026-04-01 23:12:16 - AutoPostingPipeline - INFO - AutoPosting Pipeline completed successfully
```

### Step 8: Verify Output Files

Check that all output files were created:

```bash
ls -lah /tmp/rosier_content/
```

**Expected files**:
- `20260401_*.png` — 5 generated images (trending card, brand spotlight, etc)
- `schedule_today.json` — Schedule in JSON format (for Mixpost API)
- `schedule_today.csv` — Schedule in CSV format (for spreadsheets)
- `mixpost_schedule.json` — Mixpost-formatted schedule

Example:
```
-rw-r--r-- 44K Apr 01 23:12 20260401_231216_0_trending_card.png
-rw-r--r-- 33K Apr 01 23:12 20260401_231216_1_brand_spotlight.png
-rw-r--r-- 51K Apr 01 23:12 20260401_231216_2_style_archetype_card.png
-rw-r--r-- 46K Apr 01 23:12 20260401_231216_3_daily_drop_card.png
-rw-r--r-- 49K Apr 01 23:12 20260401_231216_4_price_drop_card.png
-rw-r--r--  295 Apr 01 23:12 mixpost_schedule.json
-rw-r--r--  142 Apr 01 23:12 schedule_today.csv
-rw-r--r--  297 Apr 01 23:12 schedule_today.json
```

---

## Setup Daily Automation (Cron)

### Step 1: Make Script Executable

```bash
chmod +x /path/to/rosier/marketing/content_engine/auto_post.py
```

### Step 2: Create Cron Job

Open crontab editor:

```bash
crontab -e
```

Add this line to run daily at 6 AM EST:

```bash
0 6 * * * /usr/bin/python3 /path/to/rosier/marketing/content_engine/auto_post.py >> /tmp/rosier_autopost.log 2>&1
```

**Note**: Adjust the path to match your actual installation path.

### Step 3: Verify Cron Job

Check that the job was added:

```bash
crontab -l
```

You should see your new line in the output.

### Step 4: Monitor Cron Execution

Check the log file to verify execution:

```bash
# View logs from today
tail -50 /tmp/rosier_autopost.log

# Watch logs in real-time
tail -f /tmp/rosier_autopost.log
```

After 6 AM the next day, you should see:
```
2026-04-02 06:00:15 - AutoPostingPipeline - INFO - Starting Rosier AutoPosting Pipeline
2026-04-02 06:00:15 - AutoPostingPipeline - INFO - Fetching app data from Rosier API...
...
```

---

## Integration with Mixpost

### Option 1: Manual Upload (Simplest)

1. Run `auto_post.py` (manually or via cron)
2. Generated files appear in `/tmp/rosier_content/`
3. In Mixpost UI: Dashboard → Import → Upload `schedule_today.json`
4. Review and publish posts

### Option 2: API Integration (Advanced)

The system exports to Mixpost JSON format automatically. To connect to Mixpost API:

1. Get Mixpost API token:
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@rosier.com","password":"secure_password"}'
```

2. Update `auto_post.py` to POST to Mixpost:
```python
# Add to exports section
response = requests.post(
    'http://localhost:8000/api/posts',
    headers={'Authorization': f'Bearer {mixpost_token}'},
    json=mixpost_payload
)
```

---

## Configuration Details

### Output Directory

By default, generated content goes to `/tmp/rosier_content/`. To change:

Edit `auto_post.py`:
```python
self.output_dir = Path('/your/custom/path')
```

Or set in config:
```json
{
  "output_dir": "/home/rosier/content/staging"
}
```

### Posting Times

Adjust optimal posting times in `scheduler.py`:

```python
OPTIMAL_TIMES = {
    'instagram_reel': {
        'primary': [
            (11, 0),      # 11 AM EST
            (14, 0),      # 2 PM EST
            (19, 0),      # 7 PM EST
        ]
    },
    'tiktok': {
        'primary': [
            (7, 0),       # 7 AM EST
            (12, 0),      # 12 PM EST
            (19, 0),      # 7 PM EST
            (22, 0),      # 10 PM EST
        ]
    }
}
```

### Branding Colors

Update brand colors in `image_generator.py`:

```python
COLORS = {
    'primary': '#1A1A2E',      # Dark navy
    'accent': '#C4A77D',       # Gold
    'surface': '#F8F6F3',      # Off-white
    'text': '#FFFFFF',
    'text_dark': '#1A1A2E',
    'divider': '#E8E6E1',
}
```

---

## Troubleshooting

### Issue: "No module named 'PIL'"

**Solution**:
```bash
pip install --force-reinstall Pillow --break-system-packages
```

### Issue: "Cannot connect to API"

**Solution**:
1. Check Rosier backend is running:
```bash
curl http://localhost:3000/api/health
```

2. Update API base URL in `auto_post.py`

3. Check firewall isn't blocking connection:
```bash
nc -zv localhost 3000
```

### Issue: "Font not found" when generating images

**Solution**: Install system fonts:
```bash
# macOS
brew install font-roboto

# Linux
sudo apt-get install fonts-dejavu fonts-liberation

# Windows
# Download and install Arial.ttf from Microsoft
```

### Issue: Cron job not running

**Solution**:
1. Check crontab syntax:
```bash
crontab -e  # Verify your line is correct
```

2. Check cron service is running:
```bash
sudo systemctl status cron  # Linux
sudo launchctl list | grep cron  # macOS
```

3. Test script manually:
```bash
python3 /path/to/auto_post.py
```

4. Check system logs:
```bash
sudo journalctl -u cron --since today  # Linux
log stream --predicate 'process == "cron"'  # macOS
```

### Issue: Images look bad quality

**Solution**: Check Pillow installation:
```bash
python3 -c "from PIL import Image; Image.new('RGB', (1080,1080)).save('/tmp/test.png'); print('OK')"
```

If the test image is blurry, reinstall Pillow with system libraries:
```bash
pip uninstall Pillow
pip install Pillow --no-binary :all: --break-system-packages
```

---

## Next Steps

1. **Configure API connection** to your Rosier backend
2. **Test locally** with `python3 auto_post.py`
3. **Setup daily cron job** for automated execution
4. **Connect to Mixpost** for scheduled posting
5. **Monitor performance** with analytics tracker (see `AnalyticsTracker` in README)

---

## Quick Reference

```bash
# Test content generator
python3 content_generator.py

# Test image generation
python3 image_generator.py

# Test scheduling
python3 scheduler.py

# Run full pipeline (manual test)
python3 auto_post.py

# View output files
ls -lah /tmp/rosier_content/

# Check cron logs
tail -50 /tmp/rosier_autopost.log

# View generated images
open /tmp/rosier_content/*.png  # macOS
xdg-open /tmp/rosier_content/*.png  # Linux
```

---

**Setup complete!** Your content engine is ready to generate branded social media content daily.

For detailed usage, see [README.md](README.md).
