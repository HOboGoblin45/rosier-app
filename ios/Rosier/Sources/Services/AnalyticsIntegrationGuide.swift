import Foundation

/// COMPREHENSIVE ANALYTICS INTEGRATION GUIDE
/// ==========================================
/// This file provides detailed code snippets and instructions for adding analytics
/// tracking to every view in the Rosier app. Copy these code patterns into the
/// specified view files to instrument the app.

// MARK: - SWIPEVIEW INTEGRATION

/// FILE: Sources/Views/Swipe/SwipeView.swift
/// Add these tracking calls to SwipeView and related components:
///
/// 1. CARD IMPRESSION (when card appears)
///    Add this to CardStackView or where cards are displayed:
///
///    .onAppear {
///        guard let currentCard = currentCard else { return }
///        let event = AnalyticsEvent.cardImpression(
///            productId: currentCard.product.id.uuidString,
///            brandId: currentCard.product.brandId.uuidString,
///            category: currentCard.product.category.rawValue,
///            price: currentCard.product.currentPrice.description,
///            isOnSale: currentCard.product.isOnSale,
///            retailerId: currentCard.product.retailerId.uuidString,
///            positionInSession: currentCard.queuePosition
///        )
///        AnalyticsTracker.shared.track(event)
///    }
///
/// 2. CARD SWIPED (when user swipes)
///    Add this to SwipeView's handleSwipe method:
///
///    func handleSwipe(_ action: SwipeAction) {
///        let direction = action == .like ? "right" : "left"
///        let dwellTimeMs = Int(Date().timeIntervalSince(cardShowTime) * 1000)
///
///        let event = AnalyticsEvent.cardSwiped(
///            productId: currentCard.product.id.uuidString,
///            direction: direction,
///            dwellTimeMs: dwellTimeMs,
///            expandedBeforeSwipe: wasCardExpanded
///        )
///        AnalyticsTracker.shared.track(event)
///
///        // ... rest of swipe logic
///    }
///
/// 3. CARD UNDO (when user undoes a swipe)
///    Add this to SwipeView's undo method:
///
///    func undo() {
///        guard let lastSwiped = swipeHistory.last else { return }
///        let timeSinceSwipeMs = Int(Date().timeIntervalSince(lastSwiped.date) * 1000)
///
///        let event = AnalyticsEvent.cardUndo(
///            productId: lastSwiped.product.id.uuidString,
///            originalDirection: lastSwiped.direction == .like ? "right" : "left",
///            timeSinceSwipeMs: timeSinceSwipeMs
///        )
///        AnalyticsTracker.shared.track(event)
///
///        // ... rest of undo logic
///    }
///
/// 4. FEED END REACHED (when user runs out of cards)
///    Add this when the feed reaches the end:
///
///    if viewModel.isEndOfFeed {
///        let sessionDurationMs = Int(Date().timeIntervalSince(sessionStartTime) * 1000)
///        let event = AnalyticsEvent.feedEndReached(
///            cardsSwipedInSession: swipesInCurrentSession,
///            sessionDurationMs: sessionDurationMs
///        )
///        AnalyticsTracker.shared.track(event)
///    }

// MARK: - PRODUCTDETAILSHEET INTEGRATION

/// FILE: Sources/Views/Swipe/ProductDetailSheet.swift
/// Add these tracking calls when users interact with product details:
///
/// 1. CARD EXPANDED (when detail sheet opens)
///    Add this to ProductDetailSheet's onAppear:
///
///    .onAppear {
///        let event = AnalyticsEvent.cardExpanded(
///            productId: product.id.uuidString,
///            imagesViewedCount: 0,
///            timeInDetailMs: 0,
///            scrolledToSimilar: false
///        )
///        detailStartTime = Date()
///        initialExpansionTracked = true
///        AnalyticsTracker.shared.track(event)
///    }
///
/// 2. SHOP CLICKED (when user taps shop button)
///    Add this to the shop button action:
///
///    Button(action: {
///        let event = AnalyticsEvent.shopClicked(
///            productId: product.id.uuidString,
///            retailerId: product.retailerId.uuidString,
///            price: product.currentPrice.description,
///            isOnSale: product.isOnSale,
///            affiliateNetwork: "commission_junction" // or other affiliate network
///        )
///        AnalyticsTracker.shared.track(event)
///
///        // Open shop URL
///        UIApplication.shared.open(product.affiliateURL ?? product.productURL)
///    })
///
/// 3. SIMILAR ITEM TAPPED (when user taps a similar item)
///    Add this to the similar items grid:
///
///    ForEach(similarItems) { item in
///        SimilarItemCard(item: item)
///            .onTapGesture {
///                let event = AnalyticsEvent.similarItemTapped(
///                    sourceProductId: product.id.uuidString,
///                    tappedProductId: item.id.uuidString
///                )
///                AnalyticsTracker.shared.track(event)
///                // Navigate to detail or update display
///            }
///    }

// MARK: - WELCOMEVIEW INTEGRATION

/// FILE: Sources/Views/Onboarding/WelcomeView.swift
/// Add this tracking call when onboarding starts:
///
/// 1. ONBOARDING STARTED
///    Add this to WelcomeView's initialization or when "Get Started" is tapped:
///
///    .task {
///        let event = AnalyticsEvent.onboardingStarted(source: "app_launch")
///        AnalyticsTracker.shared.track(event)
///    }
///
///    Or in the onGetStarted button:
///
///    Button(action: {
///        let event = AnalyticsEvent.onboardingStarted(source: "welcome_screen")
///        AnalyticsTracker.shared.track(event)
///        onGetStarted()
///    })

// MARK: - STYLEQUIZVIEW INTEGRATION

/// FILE: Sources/Views/Onboarding/StyleQuizView.swift
/// Add these tracking calls throughout the quiz:
///
/// 1. QUIZ QUESTION ANSWERED
///    Add this when user selects an answer:
///
///    @State private var questionStartTime: Date?
///
///    .onAppear {
///        questionStartTime = Date()
///    }
///
///    // When user selects an image:
///    Button(action: {
///        if let startTime = questionStartTime {
///            let timeSpentMs = Int(Date().timeIntervalSince(startTime) * 1000)
///
///            let event = AnalyticsEvent.quizQuestionAnswered(
///                questionNumber: viewModel.currentQuestion + 1,
///                questionType: "visual",
///                answers: selectedAnswers.map { String($0) },
///                timeSpentMs: timeSpentMs
///            )
///            AnalyticsTracker.shared.track(event)
///        }
///        viewModel.selectImage(at: index, for: viewModel.currentQuestion)
///    })
///
/// 2. QUIZ COMPLETED
///    Add this when quiz finishes:
///
///    .task {
///        if viewModel.isQuizComplete {
///            let totalTimeMs = Int(Date().timeIntervalSince(quizStartTime) * 1000)
///
///            let event = AnalyticsEvent.quizCompleted(totalTimeMs: totalTimeMs)
///            AnalyticsTracker.shared.track(event)
///
///            onCompletion()
///        }
///    }
///
/// 3. QUIZ ABANDONED
///    Add this when user exits without completing:
///
///    func exitQuiz() {
///        let totalTimeMs = Int(Date().timeIntervalSince(quizStartTime) * 1000)
///
///        let event = AnalyticsEvent.quizAbandoned(
///            lastQuestion: viewModel.currentQuestion + 1,
///            timeSpentMs: totalTimeMs
///        )
///        AnalyticsTracker.shared.track(event)
///        dismiss()
///    }
///
/// 4. TUTORIAL DISMISSED
///    Add this when user closes any tutorial overlay:
///
///    Button(action: {
///        let event = AnalyticsEvent.tutorialDismissed(method: "tap_x")
///        AnalyticsTracker.shared.track(event)
///        showTutorial = false
///    })

// MARK: - DRESSER AND DRAWERVIEWS INTEGRATION

/// FILE: Sources/Views/Dresser/DresserView.swift
/// Add these tracking calls for dresser operations:
///
/// 1. DRESSER OPENED
///    Add this when DresserView appears:
///
///    .onAppear {
///        let event = AnalyticsEvent.dresserOpened(source: "tab_bar")
///        AnalyticsTracker.shared.track(event)
///    }
///
/// 2. DRAWER CREATED
///    Add this when user creates a new drawer:
///
///    Button(action: {
///        Task {
///            await viewModel.createDrawer(
///                name: drawerName,
///                description: nil,
///                colorTag: drawerColor
///            )
///
///            let event = AnalyticsEvent.drawerCreated(
///                name: drawerName,
///                totalDrawers: viewModel.drawers.count
///            )
///            AnalyticsTracker.shared.track(event)
///            isCreatingDrawer = false
///        }
///    })
///
/// 3. DRAWER RENAMED
///    Add this when user renames a drawer (if editing is supported):
///
///    func renameDrawer(_ drawer: DresserDrawer, newName: String) {
///        let event = AnalyticsEvent.drawerRenamed(
///            oldName: drawer.name,
///            newName: newName
///        )
///        AnalyticsTracker.shared.track(event)
///        // Update drawer name
///    }
///
/// 4. DRESSER ITEM MOVED
///    Add this in the context menu when user moves an item:
///
///    Menu("Move to Drawer") {
///        ForEach(viewModel.drawers.filter { $0.id != drawer.id }) { target in
///            Button(target.name) {
///                Task {
///                    await viewModel.moveItem(item, fromDrawer: drawer.id, toDrawer: target.id)
///
///                    let event = AnalyticsEvent.dresserItemMoved(
///                        productId: item.productId.uuidString,
///                        fromDrawer: drawer.name,
///                        toDrawer: target.name
///                    )
///                    AnalyticsTracker.shared.track(event)
///                }
///            }
///        }
///    }
///
/// 5. DRESSER ITEM REMOVED
///    Add this in the context menu when user deletes an item:
///
///    Button("Remove", role: .destructive) {
///        Task {
///            await viewModel.removeItem(item, fromDrawer: drawer.id)
///
///            let event = AnalyticsEvent.dresserItemRemoved(
///                productId: item.productId.uuidString,
///                drawerId: drawer.id.uuidString
///            )
///            AnalyticsTracker.shared.track(event)
///        }
///    }
///
/// 6. DRESSER SHARED
///    Add this when user shares a drawer:
///
///    Button(action: {
///        Task {
///            await viewModel.shareDrawerMoodboard(for: drawer)
///
///            let event = AnalyticsEvent.dresserShared(
///                drawerId: drawer.id.uuidString,
///                shareMethod: "instagram_stories", // or other method
///                itemCount: drawer.itemCount
///            )
///            AnalyticsTracker.shared.track(event)
///        }
///    })

// MARK: - PROFILEVIEW INTEGRATION

/// FILE: Sources/Views/Profile/ProfileView.swift
/// Add these tracking calls for profile interactions:
///
/// 1. STYLE DNA VIEWED
///    Add this in StyleDNACardView when it appears:
///
///    .onAppear {
///        let event = AnalyticsEvent.styleDNAViewed(
///            swipeCount: viewModel.styleDNA?.stats.totalSwipes ?? 0,
///            archetype: viewModel.styleDNA?.archetype ?? "unknown"
///        )
///        AnalyticsTracker.shared.track(event)
///    }
///
/// 2. STYLE DNA SHARED
///    Add this in the share button action:
///
///    Button(action: {
///        let event = AnalyticsEvent.styleDNAShared(
///            shareMethod: "instagram_stories",
///            archetype: viewModel.styleDNA?.archetype ?? "unknown"
///        )
///        AnalyticsTracker.shared.track(event)
///        viewModel.shareStyleDNA()
///    })

// MARK: - SETTINGSVIEW INTEGRATION

/// FILE: Sources/Views/Settings/SettingsView.swift
/// Add this tracking call when user changes settings:
///
/// Picker(selection: $notificationsEnabled) {
///     // ... picker options
/// }
/// .onChange(of: notificationsEnabled) { oldValue, newValue in
///     let event = AnalyticsEvent.settingsChanged(
///         settingName: "notifications_enabled",
///         oldValue: oldValue ? "true" : "false",
///         newValue: newValue ? "true" : "false"
///     )
///     AnalyticsTracker.shared.track(event)
/// }

// MARK: - ROSIERAPP INTEGRATION

/// FILE: Sources/App/RosierApp.swift
/// Add these tracking calls for app lifecycle:
///
/// 1. APP SESSION START
///    Add this in the App struct's initialization or in the root view:
///
///    .onAppear {
///        let daysSinceLast = calculateDaysSinceLastSession() // implement based on your logic
///        let event = AnalyticsEvent.appSessionStart(
///            daysSinceLastSession: daysSinceLast,
///            entryPoint: "app_launch"
///        )
///        AnalyticsTracker.shared.track(event)
///        sessionStartTime = Date()
///    }
///
/// 2. APP SESSION END
///    Add this when app enters background (in SceneDelegate or using @Environment):
///
///    .onDisappear {
///        let durationMs = Int(Date().timeIntervalSince(sessionStartTime) * 1000)
///        let event = AnalyticsEvent.appSessionEnd(
///            durationMs: durationMs,
///            cardsSwiped: swipeViewModel.cardsSwipedInSession,
///            itemsSaved: dresserViewModel.itemsSavedInSession,
///            shopClicks: shopClickCount
///        )
///        AnalyticsTracker.shared.track(event)
///        AnalyticsTracker.shared.flush()
///    }

// MARK: - NOTIFICATION HANDLING INTEGRATION

/// FILE: NotificationDelegate or similar
/// Add these tracking calls for notification interactions:
///
/// 1. NOTIFICATION RECEIVED
///    Add this when a notification is delivered:
///
///    func userNotificationCenter(
///        _ center: UNUserNotificationCenter,
///        willPresent notification: UNNotification
///    ) async -> UNNotificationPresentationOptions {
///        let event = AnalyticsEvent.notificationReceived(
///            type: notification.request.content.categoryIdentifier
///        )
///        AnalyticsTracker.shared.track(event)
///        return [.banner, .sound]
///    }
///
/// 2. NOTIFICATION TAPPED
///    Add this when user responds to a notification:
///
///    func userNotificationCenter(
///        _ center: UNUserNotificationCenter,
///        didReceive response: UNNotificationResponse
///    ) async {
///        let notificationTime = Date()
///        let deliveryTime = Date() // parse from notification payload
///        let timeSinceDeliveryMs = Int(notificationTime.timeIntervalSince(deliveryTime) * 1000)
///
///        let event = AnalyticsEvent.notificationTapped(
///            type: response.notification.request.content.categoryIdentifier,
///            productId: extractProductId(from: response.notification),
///            timeSinceDeliveryMs: timeSinceDeliveryMs
///        )
///        AnalyticsTracker.shared.track(event)
///    }

// MARK: - BEST PRACTICES

/// IMPORTANT GUIDELINES:
///
/// 1. TIMING
///    - Track impressions (.cardImpression) when a card first appears
///    - Track interactions (swiping, tapping) immediately after the action
///    - Track completions (quiz_completed) when the action is fully done
///    - Track time accurately using Date().timeIntervalSince()
///
/// 2. USER PRIVACY
///    - Never track sensitive data (passwords, full SSNs, etc.)
///    - Use UUIDs instead of email addresses when possible
///    - Respect user's tracking preferences (check Info.plist for App Tracking Transparency)
///
/// 3. PERFORMANCE
///    - AnalyticsTracker batches events automatically
///    - Use `.track()` freely - it's async and won't block the UI
///    - Call `.flush()` only when absolutely necessary (on app exit, after critical events)
///
/// 4. DATA QUALITY
///    - Always provide all required parameters for each event
///    - Use consistent naming for strings (e.g., "instagram_stories" vs "instastories")
///    - Include context (brand_id, retailer_id) for purchase-related events
///
/// 5. TESTING
///    - Use Xcode console to verify events are being tracked
///    - Check that all required properties are present
///    - Validate event names match the spec exactly
///
/// 6. COMMON PATTERNS
///
///    // Time-based tracking
///    @State private var cardShowTime: Date?
///    .onAppear { cardShowTime = Date() }
///    .onDisappear {
///        if let showTime = cardShowTime {
///            let dwellTimeMs = Int(Date().timeIntervalSince(showTime) * 1000)
///            // Use dwellTimeMs in event
///        }
///    }
///
///    // Boolean to string conversion
///    let stringValue = isOnSale ? "true" : "false"
///
///    // Safe optional unwrapping with defaults
///    let productId = product.id.uuidString  // Always safe if UUID is available
///    let retailerIdOpt = retailer?.id.uuidString  // Use optional in event properties
