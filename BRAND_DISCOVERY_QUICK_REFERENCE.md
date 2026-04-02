# Brand Discovery System - Quick Reference Guide

## Database Tables

### brand_candidates
Pipeline for discovering and vetting new brands.

| Column | Type | Purpose |
|--------|------|---------|
| id | UUID | Primary key |
| name | String | Brand name (unique) |
| website | String | Brand website URL |
| instagram | String | Instagram handle |
| price_range_low/high | Float | Price range ($50-$500 ideal) |
| aesthetic_tags | JSON | e.g., ["minimalist", "sustainable"] |
| affiliate_network | Enum | Rakuten, Impact, Awin, Skimlinks, Direct |
| commission_rate | Float | 0.08 = 8% |
| has_ambassador_program | Boolean | Ambassador availability |
| status | Enum | pending, approved, rejected, active, paused |
| fit_score | Float | 0-100, auto-calculated |
| created_at | Datetime | Creation timestamp |

**Indexes**: status, created_at, affiliate_network

---

### brand_discovery_cards
User-facing brand showcase cards.

| Column | Type | Purpose |
|--------|------|---------|
| id | UUID | Primary key |
| brand_id | UUID | FK to brands table |
| brand_name | String | Brand name for display |
| description | String | Brand description |
| logo_url | String | Brand logo |
| aesthetic_tags | JSON | Visual/style tags |
| price_range_low/high | Float | Product price range |
| ambassador_program_url | String | Link to join ambassador program |
| has_ambassador_program | Boolean | If ambassador program exists |
| total_views | Integer | Times shown to users |
| total_likes | Integer | Like reactions |
| total_dislikes | Integer | Dislike reactions |
| total_skips | Integer | Skip reactions |
| status | Enum | active, flagged_for_review, paused |
| is_active | Boolean | Active status |
| created_at | Datetime | Creation timestamp |

**Auto-flagging**: >60% dislikes OR >80% skips
**Boosting**: Products from brands with >70% like rate get boosted in recommendations

**Indexes**: brand_id, status, is_active, created_at

---

### brand_discovery_swipes
Records individual user reactions to brand cards.

| Column | Type | Purpose |
|--------|------|---------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| card_id | UUID | FK to brand_discovery_cards |
| brand_id | UUID | FK to brands |
| action | String | 'like', 'dislike', 'skip' |
| dwell_time_ms | Integer | How long user viewed |
| session_id | String | Session context |
| created_at | Datetime | Timestamp |

**Indexes**: user_id, card_id, brand_id, action, created_at

---

### commissions
Tracks affiliate/commission earnings per sale.

| Column | Type | Purpose |
|--------|------|---------|
| id | UUID | Primary key |
| user_id | UUID | User who clicked |
| product_id | UUID | Product purchased |
| brand_id | UUID | Brand of product |
| retailer_id | UUID | Retailer (affiliate network) |
| product_price | Float | Sale price |
| commission_rate | Float | 0.08 = 8% |
| commission_amount | Float | Calculated amount |
| affiliate_link_used | String | The affiliate link URL |
| click_timestamp | Datetime | When user clicked |
| conversion_timestamp | Datetime | When purchase completed |
| is_pending | Boolean | Awaiting conversion confirmation |
| is_confirmed | Boolean | Conversion confirmed |
| is_rejected | Boolean | Commission rejected |
| rejection_reason | String | Why rejected |
| created_at | Datetime | Record creation |

**Indexes**: user_id, brand_id, product_id, retailer_id, is_pending, is_confirmed, created_at

---

## API Endpoints

### User-Facing Brand Discovery

```
GET /api/v1/brands/discover
→ Returns next random active brand card

POST /api/v1/brands/discover/react
   {
     "card_id": "uuid",
     "action": "like|dislike|skip",
     "dwell_time_ms": 2000,
     "session_id": "optional"
   }
→ Records user reaction

GET /api/v1/brands/trending
→ Returns brands sorted by engagement

GET /api/v1/brands/favorites
→ Returns user's liked brands
```

### Admin Brand Management

```
GET /api/v1/admin/brand-candidates?status_filter=pending
→ List candidates for review

POST /api/v1/admin/brand-candidates
   {
     "name": "Brand Name",
     "website": "https://...",
     "price_range_low": 150,
     "price_range_high": 600,
     "aesthetic_tags": ["minimalist", "sustainable"],
     "affiliate_network": "rakuten",
     "commission_rate": 0.10,
     "has_ambassador_program": true
   }
→ Create new candidate

POST /api/v1/admin/brand-candidates/{id}/approve
→ Move to approved status

POST /api/v1/admin/brand-candidates/{id}/activate
   ?brand_id=uuid
→ Activate (create discovery card)

POST /api/v1/admin/brand-candidates/{id}/reject
   ?reason="Too expensive"
→ Reject with reason
```

### Admin Brand Discovery Card Management

```
GET /api/v1/admin/brand-discovery-cards?status_filter=flagged_for_review
→ List discovery cards

POST /api/v1/admin/brand-discovery-cards/{id}/pause
→ Hide card from users

POST /api/v1/admin/brand-discovery-cards/{id}/activate
→ Show card to users
```

### Admin Commission Management

```
GET /api/v1/admin/commissions/brand/{brand_id}?days=30
→ {
     "total_commissions": 42,
     "confirmed_commissions": 38,
     "conversion_rate": 0.905,
     "total_revenue": 1250.50,
     "average_commission": 29.77
   }

GET /api/v1/admin/commissions/underperforming
   ?min_conversion_rate=0.20&min_commission=10&days=30
→ Brands below thresholds

GET /api/v1/admin/commissions/top-brands?days=30&limit=10
→ Top brands by revenue

GET /api/v1/admin/commissions/retailer-performance?days=30
→ Performance by affiliate network

POST /api/v1/admin/commissions/{id}/confirm
→ Mark as confirmed/converted

POST /api/v1/admin/commissions/{id}/reject
   ?reason="Fraud detected"
→ Reject with reason
```

---

## Card Queue Integration

### How Brand Cards Get Injected

1. Standard queue generated: 85% exploitation + 10% exploration + 5% trending
2. Every 25th position gets a brand discovery card
3. Random active card selected
4. Card views incremented
5. User swipes recorded in brand_discovery_swipes table

### Card Types in Queue

```json
{
  "type": "product",
  "product_id": "uuid",
  "name": "Brand Name Product",
  "current_price": 250.00,
  ...
}

{
  "type": "brand_discovery",
  "card_id": "uuid",
  "brand_id": "uuid",
  "brand_name": "Brand Name",
  "description": "...",
  "logo_url": "...",
  "aesthetic_tags": ["minimalist"],
  "price_range": {"low": 150, "high": 600},
  "has_ambassador_program": true,
  "ambassador_program_url": "..."
}
```

---

## Seed Data Brands (25+)

**Premium Tier ($100-$800):**
- Ganni (Rakuten, 10%)
- Staud (Impact, 12%)
- Nanushka (Awin, 11%)
- Rachel Comey (Impact, 10%)
- Sandy Liang (Rakuten, 12%)
- Chopova Lowena (Awin, 10%)
- ROTATE (Impact, 10%)
- Reformation (Rakuten, 12%)

**Contemporary Tier ($70-$600):**
- Molly Goddard (Rakuten, 12%)
- Danielle Guizio (Awin, 11%)
- Collina Strada (Impact, 10%)
- Connor Ives (Rakuten, 11%)
- Baserange (Rakuten, 10%)
- Cult Gaia (Impact, 12%)
- Marine Serre (Rakuten, 11%)

**Luxury Tier ($300-$1500):**
- Paloma Wool (Rakuten, 10%)
- Lemaire (Impact, 12%)
- The Row (Rakuten, 8%)
- Khaite (Impact, 10%)
- Jacquemus (Awin, 12%)
- Peter Do (Impact, 10%)

All brands include ambassador program links and aesthetic tags.

---

## Common Workflows

### Onboard New Brand
1. Create brand in Brand table
2. Create BrandCandidate entry
3. Admin reviews (status: pending)
4. Admin approves (status: approved)
5. Admin activates with brand_id (status: active)
6. System creates BrandDiscoveryCard
7. Card appears in user queues

### Track Commission Earnings
1. User clicks affiliate link → Commission created (is_pending=true)
2. User purchases → Admin confirms (is_confirmed=true)
3. Query `/commissions/brand/{brand_id}` for stats
4. Alert if conversion_rate < 20% or total < $10

### Manage Underperforming Cards
1. System auto-flags if >60% dislikes or >80% skips
2. Admin reviews at `/admin/brand-discovery-cards?status_filter=flagged_for_review`
3. Pause underperforming cards
4. Consider removing brand or repositioning

### A/B Test Brand Positioning
1. Modify `BRAND_DISCOVERY_POSITION` in card_queue.py (currently 25)
2. Monitor like_rate improvements in discovery cards
3. Adjust based on engagement metrics
4. Track impact on conversion rates

---

## Performance Considerations

### Indexes for Speed
- brand_discovery_cards: (brand_id, status, is_active) for filtering
- commissions: (brand_id, is_confirmed, created_at) for time-based queries
- brand_discovery_swipes: (user_id, brand_id, action) for user preference tracking

### Query Patterns
- Cards per brand: `SELECT COUNT(*) FROM brand_discovery_cards WHERE brand_id = ?`
- User engagement: `SELECT action, COUNT(*) FROM brand_discovery_swipes WHERE brand_id = ? GROUP BY action`
- Revenue: `SELECT SUM(commission_amount) FROM commissions WHERE brand_id = ? AND is_confirmed = true`

### Caching Opportunities
- Brand card list (changes rarely)
- Top brands by revenue (update daily)
- Commission stats (update hourly)
