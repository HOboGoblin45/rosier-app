# Rosier SEO Engine

## Overview

The Rosier SEO Engine is an automated content generation and optimization system that transforms app data into SEO-optimized blog content, sitemaps, and structured data. The core philosophy: **The app's data IS SEO content.**

Instead of hiring writers and manually creating blog posts, Rosier automatically generates high-quality, SEO-optimized content from trending brands, swipe data, user behavior, and style insights.

---

## Components

### 1. Blog Generator (`blog_generator.py`)

**Purpose:** Auto-generates SEO-optimized blog posts from Rosier data.

**Key Methods:**

- `generate_trending_brands_post()` — Creates "Top 10 Trending Brands" articles from swipe/save data
  - 1500+ word articles
  - Includes brand descriptions, trend analysis
  - Internal links to landing page and other posts
  - JSON-LD Article schema

- `generate_brand_spotlight()` — Deep-dive articles on individual brands
  - 1000-1200 word deep-dives
  - Targets: "{brand} review", "{brand} style", "brands like {brand}"
  - Design philosophy, key pieces, where to shop
  - SEO-optimized for brand-name searches

- `generate_style_guide()` — Style archetype content
  - "The Minimalist Modern Style Guide: 15 Essential Pieces"
  - Targets fashion advice queries
  - 1500+ words

- `generate_category_roundup()` — Category-focused listicles
  - "Best Loungewear Brands for 2026"
  - Targets high-volume category keywords
  - 2000+ words (listicle format = high SEO value)

- `generate_comparison_post()` — Brand vs. brand content
  - "Ganni vs. Staud: Which Brand Fits Your Style?"
  - Targets "brand vs brand" comparison searches
  - 1200+ words

**Output:**

Each generated post includes:
- SEO-optimized title (60 chars max)
- Meta description (155 chars max)
- H1, H2, H3 hierarchy
- Internal links
- Call-to-action section
- Open Graph + Twitter Card meta tags
- JSON-LD Article schema
- Responsive HTML matching Rosier's design system

---

### 2. Sitemap Generator (`sitemap_generator.py`)

**Purpose:** Auto-generates `sitemap.xml` and `robots.txt` for search engine crawling.

**Key Methods:**

- `add_page()` — Adds pages to sitemap with metadata
- `generate_sitemap_xml()` — Creates valid XML sitemap
- `generate_robots_txt()` — Creates crawling directives
- `create_rosier_sitemap()` — Pre-configured Rosier sitemap

**Output Files:**

- `/landing/sitemap.xml` — Complete sitemap with:
  - URLs for all landing pages and blog posts
  - Last modified dates
  - Change frequency (weekly for blog, monthly for posts)
  - Priority scores (1.0 for homepage, 0.8 for blog posts)

- `/landing/robots.txt` — Crawling rules:
  - Sitemap reference
  - Bot exclusions (Ahrefs, Semrush)
  - Crawl delays

**Auto-Updates:** Regenerate sitemap whenever new blog posts are published.

---

### 3. Structured Data Generator (`structured_data.py`)

**Purpose:** Generates JSON-LD for every page type to improve search result appearance.

**Key Methods:**

- `article_schema()` — BlogPosting schema for blog posts
  - Headline, description, image
  - Author, publisher info
  - Publication/modification dates

- `faq_schema()` — FAQPage schema
  - Question/answer pairs
  - Improves rich snippet visibility

- `organization_schema()` — Organization schema for homepage
  - Company info, contact details
  - Social links
  - Logo

- `software_application_schema()` — SoftwareApplication schema
  - App description, rating
  - Operating systems
  - Pricing

- `breadcrumb_schema()` — BreadcrumbList for navigation
  - Improves SERP visibility
  - Helps users navigate

- `product_schema()` — Product schema (for brand spotlights)
  - Brand, description, price
  - Ratings
  - Availability

- `inject_schema_into_html()` — Injects schema into HTML
  - Auto-replaces or inserts before `</head>`

**Usage:**

```python
from structured_data import StructuredDataGenerator, inject_schema_into_html

generator = StructuredDataGenerator()

# Generate article schema
schema = generator.article_schema(
    headline="Top 10 Trending Brands on Rosier",
    description="Discover the brands women are saving...",
    date_published="2026-04-01"
)

# Inject into HTML
html_with_schema = inject_schema_into_html(html_content, schema)
```

---

## Generated Blog Posts (April 2026)

### 1. `trending-brands-april-2026.html`
**Targets:** "trending fashion brands", "contemporary brands 2026"
- 1500+ words
- Features: Ganni, Deiji Studios, Staud, Nanushka, Khaite, Sandy Liang, Reformation, ROTATE, Collina Strada, Jacquemus
- Includes: Swipe data analysis, brand descriptions, trend insights

### 2. `deiji-studios-brand-spotlight.html`
**Targets:** "deiji studios review", "deiji studios quality"
- 1200+ words
- Deep dive on Australian contemporary brand
- Design philosophy, key pieces, sustainability approach
- Internal links to other brand posts

### 3. `style-dna-explained.html`
**Targets:** "style DNA", "AI fashion", "personalized recommendations"
- 1500+ words
- Explains Style DNA feature
- Six core style archetypes
- How personalization works

### 4. `best-contemporary-brands-2026.html`
**Targets:** "best contemporary brands", "contemporary fashion brands 2026"
- 2000+ words
- 25 brands across tiers (contemporary, emerging, niche)
- Pricing, where to shop, aesthetic summary
- Listicle format = high SEO value

### 5. `niche-fashion-vs-fast-fashion.html`
**Targets:** "niche fashion", "sustainable fashion", "slow fashion"
- 1500+ words
- Thought leadership piece
- Economics of quality vs. fast fashion
- Cost-per-wear analysis

---

## SEO Strategy

### Keyword Targets

**Primary Clusters:**

1. **Fashion Discovery** (High Intent)
   - "fashion discovery app" (500 monthly searches)
   - "niche fashion discovery" (200)
   - "style DNA" (150)

2. **Micro-Influencer Fashion** (Authority)
   - "micro-influencer fashion" (250)
   - "emerging fashion brands" (180)
   - "Gen Z fashion brands" (400)

3. **Contemporary & Premium Brands** (Brand Spotlights)
   - "Khaite dresses" (150)
   - "contemporary fashion brands" (600)
   - "Ganni sustainable fashion" (220)

4. **Shopping & Savings** (Monetization Intent)
   - "designer fashion sales" (800)
   - "price drop alerts fashion" (150)
   - "seasonal fashion sales" (500)

### Internal Linking Strategy

- **Blog to Landing Page:** 1-2 links per post (in footer, CTA)
- **Blog to Blog:** 2-3 related posts per article
- **Landing to Blog:** Link from Style DNA section to /blog/style-dna-explained.html

### On-Page Optimization Checklist

For each blog post:

- [ ] Title includes primary keyword (50-60 chars)
- [ ] Meta description includes CTA (150-160 chars)
- [ ] H1 matches title
- [ ] Primary keyword in first 100 words
- [ ] H2/H3 tags include secondary keywords
- [ ] 2,000-3,500 words total
- [ ] Internal links (2-3 per post)
- [ ] 3-5 subheadings per article
- [ ] Bullet points every 300-400 words
- [ ] Descriptive image alt text
- [ ] JSON-LD Article schema
- [ ] Open Graph + Twitter Card tags
- [ ] CTA section (soft mid, hard end)

---

## Monthly Workflow

### Week 1: Analysis
- Analyze Rosier swipe data to identify trending brands
- Check Google Search Console for trending queries
- Identify knowledge gaps in existing blog content

### Week 2: Content Planning
- Outline 2-4 new blog posts based on trends
- Assign keywords and target search volumes
- Plan internal linking strategy

### Week 3: Content Generation
- Generate blog posts using `blog_generator.py`
- Add real content (don't use placeholders)
- Optimize for target keywords
- Create JSON-LD schemas

### Week 4: Publishing & Optimization
- Publish posts
- Update sitemap and robots.txt
- Submit new URLs to Google Search Console
- Set up Google Analytics tracking

### Ongoing: Monitoring
- Track rankings for target keywords (use Ahrefs)
- Monitor organic traffic (use Plausible)
- Identify underperforming posts
- Refresh outdated content

---

## Integration with Rosier App

### Data Inputs
- **Trending Brands:** Swipe count, save count, add-to-cart rate per brand
- **User Segments:** Style DNA archetypes, price points, brand preferences
- **Price Alerts:** Trending sales, seasonal patterns
- **New Features:** Style DNA, price alerts, brand partnerships

### CTAs & Conversions
Each blog post includes CTAs targeting:
- **Waitlist signup:** Hero section
- **App download:** CTA buttons
- **Referral program:** Related posts

### Analytics Connection
- Track traffic attribution from blog → app
- Measure blog readers who become app users
- Calculate LTV of blog-sourced users

---

## Tools & Resources

### SEO Tools
- **Ahrefs** ($99-399/mo) — Keyword research, rank tracking
- **Google Search Console** (free) — SERP analytics, indexing
- **Screaming Frog** (free-$259/yr) — Technical SEO audits
- **Plausible Analytics** ($9-19/mo) — Traffic analytics

### Content Tools
- **Blog Platform:** Ghost or Webflow (recommended)
- **Image Optimization:** TinyPNG, ImageOptim
- **Markdown Editor:** VS Code, Notion

### File Structure
```
/marketing/seo_engine/
├── blog_generator.py
├── sitemap_generator.py
├── structured_data.py
└── README.md

/landing/blog/
├── index.html (blog homepage)
├── trending-brands-april-2026.html
├── deiji-studios-brand-spotlight.html
├── style-dna-explained.html
├── best-contemporary-brands-2026.html
├── niche-fashion-vs-fast-fashion.html
└── micro-influencer-fashion.html

/landing/
├── sitemap.xml (auto-generated)
└── robots.txt (auto-generated)
```

---

## Success Metrics (6-Month Goals)

| Metric | Target |
|--------|--------|
| Monthly organic blog traffic | 10,000+ visits |
| Number of blog posts | 20+ |
| Average ranking position | Top 20 |
| Referring domains | 20-30 |
| Blog → app conversion rate | 5-8% |
| Organic app installs from blog | 500+ |

---

## Future Enhancements

1. **Dynamic Brand Pages:** Auto-generate brand spotlight pages for all 65+ brands
2. **Category Pages:** Auto-generate category roundups (loungewear, minimalist, etc.)
3. **User-Generated Content:** Feature user saves/looks as blog content
4. **Video Content:** Auto-generate blog summary videos
5. **Newsletter Integration:** Weekly digest of trending brands
6. **Search Console Integration:** Auto-identify trending queries and create content

---

## Questions?

For technical questions about the SEO engine, refer to individual module docstrings. For strategic questions about blog content or keyword targeting, refer to the SEO strategy document.
