# Rosier iOS - Quick Start Guide

**Goal:** Build and submit iOS app from Windows to App Store WITHOUT a Mac.

**Time to first build:** 30 minutes (after setup)

---

## 30-Minute Setup

### 1. Apple Developer Account (5 min)

```
Visit: developer.apple.com
→ Enroll in Developer Program ($99/year)
→ Save your Team ID (10 characters, e.g., ABC123XYZ9)
```

### 2. App Store Connect (5 min)

```
Visit: appstoreconnect.apple.com
→ Create new app "Rosier"
→ Bundle ID: com.rosier.app
→ Create API Key (Role: App Manager)
→ Download the private key file
```

### 3. Create Certificates (5 min)

```
developer.apple.com → Certificates, IDs & Profiles
→ Create iOS Distribution certificate
→ Download it
→ Export as base64 (PowerShell):

$cert = Get-Content -Path "cert.cer" -AsByteStream
$b64 = [System.Convert]::ToBase64String($cert)
Set-Clipboard -Value $b64
```

### 4. Create Provisioning Profile (5 min)

```
developer.apple.com → Profiles
→ Create App Store profile for com.rosier.app
→ Download .mobileprovision file
→ Export as base64:

$prof = Get-Content -Path "*.mobileprovision" -AsByteStream
$b64 = [System.Convert]::ToBase64String($prof)
Set-Clipboard -Value $b64
```

### 5. GitHub Secrets (5 min)

```
GitHub repo → Settings → Secrets and variables → Actions
→ New repository secret

Add these 7 secrets:
1. APPLE_DEVELOPER_ID = your team ID (ABC123XYZ9)
2. APP_STORE_CONNECT_KEY_ID = from API key
3. APP_STORE_CONNECT_ISSUER_ID = from API key
4. APP_STORE_CONNECT_PRIVATE_KEY = full key content
5. IOS_CERTIFICATE_BASE64 = from step 3
6. IOS_CERT_PASSWORD = certificate password
7. IOS_PROVISIONING_PROFILE_BASE64 = from step 4
```

**Done!** Pipeline is ready.

---

## Using the Pipeline

### Build (automatic)
```bash
git push origin main
# → Build starts automatically
# → Watch in GitHub Actions tab
```

### TestFlight (on tag)
```bash
git tag v1.0.0
git push origin v1.0.0
# → Build runs and uploads to TestFlight
# → Check App Store Connect in 5-15 min
```

### App Store (manual)
```
GitHub → Actions → iOS CI/CD → Run workflow
Select: appstore
# → Build and submit to App Store
# → Status: Waiting for Review
```

---

## What the Pipeline Does

1. **Generates Xcode project** from Swift Package Manager
2. **Builds and tests** on macOS cloud runner
3. **Signs with your certificate** automatically
4. **Uploads to TestFlight** (on tag push)
5. **Submits to App Store** (on manual trigger)

**All from Windows. All automatically.**

---

## Complete Process (Step by Step)

### Step 1: Prepare App Metadata

Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com):

1. Click Rosier app
2. Fill in Description, Screenshots, Keywords
3. Set Support URL and Privacy Policy
4. Set Category: Lifestyle
5. Save

### Step 2: Create First Release

On Windows:
```bash
git tag v1.0.0
git push origin v1.0.0
```

Wait 5-15 minutes for TestFlight to process.

### Step 3: Verify in TestFlight

1. App Store Connect → Rosier → TestFlight
2. Status should be "Ready to Test"
3. Add yourself as internal tester
4. Download in TestFlight app
5. Test the app

### Step 4: Submit to App Store

GitHub Actions:
1. Click Actions tab
2. Click iOS CI/CD
3. Click "Run workflow"
4. Select branch: main
5. Select build_type: appstore
6. Click "Run workflow"

Wait 1-2 minutes for submission.

### Step 5: Monitor Review

App Store Connect:
1. Rosier → Build
2. Watch status change:
   - "Waiting for Review" (1-3 days)
   - "In Review" (24-48 hours)
   - "Ready for Sale" (approved!)

---

## Common Commands

```bash
# View latest builds
git tag -l | tail -5

# Create release
git tag v1.0.1
git push origin v1.0.1

# View workflow status
# Visit: GitHub → Actions tab

# Download test artifacts
# GitHub → Actions → Latest run → Artifacts
```

---

## Troubleshooting

**"Build failed - certificate error"**
- Check GitHub secrets are set correctly
- Verify IOS_CERTIFICATE_BASE64 is valid base64
- Re-export certificate from Apple Developer

**"Tests are failing"**
- Fix code locally
- Commit and push
- GitHub Actions will re-run

**"TestFlight build not showing"**
- Wait 5-15 minutes for processing
- Check App Store Connect → Build section
- Status should change from "Processing" to "Ready to Test"

**"Out of Actions minutes"**
- Free tier: 2,000 min/month for macOS
- Current pipeline: ~45 min per full run
- You have plenty (~360 min/month usage)

**More help:** See `WINDOWS_TO_APP_STORE_GUIDE.md`

---

## File Locations

| File | Purpose |
|---|---|
| `.github/workflows/ios.yml` | CI/CD pipeline |
| `ios/Rosier/project.yml` | Xcode project definition |
| `ios/Rosier/scripts/generate_xcodeproj.sh` | Generate Xcode project |
| `ios/Rosier/scripts/setup_signing.sh` | Setup code signing |
| `ios/Rosier/fastlane/Fastfile` | Build automation |
| `WINDOWS_TO_APP_STORE_GUIDE.md` | Complete guide (read this!) |
| `iOS_CI_CD_README.md` | Technical documentation |

---

## Success Timeline

| Step | Time | Status |
|---|---|---|
| Setup GitHub Secrets | 30 min | One-time |
| Create and push tag | 2 min | Push v1.0.0 |
| Build in GitHub Actions | 45 min | Watch Actions tab |
| TestFlight processing | 5-15 min | Check App Store Connect |
| Team testing (TestFlight) | 2-3 days | Optional |
| Submit to App Store | 1 min | Click "Run workflow" |
| App Store review | 24-48 hrs | Apple reviews |
| **Total to "Ready for Sale"** | **3-4 days** | **Everything automated** |

---

## No Mac Required

This entire process works on Windows because:

1. **XcodeGen** - generates Xcode project from config
2. **GitHub Actions** - provides macOS runners in cloud
3. **Fastlane** - automates build and upload
4. **Your browser** - creates certificates in Apple portal
5. **Git** - triggers builds via tags

Charlie never needs to touch a Mac.

---

## Next: Read the Full Guide

For detailed instructions with screenshots and troubleshooting:

→ Open `WINDOWS_TO_APP_STORE_GUIDE.md`

---

## Help

**Questions?** See the FAQ in `WINDOWS_TO_APP_STORE_GUIDE.md`

**Issues?** Check `.github/workflows/ios.yml` logs in GitHub Actions

**Support?** Contact the team in #rosier-development Slack

---

**Version:** 1.0
**Created:** 2026-04-01
**Time to read:** 5 minutes
**Time to implement:** 30 minutes
**Status:** Ready to use

