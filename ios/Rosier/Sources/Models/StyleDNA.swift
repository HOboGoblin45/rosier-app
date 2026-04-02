import Foundation

/// User's computed style DNA based on quiz responses and swipe history.
public struct StyleDNA: Identifiable, Codable, Hashable {
    // MARK: - Identifiers

    /// Unique identifier for this style DNA.
    let id: UUID

    /// Associated user ID.
    let userId: UUID

    // MARK: - Archetype and Essence

    /// Primary style archetype (e.g., "minimalist", "romantic", "edgy").
    let archetype: String

    /// Secondary archetypes for nuance.
    let secondaryArchetypes: [String]

    /// Confidence score of the archetype (0-1).
    let archetypeConfidence: Double

    // MARK: - Brand Preferences

    /// Top brands aligned with user's style.
    let topBrands: [UUID]

    /// Brand tiers the user gravitates towards.
    let preferredBrandTiers: [BrandTier]

    // MARK: - Aesthetic Preferences

    /// Color palette preferences for the user's style.
    let palette: ColorPalette

    /// Texture and material preferences.
    let texturePreferences: [String]

    /// Silhouette preferences.
    let silhouettePreferences: [String]

    // MARK: - Price and Budget

    /// Preferred price range for items.
    let priceRange: PriceRange

    // MARK: - Stats and Confidence

    /// Statistics about the user's swipe history.
    let stats: StyleStats

    /// Overall confidence in this style DNA (0-1).
    let confidence: Double

    // MARK: - Metadata

    /// When this style DNA was created.
    let createdAt: Date

    /// When this style DNA was last updated.
    let updatedAt: Date

    /// Version number for compatibility.
    let version: Int

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StyleDNA, rhs: StyleDNA) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Initializers

    /// Creates a new style DNA.
    public init(
        userId: UUID,
        archetype: String,
        secondaryArchetypes: [String] = [],
        topBrands: [UUID] = [],
        preferredBrandTiers: [BrandTier] = [.established],
        palette: ColorPalette = .init(),
        texturePreferences: [String] = [],
        silhouettePreferences: [String] = [],
        priceRange: PriceRange = .moderate,
        stats: StyleStats = .init()
    ) {
        self.id = UUID()
        self.userId = userId
        self.archetype = archetype
        self.secondaryArchetypes = secondaryArchetypes
        self.archetypeConfidence = 0.8
        self.topBrands = topBrands
        self.preferredBrandTiers = preferredBrandTiers
        self.palette = palette
        self.texturePreferences = texturePreferences
        self.silhouettePreferences = silhouettePreferences
        self.priceRange = priceRange
        self.stats = stats
        self.confidence = 0.7
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = 1
    }
}

/// User's color palette preferences.
public struct ColorPalette: Codable, Hashable {
    /// Primary colors in the palette.
    let primaryColors: [String]

    /// Neutral colors (whites, grays, blacks).
    let neutrals: [String]

    /// Accent colors.
    let accents: [String]

    /// Whether the user prefers warm or cool tones.
    let tempPreference: TemperaturePreference

    public init(
        primaryColors: [String] = [],
        neutrals: [String] = ["black", "white", "gray"],
        accents: [String] = [],
        tempPreference: TemperaturePreference = .neutral
    ) {
        self.primaryColors = primaryColors
        self.neutrals = neutrals
        self.accents = accents
        self.tempPreference = tempPreference
    }
}

/// Color temperature preference.
public enum TemperaturePreference: String, Codable {
    case warm
    case cool
    case neutral
}

/// Price range preference bracket.
public enum PriceRange: String, Codable {
    case budget
    case moderate
    case premium
    case luxury

    /// Estimated price range in USD.
    var estimatedRangeUSD: ClosedRange<Int> {
        switch self {
        case .budget:
            return 0...100
        case .moderate:
            return 50...300
        case .premium:
            return 200...800
        case .luxury:
            return 500...5000
        }
    }
}

/// Statistics about user's swipe history and interactions.
public struct StyleStats: Codable, Hashable {
    /// Total number of swipes.
    let totalSwipes: Int

    /// Total likes.
    let totalLikes: Int

    /// Like rate (0-1).
    let likeRate: Double

    /// Total rejections.
    let totalRejects: Int

    /// Number of super likes.
    let totalSuperLikes: Int

    /// Average dwell time per card in milliseconds.
    let averageDwellTimeMs: Int

    /// Favorite categories by swipe count.
    let favoriteCategories: [ProductCategory: Int]

    /// Most engaged brands.
    let engagedBrands: [UUID: Int]

    public init(
        totalSwipes: Int = 0,
        totalLikes: Int = 0,
        likeRate: Double = 0.0,
        totalRejects: Int = 0,
        totalSuperLikes: Int = 0,
        averageDwellTimeMs: Int = 0,
        favoriteCategories: [ProductCategory: Int] = [:],
        engagedBrands: [UUID: Int] = [:]
    ) {
        self.totalSwipes = totalSwipes
        self.totalLikes = totalLikes
        self.likeRate = likeRate
        self.totalRejects = totalRejects
        self.totalSuperLikes = totalSuperLikes
        self.averageDwellTimeMs = averageDwellTimeMs
        self.favoriteCategories = favoriteCategories
        self.engagedBrands = engagedBrands
    }
}
