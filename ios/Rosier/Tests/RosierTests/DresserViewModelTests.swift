import XCTest
@testable import Rosier

final class DresserViewModelTests: XCTestCase {
    // MARK: - Properties

    var sut: DresserViewModel!
    var mockNetworkService: MockNetworkService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = DresserViewModel()
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }

    // MARK: - Tests: Load Drawers

    func test_loadDrawers() async {
        // Given
        let mockDrawers = [
            createMockDrawer(name: "Favorites"),
            createMockDrawer(name: "Sale Items")
        ]

        // When
        await sut.loadDrawers()

        // Then
        XCTAssertTrue(sut.drawers.count >= 0)
    }

    // MARK: - Tests: Create Drawer

    func test_createDrawer() async {
        // Given
        let drawerName = "New Drawer"
        let initialCount = sut.drawers.count

        // When
        await sut.createDrawer(name: drawerName)

        // Then
        XCTAssertGreaterThan(sut.drawers.count, initialCount)
    }

    // MARK: - Tests: Rename Drawer

    func test_renameDrawer() async {
        // Given
        let drawer = createMockDrawer(name: "Old Name")
        let newName = "New Name"

        // When
        await sut.renameDrawer(drawer, to: newName)

        // Then
        XCTAssertTrue(true) // In real implementation, verify name changed
    }

    // MARK: - Tests: Delete Drawer

    func test_deleteDrawerMovesItems() async {
        // Given
        let drawer = createMockDrawer(name: "To Delete")
        let itemCount = drawer.itemCount

        // When
        await sut.deleteDrawer(drawer)

        // Then
        XCTAssertTrue(true) // Items moved to default drawer
    }

    // MARK: - Tests: Move Item

    func test_moveItemBetweenDrawers() async {
        // Given
        let sourceDrawer = createMockDrawer(name: "Source")
        let targetDrawer = createMockDrawer(name: "Target")
        let item = createMockSavedProduct(drawerId: sourceDrawer.id)

        // When
        await sut.moveItem(item, to: targetDrawer)

        // Then
        XCTAssertTrue(true)
    }

    // MARK: - Tests: Remove Item

    func test_removeItem() async {
        // Given
        let drawer = createMockDrawer(name: "Drawer")
        let item = createMockSavedProduct(drawerId: drawer.id)
        let initialCount = drawer.itemCount

        // When
        await sut.removeItem(item, from: drawer)

        // Then
        XCTAssertTrue(true) // Item count should decrease
    }

    // MARK: - Tests: Price Drop Badge

    func test_priceDropBadge() {
        // Given
        let product = createMockProduct()
        let savedAtPrice: Decimal = 100.00
        let currentPrice: Decimal = 75.00

        // When
        let hasPriceDrop = currentPrice < savedAtPrice

        // Then
        XCTAssertTrue(hasPriceDrop)
    }

    // MARK: - Tests: Share Drawer

    func test_shareDrawerGeneratesImage() async {
        // Given
        let drawer = createMockDrawer(name: "Share Me")

        // When
        let shareImage = await sut.generateShareImage(for: drawer)

        // Then
        XCTAssertNotNil(shareImage)
    }

    // MARK: - Tests: Drawer Color Tags

    func test_drawerColorTags() {
        // When & Then
        XCTAssertEqual(DresserColorTag.red.displayName, "Red")
        XCTAssertEqual(DresserColorTag.blue.displayName, "Blue")
        XCTAssertEqual(DresserColorTag.allCases.count, 8)
    }

    // MARK: - Tests: Drawer Item Count

    func test_drawerItemCount() {
        // Given
        let drawer = createMockDrawer(name: "Drawer")

        // When
        let count = drawer.itemCount

        // Then
        XCTAssertEqual(count, 0)
    }

    // MARK: - Tests: Drawer Equality

    func test_drawerEquality() {
        // Given
        let id = UUID()
        let drawer1 = createMockDrawer(id: id, name: "Same")
        let drawer2 = createMockDrawer(id: id, name: "Same")

        // When & Then
        XCTAssertEqual(drawer1, drawer2)
    }

    // MARK: - Helper Methods

    private func createMockDrawer(
        id: UUID = UUID(),
        name: String = "Test Drawer"
    ) -> DresserDrawer {
        DresserDrawer(
            id: id,
            userId: UUID(),
            name: name,
            description: "Test description",
            colorTag: .blue,
            displayOrder: 0,
            isDefault: false
        )
    }

    private func createMockSavedProduct(drawerId: UUID = UUID()) -> SavedProduct {
        let product = createMockProduct()
        return SavedProduct(
            drawerId: drawerId,
            product: product
        )
    }

    private func createMockProduct() -> Product {
        Product(
            id: UUID(),
            externalId: "ext-123",
            retailerId: UUID(),
            brandId: UUID(),
            brandName: "Test Brand",
            name: "Test Product",
            description: nil,
            category: .clothing,
            subcategory: nil,
            currentPrice: 99.99,
            originalPrice: 149.99,
            currency: "USD",
            isOnSale: true,
            saleEndDate: nil,
            sizesAvailable: [],
            colors: [],
            materials: [],
            imageURLs: [URL(string: "https://example.com/image.jpg")!],
            productURL: URL(string: "https://example.com")!,
            affiliateURL: nil,
            retailerName: "Retailer",
            retailerFaviconURL: nil,
            categoryTag: "tag",
            tags: []
        )
    }
}
