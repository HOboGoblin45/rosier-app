import SwiftUI

/// Main swipe interface view containing the card stack, dresser icon, and controls.
struct SwipeView: View {
    @State private var viewModel: SwipeViewModel
    @State private var showDetailSheet = false
    @State private var detailCard: CardQueueItem?

    @Environment(\.safeAreaInsets) var safeAreaInsets

    init(viewModel: SwipeViewModel = SwipeViewModel()) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Background
            Color.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Offline banner
                if viewModel.isOffline {
                    offlineBanner()
                }

                // Main content
                ZStack {
                    // Card stack
                    CardStackView(
                        currentCard: viewModel.currentCard,
                        nextCard: viewModel.nextCard,
                        thirdCard: viewModel.thirdCard,
                        onSwipeLeft: {
                            viewModel.handleSwipe(.reject)
                        },
                        onSwipeRight: {
                            viewModel.handleSwipe(.like)
                        },
                        onSwipeUp: {
                            viewModel.handleSwipe(.superLike)
                        },
                        onSwipeDown: {
                            viewModel.undo()
                        },
                        onTap: {
                            detailCard = viewModel.currentCard
                            showDetailSheet = true
                            viewModel.handleViewDetail()
                        },
                        dresserPosition: dresserIconPosition()
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.7)
                    .padding(.horizontal, 32)

                    // Undo button (top-right)
                    VStack {
                        HStack {
                            Spacer()

                            Button(action: { viewModel.undo() }) {
                                Image(systemName: "arrow.uturn.left.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.brandAccent)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Circle())
                            }
                            .padding(.top, 16)
                            .padding(.right, 20)
                        }

                        Spacer()
                    }
                }

                Spacer()

                // Dresser icon at bottom center
                dresserIcon()
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            if let card = detailCard {
                ProductDetailSheet(card: card)
                    .presentationDetents([.large])
            }
        }
        .task {
            await viewModel.initializeSwipeView()
        }
        .onAppear {
            viewModel.startDwellTracking()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private func offlineBanner() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))

            Text("No internet connection")
                .font(.system(size: 14, weight: .medium))

            Spacer()
        }
        .foregroundColor(.white)
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(Color.destructiveRed)
    }

    @ViewBuilder
    private func dresserIcon() -> some View {
        ZStack(alignment: .topTrailing) {
            // Dresser icon button
            Button(action: {}) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.brandAccent)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }

            // Badge showing new items
            if viewModel.newItemsCount > 0 {
                ZStack {
                    Circle()
                        .fill(Color.saleRed)

                    Text("\(viewModel.newItemsCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 24, height: 24)
                .offset(x: 6, y: -6)
            }
        }
        .frame(height: 44 + 24) // Icon + safe area
        .padding(.bottom, max(safeAreaInsets.bottom, 24))
    }

    // MARK: - Helper Methods

    private func dresserIconPosition() -> CGPoint {
        let dresserIconSize: CGFloat = 44
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height - (safeAreaInsets.bottom + 44 / 2 + 24)

        return CGPoint(x: centerX, y: centerY)
    }
}

// MARK: - SafeAreaInsets Environment

struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = .init()
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

extension View {
    func safeAreaInsets(_ insets: EdgeInsets) -> some View {
        environment(\.safeAreaInsets, insets)
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
        description: "Luxurious silk blouse",
        category: .clothing,
        subcategory: "Blouses",
        currentPrice: 325,
        originalPrice: 465,
        currency: "USD",
        isOnSale: true,
        saleEndDate: Date().addingTimeInterval(86400 * 5),
        sizesAvailable: ["XS", "S", "M", "L", "XL"],
        colors: ["Emerald"],
        materials: ["Silk"],
        imageURLs: [URL(string: "https://images.unsplash.com/photo-1579208575757-c396eaff6ff2?w=500")!],
        productURL: URL(string: "https://example.com")!,
        affiliateURL: nil,
        retailerName: "SSENSE",
        retailerFaviconURL: nil,
        categoryTag: "clothing",
        tags: ["luxury"]
    )

    let mockCard = CardQueueItem(product: mockProduct, queuePosition: 0, queueSize: 40)

    SwipeView()
}
