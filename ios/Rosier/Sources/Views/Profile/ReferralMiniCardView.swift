import SwiftUI

/// Compact referral card for embedding in profile or home screen.
/// Shows quick stats and action buttons.
struct ReferralMiniCardView: View {
    // MARK: - Properties

    let stats: ReferralStats
    let onTapFullView: () -> Void
    let onShare: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Referral Rewards")
                        .styleTitleMedium()
                        .foregroundColor(.textPrimary)

                    Text(stats.currentTier.displayName)
                        .styleCaption()
                        .foregroundColor(.brandAccent)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(stats.successfulReferrals)")
                        .styleTitleMedium()
                        .foregroundColor(.brandAccent)

                    Text("Referrals")
                        .styleMicro()
                        .foregroundColor(.textSecondary)
                }
            }

            // Progress Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.textTertiary.opacity(0.2))

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.brandAccent,
                                Color.brandAccent.opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, 250 * (stats.progressToNextTier / 100)))
            }
            .frame(height: 6)

            // Next Tier Info
            if let nextTier = stats.nextTier, stats.referralsToNext > 0 {
                HStack(spacing: 8) {
                    Text("\(stats.referralsToNext) more to unlock")
                        .styleMicro()
                        .foregroundColor(.textSecondary)

                    Text(nextTier.displayName)
                        .styleMicro()
                        .foregroundColor(.brandAccent)
                        .fontWeight(.semibold)

                    Spacer()
                }
            }

            // Action Buttons
            HStack(spacing: 10) {
                Button(action: onShare) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))

                        Text("Share")
                            .styleCaption()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundColor(.brandPrimary)
                    .background(Color.brandAccent)
                    .cornerRadius(8)
                }

                Button(action: onTapFullView) {
                    HStack(spacing: 6) {
                        Text("View All")
                            .styleCaption()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundColor(.brandAccent)
                    .background(Color.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.brandAccent, lineWidth: 1)
                    )
                }
            }
        }
        .padding(14)
        .background(Color.surfaceCard)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    let mockStats = ReferralStats(
        code: "ROSIE-ABC1",
        totalReferrals: 3,
        successfulReferrals: 3,
        currentTier: .dailyDrop,
        nextTier: .foundingMember,
        referralsToNext: 2
    )

    VStack(spacing: 20) {
        ReferralMiniCardView(
            stats: mockStats,
            onTapFullView: { print("Full view") },
            onShare: { print("Share") }
        )

        Spacer()
    }
    .padding(16)
    .background(Color.surfaceBackground)
}
