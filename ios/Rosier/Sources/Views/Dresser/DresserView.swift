import SwiftUI


/// Full-screen dresser modal with drawer management and item grid.
struct DresserView: View {
    @Bindable var viewModel: DresserViewModel
    @Environment(\.dismiss) var dismiss

    @State private var isCreatingDrawer = false
    @State private var newDrawerName = ""
    @State private var newDrawerColor = DresserColorTag.blue

    var body: some View {
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(.brandAccent)
                        .frame(height: 44)
                    }

                    Spacer()

                    Text("My Dresser")
                        .styleTitleMedium()
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Button(action: { viewModel.toggleEditMode() }) {
                        Text(viewModel.isEditMode ? "Done" : "Edit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.brandAccent)
                            .frame(height: 44)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                // Drawer list with collapsible sections
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.drawers) { drawer in
                            DrawerSectionView(
                                drawer: drawer,
                                isEditMode: viewModel.isEditMode,
                                viewModel: viewModel,
                                onDelete: {
                                    Task {
                                        await viewModel.deleteDrawer(drawer)
                                    }
                                },
                                onShare: {
                                    Task {
                                        await viewModel.shareDrawerMoodboard(for: drawer)
                                    }
                                }
                            )

                            Divider()
                        }

                        // New drawer button
                        Button(action: { isCreatingDrawer = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("New Drawer")
                                    .font(Typography.body)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .foregroundColor(.brandAccent)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadDrawers()
        }
        .sheet(isPresented: $isCreatingDrawer) {
            NewDrawerSheet(
                isPresented: $isCreatingDrawer,
                viewModel: viewModel
            )
        }
        .overlay(alignment: .top) {
            if let error = viewModel.error {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(error)
                        .font(Typography.caption)
                }
                .foregroundColor(.white)
                .padding(12)
                .background(Color.saleRed)
                .cornerRadius(8)
                .padding(12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Drawer Section View

struct DrawerSectionView: View {
    let drawer: DresserDrawer
    let isEditMode: Bool
    @Bindable var viewModel: DresserViewModel

    var onDelete: () -> Void
    var onShare: () -> Void

    @State private var isExpanded = true
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    // Drawer color indicator
                    Circle()
                        .fill(drawer.colorTag.color)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(drawer.name)
                            .font(Typography.bodyBold)
                            .foregroundColor(.textPrimary)

                        Text("\(drawer.itemCount) items")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                if isEditMode && !drawer.isDefault {
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.textTertiary)
                            .frame(width: 44, height: 44)
                    }
                } else if !isEditMode {
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.brandAccent)
                            .frame(width: 44, height: 44)
                    }
                }

                Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                } }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 44, height: 44)
                }
            }
            .padding(16)
            .contentShape(Rectangle())

            // Expanded content
            if isExpanded {
                Divider()

                if drawer.itemCount > 0 {
                    DresserGridView(
                        items: drawer.savedProducts,
                        viewModel: viewModel,
                        drawer: drawer
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "hanger")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.textTertiary)

                        Text("No items yet")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                }
            }
        }
        .background(Color.surfaceCard)
        .confirmationDialog(
            "Delete Drawer",
            isPresented: $showDeleteConfirmation,
            presenting: drawer
        ) { drawer in
            Button("Delete", role: .destructive) {
                Task {
                    onDelete()
                }
            }
        } message: { drawer in
            Text("Are you sure you want to delete \"\(drawer.name)\"? This action cannot be undone.")
        }
    }
}

// MARK: - Dresser Grid View

struct DresserGridView: View {
    let items: [SavedProduct]
    @Bindable var viewModel: DresserViewModel
    let drawer: DresserDrawer

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 150), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(items) { item in
                DresserItemCardView(
                    item: item,
                    drawer: drawer,
                    viewModel: viewModel
                )
                .contextMenu {
                    Button("Remove", role: .destructive) {
                        Task {
                            await viewModel.removeItem(item, fromDrawer: drawer.id)
                        }
                    }

                    if viewModel.drawers.count > 1 {
                        Menu("Move to Drawer") {
                            ForEach(viewModel.drawers.filter { $0.id != drawer.id }) { target in
                                Button(target.name) {
                                    Task {
                                        await viewModel.moveItem(item, fromDrawer: drawer.id, toDrawer: target.id)
                                    }
                                }
                            }
                        }
                    }

                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Dresser Item Card

struct DresserItemCardView: View {
    let item: SavedProduct
    let drawer: DresserDrawer
    @Bindable var viewModel: DresserViewModel

    @State private var imagePhase: AsyncImagePhase = .empty

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Image
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.surfaceBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                    )
                    .frame(height: 150)
                    .overlay(
                        Group {
                            switch imagePhase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .clipped()

                            case .failure, .empty:
                                Image(systemName: "photo")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(.textTertiary)

                            @unknown default:
                                EmptyView()
                            }
                        }
                    )

                // Price drop badge
                if let original = item.currentPrice, original > item.currentPrice {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Deal")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.saleRed)
                    .cornerRadius(4)
                    .padding(6)
                }
            }

            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.brandName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Text(item.productName)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)

                Text(formatPrice(item.currentPrice))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            if let imageURL = item.imageURL {
                if let uiImage = await ImageCacheService.shared.loadImage(from: imageURL) {
                    imagePhase = .success(Image(uiImage: uiImage))
                } else {
                    imagePhase = .failure(NSError(domain: "DresserItem", code: -1))
                }
            }
        }
    }

    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = item.currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}

// MARK: - New Drawer Sheet

struct NewDrawerSheet: View {
    @Binding var isPresented: Bool
    @Bindable var viewModel: DresserViewModel

    @State private var drawerName = ""
    @State private var drawerColor = DresserColorTag.blue

    var body: some View {
        NavigationStack {
            Form {
                Section("Drawer Name") {
                    TextField("e.g., Summer Vibes", text: $drawerName)
                }

                Section("Color Tag") {
                    Picker("Color", selection: $drawerColor) {
                        ForEach(DresserColorTag.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 16, height: 16)
                                Text(color.displayName)
                            }
                            .tag(color)
                        }
                    }
                }
            }
            .navigationTitle("New Drawer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createDrawer(
                                name: drawerName,
                                description: nil,
                                colorTag: drawerColor
                            )
                            isPresented = false
                        }
                    }
                    .disabled(drawerName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @State var viewModel = DresserViewModel()
    return DresserView(viewModel: viewModel)
}
