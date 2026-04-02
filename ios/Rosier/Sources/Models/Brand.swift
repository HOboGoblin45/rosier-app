import Foundation

/// Represents a fashion brand in the Rosier ecosystem.
struct Brand: Identifiable, Codable, Hashable {
    // MARK: - Identifiers

    /// Unique identifier for the brand.
    let id: UUID

    /// Display name of the brand.
    let name: String

    /// Brand tier classification.
    let tier: BrandTier

    // MARK: - Branding

    /// Brand logo URL.
    let logoURL: URL?

    /// Brand description or story.
    let description: String?

    /// Official website URL.
    let websiteURL: URL?

    // MARK: - Aesthetics and Discovery

    /// Brand aesthetic tags describing the brand's style.
    let aesthetics: [String]

    /// Countries where the brand originates or operates.
    let countries: [String]

    /// Whether this is a verified brand partner.
    let isVerified: Bool

    /// Average product rating (0-5).
    let averageRating: Double?

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Brand, rhs: Brand) -> Bool {
        lhs.id == rhs.id
    }
}

/// Brand tier classification for filtering and ranking.
enum BrandTier: String, Codable, CaseIterable {
    case emerging
    case established
    case luxury

    /// Localized display name for the tier.
    var displayName: String {
        switch self {
        case .emerging:
            return "Emerging"
        case .established:
            return "Established"
        case .luxury:
            return "Luxury"
        }
    }

    /// Relative pricing tier (for sorting and filtering).
    var priceMultiplier: Double {
        switch self {
        case .emerging:
            return 1.0
        case .established:
            return 1.5
        case .luxury:
            return 3.0
        }
    }
}
