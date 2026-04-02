import XCTest
@testable import Rosier

final class ProductModelTests: XCTestCase {
    // MARK: - Tests: Decoding

    func test_productDecoding() throws {
        // Given
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "externalId": "ext-123",
            "retailerId": "550e8400-e29b-41d4-a716-446655440001",
            "brandId": "550e8400-e29b-41d4-a716-446655440002",
            "brandName": "Nike",
            "name": "Test Shoe",
            "description": "A test shoe",
            "category": "shoes",
            "subcategory": "running",
            "currentPrice": 120.00,
            "originalPrice": 150.00,
            "currency": "USD",
            "isOnSale": true,
            "saleEndDate": null,
            "sizesAvailable": ["7", "8", "9"],
            "colors": ["Black", "White"],
            "materials": ["Mesh"],
            "imageURLs": ["https://example.com/image.jpg"],
            "productURL": "https://example.com/product",
            "affiliateURL": null,
            "retailerName": "Nike Store",
            "retailerFaviconURL": null,
            "categoryTag": "shoes",
            "tags": ["trending", "summer"]
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let product = try decoder.decode(Product.self, from: data)

        // Then
        XCTAssertEqual(product.name, "Test Shoe")
        XCTAssertEqual(product.brandName, "Nike")
        XCTAssertEqual(product.category, .shoes)
        XCTAssertTrue(product.isOnSale)
    }

    // MARK: - Tests: Encoding

    func test_productEncoding() throws {
        // Given
        let product = createMockProduct()

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(product)
        let decoder = JSONDecoder()
        let decodedProduct = try decoder.decode(Product.self, from: data)

        // Then
        XCTAssertEqual(decodedProduct.id, product.id)
        XCTAssertEqual(decodedProduct.name, product.name)
        XCTAssertEqual(decodedProduct.category, product.category)
    }

    // MARK: - Tests: Pricing

    func test_salePriceCalculation() {
        // Given
        let originalPrice: Decimal = 100.00
        let currentPrice: Decimal = 75.00

        let product = Product(
            id: UUID(),
            externalId: "ext-123",
            retailerId: UUID(),
            brandId: UUID(),
            brandName: "Brand",
            name: "Product",
            description: nil,
            category: .clothing,
            subcategory: nil,
            currentPrice: currentPrice,
            originalPrice: originalPrice,
            currency: "USD",
            isOnSale: true,
            saleEndDate: nil,
            sizesAvailable: [],
            colors: [],
            materials: [],
            imageURLs: [],
            productURL: URL(string: "https://example.com")!,
            affiliateURL: nil,
            retailerName: "Retailer",
            retailerFaviconURL: nil,
            categoryTag: "tag",
            tags: []
        )

        // When
        let discount = product.discountPercentage

        // Then
        XCTAssertEqual(discount, 25)
    }

    // MARK: - Tests: Discount Percentage

    func test_discountPercentage() {
        // Given
        let product = Product(
            id: UUID(),
            externalId: "ext-456",
            retailerId: UUID(),
            brandId: UUID(),
            brandName: "Brand",
            name: "Product",
            description: nil,
            category: .bags,
            subcategory: nil,
            currentPrice: 60.00,
            originalPrice: 100.00,
            currency: "USD",
            isOnSale: true,
            saleEndDate: nil,
            sizesAvailable: [],
            colors: [],
            materials: [],
            imageURLs: [],
            productURL: URL(string: "https://example.com")!,
            affiliateURL: nil,
            retailerName: "Retailer",
            retailerFaviconURL: nil,
            categoryTag: "tag",
            tags: []
        )

        // When
        let discount = product.discountPercentage

        // Then
        XCTAssertEqual(discount, 40)
    }

    // MARK: - Tests: Category Parsing

    func test_categoryParsing() {
        // When & Then
        XCTAssertEqual(ProductCategory.clothing.displayName, "Clothing")
        XCTAssertEqual(ProductCategory.shoes.displayName, "Shoes")
        XCTAssertEqual(ProductCategory.bags.displayName, "Bags")
        XCTAssertEqual(ProductCategory.accessories.displayName, "Accessories")
    }

    // MARK: - Tests: Product Equality

    func test_productEquality() {
        // Given
        let id = UUID()
        let product1 = createMockProduct(id: id)
        let product2 = createMockProduct(id: id)

        // When & Then
        XCTAssertEqual(product1, product2)
    }

    // MARK: - Tests: Product Hashing

    func test_productHashing() {
        // Given
        let product1 = createMockProduct()
        let product2 = createMockProduct(id: product1.id)

        // When
        let set = Set([product1, product2])

        // Then
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Tests: Multiple Images

    func test_hasMultipleImages() {
        // Given
        let urls = [
            URL(string: "https://example.com/1.jpg")!,
            URL(string: "https://example.com/2.jpg")!
        ]

        let product = Product(
            id: UUID(),
            externalId: "ext-789",
            retailerId: UUID(),
            brandId: UUID(),
            brandName: "Brand",
            name: "Product",
            description: nil,
            category: .accessories,
            subcategory: nil,
            currentPrice: 50.00,
            originalPrice: nil,
            currency: "USD",
            isOnSale: false,
            saleEndDate: nil,
            sizesAvailable: [],
            colors: [],
            materials: [],
            imageURLs: urls,
            productURL: URL(string: "https://example.com")!,
            affiliateURL: nil,
            retailerName: "Retailer",
            retailerFaviconURL: nil,
            categoryTag: "tag",
            tags: []
        )

        // When
        let hasMultiple = product.hasMultipleImages

        // Then
        XCTAssertTrue(hasMultiple)
    }

    // MARK: - Tests: Primary Image

    func test_primaryImageURL() {
        // Given
        let primaryURL = URL(string: "https://example.com/primary.jpg")!
        let urls = [
            primaryURL,
            URL(string: "https://example.com/secondary.jpg")!
        ]

        let product = Product(
            id: UUID(),
            externalId: "ext-999",
            retailerId: UUID(),
            brandId: UUID(),
            brandName: "Brand",
            name: "Product",
            description: nil,
            category: .clothing,
            subcategory: nil,
            currentPrice: 80.00,
            originalPrice: nil,
            currency: "USD",
            isOnSale: false,
            saleEndDate: nil,
            sizesAvailable: [],
            colors: [],
            materials: [],
            imageURLs: urls,
            productURL: URL(string: "https://example.com")!,
            affiliateURL: nil,
            retailerName: "Retailer",
            retailerFaviconURL: nil,
            categoryTag: "tag",
            tags: []
        )

        // When
        let retrieved = product.primaryImageURL

        // Then
        XCTAssertEqual(retrieved, primaryURL)
    }

    // MARK: - Helper Methods

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
}
