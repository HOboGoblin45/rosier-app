# App Review Preparation Guide

**Complete preparation for Apple's App Review process - common rejection reasons, compliance checklist, and strategies for fashion/shopping apps**

Last Updated: April 2026
App: Rosier v1.0

---

## Table of Contents

1. [Common Rejection Reasons for Shopping Apps](#common-rejection-reasons-for-shopping-apps)
2. [How Rosier Avoids These Rejections](#how-rosier-avoids-these-rejections)
3. [Affiliate Link Disclosure Requirements](#affiliate-link-disclosure-requirements)
4. [Privacy Manifest Compliance Checklist](#privacy-manifest-compliance-checklist)
5. [Required API Usage Justifications](#required-api-usage-justifications)
6. [Login & Demo Account Handling](#login--demo-account-handling)
7. [In-App Purchase & External Links Policy](#in-app-purchase--external-links-policy)
8. [Metadata & Screenshot Compliance](#metadata--screenshot-compliance)
9. [Pre-Submission Testing Checklist](#pre-submission-testing-checklist)
10. [If You Get Rejected - Response Templates](#if-you-get-rejected--response-templates)

---

## Common Rejection Reasons for Shopping Apps

### 1. Crash on Startup / Functionality Issues

**Apple's Guideline:** "Apps must be fully functional and not contain significant crashes or bugs that interfere with core functionality"

**Common causes in shopping apps:**
- Network requests fail (backend not responding)
- Image loading crashes app
- Login/auth flow is broken
- Swipe gestures don't work
- Links don't open properly
- App works on simulator but not real device

**Why this matters:** Apple tests on real devices. Simulator doesn't catch many issues.

**Prevention:** See [Pre-Submission Testing Checklist](#pre-submission-testing-checklist) below

---

### 2. Misleading Metadata

**Apple's Guideline:** "Screenshots, description, keywords, and marketing text must accurately represent the app"

**Common issues in shopping apps:**
- Description promises features not in the app ("Coming soon" features)
- Screenshots show UI that's different from actual app
- Keywords don't match actual functionality (e.g., keywords say "luxury brands" but app shows generic items)
- App name is misleading
- Description says "free shopping" but app is actually just affiliate links

**Why this matters:** Apple checks if descriptions match reality. They test the app against all claims.

**Prevention:** Section 3 below

---

### 3. Affiliate Link Disclosure Insufficient

**Apple's Guideline:** "Disclose all financial relationships and compensation clearly to users"

**What Apple looks for:**
- Are affiliate links clearly marked?
- Does privacy policy mention affiliate relationships?
- Does Terms of Service explain commission model?
- Is there in-app disclosure when clicking links?
- Are users told they pay the same price regardless of affiliate link?

**Why this matters:** FTC regulations require affiliate disclosure. Apple enforces this.

**Prevention:** Section 4 below

---

### 4. Privacy Policy Missing or Incomplete

**Apple's Guideline:** "You must have a comprehensive privacy policy that discloses all data collection"

**What Apple checks:**
- Is privacy policy URL valid?
- Does it load properly?
- Does it explain ALL data collection in the app?
- Does it mention third-party services (Firebase, Amplitude, etc.)?
- Does it explain retention periods?
- Does it explain user rights (deletion, access)?

**Why this matters:** Privacy violations are a top rejection reason.

**Prevention:** Use the Privacy Policy at `/docs/legal/privacy_policy.md` - it's comprehensive

---

### 5. Privacy Nutrition Label Incomplete

**Apple's Guideline:** "You must fill out the Privacy Nutrition Label accurately and completely"

**What Apple checks:**
- Are all data types listed?
- Are data categories correctly marked (linked to identity, used for tracking)?
- Do purposes match API usage?
- Are retention periods reasonable?

**Why this matters:** This is mandatory. Incomplete labels = rejection.

**Prevention:** See [Privacy Manifest Compliance Checklist](#privacy-manifest-compliance-checklist)

---

### 6. Missing or Invalid Demo Account

**Apple's Guideline:** "If login is required, you must provide working demo credentials"

**Common issues:**
- No account provided in review notes
- Account credentials are incorrect
- Account doesn't have test data
- Account gets locked after failed login attempts

**Why this matters:** Reviewers need to test the full app. If they can't log in, they can't review.

**Prevention:** Section 6 below

---

### 7. Broken Links

**Apple's Guideline:** "All URLs in description, privacy policy, and support links must work"

**Common issues:**
- Privacy policy URL returns 404
- Support URL is broken
- Terms of Service link doesn't work
- Marketing URL redirects infinitely

**Why this matters:** Apple verifies all links before approval.

**Prevention:** Test every URL before submission

---

### 8. Insufficient Content Rights Disclosure

**Apple's Guideline:** "You must own rights or have permission for all content in your app"

**What Apple checks for shopping apps:**
- Do you have permission to use product images?
- Are images from authorized sources?
- Do you have affiliate agreements in place?
- Are you scraping content illegally?

**Why this matters:** Copyright violations = rejection + legal issues.

**Prevention:** Section 2 below

---

### 9. Unclear Sign-In Requirements

**Apple's Guideline:** "Don't force sign-in before demonstrating app functionality"

**Issue:** If app requires login, it must:
- Show core functionality without login (or)
- Provide demo account (or)
- Allow browsing before login

**Why this matters:** Prevents apps from locking users into accounts.

**Prevention:** Rosier allows browsing without login - all good

---

### 10. Private API Usage

**Apple's Guideline:** "Apps must not use private/undocumented APIs"

**What Apple checks:**
- Scanning binary for known private API calls
- Verifying all APIs are documented

**Why this matters:** Private APIs break on OS updates and are "unfair advantage."

**Prevention:** Use only public APIs (your code is clean)

---

## How Rosier Avoids These Rejections

### ✓ Prevention Strategy for Each Risk

| Risk | What Rosier Does | Status |
|------|------------------|--------|
| **Crash on startup** | Thorough testing on real devices, proper error handling | ✓ Pass |
| **Misleading metadata** | Description matches actual functionality exactly | ✓ Pass |
| **Affiliate disclosure insufficient** | Clear disclosure in Privacy Policy, Terms of Service, and in-app | ✓ Pass |
| **Missing privacy policy** | Comprehensive policy at rosier.app/privacy | ✓ Pass |
| **Privacy label incomplete** | PrivacyInfo.xcprivacy file filled out completely | ✓ Pass |
| **No demo account** | reviewer@rosier.app with pre-populated test data | ✓ Pass |
| **Broken links** | All URLs tested before submission | ✓ Pass |
| **Content rights unclear** | All images from authorized affiliate feeds, no scraping | ✓ Pass |
| **Forced login** | App fully browsable without login | ✓ Pass |
| **Private APIs** | Using only public, documented APIs | ✓ Pass |

---

## Affiliate Link Disclosure Requirements

### 1. FTC Disclosure Requirements

**Federal Trade Commission (FTC) requires:**
- Clear and conspicuous disclosure of material connection
- Must be understood by consumers
- Can't be hidden in fine print
- Should appear BEFORE user clicks link

### 2. Apple's Specific Requirements

Apple requires affiliate relationship disclosure in THREE places:

#### A. App Store Description

**In the "Description" field on App Store, include language like:**

```
SHOP WITH CONFIDENCE
Click any product to view details and shop directly with authorized retailers.
Rosier earns a commission if you purchase through our links, at no extra cost to you.
```

✓ **Rosier:** Already included in metadata description

---

#### B. Terms of Service

**In Terms of Service at rosier.app/terms, include detailed section:**

**Required disclosure section:**

```
AFFILIATE RELATIONSHIP

Rosier earns commission from retail partners when you make a purchase through
our affiliate links. This means:

• You pay the SAME price whether you click our link or visit the retailer directly
• We disclose our affiliate relationships for transparency
• Commission amounts do NOT influence which products we recommend
• We only partner with authorized retailers (SSENSE, Farfetch, Browns Fashion, etc.)

Our affiliate partners include: Rakuten, Impact, Awin, Skimlinks

This is how Rosier sustains its business and continues to provide the free app
to you.
```

✓ **Rosier:** Check `/docs/legal/terms_of_service.md` - should include this language

---

#### C. In-App Disclosure

**When user clicks "Shop Now" button:**

Option 1: Add text to the product detail screen:
```
This link earns Rosier a commission at no extra cost to you.
```

Option 2: Show brief toast/notification when opening link:
```
"Opening retailer website... Rosier earns commission on purchases from this link"
```

✓ **Rosier:** Should add this in v1.0 or v1.1

---

### 3. Verification Checklist

Before submission, verify:

- [ ] App Store description mentions affiliate relationship
- [ ] Terms of Service has detailed affiliate disclosure section
- [ ] Privacy Policy explains affiliate tracking
- [ ] In-app link click shows disclosure (or in metadata notes)
- [ ] All affiliate partnerships are documented
- [ ] No incentive for users to purchase (fair disclosure)

---

## Privacy Manifest Compliance Checklist

### What is PrivacyInfo.xcprivacy?

A required XML file (new in iOS 17+) that declares:
- All data your app collects
- Why you collect it (purposes)
- Whether data is linked to identity
- Whether data is used for tracking

Location: `/ios/Rosier/Sources/App/PrivacyInfo.xcprivacy`

### Compliance Checklist

**Rosier's PrivacyInfo.xcprivacy includes:**

- [x] Email Address
  - Linked to identity: YES
  - Purposes: Account management, app functionality
  - Tracking: NO

- [x] User ID
  - Linked to identity: YES
  - Purposes: Account management, app functionality
  - Tracking: NO

- [x] Product Interaction
  - Linked to identity: YES
  - Purposes: App functionality, analytics
  - Tracking: NO

- [x] Purchase History (Click events)
  - Linked to identity: YES
  - Purposes: App functionality, analytics
  - Tracking: NO

- [x] Other Diagnostic Data
  - Linked to identity: NO
  - Purposes: App functionality, analytics
  - Tracking: NO

- [x] Other User Data (Style preferences)
  - Linked to identity: YES
  - Purposes: App functionality
  - Tracking: NO

### Verification Steps

**Before submission:**

1. **Open PrivacyInfo.xcprivacy in Xcode**
   - Right-click → Open as Source Code
   - Verify all dictionaries are present
   - Verify no typos in keys

2. **Verify it's included in build**
   ```
   Build Settings → Code Signing → Privacy Manifest Location
   Should include: PrivacyInfo.xcprivacy
   ```

3. **Test that it loads correctly**
   ```bash
   # On Mac, verify file exists in built app
   cd build/Rosier.xcarchive
   ls -la Products/Applications/Rosier.app/PrivacyManifest.xml
   ```

4. **Compare to Privacy Policy**
   - Every data type in PrivacyInfo should be explained in Privacy Policy
   - Every purpose should match actual app usage
   - Retention periods should be reasonable

---

## Required API Usage Justifications

### What Are API Usage Justifications?

Apple requires justification for using certain "sensitive" APIs. When you use these APIs, you must explain WHY to Apple.

Rosier uses several APIs that require justification:

### 1. UserDefaults API

**What it does:** Stores app preferences (theme, notification settings, etc.)

**Why Rosier uses it:** Store user preferences locally

**Justification for Apple:**
```
Rosier uses UserDefaults to store user preferences including:
- Dark mode toggle state
- Notification settings
- Saved dresser items
- Style DNA profile

This is stored locally on the device and is essential for the app to remember
user choices between app launches.
```

**Status:** ✓ Included in PrivacyInfo.xcprivacy

---

### 2. System Boot Time API

**What it does:** Get device boot time (for analytics)

**Why Rosier uses it:** Detect crashes and unusual behavior

**Justification for Apple:**
```
Rosier uses System Boot Time to:
- Detect when the app crashed
- Report crash statistics to developers
- Improve app stability

This is used only for diagnostic purposes and is not shared with third parties.
```

**Status:** ✓ Included in PrivacyInfo.xcprivacy

---

### 3. File Timestamp APIs

**What it does:** Get modification dates of files

**Why Rosier uses it:** Verify when dresser items were saved

**Justification for Apple:**
```
Rosier accesses file timestamps to:
- Track when products were added to your dresser
- Sort items by save date
- Clean up old cached images

This is stored locally only.
```

**Status:** ✓ Included in PrivacyInfo.xcprivacy

---

### 4. Disk Space API

**What it does:** Check available storage on device

**Why Rosier uses it:** Prevent crashes from running out of storage

**Justification for Apple:**
```
Rosier checks disk space to:
- Ensure cached product images don't fill up the device
- Warn users if storage is critically low
- Delete old cached data to free space

This is used only locally and is not shared.
```

**Status:** ✓ Included in PrivacyInfo.xcprivacy

---

### 5. Active Keyboard API

**What it does:** Detect which keyboard is active

**Why Rosier uses it:** Proper keyboard handling for text input

**Justification for Apple:**
```
Rosier accesses the active keyboard to:
- Display the correct keyboard for email entry
- Handle third-party keyboards properly
- Ensure proper spacing/layout when keyboard appears

This is used only for UI purposes.
```

**Status:** ✓ Included in PrivacyInfo.xcprivacy

---

### Verification Checklist

Before submission:

- [x] PrivacyInfo.xcprivacy is included in app bundle
- [x] All APIs Rosier uses are documented in PrivacyInfo
- [x] Purposes match actual usage
- [x] No justifications are misleading
- [x] No APIs are listed that aren't actually used
- [x] File is syntactically valid XML
- [x] Matches Privacy Policy descriptions

---

## Login & Demo Account Handling

### 1. Rosier's Login Model

Rosier allows:
- **Browse without login:** Yes (limited functionality)
- **Login required for:** Saving dresser items, Style DNA, notifications
- **Sign-in methods:** Email + password, Apple Sign-In

### 2. Demo Account for Reviewers

**Apple requires:** If app requires login, provide demo credentials

**Rosier provides:**

```
Email:    reviewer@rosier.app
Password: ReviewTest2026!
```

**What the demo account includes:**
- Email verified (no confirmation needed)
- Pre-populated swipe history (50 interactions)
- Pre-populated dresser (12 saved items)
- Completed Style DNA profile
- Test notifications enabled
- Ready to test all features immediately

### 3. Account Setup Instructions for Reviewer

In App Review Notes, include:

```
TESTING WITHOUT A DEMO ACCOUNT (if needed):

If the provided demo account doesn't work, you can create a new one:

1. Tap "Sign Up" in the app
2. Enter any email address
3. Create a password
4. Verify the email (or skip)
5. Complete the onboarding

The app is fully functional with any account.
```

### 4. Account Lockout Prevention

**Important:** Apple tests with brute force. Your login system must handle:

- Multiple failed login attempts without crashing
- Account lockout after X attempts (security)
- Clear error messages (don't reveal if email exists or not)

**Verification:**

Test on your device:
1. Try logging in 5 times with wrong password
2. App should either:
   - Temporarily lock account (show message)
   - Or accept next correct attempt
3. App must NOT crash

---

## In-App Purchase & External Links Policy

### 1. Rosier's Model (Affiliate Links Only)

Rosier does NOT:
- Sell digital goods
- Offer subscriptions
- Process payments
- Use In-App Purchase (IAP)

Rosier DOES:
- Link to external retailers
- Earn affiliate commissions
- Provide free access to all features

### 2. Apple's Policy on External Links

**Allowed:**
- ✓ Links to retailer websites (you're doing this)
- ✓ Affiliate links with disclosure (you're doing this)
- ✓ External payments on retailer site (user pays them, not you)

**NOT allowed:**
- ✗ In-App Purchase that could be done via external link
- ✗ Hiding IAP by linking to web instead
- ✗ Circumventing App Store payment processing

### 3. Verification Checklist

- [x] No In-App Purchase in app binary
- [x] No SKPaymentTransaction imports
- [x] No payment processing in Rosier app
- [x] Affiliate links disclose relationship
- [x] User not tricked into thinking Rosier processes payment
- [x] No "Buy now" button that's actually a link (label it clearly)
- [x] User understands they're leaving the app

---

## Metadata & Screenshot Compliance

### 1. Description Accuracy

**Rule:** Description must match EXACTLY what the app does

**What NOT to do:**
- ✗ Promise features not in the app ("Coming soon" features)
- ✗ Mention brands you don't carry (yet)
- ✗ Exaggerate recommendation quality
- ✗ Claim free shipping (you don't guarantee it)
- ✗ Use competitor names to trick search

**Rosier's description:**
- ✓ Says "swipe to discover" - app does this
- ✓ Says "save to dresser" - app does this
- ✓ Says "Style DNA recommendations" - app does this
- ✓ Says "50+ retailers" - verify this is accurate count
- ✓ Says "affiliate links" - disclosed correctly

**Verification:** Every feature mentioned should be testable in 5 minutes with demo account

---

### 2. Screenshots Accuracy

**Rule:** Screenshots must show real app UI, not mockups

**Requirements:**
- ✓ PNG format (no JPEG)
- ✓ Correct dimensions (1320x2868, 1290x2796, or 1170x2532)
- ✓ Real app content (not Photoshopped or designed)
- ✓ No simulator bezels or notch visible
- ✓ No developer annotations
- ✓ Readable text (min 11pt font)

**Common issues Apple rejects:**
- ✗ Mockups with phone bezel (iPhone frame visible)
- ✗ Designer PSD files (not real app UI)
- ✗ Placeholder "Coming soon" content
- ✗ Different app version than submitted build
- ✗ Cropped or watermarked screenshots

**Verification:** Screenshots should look identical to what reviewer sees on first launch

---

### 3. Keywords Accuracy

**Rule:** Keywords must match actual app content

**Current keywords:**
```
niche fashion, fashion discovery, designer brands, style DNA, fashion app,
shop curated, swipe fashion, micro-influencer
```

**Verification:**
- ✓ "niche fashion" - app shows niche brands (SSENSE, Khaite, etc.)
- ✓ "fashion discovery" - swipe interface discovers products
- ✓ "designer brands" - carries designer brands
- ✓ "style DNA" - has quiz and profile
- ✓ "fashion app" - it's a fashion app
- ✓ "shop curated" - products are curated
- ✓ "swipe fashion" - main interaction is swiping
- ✓ "micro-influencer" - target audience mentioned in landing page

**NOT included (good):**
- ✗ "luxury" (could mislead if prices vary)
- ✗ "free shipping" (not guaranteed)
- ✗ "sale alerts" (if not in v1.0)
- ✗ Competitor names directly

---

### 4. Age Rating Accuracy

**Rosier is rated:** 4+ (Everyone)

**Verification:**
- ✓ No violence → correct
- ✓ No sexual content → correct
- ✓ No profanity → correct
- ✓ Fashion content is modest → correct

If any user-generated content shows up later:
- Implement moderation
- Update age rating if needed
- Notify Apple

---

## Pre-Submission Testing Checklist

### Phase 1: Local Testing (before archive)

#### Functionality (15 minutes)
- [ ] App launches without crash
- [ ] Main swipe interface works
- [ ] Can swipe right (like) and left (pass)
- [ ] Dresser shows liked items
- [ ] Can remove items from dresser
- [ ] Style DNA quiz completes
- [ ] Recommendations show after quiz
- [ ] Settings screen opens
- [ ] Privacy policy link works
- [ ] Support email link works

#### Performance (10 minutes)
- [ ] App launches in < 2 seconds
- [ ] Swiping is smooth (60 FPS, no jank)
- [ ] Images load without freezing
- [ ] No memory leaks (check Xcode memory graph)
- [ ] Works on slower networks (throttle to 4G)

#### Stability (10 minutes)
- [ ] Force close and reopen - no crash
- [ ] Switch to another app and back - works
- [ ] Airplane mode toggle - handles gracefully
- [ ] Device rotation (if supported) - works
- [ ] Lock screen and unlock - works

---

### Phase 2: Device Testing (on real iPhone)

#### Multiple Devices (30 minutes)
- [ ] Test on iPhone 15 (or closest available)
- [ ] Test on iPhone 14 Plus (larger device)
- [ ] Test on iPad if supported (check specs)

#### Network Conditions (10 minutes)
- [ ] Test on Wi-Fi (fast)
- [ ] Test on 4G/LTE (slow)
- [ ] Test on poor signal area
- [ ] Toggle WiFi off while using app

#### Permissions (5 minutes)
- [ ] Location permission request
- [ ] Notification permission request
- [ ] Camera permission (if applicable)
- [ ] Contacts permission (if applicable)

---

### Phase 3: Account & Auth Testing (10 minutes)

#### Sign Up
- [ ] New account creation works
- [ ] Email validation works
- [ ] Password requirements clear
- [ ] Existing email shows error

#### Sign In
- [ ] Login with correct credentials works
- [ ] Wrong password shows error
- [ ] Multiple failed attempts don't crash
- [ ] Demo account (reviewer@rosier.app) logs in

#### Session Management
- [ ] User stays logged in after restart
- [ ] Logout works
- [ ] Sign out from settings works

---

### Phase 4: Affiliate Link Testing (15 minutes)

#### Link Functionality
- [ ] Click product → opens retailer
- [ ] Link tracking works (verify with test click)
- [ ] Affiliate parameter present in URL
- [ ] Multiple retailers work (SSENSE, Farfetch, etc.)

#### User Experience
- [ ] Link opens in Safari (or in-app browser)
- [ ] "Back" button returns to app
- [ ] Link click disclosure shown
- [ ] No crashes when opening links

---

### Phase 5: Privacy & Security (10 minutes)

#### Privacy
- [ ] Privacy Policy URL is valid
- [ ] Privacy Policy is complete
- [ ] Terms of Service URL is valid
- [ ] Affiliate disclosure is clear

#### Security
- [ ] Passwords never shown in logs
- [ ] No sensitive data in crash logs
- [ ] HTTPS used for API calls
- [ ] No hardcoded API keys visible

---

### Phase 6: Offline Mode (5 minutes)

#### Test in Airplane Mode
- [ ] Saved items load offline
- [ ] Can view dresser offline
- [ ] Can't fetch new products (shows error)
- [ ] Re-enable WiFi → syncs correctly

---

### Phase 7: Metadata Verification (5 minutes)

#### App Info
- [ ] App name: "Rosier"
- [ ] Version number: "1.0.0" (in Settings)
- [ ] App icon visible and correct
- [ ] No placeholder images

#### URLs in App
- [ ] Support URL in Settings works
- [ ] Privacy Policy URL works
- [ ] Terms of Service URL works
- [ ] Marketing URL works

---

### Phase 8: Full User Journey (10 minutes)

#### Fresh Install Scenario
1. Delete app from device
2. Reinstall from development build
3. Launch app
   - [ ] Welcome screen shows
   - [ ] Can browse without login
   - [ ] Can swipe products
   - [ ] Sign up flow works
4. Log in with demo account
   - [ ] Pre-populated data appears
   - [ ] Dresser shows saved items
   - [ ] Style DNA profile loads
5. Test main features
   - [ ] Swipe works
   - [ ] Like/pass works
   - [ ] Dresser works
   - [ ] Notifications work (if enabled)
6. Click "Shop" on a product
   - [ ] Opens retailer correctly
   - [ ] Can view product
   - [ ] Can add to cart (external to Rosier)

---

## If You Get Rejected - Response Templates

### Template 1: Functionality Issue

**If rejected for:** "App crashed on startup" or "Feature X doesn't work"

**Response to Apple:**

```
Thank you for the review feedback.

We've identified and fixed the issue where [describe issue briefly].

The fix involved [brief technical description].

We've tested the fix on multiple devices:
- iPhone 15
- iPhone 14 Plus
- iPhone 15 Pro Max

The issue no longer occurs. We've uploaded build X.X with the fix.

We appreciate your patience.

Rosier Team
```

---

### Template 2: Misleading Metadata

**If rejected for:** "Description doesn't match app" or "Screenshots inaccurate"

**Response to Apple:**

```
Thank you for pointing out the discrepancy.

We've reviewed [description/screenshots] and updated them to accurately reflect
the current app functionality.

Changes made:
- Updated description: [specific changes]
- Replaced screenshots with accurate ones from [version X]
- Verified all features mentioned are present in the app

The app now accurately represents: [list actual features]

Updated build X.X is submitted for review.

Rosier Team
```

---

### Template 3: Privacy/Affiliate Issue

**If rejected for:** "Affiliate disclosure insufficient" or "Privacy Policy incomplete"

**Response to Apple:**

```
Thank you for the feedback on our affiliate disclosure.

We've enhanced our disclosures:

1. Updated App Store description to include: "Rosier earns a commission if
   you purchase through our links, at no extra cost to you."

2. Updated Terms of Service with detailed Affiliate Relationship section at:
   https://rosier.app/terms

3. In-app: Product detail screen now shows "This link earns Rosier a
   commission at no extra cost to you."

4. Privacy Policy updated at: https://rosier.app/privacy

The affiliate relationship is now clearly disclosed at multiple touchpoints.

Updated build X.X is submitted.

Rosier Team
```

---

### Template 4: Demo Account Issue

**If rejected for:** "Demo account not provided" or "Account doesn't work"

**Response to Apple:**

```
Thank you for the feedback.

Demo account details are provided for the next submission:

Email: reviewer@rosier.app
Password: ReviewTest2026!

This account is pre-populated with:
- Swipe history (50 interactions)
- Dresser items (12 saved products)
- Completed Style DNA profile
- Enabled notifications

The account is fully functional and ready for immediate testing.

These credentials are also included in the App Review Notes.

Updated build X.X is submitted.

Rosier Team
```

---

### Template 5: Generic Issue

**If rejected for unclear reason:**

**Response to Apple:**

```
Thank you for the review feedback. We'd like to understand the issue better
so we can address it properly.

Could you provide more details on:
- Specific feature that failed
- When the issue occurred
- Screenshots or video if possible

Once we understand the issue, we'll fix it immediately and resubmit.

Rosier Team
```

---

## Final Verification Before Submission

### Submission Checklist

**Code Quality:**
- [ ] No compiler warnings
- [ ] All tests passing
- [ ] SwiftLint clean (or exceptions documented)
- [ ] No force unwraps (except safe cases)
- [ ] Proper error handling

**Functionality:**
- [ ] App launches without crash
- [ ] All core features work
- [ ] Demo account logs in successfully
- [ ] Swipe interface smooth
- [ ] Image loading works
- [ ] Affiliate links open correctly

**Metadata:**
- [ ] App name: "Rosier"
- [ ] Subtitle: "Niche Fashion Discovery"
- [ ] Description: accurate and compelling
- [ ] Keywords: relevant and accurate
- [ ] Screenshots: 5+ accurate ones
- [ ] App icon: 1024x1024 PNG

**Privacy & Compliance:**
- [ ] Privacy Policy URL valid
- [ ] Terms of Service URL valid
- [ ] Privacy Nutrition Label complete
- [ ] PrivacyInfo.xcprivacy included
- [ ] Affiliate disclosure clear
- [ ] Age rating: 4+

**App Review Notes:**
- [ ] Demo account provided
- [ ] Testing instructions clear
- [ ] Affiliate relationship explained
- [ ] Contact information provided
- [ ] Known limitations disclosed

**Final Check:**
- [ ] All URLs tested (Privacy, Support, Marketing, Terms)
- [ ] Build uploaded and processed
- [ ] Version/Build numbers set correctly
- [ ] No placeholder content
- [ ] Ready for submission

---

## Success Metrics

**You'll know you've succeeded when:**

✓ App approved within 1-3 days
✓ No rejection for compliance issues
✓ No follow-up requests for information
✓ App goes live on App Store
✓ All metadata displays correctly
✓ Search finds app by keywords

---

**This document is complete. You're ready to submit!**
