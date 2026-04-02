# iOS Testing Strategy for Rosier

## Overview

Charlie is on a Windows PC without access to a MacBook. This document outlines how to build, test, and validate the iOS app without requiring local Mac hardware.

## 1. GitHub Actions with macOS Runners

### Why GitHub Actions?

- **Free**: GitHub provides 3,000 minutes/month of free macOS runner time (more than enough for CI/CD)
- **Integrated**: Works directly with your repository
- **Reliable**: Same machine every time; no local environment issues
- **Scalable**: Run tests on every commit/PR automatically

### Current Workflow

The existing `.github/workflows/ios.yml` already has the foundation. Here's what we'll enhance:

```yaml
# .github/workflows/ios.yml
name: iOS CI

on:
  push:
    branches: [main, develop]
    paths: ['ios/**']
  pull_request:
    branches: [develop]
    paths: ['ios/**']

jobs:
  test:
    runs-on: macos-14  # Latest macOS with Xcode
    steps:
      - uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Run Tests
        run: |
          cd ios/Rosier
          xcodebuild test \
            -scheme Rosier \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -derivedDataPath build \
            -resultBundlePath TestResults.xcresult

      - name: Generate Coverage Report
        run: |
          xcrun xccov view --report --json TestResults.xcresult > coverage.json

      - name: Upload Coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage.json
          flags: ios

  build:
    runs-on: macos-14
    needs: test
    steps:
      - uses: actions/checkout@v4
      - name: Build for Release
        run: |
          cd ios/Rosier
          xcodebuild build-for-testing \
            -scheme Rosier \
            -configuration Release

      - name: Archive Build
        run: |
          xcodebuild archive \
            -scheme Rosier \
            -archivePath "build/Rosier.xcarchive"

      - name: Upload Build Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: rosier-build
          path: build/Rosier.xcarchive
```

### Key Benefits

- Tests run automatically on every push and PR
- Fast feedback (typically 10-15 minutes)
- No manual setup required
- Coverage reports uploaded to Codecov
- Build artifacts available for download

## 2. Local Development Without Mac (Windows PC)

### Option A: Remote SSH to Mac Build Server (Recommended for Active Development)

If you need to develop actively on Windows, you can:

1. **SSH into a remote Mac** and use VSCode Remote SSH
2. **Use Xcode Server** for automated builds
3. **Sync code via Git** instead of file transfers

### Option B: Mock API Server Approach (Best for Windows-based Development)

Instead of running iOS simulator locally:

```python
# backend/scripts/mock_api_server.py
# A lightweight mock server that can run on Windows to simulate the backend
```

This allows:
- Full API contract testing
- Integration testing without iOS simulator
- Team members on Windows to contribute to backend integration logic

## 3. Cloud Mac Rental Options

If you need occasional Mac access for specific testing (e.g., final pre-release testing):

### Option 1: MacStadium ($1-2/hour)
- **URL**: https://www.macstadium.com/
- **Pros**: High performance, dedicated cloud Macs
- **Cost**: ~$1.50/hour for basic Mac mini
- **Best For**: Intensive testing sessions, builds before release
- **Setup**: SSH access, VPN optional

### Option 2: MacinCloud ($2-7/hour)
- **URL**: https://www.macincloud.com/
- **Pros**: Hourly billing, easy setup, includes Xcode pre-installed
- **Cost**: Depends on Mac model (M1 Pro recommended for ~$3/hour)
- **Best For**: Quick testing, temporary needs
- **Setup**: Browser or VNC access

### Option 3: AWS EC2 Mac (Starting at $10.322/day minimum)
- **URL**: https://aws.amazon.com/ec2/mac/
- **Pros**: Scalable, integrates with other AWS services
- **Cost**: Expensive - ~$1/hour + data transfer
- **Best For**: Large-scale CI/CD with private infrastructure
- **Setup**: Requires AWS account

### Option 4: BrowserStack App Live ($99-199/month)
- **URL**: https://www.browserstack.com/app-live
- **Pros**: Real devices, no setup, pay-as-you-go options
- **Cost**: Per test minute or monthly subscription
- **Best For**: Final QA testing on real devices
- **Setup**: Browser-based testing

### Cost Comparison Table

| Option | Cost/Hour | Setup Time | Best For |
|--------|-----------|-----------|----------|
| GitHub Actions | Free (3000 min/month) | 1 hour | Regular CI/CD |
| MacStadium | $1-2 | 30 min | Testing sessions |
| MacinCloud | $2-7 | 15 min | Quick testing |
| AWS EC2 Mac | $10.32/day min | 1 hour | Enterprise CI |
| BrowserStack | $0.50-5/min | 5 min | Real device QA |

**Recommendation**: Use **GitHub Actions for free CI/CD** + **MacinCloud for occasional access** = Best cost/benefit

## 4. Mock API Server for Windows Development

Create a mock API that simulates the backend for iOS testing on Windows:

```python
# backend/scripts/mock_api_server.py
from fastapi import FastAPI
from typing import List
import json
import uuid

app = FastAPI()

# Mock data
MOCK_PRODUCTS = [
    {
        "id": str(uuid.uuid4()),
        "name": "Le Bambino Shoulder Bag",
        "price": 450,
        "currency": "USD",
        "image_urls": ["https://placehold.co/400"],
        "brand": "Paloma Wool",
        "category": "Bags"
    } for _ in range(10)
]

@app.post("/api/v1/auth/email/register")
async def register(email: str, password: str, display_name: str):
    return {
        "access_token": "mock_token_" + uuid.uuid4().hex,
        "token_type": "bearer",
        "expires_in": 3600
    }

@app.get("/api/v1/cards/next")
async def get_cards(limit: int = 10):
    return MOCK_PRODUCTS[:limit]

@app.post("/api/v1/cards/swipe")
async def swipe(product_id: str, action: str, dwell_time_ms: int):
    return {"success": True, "message": f"Swiped {action}"}

@app.get("/api/v1/profile")
async def get_profile():
    return {
        "email": "user@example.com",
        "display_name": "Test User",
        "onboarding_completed": True
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

**To use from Windows**:
```bash
# Terminal 1: Start mock API
python backend/scripts/mock_api_server.py

# Terminal 2: Configure iOS app to use localhost:8000
# Update NetworkService.swift to use http://host.docker.internal:8000 when in development

# Terminal 3: Run tests
cd ios/Rosier
xcodebuild test -scheme Rosier -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 5. Recommended iOS Testing Workflow

### For Daily Development (On Windows)

1. **Write code** in VSCode/Xcode on Windows
2. **Push to GitHub** (or `git stash` + remote SSH)
3. **GitHub Actions runs tests** automatically
4. **Check results** in GitHub PR/Actions tab
5. **Fix failures** based on CI feedback

### For Pre-Release Testing

1. **Reserve 1-2 hours** on MacinCloud ($3-7)
2. **SSH in and pull latest code**
3. **Run full test suite locally**
4. **Test on simulated devices** (iPhone 15, iPad, etc.)
5. **Generate final build artifacts**

### For Final QA (Before App Store)

1. **Use BrowserStack** to test on real devices
2. **Test on multiple iOS versions** (14, 15, 16, 17+)
3. **Check real-world network conditions**
4. **Verify device-specific features** (Face ID, etc.)

## 6. Enhanced Local Swift Testing (Without Simulator)

Even without running the iOS app, you can test Swift code on Windows using Docker:

```dockerfile
# Dockerfile.swift
FROM swift:5.9

WORKDIR /app
COPY ios/Rosier /app

RUN swift test --enable-code-coverage
```

Run on Windows:
```bash
docker build -f Dockerfile.swift -t rosier-swift-tests .
docker run --rm rosier-swift-tests
```

This:
- Runs all XCTests
- Generates coverage reports
- Works on Windows Docker Desktop
- No Xcode required

## 7. Summary: Testing Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS Testing Strategy                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Tier 1: Automated (Every Commit)                          │
│  ├─ GitHub Actions + macOS runner                          │
│  ├─ Run full test suite                                    │
│  ├─ Generate coverage reports                              │
│  └─ Cost: $0/month (free tier)                            │
│                                                             │
│  Tier 2: Integration (During Development)                  │
│  ├─ Mock API server on Windows                             │
│  ├─ Swift tests via Docker                                │
│  ├─ Postman/API contract tests                            │
│  └─ Cost: $0/month                                        │
│                                                             │
│  Tier 3: Manual (Pre-Release Testing)                     │
│  ├─ MacinCloud for final validation                       │
│  ├─ BrowserStack for real devices                         │
│  └─ Cost: $50-200 per release                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 8. Getting Started

### Immediate (This Week)
- [ ] Update GitHub Actions workflow with enhanced test config
- [ ] Set up codecov integration
- [ ] Configure Android/iOS build caching

### Short Term (This Month)
- [ ] Create mock API server for Windows development
- [ ] Document Windows development setup
- [ ] Add Docker-based Swift testing

### Medium Term (Q2)
- [ ] Evaluate MacinCloud for occasional use
- [ ] Set up Xcode Server for on-demand builds
- [ ] Create pre-release QA checklist

## References

- [GitHub Actions macOS Runners](https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md)
- [Xcode Testing in CI/CD](https://developer.apple.com/documentation/xcode/building_your_app_in_continuous_integration)
- [Swift Testing Best Practices](https://developer.apple.com/swift/testing/)
- [MacStadium Pricing](https://www.macstadium.com/pricing)
- [MacinCloud Pricing](https://www.macincloud.com/pricing)
