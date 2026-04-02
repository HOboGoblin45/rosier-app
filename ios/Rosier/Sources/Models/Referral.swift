import Foundation

/// Referral tier enum for reward tracking.
enum ReferralTier: String, Codable {
    case none = "none"
    case styleDna = "style_dna"
    case dailyDrop = "daily_drop"
    case foundingMember = "founding_member"
    case vipDresser = "vip_dresser"
    case ambassador = "ambassador"

    var displayName: String {
        switch self {
        case .none:
            return "No Tier"
        case .styleDna:
            return "Style DNA"
        case .dailyDrop:
            return "Daily Drop Early Access"
        case .foundingMember:
            return "Founding Member"
        case .vipDresser:
            return "VIP Dresser"
        case .ambassador:
            return "Brand Ambassador"
        }
    }

    var description: String {
        switch self {
        case .none:
            return "Invite your first friend to unlock rewards"
        case .styleDna:
            return "Unlock Style DNA shareable card"
        case .dailyDrop:
            return "Early access to Daily Drop (30 min before everyone else)"
        case .foundingMember:
            return "Founding Member badge + profile flair"
        case .vipDresser:
            return "VIP Dresser (unlimited drawers, priority notifications)"
        case .ambassador:
            return "Ambassador status (early brand access, exclusive content)"
        }
    }
}

/// User's referral code and stats.
struct ReferralCode: Codable {
    let code: String
    let totalReferrals: Int
    let successfulReferrals: Int
    let currentTier: ReferralTier
    let nextTier: ReferralTier?
    let referralsToNext: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case code
        case totalReferrals = "total_referrals"
        case successfulReferrals = "successful_referrals"
        case currentTier = "current_tier"
        case nextTier = "next_tier"
        case referralsToNext = "referrals_to_next"
        case createdAt = "created_at"
    }
}

/// User's referral statistics.
struct ReferralStats: Codable {
    let code: String
    let totalReferrals: Int
    let successfulReferrals: Int
    let currentTier: ReferralTier
    let nextTier: ReferralTier?
    let referralsToNext: Int

    enum CodingKeys: String, CodingKey {
        case code
        case totalReferrals = "total_referrals"
        case successfulReferrals = "successful_referrals"
        case currentTier = "current_tier"
        case nextTier = "next_tier"
        case referralsToNext = "referrals_to_next"
    }

    /// Progress to next tier as percentage (0-100).
    var progressToNextTier: Double {
        guard let nextTier = nextTier, referralsToNext > 0 else { return 0 }

        let thresholds: [ReferralTier: Int] = [
            .styleDna: 1,
            .dailyDrop: 3,
            .foundingMember: 5,
            .vipDresser: 10,
            .ambassador: 25,
        ]

        let nextThreshold = thresholds[nextTier] ?? 0
        let currentThreshold = thresholds[currentTier] ?? 0

        if nextThreshold <= currentThreshold {
            return 0
        }

        let progress = Double(successfulReferrals - currentThreshold) / Double(nextThreshold - currentThreshold)
        return max(0, min(1, progress)) * 100
    }
}

/// Leaderboard entry.
struct LeaderboardEntry: Codable {
    let rank: Int
    let userId: String
    let name: String
    let invites: Int
    let tier: ReferralTier

    enum CodingKeys: String, CodingKey {
        case rank
        case userId = "user_id"
        case name
        case invites
        case tier
    }

    var isTopThree: Bool {
        return rank <= 3
    }

    var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
}

/// Leaderboard response.
struct Leaderboard: Codable {
    let month: String?
    let leaderboard: [LeaderboardEntry]
    let yourRank: Int?
    let yourInvites: Int?

    enum CodingKeys: String, CodingKey {
        case month
        case leaderboard
        case yourRank = "your_rank"
        case yourInvites = "your_invites"
    }
}

/// Referral link for sharing.
struct ReferralLink: Codable {
    let code: String
    let link: String
    let qrCode: String?

    enum CodingKeys: String, CodingKey {
        case code
        case link
        case qrCode = "qr_code"
    }
}

/// Reward details.
struct ReferralReward: Codable {
    let id: String
    let userId: String
    let rewardType: String
    let milestoneCount: Int
    let grantedAt: Date
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case rewardType = "reward_type"
        case milestoneCount = "milestone_count"
        case grantedAt = "granted_at"
        case isActive = "is_active"
    }
}

/// Reward milestone information.
struct RewardMilestone: Codable {
    let milestone: Int
    let tier: ReferralTier
    let rewardType: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case milestone
        case tier
        case rewardType = "reward_type"
        case description
    }
}

/// Response containing all milestones.
struct MilestonesResponse: Codable {
    let milestones: [RewardMilestone]
    let description: String
}

/// Shareable Style DNA card with referral QR code.
struct StyleDNACard: Codable {
    let userId: String
    let archetype: String
    let topBrands: [String]
    let palette: [String]
    let referralCode: String
    let shareUrl: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case archetype
        case topBrands = "top_brands"
        case palette
        case referralCode = "referral_code"
        case shareUrl = "share_url"
        case imageUrl = "image_url"
    }
}

/// Referral code application request.
struct ApplyReferralCodeRequest: Codable {
    let code: String
    let source: String

    init(code: String, source: String = "link") {
        self.code = code
        self.source = source
    }
}

/// Share tracking request.
struct ShareTrackingRequest: Codable {
    let platform: String

    enum Platform: String {
        case imessage = "imessage"
        case whatsapp = "whatsapp"
        case instagram = "instagram"
        case email = "email"
        case link = "link"
        case other = "other"
    }
}
