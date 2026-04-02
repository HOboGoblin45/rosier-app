# Rosier iOS Project Structure

This document describes the complete iOS foundation for Rosier, a swipe-based niche fashion discovery app.

## Architecture Overview

The app uses **MVVM + Coordinators** pattern with:
- **SwiftUI** for UI (iOS 17+)
- **Coordinator Pattern** for navigation
- **Service Layer** for business logic
- **Model Layer** with Codable conformance
- **Design System** with centralized styling

## Project Structure

```
Sources/
├── DesignSystem/         # Design tokens and styling
├── Models/               # Data models
├── Services/             # Business logic and networking
├── Coordinators/         # Navigation and flow management
├── App/                  # App entry point and delegates
└── Extensions/           # Swift extensions and utilities
```

## Directory Details

### DesignSystem/

Centralized design system with production-ready tokens:

- **Colors.swift** - Color tokens with light/dark variants
  - Brand colors: primaryBrand, accent
  - Surface colors: card, background
  - Text colors: primary, secondary, tertiary
  - Status colors: sale, success, destructive

- **Typography.swift** - Text styles with Dynamic Type
  - Display, Title, Body, Caption, Footnote, Micro
  - View modifiers for easy application

- **Haptics.swift** - Haptic feedback manager
  - Centralized haptic feedback for all interactions
  - Methods: swipeLeft, swipeRight, superLike, undo, buttonPress

- **Animations.swift** - Animation constants
  - Spring animations with specific damping ratios
  - Transition durations for card UI
  - Reduced motion support

### Models/

Data models with Codable conformance:

- **Product.swift** - Fashion product model
  - Pricing, images, retailer info
  - Computed properties: discount percentage, primary image

- **Brand.swift** - Fashion brand model
  - Brand tier classification (emerging, established, luxury)
  - Aesthetic tags and verification status

- **SwipeEvent.swift** - User interaction tracking
  - Swipe actions: like, reject, superLike, undo, viewDetail, shopClick
  - Device context and network type detection

- **DresserDrawer.swift** - Virtual wardrobe management
  - Drawer model with color tags and display order
  - SavedProduct model for saved items

- **UserProfile.swift** - User information and preferences
  - Authentication state, profile data
  - Price preferences, favorite brands, settings

- **StyleDNA.swift** - Computed style profile
  - Archetype, brand preferences, color palette
  - Stats based on swipe history

- **CardQueueItem.swift** - Card queue wrapper
  - Product reference with queue metadata
  - Progress tracking and queue state

### Services/

Core business logic and networking:

- **NetworkService.swift** - Generic URLSession wrapper
  - JWT token injection via AuthService
  - Automatic token refresh on 401
  - Custom NetworkError enum with specific error types

- **AuthService.swift** - Authentication management
  - Apple Sign-In and email authentication
  - Keychain storage for tokens
  - Session management with anonymous support
  - Token refresh and merge session handling

- **CardQueueService.swift** - Card queue management
  - Local queue of 40+ cards with pre-fetching
  - Offline support with disk caching
  - Queue invalidation when below threshold

- **SwipeEventService.swift** - Analytics event batching
  - Batches events every 10 seconds or on app background
  - Local persistence for retry on failure
  - Automatic upload on app exit

- **ImageCacheService.swift** - Image loading and caching
  - Memory cache (100MB limit) using NSCache
  - Disk cache (500MB limit) using URLCache
  - Progressive loading with low/high quality variants
  - CachedAsyncImage SwiftUI component

- **AnalyticsService.swift** - Analytics wrapper
  - Protocol-based for provider flexibility
  - Event tracking with custom properties
  - User property segmentation
  - Session management

- **DeepLinkService.swift** - Universal link handling
  - rosier:// scheme parsing
  - https://rosier.app universal links
  - Product, dresser, style DNA, invite, sale routes

### Coordinators/

Navigation and flow management:

- **Coordinator.swift** - Base coordinator protocol and implementation
  - Generic BaseCoordinator class
  - Navigation path, sheet, and full screen cover management
  - Screen and sheet type definitions

- **AppCoordinator.swift** - Root app flow
  - Authentication state management (checking, unauthenticated, authenticating, authenticated, onboarding)
  - Deep link routing
  - Auth state detection and transitions

- **OnboardingCoordinator.swift** - Onboarding flow
  - Welcome → StyleQuiz → Confirmation sequence
  - Quiz response capture and archetype selection
  - Session merge after completion

- **MainCoordinator.swift** - Tab-based main app
  - Tab management (Swipe, Dresser, Profile)
  - Card queue initialization
  - Product detail and drawer navigation
  - Share and filter sheet management

- **AuthCoordinator.swift** - Authentication flows
  - Sign in and sign up screens
  - Apple Sign-In handling
  - Password reset flow
  - Error state management

### App/

App entry point and lifecycle:

- **RosierApp.swift** - SwiftUI App entry point
  - AppCoordinator initialization
  - Auth state-based view routing
  - Deep link URL handling
  - Container views for each auth state

- **AppDelegate.swift** - UIKit lifecycle
  - Push notification registration
  - Remote notification handling
  - Deep link routing from notifications
  - App appearance configuration
  - Analytics session management

### Extensions/

Swift extensions and utilities:

- **View+Extensions.swift**
  - Conditional modifiers (`if`, `ifElse`)
  - Loading and error states
  - Layout helpers (center, padding, spacing)
  - Shape and styling (corner radius, containers)
  - Accessibility helpers
  - Debug modifiers

- **Date+Extensions.swift**
  - Date formatting (short, long, relative)
  - Date calculations and comparisons
  - Sale-specific formatters
  - Social sharing formatters

- **Decimal+Extensions.swift**
  - Currency formatting (USD, compact, localized)
  - Discount calculations
  - Price bracket classification
  - Rounding and arithmetic

## Key Features

### Authentication
- Apple Sign-In integration
- Email/password authentication
- Keychain secure token storage
- Automatic token refresh
- Anonymous session support with merge

### Product Discovery
- Dynamic card queue with 40+ product buffer
- Pre-fetching when queue drops below 5 items
- Offline caching support
- Image pre-loading and caching

### Swipe Analytics
- Event batching every 10 seconds or on app background
- Device context tracking (model, OS version, dark mode)
- Dwell time measurement
- Local persistence with retry

### Image Handling
- Memory cache (100MB) with LRU eviction
- Disk cache (500MB) with URLCache
- Device-appropriate image selection
- Progressive loading support
- CachedAsyncImage SwiftUI component

### Design System
- Light/dark mode support
- Dynamic Type compliance
- Haptic feedback for all interactions
- Consistent spacing and typography
- Smooth animations with reduced motion support

## iOS Requirements

- **Minimum iOS:** 17.0
- **Swift Version:** 5.9+
- **Xcode:** 15.0+

## Dependencies

No external dependencies required. Uses standard iOS frameworks:
- SwiftUI
- UIKit (for haptics, appearance)
- Combine
- Foundation
- Network (for connectivity)
- UserNotifications

## Code Quality Standards

### Conventions
- No force unwraps (`!`)
- Comprehensive doc comments on public APIs
- Proper error handling with custom enums
- Protocol-based services for testability

### Patterns
- MVVM for view models
- Coordinators for navigation
- Service layer separation
- Dependency injection via initializers
- ObservableObject for reactive updates

### Safety
- Keychain for sensitive data
- JWT Bearer authentication
- Network error handling and retry
- Proper memory management with weak references

## Building and Running

```bash
# Open in Xcode
open Rosier.xcodeproj

# Build for iOS 17+
xcodebuild -scheme Rosier -destination 'generic/platform=iOS'

# Run tests
xcodebuild test -scheme Rosier
```

## API Integration

The app integrates with a REST API at `https://api.rosier.app/v1`:

### Key Endpoints
- `POST /auth/apple` - Apple Sign-In
- `POST /auth/email` - Email authentication
- `POST /auth/refresh` - Token refresh
- `POST /auth/merge-session` - Merge anonymous session
- `POST /cards/queue` - Fetch product queue
- `POST /analytics/swipes` - Submit swipe events
- `POST /analytics/events` - Submit analytics events
- `GET /users/me` - Current user profile

## Future Enhancements

- [ ] Core Data for offline persistence
- [ ] Push notification handling
- [ ] Sharing functionality
- [ ] Wishlist and drawer sharing
- [ ] Social features (followers, recommendations)
- [ ] App Clips for shared products
- [ ] Widget support for trending items
- [ ] Siri Shortcuts integration

## Notes

All code is production-ready with:
- No placeholder or TODO comments
- Complete error handling
- Proper async/await patterns
- Memory leak prevention
- Performance optimization
