import SwiftUI

/// Main referral dashboard showing code, stats, and reward tiers.
struct ReferralDashboardView: View {
    // MARK: - Properties

    @State private var viewModel = ReferralViewModel()
    @State private var copiedFeedback = false
    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    if viewModel.isLoading {
                        LoadingStateView()
                            .frame(maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else if let stats = viewModel.referralStats {
                        // Referral Code Card
                        ReferralCodeCardView(
                            code: viewModel.referralCode,
                            onCopy: handleCopyCode,
                            onShare: viewModel.showNativeShareSheet
                        )
                        .padding(.horizontal, 16)

                        // Progress Section
                        ReferralProgressSectionView(stats: stats)
                            .padding(.horizontal, 16)

                        // Reward Tiers
                        VStack(spacing: 12) {
                            Text("Reward Tiers")
                                .styleTitleMedium()
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)

                            VStack(spacing: 10) {
                                ReferralRewardCard(
                                    tier: .styleDna,
                                    referralsNeeded: 1,
                                    isUnlocked: stats.successfulReferrals >= 1
                                )

                                ReferralRewardCard(
                                    tier: .dailyDrop,
                                    referralsNeeded: 3,
                                    isUnlocked: stats.successfulReferrals >= 3
                                )

                                ReferralRewardCard(
                                    tier: .foundingMember,
                                    referralsNeeded: 5,
                                    isUnlocked: stats.successfulReferrals >= 5
                                )

                                ReferralRewardCard(
                                    tier: .vipDresser,
                                    referralsNeeded: 10,
                                    isUnlocked: stats.successfulReferrals >= 10
                                )

                                ReferralRewardCard(
                                    tier: .ambassador,
                                    referralsNeeded: 25,
                                    isUnlocked: stats.successfulReferrals >= 25
                                )
                            }
                            .padding(.horizontal, 16)
                        }

                        // Info Card
                        infoCard
                            .padding(.horizontal, 16)
                    }

                    Spacer()
                        .frame(height: 24)
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await viewModel.loadReferralData()
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.brandAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Referral Program")
                    .styleTitleMedium()
                    .foregroundColor(.textPrimary)

                Text("Invite friends and unlock rewards")
                    .styleCaption()
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.textTertiary)
            }
        }
    }

    private var infoCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.brandAccent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("How it works")
                        .styleTitleMedium()
                        .foregroundColor(.textPrimary)

                    Text("Share your unique code with friends. When they join using your code, you both get rewards.")
                        .styleCaption()
                        .foregroundColor(.textSecondary)
                        .lineLimit(3)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.brandAccent.opacity(0.08))
        .cornerRadius(12)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.saleRed)

            VStack(spacing: 8) {
                Text("Unable to Load Referrals")
                    .styleTitleMedium()
                    .foregroundColor(.textPrimary)

                Text(error)
                    .styleCaption()
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await viewModel.retry()
                }
            }) {
                Text("Try Again")
                    .styleBodyBold()
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.brandPrimary)
                    .background(Color.saleRed)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(24)
        .background(Color.surfaceCard)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.top, 40)
    }

    // MARK: - Actions

    private func handleCopyCode() {
        viewModel.copyCodeToClipboard()
        copiedFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copiedFeedback = false
        }
    }
}

// MARK: - Referral Code Card

struct ReferralCodeCardView: View {
    let code: String
    let onCopy: () -> Void
    let onShare: () -> Void

    @State private var showCopiedFeedback = false

    var body: some View {
        VStack(spacing: 16) {
            // Code Display
            VStack(spacing: 8) {
                Text("Your Referral Code")
                    .styleCaption()
                    .foregroundColor(.textSecondary)

                Text(code)
                    .styleDisplayMedium()
                    .foregroundColor(.brandAccent)
                    .tracking(4)
                    .selectableText()
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.brandPrimary.opacity(0.04))
            .cornerRadius(12)

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    onCopy()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCopiedFeedback = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCopiedFeedback = false
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16, weight: .semibold))

                        Text(showCopiedFeedback ? "Copied!" : "Copy")
                            .styleBodyBold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundColor(.brandPrimary)
                    .background(
                        showCopiedFeedback ? Color.successGreen : Color.brandAccent
                    )
                    .cornerRadius(10)
                }

                Button(action: onShare) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Share")
                            .styleBodyBold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundColor(.brandAccent)
                    .background(Color.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.brandAccent, lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .cornerRadius(16)
    }
}

// MARK: - Progress Section

struct ReferralProgressSectionView: View {
    let stats: ReferralStats

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Referrals")
                        .styleCaption()
                        .foregroundColor(.textSecondary)

                    HStack(spacing: 4) {
                        Text("\(stats.successfulReferrals)")
                            .styleTitleMedium()
                            .foregroundColor(.brandAccent)

                        if stats.nextTier != nil {
                            Text("of \(stats.referralsToNext + stats.successfulReferrals)")
                                .styleCaption()
                                .foregroundColor(.textTertiary)
                        }
                    }
                }

                Spacer()

                if let nextTier = stats.nextTier {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Next tier")
                            .styleCaption()
                            .foregroundColor(.textSecondary)

                        Text(nextTier.displayName)
                            .styleBodyBold()
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                    }
                }
            }

            // Progress Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.textTertiary.opacity(0.2))

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.brandAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(width: max(8, UIScreen.main.bounds.width * 0.7 * (stats.progressToNextTier / 100)))
            }
            .frame(height: 8)

            HStack(spacing: 4) {
                Text("\(Int(stats.progressToNextTier))%")
                    .styleMicro()
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("\(stats.referralsToNext) more to next tier")
                    .styleMicro()
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(14)
        .background(Color.surfaceCard)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.surfaceBackground
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                ReferralCodeCardView(
                    code: "ROSIE-ABC1",
                    onCopy: { print("Copied") },
                    onShare: { print("Share") }
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                let mockStats = ReferralStats(
                    code: "ROSIE-ABC1",
                    totalReferrals: 3,
                    successfulReferrals: 3,
                    currentTier: .dailyDrop,
                    nextTier: .foundingMember,
                    referralsToNext: 2
                )

                ReferralProgressSectionView(stats: mockStats)
                    .padding(.horizontal, 16)
            }
        }
    }
}
