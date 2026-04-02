import Foundation

/// Handles deep link routing for universal links and app schemes.
final class DeepLinkService {
    // MARK: - Singleton

    static let shared = DeepLinkService()

    // MARK: - Properties

    private var deepLinkHandler: ((DeepLink) -> Void)?

    // MARK: - Public Methods

    /// Registers a handler for deep link routing.
    func setHandler(_ handler: @escaping (DeepLink) -> Void) {
        self.deepLinkHandler = handler
    }

    /// Handles a URL and routes to appropriate destination.
    func handleURL(_ url: URL) -> DeepLink? {
        let deepLink = parseURL(url)
        deepLinkHandler?(deepLink)
        return deepLink
    }

    /// Handles a universal link URL.
    func handleUniversalLink(_ url: URL) -> DeepLink? {
        handleURL(url)
    }

    // MARK: - Private Methods

    /// Parses a URL into a DeepLink.
    private func parseURL(_ url: URL) -> DeepLink {
        // Handle rosier:// scheme
        if url.scheme == "rosier" {
            return parseRosierScheme(url)
        }

        // Handle https:// universal links
        if url.scheme == "https" || url.scheme == "http" {
            return parseUniversalLink(url)
        }

        return .unknown
    }

    /// Parses rosier:// scheme URLs.
    private func parseRosierScheme(_ url: URL) -> DeepLink {
        guard let host = url.host else {
            return .unknown
        }

        let path = url.pathComponents.dropFirst()
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch host {
        case "product":
            if let productId = path.first, let uuid = UUID(uuidString: productId) {
                return .product(id: uuid)
            }

        case "dresser":
            if let drawerId = path.first, let uuid = UUID(uuidString: drawerId) {
                return .dresser(id: uuid)
            }

        case "dna":
            return .styleDNA

        case "invite":
            if let code = query.first(where: { $0.name == "code" })?.value {
                return .invite(code: code)
            }

        case "sale":
            if let saleId = path.first, let uuid = UUID(uuidString: saleId) {
                return .sale(id: uuid)
            }

        default:
            return .unknown
        }

        return .unknown
    }

    /// Parses https:// universal links.
    private func parseUniversalLink(_ url: URL) -> DeepLink {
        guard let host = url.host else {
            return .unknown
        }

        let pathComponents = url.pathComponents.dropFirst()

        // rosier.app/product/[id]
        if host.contains("rosier.app") {
            if pathComponents.count >= 2 && pathComponents[0] == "product" {
                if let uuid = UUID(uuidString: pathComponents[1]) {
                    return .product(id: uuid)
                }
            }

            // rosier.app/dresser/[id]
            if pathComponents.count >= 2 && pathComponents[0] == "dresser" {
                if let uuid = UUID(uuidString: pathComponents[1]) {
                    return .dresser(id: uuid)
                }
            }

            // rosier.app/style-dna
            if pathComponents.count >= 1 && pathComponents[0] == "style-dna" {
                return .styleDNA
            }

            // rosier.app/invite/[code]
            if pathComponents.count >= 2 && pathComponents[0] == "invite" {
                return .invite(code: pathComponents[1])
            }

            // rosier.app/sale/[id]
            if pathComponents.count >= 2 && pathComponents[0] == "sale" {
                if let uuid = UUID(uuidString: pathComponents[1]) {
                    return .sale(id: uuid)
                }
            }
        }

        return .unknown
    }
}

// MARK: - DeepLink Enum

enum DeepLink: Equatable, Hashable {
    case product(id: UUID)
    case dresser(id: UUID)
    case styleDNA
    case invite(code: String)
    case sale(id: UUID)
    case dailyDrop
    case dresserSaleFilter(retailerId: UUID)
    case swipeFeed
    case unknown

    // MARK: - URL Generators

    /// Generates a rosier:// URL for this deep link.
    func rosierSchemeURL() -> URL? {
        switch self {
        case .product(let id):
            return URL(string: "rosier://product/\(id.uuidString)")
        case .dresser(let id):
            return URL(string: "rosier://dresser/\(id.uuidString)")
        case .styleDNA:
            return URL(string: "rosier://dna")
        case .invite(let code):
            return URL(string: "rosier://invite?code=\(code)")
        case .sale(let id):
            return URL(string: "rosier://sale/\(id.uuidString)")
        case .dailyDrop:
            return URL(string: "rosier://daily-drop")
        case .dresserSaleFilter(let retailerId):
            return URL(string: "rosier://dresser?retailer=\(retailerId.uuidString)")
        case .swipeFeed:
            return URL(string: "rosier://swipe")
        case .unknown:
            return nil
        }
    }

    /// Generates a universal HTTPS URL for this deep link.
    func universalURL(baseURL: String = "https://rosier.app") -> URL? {
        switch self {
        case .product(let id):
            return URL(string: "\(baseURL)/product/\(id.uuidString)")
        case .dresser(let id):
            return URL(string: "\(baseURL)/dresser/\(id.uuidString)")
        case .styleDNA:
            return URL(string: "\(baseURL)/style-dna")
        case .invite(let code):
            return URL(string: "\(baseURL)/invite/\(code)")
        case .sale(let id):
            return URL(string: "\(baseURL)/sale/\(id.uuidString)")
        case .dailyDrop:
            return URL(string: "\(baseURL)/daily-drop")
        case .dresserSaleFilter(let retailerId):
            return URL(string: "\(baseURL)/dresser?retailer=\(retailerId.uuidString)")
        case .swipeFeed:
            return URL(string: "\(baseURL)/swipe")
        case .unknown:
            return nil
        }
    }
}
