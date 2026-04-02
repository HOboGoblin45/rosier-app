# Rosier App Store Connect Setup Log

**Date:** April 1, 2026
**Developer:** Dev 1
**Project:** Rosier Fashion Discovery App
**Account:** Charles Cresci (crescicharles@gmail.com)
**Team ID:** 52SKBHZK3L

---

## STEP 1: Bundle ID Registration - COMPLETED ✓

### Status: SUCCESS

Successfully registered the Bundle ID `com.rosier.app` with the following details:

**Registration Details:**
- **Description:** Rosier Fashion Discovery
- **Bundle ID:** com.rosier.app (Explicit)
- **App ID Prefix:** 52SKBHZK3L (Team ID)
- **Platform:** iOS, iPadOS, macOS, tvOS, watchOS, visionOS

**Enabled Capabilities:**
1. ✓ Sign In with Apple
2. ✓ Push Notifications
3. ✓ Associated Domains
4. ✓ App Groups (group.com.rosier.app)

**Registration Process:**
1. Navigated to: https://developer.apple.com/account/resources/identifiers/list
2. Clicked "Register an App ID"
3. Selected "App IDs" → "App" type
4. Filled in Description and Bundle ID
5. Enabled all 4 required capabilities
6. Successfully registered Bundle ID
7. Verified in Identifiers list

**Verification:**
- Bundle ID appears in Certificates, Identifiers & Profiles
- Name: "Rosier Fashion Discovery"
- Identifier: "com.rosier.app"

---

## STEP 2: Create App in App Store Connect - IN PROGRESS

### Status: PARTIALLY STARTED (Form validation issues)

Successfully navigated to App Store Connect and opened the New App creation dialog.

**Form Fields Completed:**
- ✓ **Platform:** iOS (selected)
- ✓ **Name:** Rosier
- ✓ **Primary Language:** English (U.S.)
- ⚠ **Bundle ID:** Attempted selection of com.rosier.app (form validation issue)
- ⚠ **SKU:** Attempted entry of ROSIER-APP-001 (form validation issue)
- ✓ **User Access:** Full Access (selected)

**Technical Issue Encountered:**
The App Store Connect form uses React-based custom components that do not respond to standard DOM manipulation or form_input tool. The Bundle ID dropdown and SKU field show validation errors even after attempting to fill them through multiple methods:
- form_input tool
- JavaScript DOM manipulation
- Direct typing/clicking

**Next Steps:**
The form requires manual interaction with the React component's internal state management.

---

## STEP 3: Fill App Information - NOT YET STARTED

**Planned Details:**
- **Subtitle:** "Niche Fashion Discovery" (30 chars)
- **Category:** Shopping (primary), Lifestyle (secondary)
- **Content Rights:** "Does not contain, show, or access third-party content"
- **Age Rating:** 4+ (all answers "None" to violence, gambling, etc.)
- **Privacy Policy URL:** https://rosier.app/privacy
- **Support URL:** https://rosier.app/support
- **Marketing URL:** https://rosier.app

---

## STEP 4: Version Information (1.0) - NOT YET STARTED

**Planned Details:**
- **Promotional Text:** "Discover niche fashion brands through an addictive swipe interface. Your style, curated by AI."
- **Description:** [Full description from metadata doc - 1,547 characters]
- **Keywords:** niche fashion, fashion discovery, designer brands, style DNA, fashion app, shop curated, swipe fashion, micro-influencer
- **What's New:** "Welcome to Rosier! Swipe to discover your next favorite brand."
- **Support URL:** https://rosier.app/support
- **Marketing URL:** https://rosier.app

---

## STEP 5: Screenshot Placeholders - NOT YET STARTED

**Required Screenshots:**
- iPhone 16 Pro Max (1320 x 2868 px)
- iPhone 15 Pro Max (1290 x 2796 px)
- iPhone 15 (1170 x 2532 px)

Screenshots should showcase:
1. Swipe Interface
2. Dresser (saved items)
3. Style DNA
4. Daily Drops notifications
5. Shop/Purchase flow

---

## Critical Information

### Bundle ID Successfully Registered
- The most critical first step has been completed
- Bundle ID is now available in App Store Connect dropdown
- Bundle ID appears in both Developer Portal and App Store Connect systems

### Demo Account Ready
- **Email:** reviewer@rosier.app
- **Password:** ReviewTest2026!
- **Pre-populated Data:** Sample swipes, saved items, Style DNA profile

### Required URLs (Must be live before submission)
- https://rosier.app (landing page)
- https://rosier.app/privacy (privacy policy)
- https://rosier.app/support (support/FAQ)
- https://rosier.app/terms (terms of service)

---

## Technical Notes

### App Store Connect Form Issue
The New App dialog in App Store Connect uses modern React component architecture that doesn't expose standard HTML form elements. The Bundle ID and SKU fields appear to be controlled by React state rather than direct DOM manipulation.

**Recommended Resolution:**
1. Use the web browser UI directly to click dropdowns and enter values
2. Or contact Apple Support if there are API limitations for bulk app creation
3. Alternative: Use Xcode's AppStore submission workflow if available

---

## Completion Status

**Overall Progress:** 33% (1 of 3 main steps completed)

| Step | Task | Status | Notes |
|------|------|--------|-------|
| 1 | Register Bundle ID | ✓ COMPLETE | Successfully registered com.rosier.app |
| 2 | Create App in ASC | ⚠ PARTIAL | Dialog opened, form has validation issues |
| 3 | Fill App Info | ❌ PENDING | Awaiting Step 2 completion |
| 4 | Version Information | ❌ PENDING | Awaiting Step 2 completion |
| 5 | Screenshots | ❌ PENDING | Awaiting Steps 2-4 completion |

---

## Next Action Items

1. **IMMEDIATE:** Resolve App Store Connect form issue
   - Contact Apple Developer Support for form submission guidance
   - Or use direct UI interaction to manually select dropdown options
   - Verify SKU field accepts the format "ROSIER-APP-001"

2. **AFTER Step 2:** Fill app metadata using values from app_store_connect_metadata.md

3. **CONCURRENT:** Prepare screenshot assets in correct dimensions

4. **BEFORE SUBMISSION:** Verify all URLs are live and accessible:
   - https://rosier.app
   - https://rosier.app/privacy
   - https://rosier.app/support
   - https://rosier.app/terms

---

**Document Status:** ACTIVE - Awaiting completion of App Store Connect form submission

**Last Updated:** April 1, 2026 10:35 AM PT
