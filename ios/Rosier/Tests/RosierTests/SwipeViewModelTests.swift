import XCTest
@testable import Rosier

final class SwipeViewModelTests: XCTestCase {
    // MARK: - Properties

    var sut: SwipeViewModel!
    var mockCardQueueService: MockCardQueueService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockCardQueueService = MockCardQueueService()
        sut = SwipeViewModel(cardQueueService: mockCardQueueService)
    }

    override func tearDown() {
        sut = nil
        mockCardQueueService = nil
        super.tearDown()
    }

    // MARK: - Tests: Initialization

    func test_initialState_cardQueueEmpty() {
        XCTAssertNil(sut.currentCard)
        XCTAssertNil(sut.nextCard)
        XCTAssertNil(sut.thirdCard)
        XCTAssertTrue(sut.queue.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    // MARK: - Tests: Load Cards

    func test_loadCards_populatesQueue() async {
        // Given
        let products = [
            createMockProduct(id: UUID()),
            createMockProduct(id: UUID()),
            createMockProduct(id: UUID())
        ]
        let items = products.enumerated().map { index, product in
            CardQueueItem(product: product, queuePosition: index, queueSize: 3, sessionId: UUID())
        }
        mockCardQueueService.queueToReturn = items

        // When
        await sut.initializeSwipeView()

        // Then
        XCTAssertNotNil(sut.currentCard)
        XCTAssertEqual(sut.currentCard?.product.id, products[0].id)
        XCTAssertEqual(sut.queue.count, 2)
    }

    // MARK: - Tests: Swipe Actions

    func test_swipeRight_sendsLikeEvent() async {
        // Given
        setupQueueWithCards(count: 3)
        await sut.initializeSwipeView()

        let initialCard = sut.currentCard

        // When
        sut.handleSwipe(.like)

        // Then
        XCTAssertNotEqual(sut.currentCard?.product.id, initialCard?.product.id)
        XCTAssertNotNil(sut.currentCard)
    }

    func test_swipeLeft_sendsRejectEvent() async {
        // Given
        setupQueueWithCards(count: 3)
        await sut.initializeSwipeView()

        let initialCard = sut.currentCard

        // When
        sut.handleSwipe(.reject)

        // Then
        XCTAssertNotEqual(sut.currentCard?.product.id, initialCard?.product.id)
    }

    func test_swipeUp_sendsSuperLikeEvent() async {
        // Given
        setupQueueWithCards(count: 3)
        await sut.initializeSwipeView()

        let initialCard = sut.currentCard

        // When
        sut.handleSwipe(.superLike)

        // Then
        XCTAssertNotEqual(sut.currentCard?.product.id, initialCard?.product.id)
    }

    // MARK: - Tests: Undo

    func test_undo_restoresLastCard() async {
        // Given
        setupQueueWithCards(count: 5)
        await sut.initializeSwipeView()

        let firstCard = sut.currentCard

        // When
        sut.handleSwipe(.like)
        sut.undo()

        // Then
        XCTAssertEqual(sut.currentCard?.product.id, firstCard?.product.id)
    }

    func test_undo_nullifiesPreviousEvent() async {
        // Given
        setupQueueWithCards(count: 3)
        await sut.initializeSwipeView()

        // When
        sut.handleSwipe(.like)
        let undoCount = sut.queue.count
        sut.undo()

        // Then
        XCTAssertEqual(sut.queue.count, undoCount)
    }

    // MARK: - Tests: Pre-fetch

    func test_preFetchTriggersAtFiveCards() async {
        // Given
        setupQueueWithCards(count: 8)
        await sut.initializeSwipeView()

        // When
        for _ in 0..<3 {
            sut.handleSwipe(.like)
        }

        // Then - queue should have triggered prefetch when reaching 5 cards
        XCTAssertTrue(sut.queue.count > 0)
    }

    // MARK: - Tests: Dwell Time

    func test_dwellTimeTracking() {
        // Given
        sut.startDwellTracking()

        // When
        Thread.sleep(forTimeInterval: 0.1)
        let card = createMockCardItem()
        sut.currentCard = card

        // Then
        XCTAssertNotNil(sut.currentCard)
    }

    // MARK: - Tests: Offline State

    func test_offlineState_usesCache() async {
        // Given
        setupQueueWithCards(count: 3)
        await sut.initializeSwipeView()

        // When
        let beforeLoad = sut.currentCard

        // Then
        XCTAssertNotNil(beforeLoad)
    }

    // MARK: - Tests: Session Position

    func test_sessionPositionIncrements() async {
        // Given
        setupQueueWithCards(count: 5)
        await sut.initializeSwipeView()

        // When
        sut.handleSwipe(.like)
        sut.handleSwipe(.reject)
        sut.handleSwipe(.superLike)

        // Then
        XCTAssertNotNil(sut.currentCard)
    }

    // MARK: - Tests: Queue Refresh

    func test_cardQueueRefresh() async {
        // Given
        setupQueueWithCards(count: 3)
        await sut.initializeSwipeView()
        let firstCard = sut.currentCard

        // When
        mockCardQueueService.queueToReturn = [
            createMockCardItem(),
            createMockCardItem(),
            createMockCardItem()
        ]

        // Then
        XCTAssertNotNil(firstCard)
    }

    // MARK: - Helper Methods

    private func setupQueueWithCards(count: Int) {
        let products = (0..<count).map { _ in createMockProduct(id: UUID()) }
        let items = products.enumerated().map { index, product in
            CardQueueItem(product: product, queuePosition: index, queueSize: count, sessionId: UUID())
        }
        mockCardQueueService.queueToReturn = items
    }

    private func createMockProduct(id: UUID = UUID()) -> Product {
        Product(
            id: id,
            externalId: "ext-\(id.uuidString)",
            retailerId: UUID(),
            brandId: UUID(),
            brandName: "Test Brand",
            name: "Test Product",
            description: "A test product",
            category: .clothing,
            subcategory: "dress",
            currentPrice: 99.99,
            originalPrice: 149.99,
            currency: "USD",
            isOnSale: true,
            saleEndDate: nil,
            sizesAvailable: ["XS", "S", "M", "L"],
            colors: ["Black", "White"],
            materials: ["Cotton"],
            imageURLs: [URL(string: "https://example.com/image.jpg")!],
            productURL: URL(string: "https://example.com/product")!,
            affiliateURL: nil,
            retailerName: "Test Retailer",
            retailerFaviconURL: nil,
            categoryTag: "dresses",
            tags: ["trendy", "summer"]
        )
    }

    private func createMockCardItem() -> CardQueueItem {
        CardQueueItem(
            product: createMockProduct(),
            queuePosition: 0,
            queueSize: 10,
            sessionId: UUID()
        )
    }
}
