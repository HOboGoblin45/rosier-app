import SwiftUI

/// Individual product card view with image, pricing, and sale information.
struct ProductCardView: View {
    let card: CardQueueItem
    let onTap: () -> Void

    @State private var imagePhase: AsyncImagePhase = .empty

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Color.surfaceCard
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Product Image Section (70% of card height)
                ZStack(alignment: .topLeading) {
                    // Image
                    imageContent()
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.5)
                        .clipped()

                    // Sale Badge (if applicable)
                    if card.product.isOnSale, let discount = card.product.discountPercentage {
                        VStack(alignment: .leading) {
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("\(discount)% OFF")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.saleRed)
                            .cornerRadius(4)
                            .padding(12)
                        }
                    }

                    // Retailer Badge (bottom-left, frosted glass)
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            if let faviconURL = card.product.retailerFaviconURL {
                                AsyncImage(url: faviconURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 16, height: 16)
                                    default:
                                        Circle()
                                            .fill(Color.textSecondary)
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.textSecondary)
                                    .frame(width: 16, height: 16)
                            }

                            Text(card.product.retailerName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Color.white.opacity(0.2)
                                .blur(radius: 10)
                                .background(Color.white.opacity(0.1))
                        )
                        .cornerRadius(8)
                        .padding(12)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottomLeading)
                }

                // Content Section
                VStack(alignment: .leading, spacing: 8) {
                    // Brand Name
                    Text(card.product.brandName)
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    // Product Name
                    Text(card.product.name)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)

                    // Pricing
                    HStack(spacing: 8) {
                        // Current Price
                        Text(formatPrice(card.product.currentPrice))
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.textPrimary)

                        // Original Price (if exists and on sale)
                        if let original = card.product.originalPrice, original != card.product.currentPrice {
                            Text(formatPrice(original))
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.textTertiary)
                                .strikethrough()
                        }
                    }

                    // Category Pill
                    HStack(spacing: 0) {
                        Image(systemName: card.product.category.emoji)
                        Text(card.product.category.displayName)
                    }
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.textTertiary.opacity(0.1))
                    .cornerRadius(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.7)
        .cornerRadius(20)
        .clipped()
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .task {
            await loadImage()
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func imageContent() -> some View {
        switch imagePhase {
        case .empty:
            ZStack {
                Color.surfaceBackground
                    .opacity(0.5)
                ProgressView()
                    .tint(.textSecondary)
            }

        case .success(let image):
            image
                .resizable()
                .scaledToFill()

        case .failure:
            ZStack {
                Color.surfaceBackground
                    .opacity(0.5)
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.textTertiary)
                    Text("Unable to load image")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textTertiary)
                }
            }

        @unknown default:
            ZStack {
                Color.surfaceBackground
                    .opacity(0.5)
            }
        }
    }

    // MARK: - Private Methods

    private func loadImage() async {
        guard let primaryURL = card.product.primaryImageURL else {
            imagePhase = .failure(NSError(domain: "ProductCard", code: -1))
            return
        }

        do {
            if let uiImage = await ImageCacheService.shared.loadImage(from: primaryURL) {
                imagePhase = .success(Image(uiImage: uiImage))
            } else {
                imagePhase = .failure(NSError(domain: "ProductCard", code: -2))
            }
        } catch {
            imagePhase = .failure(error)
        }
    }

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
        description: "Luxurious silk blouse perfect for any occasion",
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
        imageURLs: [URL(string: "https://images.unsplash.com/photo-1579208575757-c396eaff6ff2?w=500")!],
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

    ProductCardView(card: mockCard) {}
        .padding(32)
        .frame(maxHeight: .infinity)
        .background(Color.surfaceBackground)
}
