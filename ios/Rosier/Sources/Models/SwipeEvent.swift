import Foundation
import UIKit

/// Represents a user swipe interaction event for analytics and recommendations.
public struct SwipeEvent: Codable {
    // MARK: - Event Metadata

    /// Unique identifier for this event.
    let id: UUID

    /// Timestamp when the event occurred.
    let timestamp: Date

    /// Type of swipe action performed.
    let action: SwipeAction

    // MARK: - Product Context

    /// ID of the swiped product.
    let productId: UUID

    /// External ID of the product at the source.
    let externalProductId: String

    /// ID of the brand associated with the product.
    let brandId: UUID

    /// Category of the product.
    let category: ProductCategory

    /// Tags associated with the product.
    let productTags: [String]

    // MARK: - Session Context

    /// Position of the product in the current session queue.
    let sessionPosition: Int

    /// Time spent viewing the product in milliseconds.
    let dwellTimeMs: Int

    /// Whether the product was viewed in expanded detail.
    let expanded: Bool

    // MARK: - Device Context

    /// Device model identifier (e.g., "iPhone15,2").
    let deviceModel: String

    /// Operating system version (e.g., "17.4").
    let osVersion: String

    /// Screen dimensions in points.
    let screenSize: CGSize

    /// Whether dark mode is enabled.
    let isDarkMode: Bool

    /// Network connectivity type.
    let networkType: NetworkType

    // MARK: - Initializers

    /// Creates a new swipe event.
    /// - Parameters:
    ///   - action: The swipe action performed
    ///   - productId: ID of the product
    ///   - externalProductId: External product ID
    ///   - brandId: Brand ID
    ///   - category: Product category
    ///   - productTags: Product tags
    ///   - sessionPosition: Position in queue
    ///   - dwellTimeMs: Time spent viewing in milliseconds
    ///   - expanded: Whether viewed in detail
    public init(
        action: SwipeAction,
        productId: UUID,
        externalProductId: String,
        brandId: UUID,
        category: ProductCategory,
        productTags: [String] = [],
        sessionPosition: Int,
        dwellTimeMs: Int,
        expanded: Bool = false
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
        self.productId = productId
        self.externalProductId = externalProductId
        self.brandId = brandId
        self.category = category
        self.productTags = productTags
        self.sessionPosition = sessionPosition
        self.dwellTimeMs = dwellTimeMs
        self.expanded = expanded

        // Device context
        self.deviceModel = UIDevice.current.model
        self.osVersion = UIDevice.current.systemVersion
        self.screenSize = UIScreen.main.bounds.size
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        self.networkType = NetworkType.current
    }
}

/// Enumeration of swipe actions.
public enum SwipeAction: String, Codable {
    case like
    case reject
    case superLike
    case undo
    case viewDetail
    case shopClick
}

/// Network connectivity types.
public enum NetworkType: String, Codable {
    case wifi
    case cellular
    case unknown

    /// Detects the current network type.
    static var current: NetworkType {
        // Simplified version - returns .wifi
        return .wifi
    }
}

// MARK: - Extension for Device Information

extension UIDevice {
    /// Machine identifier string (e.g., "iPhone15,2").
    var model: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
