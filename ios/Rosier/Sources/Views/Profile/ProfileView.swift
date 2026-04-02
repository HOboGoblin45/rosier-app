import SwiftUI

/// User profile tab showing profile info and style DNA.
struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel

    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Profile")
                            .styleTitleLarge()
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()

                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // User info section
                            if let profile = viewModel.userProfile {
                                VStack(spacing: 16) {
                                    // Avatar placeholder
                                    Circle()
                                        .fill(Color.brandAccent.opacity(0.1))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Text(String(profile.displayName?.prefix(1) ?? "U").uppercased())
                                                .font(.system(size: 32, weight: .semibold))
                                                .foregroundColor(.brandAccent)
                                        )

                                    VStack(spacing: 4) {
                                        Text(profile.displayName ?? "User")
                                            .styleTitleMedium()
                                            .foregroundColor(.textPrimary)

                                        Text(profile.email ?? "No email")
                                            .font(Typography.caption)
                                            .foregroundColor(.textSecondary)
                                    }

                                    // Stats
                                    HStack(spacing: 0) {
                                        VStack(spacing: 4) {
                                            Text("\(viewModel.totalSwipes)")
                                                .font(Typography.titleMedium)
                                                .foregroundColor(.textPrimary)

                                            Text("Swipes")
                                                .font(Typography.caption)
                                                .foregroundColor(.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)

                                        Divider()

                                        VStack(spacing: 4) {
                                            Text("\(viewModel.totalSaves)")
                                                .font(Typography.titleMedium)
                                                .foregroundColor(.textPrimary)

                                            Text("Saved")
                                                .font(Typography.caption)
                                                .foregroundColor(.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)

                                        Divider()

                                        VStack(spacing: 4) {
                                            Text(viewModel.memberSinceDate)
                                                .font(Typography.caption)
                                                .foregroundColor(.textPrimary)

                                            Text("Member Since")
                                                .font(Typography.caption)
                                                .foregroundColor(.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .padding(16)
                                    .background(Color.surfaceCard)
                                    .cornerRadius(12)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.surfaceCard)
                                .cornerRadius(12)
                            }

                            // Style DNA section
                            if viewModel.hasStyleDNA {
                                StyleDNACardView(viewModel: viewModel)
                                    .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundColor(.textTertiary)

                                    Text("Unlock Your Style DNA")
                                        .font(Typography.bodyBold)
                                        .foregroundColor(.textPrimary)

                                    Text("Swipe 100+ items to discover your unique style profile")
                                        .font(Typography.caption)
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.center)

                                    HStack(spacing: 0) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Keep swiping")
                                            .font(Typography.caption)
                                    }
                                    .foregroundColor(.brandAccent)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(20)
                                .background(Color.surfaceCard)
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                            }

                            Spacer()
                                .frame(height: 8)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .task {
                await viewModel.loadProfile()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Style DNA Card View

struct StyleDNACardView: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    // Title
                    VStack(spacing: 4) {
                        Text("Your Style DNA")
                            .font(Typography.titleMedium)
                            .foregroundColor(.textPrimary)

                        Text("Your unique style archetype")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }

                    // Archetype
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text(viewModel.archetypeName)
                            .font(Typography.body)
                    }
                    .foregroundColor(.brandAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Top brands
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Brands")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)

                    HStack(spacing: 8) {
                        ForEach(0..<min(3, viewModel.styleDNA?.topBrands.count ?? 0), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.surfaceBackground)
                                .frame(height: 32)
                        }

                        if (viewModel.styleDNA?.topBrands.count ?? 0) > 3 {
                            Text("+\(viewModel.styleDNA?.topBrands.count ?? 0 - 3)")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()
                    }
                }

                Divider()

                // Color palette
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Palette")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.saleRed)
                            .frame(width: 28, height: 28)

                        Circle()
                            .fill(Color.brandAccent)
                            .frame(width: 28, height: 28)

                        Circle()
                            .fill(Color.successGreen)
                            .frame(width: 28, height: 28)

                        Circle()
                            .fill(Color.textSecondary)
                            .frame(width: 28, height: 28)

                        Circle()
                            .fill(Color.surfaceCard)
                            .stroke(Color.textTertiary.opacity(0.2), lineWidth: 1)
                            .frame(width: 28, height: 28)

                        Spacer()
                    }
                }

                Divider()

                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stats")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Price Sweet Spot: $\(viewModel.styleDNA?.priceRange.estimatedRangeUSD.lowerBound ?? 0) – $\(viewModel.styleDNA?.priceRange.estimatedRangeUSD.upperBound ?? 0)")
                            .font(Typography.caption)
                            .foregroundColor(.textPrimary)

                        Text("Most Saved: \(viewModel.mostSavedCategory)")
                            .font(Typography.caption)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .padding(16)
            .background(Color.surfaceBackground.opacity(0.5))
            .cornerRadius(8)

            // Share button
            Button(action: { viewModel.shareStyleDNA() }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Share Your Style DNA")
                        .font(Typography.bodyBold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.brandAccent)
                .foregroundColor(.brandPrimary)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    @State var viewModel = ProfileViewModel()
    return ProfileView(viewModel: viewModel)
        .preferredColorScheme(.light)
}
