# Rosier iOS - Dependencies and Import Structure

## Overview

Rosier uses **zero external dependencies** and leverages only standard iOS frameworks.

## Framework Dependencies

### Core Frameworks
- **Foundation** - Base classes, data types, networking
- **SwiftUI** - UI framework (iOS 17+)
- **UIKit** - Legacy components (haptics, delegates, appearance)
- **Combine** - Reactive programming

### System Frameworks
- **UserNotifications** - Push notifications and local notifications
- **AuthenticationServices** - Apple Sign-In integration
- **Security** - Keychain operations
- **Network** - Network type detection

## Module Organization

### Import Hierarchy

```
RosierApp (Entry Point)
├── AppCoordinator
│   ├── AuthService
│   │   ├── NetworkService
│   │   └── KeychainHelper
│   ├── DeepLinkService
│   └── AppDelegate
│
├── MainCoordinator
│   ├── CardQueueService
│   │   ├── NetworkService
│   │   └── ImageCacheService
│   ├── SwipeEventService
│   │   └── NetworkService
│   ├── AnalyticsService
│   │   └── NetworkService
│   └── Models (Product, DresserDrawer, etc.)
│
└── DesignSystem
    ├── Colors
    ├── Typography
    ├── Haptics
    └── Animations
```

## File-by-File Import Summary

### DesignSystem/

**Colors.swift**
```swift
import SwiftUI
// ✓ No internal dependencies
```

**Typography.swift**
```swift
import SwiftUI
// ✓ No internal dependencies
```

**Haptics.swift**
```swift
import UIKit
// ✓ No internal dependencies
```

**Animations.swift**
```swift
import SwiftUI
// ✓ No internal dependencies
```

### Models/

**Product.swift**
```swift
import Foundation
// Dependencies: ProductCategory (enum in same file)
```

**Brand.swift**
```swift
import Foundation
// Dependencies: BrandTier (enum in same file)
```

**SwipeEvent.swift**
```swift
import Foundation
import UIKit  // For device info
// Dependencies: SwipeAction, NetworkType (enums in same file)
```

**DresserDrawer.swift**
```swift
import SwiftUI  // For Color enum
import Foundation
// Dependencies: DresserColorTag, SavedProduct (in same file)
```

**UserProfile.swift**
```swift
import Foundation
// Dependencies: AgeRange, QuizResponses, PricePreferences (in same file)
```

**StyleDNA.swift**
```swift
import Foundation
// Dependencies: ColorPalette, TemperaturePreference, PriceRange, StyleStats (in same file)
```

**CardQueueItem.swift**
```swift
import Foundation
// Dependencies: Product (from Models/)
```

### Services/

**NetworkService.swift**
```swift
import Foundation
// Dependencies: HTTPMethod, NetworkError (enums in same file)
// Uses: AuthService (weak reference)
```

**AuthService.swift**
```swift
import Foundation
import AuthenticationServices
// Dependencies: All auth request/response structs (in same file)
// Uses: NetworkService, KeychainHelper
```

**CardQueueService.swift**
```swift
import Foundation
// Dependencies: CardQueueRequest, CardQueueResponse, CardQueueError (in same file)
// Uses: NetworkService, ImageCacheService, CardQueueItem, Product
```

**SwipeEventService.swift**
```swift
import Foundation
// Dependencies: SwipeEventBatchRequest (in same file)
// Uses: NetworkService, SwipeEvent
```

**ImageCacheService.swift**
```swift
import Foundation
import UIKit
import SwiftUI  // For CachedAsyncImage extension
// Dependencies: CachedAsyncImage (in same file)
// ✓ No service dependencies
```

**AnalyticsService.swift**
```swift
import Foundation
// Dependencies: AnalyticsEvent, AnalyticsEventBatch, UserAction (in same file)
// Uses: NetworkService
```

**DeepLinkService.swift**
```swift
import Foundation
// Dependencies: DeepLink (enum in same file)
// ✓ No service dependencies
```

### Coordinators/

**Coordinator.swift**
```swift
import Foundation
import SwiftUI
// Dependencies: OnboardingScreen, MainScreen, SheetType, FullScreenCoverType (enums in same file)
// ✓ No service dependencies
```

**AppCoordinator.swift**
```swift
import SwiftUI
import Combine
// Dependencies: BaseCoordinator, AuthState (enum in same file)
// Uses: AuthService, DeepLinkService
```

**OnboardingCoordinator.swift**
```swift
import SwiftUI
// Dependencies: BaseCoordinator, OnboardingScreen
// Uses: AuthService, AnalyticsService, QuizResponses
```

**MainCoordinator.swift**
```swift
import SwiftUI
// Dependencies: BaseCoordinator, MainScreen, Tab (enum in same file)
// Uses: CardQueueService, AnalyticsService, DeepLinkService
```

**AuthCoordinator.swift**
```swift
import SwiftUI
// Dependencies: BaseCoordinator, AuthScreen (enum in same file)
// Uses: AuthService, PasswordResetRequest (in same file)
```

### App/

**RosierApp.swift**
```swift
import SwiftUI
// Dependencies: AppCoordinator, SplashScreenView, AuthFlowContainer, etc.
// Uses: All coordinators and helper views
```

**AppDelegate.swift**
```swift
import UIKit
import UserNotifications
// Dependencies: DeviceTokenRequest (in same file)
// Uses: NetworkService, AnalyticsService, SwipeEventService, DeepLinkService
```

### Extensions/

**View+Extensions.swift**
```swift
import SwiftUI
// ✓ No dependencies
```

**Date+Extensions.swift**
```swift
import Foundation
// ✓ No dependencies
```

**Decimal+Extensions.swift**
```swift
import Foundation
// Dependencies: PriceBracket (enum in same file)
```

## Dependency Injection Pattern

All services use dependency injection through initializers:

```swift
// Example: CardQueueService
init(
    networkService: NetworkService = .shared,
    imageCacheService: ImageCacheService = .shared
) {
    // Can inject test doubles in tests
}
```

## Singleton Pattern

Services use thread-safe singletons:

```swift
class NetworkService {
    static let shared = NetworkService()
    private init() {}
}
```

This pattern allows for:
- Lazy initialization
- Single instance throughout app lifetime
- Easy testing via dependency injection in init

## Memory Management

All cross-service references use weak references to prevent cycles:

```swift
private weak var authService: AuthService?
```

## Thread Safety

- Network requests use async/await on background threads
- UI updates dispatched to MainActor
- UserDefaults access is thread-safe by default
- Keychain access is thread-safe

## No External Dependencies

Rosier intentionally avoids external packages for:
- Networking (uses URLSession)
- Caching (uses NSCache + URLCache)
- Analytics (uses custom service)
- Date handling (uses Foundation + extensions)
- Concurrency (uses native async/await)

This ensures:
- Minimal build time
- Maximum control over behavior
- Easy maintenance and updates
- No version conflicts
- Optimal app size and performance

## Import Optimization

Each file imports only what it needs:

```swift
// ✓ Specific imports
import Foundation
import SwiftUI

// ✗ Avoid unnecessary imports
// import Combine  // Only if needed
```

## Testing Compatibility

All services and coordinators support dependency injection for testing:

```swift
// In unit tests
let mockNetworkService = MockNetworkService()
let authService = AuthService(networkService: mockNetworkService)
```

Protocol-based services allow full mock implementations:

```swift
protocol AnalyticsServiceProtocol {
    func trackEvent(_ name: String, properties: [String: Any]?)
}

class MockAnalyticsService: AnalyticsServiceProtocol {
    // Test implementation
}
```
