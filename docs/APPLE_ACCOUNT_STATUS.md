# Rosier - Apple Developer Account Status

**Last Updated:** April 1, 2026
**Account Owner:** Charles Cresci
**Team ID:** 52SKBHZK3L

---

## Current Enrollment Status

**Status:** FULLY APPROVED & ACTIVE

The Apple Developer account is fully approved and operational. No pending review notifications.

### Account Details
- **Team Name:** Charles Cresci
- **Program:** Apple Developer Program
- **Enrollment Type:** Individual
- **Membership Renewal Date:** April 1, 2027
- **Annual Fee:** $99 (paid)
- **Account Email:** crescicharles@gmail.com
- **Phone:** 1-3092122470
- **Address:** 811 S Fell Ave, Normal, Illinois 61761, United States

---

## What's Been Set Up

### 1. Apple Developer Account Access
- Full access to Apple Developer portal confirmed
- Program resources available:
  - App Store Connect
  - Certificates, IDs & Profiles
  - Services (Xcode Cloud, CloudKit, Push Notifications, etc.)

### 2. Metadata Documentation
- Complete App Store Connect metadata prepared and stored in:
  - `/sessions/busy-tender-goldberg/mnt/Women's fashion app/rosier/docs/app_store_connect_metadata.md`
- Metadata includes:
  - App name: Rosier
  - Subtitle: Niche Fashion Discovery
  - Bundle ID: com.rosier.app
  - SKU: ROSIER-APP-001
  - Full 1,547-character marketing description
  - Keywords (97 characters)
  - Privacy policy declarations
  - Age rating (4+)
  - App review notes and demo account credentials
  - All required URLs and support information

### 3. Account Configuration
- Profile configured with:
  - Role: Hobbyist
  - Platform: iOS
  - App Categories: Lifestyle, Shopping
  - Topics: App Store Distribution & Marketing, Design, Developer Tools, Swift, SwiftUI, System Services

---

## What Still Needs to Be Done

### 1. Bundle ID Registration (com.rosier.app)
- **Status:** NOT YET REGISTERED
- **Action Required:** Register bundle ID in Certificates, Identifiers & Profiles
- **Steps:**
  1. Navigate to: https://developer.apple.com/account/resources/identifiers/addAppId
  2. Select "App IDs" identifier type
  3. Enter:
     - Description: Rosier
     - Bundle ID: com.rosier.app
  4. Configure required app services if needed
  5. Save and return to App Store Connect

### 2. Create App in App Store Connect
- **Status:** NOT YET CREATED
- **Action Required:** Create new app entry
- **Steps:**
  1. Go to App Store Connect: https://appstoreconnect.apple.com/apps
  2. Click "Add Apps" button
  3. Select Platforms: iOS
  4. Enter App Name: Rosier
  5. Select Primary Language: English (U.S.)
  6. Select Bundle ID: com.rosier.app (after registering above)
  7. Enter SKU: ROSIER-APP-001
  8. Set User Access: Limited Access (or Full Access based on team)
  9. Click Create

### 3. Complete App Store Metadata
- **Status:** READY TO INPUT (metadata document prepared)
- **Action Required:** Fill in App Store Connect form with metadata from app_store_connect_metadata.md
- **Fields to Complete:**
  - App description (1,547 characters)
  - Keywords (97 characters)
  - Privacy policy URL: https://rosier.app/privacy
  - Support URL: https://rosier.app/support
  - Marketing URL: https://rosier.app
  - Terms of Service: https://rosier.app/terms
  - Age rating questionnaire: 4+ rating
  - Privacy nutrition label
  - Screenshots (5-10 screenshots required)
  - App icon (1024x1024 PNG)
  - Launch screen assets

### 4. Build & TestFlight Setup
- **Status:** NOT STARTED
- **Prerequisites:**
  - Xcode project configured with Bundle ID: com.rosier.app
  - Code signing certificates created
  - Provisioning profiles created
  - App built and archived
- **Steps:**
  1. Create iOS distribution certificate in Certificates, IDs & Profiles
  2. Create App Store provisioning profile
  3. Build and archive app in Xcode
  4. Upload build to App Store Connect
  5. Set up TestFlight testers and invitations (optional)

### 5. App Review Submission
- **Status:** PENDING BUILD UPLOAD
- **Demo Account Ready:** Yes
  - Email: reviewer@rosier.app
  - Password: ReviewTest2026!
  - Pre-populated with test data
- **Action:** After all metadata complete, submit for review

---

## Prerequisites Before App Submission

### URLs Must Be Live & Accessible
All the following URLs must be live and serving the specified content:

| URL | Status | Purpose |
|-----|--------|---------|
| https://rosier.app | [ ] REQUIRED | App landing page |
| https://rosier.app/privacy | [ ] REQUIRED | Privacy policy (2KB minimum) |
| https://rosier.app/terms | [ ] REQUIRED | Terms of service |
| https://rosier.app/support | [ ] REQUIRED | Support/FAQ page |

### App Build Requirements
- [ ] Bundle ID: com.rosier.app
- [ ] iOS deployment target: iOS 17.0 minimum
- [ ] Devices: iPhone only
- [ ] Orientation: Portrait only
- [ ] Version: 1.0.0
- [ ] Build number: 1
- [ ] All features functional and tested
- [ ] No compiler warnings
- [ ] Tested on iOS 17+ devices

### Screenshots & Assets
- [ ] 5-10 app screenshots per device type
- [ ] App icon: 1024x1024 PNG
- [ ] Launch screen designed
- [ ] All images less than 5MB each
- [ ] Screenshots show actual UI (not mockups)

---

## Next Steps (Priority Order)

1. **Register Bundle ID com.rosier.app** (5 minutes)
   - Access: https://developer.apple.com/account/resources/identifiers/list
   - Register App ID with bundle ID: com.rosier.app

2. **Create App in App Store Connect** (5 minutes)
   - Once bundle ID is registered, create the app entry
   - Select the newly registered bundle ID

3. **Complete App Store Metadata** (30 minutes)
   - Fill in description, keywords, URLs
   - Upload screenshots and app icon
   - Configure privacy labels

4. **Prepare Build for Upload** (varies)
   - Ensure Xcode project uses correct bundle ID
   - Create signing certificates and profiles
   - Build and archive app

5. **Upload Build to TestFlight** (10 minutes)
   - Upload build via Xcode or Transporter
   - Wait for build processing (5-10 minutes)
   - Configure TestFlight testers if desired

6. **Submit for App Review** (5 minutes)
   - Complete final review information
   - Submit for review
   - Expected review time: 1-3 days

---

## Account Capabilities Summary

The Apple Developer account has full access to:
- **App Distribution:** Create, build, and submit apps to App Store
- **Testing:** TestFlight beta testing
- **Signing:** Create and manage certificates and provisioning profiles
- **Analytics:** App Store analytics and sales reports
- **Services:** Access to CloudKit, Push Notifications, Xcode Cloud, etc.
- **Support:** Priority support on Apple Developer Forums

---

## Technical References

- **Apple Developer Account:** https://developer.apple.com/account
- **App Store Connect:** https://appstoreconnect.apple.com
- **Certificates, IDs & Profiles:** https://developer.apple.com/account/resources/identifiers/list
- **App Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/
- **App Store Connect Help:** https://developer.apple.com/help/app-store-connect/

---

## Important Notes

### Timeline
- Bundle ID registration is instantaneous
- App creation in App Store Connect is immediate
- Build processing: 5-10 minutes
- App Review: 24-48 hours typically (1-3 days)

### Blockers
- The app URLs (rosier.app domain) must be live and serving content before submission
- Demo account (reviewer@rosier.app) must be valid and functional
- All metadata fields must be filled in (no incomplete submissions allowed)

### Authorization
Dev 2 confirmed on April 1, 2026 that:
- Account is fully approved and operational
- No enrollment delays or restrictions
- All features are enabled
- Ready for app registration and submission

---

**Document Prepared By:** Dev 2
**Date:** April 1, 2026
**Status:** Account Assessment Complete - Ready for App Registration
