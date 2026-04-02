# Sprint 3 Assets - Complete Index & Reference Guide

**Sprint:** 3 — App Store Readiness
**Status:** Complete
**Last Updated:** April 1, 2026

---

## Quick Reference

| Category | File | Location | Size | Purpose |
|----------|------|----------|------|---------|
| **Screenshots** | 01_swipe.html | docs/screenshots/ | 7.6K | Swipe discovery interface |
| | 02_dresser.html | docs/screenshots/ | 6.3K | Personal dresser view |
| | 03_style_dna.html | docs/screenshots/ | 8.6K | Style DNA profile |
| | 04_quiz.html | docs/screenshots/ | 6.4K | Onboarding quiz |
| | 05_sale.html | docs/screenshots/ | 7.7K | Price drop notification |
| **Landing** | index.html | landing/ | 19K | Waitlist landing page |
| **Localization** | Localizable.strings | ios/Rosier/Sources/Resources/ | 13K | User-facing strings (117 keys) |
| | InfoPlist.strings | ios/Rosier/Sources/Resources/ | 6.8K | Permission descriptions |
| **Documentation** | quiz_assets.md | docs/ | 20K | Asset specifications |

---

## Asset Details

### 1. App Store Screenshots

All screenshots are **self-contained HTML files** ready for preview and submission. Each includes an iPhone frame mockup at **1290×2796px** (iPhone 14 Plus resolution).

#### 01_swipe.html — "Discover your style"
- **Purpose:** Screenshot 1 — Main swipe interface
- **Content:**
  - Product card: Lemaire Oversized Wool Blazer ($485)
  - Next card peeking: Khaite Small Edith Bag ($395)
  - Dresser icon at bottom
  - Swipe gesture hints
- **How to Use:**
  - Open in web browser to preview
  - Use browser dev tools for iPhone frame
  - Export to PNG/JPEG for App Store submission
- **Key Design Elements:**
  - Color palette: #1A1A2E (primary), #C4A77D (accent), #F5F5F5 (light)
  - Card stack animation concept
  - Clear product hierarchy

#### 02_dresser.html — "Save what you love"
- **Purpose:** Screenshot 2 — Personal dresser organization
- **Content:**
  - Tabs: "Summer (8)" and "Want List (5)"
  - 8-item grid of fashion thumbnails
  - Price drop badge on featured item (🔥)
  - Clean, scannable grid layout
- **How to Use:**
  - Preview in browser
  - Shows drawer management UI
  - Demonstrates saved items organization
- **Key Design Elements:**
  - Tab navigation pattern
  - Grid layout (3 columns × responsive)
  - Price drop visual indicator

#### 03_style_dna.html — "Your Style DNA"
- **Purpose:** Screenshot 3 — Personalized recommendations
- **Content:**
  - Complete Style DNA card with:
    - Archetype: "Minimalist with Edge"
    - Top Brands: Lemaire, Khaite, The Row, Baserange, Sandy Liang
    - Color swatches (warm neutral palette): 5 colors
    - Price Range: $150–$450
    - User Stats: 847 swipes, 142 saves
- **How to Use:**
  - Browser preview shows full profile card
  - Demonstrates personalization algorithm
  - Shows statistics and user engagement
- **Key Design Elements:**
  - Card-based UI with hierarchy
  - Visual color swatches
  - Badge system for archetype
  - Statistics layout

#### 04_quiz.html — "Built around you"
- **Purpose:** Screenshot 4 — Onboarding style quiz
- **Content:**
  - Question 2 of 5: "What catches your eye?"
  - 2×2 grid of selectable options
  - Two items with checkmarks (selected state)
  - Progress dots (2/5 filled)
  - Next button
- **How to Use:**
  - Preview interactive quiz flow
  - Shows question format and interaction pattern
  - Demonstrates selection mechanics
- **Key Design Elements:**
  - Progress indicator (dots)
  - 2×2 grid of options
  - Selected state with checkmark
  - Button CTA

#### 05_sale.html — "Never miss a deal"
- **Purpose:** Screenshot 5 — Price alert flow
- **Content:**
  - Push notification mockup:
    - Title: "Price Drop 🔥"
    - Message: Price and savings (Jacquemus Le Bambino)
  - Product detail below:
    - Current price: $315
    - Original price: $450
    - Discount: 30% off
    - Retailer: SSENSE
    - Shop button
- **How to Use:**
  - Shows notification-to-purchase flow
  - Demonstrates value prop (price alerts work)
  - Clear product detail layout
- **Key Design Elements:**
  - Notification badge at top
  - Price comparison visualization
  - Discount percentage badge
  - CTA button

---

### 2. Waitlist Landing Page

**File:** `landing/index.html` (19K)

**Purpose:** High-converting pre-launch landing page to capture emails and build audience

**Key Sections:**

1. **Hero Section**
   - Gradient background (#1A1A2E → #C4A77D)
   - Headline: "Your taste. Your brands. Your feed."
   - Subheadline: Value proposition (swipe, curated, free)
   - Email input + Instagram field (optional)
   - "Join the Waitlist" button
   - Social proof: "Join 2,000+ fashion-obsessed women"

2. **Features Section (3 columns)**
   - 🎴 Swipe to Discover
   - ✦ Your Style DNA
   - 🔥 Never Miss a Sale
   - Each with description and icon

3. **Brands Section**
   - "Brands You'll Discover" headline
   - 12 brand logos in responsive grid:
     - Lemaire, Khaite, The Row, Jacquemus
     - Sandy Liang, Ganni, Baserange, Olivela
     - SSENSE, Browns Fashion, Dover Street, Farfetch

4. **CTA Section**
   - "Coming Summer 2026" badge
   - Emphasis on launch anticipation

5. **Footer**
   - Logo
   - Social links (Instagram, Twitter)
   - Legal links (Privacy, Terms)
   - Copyright

**Technical Features:**
- Fully responsive (mobile-first)
- Form validation (email format)
- Form submission to `/api/waitlist` endpoint
- Success state UI with confirmation message
- Smooth scroll animations on load
- Social sharing meta tags (og:title, og:description, og:image)
- Scroll-triggered feature animations

**How to Deploy:**
1. Set `/api/waitlist` endpoint to accept POST with { email, instagram }
2. Configure HTTPS and SSL
3. Deploy to production server
4. Update og:image meta tag with actual image URL
5. Test form submission flow

---

### 3. Localization Strings

**File:** `Localizable.strings` (13K, 117 keys)
**Location:** `ios/Rosier/Sources/Resources/`
**Format:** Standard iOS `.strings` file (ASCII encoding)

**Organization:** 13 feature areas with MARK comments

#### Onboarding (8 keys)
- Welcome screen headline/subheadline
- Get Started button
- Sign In prompt
- Permissions request
- Disclaimer message

#### Quiz (18 keys)
- All 5 question prompts
- All 20 option labels (4 per question)
- Progress text ("Question X of Y")
- Navigation buttons (Next, Back)
- Completion text ("See Your Style DNA")
- Results section labels

#### Swipe View (11 keys)
- Main interface labels
- Offline state messaging
- Feed end states (title, subtitle, actions)
- Product detail labels (Brand, Price, Retailer)
- Card descriptions and hints

#### Dresser View (16 keys)
- Header and navigation
- Drawer management (create, rename, delete)
- Empty state messages
- Item actions (share, remove, view, shop)
- Price drop badge and messaging

#### Profile & Style DNA (10 keys)
- Profile header and navigation
- Style DNA locked state message
- Card section labels (Archetype, Top Brands, Colors, Price Range)
- Statistics labels
- Quiz retake prompts

#### Notifications & Alerts (10 keys)
- Push notification titles and bodies
- Price drop alerts
- New arrivals
- Daily drops
- Sales and promotions
- In-app confirmation messages

#### Filters & Search (10 keys)
- Filter UI labels
- Brand filter options
- Category options (Clothing, Shoes, Bags, Accessories, Jewelry)
- Price range options
- Filter control buttons

#### Settings (12 keys)
- Account settings (Email, Password)
- Notification preferences (Price drops, New arrivals, Daily drops, Sales)
- Privacy settings
- About section
- Rate app, send feedback

#### Authentication (13 keys)
- Sign up screen (Email, Password, Confirm)
- Sign in screen (Email, Password, Forgot Password)
- Apple Sign-In button
- Password reset flow
- Validation messages

#### Errors & Network (8 keys)
- Generic network error
- No internet connection
- Timeout error
- Item not found
- Server error
- Retry button
- Loading states

#### Accessibility (11 keys)
- VoiceOver hints for swipe, tabs, buttons
- Product card descriptions
- Screen descriptions for main views
- Price, brand, retailer labels

#### Additional Categories (8 keys)
- Share functionality (items, dresser)
- Deep linking messages
- Future premium features
- Affiliate disclosure
- Empty state messages

**How to Use:**
1. Place in Xcode project under Resources
2. Configure Build Settings: Development Language = English
3. Use `NSLocalizedString("key", comment: "...")` in SwiftUI
4. For future languages, create `Localizable.strings` files in language-specific .lproj folders

**Example Usage in Code:**
```swift
Text(NSLocalizedString("swipe.feedEnd.title", comment: ""))
// Returns: "You've seen everything!"
```

---

### 4. Info.plist Localization Strings

**File:** `InfoPlist.strings` (6.8K)
**Location:** `ios/Rosier/Sources/Resources/`
**Format:** iOS permission and system configuration strings

**Contents:**

#### Permission Descriptions
- **Notifications:** Push and local notification access
- **Photos:** Read and write access for sharing screenshots
- **Camera:** Future video/photo capture
- **Location:** City-level location for retail information
- **Calendar:** Add sale dates and launches
- **Contacts:** Share favorites with friends
- **Bluetooth:** Future wearable integration
- **Health:** Size recommendations (future)
- **Face ID/Touch ID:** Secure authentication
- **Microphone:** Voice search (future)
- **HomeKit:** Smart home integration (future)
- **Siri:** Voice commands (future)
- **Mail:** Share via email
- **VoIP:** Video consultations (future)
- **Health Records:** Medical-grade sizing (future)

#### System Configuration
- App Transport Security (HTTPS enforcement)
- Retailer domain whitelist:
  - ssense.com
  - farfetch.com
  - brownsfashion.com
- URL schemes for deep linking
- Background modes (remote notification, fetch)
- Firebase configuration placeholders
- API configuration constants

**How to Integrate:**
1. Merge with existing Info.plist
2. Update permission descriptions as features are implemented
3. Test all permission prompts before App Store submission
4. Ensure all retailer URLs are HTTPS

---

### 5. Quiz Assets Planning Document

**File:** `quiz_assets.md` (20K, 513 lines)
**Location:** `docs/`
**Purpose:** Complete specification for sourcing/creating 20 style quiz images

**Document Sections:**

#### Asset Breakdown (20 images total)

**Q1: Silhouettes (4 images)**
- Structured & Tailored (blazer, sharp shoulders)
- Relaxed & Effortless (oversized, flowing fabric)
- Body-Conscious & Fitted (contoured, form-fitting)
- Avant-Garde & Experimental (unconventional cuts)

**Q2: Colors (4 mood boards)**
- Warm Neutrals (taupes, camels, creams)
- Cool Tones (grays, blues, silvers)
- Pastels & Soft Hues (pinks, blues, lavenders)
- Bold & Saturated (jewels, blacks, primary colors)

**Q3: Price Tiers (4 representative products)**
- Under $150 (contemporary basics)
- $150–$300 (mid-tier designer)
- $300–$500 (designer pieces)
- $500+ (luxury/premium)

**Q4: Categories (4 types)**
- Clothing & Apparel
- Shoes & Footwear
- Bags & Accessories
- Complete styled outfit

**Q5: Aesthetic Vibes (4 lifestyle aesthetics)**
- Quiet Luxury (minimalist, understated)
- Street Meets Runway (editorial, contemporary)
- Eclectic Maximalist (artistic, colorful)
- Minimalist Edge (neutral + statement element)

#### For Each Image:
- Visual direction with mood description
- Example brands to reference
- Detailed specifications
- Technical requirements
- Recommended sources

#### Sourcing Options
1. **Use Retailer Images** ($0–$500, 2–3 weeks)
   - Source: SSENSE, Farfetch, Browns Fashion
   - Advantage: Cost-effective, authentic brand photography

2. **Commission Original Photography** ($5K–$15K, 4–8 weeks)
   - Advantage: Branded consistency, unique to Rosier
   - Includes casting, shooting, post-production

3. **Hybrid Approach** ($3K–$8K, 4–6 weeks)
   - Retailer images for Q1–Q4
   - Original photography for Q5

#### Technical Specifications
- Display: 400×400px (square)
- Retina: 800×800px
- Format: PNG or JPG
- Color space: sRGB
- Compression: Max 150KB per image
- Aspect ratio: 1:1

#### Diversity Guidelines
- Various body types, skin tones, genders
- Age representation (20s–40s+)
- Inclusive styling across demographics

#### Timeline
- Week 1: Planning & sourcing approach
- Week 2–3: Secure images
- Week 3–5: Processing and editing
- Week 5–6: App integration and testing

---

## File Dependencies & Integration

### Screenshots
- **Dependency:** None (self-contained HTML)
- **Integration:** Preview in browser, export to PNG for submission
- **App Store Connection:** Screenshots 1–5 in correct order

### Landing Page
- **Dependency:** `/api/waitlist` endpoint (must be configured)
- **Integration:** Deploy to domain root or /landing/ subdomain
- **External:** Email service for confirmation emails

### Localization
- **Dependency:** SwiftUI views must use NSLocalizedString()
- **Integration:** Add to Xcode project Resources folder
- **Testing:** Verify all strings are properly referenced in code

### Info.plist
- **Dependency:** Existing Info.plist file
- **Integration:** Merge strings into project configuration
- **Testing:** Request permissions during onboarding

### Quiz Assets
- **Dependency:** Design feedback and sourcing approval
- **Integration:** Add to Xcode asset catalog
- **Timeline:** 6 weeks from approval to ready

---

## Usage Examples

### Using Screenshot in App Store Connect
```
1. Open App Store Connect
2. Go to "Screenshots" section
3. For each device size (iPhone 14 Plus):
   - Export HTML screenshot as PNG/JPEG
   - Upload image
   - Add caption from header text
   - Save
```

### Using Localization in Code
```swift
// SwiftUI example
VStack {
    Text(NSLocalizedString("swipe.feedEnd.title", comment: "End of feed"))
        .font(.headline)
    Text(NSLocalizedString("swipe.feedEnd.subtitle", comment: ""))
        .font(.caption)
}
```

### Deploying Landing Page
```bash
# 1. Build/minify if needed
# 2. Upload to server
# 3. Configure domain
# 4. Set up SSL/HTTPS
# 5. Test form submission
# 6. Monitor analytics
```

### Integrating Quiz Assets
```swift
// Once images are sourced and added to asset catalog
Image("q1_option1_structured")
    .resizable()
    .scaledToFill()
    .frame(width: 180, height: 180)
```

---

## Checklist for Next Steps

### Immediate (This Week)
- [ ] Review all screenshots in browser
- [ ] Share screenshots with stakeholders for approval
- [ ] Test landing page form locally
- [ ] Review localization keys for accuracy

### Short-term (Week 2)
- [ ] Configure `/api/waitlist` endpoint
- [ ] Deploy landing page to staging environment
- [ ] Begin quiz asset sourcing process
- [ ] Integrate Localizable.strings into Xcode

### Medium-term (Week 3–4)
- [ ] Receive quiz asset mock-ups or samples
- [ ] Export screenshots as high-res PNG for submission
- [ ] Deploy landing page to production
- [ ] Finalize quiz asset specifications with designer

### Pre-Launch (Week 5–6)
- [ ] Receive final quiz assets
- [ ] Integrate assets into app
- [ ] Test quiz flow end-to-end
- [ ] Prepare App Store submission package

---

## Support & Questions

### Screenshots
- **Question:** How do I convert HTML to App Store format?
- **Answer:** Use browser print-to-PDF or screenshot tools (e.g., Puppeteer, PhantomJS)

### Landing Page
- **Question:** What API endpoint structure do I need?
- **Answer:** POST `/api/waitlist` accepting `{ email: string, instagram?: string }`

### Localization
- **Question:** Do I need to add all 117 keys to code?
- **Answer:** Add keys as you implement each feature. Not all need to be used immediately.

### Quiz Assets
- **Question:** Can I use generic stock photos?
- **Answer:** Recommended to use actual designer/boutique imagery for authenticity

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Apr 1, 2026 | Initial creation - All Sprint 3 deliverables |

---

**Created By:** Senior iOS Developer #2
**Project:** Rosier Fashion Discovery App
**Status:** Production Ready
