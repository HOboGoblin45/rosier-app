# Wallpaper System Documentation

## Overview

The Wallpaper System is a brand partnership module that manages wallpaper pattern assignments, rotations, and analytics for the Rosier app. Wallpaper houses (de Gournay, Phillip Jeffries, Schumacher, Scalamandr é) can become SPONSORS with premium ad placements worth $5K-50K/month.

## Architecture

### Database Models
Located in `/app/models/wallpaper.py`

#### WallpaperHouse
Main brand partnership entity
- **Fields:**
  - `id`: UUID primary key
  - `name`: Unique house name (e.g., "de Gournay")
  - `slug`: URL-friendly identifier
  - `description`: Marketing description
  - `website_url`: House website
  - `logo_url`: Logo asset URL
  - `partnership_status`: Enum (prospect, active, paused, churned)
  - `monthly_fee`: Sponsorship fee in dollars
  - `contract_start`, `contract_end`: Partnership dates
  - `impression_count`: Total impressions for billing
  - `is_active`: Boolean status
  - `created_at`, `updated_at`: Timestamps

**Relationships:**
- `patterns`: One-to-many with WallpaperPattern
- `impressions`: One-to-many with WallpaperImpression

#### WallpaperPattern
Individual wallpaper design patterns
- **Fields:**
  - `id`: UUID primary key
  - `house_id`: Foreign key to WallpaperHouse
  - `name`: Pattern display name
  - `slug`: Unique identifier
  - `description`: Pattern description
  - `pattern_type`: Enum (chinoiserie, textural, bold_print, zoological, floral, geometric)
  - Color schemes for light and dark themes:
    - `primary_color_light/dark`: Hex color codes
    - `secondary_color_light/dark`: Optional accent colors
    - `opacity_light/dark`: Opacity values (0.0-1.0)
  - `style_archetypes`: JSON array of applicable user archetypes
  - `asset_key`: S3 key or local asset path
  - `display_priority`: Integer weight for pattern selection
  - `is_active`: Boolean status
  - `created_at`, `updated_at`: Timestamps

**Relationships:**
- `house`: Many-to-one relationship with WallpaperHouse
- `impressions`: One-to-many with WallpaperImpression

#### WallpaperImpression
Analytics tracking for billing and performance
- **Fields:**
  - `id`: UUID primary key
  - `user_id`: Foreign key to User
  - `pattern_id`: Foreign key to WallpaperPattern
  - `house_id`: Foreign key to WallpaperHouse (denormalized for queries)
  - `session_id`: Optional session identifier
  - `swipe_position`: Position in card queue where wallpaper was shown
  - `dwell_ms`: Time spent viewing in milliseconds
  - `created_at`: Impression timestamp

**Relationships:**
- `pattern`: Many-to-one relationship with WallpaperPattern
- `house`: Many-to-one relationship with WallpaperHouse

### Service Layer
Located in `/app/services/wallpaper_service.py`

#### WallpaperService

**get_pattern_for_user(session, user_id) → dict**
- Returns current wallpaper pattern for user based on style archetype
- Uses ARCHETYPE_TO_HOUSES mapping (defined in service)
- For new users with no archetype, uses DISCOVERY_HOUSES rotation
- Selects pattern with weighted distribution by display_priority
- Boosts selection weight for active partners
- Returns complete pattern config with colors, opacity, asset_key, and house info

**rotate_pattern(session, user_id) → dict**
- Called every ~50 swipes to rotate to a new pattern
- Selects alternative pattern from same house
- Falls back to current pattern if no alternatives available
- Returns new pattern configuration

**record_impression(session, user_id, pattern_id, dwell_ms, session_id=None, swipe_position=0)**
- Records wallpaper view for billing/analytics
- Creates WallpaperImpression record
- Increments house impression_count
- Commits to database

**get_house_analytics(session, house_id, days=30) → dict**
- Retrieves billing metrics for a specific house
- Calculates:
  - Total impressions in period
  - Unique viewer count
  - Average dwell time
  - Partnership status and fee
- Default period: 30 days

**get_pattern_analytics(session, pattern_id, days=30) → dict**
- Retrieves performance metrics for specific pattern
- Similar metrics to house analytics
- Useful for A/B testing patterns

### API Endpoints
Located in `/app/api/v1/endpoints/wallpaper.py`

#### User Endpoints

**GET /api/v1/wallpaper/current** (Authenticated)
```json
Response:
{
  "pattern_id": "uuid-string",
  "pattern_name": "Bamboo Garden",
  "pattern_type": "chinoiserie",
  "house_id": "uuid-string",
  "house_name": "de Gournay",
  "description": "Hand-painted chinoiserie with...",
  "primary_color": "#F5F1E8",
  "secondary_color": "#2C3E50",
  "opacity": 0.20,
  "asset_key": "wallpaper/de-gournay/bamboo-garden.png",
  "website_url": "https://www.degournay.com",
  "logo_url": "https://www.degournay.com/logo.png"
}
```

**POST /api/v1/wallpaper/impression** (Authenticated)
```json
Request:
{
  "pattern_id": "uuid-string",
  "dwell_ms": 3500,
  "session_id": "optional-session-id",
  "swipe_position": 15
}

Response:
{
  "status": "recorded"
}
```

#### Admin Endpoints

**GET /api/v1/admin/wallpaper/houses**
List all wallpaper houses with partnership details

**POST /api/v1/admin/wallpaper/houses**
Create new wallpaper house partnership
```json
Request:
{
  "name": "New House",
  "slug": "new-house",
  "description": "...",
  "website_url": "https://...",
  "logo_url": "https://...",
  "partnership_status": "prospect",
  "monthly_fee": 15000.0,
  "is_active": true
}
```

**PATCH /api/v1/admin/wallpaper/houses/{house_id}**
Update partnership terms
```json
Request:
{
  "partnership_status": "active",
  "monthly_fee": 25000.0,
  "contract_start": "2026-04-01T00:00:00Z",
  "contract_end": "2027-04-01T00:00:00Z"
}
```

**GET /api/v1/admin/wallpaper/analytics/houses/{house_id}?days=30**
House-level analytics for billing

**GET /api/v1/admin/wallpaper/analytics/patterns/{pattern_id}?days=30**
Pattern-level analytics for performance

**GET /api/v1/admin/wallpaper/analytics?days=30**
Aggregated analytics across all houses

### Schema Types
Located in `/app/schemas/wallpaper.py`

Key request/response schemas:
- `WallpaperHouseCreate`, `WallpaperHouseUpdate`, `WallpaperHouseResponse`
- `WallpaperPatternCreate`, `WallpaperPatternUpdate`, `WallpaperPatternResponse`
- `WallpaperCurrentResponse` - User's current pattern
- `WallpaperImpressionRequest` - Record view event
- `WallpaperHouseAnalyticsResponse` - House metrics
- `WallpaperPatternAnalyticsResponse` - Pattern metrics

## Archetype Mapping

The service maps user style archetypes to preferred wallpaper houses:

```
Minimalist Modern → Phillip Jeffries
Eclectic Creative → Schumacher
Classic Refined → de Gournay
Bold Avant-Garde → Scalamandr é
Relaxed Natural → Phillip Jeffries
```

Additional mappings for app archetypes:
- Minimalist with Edge → Phillip Jeffries
- Quiet Luxury → de Gournay
- Eclectic Maximalist → Schumacher
- Street-Meets-Runway → Scalamandr é
- Romantic Bohemian → de Gournay
- Modern Minimalist → Phillip Jeffries
- Vintage Inspired → de Gournay
- Sporty Chic → Phillip Jeffries

## Pattern Selection Logic

1. **Get user's style archetype** from cached Style DNA
2. **Map to preferred house(s)**
   - If archetype exists: use ARCHETYPE_TO_HOUSES mapping
   - If new user (no archetype): use DISCOVERY_HOUSES rotation
3. **Query active patterns** from preferred house(s)
4. **Weight by display_priority** + sponsorship status boost
5. **Random selection** with weighted distribution
6. **Apply theme colors** (light/dark) and opacity
7. **Return complete pattern config**

## Seed Data

Located in `/scripts/seed_wallpaper_data.py`

Pre-configured with:
- **4 Wallpaper Houses**
  - de Gournay: 4 patterns (chinoiserie focus)
  - Phillip Jeffries: 4 patterns (textural focus)
  - Schumacher: 4 patterns (bold prints)
  - Scalamandr é: 4 patterns (zoological focus)

- **16 Total Patterns** with:
  - Authentic descriptions matching house aesthetics
  - Light and dark theme colors
  - Style archetype mappings
  - Display priorities for weighted selection
  - S3 asset keys (placeholder format)

**Partnership Status:**
- de Gournay, Scalamandr é: ACTIVE ($25K-30K/month)
- Phillip Jeffries, Schumacher: PROSPECT

Run seed script:
```bash
python scripts/seed_wallpaper_data.py
```

## Database Migration

Located in `/migrations/versions/003_add_wallpaper_tables.py`

Creates:
- `wallpaper_houses` table
- `wallpaper_patterns` table
- `wallpaper_impressions` table
- Appropriate indexes for queries and foreign keys

## Integration Points

### Style DNA Service
- Uses `StyleDNAService.get_or_compute_style_dna()` to get user archetypes
- Archetype determines preferred wallpaper house
- Falls back to discovery rotation for new users

### User Model
- Wallpaper impressions linked via `user_id` FK
- No direct wallpaper field on User model needed

### Swipe Events
- Pattern rotation triggered at ~50 swipe threshold
- Impression recording happens during swipe session
- Can integrate with card queue service for position tracking

## Configuration

No new environment variables required. All settings hardcoded:
- Pattern rotation threshold: 50 swipes
- Discovery houses: All 4 houses
- Analytics default period: 30 days
- Archetype mappings: Defined in WallpaperService

## Future Enhancements

1. **Dynamic Archetype Weighting**
   - Adjust house preferences based on pattern performance metrics

2. **A/B Testing Framework**
   - Split users into pattern test groups
   - Track conversion metrics per pattern variant

3. **Seasonal Rotation**
   - Automatically retire patterns by season
   - Introduce limited-edition patterns

4. **Personalized Recommendations**
   - ML model to predict pattern preferences from swipe history
   - Beyond simple archetype mapping

5. **Partner Dashboard**
   - Self-service analytics for house partners
   - Real-time impression tracking

6. **Dynamic Pricing**
   - Adjust partnership fees based on impression performance
   - Tiered pricing: CPM-based billing option

## Testing Considerations

- Mock StyleDNAService for archetype tests
- Create test fixtures for each house/pattern type
- Verify impression tracking accuracy
- Test pattern rotation logic (new patterns selected after threshold)
- Validate analytics calculations
- Test theme color application (light/dark)
