# Referral System iOS Views Integration Guide

## Overview

The referral system provides five production-ready SwiftUI views for user-facing referral code management, reward tracking, and sharing functionality. All views follow Rosier's design system (rose/pink luxury aesthetic) and use the MVVM + Coordinator pattern.

## Components

### 1. ReferralViewModel.swift
**Location:** `Sources/ViewModels/ReferralViewModel.swift`

Core business logic for referral operations:
- Load user's referral code and stats
- Copy code to clipboard
- Trigger native iOS share sheet
- Apply referral codes during onboarding
- Track share events (analytics)
- Validate ROSIE-XXXX format
- Trigger celebration animations on tier unlock

**Key Methods:**
- `loadReferralData()` - Fetches stats from `/referrals/stats`
- `applyReferralCode(_:source:)` - Applies code via `/referrals/apply`
- `showNativeShareSheet()` - Opens iOS activity controller
- `validateReferralCodeFormat(_:)` - Regex validation for ROSIE-XXXX

**Published Properties:**
- `referralStats: ReferralStats?` - Current tier and count data
- `referralCode: String` - User's unique code
- `isLoading: Bool` - Loading state
- `error: String?` - Error messages
- `celebrationTrigger: Bool` - Animation trigger

---

### 2. ReferralDashboardView.swift
**Location:** `Sources/Views/Profile/ReferralDashboardView.swift`

**Purpose:** Main referral hub (full-screen modal or navigation destination)

**Features:**
- Prominent ROSIE-XXXX code display with copy button
- Visual progress bar (0-100%) toward next tier
- Reward tier breakdown (5 tiers with descriptions)
- Current referral count and next milestone
- Share button (native iOS share sheet)
- Loading and error states
- Info card explaining the program

**Design Highlights:**
- Gold/rose brand accent colors
- Spring animations on load
- Gesture feedback for copy action
- Responsive layout (auto-scaling progress)

**Usage:**
```swift
@State private var showReferralDashboard = false

// In navigation or sheet modifier:
.sheet(isPresented: $showReferralDashboard) {
    ReferralDashboardView()
}

// Or in navigation stack:
NavigationLink(destination: ReferralDashboardView()) {
    Text("View Referral Program")
}
```

---

### 3. ReferralRewardCard.swift
**Location:** `Sources/Views/Profile/ReferralRewardCard.swift`

**Purpose:** Reusable tier card component

**Properties:**
- `tier: ReferralTier` - The reward tier (styleDna, dailyDrop, etc.)
- `referralsNeeded: Int` - Milestone count (1, 3, 5, 10, 25)
- `isUnlocked: Bool` - Visual locked/unlocked state

**Features:**
- Icon badge (sparkles, calendar, crown, star, megaphone)
- Tier name and description
- Milestone badge
- Checkmark indicator when unlocked
- Conditional styling (gradient/opacity)
- Spring animation on unlock

**Usage:**
```swift
ReferralRewardCard(
    tier: .vipDresser,
    referralsNeeded: 10,
    isUnlocked: stats.successfulReferrals >= 10
)
```

---

### 4. ReferralCodeEntryView.swift
**Location:** `Sources/Views/Onboarding/ReferralCodeEntryView.swift`

**Purpose:** New user onboarding screen for applying referral codes

**Features:**
- Formatted text input (auto-inserts dash: ROSIE-XXXX)
- Real-time validation with visual feedback
- Format guidelines card
- Skip button option
- Success alert on code application
- Error handling with recovery

**Design Highlights:**
- Gift icon for visual interest
- Clear input field with checkmark confirmation
- Info card with example format
- Disabled apply button until valid

**Usage:**
```swift
ReferralCodeEntryView(
    onSuccess: {
        // Navigate to next onboarding step
    },
    onSkip: {
        // Skip referral setup
    }
)
```

---

### 5. ReferralShareSheet.swift
**Location:** `Sources/Views/Profile/ReferralShareSheet.swift`

**Purpose:** UIViewControllerRepresentable wrapper for native iOS share

**Features:**
- Native activity controller
- Pre-populated referral message
- Deep link to invite URL
- Platform tracking (Messages, Email, WhatsApp, etc.)
- Graceful completion handling

**Tracked Platforms:**
- `.imessage` (Messages)
- `.email` (Mail)
- `.other` (WhatsApp, Instagram DM, etc.)

**Usage via Modifier:**
```swift
@State private var showShare = false

someView
    .referralShareSheet(
        isPresented: $showShare,
        referralCode: "ROSIE-ABC1",
        shareMessage: "Join me on Rosier!",
        onDismiss: { print("Share completed") }
    )
```

---

### 6. ReferralMiniCardView.swift
**Location:** `Sources/Views/Profile/ReferralMiniCardView.swift`

**Purpose:** Compact card for embedding in profile/home screens

**Features:**
- Quick stats display (current referral count)
- Current tier badge
- Progress bar to next tier
- Share and "View All" buttons
- Optimized for sidebar or card layout

**Usage:**
```swift
// In profile view
if let stats = referralStats {
    ReferralMiniCardView(
        stats: stats,
        onTapFullView: { showFullDashboard = true },
        onShare: { showShare = true }
    )
}
```

---

## Integration Patterns

### Pattern 1: Profile Tab Integration
```swift
struct ProfileView: View {
    @State private var viewModel = ReferralViewModel()
    @State private var showReferralDashboard = false

    var body: some View {
        NavigationStack {
            List {
                // Profile sections...

                Section("Growth") {
                    if let stats = viewModel.referralStats {
                        ReferralMiniCardView(
                            stats: stats,
                            onTapFullView: { showReferralDashboard = true },
                            onShare: { viewModel.showNativeShareSheet() }
                        )
                    }
                }
            }
            .sheet(isPresented: $showReferralDashboard) {
                ReferralDashboardView()
            }
            .task {
                await viewModel.loadReferralData()
            }
        }
    }
}
```

### Pattern 2: Onboarding Flow
```swift
struct OnboardingCoordinator {
    @State var currentStep = 0

    var body: some View {
        Group {
            switch currentStep {
            case 0:
                AuthView()
            case 1:
                StylePreferencesView()
            case 2:
                ReferralCodeEntryView(
                    onSuccess: { currentStep += 1 },
                    onSkip: { currentStep += 1 }
                )
            case 3:
                HomeView()
            default:
                HomeView()
            }
        }
    }
}
```

### Pattern 3: Standalone Modal
```swift
@State private var showReferral = false

Button("Share Rosier") {
    showReferral = true
}
.sheet(isPresented: $showReferral) {
    ReferralDashboardView()
}
```

---

## API Endpoints Used

### 1. Load Referral Stats
**GET** `/referrals/stats`
- Returns: `ReferralStats` (code, tier, counts, progress)

### 2. Apply Referral Code
**POST** `/referrals/apply`
- Body: `ApplyReferralCodeRequest { code, source }`
- Returns: 204 No Content

### 3. Track Share Event
**POST** `/referrals/track-share`
- Body: `ShareTrackingRequest { platform }`
- Returns: 204 No Content
- Platforms: imessage, whatsapp, instagram, email, link, other

---

## Design System Integration

### Colors Used
- **Brand Accent:** `Color.brandAccent` (gold/rose tone)
- **Brand Primary:** `Color.brandPrimary` (dark luxury)
- **Text:** `Color.textPrimary`, `.textSecondary`, `.textTertiary`
- **Surface:** `Color.surfaceCard`, `.surfaceBackground`
- **Status:** `Color.successGreen` (tier unlocked), `Color.saleRed` (error)

### Typography
- Headers: `Typography.displayMedium`, `Typography.titleMedium`
- Body: `Typography.body`, `Typography.bodyBold`
- Labels: `Typography.caption`, `Typography.micro`

### Animations
- Spring: `Animations.cardSpring` (0.35s response, 0.8 damping)
- Badge Pulse: `Animations.badgePulse` (celebration effect)
- Transitions: Fade, scale, combined fade+scale

---

## State Management Notes

**Observe Decorator:** All ViewModels use `@Observable` for SwiftUI observation (iOS 17+)

```swift
@Observable final class ReferralViewModel {
    var referralStats: ReferralStats?
    var isLoading = false
    var error: String?
    // ...
}
```

**Usage in Views:**
```swift
struct MyView: View {
    @State private var viewModel = ReferralViewModel()

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let stats = viewModel.referralStats {
            Text("\(stats.successfulReferrals) referrals")
        }
    }
}
```

---

## Error Handling

All views implement graceful error states:
- Network errors: "Unable to Load Referrals" card with retry button
- Invalid code format: "Invalid code format. Use ROSIE-XXXX"
- Application failure: Error message from server
- Offline: Handled by NetworkService layer

---

## Accessibility

Views include:
- Semantic HTML labels on buttons/icons
- High contrast colors (WCAG AA compliant)
- Dynamic type support via Typography system
- Proper semantic ordering

---

## Testing

Each view includes SwiftUI previews:
- ReferralDashboardView: Full screen preview
- ReferralRewardCard: Multiple states (locked/unlocked)
- ReferralCodeEntryView: Valid/invalid input states
- ReferralMiniCardView: Compact preview

Run previews:
```bash
xcode-build -scheme Rosier -destination "platform=iOS Simulator,name=iPhone 15"
```

---

## Production Checklist

- [ ] ViewModels added to RosierUI framework sources
- [ ] All files compiled without warnings
- [ ] Previews render correctly in Xcode
- [ ] NetworkService configured with base URL
- [ ] AuthService provides valid JWT tokens
- [ ] Share tracking endpoint is live
- [ ] Deep links are functional (rosier.app/invite/{CODE})
- [ ] Analytics events are firing
