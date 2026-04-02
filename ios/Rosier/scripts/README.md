# Rosier App Store Submission Scripts

Automated tools for validating, building, and submitting the Rosier app to the Apple App Store.

## Quick Start

```bash
cd ios/Rosier

# 1. Validate app readiness
./scripts/pre_submission_validator.sh --verbose

# 2. Generate screenshots
./scripts/generate_screenshots.sh chrome

# 3. Submit to TestFlight
./scripts/submit_to_app_store.sh testflight --notify

# 4. Submit to App Store
./scripts/submit_to_app_store.sh appstore --notify
```

## Scripts Overview

### 1. pre_submission_validator.sh

**Purpose**: Comprehensive pre-submission checklist validation

**Usage**:
```bash
./scripts/pre_submission_validator.sh [--verbose] [--fix-report]
```

**What it checks** (30+ validations):

**Code Quality**
- Force unwrap count
- SwiftLint compliance
- TODO/FIXME comments
- Print statements
- Hardcoded secrets
- Compiler warnings

**Required Files**
- Info.plist exists and valid XML
- Entitlements file exists
- Privacy manifest (PrivacyInfo.xcprivacy)
- Launch screen storyboard
- App icons (1024×1024)

**App Store Requirements**
- ITSAppUsesNonExemptEncryption set
- NSPrivacyTracking declared
- Apple Sign-In configured
- Push notification entitlements
- Keychain sharing setup
- Bundle identifier configured
- App version set correctly
- Minimum iOS version specified

**Legal & Compliance**
- Terms of Service document exists
- Privacy Policy document exists
- Affiliate Disclosure document exists
- Documents are not empty

**Localization**
- Localizable.strings present
- Limited hardcoded text strings

**Test Coverage**
- Test files exist
- 40+ test methods (recommended)
- XCTest properly imported
- Mock objects defined

**Configuration**
- Package.swift exists and valid
- SwiftLint configuration file
- Git properly configured

**Accessibility**
- Accessibility labels configured
- Dynamic type support
- Accessibility elements marked

**Performance**
- Memory leak detection (weak self patterns)
- Async/await usage
- Thread management

**Security**
- SSL/TLS configuration
- Keychain usage for secure storage
- No hardcoded URLs
- Privacy manifest configured

**Exit Codes**:
- `0` = All critical checks passed, ready for submission
- `1` = Critical failures detected, fix before submitting

**Example Output**:
```
╔══════════════════════════════════════════════════════════╗
║   Rosier Pre-App Store Submission Validator              ║
║   Version: 1.0.0                                          ║
╚══════════════════════════════════════════════════════════╝

=== VALIDATION SUMMARY ===
Total Checks:     35
Passed:           35
Failed:           0
Warnings:         2
Pass Rate:        100%

[SUCCESS] All critical checks passed! Ready for submission.
```

---

### 2. submit_to_app_store.sh

**Purpose**: Automated App Store submission with full validation

**Usage**:
```bash
./scripts/submit_to_app_store.sh [mode] [--skip-validation] [--notify]
```

**Modes**:
- `testflight` (default) - Submit to TestFlight for beta testing
- `appstore` - Submit to App Store for public release

**Options**:
- `--skip-validation` - Skip pre-flight validation (not recommended)
- `--notify` - Send Slack notification on completion

**Prerequisites**:
```bash
# Set environment variables
export APPLE_TEAM_ID="ABC123XYZ"  # Your Apple Developer Team ID
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."  # Optional

# Or store in ~/.zshrc or ~/.bashrc
echo 'export APPLE_TEAM_ID="ABC123XYZ"' >> ~/.zshrc
source ~/.zshrc
```

**What it does**:

1. **Environment Validation**
   - Checks Xcode version (16+)
   - Verifies code signing identities
   - Validates provisioning profiles
   - Tests available tools (xcodebuild, xcrun, git)

2. **Code Quality Validation**
   - Scans for force unwraps
   - Checks for TODO/FIXME comments
   - Looks for print statements
   - Validates Swift syntax

3. **Required Files Check**
   - Info.plist
   - Entitlements
   - Privacy manifest
   - Launch screen
   - App icons

4. **App Store Metadata**
   - Bundle identifier configured
   - Version numbers set
   - Legal documents present
   - Privacy manifest valid

5. **Build Archive**
   - Clean build folder
   - Create release archive
   - Validate archive structure
   - Verify app binary

6. **Export IPA**
   - Generate export options
   - Export to IPA format
   - Validate IPA file
   - Report file size

7. **Validation & Upload**
   - Validate IPA with altool
   - Upload to App Store Connect
   - Create git tag
   - Update submission record

8. **Notification**
   - Send Slack message (if webhook configured)
   - Log submission details

**Example Usage**:

```bash
# Submit to TestFlight with notifications
./scripts/submit_to_app_store.sh testflight --notify

# Submit to App Store
./scripts/submit_to_app_store.sh appstore --notify

# Skip validation if urgent
./scripts/submit_to_app_store.sh testflight --skip-validation

# Output goes to: build/
# - build/Rosier.xcarchive
# - build/export/Rosier.ipa
# - build/build.log
# - build/export.log
# - build/validation.log
```

**Example Output**:
```
╔══════════════════════════════════════════════════════════╗
║   Rosier App Store Submission                            ║
║   Mode: testflight                                        ║
╚══════════════════════════════════════════════════════════╝

[INFO] >>> Running environment checks...
[SUCCESS] Xcode version: 16.0.1
[SUCCESS] Found valid code signing identities
[SUCCESS] Found 3 provisioning profiles

[INFO] >>> Building Archive...
[SUCCESS] Archive built successfully
[SUCCESS] Archive validated

[INFO] >>> Exporting IPA...
[SUCCESS] IPA exported successfully (Size: 45 MB)

[INFO] >>> Uploading...
[SUCCESS] IPA uploaded successfully

=== SUBMISSION SUMMARY ===
Mode:          testflight
Archive:       build/Rosier.xcarchive
IPA:           build/export/Rosier.ipa
Timestamp:     2026-04-01 15:30:45

[SUCCESS] Submission complete!
```

---

### 3. generate_screenshots.sh

**Purpose**: Generate App Store screenshots from HTML mockups

**Usage**:
```bash
./scripts/generate_screenshots.sh [browser] [--verbose]
```

**Browser Options**:
- `chrome` (default) - Use Chrome headless
- `puppeteer` - Use Puppeteer (Node.js)

**What it does**:

1. **Environment Validation**
   - Checks for Chrome/Chromium
   - Verifies screenshot directory
   - Creates output directory

2. **Screenshot Generation**
   - Processes each HTML file in docs/screenshots/
   - Generates 3 device sizes:
     - iPhone 16 Pro Max: 1290×2796
     - iPhone 14 Pro Max: 1284×2778
     - iPhone 14 Pro: 1179×2556
   - Captures as PNG images

3. **Validation**
   - Checks file sizes
   - Verifies dimensions (if ImageMagick available)
   - Reports generation status

4. **Optimization**
   - Compresses PNG files
   - Maintains quality
   - Reduces upload size

5. **Documentation**
   - Generates SCREENSHOTS.md
   - Lists all generated files
   - Provides upload instructions

**Prerequisites**:
```bash
# Install Chrome/Chromium
# macOS
brew install chromium

# Ubuntu/Debian
sudo apt-get install chromium-browser

# Optional: ImageMagick for optimization
sudo apt-get install imagemagick
```

**Example Usage**:

```bash
# Generate all screenshots (Chrome headless)
./scripts/generate_screenshots.sh chrome

# Generate with verbose output
./scripts/generate_screenshots.sh chrome --verbose

# Output directory structure:
# docs/screenshots/output/
# ├── 01_swipe_iphone16promax.png
# ├── 01_swipe_iphone14promax.png
# ├── 01_swipe_iphone14pro.png
# ├── 02_dresser_iphone16promax.png
# └── ... (3 sizes per screenshot)
```

**Example Output**:
```
╔══════════════════════════════════════════════════════════╗
║   Rosier App Store Screenshot Generator                  ║
║   Version: 1.0.0                                          ║
║   Browser: chrome                                         ║
╚══════════════════════════════════════════════════════════╝

=== GENERATING APP STORE SCREENSHOTS ===

Processing: 01_swipe.html
[INFO] Generating: 01_swipe_iphone16promax.png (1290 x 2796)
[SUCCESS] Generated: 01_swipe_iphone16promax.png
[INFO] Generating: 01_swipe_iphone14promax.png (1284 x 2778)
[SUCCESS] Generated: 01_swipe_iphone14promax.png
[INFO] Generating: 01_swipe_iphone14pro.png (1179 x 2556)
[SUCCESS] Generated: 01_swipe_iphone14pro.png

[SUCCESS] All screenshots validated

=== SCREENSHOT GENERATION SUMMARY ===
Output Directory:      docs/screenshots/output
Screenshots Generated: 15
Screenshots Failed:    0

[SUCCESS] Screenshot generation complete!

Files ready for App Store submission:
-rw-r--r--  1.2M  01_swipe_iphone16promax.png
-rw-r--r--  1.1M  01_swipe_iphone14promax.png
-rw-r--r--  0.9M  01_swipe_iphone14pro.png
...
```

---

## Workflow Example

### Complete Submission Workflow

```bash
# 1. Start in project root
cd ios/Rosier

# 2. Run pre-submission validation
echo "=== Validating readiness ==="
./scripts/pre_submission_validator.sh --verbose

# If validation fails, fix issues and re-run

# 3. Generate screenshots
echo "=== Generating screenshots ==="
./scripts/generate_screenshots.sh chrome

# 4. Commit all changes
git add -A
git commit -m "Release v1.0.0 - App Store submission"

# 5. Submit to TestFlight first
echo "=== Submitting to TestFlight ==="
./scripts/submit_to_app_store.sh testflight --notify

# 6. Wait for TestFlight processing and internal testing
echo "Testing on TestFlight..."
# (In App Store Connect, send to testers and collect feedback)

# 7. After testing approval, submit to App Store
echo "=== Submitting to App Store ==="
./scripts/submit_to_app_store.sh appstore --notify

# 8. Monitor submission status in App Store Connect
echo "Check: https://appstoreconnect.apple.com/"
```

---

## Troubleshooting

### Script Execution Issues

**Error: "Permission denied"**
```bash
# Make script executable
chmod +x ./scripts/*.sh

# Or run with bash
bash ./scripts/pre_submission_validator.sh
```

**Error: "Command not found: xcodebuild"**
```bash
# Install Xcode command-line tools
xcode-select --install

# Or specify path
/usr/bin/xcodebuild -version
```

### Validation Failures

**Issue: Force unwraps detected**
```bash
# Search for force unwraps
grep -rn '!' Sources/ --include='*.swift' | grep -v '//' | grep -v '!='

# Replace with optional binding
# Before: value!
# After: guard let value = value else { return }
```

**Issue: Hardcoded secrets found**
```bash
# Use environment variables or Config files
# Before: let apiKey = "sk_live_..."
# After: let apiKey = Bundle.main.infoDictionary?["API_KEY"]
```

### Build Failures

**Error: "No provisioning profile"**
```bash
# Renew provisioning profile
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/

# Download from Apple Developer Console
# Re-run submission script
```

**Error: "Invalid code signature"**
```bash
# List available certificates
security find-identity -v -p codesigning

# Renew distribution certificate in Apple Developer
# Re-import to Keychain
# Retry build
```

---

## Environment Variables

### Required Variables

```bash
# Apple Developer Team ID (required for submission)
export APPLE_TEAM_ID="ABC123XYZ"
```

### Optional Variables

```bash
# Slack webhook for notifications
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."

# API key for automated uploads
export APPLE_API_KEY="your_api_key_id"
export APPLE_API_ISSUER="your_issuer_id"

# Custom Xcode path (usually auto-detected)
export XCODE_PATH="/Applications/Xcode.app"
```

### Store in Shell Profile

```bash
# Add to ~/.zshrc or ~/.bashrc
cat >> ~/.zshrc <<EOF
# Rosier App Store Submission
export APPLE_TEAM_ID="ABC123XYZ"
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
EOF

# Reload
source ~/.zshrc
```

---

## Configuration Files

### Package.swift

SPM manifest with all targets and dependencies.

```swift
// Build/run:
swift build
swift run Rosier

// Or via Xcode:
open Package.swift
```

### Fastlane Integration

Scripts integrate with existing Fastlane setup:

```bash
# Match signing certificates
fastlane match appstore

# Upload to TestFlight via Fastlane
fastlane beta

# Submit to App Store via Fastlane
fastlane release
```

---

## Monitoring & Logs

All scripts generate detailed logs:

```bash
# Submission logs
build/build.log        # xcodebuild output
build/export.log       # Export process output
build/validation.log   # App Store validation
build/upload.log       # Upload status

# View logs
tail -f build/build.log    # Real-time build log
grep ERROR build/*.log     # Find errors
```

---

## Support & Help

**Common Issues**:
- See SUBMISSION_GUIDE.md for complete step-by-step instructions
- Check Troubleshooting section in SUBMISSION_GUIDE.md
- Review Apple's guidelines: https://developer.apple.com/app-store/review/guidelines/

**Resources**:
- [Xcode Help](https://help.apple.com/xcode)
- [App Store Connect Help](https://help.apple.com/app-store-connect)
- [Swift Package Manager](https://swift.org/package-manager/)

**Contact**:
- Team: support@rosier.app
- Issues: GitHub Issues
- Slack: #app-store-submission

---

## Version History

| Script | Version | Last Updated | Status |
|--------|---------|--------------|--------|
| pre_submission_validator.sh | 1.0.0 | 2026-04-01 | Production |
| submit_to_app_store.sh | 1.0.0 | 2026-04-01 | Production |
| generate_screenshots.sh | 1.0.0 | 2026-04-01 | Production |

