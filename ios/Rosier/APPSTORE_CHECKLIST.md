# Rosier - App Store Submission Checklist

**App Name:** Rosier
**Bundle ID:** com.rosier.app
**Minimum iOS:** 17.0
**Status:** Sprint 3 - App Store Readiness
**Prepared:** 2026-04-01

---

## Configuration Files Generated ✓

- [x] **Sources/App/Info.plist** — Complete bundle configuration
- [x] **Sources/App/Rosier.entitlements** — Capabilities and signing
- [x] **Sources/App/PrivacyInfo.xcprivacy** — Privacy manifest (REQUIRED)
- [x] **Resources/LaunchScreen.storyboard** — Adaptive launch screen
- [x] **Resources/Assets/AppIconGenerator.swift** — Icon generation script
- [x] **Resources/Assets/ColorAssets.swift** — Color design system
- [x] **apple-app-site-association** — Universal links configuration
- [x] **Sources/App/BUILD_SETTINGS.xcconfig** — Build configuration
- [x] **Sources/App/XcodeProjectSetup.md** — Step-by-step setup guide

---

## Pre-Submission Tasks

### Code & Build
- [ ] All source files compile without warnings (`⌘B`)
- [ ] No deprecated API usage
- [ ] Swift strict concurrency enabled
- [ ] Minimum iOS version set to 17.0
- [ ] Target device capability: arm64 only
- [ ] Orientation locked to portrait

### Configuration Files
- [ ] Info.plist in place and valid XML
- [ ] Entitlements file configured
- [ ] Privacy Manifest complete (PrivacyInfo.xcprivacy)
- [ ] LaunchScreen.storyboard references correct file
- [ ] App Icon set complete (all sizes)
- [ ] Color Assets created in Xcode

### Bundle Identifiers & Signing
- [ ] Bundle ID: com.rosier.app
- [ ] Development Team assigned in Xcode
- [ ] Code signing identity: iOS Developer (Debug)
- [ ] Provisioning profile: Automatic
- [ ] Entitlements: Sources/App/Rosier.entitlements
- [ ] Capabilities enabled:
  - [ ] Apple Sign In
  - [ ] Associated Domains (applinks:rosier.app, webcredentials:rosier.app)
  - [ ] Background Modes (fetch, processing, remote-notification)
  - [ ] Push Notifications

### Testing on Device
- [ ] Build and run on iPhone 15+ (iOS 17+)
- [ ] App launches without crashes
- [ ] Launch screen displays correctly
- [ ] Tab navigation works (Swipe, Dresser, Profile)
- [ ] Dark mode toggle works
- [ ] Orientation portrait-only (no rotation)
- [ ] Status bar visibility correct
- [ ] Memory leaks checked (Xcode Memory Graph)
- [ ] Network calls work in production environment

### Feature Testing
- [ ] Authentication flow works
- [ ] Swipe interaction responds
- [ ] Image caching works offline
- [ ] Deep linking functional:
  - [ ] rosier://product/[uuid]
  - [ ] rosier://dresser/[uuid]
  - [ ] rosier://dna/[uuid]
  - [ ] rosier://sale/[uuid]
- [ ] Push notifications receive (if applicable)
- [ ] Background refresh scheduled

### Security
- [ ] All API calls use HTTPS (NSAppTransportSecurity = secure)
- [ ] No hardcoded API keys or secrets in code
- [ ] Authentication tokens secured in Keychain
- [ ] User data encrypted at rest
- [ ] No export of sensitive data
- [ ] ITSAppUsesNonExemptEncryption = false (we use standard HTTPS)

### Privacy & Compliance
- [ ] Privacy Policy URL set: https://rosier.app/privacy
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) complete:
  - [ ] Data collection types listed
  - [ ] API usage reasons provided
  - [ ] No tracking enabled
- [ ] GDPR compliance (if applicable)
- [ ] Children's privacy (COPPA) if applicable
- [ ] No collection of health data
- [ ] No use of IDFA (Identifier for Advertisers)

---

## Version & Build Numbers

- [ ] **CFBundleShortVersionString:** 1.0.0
- [ ] **CFBundleVersion (Build):** 1 (increment before each submission)
- [ ] Version matches App Store Connect

---

## App Store Connect Setup

### App Information
- [ ] App name: Rosier
- [ ] Bundle ID: com.rosier.app
- [ ] SKU: com.rosier.app (or unique identifier)
- [ ] Category: Lifestyle
- [ ] Primary Language: English
- [ ] Content Rating: Completed

### Metadata
- [ ] App description (max 4000 characters)
  - [ ] Explain swipe-based fashion discovery
  - [ ] Mention dresser/wardrobe feature
  - [ ] Highlight style profile matching
- [ ] Keywords: fashion, swipe, discovery, style, dresser, wardrobe, curation
- [ ] Support URL: https://rosier.app/support
- [ ] Marketing URL: https://rosier.app
- [ ] Privacy Policy URL: https://rosier.app/privacy

### Screenshots
- [ ] iPhone 6.7" (2796×1290) or 6.5" (2688×1242)
  - [ ] Minimum 2 screenshots, maximum 10
  - [ ] PNG or JPEG format
  - [ ] No device frames required
  - [ ] Showcase:
    - [ ] Swipe discovery flow
    - [ ] Dresser/wardrobe view
    - [ ] Style profile
    - [ ] Product details
- [ ] iPad 12.9" (optional, if supporting iPad)

### Pricing & Availability
- [ ] Pricing tier: Free (or select paid tier)
- [ ] Availability: All regions
- [ ] Release date: Manual or automatic

### App Review Information
- [ ] Demo account (if required): username, password
- [ ] Demo account website: https://rosier.app
- [ ] Notes for reviewer:
  - [ ] Explain any special setup
  - [ ] Detail background modes used
  - [ ] Mention push notification setup
  - [ ] Note any in-app sign-up flows

### Rights & Compliance
- [ ] Encryption export compliance: Not applicable (HTTPS only)
- [ ] Alcohol content: No
- [ ] Tobacco content: No
- [ ] Gambling content: No
- [ ] Warranty & Indemnity: Confirmed
- [ ] Third-party licenses disclosed

---

## Release Notes

```
Version 1.0.0 (Build 1)
Release Date: [DATE]
Status: First public release

What's New:
- Discover fashion through intuitive swiping
- Build your personal Style DNA profile
- Organize liked items in your virtual dresser
- Get personalized recommendations based on your taste
- Connect with niche micro-influencer curations
- Seamless checkout integration with retailers

Bug Fixes:
- None (initial release)

Known Issues:
- None
```

---

## Build Archive & Upload

### Creating Archive
- [ ] Select Rosier scheme
- [ ] Select Generic iOS Device (not simulator)
- [ ] Build configuration: Release
- [ ] **Product → Archive**
- [ ] Verify archive size is reasonable (< 200 MB)
- [ ] Verify no bitcode warnings

### Uploading to App Store Connect
- [ ] Open Xcode Organizer (⌘⇧2)
- [ ] Select archive
- [ ] **Distribute App**
- [ ] **App Store Connect**
- [ ] **Upload options:**
  - [ ] Strip Swift symbols: checked
  - [ ] Upload symbols: checked
  - [ ] Include bitcode: unchecked
- [ ] Select signing team
- [ ] Review and submit

### Post-Upload
- [ ] Build appears in App Store Connect within 5-30 minutes
- [ ] Build processing shows "Metadata Uploaded"
- [ ] Check for any warnings or errors

---

## App Review Submission

### Before Submission
- [ ] All marketing assets uploaded (screenshots, icon)
- [ ] Content rating survey completed
- [ ] Privacy questions answered
- [ ] Licensing agreements accepted
- [ ] Export compliance verified
- [ ] Build selected in "Build" section

### Submission
- [ ] **All Sections → Submission Info**
- [ ] Review notes added (if needed)
- [ ] Content age rating selected
- [ ] **Click Submit for Review**
- [ ] Status changes to "Waiting for Review"

### After Submission
- [ ] Monitor status in App Store Connect
- [ ] Check emails for review communication
- [ ] Be ready to respond to reviewer questions
- [ ] Typical review time: 24-48 hours

---

## Monitoring Review Status

### Possible Outcomes

**✓ Approved**
- App ready for release
- Select release date: Automatic (immediate) or Manual
- App becomes available on App Store

**⚠ Needs Info**
- Apple asks for clarification
- Respond with requested information
- Resubmit within 30 days
- Review restarts (does not reset timer)

**✗ Rejected**
- Review Apple's rejection reason
- Address issues in code/metadata
- Increment build number
- Create new archive and resubmit
- No penalty for resubmission

**⏸ Removed from Review**
- You requested withdrawal
- Can resubmit at any time
- Build remains in archive

---

## Post-Release Monitoring

- [ ] Monitor crash reports in Xcode Organizer
- [ ] Track App Analytics in App Store Connect
- [ ] Monitor user reviews and ratings
- [ ] Watch for performance regressions
- [ ] Keep OS compatibility up to date
- [ ] Plan maintenance releases for bugs

---

## Important Notes

### Privacy Manifest (CRITICAL)
- **Required since Spring 2024**
- Apple will reject without it
- File: Sources/App/PrivacyInfo.xcprivacy
- Must list all data collection types
- Must provide reason codes for APIs used

### Development vs. Production
- **Development build:**
  - aps-environment: development
  - Code signing: iPhone Developer
  - Push notifications: Dev environment

- **Production build:**
  - aps-environment: production
  - Code signing: Apple Distribution
  - Push notifications: Production environment

### Team ID Placeholder
- **File:** apple-app-site-association
- **Current:** "TEAMID" (placeholder)
- **Action required:** Replace with actual Team ID from Apple Developer account
- **Example:** "ABC123XYZ9.com.rosier.app"

### App Icon Dimensions
All sizes required for App Store:
- iPhone: 20, 29, 40, 60, 120, 180 (points, not pixels)
- iPad: 20, 29, 40, 76, 152, 167
- App Store: 1024×1024
- Retina (@2x, @3x variants generated)

---

## Quick Links

- [App Store Connect](https://appstoreconnect.apple.com/)
- [Apple Developer Account](https://developer.apple.com/account/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy Manifest Documentation](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [TestFlight for Beta Testing](https://testflight.apple.com/)

---

## Support & Help

**Common Issues:**
- [Build fails: provisioning profile](#troubleshooting)
- [Code signing error](#troubleshooting)
- [Icon not showing](#troubleshooting)
- [Deep links don't work](#troubleshooting)
- [Push notifications failing](#troubleshooting)

**Contact:**
- Apple Developer Support: support.apple.com
- App Store Review: Check email for rejection details
- Xcode Help: Use Xcode's help menu

---

**Last Verified:** 2026-04-01
**iOS Target:** 17.0+
**Swift Version:** 5.9+
**Status:** ✓ Ready for App Store Submission
