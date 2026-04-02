# Complete Guide: Building and Submitting Rosier iOS App from Windows

This guide walks through the entire process of building, testing, and submitting the Rosier iOS app to the App Store WITHOUT owning a Mac. Charlie builds and submits from Windows using GitHub Actions.

**Updated:** 2026-04-01
**For:** Rosier v1.0.0
**Status:** Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup (One-time)](#initial-setup-one-time)
4. [Setting up GitHub Secrets](#setting-up-github-secrets)
5. [Creating Certificates & Provisioning Profiles](#creating-certificates--provisioning-profiles)
6. [Triggering Builds](#triggering-builds)
7. [Monitoring Builds](#monitoring-builds)
8. [TestFlight Deployment](#testflight-deployment)
9. [App Store Submission](#app-store-submission)
10. [Troubleshooting](#troubleshooting)
11. [Cost Estimates](#cost-estimates)
12. [FAQ](#faq)

---

## Overview

The Rosier iOS app uses a fully automated CI/CD pipeline running on GitHub Actions macOS runners. This allows Charlie to:

- Build the app entirely in the cloud (no local Mac needed)
- Run comprehensive tests automatically
- Generate provisioning profiles and certificates in the browser
- Deploy to TestFlight with a single git tag
- Submit to the App Store with a manual trigger
- All while working from Windows

**Pipeline Architecture:**

```
Windows (Charlie)
    ↓
    └─→ Push to GitHub
         ↓
         ├─→ GitHub Actions (macOS-14 runner)
         │    ├─ Build & Test (automatic on every push)
         │    ├─ Snapshot Tests (on main/develop)
         │    └─ Archive & Sign (on version tags)
         │
         ├─→ TestFlight (on tag push v*)
         │    └─ Upload IPA
         │
         └─→ App Store (manual workflow_dispatch)
              └─ Submit for Review
```

---

## Prerequisites

Before starting, ensure you have:

### 1. Apple Developer Account ($99/year)

- Visit [developer.apple.com](https://developer.apple.com)
- Enroll in Apple Developer Program
- Accept legal agreements
- **Save your Team ID** (shown as 10-character code, e.g., `ABC123XYZ9`)

### 2. App Store Connect Account

- Automatically created with Developer account
- Login at [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- Verify **Agreements, Tax, and Banking** are complete

### 3. GitHub Account with Rosier Repo

- Repo: [your-org]/rosier
- Must have admin access to configure secrets
- Actions enabled (default)

### 4. Xcode (for local testing only)

- Not required for CI builds
- Optional for testing locally on Mac when available
- Xcode 16.0+ recommended

### 5. Certificate Password

- Create a strong password for the distribution certificate
- You'll need this when exporting the certificate

---

## Initial Setup (One-time)

### Step 1: Create App ID in Apple Developer

1. Open [developer.apple.com](https://developer.apple.com) in browser
2. Sign in with your Apple ID
3. Go to **Certificates, IDs & Profiles**
4. Select **Identifiers** → **+** (top right)
5. Choose **App IDs**
6. Fill in:
   - **Type:** App IDs
   - **Description:** Rosier Fashion App
   - **Bundle ID:** `com.rosier.app` (exact)
   - **Capabilities:**
     - ✓ Push Notifications
     - ✓ Sign in with Apple
     - ✓ Background Modes
7. Click **Register** → **Done**

**Save the App ID** for later reference.

### Step 2: Create App Store Connect Record

1. Open [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+ New App**
3. Fill in:
   - **Platform:** iOS
   - **Name:** Rosier
   - **Bundle ID:** `com.rosier.app` (from the dropdown - must match step 1)
   - **SKU:** rosier-app-001 (any unique identifier)
   - **User Access:** Full Access
4. Click **Create**

Your app record is now created. You can return later to fill in metadata, screenshots, etc.

### Step 3: Create App Store Connect API Key

This allows the CI pipeline to upload builds automatically without manual interaction.

1. Go to [appstoreconnect.apple.com/access/api](https://appstoreconnect.apple.com/access/api)
2. Click **+** (top left) → **Generate API Key**
3. Configure:
   - **Name:** Rosier CI Bot
   - **Role:** App Manager (minimum required for uploads)
4. Click **Generate** → **Done**
5. **Important:** Click the key to view it and download immediately
6. Save the downloaded file (contains Key ID and Issuer ID)

**What you'll see:**
```
Key ID: ABC123DEFG
Issuer ID: 12345678-1234-5678-1234-567812345678
```

Save these values - you'll need them for GitHub secrets.

---

## Setting up GitHub Secrets

GitHub Secrets are encrypted environment variables that the CI pipeline uses. Charlie needs to configure these in the Windows browser.

### Step 1: Navigate to GitHub Settings

1. Open GitHub in browser
2. Go to your Rosier repository
3. Click **Settings** (top right)
4. Left sidebar → **Secrets and variables** → **Actions**
5. Click **New repository secret**

### Step 2: Add Apple Developer ID

1. Click **New repository secret**
2. **Name:** `APPLE_DEVELOPER_ID`
3. **Value:** Your 10-character Team ID (e.g., `ABC123XYZ9`)
   - Found at [developer.apple.com](https://developer.apple.com) → Account settings → Team ID
4. Click **Add secret**

### Step 3: Add App Store Connect API Key Credentials

Repeat this 3 times with different keys:

**Secret 1:**
- **Name:** `APP_STORE_CONNECT_KEY_ID`
- **Value:** (from the API key you downloaded, looks like `ABC123DEFG`)

**Secret 2:**
- **Name:** `APP_STORE_CONNECT_ISSUER_ID`
- **Value:** (from the API key, looks like `12345678-1234-5678-1234-567812345678`)

**Secret 3:**
- **Name:** `APP_STORE_CONNECT_PRIVATE_KEY`
- **Value:** The entire private key content
  - Go back to [appstoreconnect.apple.com/access/api](https://appstoreconnect.apple.com/access/api)
  - Click the key you just created
  - Download the private key file
  - Open it in a text editor
  - Copy the entire content (including `-----BEGIN` and `-----END` lines)
  - Paste into the secret

### Step 4: Add Distribution Certificate & Profile

This is done in the next section [Creating Certificates & Provisioning Profiles](#creating-certificates--provisioning-profiles).

**Summary of all GitHub Secrets needed:**

```
APPLE_DEVELOPER_ID                    # Your 10-char Team ID
APP_STORE_CONNECT_KEY_ID              # API Key ID
APP_STORE_CONNECT_ISSUER_ID           # API Issuer ID
APP_STORE_CONNECT_PRIVATE_KEY         # Full private key content
IOS_CERTIFICATE_BASE64                # Certificate (in next section)
IOS_CERT_PASSWORD                     # Certificate password (in next section)
IOS_PROVISIONING_PROFILE_BASE64       # Profile (in next section)
```

---

## Creating Certificates & Provisioning Profiles

Certificates and provisioning profiles allow the CI pipeline to sign the app for App Store distribution. These are created in the Apple Developer portal.

### Step 1: Create Distribution Certificate

1. Go to [developer.apple.com](https://developer.apple.com)
2. Click **Certificates, IDs & Profiles** → **Certificates**
3. Click **+** (top right)
4. Choose **iOS Distribution**
5. Click **Continue**
6. Follow the **Certificate Signing Request (CSR)** instructions:
   - You need to generate a CSR on a Mac
   - **If you don't have a Mac:** Use an online CSR generator
     - Open [this online tool](https://csrgenerator.com/) or similar
     - Company: Rosier
     - Common Name: your-email@example.com
     - Download the CSR file
7. Upload the CSR file
8. Click **Download** to get the certificate file (`.cer`)
9. **Save this file** - you'll need it to extract the base64 value

**Converting to Base64 (Windows):**

1. Open **PowerShell** as Administrator
2. Navigate to where you saved the certificate:
   ```powershell
   cd C:\Users\YourUsername\Downloads
   ```
3. Convert to base64:
   ```powershell
   $cert = Get-Content -Path "ios_distribution.cer" -AsByteStream
   $base64 = [System.Convert]::ToBase64String($cert)
   Set-Clipboard -Value $base64
   ```
4. Paste into GitHub secret `IOS_CERTIFICATE_BASE64`

**Note:** The CI pipeline expects the certificate in `.p12` format (PKCS12). If you have a `.cer` file, you can convert it using an online tool or macOS Keychain.

### Step 2: Create Provisioning Profile

1. Go to [developer.apple.com](https://developer.apple.com)
2. Click **Certificates, IDs & Profiles** → **Profiles**
3. Click **+** (top right)
4. Choose **App Store**
5. Select the Bundle ID: `com.rosier.app`
6. Select the distribution certificate you just created
7. Name: `Rosier Distribution`
8. Click **Generate** → **Download**
9. **Save the `.mobileprovision` file**

**Converting to Base64 (Windows):**

1. Open PowerShell as Administrator:
   ```powershell
   $profile = Get-Content -Path "Rosier_Distribution.mobileprovision" -AsByteStream
   $base64 = [System.Convert]::ToBase64String($profile)
   Set-Clipboard -Value $base64
   ```
2. Paste into GitHub secret `IOS_PROVISIONING_PROFILE_BASE64`

### Step 3: Add Certificate Password to GitHub

1. Go to GitHub Settings → Secrets
2. Click **New repository secret**
3. **Name:** `IOS_CERT_PASSWORD`
4. **Value:** The password you used to create the certificate
5. Click **Add secret**

---

## Triggering Builds

The CI pipeline is triggered automatically or manually. Here's how Charlie triggers builds from Windows.

### Build Type 1: Automatic (on every push)

Any push to `main` or `develop` branch automatically:
1. Builds the app for simulator
2. Runs SwiftLint (code quality)
3. Runs unit tests
4. Uploads test results to GitHub

**How to trigger:**
1. Make a commit locally on Windows
2. Push to GitHub:
   ```bash
   git push origin main
   ```
3. Watch the build in **Actions** tab on GitHub

### Build Type 2: TestFlight (on tag push)

Pushing a tag like `v1.0.0` triggers:
1. All tests pass
2. Archive the app
3. Sign with distribution certificate
4. Upload to TestFlight
5. Build appears in App Store Connect

**How to trigger (Windows):**

```bash
# Using Git Bash or PowerShell
# Make sure code is committed first
git tag v1.0.0
git push origin v1.0.0
```

**In GitHub UI:**
1. Go to **Code** tab
2. Right sidebar → **Releases** → **Draft a new release**
3. Choose tag: v1.0.0
4. Title: Rosier 1.0.0
5. Click **Publish release**

This pushes the tag and triggers TestFlight build.

### Build Type 3: App Store (manual dispatch)

Manual trigger to submit directly to App Store review.

**How to trigger (Windows):**

1. Open GitHub in browser
2. Go to Rosier repo
3. Click **Actions** tab
4. Left sidebar → **iOS CI/CD** workflow
5. Click **Run workflow** button
6. Select:
   - **Branch:** main
   - **Build type:** appstore
7. Click **Run workflow**

This builds the app and automatically submits it for App Store review.

---

## Monitoring Builds

### View Build Status in GitHub

1. Open Rosier repo in browser
2. Click **Actions** tab
3. See list of recent workflow runs
4. Click on a workflow to see details

**Status indicators:**
- Green checkmark = Success
- Red X = Failed
- Yellow dot = In progress

### View Build Logs

1. Click on a workflow run
2. Click **Build & Test** job
3. Expand sections to see logs:
   - "Generate Xcode project" - Project generation
   - "Run unit tests" - Test results
   - "Build archive" - Build status
   - "Upload to TestFlight" - Upload results

### Download Build Artifacts

1. Click on a workflow run
2. Scroll down to **Artifacts** section
3. Download:
   - `test-results` - Test reports
   - `testflight-build` - IPA file
   - `app-store-build` - Archive for App Store

### Understand Build Failures

Common failures and fixes:

**"Certificate not found"**
- Check GitHub secrets are set correctly
- Verify `IOS_CERTIFICATE_BASE64` is valid base64

**"Provisioning profile error"**
- Ensure profile includes App ID `com.rosier.app`
- Check profile matches bundle ID exactly

**"SwiftLint failed"**
- Fix code warnings locally
- Run SwiftLint: `swiftlint lint`
- Commit fixes and push again

**"Tests failed"**
- Check test failure details in logs
- Fix failing tests locally
- Run tests: `xcodebuild test -scheme Rosier`

---

## TestFlight Deployment

After a successful tag push (e.g., `v1.0.0`), the build automatically uploads to TestFlight.

### View Build in TestFlight

1. Open [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **Rosier** app
3. Go to **TestFlight** tab
4. Click **iOS Builds**
5. Wait for build to process (5-15 minutes)
6. Status changes from "Processing" to "Ready to Test"

### Add Testers

1. In TestFlight tab, click **Testers**
2. Click **+ Internal Testing Group**
3. Name: "Alpha Testers"
4. Add your email addresses
5. Click **Create**

Internal testers can install via TestFlight app immediately without App Review.

### Distribute to External Testers

For external beta testing:

1. Go to **TestFlight** → **External Testing Group**
2. Click **+ Create**
3. Name: "Beta Testers"
4. Set **Max testers:** (e.g., 10000)
5. Add tester emails or sharing link
6. Click **Create**

**Note:** External distribution requires App Review (1-2 days).

---

## App Store Submission

Once TestFlight build is ready, submit it to App Store review.

### Step 1: Complete App Store Metadata

Before submission, fill in app information in App Store Connect.

1. Open [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **Rosier** → **App Information**

Fill in:

**General Information:**
- App Name: Rosier
- Subtitle: Discover Fashion Your Way
- Primary Category: Lifestyle
- Secondary Category: (optional) Shopping
- Content Rights Owner: Yes

**Description (required, min 30 chars):**
```
Discover fashion tailored to your style with Rosier.

Swipe through curated collections from emerging fashion brands
and micro-influencers. Like your favorites, skip what doesn't
match your vibe, and build your personal "Dresser" of must-haves.

Features:
- Swipe-based discovery of niche fashion brands
- Personalized Style DNA profile
- Smart collections organization
- Real-time sale calendar
- Offline support
- Dark mode
```

**Keywords:**
- fashion
- swipe
- discovery
- style
- microinfluencers

**Support URL & Privacy Policy:**
- Support: https://rosier.app/support
- Privacy Policy: https://rosier.app/legal/privacy

### Step 2: Add Screenshots

1. Click **App Store** → **Localization** → **English (U.S.)**
2. Click **Screenshots**
3. For each device size (iPhone 6.7", 6.1", 5.5"):
   - Click **+ Add Screenshot**
   - Drag and drop PNG file
   - Add description (optional)

**Screenshot Requirements:**
- Size: Exact device dimensions
- Format: PNG only (no JPEG)
- Quality: 72+ DPI
- No simulator bezels or status bars

Example dimensions:
- iPhone 6.7": 1290 x 2796
- iPhone 6.1": 1170 x 2532
- iPhone 5.5": 1080 x 1920

### Step 3: Submit for Review

1. Go to **App Store** → **Pricing and Availability**
2. Set **Pricing Tier:** Free
3. Set **Availability:** All regions (or specific regions)
4. Click **Release This App** → "Immediately"

Now go to **Version Release Notes:**

1. Type release notes:
```
Welcome to Rosier!

Version 1.0.0 includes:
- Complete swipe-based fashion discovery
- Personal Dresser for saving favorites
- Style DNA personalization
- Real-time sale alerts
- Offline browsing support
- Dark mode
- Full accessibility support

We'd love your feedback! Contact support@rosier.app
```

2. Click **Submission Info** (top right)
3. Check all required fields:
   - **Content Rights:** "This app does not violate..."
   - **IDFA:** "No"
   - **Encryption:** "No"
   - **Third-Party Content:** "No"
   - **Export Compliance:** "No"

4. Complete **Age Ratings Questionnaire**
5. Review and click **Submit for Review**

**Status Timeline:**
- Submitted → "Waiting for Review" (1-3 days)
- "In Review" (24-48 hours)
- "Ready for Sale" = Approved!
- Or "Rejected" (see rejection reason)

### Step 4: Monitor Review Status

Check status daily in App Store Connect:

1. Click **Rosier** → **Build**
2. Watch for status updates
3. Check email for Apple notifications

---

## Troubleshooting

### Build Failures

**XcodeGen generation failed**
- Check project.yml syntax
- Verify all source paths exist
- Run locally (if Mac available): `xcodegen generate`

**Certificate validation failed**
- Verify certificate is in PKCS12 format
- Check `IOS_CERT_PASSWORD` is correct
- Re-download certificate from Apple Developer

**Provisioning profile mismatch**
- Ensure bundle ID is exactly `com.rosier.app`
- Check profile is for App Store (not development)
- Re-download profile from Apple Developer

**Code signing error during archive**
- Verify `APPLE_DEVELOPER_ID` matches your Team ID
- Check certificate is imported correctly
- Ensure provisioning profile is installed

### Test Failures

**Unit tests failing**
- Fix code locally
- Run tests: `xcodebuild test -scheme Rosier`
- Commit fixes and push

**SwiftLint warnings**
- Fix code style issues
- Run: `swiftlint lint --fix`
- Push fixes

**Snapshot test changes**
- Review snapshots for visual regressions
- If correct, update snapshots in Tests directory
- Commit snapshot changes

### App Store Submission Issues

**Rejected: Missing privacy policy**
- Ensure privacy policy URL is valid and accessible
- Check URL works in browser: https://rosier.app/legal/privacy

**Rejected: Crash on launch**
- Test build locally in simulator
- Check crash logs in Xcode
- Fix code issues

**Rejected: Incomplete app description**
- Check description is > 30 characters
- Ensure all required fields are filled
- Add screenshots for all device sizes

**Build processing stuck**
- Wait 30 minutes, then refresh
- Check App Store Connect status page
- Contact Apple Support if > 1 hour

### GitHub Actions Issues

**Workflow not triggering**
- Verify branch is `main` or `develop`
- Check paths include `ios/**`
- Verify Actions are enabled in repo settings

**Cannot access secrets**
- Confirm you have admin access to repo
- Check secret names match exactly (case-sensitive)
- Verify secrets are set in correct repo (not organization-level)

**Out of Actions minutes**
- Free tier provides 2,000 macOS minutes/month
- Monitor usage in **Settings** → **Billing and usage**
- Upgrade plan if needed (pay-as-you-go or fixed tier)

---

## Cost Estimates

### Apple Developer Program

- **One-time setup:** None (already $99/year from enrollment)
- **App Store submission:** Free
- **Certificates & profiles:** Free
- **TestFlight distribution:** Free

**Total annual Apple cost:** $99

### GitHub Actions

GitHub provides free Actions minutes:

**Free tier:**
- 2,000 minutes/month of macOS runners
- Resets monthly

**Usage per build:**
- Build & Test: ~15 minutes
- Snapshot Tests: ~10 minutes
- TestFlight: ~20 minutes
- Total per full pipeline: ~45 minutes

**Monthly estimate:**
- 2 builds/week × 45 min = 360 minutes
- Stays well within 2,000 minute free tier

**If exceeding free tier:**
- $0.08 per minute for macOS runners
- $360/month for unlimited macOS builds
- GitHub also offers free tier increases for popular projects

**Recommendation:** Stick to free tier. Cost is essentially zero.

### Alternative: Cloud Mac Rental (if needed)

If GitHub Actions usage is insufficient, rent a cloud Mac:

- **MacStadium:** $79/month for dedicated cloud Mac
- **MacinCloud:** $3/hour or $30/day
- Use if: Doing 100+ builds/month or need local development

---

## FAQ

### Q: Do I need a Mac to build the app?

**A:** No. GitHub Actions provides macOS runners in the cloud. Builds run automatically on GitHub's hardware.

### Q: Can I build locally on Windows?

**A:** Not directly. Swift compilation requires macOS. Options:
1. Use a virtual Mac (UTM, Parallels) - complex setup
2. Rent cloud Mac for local testing
3. Use GitHub Actions (recommended)

### Q: What if I don't have an Apple Developer account?

**A:** You must enroll in the Apple Developer Program ($99/year). This is a requirement to distribute on the App Store.

### Q: How long does App Store review take?

**A:** Typically 24-48 hours. Sometimes as fast as 12 hours, rarely longer than 3 days.

### Q: What if my app gets rejected?

**A:** Apple will email the rejection reason. Common fixes:
1. Add missing privacy policy
2. Fix crashing on launch
3. Match app description with actual features
4. Remove private API usage

Resubmit after fixing.

### Q: Can I submit updates automatically?

**A:** Not directly to App Store. You must submit for review each time. Setup:
1. Manual trigger: Click "Run workflow" in GitHub
2. Or: Create a scheduled workflow to trigger weekly
3. Manually approve before each submission

### Q: What if I exceed GitHub Actions minutes?

**A:** GitHub charges $0.08/minute for macOS runners. To avoid:
1. Consolidate builds (push less frequently)
2. Upgrade to higher plan
3. Use MacStadium or MacinCloud instead

### Q: Can I rollback if something breaks?

**A:** Yes:
1. In App Store Connect, you can remove a build
2. Resubmit previous build for review
3. Or submit a new fix

### Q: How do I set up CI for automated screenshots?

**A:** The pipeline supports screenshot capture via fastlane. See `ios/Rosier/fastlane/Fastfile` for the `screenshots` lane.

### Q: Is the GitHub Actions pipeline secure?

**A:** Yes. Certificates and credentials are:
1. Encrypted in GitHub Secrets
2. Only accessible to Actions in this repository
3. Never logged or displayed in output
4. Deleted after build completes

### Q: Can my team review builds before submission?

**A:** Yes. Use TestFlight:
1. Tag builds (v1.0.0)
2. Builds upload to TestFlight automatically
3. Add team members as internal testers
4. They install via TestFlight app
5. After team approves, submit to App Store

### Q: What's included in the build?

**A:** The CI pipeline:
1. Generates Xcode project from Swift Package Manager
2. Runs SwiftLint for code quality
3. Builds for simulator
4. Runs all unit tests
5. Generates coverage reports
6. Archives the app
7. Signs with distribution certificate
8. Creates IPA file
9. Uploads to TestFlight

---

## Next Steps

1. **Enroll in Apple Developer Program** ($99)
2. **Create app ID and App Store Connect record** (5 min)
3. **Generate App Store Connect API key** (5 min)
4. **Create distribution certificate and provisioning profile** (15 min)
5. **Configure GitHub Secrets** (10 min)
6. **Push first tag to trigger build** (1 min)
7. **Monitor build in GitHub Actions** (5 min)
8. **Review build in TestFlight** (verify it works)
9. **Complete App Store metadata** (15 min)
10. **Submit to App Store** (1 min)

**Total setup time:** ~1 hour

---

## Support & Resources

**Apple Developer Documentation**
- [App Store Connect Help](https://help.apple.com/app-store-connect)
- [iOS App Development](https://developer.apple.com/ios/)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)

**GitHub Actions**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Managing GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

**Rosier Internal**
- CI/CD Pipeline: `.github/workflows/ios.yml`
- Build Scripts: `ios/Rosier/scripts/`
- Fastlane Config: `ios/Rosier/fastlane/Fastfile`
- Xcode Project: `ios/Rosier/project.yml`

**Contact**
- Issues: GitHub Issues
- Support: support@rosier.app
- Team: Slack #rosier-development

---

## Checklists

### Pre-Submission Checklist

- [ ] GitHub secrets configured (all 7)
- [ ] App ID created in Apple Developer
- [ ] Distribution certificate created and exported
- [ ] Provisioning profile created and exported
- [ ] App Store Connect record created
- [ ] App metadata filled in
- [ ] Screenshots uploaded (2-10 per device size)
- [ ] Privacy policy URL valid
- [ ] Support URL configured
- [ ] Age rating set

### TestFlight Checklist

- [ ] TestFlight build appears in App Store Connect
- [ ] Status shows "Ready to Test"
- [ ] Internal testers added
- [ ] Testers can install app via TestFlight
- [ ] App launches without crash
- [ ] All features functional
- [ ] No console errors

### App Store Submission Checklist

- [ ] All TestFlight tests passed
- [ ] Release notes added
- [ ] Encryption compliance verified
- [ ] IDFA tracking disabled
- [ ] Export compliance filled
- [ ] Age rating complete
- [ ] App description matches features
- [ ] Ready for Review button visible
- [ ] Final review of all fields

---

**Version History**

| Date | Version | Notes |
|------|---------|-------|
| 2026-04-01 | 1.0 | Initial guide for Rosier v1.0 |

