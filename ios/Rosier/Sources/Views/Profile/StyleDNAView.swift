import SwiftUI

/// Full-screen, beautif dedicated Style DNA experience with viral sharing mechanics.
/// Shows user's archetype, brands, color palette, and stats in an Instagram Story-sized card.
struct StyleDNAView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    @State private var isShowingShareSheet = false
    @State private var showArchetypeInfo = false
    @State private var selectedArchetype: String?
    @State private var generatedImage: UIImage?
    @State private var isGeneratingImage = false

    private let storyCardSize = CGSize(width: 1080, height: 1920)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.brandAccent)
                                .frame(width: 44, height: 44)
                        }

                        Text("Your Style DNA")
                            .styleTitleMedium()
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Button(action: {
                            Task {
                                await viewModel.loadStyleDNA()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.brandAccent)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()

                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Main card - Instagram Story simulation
                            styleCard()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)

                            // Share buttons
                            VStack(spacing: 12) {
                                // Share to Stories button
                                Button(action: shareToInstagramStories) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.fill.on.square")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Share to Stories")
                                            .styleBodyBold()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .foregroundColor(.brandPrimary)
                                    .background(Color.brandAccent)
                                    .cornerRadius(12)
                                }

                                // Share via Activity button
                                Button(action: {
                                    isShowingShareSheet = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Share")
                                            .styleBodyBold()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .foregroundColor(.brandAccent)
                                    .background(Color.surfaceCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.brandAccent, lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }

                                // Copy text button
                                Button(action: copyShareText) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Copy Text")
                                            .styleBodyBold()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .foregroundColor(.textSecondary)
                                    .background(Color.surfaceCard)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 16)

                            // Info section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About Your Style DNA")
                                    .styleTitleMedium()
                                    .foregroundColor(.textPrimary)

                                VStack(alignment: .leading, spacing: 12) {
                                    if let archetype = viewModel.styleDNA?.archetype {
                                        infoRow(
                                            icon: "sparkles",
                                            label: "Archetype",
                                            value: archetype,
                                            onTap: {
                                                selectedArchetype = archetype
                                                showArchetypeInfo = true
                                            }
                                        )
                                    }

                                    if let stats = viewModel.styleDNA?.stats {
                                        infoRow(
                                            icon: "hand.thumbsup.fill",
                                            label: "Swipes",
                                            value: "\(stats.totalSwipes)"
                                        )

                                        infoRow(
                                            icon: "heart.fill",
                                            label: "Saves",
                                            value: "\(stats.totalLikes)"
                                        )
                                    }

                                    if !viewModel.mostSavedCategory.isEmpty {
                                        infoRow(
                                            icon: "bookmark.fill",
                                            label: "Top Category",
                                            value: viewModel.mostSavedCategory
                                        )
                                    }
                                }
                                .padding(12)
                                .background(Color.surfaceCard)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)

                            Spacer()
                                .frame(height: 12)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let image = generatedImage ?? viewModel.generateStyleDNAImage() {
                    let shareText = "Check out my Style DNA on Rosier! Discover your unique style profile. Download Rosier today. rosier.app"

                    ActivityViewController(
                        activityItems: [image, shareText]
                    )
                }
            }
            .sheet(isPresented: $showArchetypeInfo) {
                if let archetype = selectedArchetype {
                    archetypeInfoSheet(for: archetype)
                }
            }
            .onAppear {
                generatedImage = viewModel.generateStyleDNAImage()
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private func styleCard() -> some View {
        ZStack(alignment: .topLeading) {
            // Solid background color (replaced gradient)
            Color.brandPrimary.opacity(0.85)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR STYLE DNA")
                        .styleDisplayMedium()
                        .foregroundColor(.white)
                        .tracking(1)

                    // Archetype pill
                    if let archetype = viewModel.styleDNA?.archetype {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.brandAccent)
                                .frame(width: 6, height: 6)

                            Text(archetype)
                                .styleBodyBold()
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                    }
                }

                Spacer()

                // Top brands section
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOP BRANDS")
                        .styleMicro()
                        .foregroundColor(.white.opacity(0.7))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lemaire · Khaite · The Row")
                            .styleBodyBold()
                            .foregroundColor(.white)

                        Text("Baserange · Sandy Liang")
                            .styleBody()
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                // Color palette section
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR PALETTE")
                        .styleMicro()
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.saleRed)
                            .frame(width: 40, height: 40)

                        Circle()
                            .fill(Color.brandAccent)
                            .frame(width: 40, height: 40)

                        Circle()
                            .fill(Color.successGreen)
                            .frame(width: 40, height: 40)

                        Circle()
                            .fill(Color.textSecondary)
                            .frame(width: 40, height: 40)

                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 40, height: 40)
                    }
                }

                // Price sweet spot
                VStack(alignment: .leading, spacing: 4) {
                    Text("PRICE SWEET SPOT")
                        .styleMicro()
                        .foregroundColor(.white.opacity(0.7))

                    if let priceRange = viewModel.styleDNA?.priceRange.estimatedRangeUSD {
                        Text("$\(priceRange.lowerBound) – $\(priceRange.upperBound)")
                            .styleDisplayMedium()
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Stats grid
                if let stats = viewModel.styleDNA?.stats {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            statBox(
                                number: "\(stats.totalSwipes)",
                                label: "swipes"
                            )

                            statBox(
                                number: "\(stats.totalLikes)",
                                label: "saves"
                            )
                        }

                        HStack(spacing: 8) {
                            statBox(
                                number: viewModel.mostSavedCategory.split(separator: " ").first.map(String.init) ?? "–",
                                label: viewModel.mostSavedCategory.contains("%") ? "of saves" : "top pick"
                            )

                            statBox(
                                number: viewModel.mostSavedCategory.contains("%") ? viewModel.mostSavedCategory.split(separator: " ").last.map(String.init) ?? "–" : "–",
                                label: viewModel.mostSavedCategory.contains("%") ? "" : "–"
                            )
                        }
                    }
                }

                Spacer()
                    .frame(height: 12)

                // Footer
                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.brandAccent)

                    Text("Discover your style at")
                        .styleCaption()
                        .foregroundColor(.white.opacity(0.8))

                    Text("rosier.app")
                        .styleBodyBold()
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private func statBox(number: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(number)
                .styleBodyBold()
                .foregroundColor(.white)

            Text(label)
                .styleMicro()
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func infoRow(
        icon: String,
        label: String,
        value: String,
        onTap: (() -> Void)? = nil
    ) -> some View {
        if let onTap = onTap {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.brandAccent)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .styleMicro()
                            .foregroundColor(.textSecondary)

                        Text(value)
                            .styleBody()
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.brandAccent)
                }
            }
        } else {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brandAccent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .styleMicro()
                        .foregroundColor(.textSecondary)

                    Text(value)
                        .styleBody()
                        .foregroundColor(.textPrimary)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func archetypeInfoSheet(for archetype: String) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.brandAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(archetype)
                                .styleTitleMedium()
                                .foregroundColor(.textPrimary)

                            Text("Your unique style profile")
                                .styleCaption()
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(Color.surfaceCard)
                    .cornerRadius(12)

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What it means")
                            .styleTitleMedium()
                            .foregroundColor(.textPrimary)

                        Text(archetypeDescription(for: archetype))
                            .styleBody()
                            .foregroundColor(.textSecondary)
                            .lineSpacing(1.5)
                    }
                    .padding(16)
                    .background(Color.surfaceCard)
                    .cornerRadius(12)

                    // Key traits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your style traits")
                            .styleTitleMedium()
                            .foregroundColor(.textPrimary)

                        VStack(alignment: .leading, spacing: 8) {
                            traitItem("Sophisticated minimalism with a modern edge")
                            traitItem("Quality over quantity")
                            traitItem("Investment pieces in neutral palettes")
                            traitItem("Subtle details and craftsmanship")
                        }
                    }
                    .padding(16)
                    .background(Color.surfaceCard)
                    .cornerRadius(12)
                }
                .padding(16)
            }
            .navigationTitle("About Your Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showArchetypeInfo = false }
                        .font(Typography.bodyBold)
                        .foregroundColor(.brandAccent)
                }
            }
        }
    }

    @ViewBuilder
    private func traitItem(_ text: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.brandAccent)
                .frame(width: 6, height: 6)

            Text(text)
                .styleCaption()
                .foregroundColor(.textPrimary)
        }
    }

    // MARK: - Helper Methods

    private func archetypeDescription(for archetype: String) -> String {
        switch archetype.lowercased() {
        case let s where s.contains("minimalist"):
            return "You appreciate clean lines, neutral palettes, and timeless pieces. Your style philosophy is 'less is more,' focusing on quality basics and architectural silhouettes that work across multiple outfits."

        case let s where s.contains("romantic"):
            return "You embrace femininity through delicate fabrics, soft colors, and vintage-inspired details. Your aesthetic celebrates elegance with ruffles, lace, and romantic silhouettes."

        case let s where s.contains("edgy"):
            return "You push boundaries with bold colors, unexpected textures, and statement pieces. Your style is confident and individual, often featuring leather, metallics, and avant-garde designs."

        default:
            return "Your unique style reflects a blend of influences and personal preferences. Keep exploring and swiping to refine your style DNA."
        }
    }

    private func shareToInstagramStories() {
        guard let image = generatedImage ?? viewModel.generateStyleDNAImage(),
              let data = image.pngData(),
              let base64 = data.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return
        }

        let urlScheme = "instagram-stories://share?backgroundImage=\(base64)"

        if let url = URL(string: urlScheme) {
            UIApplication.shared.open(url)
        }
    }

    private func copyShareText() {
        let text = """
        Check out my Style DNA on Rosier!

        Archetype: \(viewModel.styleDNA?.archetype ?? "Unknown")
        Swipes: \(viewModel.styleDNA?.stats.totalSwipes ?? 0)
        Saves: \(viewModel.styleDNA?.stats.totalLikes ?? 0)

        Discover your unique style profile at rosier.app
        """

        UIPasteboard.general.string = text
    }
}

// MARK: - Activity View Controller

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    @State var viewModel = ProfileViewModel()
    return StyleDNAView(viewModel: viewModel)
        .preferredColorScheme(.light)
}
