import SwiftUI

/// Reusable component displaying a single reward tier.
struct ReferralRewardCard: View {
    // MARK: - Properties

    let tier: ReferralTier
    let referralsNeeded: Int
    let isUnlocked: Bool

    // MARK: - State

    @State private var scaleEffect: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isUnlocked
                        ? Color.brandAccent.opacity(0.12)
                        : Color.textTertiary.opacity(0.08)
                )

            // Border
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isUnlocked
                        ? Color.brandAccent.opacity(0.3)
                        : Color.textTertiary.opacity(0.1),
                    lineWidth: 1.5
                )

            HStack(spacing: 14) {
                // Tier Badge
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(
                                isUnlocked
                                    ? Color.brandAccent
                                    : Color.textTertiary.opacity(0.3)
                            )

                        Image(systemName: tierIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(
                                isUnlocked ? Color.brandPrimary : Color.textTertiary
                            )
                    }
                    .frame(width: 54, height: 54)

                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.successGreen)
                            .offset(y: -8)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tier.displayName)
                                .styleBodyBold()
                                .foregroundColor(
                                    isUnlocked ? .textPrimary : .textSecondary
                                )

                            Text(tier.description)
                                .styleCaption()
                                .foregroundColor(.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer()
                    }

                    // Milestone Badge
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 12, weight: .semibold))

                        Text("\(referralsNeeded) \(referralsNeeded == 1 ? "referral" : "referrals")")
                            .styleMicro()
                    }
                    .foregroundColor(
                        isUnlocked ? Color.brandAccent : Color.textTertiary
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        isUnlocked
                            ? Color.brandAccent.opacity(0.12)
                            : Color.textTertiary.opacity(0.08)
                    )
                    .cornerRadius(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding(12)
        }
        .frame(minHeight: 100)
        .scaleEffect(scaleEffect)
        .onAppear {
            if isUnlocked {
                withAnimation(Animations.cardSpring) {
                    scaleEffect = 1.0
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var tierIcon: String {
        switch tier {
        case .none:
            return "sparkles"
        case .styleDna:
            return "sparkles"
        case .dailyDrop:
            return "calendar"
        case .foundingMember:
            return "crown.fill"
        case .vipDresser:
            return "star.fill"
        case .ambassador:
            return "megaphone.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        ReferralRewardCard(
            tier: .styleDna,
            referralsNeeded: 1,
            isUnlocked: true
        )

        ReferralRewardCard(
            tier: .dailyDrop,
            referralsNeeded: 3,
            isUnlocked: true
        )

        ReferralRewardCard(
            tier: .foundingMember,
            referralsNeeded: 5,
            isUnlocked: false
        )

        ReferralRewardCard(
            tier: .vipDresser,
            referralsNeeded: 10,
            isUnlocked: false
        )

        ReferralRewardCard(
            tier: .ambassador,
            referralsNeeded: 25,
            isUnlocked: false
        )

        Spacer()
    }
    .padding(16)
    .background(Color.surfaceBackground)
    .preferredColorScheme(.light)
}
