# Rosier Affiliate Revenue - Implementation Checklist

**Use this to track progress as you build the affiliate system.**

Last Updated: April 1, 2026

---

## Phase 1: Affiliate Network & Retailer Setup (Week 1-2)

### Network Applications
- [ ] **Rakuten Advertising**
  - URL: https://rakutenadvertising.com/publishers/
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Publisher ID: ___________________
  - Notes: ___________________

- [ ] **Skimlinks**
  - URL: https://signup.skimlinks.com/en
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Site ID: ___________________
  - Account Manager: ___________________

- [ ] **Awin**
  - URL: https://ui.awin.com/publisher-signup/en/awin/step1
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Affiliate ID: ___________________

- [ ] **Impact**
  - URL: https://impact.com/affiliate-marketing/
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Campaign IDs: ___________________

### Direct Retailer Applications
- [ ] **SSENSE**
  - URL: https://www.ssense.com/en-us/affiliates
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days
  - Program ID: ___________________

- [ ] **NET-A-PORTER**
  - URL: https://www.net-a-porter.com/en-us/content/affiliates/
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days
  - Program ID: ___________________

- [ ] **Farfetch**
  - URL: https://www.farfetch.com/pag1987.aspx
  - Email: affiliates@farfetch.com
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days
  - Program ID: ___________________

- [ ] **FWRD**
  - URL: https://www.fwrd.com/fw/content/customercare/affiliate/
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days
  - Program ID: ___________________

- [ ] **Shopbop**
  - URL: https://www.shopbop.com/ci/v2/shopbop_affiliate_program.html
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days
  - Program ID: ___________________

- [ ] **Matches Fashion**
  - URL: https://www.matchesfashion.com/us/affiliates
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days
  - Program ID: ___________________

- [ ] **Browns Fashion**
  - URL: https://brownsfashion.com/pages/affiliates
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days
  - Program ID: ___________________

### Direct Brand Applications
- [ ] **Reformation**
  - URL: https://www.thereformation.com/ref-affiliates.html
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days

- [ ] **Ganni**
  - Email: affiliates@ganni.com or partnerships@ganni.com
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days

- [ ] **Staud**
  - Email: partnerships@staud.clothing
  - Status: [ ] Submitted [ ] Approved [ ] Active
  - Commission Rate: ___% | Cookie: ___ days

---

## Phase 2: Backend Integration (Week 2-3)

### Affiliate Service Updates
- [ ] Review current `/backend/app/services/affiliate.py`
- [ ] Update `RETAILER_AFFILIATE_CONFIG` with approved program IDs:
  - [ ] SSENSE: merchant_id = _______________
  - [ ] NET-A-PORTER: merchant_id = _______________
  - [ ] Farfetch: merchant_id = _______________
  - [ ] FWRD: campaign_id = _______________
  - [ ] Shopbop: merchant_id = _______________
  - [ ] Matches Fashion: merchant_id = _______________
  - [ ] Browns Fashion: merchant_id = _______________
  - [ ] Reformation: (update contact/commission)

### Link Generation Testing
- [ ] Test `AffiliateService.get_affiliate_link()` for each retailer
  - [ ] Rakuten links generate correctly
  - [ ] Skimlinks links generate correctly
  - [ ] Awin links generate correctly
  - [ ] Impact links generate correctly
  - [ ] Direct links generate correctly

- [ ] Test `AffiliateService.get_retailer_config()` returns data for all retailers

- [ ] Test `AffiliateService.list_all_retailers()` returns complete config

### Database Updates (if needed)
- [ ] Confirm Retailer model has `affiliate_network` field
- [ ] Confirm Retailer model has `affiliate_publisher_id` field
- [ ] Add any missing fields to retailer records:
  - [ ] SSENSE
  - [ ] NET-A-PORTER
  - [ ] Farfetch
  - [ ] FWRD
  - [ ] Shopbop
  - [ ] Matches Fashion
  - [ ] Browns Fashion

---

## Phase 3: Product Feed Integration (Week 3-4)

### Affiliate Link Integration
- [ ] Update Product detail screen to include affiliate links
- [ ] Update Collection view to include affiliate links
- [ ] Update Trending/Popular view to include affiliate links
- [ ] Update User Saves/Wishlist to show affiliate links

### UI/UX Components
- [ ] Design "Shop Now" button/CTA
- [ ] Test link placement for CTR optimization
- [ ] Add tracking for button clicks
- [ ] Ensure proper affiliate disclosure (FTC compliance)
- [ ] Test on iOS for proper link handling (app → browser)

### Tracking & Attribution
- [ ] Confirm each link includes user_id for attribution
- [ ] Set up analytics to track:
  - [ ] Clicks per retailer
  - [ ] Clicks per product
  - [ ] Clicks per user
  - [ ] CTR by product category
  - [ ] CTR by placement (hero, collection, trending, etc.)

---

## Phase 4: Testing & QA (Week 4-5)

### Link Validation
- [ ] Test 10+ affiliate links in development
- [ ] Confirm links redirect to correct product pages
- [ ] Confirm affiliate attribution is captured
- [ ] Test on actual iOS device (not just simulator)
- [ ] Test different network types (WiFi, 4G, 5G)

### Conversion Tracking (if available)
- [ ] Set up conversion pixel/webhook if networks provide
- [ ] Test end-to-end: click link → add to cart → purchase
- [ ] Verify commission is credited to your account
- [ ] Document conversion time (how quickly commissions post)

### Edge Cases
- [ ] Test with out-of-stock products
- [ ] Test with discontinued products
- [ ] Test fallback if retailer is down
- [ ] Test with ad blockers (if applicable)

### Legal & Compliance
- [ ] Add affiliate disclosure to app (FTC requirement)
- [ ] Review privacy policy (mention affiliate partners)
- [ ] Review terms of service (mention affiliate relationships)
- [ ] Ensure compliance with affiliate network policies

---

## Phase 5: Go Live & Launch (Week 5)

### Pre-Launch Checklist
- [ ] All affiliate links tested and working
- [ ] Analytics tracking confirmed
- [ ] Affiliate disclosures in place
- [ ] Engineering sign-off complete
- [ ] Product team sign-off complete

### Launch
- [ ] Deploy to TestFlight
- [ ] Internal testing complete
- [ ] Deploy to App Store (or update existing app)
- [ ] Monitor first 24 hours for errors/issues
- [ ] Celebrate first affiliate click!

### Monitoring
- [ ] Daily check of affiliate dashboard (Rakuten, Skimlinks, etc.)
- [ ] Track daily clicks, conversions, revenue
- [ ] Monitor for any broken links
- [ ] Watch for performance issues

---

## Phase 6: Optimization (Week 6+)

### Daily Monitoring
- [ ] [ ] Track clicks by retailer
- [ ] [ ] Track clicks by product category
- [ ] [ ] Track clicks by placement
- [ ] [ ] Track conversion rate per retailer

### Weekly Optimization
- [ ] [ ] Identify top-performing products
- [ ] [ ] Identify top-performing retailers
- [ ] [ ] Identify top-performing placements
- [ ] [ ] Test new product recommendations
- [ ] [ ] A/B test CTA button text/color

### Monthly Strategy
- [ ] [ ] Review month's affiliate revenue
- [ ] [ ] Identify trends (seasonal, product category, etc.)
- [ ] [ ] Plan next month's curations
- [ ] [ ] Outreach to underperforming retailers
- [ ] [ ] Negotiate higher commission rates for top performers

---

## Phase 7: Scale (Month 2-6)

### Month 2: Add More Retailers
- [ ] Apply for any missed retailers
- [ ] Integrate additional networks (if approved)
- [ ] Expand product feed to 500+ items with affiliate links

### Month 3: Direct Brand Partnerships
- [ ] Contact 5-10 brands for direct partnerships
- [ ] Propose curated collections
- [ ] Negotiate higher commission rates
- [ ] Launch first brand partnership

### Month 4: Ambassador Programs
- [ ] Evaluate FWRD Brand Ambassador program
- [ ] Apply for brand ambassador programs
- [ ] Reach out to brands for exclusive opportunities

### Month 5-6: Advanced Optimization
- [ ] Implement machine learning for product recommendations
- [ ] Dynamic pricing/commission optimization
- [ ] Sponsored product placements (paid by brands)
- [ ] Test subscription model for exclusive collections

---

## Revenue Tracking

### Monthly Revenue Goals

| Month | Target MRR | Status | Actual |
|---|---|---|---|
| Month 1 (Setup) | $0 | [ ] | $ _____ |
| Month 2 (Testing) | $500 | [ ] | $ _____ |
| Month 3 (Growth) | $2,500 | [ ] | $ _____ |
| Month 4 (Scale) | $4,500 | [ ] | $ _____ |
| Month 5 (Optimize) | $7,000 | [ ] | $ _____ |
| Month 6 (Target) | $10,000 | [ ] | $ _____ |

### Key Metrics to Track

**Daily:**
- [ ] Clicks
- [ ] Conversions (if available)
- [ ] Revenue generated

**Weekly:**
- [ ] CTR (click-through rate)
- [ ] Top 5 products by clicks
- [ ] Top 3 retailers by clicks
- [ ] Conversion rate per retailer

**Monthly:**
- [ ] Total MRR
- [ ] Growth rate from last month
- [ ] Top retailers by revenue
- [ ] Top product categories
- [ ] Revenue per product
- [ ] Comparison to revenue targets

---

## Important Dates

| Date | Milestone | Status |
|---|---|---|
| Week 1 | Network signups complete | [ ] |
| Week 2 | All retailer apps submitted | [ ] |
| Week 3 | Engineering: All IDs received | [ ] |
| Week 4 | Testing complete, QA sign-off | [ ] |
| Week 5 | Links live in production | [ ] |
| Day 30 | First affiliate revenue | [ ] |
| Day 60 | $1,000+ cumulative revenue | [ ] |
| Month 3 | $2,500/month run rate | [ ] |
| Month 6 | $10,000/month achieved | [ ] |

---

## Contacts & Resources

### Key People
- **Charlie (Founder):** Leads affiliate applications and strategy
- **[Engineering Lead]:** Integrates affiliate links, updates service
- **[Product Lead]:** Designs placement, optimizes CTR
- **[Analytics Lead]:** Tracks metrics, identifies optimization opportunities

### Documents
- Full Guide: `/docs/affiliate_partnership_guide.md`
- Application Templates: `/docs/affiliate_application_drafts.md`
- Quick Start: `/docs/AFFILIATE_QUICK_START.md`
- Service Code: `/backend/app/services/affiliate.py`

### Network Dashboards
- Rakuten: https://rakuten.com/publishers/ (login after signup)
- Skimlinks: https://ui.skimlinks.com/ (login after signup)
- Awin: https://ui.awin.com/ (login after signup)
- Impact: https://app.impact.com/ (login after signup)

---

## Notes

```
[Space for ongoing notes about negotiations, approvals, issues, etc.]

```

---

**Last Updated:** April 1, 2026
**Owner:** Charlie (Founder)
**Next Review:** Week 2 (April 8, 2026)
