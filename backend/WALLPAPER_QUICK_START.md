# Wallpaper System Quick Start Guide

## For Developers Integrating the Wallpaper System

### Quick File Reference

| Component | File Path | What It Does |
|-----------|-----------|--------------|
| **Models** | `app/models/wallpaper.py` | WallpaperHouse, WallpaperPattern, WallpaperImpression |
| **Service** | `app/services/wallpaper_service.py` | Business logic (pattern selection, rotation, analytics) |
| **API** | `app/api/v1/endpoints/wallpaper.py` | REST endpoints (user + admin) |
| **Schemas** | `app/schemas/wallpaper.py` | Pydantic validation models |
| **Migration** | `migrations/versions/003_add_wallpaper_tables.py` | Database schema |
| **Seed** | `scripts/seed_wallpaper_data.py` | Initial data (4 houses, 16 patterns) |

### Getting Started

#### 1. Run Database Migration
```bash
cd /path/to/rosier/backend
alembic upgrade head  # Creates 3 new tables
```

#### 2. Load Seed Data
```bash
python scripts/seed_wallpaper_data.py
# Creates 4 houses and 16 patterns with full configuration
```

#### 3. Test User Endpoint
```bash
# Get current wallpaper for authenticated user
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/wallpaper/current

# Returns pattern config with colors, opacity, asset key
```

#### 4. Test Recording Impression
```bash
# Record a wallpaper view
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pattern_id": "your-pattern-uuid",
    "dwell_ms": 3500,
    "swipe_position": 15
  }' \
  http://localhost:8000/api/v1/wallpaper/impression
```

### Common Integration Points

#### In Card Queue Service
```python
# When serving cards to user, include wallpaper pattern
from app.services import WallpaperService

pattern = await WallpaperService.get_pattern_for_user(db, user_id)
# Include pattern in card response
card_response = {
    "cards": [...],
    "wallpaper": pattern  # Add to response
}
```

#### In Swipe Events
```python
# After ~50 swipes, rotate to next pattern
swipe_count = await get_user_swipe_count(db, user_id)
if swipe_count % 50 == 0:
    new_pattern = await WallpaperService.rotate_pattern(db, user_id)
    # Notify client of pattern change

# When swipe completes, record impression
await WallpaperService.record_impression(
    db,
    user_id,
    pattern_id,
    dwell_ms=dwell_time,
    swipe_position=card_position
)
```

#### In Admin Dashboard
```python
# View analytics for a house
analytics = await WallpaperService.get_house_analytics(
    db,
    house_id,
    days=30
)
# {
#   "total_impressions": 45230,
#   "unique_viewers": 8942,
#   "avg_dwell_ms": 2847.5,
#   "monthly_fee": 25000.0
# }
```

### Key Concepts

#### Style Archetypes
Users are classified into 8 style archetypes. Each maps to a preferred wallpaper house:
```python
ARCHETYPE_TO_HOUSES = {
    "Minimalist with Edge": ["Phillip Jeffries"],
    "Quiet Luxury": ["de Gournay"],
    "Eclectic Maximalist": ["Schumacher"],
    "Street-Meets-Runway": ["Scalamandr é"],
    "Romantic Bohemian": ["de Gournay"],
    "Modern Minimalist": ["Phillip Jeffries"],
    "Vintage Inspired": ["de Gournay"],
    "Sporty Chic": ["Phillip Jeffries"],
}
```

#### New Users (No Archetype Yet)
If user hasn't completed onboarding, use discovery rotation:
```python
DISCOVERY_HOUSES = ["de Gournay", "Phillip Jeffries", "Schumacher", "Scalamandr é"]
# Cycles through all houses fairly
```

#### Pattern Selection Logic
1. Get user's archetype from Style DNA
2. Find preferred house(s)
3. Query all active patterns from house
4. Weight by `display_priority`
5. Boost sponsorship status (active partners get +priority)
6. Random selection weighted by priority
7. Apply theme colors (light/dark)

#### Impression Tracking
Every time a user sees a wallpaper:
1. Record to `wallpaper_impressions` table
2. Increment house `impression_count`
3. Track dwell time (milliseconds viewed)
4. Store swipe position (for sequencing analysis)

### API Response Examples

#### GET /api/v1/wallpaper/current
```json
{
  "pattern_id": "abc123-def456",
  "pattern_name": "Bamboo Garden",
  "pattern_type": "chinoiserie",
  "house_id": "house123",
  "house_name": "de Gournay",
  "description": "Hand-painted chinoiserie with delicate bamboo...",
  "primary_color": "#F5F1E8",
  "secondary_color": "#2C3E50",
  "opacity": 0.20,
  "asset_key": "wallpaper/de-gournay/bamboo-garden.png",
  "website_url": "https://www.degournay.com",
  "logo_url": "https://www.degournay.com/logo.png"
}
```

#### POST /api/v1/wallpaper/impression
Request:
```json
{
  "pattern_id": "abc123-def456",
  "dwell_ms": 3500,
  "session_id": "session-2026-04-01-user123",
  "swipe_position": 15
}
```
Response:
```json
{
  "status": "recorded"
}
```

#### GET /api/v1/admin/wallpaper/analytics/houses/{house_id}
```json
{
  "house_id": "house123",
  "house_name": "de Gournay",
  "total_impressions": 45230,
  "unique_viewers": 8942,
  "avg_dwell_ms": 2847.5,
  "partnership_status": "active",
  "monthly_fee": 25000.0,
  "period_days": 30
}
```

### Wallpaper Houses (Pre-Seeded)

| Name | Style | Patterns | Status | Monthly Fee |
|------|-------|----------|--------|------------|
| de Gournay | Chinoiserie & Classic | 4 | ACTIVE | $25,000 |
| Phillip Jeffries | Textural & Natural | 4 | Prospect | $15,000 |
| Schumacher | Bold Prints | 4 | Prospect | $20,000 |
| Scalamandr é | Zoological & Luxury | 4 | ACTIVE | $30,000 |

### Pattern Types

- **Chinoiserie**: Hand-painted Asian-inspired designs
- **Textural**: Natural fiber and texture focus
- **Bold Print**: High-contrast geometric and floral patterns
- **Zoological**: Animal and wildlife motifs
- **Floral**: Botanical and flower patterns
- **Geometric**: Abstract and geometric designs

### Common Queries

#### Check if user has archetype
```python
style_dna = await StyleDNAService.get_or_compute_style_dna(db, user_id)
archetype = style_dna.get("archetype")
if archetype:
    # Use archetype mapping
else:
    # Use discovery rotation
```

#### Get total impressions for reporting
```python
analytics = await WallpaperService.get_house_analytics(db, house_id, days=30)
print(f"House: {analytics['house_name']}")
print(f"Impressions: {analytics['total_impressions']}")
print(f"Unique viewers: {analytics['unique_viewers']}")
print(f"Avg engagement: {analytics['avg_dwell_ms']}ms")
```

#### Update partnership status
```python
# When closing a deal with a partner
curl -X PATCH \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "partnership_status": "active",
    "monthly_fee": 35000.0,
    "contract_start": "2026-04-01T00:00:00Z",
    "contract_end": "2027-04-01T00:00:00Z"
  }' \
  http://localhost:8000/api/v1/admin/wallpaper/houses/{house_id}
```

### Troubleshooting

#### "No active wallpaper patterns available"
- Check that wallpaper_houses and wallpaper_patterns tables are populated
- Verify `is_active = true` for both house and pattern
- Run seed script: `python scripts/seed_wallpaper_data.py`

#### User gets wrong wallpaper house
- Check Style DNA archetype computation
- Verify ARCHETYPE_TO_HOUSES mapping matches archetype
- For new users, confirm discovery rotation is working

#### Impression counts not updating
- Verify wallpaper_impressions table is being written to
- Check database connection in swipe event handler
- Ensure `record_impression()` is being called during swipes

#### Admin analytics showing zeros
- Check created_at timestamps on impressions (timezone aware?)
- Verify date filtering in get_house_analytics()
- Ensure enough time has passed since impressions recorded

### Next Steps

1. **Integrate with Card Queue** - Include wallpaper in card responses
2. **Trigger Pattern Rotation** - Call rotate_pattern() every 50 swipes
3. **Record Impressions** - Call record_impression() on swipe completion
4. **Admin Dashboard** - Display analytics from `/admin/wallpaper/analytics`
5. **Partner Onboarding** - Use POST `/admin/wallpaper/houses` to add partners

### Documentation References

- **Full System Design:** `WALLPAPER_SYSTEM.md`
- **Implementation Checklist:** `WALLPAPER_IMPLEMENTATION_CHECKLIST.md`
- **Code Files:** See table above
