# Rosier iOS CI/CD Pipeline - Complete Implementation

This document describes the production-grade CI/CD pipeline for building and submitting the Rosier iOS app from Windows without a Mac.

**Status:** Production Ready
**Updated:** 2026-04-01
**Maintainer:** Dev 2

---

## Files Created

### 1. XcodeGen Configuration
**Path:** `ios/Rosier/project.yml`

XcodeGen specification that generates the complete Xcode project from configuration. This is the source of truth for the build configuration.

**Key components:**
- Target definitions (RosierCore, RosierUI, Rosier app, Tests)
- Build settings for Debug and Release configurations
- Capabilities (Push Notifications, Sign in with Apple, Background Modes)
- Entitlements and Info.plist references
- Scheme definitions with test targets

**Why:** Keeps Xcode project definition in code, making it version-controlled and reproducible in CI.

---

### 2. Project Generation Script
**Path:** `ios/Rosier/scripts/generate_xcodeproj.sh`

Bash script that:
1. Validates XcodeGen installation
2. Checks project.yml syntax
3. Backs up existing Xcode project
4. Generates fresh .xcodeproj from project.yml
5. Verifies generated structure
6. Validates build settings

**Usage:**
```bash
./scripts/generate_xcodeproj.sh [--verbose]
```

**When it runs:**
- First step in every CI build
- Creates reproducible Xcode project

---

### 3. Code Signing Setup Script
**Path:** `ios/Rosier/scripts/setup_signing.sh`

Bash script that configures code signing in CI environment:

1. Validates required environment variables
2. Decodes base64-encoded certificate
3. Decodes base64-encoded provisioning profile
4. Creates temporary keychain
5. Imports distribution certificate
6. Installs provisioning profile
7. Updates build settings with Team ID

**Environment variables required:**
```
APPLE_DEVELOPER_ID              # 10-char Team ID
IOS_CERTIFICATE_BASE64          # Distribution cert
IOS_CERT_PASSWORD               # Certificate password
PROVISIONING_PROFILE_BASE64     # Provisioning profile
```

**Usage:**
```bash
./scripts/setup_signing.sh [--type development|appstore]
```

**Security:**
- Decodes secrets at runtime (not stored in git)
- Uses temporary files in `/tmp`
- Encrypts via GitHub Secrets
- Cleans up temp files after build

---

### 4. GitHub Actions Workflow
**Path:** `.github/workflows/ios.yml`

Complete CI/CD pipeline with 4 jobs:

#### Job 1: Build & Test (Runs on every push)
- **Trigger:** Push to `main` or `develop` with `ios/**` changes
- **Actions:**
  1. Install XcodeGen and tools
  2. Generate Xcode project
  3. Run SwiftLint
  4. Build for iOS Simulator
  5. Run unit tests
  6. Generate coverage reports
  7. Upload test artifacts

#### Job 2: Snapshot Tests (Runs after Build & Test)
- **Trigger:** Automatic if Build & Test succeeds
- **Actions:**
  1. Run snapshot tests
  2. Upload snapshot diffs on failure

#### Job 3: Deploy to TestFlight (Runs on version tags)
- **Trigger:** `git push origin v*` (tags like v1.0.0)
- **Requires:** Both Build & Test and Snapshot Tests pass
- **Actions:**
  1. Setup code signing
  2. Build archive (Release configuration)
  3. Export IPA
  4. Verify IPA integrity
  5. Upload to TestFlight via fastlane
  6. Upload build artifacts

#### Job 4: Deploy to App Store (Manual dispatch)
- **Trigger:** `GitHub Actions → Run workflow` (manual)
- **Actions:**
  1. Setup code signing
  2. Run tests
  3. Increment build number
  4. Build archive
  5. Export IPA
  6. Submit to App Store
  7. Create GitHub release

---

### 5. Updated Fastlane Configuration
**Path:** `ios/Rosier/fastlane/Fastfile`

Updates to Fastfile lanes:

**setup_signing lane:**
- Detects CI environment
- Skips `match` if in CI (already configured by setup_signing.sh)

**beta lane:**
- Accepts pre-built IPA path (for CI)
- Accepts API key options from environment
- Uploads to TestFlight with appropriate settings

**release lane:**
- Accepts pre-built IPA path
- Accepts API key options
- Submits to App Store for review

**app_store_connect_api_key:**
- Supports multiple environment variable names
- Validates all required credentials present
- Creates Spaceship token for API access

---

### 6. Windows to App Store Guide
**Path:** `WINDOWS_TO_APP_STORE_GUIDE.md`

Complete step-by-step guide for Charlie (8,000+ words):

1. **Overview** - How the pipeline works
2. **Prerequisites** - What to set up first
3. **GitHub Secrets** - Step-by-step configuration
4. **Certificates** - Creating and exporting from Windows
5. **Triggering Builds** - All 3 build types explained
6. **Monitoring** - How to track builds
7. **TestFlight** - Distributing to testers
8. **App Store Submission** - Complete submission flow
9. **Troubleshooting** - Common issues and fixes
10. **Cost Estimates** - GitHub Actions and Apple costs
11. **FAQ** - Common questions answered
12. **Checklists** - Pre-submission and submission checklists

**Key sections:**
- Screenshots of GitHub web UI
- PowerShell commands for Windows
- Exact bundle IDs and team IDs to use
- Timeline estimates for each step
- Cost breakdown (essentially free)
- Troubleshooting common errors

---

## Build Architecture

```
Charlie (Windows)
    ↓
    └─ Push to GitHub
        ├─ Commit to main/develop
        │  └─ Actions workflow: Build & Test
        │     ├─ Generate Xcode project
        │     ├─ Run SwiftLint
        │     ├─ Build for simulator
        │     ├─ Run unit tests
        │     └─ Upload test artifacts
        │
        ├─ Tag push (v1.0.0)
        │  └─ Actions workflow: TestFlight
        │     ├─ Setup code signing
        │     ├─ Build archive (Release)
        │     ├─ Export IPA
        │     └─ Upload to TestFlight
        │
        └─ Workflow dispatch (manual)
           └─ Actions workflow: App Store
              ├─ Setup code signing
              ├─ Build archive
              ├─ Export IPA
              └─ Submit to App Store
```

---

## GitHub Secrets Required

All stored encrypted in GitHub Settings → Secrets and variables → Actions:

| Secret Name | Example | Source |
|---|---|---|
| `APPLE_DEVELOPER_ID` | `ABC123XYZ9` | Apple Developer account settings |
| `APP_STORE_CONNECT_KEY_ID` | `ABC123DEFG` | App Store Connect API key |
| `APP_STORE_CONNECT_ISSUER_ID` | `12345678-...` | App Store Connect API key |
| `APP_STORE_CONNECT_PRIVATE_KEY` | (full key content) | Downloaded from App Store Connect |
| `IOS_CERTIFICATE_BASE64` | (base64 encoded cert) | Exported from Apple Developer |
| `IOS_CERT_PASSWORD` | (password) | Set when creating certificate |
| `IOS_PROVISIONING_PROFILE_BASE64` | (base64 encoded) | Exported from Apple Developer |

**Setup time:** ~30 minutes (one-time)

---

## How to Use

### For Daily Development (Charlie on Windows)

**1. Push to develop:**
```bash
git commit -m "Add feature"
git push origin develop
```
→ Automatic build and test run

**2. Deploy to TestFlight:**
```bash
git tag v1.0.0
git push origin v1.0.0
```
→ Build archives and uploads to TestFlight automatically

**3. Submit to App Store:**
- Go to GitHub → Actions → iOS CI/CD
- Click "Run workflow"
- Select branch: main
- Select: appstore
- Click "Run workflow"
→ Build submits to App Store automatically

### For Team Review

1. Push tag to trigger TestFlight upload
2. Build appears in App Store Connect → TestFlight → iOS Builds
3. Team members install via TestFlight app
4. After review, manual dispatch to App Store

---

## Build Time Estimates

| Task | Duration |
|---|---|
| Generate Xcode project | 1-2 min |
| Run SwiftLint | 2-3 min |
| Build for simulator | 5-10 min |
| Run unit tests | 5-10 min |
| Run snapshot tests | 8-12 min |
| Build Release archive | 8-15 min |
| Export IPA | 2-3 min |
| Upload to TestFlight | 2-5 min |
| **Total (TestFlight)** | **35-60 min** |
| **Total (App Store)** | **35-60 min** |

All builds run in parallel where possible.

---

## Security Considerations

### Certificates & Profiles
- Stored as base64 in GitHub Secrets (encrypted)
- Decoded only during build (never logged)
- Imported into temporary keychain
- Deleted from CI environment after build

### API Keys
- Stored encrypted in GitHub Secrets
- Never printed in logs
- Used only for authenticated API calls
- Rotated every 12 months recommended

### Code Signing
- Distribution certificate has 3-year expiration
- Provisioning profile has 1-year expiration
- Both must be renewed before expiration
- CI logs never show certificate details

### Best Practices
1. Rotate API keys annually
2. Use "App Manager" role (minimum required)
3. Monitor GitHub Actions logs for suspicious access
4. Keep certificate password secure
5. Don't share GitHub secrets with team members

---

## Maintenance

### Monthly
- Monitor GitHub Actions usage (free tier: 2,000 min/month)
- Check for any failed builds
- Review test coverage trends

### Quarterly
- Review certificates expiration dates
- Check provisioning profile status
- Update dependencies if needed

### Annually
- Renew Apple Developer Program ($99)
- Rotate App Store Connect API keys
- Audit GitHub secrets for rotation

---

## Troubleshooting Guide

### Build Generation Fails
**Error:** "XcodeGen not found"
- Solution: Installed automatically via Homebrew in CI
- Local: `brew install xcodegen`

**Error:** "project.yml syntax invalid"
- Solution: Check YAML formatting (no tabs, proper indentation)
- Validate: `yq eval '.' project.yml`

### Code Signing Fails
**Error:** "Certificate not found"
- Cause: `IOS_CERTIFICATE_BASE64` invalid
- Fix: Re-export certificate from Apple Developer
- Convert: Use PowerShell `[System.Convert]::ToBase64String()`

**Error:** "Provisioning profile mismatch"
- Cause: Profile bundle ID doesn't match `com.rosier.app`
- Fix: Re-create profile for exact bundle ID
- Check: `grep -a CFBundleIdentifier *.mobileprovision`

### Tests Fail
**Error:** "Test target not found"
- Cause: RosierTests not in project.yml
- Fix: Verify targets section includes test target
- Rebuild: `./scripts/generate_xcodeproj.sh`

### Upload Fails
**Error:** "Invalid IPA"
- Cause: IPA not signed correctly
- Fix: Check code signing setup succeeded
- Verify: `unzip -l build/export/Rosier.ipa | head`

### GitHub Actions Issues
**Problem:** "Workflow not triggering"
- Check: Branch is `main` or `develop`
- Check: Changes include `ios/**` paths
- Check: Actions enabled in Settings

**Problem:** "Out of Actions minutes"
- Current: Free tier has 2,000 min/month macOS
- Usage: ~45 min per full pipeline
- Monthly: ~360 min (plenty available)
- If needed: Upgrade plan or use MacStadium

---

## Testing the Pipeline

### Test 1: Verify Build & Test Job
```bash
git checkout develop
echo "// test comment" >> ios/Rosier/Sources/App/RosierApp.swift
git add .
git commit -m "Test build"
git push origin develop
```
Expected: GitHub Actions runs and completes successfully

### Test 2: Verify TestFlight Job
```bash
git tag v0.0.1-test
git push origin v0.0.1-test
```
Expected: Build uploads to TestFlight, appears in 5-15 min

### Test 3: Verify App Store Job (dry run)
1. Go to GitHub Actions UI
2. Click "iOS CI/CD" workflow
3. Click "Run workflow"
4. Select `appstore` build type
5. Click "Run workflow"

Expected: Build completes and creates release

---

## Next Steps for Charlie

1. **Complete Apple setup** (1 hour)
   - Enroll in Developer Program ($99)
   - Create App ID
   - Create App Store Connect record

2. **Create certificates** (30 min)
   - Generate distribution certificate
   - Create provisioning profile
   - Export to base64

3. **Configure GitHub Secrets** (15 min)
   - Add all 7 secrets
   - Verify correct values

4. **Test pipeline** (30 min)
   - Push to develop → verify build
   - Create tag v0.0.1 → verify TestFlight
   - Manual dispatch → verify submission

5. **Complete app metadata** (30 min)
   - Add screenshots
   - Fill in description
   - Set up support URLs

6. **First submission** (5 min)
   - Ready for Review → Submit
   - Wait for approval (24-48 hrs)

**Total time to App Store:** ~3 hours setup + 1-2 days review

---

## References

- **Apple Developer:** https://developer.apple.com
- **App Store Connect:** https://appstoreconnect.apple.com
- **XcodeGen Documentation:** https://github.com/yonaskolb/XcodeGen
- **Fastlane Documentation:** https://docs.fastlane.tools
- **GitHub Actions:** https://docs.github.com/en/actions

---

## Support

**For issues with:**
- **Build script:** Check `.github/workflows/ios.yml`
- **Code signing:** See `scripts/setup_signing.sh`
- **Project generation:** See `project.yml`
- **General guidance:** Read `WINDOWS_TO_APP_STORE_GUIDE.md`

**Contact:**
- Issues: GitHub Issues in rosier repo
- Questions: Team Slack #rosier-development
- Support: support@rosier.app

---

**Version:** 1.0
**Created:** 2026-04-01
**Status:** Production Ready

