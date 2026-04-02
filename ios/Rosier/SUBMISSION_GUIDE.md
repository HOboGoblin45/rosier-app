# Rosier App Store Submission Guide

Complete step-by-step guide for submitting the Rosier app to the Apple App Store. This guide covers the entire process from preparation through post-submission monitoring.

**Project**: Rosier — Fashion Discovery iOS App
**Target Platform**: iOS 17.0+
**App Identifier**: com.rosier.app
**Last Updated**: 2026-04-01

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pre-Submission Validation](#pre-submission-validation)
3. [Create Xcode Project](#create-xcode-project)
4. [Configure Code Signing](#configure-code-signing)
5. [Build and Test Locally](#build-and-test-locally)
6. [Generate Screenshots](#generate-screenshots)
7. [Archive and Export](#archive-and-export)
8. [App Store Connect Setup](#app-store-connect-setup)
9. [App Submission](#app-submission)
10. [Post-Submission Monitoring](#post-submission-monitoring)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Apple Developer Account Requirements

1. **Apple Developer Program Enrollment**
   - Visit [developer.apple.com](https://developer.apple.com)
   - Enroll in Apple Developer Program ($99/year)
   - Verify your Apple ID and accept legal agreements

2. **App Store Connect Access**
   - Log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Add users with appropriate roles if needed
   - Verify banking and tax information is complete

3. **Required Roles**
   - Your Apple ID must have **Account Owner** or **Admin** role for initial setup
   - At least **Developer** role to build and test

### Development Environment

```bash
# Minimum requirements
Xcode:                 16.0+
macOS:                 14.0+ (Sonoma)
iOS Deployment Target: 17.0
Swift:                 5.9+

# Verify installation
xcode-select --install
xcodebuild -version
```

### Required Certificates & Profiles

1. **iOS Distribution Certificate**
   - Used to sign your app for App Store submission
   - Valid for 3 years before renewal

2. **App Store Connect API Key** (recommended)
   - For automated uploads via `xcrun altool`
   - Create at: https://appstoreconnect.apple.com/access/api

3. **Provisioning Profile**
   - Type: iOS App Store
   - App ID: com.rosier.app
   - Includes distribution certificate

### Generate Certificates

```bash
# 1. Open Keychain Access
open /Applications/Utilities/Keychain\ Access.app

# 2. Request Certificate Signing Request (CSR)
# Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority
# Use your Apple ID email as "User Email Address"
# Save to disk

# 3. Go to Apple Developer > Certificates, Identifiers & Profiles
# Upload CSR and download iOS Distribution Certificate

# 4. Import into Keychain
# Double-click downloaded certificate to import
```

---

## Pre-Submission Validation

Run the comprehensive pre-submission validator to catch issues early:

```bash
cd ios/Rosier

# Run full validation suite
./scripts/pre_submission_validator.sh --verbose

# Expected output:
# ✓ No force unwraps
# ✓ SwiftLint passes
# ✓ No TODO/FIXME in production code
# ✓ No print statements
# ✓ Info.plist exists and is valid
# ✓ Entitlements file exists
# ✓ PrivacyInfo.xcprivacy exists
# ✓ All required legal documents present
# ✓ 40+ unit tests
# ... (25+ total checks)
```

**Exit codes**:
- `0` = Ready for submission
- `1` = Fix issues before proceeding

**Common fixes**:

```bash
# Remove force unwraps
# Replace: value!
# With:    guard let value = value else { return }

# Add localization keys
# Replace: Text("Welcome")
# With:    Text("greeting.welcome")

# Use os_log instead of print
import os.log
os_log("Debug message", log: .default, type: .debug)
```

---

## Create Xcode Project

### Option A: From Source (Recommended)

```bash
# 1. Create new Xcode project using SPM structure
xcode-select --install
open ios/Rosier

# 2. Build from command line to verify
cd ios/Rosier
swift build

# Expected output:
# Building for production...
# Build complete!
```

### Option B: Create Project Manually

```bash
# 1. Create new project in Xcode
# File > New > Project
# Template: App (iOS)
# Product Name: Rosier
# Organization Identifier: com.rosier
# Interface: SwiftUI
# Deployment Target: iOS 17.0

# 2. Copy source files
cp -r Sources/* <YourXcodeProject>/Rosier/

# 3. Add resource files
cp Resources/LaunchScreen.storyboard <YourXcodeProject>/Rosier/
cp -r Resources/Assets/* <YourXcodeProject>/Rosier/Assets.xcassets/

# 4. Configure build settings
# See "Configure Code Signing" section below
```

### Verify Project Configuration

```bash
# In Xcode, navigate to Build Settings and verify:

PRODUCT_NAME: Rosier
PRODUCT_BUNDLE_IDENTIFIER: com.rosier.app
MARKETING_VERSION: 1.0.0
CURRENT_PROJECT_VERSION: 1
DEPLOYMENT_TARGET: 17.0
TARGETED_DEVICE_FAMILY: 1 (iPhone only)
```

---

## Configure Code Signing

### Step 1: Add App ID in Apple Developer

1. Go to [Apple Developer > Certificates, IDs & Profiles](https://developer.apple.com/account/resources/)
2. Click **Identifiers** → **App IDs**
3. Create new App ID:
   - Name: `Rosier`
   - Bundle ID: `com.rosier.app`
   - Capabilities:
     - Push Notifications: ✓ Enabled
     - Sign In with Apple: ✓ Enabled
     - Background Modes: ✓ Enabled

### Step 2: Configure Distribution Certificate

```bash
# In Xcode:
# 1. Preferences (Cmd+,) > Accounts
# 2. Select your Apple ID
# 3. Manage Certificates
# 4. Create Distribution certificate (iOS Distribution)
# 5. Download and import into Keychain
```

**Expected certificate chain**:
```
Your Certificate
  ↓
Apple Worldwide Developer Relations Certification Authority
  ↓
Apple Root CA
```

### Step 3: Create Provisioning Profile

In [Apple Developer Console](https://developer.apple.com/account/resources/):

1. Go to **Profiles** → **+**
2. Select **App Store**
3. Select **com.rosier.app** Bundle ID
4. Select Distribution certificate
5. Name: `Rosier Distribution`
6. Download and double-click to import

### Step 4: Configure in Xcode

```bash
# In Xcode:
# 1. Select Rosier project
# 2. Target: Rosier
# 3. Signing & Capabilities tab

# Set:
Signing Certificate:     iOS Distribution
Provisioning Profile:    Rosier Distribution (Automatic)

# Verify in Build Settings:
CODE_SIGN_IDENTITY: "iPhone Distribution"
PROVISIONING_PROFILE_SPECIFIER: Rosier Distribution
```

### Verify Signing Configuration

```bash
# Check certificates in keychain
security find-identity -v -p codesigning

# Expected output:
# 1) ABC123DEF... "iPhone Distribution: Your Name (ABC123DEF)"

# Check provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/ | grep -i rosier
```

---

## Build and Test Locally

### Build for Testing

```bash
cd ios/Rosier

# Clean build folder
xcodebuild clean -configuration Release

# Build app
xcodebuild build \
    -scheme Rosier \
    -configuration Release \
    -destination generic/platform=iOS \
    -allowProvisioningUpdates

# Expected output:
# [1/100] Compiling Swift...
# ...
# Build complete!
```

### Run Unit Tests

```bash
# Run all tests
xcodebuild test \
    -scheme Rosier \
    -destination 'platform=iOS Simulator,name=iPhone 15'

# Expected output:
# Test Suite 'RosierTests' started at ...
# Executed 40 tests, with 0 failures (0 unexpected)
# Test Plan Summary
```

### Test on Device

1. **Connect iPhone**
   - Plug in iPhone via USB
   - Trust the computer on the device
   - Wait for Xcode to finish indexing

2. **Select Device**
   - In Xcode, select iPhone from device menu (top-left)
   - Select scheme: Rosier

3. **Build and Run**
   ```bash
   xcodebuild build-for-testing \
       -scheme Rosier \
       -destination 'generic/platform=iOS' \
       -allowProvisioningUpdates
   ```

4. **Manual Testing Checklist**
   - [ ] App launches successfully
   - [ ] All screens render correctly
   - [ ] Swipe interactions work
   - [ ] Image loading works
   - [ ] Offline mode functions
   - [ ] Settings pages accessible
   - [ ] No crashes or warnings in console
   - [ ] No private API usage
   - [ ] Orientation handling correct

---

## Generate Screenshots

### Prepare HTML Mockups

Screenshot mockups are located in `docs/screenshots/`:

```bash
ls docs/screenshots/
# 01_swipe.html
# 02_dresser.html
# 03_style_dna.html
# 04_quiz.html
# 05_sale.html
```

### Generate Screenshots

```bash
cd ios/Rosier

# Generate all screenshots for all device sizes
./scripts/generate_screenshots.sh chrome

# Output directory: docs/screenshots/output/
# Generated files:
# 01_swipe_iphone16promax.png (1290×2796)
# 01_swipe_iphone14promax.png (1284×2778)
# 01_swipe_iphone14pro.png    (1179×2556)
# ... (3 sizes per screenshot)

# Verify generation
ls -lh docs/screenshots/output/
```

### Screenshot Requirements

- **Sizes**: Must match exact App Store dimensions
- **Format**: PNG (no JPEG)
- **File Size**: < 5MB each
- **Content**: No simulator bezels or notches
- **Text**: Readable at actual size (minimum 11pt font)
- **Count**: 2-10 screenshots per device type

### Upload Screenshots

Done in [App Store Connect](#app-store-connect-setup) later.

---

## Archive and Export

### Create Archive

```bash
cd ios/Rosier

# Create release archive
xcodebuild archive \
    -scheme Rosier \
    -configuration Release \
    -archivePath build/Rosier.xcarchive \
    -destination 'generic/platform=iOS' \
    -allowProvisioningUpdates

# Expected output:
# Archiving...
# Archive created at: build/Rosier.xcarchive
```

**Verify archive**:
```bash
# Check archive structure
ls -la build/Rosier.xcarchive/Products/Applications/
# Should show: Rosier.app

# Check App binary
file build/Rosier.xcarchive/Products/Applications/Rosier.app/Rosier
# Should show: Mach-O 64-bit executable arm64
```

### Export for App Store

```bash
# Create ExportOptions.plist
cat > build/ExportOptions.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>teamBundleIdentifier</key>
    <string>com.rosier.app</string>
</dict>
</plist>
EOF

# Export IPA
xcodebuild -exportArchive \
    -archivePath build/Rosier.xcarchive \
    -exportOptionsPlist build/ExportOptions.plist \
    -exportPath build/export

# Expected output:
# Exported Rosier to: build/export/Rosier.ipa

# Verify IPA
file build/export/Rosier.ipa
# Should show: Zip archive data
```

### Validate IPA

```bash
# Using Xcode's validation tool
xcrun altool --validate-app \
    --file build/export/Rosier.ipa \
    --type ios \
    --apiKey YOUR_API_KEY \
    --apiIssuer YOUR_API_ISSUER

# Expected output:
# Validating your app
# 2024-04-01 15:30:45.123 UploadTransport: Info about app...
# ✓ Validation successful
```

---

## App Store Connect Setup

### Create App Record

1. **Log in to App Store Connect**
   - Visit [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Click your icon > My Apps

2. **Create New App**
   - Click **+ Create an app**
   - Platform: iOS
   - Name: Rosier
   - Bundle ID: com.rosier.app
   - SKU: rosier-app-001
   - User Access: Full Access

### App Information

**Basic Information** tab:

```
Name:                  Rosier
Subtitle:              Discover Fashion Your Way
Description:           (Required: min 30 characters)
Privacy Policy URL:    https://rosier.app/legal/privacy
Website:               https://rosier.app
Support URL:           https://rosier.app/support

Category:              Lifestyle
Content Rights Owner:  Yes, our company owns the rights

Keywords:
- fashion
- swipe
- style
- trends
- micro-influencer
```

### Pricing and Availability

```
Price Tier:            Free
Availability:          All countries
Release Date:          Select "Release this app on the App Store immediately"
Or:                    Schedule specific date
```

### App Privacy

Navigate to **App Privacy** tab:

```
Does this app use encryption?
→ No (unless using HTTPS only)

Data & Privacy
→ Add:
   - Email Address (Account Management)
   - User ID (Account Management)
   - Product Interaction (App Functionality, Analytics)
   - Purchase History (App Functionality, Analytics)
```

**Expected result**: Privacy policy automatically generated or verified

### App Clips (Optional)

Skip for MVP. Can be added post-launch.

---

## App Submission

### Upload Build to App Store Connect

```bash
# Set API credentials
export APPLE_API_KEY="YOUR_API_KEY"
export APPLE_API_ISSUER="YOUR_API_ISSUER"

# Upload IPA
xcrun altool --upload-app \
    --file build/export/Rosier.ipa \
    --type ios \
    --apiKey "$APPLE_API_KEY" \
    --apiIssuer "$APPLE_API_ISSUER"

# Expected output:
# 2024-04-01 15:35:22.456 UploadTransport:
# Successfully uploaded to the App Store
```

**Or use automated submission script**:

```bash
./scripts/submit_to_app_store.sh appstore --notify
```

### Fill in Screenshots

In App Store Connect:

1. **Navigate to**: App Store → Localization → English (U.S.) → Screenshots

2. **For each device type** (iPhone 6.7-inch, 6.1-inch, 5.5-inch):
   - Click **+ Add Screenshot**
   - Upload PNG from `docs/screenshots/output/`
   - Add optional description:
     ```
     Screenshot 1: Swipe-based discovery. Swipe right to like, left to skip
     Screenshot 2: Your Dresser. Save favorited items and create collections
     Screenshot 3: Style DNA. View your personal style profile and trends
     Screenshot 4: Style Quiz. Personalize your fashion preferences
     Screenshot 5: Sale Calendar. Never miss sales from your favorite brands
     ```
   - Order matters: arrange 1→2→3...

### Fill in Description

```
Discover fashion tailored to your style with Rosier.

Swipe through curated collections from emerging fashion brands and micro-influencers.
Like your favorites, skip what doesn't match your vibe, and build your personal
"Dresser" of must-haves.

Features:
- Swipe-based discovery of niche fashion brands
- Personalized Style DNA profile
- Smart collections organization
- Real-time sale calendar
- Offline support
- Dark mode support

Perfect for fashion lovers who want to explore emerging designers without the overwhelm.
```

### Add Build

1. **Navigate to**: Build section
2. **Select build**: Choose the build you just uploaded
3. **Verify** it's processing (check status indicator)

### Review and Submit

1. **Version Release Notes** (required):
   ```
   Welcome to Rosier!

   Our first release includes:
   - Complete swipe-based fashion discovery
   - Personal Dresser with collections
   - Style DNA profile generation
   - Sale calendar notifications
   - Full offline support
   - Dark mode
   - Accessibility features

   We'd love your feedback! Contact us at support@rosier.app
   ```

2. **Encryption Compliance** (required):
   - Select: "This app does not contain, use or access any controlled information"

3. **IDFA** (required):
   - Select: "No, this app does not request the App Tracking Transparency framework"

4. **Export Compliance** (required):
   - Select: "No" (no encryption or restricted cryptography)

5. **Third-Party Content** (required):
   - Select: "No" or document any third-party licenses

6. **Age Rating**:
   - Complete questionnaire
   - Expected: 4+ (Content Rating: Everyone)

7. **Review Notes** (optional but recommended):
   ```
   Thank you for reviewing Rosier!

   Key Testing Areas:
   - Swipe gestures (right to like, left to skip)
   - Offline functionality (airplane mode)
   - Dark mode switching
   - Deep linking (rosier://product/<id>)

   No special setup required. App is fully functional as-is.

   Contact: support@rosier.app
   Team: Rosier
   ```

8. **Click: Submit for Review**

---

## Post-Submission Monitoring

### Check Review Status

```bash
# In App Store Connect
1. Click your app name
2. View "Build" → Status

Possible statuses:
- Waiting for Review         (queue time: 1-3 days)
- In Review                  (Apple reviewing: 24-48 hours)
- Ready for Sale             (✓ Approved!)
- Rejected                   (See rejection reason)
```

### Monitor Notifications

```bash
# Email notifications sent to your Apple ID for:
- Build submitted
- Review started
- Review completed
- App approved / rejected
```

### Handle Rejection

If rejected:

1. **Read rejection reason** carefully in App Store Connect
2. **Common reasons**:
   - Missing privacy policy (add URL)
   - Insufficient documentation (add screenshots, descriptions)
   - Crash on startup (test locally)
   - Unsupported app design (must match description)

3. **Resubmit**:
   - Make fixes locally
   - Build and archive new version
   - Increment CURRENT_PROJECT_VERSION
   - Upload new build
   - Submit new build for review

```bash
# Increment version for resubmission
open ios/Rosier/Rosier.xcodeproj/project.pbxproj

# Find: CURRENT_PROJECT_VERSION = 1;
# Change to: CURRENT_PROJECT_VERSION = 2;

# Then rebuild and resubmit
```

### Post-Launch Monitoring

Once live:

```bash
# Daily checks
1. App Store Sales (Reports tab)
2. Crashes and Exceptions (Diagnostics)
3. App Analytics (Analytics tab)
4. Customer Reviews (Reviews tab)

# Weekly checks
- Review ratings and sentiment
- Crash frequency trends
- User retention metrics
- Store optimization opportunities
```

### Update Management

For future updates:

1. Make code/design changes locally
2. Increment version numbers
3. Build, archive, export
4. Upload new build
5. Write release notes
6. Submit for review

---

## Troubleshooting

### Build Issues

**Error: "No signing certificate"**
```bash
# Solution:
# 1. Open Keychain Access
# 2. Ensure distribution certificate imported
# 3. In Xcode: Preferences > Accounts > Manage Certificates
# 4. Create iOS Distribution certificate
# 5. Restart Xcode
```

**Error: "Provisioning profile not found"**
```bash
# Solution:
# 1. Go to Apple Developer > Profiles
# 2. Verify com.rosier.app profile exists
# 3. Download and import profile
# 4. In Xcode: Shift+Cmd+K to clean build folder
# 5. Rebuild
```

**Error: "Invalid code signature"**
```bash
# Solution:
# 1. Check expiration: security find-identity -v -p codesigning
# 2. Renew certificate if expired
# 3. Delete old provisioning profiles: rm ~/Library/MobileDevice/Provisioning\ Profiles/*
# 4. Re-download from Apple Developer
# 5. Rebuild
```

### Upload Issues

**Error: "Asset validation failed"**
```bash
# Solution:
# Check App Icon:
# - Must be 1024×1024 PNG
# - No transparency
# - No rounded corners (icon will add them)

# Check Screenshots:
# - Exact dimensions required
# - No iPhone bezels
# - PNG format only
# - < 5MB each
```

**Error: "Validation failed - account issue"**
```bash
# Solution:
# 1. Verify Apple Developer Program membership active
# 2. Update agreements in App Store Connect
# 3. Verify banking/tax information complete
# 4. Test API key: xcrun altool --fetch-signing-certs -u <email>
```

### Common Rejection Reasons

| Issue | Solution |
|-------|----------|
| Crash on launch | Run on simulator, check crash logs in Xcode |
| Missing privacy policy | Add valid URL in App Info |
| Incomplete app functionality | Ensure all features work as described |
| Uses private API | Search for blacklisted APIs (see Xcode warnings) |
| No online functionality | Ensure app connects to backend/network |
| Misleading metadata | Match description with actual app features |
| Prohibited content | Review App Store Review Guidelines |

### Check App Store Review Guidelines

Apple's complete guidelines at:
https://developer.apple.com/app-store/review/guidelines/

Key sections:
- 1.2: Functionality
- 3.1: Safety
- 4: Design
- 5: Business
- 6: Support

---

## Final Checklist

Before clicking "Submit for Review":

**Code Quality**
- [ ] No compiler warnings
- [ ] All tests passing
- [ ] SwiftLint clean
- [ ] No force unwraps
- [ ] Proper error handling

**Functionality**
- [ ] App launches without crash
- [ ] All screens accessible
- [ ] Swipe gestures work
- [ ] Image loading works
- [ ] Settings configurable
- [ ] Offline mode functional

**Configuration**
- [ ] Bundle ID: com.rosier.app
- [ ] Version: 1.0.0
- [ ] Deployment: iOS 17.0+
- [ ] Device: iPhone only
- [ ] Orientation: Portrait

**Store Metadata**
- [ ] App name set
- [ ] Description complete (30+ chars)
- [ ] Category: Lifestyle
- [ ] Keywords: 5 terms
- [ ] Screenshots: All sizes, 2-10 per device
- [ ] Privacy policy URL: Valid
- [ ] Support email/URL: Valid

**Compliance**
- [ ] Privacy manifest complete
- [ ] Entitlements configured
- [ ] No hardcoded secrets
- [ ] No private API usage
- [ ] Age rating: 4+
- [ ] Encryption: None

**Certificates & Profiles**
- [ ] Distribution certificate: Valid, imported
- [ ] Provisioning profile: Imported, valid
- [ ] Team ID: Configured
- [ ] Signing: Automatic

---

## Support & Resources

**Apple Developer Documentation**
- [App Store Distribution](https://developer.apple.com/documentation/appstoreconnectapi)
- [Xcode Help](https://help.apple.com/xcode)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

**Rosier Internal Resources**
- PRODUCTION_READINESS_SUMMARY.md
- INFRASTRUCTURE_BUILD_SUMMARY.md
- Fastlane configuration: `fastlane/`

**Contact**
- Support: support@rosier.app
- Issues: GitHub Issues
- Questions: Team Slack channel

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-04-01 | Initial submission guide for Rosier v1.0 |

