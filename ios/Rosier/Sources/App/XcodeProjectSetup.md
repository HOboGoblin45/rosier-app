# Rosier iOS App - Xcode Project Setup Guide

**App Name:** Rosier
**Bundle ID:** com.rosier.app
**Minimum iOS:** 17.0
**Target Device:** iPhone only (portrait orientation)
**Status:** App Store Ready Configuration

---

## Overview

This guide walks through creating a complete Xcode project for Rosier with all App Store submission requirements. All configuration files have been generated in this repository.

---

## Step 1: Create New Xcode Project

### 1.1 Create Project
- **File → New → Project**
- **Template:** iOS → App
- **Product Name:** Rosier
- **Organization Identifier:** com.rosier (or your company identifier)
- **Bundle Identifier:** com.rosier.app
- **Interface:** SwiftUI
- **Lifecycle:** SwiftUI App
- **Language:** Swift
- **Include Tests:** ✓ (checked)

### 1.2 Project Settings
- **Save location:** `/sessions/busy-tender-goldberg/mnt/Women's fashion app/rosier/ios/Rosier`
- **Create Git repository:** ✓ (recommended)

---

## Step 2: Configure Project Structure

### 2.1 Directory Organization
After creating the Xcode project, organize files as follows:

```
Rosier/
├── Sources/
│   ├── App/
│   │   ├── RosierApp.swift (EXISTING)
│   │   ├── AppDelegate.swift (EXISTING)
│   │   ├── Info.plist (NEW - copy from generated)
│   │   ├── Rosier.entitlements (NEW - copy from generated)
│   │   ├── PrivacyInfo.xcprivacy (NEW - copy from generated)
│   │   └── SceneDelegate.swift (CREATE)
│   ├── Models/ (EXISTING)
│   ├── Services/ (EXISTING)
│   ├── Coordinators/ (EXISTING)
│   ├── Views/ (EXISTING)
│   └── Utilities/ (EXISTING)
├── Resources/
│   ├── LaunchScreen.storyboard (NEW - copy from generated)
│   └── Assets/
│       ├── AppIconGenerator.swift (NEW - copy from generated)
│       ├── ColorAssets.swift (NEW - copy from generated)
│       └── Assets.xcassets (CREATE - see step 2.2)
├── Tests/ (EXISTING)
└── Rosier.xcodeproj/
    ├── project.pbxproj
    └── xcshareddata/
        └── xcschemes/
```

### 2.2 Create Asset Catalog

1. **File → New → Asset Catalog**
2. **Save as:** Assets.xcassets
3. **Target:** Rosier

---

## Step 3: Add Configuration Files

### 3.1 Info.plist
- **Copy:** Sources/App/Info.plist (generated)
- **Target:** Rosier (check the checkbox)
- **Build Phases:**
  - Verify in "Copy Bundle Resources" phase

### 3.2 Entitlements
- **Copy:** Sources/App/Rosier.entitlements (generated)
- **Target:** Rosier
- **Project Settings:**
  - Select project Rosier
  - Target: Rosier
  - Signing & Capabilities tab
  - Load "Rosier.entitlements" file

### 3.3 Privacy Manifest
- **Copy:** Sources/App/PrivacyInfo.xcprivacy (generated)
- **Target:** Rosier (check the checkbox)
- **Build Phases:**
  - Verify in "Copy Bundle Resources" phase
- **Note:** Required for App Store submission since Spring 2024

### 3.4 Launch Screen
- **Copy:** Resources/LaunchScreen.storyboard (generated)
- **Target:** Rosier
- **Project Settings:**
  - Select project Rosier
  - Build Settings tab
  - Search for "Launch Screen"
  - Set "Launch Screen File Base Name" = LaunchScreen

---

## Step 4: Configure Signing and Capabilities

### 4.1 Team ID Configuration
- **Select Project: Rosier**
- **Select Target: Rosier**
- **Signing & Capabilities tab**
- **Team:** Select your Apple Developer Team
- **Bundle Identifier:** com.rosier.app

### 4.2 Enable Required Capabilities
Click **+ Capability** for each:

1. **Apple Sign In**
   - Already in entitlements
   - Verify checkbox is enabled

2. **Associated Domains**
   - Domains:
     - `applinks:rosier.app`
     - `webcredentials:rosier.app`

3. **Background Modes**
   - ✓ Background Fetch
   - ✓ Remote Notifications
   - ✓ Processing Tasks

4. **Push Notifications**
   - Development team: Auto-populated

5. **App Groups** (optional, already in entitlements)
   - Container: group.com.rosier.app
   - Container: group.com.rosier.app.shared

---

## Step 5: Build Settings Configuration

### 5.1 Deployment Target
- **Select Project: Rosier**
- **Select Target: Rosier**
- **Build Settings tab**
- **Minimum Deployments iOS Version:** 17.0

### 5.2 Swift Settings
- **Swift Language Version:** Swift 5.9 or later
- **Swift Compiler Optimizations:** Fast, Whole Module Optimization (Release)

### 5.3 Code Signing
- **Code Signing Identity:** iOS Developer (Debug), Apple Distribution (Release)
- **Provisioning Profile:** Automatic (recommended)
- **Development Team:** Your Apple Team ID

### 5.4 Bundle Settings
- **Bundle Identifier:** com.rosier.app
- **Version Number:** 1.0.0
- **Build Number:** 1 (increment for each build)

### 5.5 Search Paths (if applicable)
- **Header Search Paths:** (leave empty unless using headers)
- **Framework Search Paths:** (leave empty unless using frameworks)

---

## Step 6: App Icon Setup

### 6.1 Generate Icon Files
```bash
cd Resources/Assets
swift AppIconGenerator.swift
```

This generates all required sizes:
- AppIcon-20@1x.png through AppIcon-1024.png
- Output directory: ./AppIcons/

### 6.2 Import Icons to Asset Catalog

1. **Open Assets.xcassets** in Xcode
2. **File → New → App Icon Set**
3. **Name it:** AppIcon
4. **Drag each PNG** from ./AppIcons/ to corresponding size slots
   - 20×20@1x, 20×20@2x, 20×20@3x
   - 29×29@1x, 29×29@2x, 29×29@3x
   - 40×40@1x, 40×40@2x, 40×40@3x
   - 60×60@2x, 60×60@3x
   - 76×76@1x, 76×76@2x
   - 83.5×83.5@2x
   - 1024×1024@1x

### 6.3 Verify App Icon Assignment
- **Select Project: Rosier**
- **Build Settings tab**
- **Search for "App Icon Set Name"**
- **Value:** AppIcon

---

## Step 7: Color Assets Setup

### 7.1 Create Color Sets in Asset Catalog

In Assets.xcassets, create Color Sets for each entry in ColorAssets.swift:

**Appearance: Light, Dark (required)**

| Color Set Name | Light RGB | Dark RGB |
|---|---|---|
| BrandPrimary | (26, 26, 46) | (26, 26, 46) |
| BrandAccent | (196, 167, 125) | (196, 167, 125) |
| BrandTertiary | (142, 108, 129) | (142, 108, 129) |
| SurfaceBackground | (250, 250, 250) | (18, 18, 18) |
| SurfaceCard | (255, 255, 255) | (28, 28, 28) |
| SurfaceOverlay | (255, 255, 255, 0.95) | (35, 35, 35, 0.95) |
| TextPrimary | (44, 44, 44) | (229, 229, 229) |
| TextSecondary | (108, 108, 108) | (158, 158, 158) |
| TextTertiary | (158, 158, 158) | (108, 108, 108) |
| TextDisabled | (192, 192, 192) | (80, 80, 80) |
| StateSuccess | (34, 177, 76) | (34, 177, 76) |
| StateError | (231, 76, 60) | (231, 76, 60) |
| StateWarning | (241, 196, 15) | (241, 196, 15) |
| StateInfo | (52, 152, 219) | (52, 152, 219) |
| Divider | (229, 229, 229) | (64, 64, 64) |
| BorderSubtle | (217, 217, 217) | (76, 76, 76) |
| BorderEmphasis | (179, 179, 179) | (115, 115, 115) |

### 7.2 Update ColorAssets.swift

After creating all Color Sets, update the extension in ColorAssets.swift:

```swift
extension Color {
    static let brandPrimary = Color("BrandPrimary")
    static let brandAccent = Color("BrandAccent")
    // ... reference all colors from Asset Catalog
}
```

---

## Step 8: Launch Screen Configuration

### 8.1 Add Storyboard
- **Copy:** Resources/LaunchScreen.storyboard (generated)
- **Target:** Rosier (check the checkbox)
- **Project Settings:**
  - Build Settings → Launch Screen File Base Name = LaunchScreen

### 8.2 Verify Launch Screen
- Run on simulator to verify it displays correctly
- Should show "Rosier" text with gradient background
- No external image assets required (keeps app binary small)

---

## Step 9: Create SceneDelegate (if not using SwiftUI lifecycle)

**Note:** Modern SwiftUI projects don't require SceneDelegate. Skip if using `@main` with `App` protocol.

If manually managing scenes:

```swift
import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: RosierApp())
        self.window = window
        window.makeKeyAndVisible()
    }
}
```

---

## Step 10: Build and Test

### 10.1 Build for Simulator
```bash
xcodebuild -scheme Rosier -configuration Debug -sdk iphonesimulator
```

### 10.2 Run on Simulator
- **Product → Run** (⌘R)
- Select iPhone 15+ (minimum iOS 17)
- Verify:
  - App launches
  - Launch screen displays correctly
  - App icon shows in home screen
  - Tab navigation works
  - Dark mode toggling works
  - Orientation is locked to portrait

### 10.3 Run on Device
1. Connect iPhone running iOS 17+
2. Select device in scheme dropdown
3. **Product → Run** (⌘R)
4. Trust developer certificate on device
5. Verify same functionality as simulator

### 10.4 Test Deep Linking
Test all URL schemes from `Info.plist`:
```
rosier://product/uuid
rosier://dresser/uuid
rosier://dna/uuid
rosier://sale/uuid
```

### 10.5 Test Background Modes
- App refresh (fetch)
- Remote notifications
- Processing tasks

---

## Step 11: Prepare for App Store Submission

### 11.1 Update Build Number
- **Project → General tab**
- **Version:** 1.0.0
- **Build:** Increment (e.g., 1 → 2)

### 11.2 Change Entitlements for Production
- **Rosier.entitlements**
  - Change `aps-environment` from "development" to "production"

### 11.3 Create Release Configuration
- **Project → Build Settings**
- Search "Code Signing"
- **Release configuration:**
  - Code Signing Identity: Apple Distribution
  - Provisioning Profile: Distribution profile (from Apple Developer)

### 11.4 Create App Store Connect Record
1. Visit [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps → + New App**
3. **Platforms:** iOS
4. **App Name:** Rosier
5. **Primary Language:** English
6. **Bundle ID:** com.rosier.app
7. **SKU:** com.rosier.app

### 11.5 Complete App Information
- **Pricing and Availability**
  - Pricing Tier: Free
  - Availability: All regions initially

- **App Privacy**
  - Fill in all required data collection disclosures
  - Upload PrivacyInfo.xcprivacy manifest
  - Match fields in Privacy Manifest file

- **App Review Information**
  - Provide demo account (if gated)
  - Note any special setup required
  - Explain any background modes used

### 11.6 Screenshots for App Store
- iPhone 6.7" (landscape): 1242×2208 or 1290×2796
- iPhone 5.5" (landscape): 1242×2208
- iPad 12.9" (if supporting): 2048×2732
- Minimum 2 screenshots, maximum 10

### 11.7 App Description & Metadata
- **App Description:** (max 4000 characters)
  - Explain swipe-based fashion discovery
  - Mention dresser/wardrobe feature
  - Highlight micro-influencer curations

- **Keywords:** fashion, swipe, discovery, style, curation

- **Support URL:** https://rosier.app/support

- **Privacy Policy URL:** https://rosier.app/privacy

- **Category:** Lifestyle

---

## Step 12: Build for App Store

### 12.1 Create Archive
- **Select Rosier scheme**
- **Select Generic iOS Device**
- **Product → Archive**
- Wait for build to complete

### 12.2 Export for App Store
1. **Xcode → Window → Organizer**
2. **Select your archive**
3. **Distribute App**
4. **Select: App Store Connect**
5. **Upload options:**
   - Strip Swift symbols: ✓
   - Upload symbols: ✓
6. **Select signing team**
7. **Review and upload**

### 12.3 Monitor Upload
- Check [App Store Connect](https://appstoreconnect.apple.com)
- Wait for processing (5-30 minutes)
- Verify version appears under "Builds"

---

## Step 13: App Store Review Submission

### 13.1 Version Release Notes
- **App Store Connect → Version Release Notes**
- Document new features and changes
- Example: "Initial public release - discover fashion through swiping"

### 13.2 Submit for Review
1. **All Sections → Submission Info**
2. **Review Notes:** Add relevant context for reviewers
3. **Content Rights:** Confirm all rights obtained
4. **Advertising ID:** Select appropriate option
5. **Export Compliance:** ITAR/Encryption info
6. **Alcohol/Tobacco:** Not applicable

### 13.3 Click Submit for Review
- App will enter "Waiting for Review" status
- Apple typically reviews within 24-48 hours
- Monitor for rejections/requests

---

## Troubleshooting

### Build Fails - "Info.plist not found"
- Verify Info.plist is in Build Phases → Copy Bundle Resources
- Check file is in Targets → Build Settings → Info.plist File

### App Icon Not Showing
- Verify AppIcon is in Assets.xcassets
- Project → Build Settings → App Icon Set Name = AppIcon
- All required sizes must be present

### Dark Mode Not Working
- Verify Color Sets have both Light and Dark appearances
- Use Color("ColorName") instead of hardcoded UIColor
- Test in Simulator with Appearance toggle (Xcode → Debug Menu)

### Deep Links Not Working
- Verify URL scheme in Info.plist: rosier://
- Check entitlements include Associated Domains
- Test with: `xcrun simctl openurl booted rosier://product/uuid`

### Push Notifications Not Working
- Verify aps-environment in entitlements
- Check provisioning profile includes Push Notifications
- Use development environment for testing
- Change to production for release

### Archive Fails
- Verify build settings for Release configuration
- Check all Swift files compile: **Cmd+B**
- Ensure no Swift syntax errors
- Check provisioning profile is valid

---

## Checklist for App Store Submission

- [ ] Version set to 1.0.0
- [ ] Build number incremented
- [ ] All sources files added to target
- [ ] Info.plist configured
- [ ] Entitlements configured
- [ ] Privacy manifest added and complete
- [ ] LaunchScreen storyboard set
- [ ] AppIcon in Assets.xcassets
- [ ] All required sizes present in AppIcon set
- [ ] Color assets created (minimum 10 colors)
- [ ] Signing team assigned
- [ ] Code signing identity set (iOS Developer/Distribution)
- [ ] Provisioning profile valid
- [ ] Minimum iOS 17.0
- [ ] Portrait orientation only
- [ ] Deep linking tested
- [ ] Push notifications tested
- [ ] Background modes tested
- [ ] Launch screen displays correctly
- [ ] App icon displays correctly
- [ ] Dark mode works
- [ ] All tabs/navigation functional
- [ ] App Store Connect record created
- [ ] Screenshots uploaded
- [ ] Privacy policy URL set
- [ ] App description complete
- [ ] Review notes added
- [ ] Archive created successfully
- [ ] Uploaded to App Store Connect
- [ ] Build appears in "Builds" section
- [ ] Submitted for review

---

## References

- [Apple App Store Connect Help](https://help.apple.com/app-store-connect)
- [iOS App Development Guide](https://developer.apple.com/ios/)
- [App Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Universal Links](https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content)
- [SwiftUI Documentation](https://developer.apple.com/xcode/swiftui/)

---

**Last Updated:** 2026-04-01
**For:** Rosier v1.0.0
**Status:** App Store Ready
