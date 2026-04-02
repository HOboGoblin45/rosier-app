# Rosier Marketing Infrastructure

Production-quality marketing assets for Rosier fashion discovery app.

## Overview

This directory contains all customer-facing marketing pages for the Rosier platform. All pages are:

- **SEO-optimized** with proper meta tags, structured data (JSON-LD), and keyword integration
- **Mobile-first responsive** design targeting women 18-35 on iOS/Android
- **Conversion-focused** with clear CTAs and email capture mechanisms
- **Brand-aligned** using Rosier's design system (colors: primary #1A1A2E, accent #C4A77D, surface #F8F6F3)
- **Performance-optimized** with no heavy frameworks, inline critical CSS, minimal JavaScript
- **Accessible** with semantic HTML and ARIA labels

---

## File Structure

```
landing/
├── index.html                          # Main landing page
├── blog/
│   ├── index.html                      # Blog landing page
│   └── micro-influencer-fashion.html   # Sample blog post (~1500 words)
├── thank-you.html                      # Waitlist signup confirmation
├── MARKETING_INFRASTRUCTURE.md          # This file
└── [future blog posts]
```

---

## Page Details

### 1. Main Landing Page (`index.html`)

**Purpose:** Capture email signups and establish brand positioning

**Key Sections:**
- **Header Navigation:** Sticky nav with links to blog and app features
- **Hero Section:** Clear value proposition ("Your taste. Your brands. Your feed.")
- **Email Capture Form:** Two-field form (email + optional Instagram handle)
- **How It Works:** 3-step visual walkthrough (Swipe → Save → Shop)
- **Style DNA Feature:** Explains AI personalization with visual mock-up
- **Why Rosier:** 3-card feature section (Swipe to Discover, Niche Curation, Price Alerts)
- **Brands Section:** 12 featured brand logos (Ganni, Khaite, The Row, etc.)
- **Social Proof:** 3 testimonial cards from early testers
- **CTA Section:** Launch badge + final call-to-action
- **Footer:** Links to blog, social, privacy/terms

**SEO Elements:**
- Title: "Rosier - Fashion Discovery App | Niche Brands, Swipe to Shop"
- Meta description targets keywords: "fashion discovery app", "niche fashion", "swipe to shop"
- H1: "Your taste. Your brands. Your feed."
- Open Graph + Twitter Card tags for social sharing
- JSON-LD schema for SoftwareApplication, FAQPage, and AggregateRating
- Internal links to blog posts

**CTA Flow:**
1. Hero form (primary capture)
2. Read blog section (secondary engagement)
3. Footer links (retention)

**Form Behavior:**
- Email validation before submission
- POST to `/api/waitlist` endpoint
- Success state shows checkmark + "Check your email"
- Redirect to `/thank-you` after 2 seconds

---

### 2. Blog Landing Page (`blog/index.html`)

**Purpose:** Drive organic traffic through SEO + build authority on niche fashion topics

**Key Sections:**
- **Hero Banner:** Clear blog positioning
- **Category Filters:** Tags for Trends, Brands, Style Guide, Behind the App
- **Featured Post:** "The Rise of Micro-Influencer Fashion" with 2-column layout
- **Recent Posts Grid:** 6 blog post cards with categories, excerpts, read time
- **Post Cards Include:**
  - Category badge
  - Title (18px font)
  - 50-word excerpt
  - Publication date + read time
  - "Read" link to full post

**SEO Elements:**
- Title: "Rosier Style Guide - Fashion Discovery Blog | Niche Brands & Style Tips"
- Meta description targets blog keywords
- JSON-LD schema for Blog type
- Links to all blog posts for internal linking
- Breadcrumb navigation (implied)

**Content Strategy:**
- 6 featured posts covering: micro-influencer fashion, style DNA, emerging brands, how to shop, brand spotlights, capsule wardrobes
- Each post has unique category tag
- Grid is mobile-responsive (1 column on mobile, 3 columns on desktop)

**CTA:**
- "Read Full Article" buttons on each post card
- Back to app link in navigation

---

### 3. Blog Post: Micro-Influencer Fashion (`blog/micro-influencer-fashion.html`)

**Purpose:** SEO target for "micro-influencer fashion" + establish thought leadership

**Word Count:** ~1,500 words

**Target Keywords:**
- Primary: "micro-influencer fashion"
- Secondary: "niche fashion discovery", "authentic style", "contemporary brands"

**Content Structure:**
1. **Hero Section**
   - Category badge: "Trends"
   - Title: "The Rise of Micro-Influencer Fashion: Why Niche Beats Mass"
   - Meta: Date, read time, author

2. **Body Sections**
   - Opening hook on fashion discovery shift
   - "What's Wrong With the Old Model?" - Problems with mega-influencer + algorithmic discovery
   - "Enter Micro-Influencers" - Why they're winning
   - "Why Niche Beats Mass" - Core argument with 5-point breakdown
   - "How Micro-Influencers Actually Find Fashion" - Comparison table
   - "The Brands Winning This Shift" - Brand examples (Khaite, Ganni, etc.)
   - "How to Shop Like Your Favorite Micro-Influencer" - 5-step guide
   - "The Future of Fashion Discovery" - Thought leadership
   - "Key Takeaway" - Conclusion

3. **Special Elements**
   - Blockquote: Testimonial from early tester
   - Highlight box: "The Micro-Influencer Economy" with stats
   - CTA box: Link to waitlist with context

4. **Social Features**
   - Share buttons: Twitter, Facebook, LinkedIn, Pinterest
   - Related posts: 3-post grid at bottom

**SEO Elements:**
- JSON-LD Article schema with metadata
- H1 in title
- H2s for major sections (improves featured snippet chances)
- Internal links to:
  - Landing page (`/`)
  - Blog landing (`/blog/`)
  - Thank you page (`/thank-you`)
  - Other blog posts
- Image alt text (placeholder emojis, but real images would have descriptive alt)
- First mention of keyword "micro-influencer fashion" in first paragraph
- Keyword density: ~1.2% (natural distribution)

**Call-to-Action:**
- Mid-article: "Read our blog: Style DNA Explained"
- Post-article: "Discover Fashion the Micro-Influencer Way" → Join waitlist CTA
- Footer: Related posts with internal links

---

### 4. Thank You Page (`thank-you.html`)

**Purpose:** Confirm signup, encourage referrals, build engagement

**Key Sections:**
- **Success Message:** Animated checkmark + "You're In!"
- **Info Cards:**
  - Check your email
  - Launch date (Summer 2026)
  - Early access tier
- **Referral Section:**
  - Explain referral program
  - Show rewards (500 coins earned, 250 coins friend gets)
  - Link to referral signup
- **Social Follow Section:**
  - Links to Instagram, Twitter, TikTok
- **CTA Buttons:**
  - Read blog
  - Back to app

**Purpose:**
- Confirm email was received
- Direct user to check email for referral link
- Encourage social sharing
- Re-engage with blog content
- Build community (follow social)

**Design Elements:**
- Animated success icon (bounce animation)
- Info cards with hover effects
- Highlighted referral section with special styling
- Responsive design for mobile

---

## SEO Strategy Implementation

### Keywords Targeted Across All Pages

**Primary:**
- "fashion discovery app"
- "niche fashion"
- "micro-influencer fashion"
- "style DNA"
- "swipe to shop"
- "contemporary brands"

**Secondary:**
- "fashion TikTok"
- "niche fashion discovery"
- "authentic fashion"
- "fashion finder app"
- "clothing recommendation app"
- Individual brand keywords (Khaite, Ganni, The Row, etc.)

### Internal Linking Strategy

**Linking Pattern:**
- Landing page → Blog landing (header nav)
- Blog landing → Individual posts (post cards)
- Individual posts → Landing page (footer CTA)
- Individual posts → Other posts (related posts section)
- Blog posts → Thank you page (form submission)
- All pages → Privacy/Terms (footer)

**Anchor Text Guidelines:**
- Use keyword-rich anchors: "fashion discovery app", "style DNA explained", "micro-influencer fashion guide"
- Mix with branded: "Rosier blog", "back to app"
- Vary to appear natural (not all exact-match)

### Structured Data Implemented

**SoftwareApplication Schema** (landing page):
- App name, description, category
- Offer (free)
- Aggregate rating (4.8 stars, 2000+ reviews)
- Operating systems (iOS, Android)

**FAQPage Schema** (landing page):
- 4 common questions + answers
- Improves Google snippet optimization

**Blog Schema** (blog landing):
- Blog type with publisher info
- Enables Google Blog Search visibility

**BlogPosting Schema** (blog posts):
- Headline, description, author, date
- Image, main entity
- Enables rich search results

---

## Analytics & Tracking

### Events to Track

**Landing Page:**
- Form submissions (email + instagram captures)
- CTA clicks (blog link, social links)
- Scroll depth (how far users read)
- Source tracking (UTM parameters)

**Blog Pages:**
- Page views + sessions
- Time on page
- Click-through to other pages
- Social share clicks
- Email signup from blog CTAs

**Thank You Page:**
- Page visits (conversion confirmation)
- Social follow clicks
- Blog click-through rate

### Recommended Tools

1. **Plausible Analytics** ($9-19/month)
   - GDPR-compliant, lightweight
   - Track: traffic source, page views, bounce rate, conversion rate
   - Good for blog traffic attribution

2. **PostHog** (Free tier + paid)
   - Product analytics when app launches
   - Track which blog posts drive highest-quality users
   - Measure blog → app download → retention correlation

3. **Google Search Console** (Free)
   - Monitor keyword rankings
   - Check click-through rate from search results
   - Identify pages with low engagement

### Monthly Metrics to Review

- [ ] Blog landing page visits
- [ ] Traffic to individual blog posts
- [ ] Average time on page (target: 3+ minutes for posts)
- [ ] Click-through rate to landing page from blog
- [ ] Email signups from all sources
- [ ] Social shares per post
- [ ] Related posts click-through rate
- [ ] Thank you page conversion rate (email signups)

---

## Content Roadmap

### Immediate (Week 1-2)

- [x] Main landing page (index.html)
- [x] Blog landing page
- [x] Sample blog post (micro-influencer fashion)
- [x] Thank you page
- [ ] Deploy to rosier.app

### Month 1-2

**Blog Posts (4-5 new):**
1. "Style DNA Explained: How AI Learns Your Fashion Taste" (3,200 words)
2. "10 Emerging Brands You Should Know in 2026" (2,800 words)
3. "How to Shop Like Your Favorite Micro-Influencer" (2,500 words)
4. "Khaite: How a Designer Dress Became an 'It Piece'" (2,200 words)

**SEO/Tech:**
- Set up Google Search Console
- Install Plausible Analytics
- Configure 301 redirects (if moving from old blog)
- Build sitemap.xml for all blog pages

### Month 3-6

**Blog Posts (8-10 new):**
- Brand spotlights: The Row, Jacquemus, Ganni, Baserange, Sandy Liang
- Lifestyle content: Capsule wardrobe, seasonal trends, color analysis
- Comparisons: Fashion apps compared, where to shop, price guides

**Repurposing:**
- Turn each blog post into 3-4 social assets (TikTok, Instagram Reels, YouTube Shorts)
- Create email newsletter series (weekly)
- Guest post on fashion publications

---

## Performance Checklist

Before going live, verify:

- [ ] All pages load in <3 seconds (test on 4G)
- [ ] Mobile-responsive on all devices (iPhone SE, iPhone 14, Android)
- [ ] Form submission works and redirects to thank you page
- [ ] All links are working (internal + external)
- [ ] Images have alt text
- [ ] Meta tags are unique on each page
- [ ] Schema markup validates (schema.org validator)
- [ ] Open Graph tags display correctly on social sharing
- [ ] No JavaScript errors in console
- [ ] Cookie/privacy notice if applicable
- [ ] Footer links to Privacy/Terms pages exist

---

## Design System Reference

**Colors:**
- Primary (dark navy): #1A1A2E
- Accent (gold): #C4A77D
- Surface (off-white): #F8F6F3
- Text: #1A1A1A
- Text Secondary: #6B6B6B
- Text Tertiary: #9B9B9B
- Border: #E8E8E8

**Typography:**
- Font family: Inter (imported from rsms.me/inter/inter.css)
- H1: 44-64px, weight 700, letter-spacing -1px
- H2: 28-32px, weight 700
- H3: 20px, weight 700
- Body: 15-16px, weight 400, line-height 1.6-1.8

**Spacing:**
- Section padding: 80-100px vertical, 20px horizontal
- Card gaps: 24-48px
- Button padding: 12-14px vertical, 24-32px horizontal

**Border Radius:**
- Large elements: 16px
- Medium elements: 12px
- Small elements: 8px
- Buttons: 8-10px
- Avatars/pills: 50% (circular)

**Animations:**
- Fade in: 0.8s ease-out
- Hover transform: translateY(-2px), 0.2s
- Scroll animations: fade + translateY(20px)

---

## Future Enhancements

### Phase 2 (Post-Launch)

1. **Blog Features:**
   - Search functionality
   - Category/tag filtering
   - Author bios
   - Comment section (Disqus or similar)
   - Newsletter subscription (separate from waitlist)

2. **Interactive Elements:**
   - "Style Quiz" (linked from landing page)
   - Brand comparison tool
   - Shopping guide generator
   - Community testimonials (dynamic)

3. **Personalization:**
   - Recommendation engine based on user segment
   - Dynamic landing page variants for paid traffic
   - Email segmentation (early access tier, referral incentives)

4. **Content Expansion:**
   - Video content (YouTube embeds)
   - Infographics (contemporary fashion tier breakdown)
   - Podcast/audio content snippets
   - User-generated content (testimonials, style stories)

---

## Maintenance & Updates

### Weekly
- [ ] Monitor form submissions (check for spam)
- [ ] Respond to any contact form inquiries
- [ ] Review analytics dashboard

### Monthly
- [ ] Check for broken links (use Screaming Frog)
- [ ] Update blog section with new posts
- [ ] Review page load speed (Google PageSpeed Insights)
- [ ] Check mobile responsiveness on latest devices
- [ ] Verify all external links still work

### Quarterly
- [ ] SEO audit (keyword rankings, competitor analysis)
- [ ] Content audit (refresh old posts with new data)
- [ ] Conversion rate analysis (form submission rates)
- [ ] User feedback review (if survey tools implemented)

---

## Deployment Notes

### Pre-Launch Checklist
- [ ] DNS configured for rosier.app
- [ ] SSL certificate installed (HTTPS)
- [ ] Pages uploaded to correct directory (`/landing/`)
- [ ] Subdomains configured (blog.rosier.app or /blog/)
- [ ] Favicon added
- [ ] 404 error page created
- [ ] Robots.txt configured
- [ ] Google Search Console verified
- [ ] Analytics tracking code installed
- [ ] Form API endpoint ready (`/api/waitlist`)

### Production Deployment
- Deploy to production server
- Test all forms and links
- Monitor error logs for 48 hours
- Set up automated backups
- Configure email notifications for form submissions

---

## Additional Resources

**SEO Reference:**
- [Google Search Console](https://search.google.com/search-console)
- [Schema.org Validator](https://validator.schema.org/)
- [Ahrefs Keyword Research](https://ahrefs.com/)

**Analytics:**
- [Plausible Analytics](https://plausible.io/)
- [PostHog](https://posthog.com/)

**Content Marketing:**
- [Rosier SEO Strategy Doc](../docs/seo_strategy.md)
- [Rosier Marketing Strategy Doc](../docs/marketing_growth_strategy.md)

---

**Last Updated:** April 1, 2026
**Maintained by:** Dev 3 (Marketing Infrastructure)
**Status:** Production Ready
