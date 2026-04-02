import SwiftUI
import SafariServices

/// Detailed product view presented as a modal sheet when user taps a card.
struct ProductDetailSheet: View {
    let card: CardQueueItem
    @Environment(\.dismiss) var dismiss

    @State private var selectedImageIndex = 0
    @State private var showSafari = false
    @State private var safariURL: URL?
    @State private var expandedDescription = false
    @State private var isSaved = false

    var body: some View {
        ZStack {
            Color.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle bar
                VStack {
                    Capsule()
                        .fill(Color.textTertiary)
                        .frame(width: 40, height: 4)
                }
                .frame(height: 20)
                .frame(maxWidth: .infinity)

                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Image carousel
                        imageCarousel()

                        // Product info
                        productInfo()

                        // Sale intelligence
                        if card.product.isOnSale {
                            saleIntelligenceSection()
                        }

                        // Size availability
                        sizeAvailabilitySection()

                        // Description
                        descriptionSection()

                        // Similar items
                        similarItemsSection()

                        // Action buttons
                        actionButtonsSection()

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .sheet(isPresented: $showSafari) {
            if let url = safariURL {
                SafariView(url: url)
            }
        }
    }

    // MARK: - View Sections

    @ViewBuilder
    private func imageCarousel() -> some View {
        VStack(spacing: 12) {
            // Main image
            TabView(selection: $selectedImageIndex) {
                ForEach(Array(card.product.imageURLs.enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea()

                        case .empty:
                            ZStack {
                                Color.surfaceCard
                                ProgressView()
                                    .tint(.textSecondary)
                            }

                        case .failure:
                            ZStack {
                                Color.surfaceCard
                                Image(systemName: "photo")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(.textTertiary)
                            }

                        @unknown default:
                            Color.surfaceCard
                        }
                    }
                    .tag(index)
                }
            }
            .frame(height: 400)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .cornerRadius(16)

            // Page dots
            if card.product.imageURLs.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<card.product.imageURLs.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedImageIndex ? Color.brandAccent : Color.textTertiary)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func productInfo() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Brand + Product name
            Text(card.product.brandName)
                .font(.system(size: 22, weight: .semibold, design: .default))
                .foregroundColor(.textPrimary)

            Text(card.product.name)
                .font(.system(size: 17, weight: .regular, design: .default))
                .foregroundColor(.textSecondary)
                .lineLimit(3)

            // Pricing
            HStack(spacing: 12) {
                Text(formatPrice(card.product.currentPrice))
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.textPrimary)

                if let original = card.product.originalPrice, original != card.product.currentPrice {
                    Text(formatPrice(original))
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.textTertiary)
                        .strikethrough()
                }
            }
        }
    }

    @ViewBuilder
    private func saleIntelligenceSection() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.saleRed)

            VStack(alignment: .leading, spacing: 2) {
                Text("On sale now")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)

                if let saleEndDate = card.product.saleEndDate {
                    Text("Ends \(formattedDate(saleEndDate))")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.saleRed.opacity(0.1))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func sizeAvailabilitySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Size Availability")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(card.product.sizesAvailable, id: \.self) { size in
                        Text(size)
                            .font(.system(size: 13, weight: .medium))
                            .frame(minWidth: 44)
                            .frame(height: 44)
                            .background(Color.brandAccent.opacity(0.2))
                            .foregroundColor(.textPrimary)
                            .cornerRadius(6)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func descriptionSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)

            let maxChars = expandedDescription ? Int.max : 200
            let text = card.product.description ?? "No description available"
            let displayText = text.count > maxChars
                ? String(text.prefix(maxChars)) + "..."
                : text

            Text(displayText)
                .font(.system(size: 15, weight: .regular, design: .default))
                .foregroundColor(.textSecondary)
                .lineLimit(expandedDescription ? nil : 3)

            if let description = card.product.description, description.count > 200 {
                Button(action: { expandedDescription.toggle() }) {
                    Text(expandedDescription ? "Read less" : "Read more")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.brandAccent)
                }
            }
        }
    }

    @ViewBuilder
    private func similarItemsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Similar Items")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        AsyncImage(url: card.product.primaryImageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .cornerRadius(12)
                                    .clipped()

                            default:
                                ZStack {
                                    Color.surfaceCard
                                    Image(systemName: "photo")
                                        .foregroundColor(.textTertiary)
                                }
                                .frame(width: 120, height: 120)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actionButtonsSection() -> some View {
        VStack(spacing: 12) {
            // Shop This button
            Button(action: { shopProduct() }) {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Shop This")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.brandAccent)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Save to Dresser button
            Button(action: { isSaved.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))

                    Text(isSaved ? "Saved" : "Save to Dresser")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.surfaceCard)
                .foregroundColor(isSaved ? .saleRed : .textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.textTertiary.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Methods

    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = card.product.currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        if let formatted = formatter.string(from: price as NSDecimalNumber) {
            return formatted
        }
        return "$\(price)"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func shopProduct() {
        if let affiliateURL = card.product.affiliateURL {
            safariURL = affiliateURL
        } else {
            safariURL = card.product.productURL
        }
        showSafari = true
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(
        _ uiViewController: SFSafariViewController,
        context: UIViewControllerRepresentableContext<SafariView>
    ) {}
}

// MARK: - Preview

#Preview {
    let mockProduct = Product(
        id: UUID(),
        externalId: "ext-123",
        retailerId: UUID(),
        brandId: UUID(),
        brandName: "Gucci",
        name: "Silk Blouse in Emerald",
        description: "Luxurious silk blouse perfect for any occasion. Made from premium Italian silk with a relaxed fit and delicate pleating details. Perfect for layering or wearing alone.",
        category: .clothing,
        subcategory: "Blouses",
        currentPrice: 325,
        originalPrice: 465,
        currency: "USD",
        isOnSale: true,
        saleEndDate: Date().addingTimeInterval(86400 * 5),
        sizesAvailable: ["XS", "S", "M", "L", "XL"],
        colors: ["Emerald", "Ivory", "Black"],
        materials: ["100% Silk"],
        imageURLs: [
            URL(string: "https://images.unsplash.com/photo-1579208575757-c396eaff6ff2?w=500")!,
            URL(string: "https://images.unsplash.com/photo-1560707303-4e980ce876ad?w=500")!,
        ],
        productURL: URL(string: "https://example.com/product")!,
        affiliateURL: nil,
        retailerName: "SSENSE",
        retailerFaviconURL: nil,
        categoryTag: "clothing",
        tags: ["luxury", "silk", "blouse"]
    )

    let mockCard = CardQueueItem(
        product: mockProduct,
        queuePosition: 0,
        queueSize: 40
    )

    ProductDetailSheet(card: mockCard)
}
