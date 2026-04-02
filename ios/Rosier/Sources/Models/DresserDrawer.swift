import Foundation

/// Represents a user's virtual dresser drawer for saving and organizing fashion items.
public struct DresserDrawer: Identifiable, Codable, Hashable {
    // MARK: - Identifiers

    /// Unique identifier for the dresser drawer.
    let id: UUID

    /// ID of the user who owns this drawer.
    let userId: UUID

    // MARK: - Metadata

    /// Display name of the drawer.
    let name: String

    /// Optional description of the drawer's theme or purpose.
    let description: String?

    /// Creation date of the drawer.
    let createdAt: Date

    /// Last modification date.
    let updatedAt: Date

    // MARK: - Organization

    /// Unique color tag for visual identification.
    let colorTag: DresserColorTag

    /// Custom sorting order for drawers.
    let displayOrder: Int

    /// Whether this is the default/primary dresser.
    let isDefault: Bool

    // MARK: - Content

    /// Saved products in this drawer.
    var savedProducts: [SavedProduct] = []

    /// Number of items in the drawer.
    var itemCount: Int {
        savedProducts.count
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DresserDrawer, rhs: DresserDrawer) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Initializers

    /// Creates a new dresser drawer.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - userId: ID of the owner
    ///   - name: Display name
    ///   - description: Optional description
    ///   - colorTag: Color tag for visual identification
    ///   - displayOrder: Sorting order
    ///   - isDefault: Whether this is the default drawer
    public init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        description: String? = nil,
        colorTag: DresserColorTag = .blue,
        displayOrder: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.colorTag = colorTag
        self.displayOrder = displayOrder
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// A product saved to a dresser drawer.
public struct SavedProduct: Identifiable, Codable, Hashable {
    // MARK: - Identifiers

    /// Unique identifier for this saved product entry.
    let id: UUID

    /// ID of the saved dresser drawer.
    let drawerId: UUID

    /// ID of the actual product.
    let productId: UUID

    /// External product ID from the retailer.
    let externalProductId: String

    // MARK: - Product Information

    /// Product name snapshot.
    let productName: String

    /// Brand name snapshot.
    let brandName: String

    /// Current price snapshot.
    let currentPrice: Decimal

    /// Currency code.
    let currency: String

    /// Primary image URL snapshot.
    let imageURL: URL?

    /// Product category.
    let category: ProductCategory

    // MARK: - Metadata

    /// Date the product was saved.
    let savedAt: Date

    /// Notes or personal comments about the product.
    let notes: String?

    /// Desired size if applicable.
    let desiredSize: String?

    /// Whether this is marked as a priority/wishlist item.
    let isPriority: Bool

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SavedProduct, rhs: SavedProduct) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Initializers

    /// Creates a new saved product entry.
    /// - Parameters:
    ///   - drawerId: ID of the drawer
    ///   - product: Product to save
    ///   - notes: Optional notes
    ///   - desiredSize: Optional desired size
    ///   - isPriority: Whether marked as priority
    public init(
        drawerId: UUID,
        product: Product,
        notes: String? = nil,
        desiredSize: String? = nil,
        isPriority: Bool = false
    ) {
        self.id = UUID()
        self.drawerId = drawerId
        self.productId = product.id
        self.externalProductId = product.externalId
        self.productName = product.name
        self.brandName = product.brandName
        self.currentPrice = product.currentPrice
        self.currency = product.currency
        self.imageURL = product.primaryImageURL
        self.category = product.category
        self.savedAt = Date()
        self.notes = notes
        self.desiredSize = desiredSize
        self.isPriority = isPriority
    }
}

/// Color tags for visual organization of dresser drawers.
public enum DresserColorTag: String, Codable, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink
    case gray

    /// SwiftUI Color representation.
    var color: Color {
        switch self {
        case .red:
            return Color(UIColor.systemRed)
        case .orange:
            return Color(UIColor.systemOrange)
        case .yellow:
            return Color(UIColor.systemYellow)
        case .green:
            return Color(UIColor.systemGreen)
        case .blue:
            return Color(UIColor.systemBlue)
        case .purple:
            return Color(UIColor.systemPurple)
        case .pink:
            return Color(UIColor.systemPink)
        case .gray:
            return Color(UIColor.systemGray)
        }
    }

    /// Localized display name.
    var displayName: String {
        self.rawValue.capitalized
    }
}

import SwiftUI
