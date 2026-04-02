import Foundation

/// Represents a fashion product from a retail partner.
struct Product: Identifiable, Codable, Hashable {
    // MARK: - Identifiers

    /// Unique identifier for this product in Rosier.
    let id: UUID

    /// External identifier from the retail source.
    let externalId: String

    /// Identifier of the retailer providing this product.
    let retailerId: UUID

    /// Identifier of the brand.
    let brandId: UUID

    /// Display name of the brand.
    let brandName: String

    // MARK: - Basic Information

    /// Product name/title.
    let name: String

    /// Detailed product description.
    let description: String?

    /// Primary product category.
    let category: ProductCategory

    /// Subcategory within the primary category (e.g., "denim" under "clothing").
    let subcategory: String?

    // MARK: - Pricing

    /// Current price in the specified currency.
    let currentPrice: Decimal

    /// Original price before any discounts.
    let originalPrice: Decimal?

    /// Currency code (e.g., "USD").
    let currency: String

    /// Whether the product is currently on sale.
    let isOnSale: Bool

    /// Date when the sale ends.
    let saleEndDate: Date?

    // MARK: - Variants

    /// Available sizes for this product.
    let sizesAvailable: [String]

    /// Available colors.
    let colors: [String]

    /// Materials used in this product.
    let materials: [String]

    // MARK: - Media and Links

    /// URLs to product images.
    let imageURLs: [URL]

    /// Direct link to the product on the retailer's site.
    let productURL: URL

    /// Affiliate link if applicable.
    let affiliateURL: URL?

    // MARK: - Retailer Information

    /// Display name of the retailer.
    let retailerName: String

    /// Favicon URL for the retailer.
    let retailerFaviconURL: URL?

    // MARK: - Tagging and Discovery

    /// Primary category tag for discovery.
    let categoryTag: String

    /// Additional tags for discovery and filtering.
    let tags: [String]

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    /// Discount percentage if on sale.
    var discountPercentage: Int? {
        guard let original = originalPrice, isOnSale, original > 0 else {
            return nil
        }
        let discount = ((original - currentPrice) / original) * 100
        return NSDecimalNumber(decimal: discount).rounding(accordingToBehavior: nil).intValue
    }

    /// Whether the product has multiple images.
    var hasMultipleImages: Bool {
        imageURLs.count > 1
    }

    /// Primary image URL.
    var primaryImageURL: URL? {
        imageURLs.first
    }
}

/// Product category enumeration.
enum ProductCategory: String, Codable, CaseIterable {
    case clothing
    case shoes
    case bags
    case accessories

    /// Localized display name for the category.
    var displayName: String {
        switch self {
        case .clothing:
            return "Clothing"
        case .shoes:
            return "Shoes"
        case .bags:
            return "Bags"
        case .accessories:
            return "Accessories"
        }
    }

    /// Emoji representation for quick visual identification.
    var emoji: String {
        switch self {
        case .clothing:
            return "👔"
        case .shoes:
            return "👠"
        case .bags:
            return "👜"
        case .accessories:
            return "⌚"
        }
    }
}
