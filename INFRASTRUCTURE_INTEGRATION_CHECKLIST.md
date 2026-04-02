# Infrastructure Integration Checklist

## Pre-Deployment Steps

### 1. Info.plist Configuration
Add required entries for background tasks and push notifications:

```xml
<!-- Background Task Capabilities -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.rosier.app.refresh</string>
    <string>com.rosier.app.processing</string>
</array>

<!-- App Transport Security -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.rosier.app</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>

<!-- Cache Policy -->
<key>NSURLCache</key>
<dict>
    <key>NSURLCacheMemoryCapacity</key>
    <integer>100000000</integer>
    <key>NSURLCacheDiskCapacity</key>
    <integer>500000000</integer>
</dict>
```

### 2. Xcode Capabilities
Enable in Xcode project settings:

- [x] Push Notifications
- [x] Background Modes (App Refresh, Background Processing)
- [x] Keychain Sharing
- [x] Associated Domains (for universal links)

### 3. Environment Variables (Fastlane)
Create `.env` file or GitHub Actions secrets:

```bash
# App Store Connect
FASTLANE_USER=developer@rosier.app
FASTLANE_TEAM_ID=ABCDEF1234
ITC_TEAM_ID=1234567890
ITC_TEAM_NAME="Rosier Team"

# Code Signing
MATCH_GIT_URL=https://github.com/rosier-app/code-signing.git
MATCH_GIT_USERNAME=bot-username
MATCH_GIT_TOKEN=github-token
MATCH_GIT_BRANCH=main
MATCH_STORAGE_MODE=git

# App Store Connect API Key
APP_STORE_CONNECT_KEY_ID=ABC123XYZ
APP_STORE_CONNECT_ISSUER_ID=12345678-1234-1234-1234-123456789012
APP_STORE_CONNECT_KEY_CONTENT=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----

# Notifications
SLACK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### 4. Git Configuration
```bash
# Add SwiftLint pre-commit hook
cd ios/Rosier
cp fastlane/.pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

### 5. Deployment Script (Optional)
```bash
#!/bin/bash
# deploy.sh

cd ios/Rosier

# Run tests
fastlane test || exit 1

# Build beta
fastlane beta version:1.0.0

# Or release to App Store
fastlane release version:1.0.0
```

---

## Runtime Configuration

### 1. Backend API Endpoints
Ensure these endpoints are implemented on backend:

```
POST /api/v1/profile/device_token
  - Register device for push notifications

POST /api/v1/analytics/swipes
  - Batch upload of queued swipe events

POST /api/v1/cards/queue
  - Fetch card queue for swiping

GET /api/v1/dressers
  - Load user's dresser drawers

GET /api/v1/users/me
  - Fetch current user profile
```

### 2. Push Notification Payload Format
Expected push notification payload structure:

```json
{
  "aps": {
    "alert": {
      "title": "Price Drop Alert",
      "body": "Your saved item is now $75"
    },
    "sound": "default",
    "badge": 1,
    "category": "PRICE_DROP"
  },
  "type": "price_drop",
  "productId": "550e8400-e29b-41d4-a716-446655440000",
  "deepLink": "rosier://product/550e8400-e29b-41d4-a716-446655440000"
}
```

### 3. Core Data Setup
Core Data stack is initialized in PersistenceController:
- Model: `RosierModel` (programmatic)
- Container: `NSPersistentContainer(name: "Rosier")`
- Store: SQLite (default) or in-memory for testing
- Migration: Lightweight migration enabled

### 4. Offline Sync Strategy

**On App Launch:**
1. Initialize Core Data stack
2. Check NWPathMonitor for connectivity
3. If online:
   - Sync unsynced SwipeEvent entities to `/analytics/swipes`
   - Prefetch 40+ products to CachedCardQueue
4. If offline:
   - Load products from CachedCardQueue
   - Queue swipes locally in CachedSwipeEvent

**On Network Restoration:**
1. NWPathMonitor detects change to .satisfied
2. Automatically trigger:
   - `syncUnyncedSwipeEvents()`
   - `prefetchCardQueue()`
   - `checkDresserPriceDrops()`

**Every 2 Hours (Background App Refresh):**
1. BGAppRefreshTask executes handler
2. Sync any remaining unsynced events
3. Refresh card queue cache
4. Check for dresser price drops
5. Schedule next refresh (2 hours)

**On Charging + WiFi (Background Processing):**
1. BGProcessingTask executes handler
2. Download and cache card images
3. Clean Core Data cache (7+ days old)
4. Schedule next processing task

---

## Testing Procedures

### 1. Unit Tests
```bash
cd ios/Rosier
fastlane test

# Expected: 49 tests pass
# Coverage: ~85% of infrastructure
```

### 2. Manual Testing

**Push Notification Testing:**
```bash
# Simulate push while app in foreground
xcrun simctl push booted com.rosier.app '{
  "aps": {
    "alert": "Test notification",
    "category": "PRICE_DROP"
  }
}'
```

**Background Task Testing:**
- Modify system time to trigger 2-hour refresh
- Put app in background
- Monitor console for sync operations

**Offline Sync Testing:**
- Disable network in simulator
- Perform swipes (should queue locally)
- Enable network
- Observe automatic sync of queued events

### 3. SwiftLint Validation
```bash
cd ios/Rosier
swiftlint --fix  # Auto-fix issues
swiftlint          # Check for violations
```

---

## Monitoring & Observability

### 1. Logging Points
Key locations to monitor:

```swift
// PersistenceController
print("Core Data save: \(context.hasChanges ? "saving..." : "no changes")")

// OfflineSyncService
print("Sync status: online=\(isOnline), syncing=\(isSyncing)")

// BackgroundTaskService
print("Background task \(taskId): started/completed")

// PushNotificationService
print("Device token registered: \(token.prefix(20))...")
```

### 2. Crash Reporting Integration
Add Sentry or Crashlytics:

```swift
// In AppDelegate.application(_:didFinishLaunchingWithOptions:)
Sentry.start { options in
    options.dsn = "YOUR_SENTRY_DSN"
}
```

### 3. Analytics Events
Track infrastructure events:

```swift
AnalyticsService.shared.track(
    event: "swipe_event_synced",
    properties: ["count": 10, "duration": 2.5]
)
```

---

## Performance Baselines

### Memory
- Core Data stack: ~5-8 MB
- Image cache (100 MB max): grows to ~80 MB under normal use
- Queued events (1000 max): ~2-3 MB

### CPU
- Sync operation: <50 ms
- Background task: <5 seconds
- Image preload: parallelized

### Network
- Card queue fetch: ~500-800 ms (50 products, 2-3 MB images)
- Event batch upload: ~200-400 ms (10-100 events)
- Price check: ~100-200 ms

### Disk
- SQLite database: grows with swipe history (~500 KB/year)
- Image cache: configurable (default 500 MB)
- Queue cache: ~50-100 KB

---

## Troubleshooting

### Issue: Background tasks not executing

**Symptoms:** Swipe events not synced, card queue not refreshing

**Solutions:**
1. Verify Info.plist has BGTaskSchedulerPermittedIdentifiers
2. Check Background Modes capability is enabled
3. Ensure device is not in Low Power Mode
4. Verify NWPathMonitor shows connectivity

### Issue: Push notifications not received

**Symptoms:** Notifications don't appear, device token registration fails

**Solutions:**
1. Check notification permissions granted
2. Verify device token is registered with backend
3. Ensure certificate/provisioning profile includes push capability
4. Check Apple Push Notification service is enabled

### Issue: Core Data corruption

**Symptoms:** Data inconsistency, migration errors

**Solutions:**
1. Enable SQLite debugging: `sqlite3 ~/.../Rosier`
2. Call `PersistenceController.shared.clearAllData()` to reset
3. Check for concurrent access issues
4. Verify background context merges correctly

### Issue: Memory leaks with image caching

**Symptoms:** Memory grows unbounded, app crashes

**Solutions:**
1. Verify NSCache limits are respected
2. Check image loading cancellation on view dealloc
3. Monitor heap allocations in Instruments
4. Reduce cache size if necessary

---

## Rollback Procedure

If infrastructure issues occur in production:

1. **Disable Sync:**
   ```swift
   OfflineSyncService.shared.isSyncing = false
   ```

2. **Disable Background Tasks:**
   Remove BGTaskScheduler registration from AppDelegate

3. **Clear Cache:**
   ```swift
   try PersistenceController.shared.clearAllData()
   ```

4. **Fallback to Manual Sync:**
   Provide UI button to manually trigger sync

---

## Success Criteria

✅ All 49 unit tests pass
✅ Zero SwiftLint violations
✅ Push notifications received within 5 seconds
✅ Offline sync completes within 10 seconds
✅ Background tasks complete within 30 seconds
✅ App launch time < 2 seconds (cold start)
✅ Memory footprint < 100 MB
✅ Battery impact: <2% per day (typical usage)
✅ Fastlane CI/CD pipeline working
✅ Code signing via Match working

---

## Support & Escalation

For infrastructure issues:

1. Check Console logs for errors
2. Review INFRASTRUCTURE_BUILD_SUMMARY.md
3. Run unit tests in isolation
4. Enable verbose logging in services
5. Use Xcode debugger with breakpoints
6. Check Network tab in Xcode for API issues
7. Use Instruments for performance profiling

**Escalation contacts:**
- Backend API issues → API Team
- Push notification provider issues → APNs documentation
- Code signing issues → DevOps team
- Performance issues → Platform team
