import Foundation

/// User profile containing personal information, preferences, and settings.
public struct UserProfile: Identifiable, Codable, Hashable {
    // MARK: - Identifiers

    /// Unique user identifier.
    let id: UUID

    /// User's email address.
    let email: String?

    /// User's display name.
    let displayName: String?

    // MARK: - Authentication

    /// Apple ID if signed in via Apple Sign-In.
    let appleId: String?

    // MARK: - Profile Information

    /// User's profile picture URL.
    let profileImageURL: URL?

    /// Biographical description.
    let bio: String?

    /// User's age range preference for discovery filtering.
    let ageRange: AgeRange?

    /// User's location (country/region).
    let location: String?

    // MARK: - Preferences and Settings

    /// Style DNA representing the user's aesthetic.
    let styleDNA: StyleDNA?

    /// Quiz responses capturing user preferences.
    let quizResponses: QuizResponses?

    /// Preferred price ranges for different categories.
    let pricePreferences: PricePreferences

    /// Brands the user has marked as favorites.
    let favoriteBrands: [UUID]

    /// Brands the user wants to avoid.
    let blockedBrands: [UUID]

    /// Preferred product categories.
    let preferredCategories: [ProductCategory]

    // MARK: - Metadata

    /// Account creation date.
    let createdAt: Date

    /// Last profile update date.
    let updatedAt: Date

    /// Whether the user has completed initial onboarding.
    let hasCompletedOnboarding: Bool

    /// Whether the user has completed the style quiz.
    let hasCompletedStyleQuiz: Bool

    /// Whether the user has accepted push notifications.
    let pushNotificationsEnabled: Bool

    /// Whether the user has accepted email communications.
    let emailNotificationsEnabled: Bool

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Initializers

    /// Creates a new user profile.
    public init(
        id: UUID = UUID(),
        email: String? = nil,
        displayName: String? = nil,
        appleId: String? = nil,
        pricePreferences: PricePreferences = .default
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.appleId = appleId
        self.profileImageURL = nil
        self.bio = nil
        self.ageRange = nil
        self.location = nil
        self.styleDNA = nil
        self.quizResponses = nil
        self.pricePreferences = pricePreferences
        self.favoriteBrands = []
        self.blockedBrands = []
        self.preferredCategories = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.hasCompletedOnboarding = false
        self.hasCompletedStyleQuiz = false
        self.pushNotificationsEnabled = true
        self.emailNotificationsEnabled = true
    }
}

/// User's age range for personalization and compliance.
public enum AgeRange: String, Codable, CaseIterable {
    case range18To24 = "18-24"
    case range25To34 = "25-34"
    case range35To44 = "35-44"
    case range45To54 = "45-54"
    case range55Plus = "55+"

    var displayName: String {
        self.rawValue
    }
}

/// Style quiz responses capturing user fashion preferences.
public struct QuizResponses: Codable, Hashable {
    /// Preferred style archetypes.
    let styleArchetypes: [String]

    /// Color palette preferences.
    let colorPreferences: [String]

    /// Preferred fit styles (e.g., "fitted", "oversized", "relaxed").
    let fitPreferences: [String]

    /// Sustainability preferences.
    let sustainabilityFocus: Bool

    /// Local/independent brand preference.
    let preferIndependentBrands: Bool

    /// Answers to any additional quiz questions.
    let customResponses: [String: String]
}

/// Price range preferences for different product categories.
public struct PricePreferences: Codable, Hashable {
    /// Maximum price for clothing in cents.
    let clothingMaxCents: Int

    /// Maximum price for shoes in cents.
    let shoesMaxCents: Int

    /// Maximum price for bags in cents.
    let bagsMaxCents: Int

    /// Maximum price for accessories in cents.
    let accessoriesMaxCents: Int

    /// Whether to show sale items.
    let showSalesOnly: Bool

    static var `default`: PricePreferences {
        PricePreferences(
            clothingMaxCents: 50000, // $500
            shoesMaxCents: 40000,    // $400
            bagsMaxCents: 60000,     // $600
            accessoriesMaxCents: 20000, // $200
            showSalesOnly: false
        )
    }

    /// Gets the maximum price for a specific category.
    func maxPrice(for category: ProductCategory) -> Decimal {
        let cents = switch category {
        case .clothing:
            clothingMaxCents
        case .shoes:
            shoesMaxCents
        case .bags:
            bagsMaxCents
        case .accessories:
            accessoriesMaxCents
        }
        return Decimal(cents) / 100
    }
}
