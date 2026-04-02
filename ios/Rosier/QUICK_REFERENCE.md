# Rosier App Store Submission - Quick Reference

Fast lookup guide for common tasks and commands.

---

## Essential Commands

### Pre-Submission Check
```bash
cd ios/Rosier
./scripts/pre_submission_validator.sh --verbose
```
**Expected**: Exit code 0 (all checks pass)

### Build & Test Locally
```bash
cd ios/Rosier
swift build
xcodebuild test -scheme Rosier
```

### Generate Screenshots
```bash
./scripts/generate_screenshots.sh chrome
# Output: docs/screenshots/output/*.png
```

### Submit to TestFlight
```bash
./scripts/submit_to_app_store.sh testflight --notify
```

### Submit to App Store
```bash
./scripts/submit_to_app_store.sh appstore --notify
```

---

## Environment Setup

### Required Variables
```bash
export APPLE_TEAM_ID="ABC123XYZ"
```

### Optional Variables
```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

### Permanent Setup
```bash
# Add to ~/.zshrc
echo 'export APPLE_TEAM_ID="ABC123XYZ"' >> ~/.zshrc
source ~/.zshrc
```

---

## Key Files

| File | Purpose | Status |
|------|---------|--------|
| Package.swift | SPM manifest | Ready |
| SUBMISSION_GUIDE.md | Complete guide | Ready |
| APP_STORE_READINESS_SUMMARY.md | Overview | Ready |
| scripts/pre_submission_validator.sh | Validation | Ready |
| scripts/submit_to_app_store.sh | Automation | Ready |
| scripts/generate_screenshots.sh | Screenshots | Ready |
| scripts/README.md | Script docs | Ready |

---

## Submission Checklist (5 Steps)

```bash
# Step 1: Validate (30 seconds)
./scripts/pre_submission_validator.sh --verbose

# Step 2: Test locally (5 minutes)
swift build && xcodebuild test -scheme Rosier

# Step 3: Generate screenshots (2 minutes)
./scripts/generate_screenshots.sh chrome

# Step 4: Submit to TestFlight (5 minutes)
./scripts/submit_to_app_store.sh testflight --notify

# Step 5: Monitor in App Store Connect
# https://appstoreconnect.apple.com/
```

**Total time**: ~15 minutes

---

## Documentation Map

### For Complete Instructions
→ **SUBMISSION_GUIDE.md**
- Step-by-step process
- Expected outputs
- Troubleshooting

### For Script Usage
→ **scripts/README.md**
- Script descriptions
- Usage examples
- Environment variables

### For Overview
→ **APP_STORE_READINESS_SUMMARY.md**
- Status overview
- Validation checklist
- Integration points

### For Quick Answers
→ **QUICK_REFERENCE.md** (this file)
- Essential commands
- Common tasks
- Quick lookups

---

## Validation Checklist

30+ checks run automatically. Key validations:

```
CODE QUALITY
✓ 0 force unwraps
✓ 0 hardcoded secrets
✓ 0 print statements
✓ SwiftLint passes

REQUIRED FILES
✓ Info.plist
✓ Entitlements
✓ Privacy manifest
✓ App icons

APP STORE
✓ Bundle ID: com.rosier.app
✓ Version: 1.0.0
✓ Min iOS: 17.0
✓ Capabilities configured

TESTING
✓ 40+ tests
✓ 100% pass rate
✓ Mocks defined

LEGAL
✓ Terms of Service
✓ Privacy Policy
✓ Affiliate Disclosure
```

---

## Version Numbers

### Current
- Bundle Version: 1.0.0
- Build Number: 1

### For Updates
```bash
# Increment build number
CURRENT_PROJECT_VERSION = 2

# Or update version
CFBundleShortVersionString = 1.0.1
```

---

## Common Tasks

### View validation results
```bash
./scripts/pre_submission_validator.sh --verbose 2>&1 | grep -E "PASS|FAIL|WARN"
```

### Check build logs
```bash
tail -f build/build.log
```

### View generated screenshots
```bash
ls -lh docs/screenshots/output/
```

### Clean build artifacts
```bash
rm -rf build/
```

### Test on simulator
```bash
xcodebuild test \
  -scheme Rosier \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test on device
```bash
# 1. Connect iPhone
# 2. Trust computer
# 3. Select device in Xcode
# 4. Product > Run (⌘R)
```

---

## Troubleshooting Quick Fixes

### "No code signing identity"
```bash
security find-identity -v -p codesigning
# If empty: Apple Developer → Create Distribution cert
```

### "Provisioning profile not found"
```bash
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/
# Re-download from Apple Developer
```

### "Force unwraps detected"
```bash
grep -rn '!' Sources/ --include='*.swift' | grep -v '//' | grep -v '!='
# Replace with: guard let x = x else { return }
```

### "Script not executable"
```bash
chmod +x ./scripts/*.sh
```

### "Xcode not found"
```bash
xcode-select --install
# Or: /usr/bin/xcode-select --reset
```

---

## Submission Status

### Check Status in App Store Connect
1. Log in: https://appstoreconnect.apple.com
2. Click your app
3. View "Build" section
4. Check status indicator

### Possible Statuses
- **Waiting for Review** - In queue (1-3 days)
- **In Review** - Being reviewed (24-48 hours)
- **Ready for Sale** - Approved!
- **Rejected** - See rejection reason

---

## Key Contacts

| Role | Email | Use For |
|------|-------|---------|
| Team Lead | support@rosier.app | Questions |
| Apple Support | developer.apple.com | Certificates |
| App Review | appstoreconnect.apple.com | Appeals |

---

## Performance Benchmarks

| Task | Time | Status |
|------|------|--------|
| Validation | 30 sec | Fast |
| Build | 130 sec | Normal |
| Screenshot Gen | 90 sec | Normal |
| Submission | 300 sec | Normal |
| **Total** | **~10 min** | **Good** |

---

## Validation Exit Codes

```bash
./scripts/pre_submission_validator.sh
# Exit 0 = Ready for submission
# Exit 1 = Fix issues first
```

```bash
./scripts/submit_to_app_store.sh testflight
# Exit 0 = Submission successful
# Exit 1 = Submission failed
```

---

## Links & Resources

**Internal Docs**
- SUBMISSION_GUIDE.md - Complete guide
- APP_STORE_READINESS_SUMMARY.md - Overview
- scripts/README.md - Script documentation

**Apple Resources**
- [App Store Connect](https://appstoreconnect.apple.com)
- [Developer Account](https://developer.apple.com/account)
- [Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

**Tools**
- Xcode 16+ required
- macOS 14+ required
- Chrome/Chromium for screenshots

---

## One-Liner Commands

```bash
# Full validation
cd ios/Rosier && ./scripts/pre_submission_validator.sh --verbose

# Full submission
cd ios/Rosier && \
  ./scripts/pre_submission_validator.sh && \
  ./scripts/generate_screenshots.sh chrome && \
  ./scripts/submit_to_app_store.sh testflight --notify

# Check all logs
tail -f ios/Rosier/build/*.log

# Count test methods
find ios/Rosier/Tests -name '*.swift' -exec grep -h 'func test' {} \; | wc -l

# List all Swift files
find ios/Rosier/Sources -name '*.swift' | wc -l

# Check file structure
tree -L 2 ios/Rosier/Sources
```

---

## Checklists

### Pre-Submission (5 minutes)
- [ ] Run pre_submission_validator.sh
- [ ] All checks pass (exit 0)
- [ ] Build locally
- [ ] Run tests locally

### Submission (15 minutes)
- [ ] Generate screenshots
- [ ] Update version number
- [ ] Run submit_to_app_store.sh
- [ ] Monitor in App Store Connect

### Post-Submission (Weekly)
- [ ] Check App Store status
- [ ] Monitor crash reports
- [ ] Review user feedback
- [ ] Plan next iteration

---

## FAQ

**Q: How long does validation take?**
A: ~30 seconds. View with `pre_submission_validator.sh --verbose`

**Q: Can I skip validation?**
A: Not recommended, but possible with `--skip-validation` flag

**Q: Where are screenshots saved?**
A: `docs/screenshots/output/` after running `generate_screenshots.sh`

**Q: How do I update the app version?**
A: Edit `ios/Rosier/Sources/App/Info.plist` CFBundleShortVersionString

**Q: What if validation fails?**
A: Script output shows exactly which checks failed and why

**Q: Can I submit multiple builds?**
A: Yes, increment CURRENT_PROJECT_VERSION and resubmit

**Q: How do I check submission status?**
A: https://appstoreconnect.apple.com → Your App → Build

**Q: What if submission is rejected?**
A: Check rejection reason in App Store Connect, fix, resubmit

---

## Common Errors & Fixes

```
❌ "No provisioning profile"
✓ rm ~/Library/MobileDevice/Provisioning\ Profiles/*
✓ Download from Apple Developer
✓ Re-import and retry

❌ "Code sign error"
✓ Check: security find-identity -v -p codesigning
✓ Renew cert if expired
✓ Restart Xcode

❌ "Force unwraps found"
✓ Replace: value! → guard let value = value else { return }

❌ "Xcode not found"
✓ Run: xcode-select --install
✓ Or: xcode-select --reset

❌ "Permission denied"
✓ Run: chmod +x ./scripts/*.sh
✓ Or: bash ./scripts/script.sh
```

---

## Shortcuts

### Alias Setup
```bash
# Add to ~/.zshrc
alias rosier-validate="cd ios/Rosier && ./scripts/pre_submission_validator.sh --verbose"
alias rosier-submit-tf="cd ios/Rosier && ./scripts/submit_to_app_store.sh testflight --notify"
alias rosier-submit="cd ios/Rosier && ./scripts/submit_to_app_store.sh appstore --notify"
alias rosier-screenshots="cd ios/Rosier && ./scripts/generate_screenshots.sh chrome"

# Usage:
# rosier-validate
# rosier-submit-tf
# rosier-screenshots
```

---

## Emergency Contacts

**Build Issues**: support@rosier.app
**App Store Questions**: Apple Developer Support
**Script Bugs**: GitHub Issues or dev@rosier.app

---

**Last Updated**: 2026-04-01
**Version**: 1.0.0
**For**: Rosier iOS App - Sprint 3 Delivery

