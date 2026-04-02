import Foundation
import SwiftUI
import RosierCore

/// ViewModel managing dresser drawers, items, and organization.
@Observable final class DresserViewModel {
    // MARK: - Published Properties

    var drawers: [DresserDrawer] = []
    var isLoading = false
    var error: String?
    var isEditMode = false
    var selectedDrawerId: UUID?

    var draggedItem: SavedProduct?
    var sourceDrawerId: UUID?

    // MARK: - Private Properties

    private let networkService = NetworkService.shared
    private let authService = AuthService.shared

    // MARK: - Computed Properties

    var allItems: [SavedProduct] {
        drawers.flatMap { $0.savedProducts }
    }

    var totalItemCount: Int {
        allItems.count
    }

    var defaultDrawer: DresserDrawer? {
        drawers.first { $0.isDefault }
    }

    // MARK: - Public Methods

    func loadDrawers() async {
        isLoading = true
        error = nil

        do {
            let fetchedDrawers: [DresserDrawer] = try await networkService.request(
                "dressers",
                method: .get
            )

            DispatchQueue.main.async {
                self.drawers = fetchedDrawers.sorted { $0.displayOrder < $1.displayOrder }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func createDrawer(
        name: String,
        description: String?,
        colorTag: DresserColorTag
    ) async {
        do {
            let request = CreateDrawerRequest(
                name: name,
                description: description,
                colorTag: colorTag
            )

            let newDrawer: DresserDrawer = try await networkService.request(
                "dressers",
                method: .post,
                body: request
            )

            DispatchQueue.main.async {
                self.drawers.append(newDrawer)
                self.drawers.sort { $0.displayOrder < $1.displayOrder }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }

    func updateDrawer(
        _ drawer: DresserDrawer,
        name: String,
        description: String?,
        colorTag: DresserColorTag
    ) async {
        do {
            let request = UpdateDrawerRequest(
                name: name,
                description: description,
                colorTag: colorTag
            )

            let updated: DresserDrawer = try await networkService.request(
                "dressers/\(drawer.id)",
                method: .patch,
                body: request
            )

            DispatchQueue.main.async {
                if let index = self.drawers.firstIndex(where: { $0.id == drawer.id }) {
                    self.drawers[index] = updated
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }

    func deleteDrawer(_ drawer: DresserDrawer) async {
        guard !drawer.isDefault else { return }

        do {
            try await networkService.requestEmpty(
                "dressers/\(drawer.id)",
                method: .delete
            )

            DispatchQueue.main.async {
                self.drawers.removeAll { $0.id == drawer.id }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }

    func moveItem(
        _ item: SavedProduct,
        fromDrawer: UUID,
        toDrawer: UUID
    ) async {
        do {
            let request = MoveItemRequest(
                targetDrawerId: toDrawer
            )

            try await networkService.requestEmpty(
                "dressers/items/\(item.id)/move",
                method: .post,
                body: request
            )

            DispatchQueue.main.async {
                // Update local state
                if let fromIndex = self.drawers.firstIndex(where: { $0.id == fromDrawer }),
                   let itemIndex = self.drawers[fromIndex].savedProducts.firstIndex(where: { $0.id == item.id }) {
                    let movedItem = self.drawers[fromIndex].savedProducts.remove(at: itemIndex)

                    if let toIndex = self.drawers.firstIndex(where: { $0.id == toDrawer }) {
                        self.drawers[toIndex].savedProducts.append(movedItem)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }

    func removeItem(_ item: SavedProduct, fromDrawer: UUID) async {
        do {
            try await networkService.requestEmpty(
                "dressers/items/\(item.id)",
                method: .delete
            )

            DispatchQueue.main.async {
                if let drawerIndex = self.drawers.firstIndex(where: { $0.id == fromDrawer }) {
                    self.drawers[drawerIndex].savedProducts.removeAll { $0.id == item.id }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }

    func reorderDrawers(_ newOrder: [DresserDrawer]) async {
        let request = ReorderDrawersRequest(
            drawerIds: newOrder.map { $0.id }
        )

        do {
            try await networkService.requestEmpty(
                "dressers/reorder",
                method: .post,
                body: request
            )

            DispatchQueue.main.async {
                self.drawers = newOrder
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }

    func generateDrawerMoodboard(for drawer: DresserDrawer) async -> UIImage? {
        let images = drawer.savedProducts.prefix(9).compactMap { item -> UIImage? in
            // In production, load actual images from URLs
            // For now, return nil to indicate async image loading
            nil
        }

        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Background
            UIColor(Color.surfaceCard).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw grid layout
            let gridSize = CGFloat(3)
            let itemSize = size.width / gridSize

            for (index, _) in images.enumerated() {
                let row = CGFloat(index / 3)
                let col = CGFloat(index % 3)
                let rect = CGRect(
                    x: col * itemSize,
                    y: row * itemSize,
                    width: itemSize,
                    height: itemSize
                )

                // Placeholder rectangle
                UIColor(Color.surfaceBackground).setFill()
                context.cgContext.fill(rect)

                // Border
                UIColor(Color.textTertiary).setStroke()
                context.cgContext.setLineWidth(1)
                context.cgContext.stroke(rect)
            }

            // Title
            let title = drawer.name
            let font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(Color.textPrimary)
            ]

            let titleSize = (title as NSString).size(withAttributes: attributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: size.height - 40,
                width: titleSize.width,
                height: titleSize.height
            )

            (title as NSString).draw(in: titleRect, withAttributes: attributes)
        }

        return image
    }

    func shareDrawerMoodboard(for drawer: DresserDrawer) async {
        guard let image = await generateDrawerMoodboard(for: drawer) else {
            self.error = "Failed to generate moodboard image"
            return
        }

        DispatchQueue.main.async {
            let activityViewController = UIActivityViewController(
                activityItems: [image, drawer.name],
                applicationActivities: nil
            )

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(activityViewController, animated: true)
            }
        }
    }

    func toggleEditMode() {
        isEditMode.toggle()
        if !isEditMode {
            draggedItem = nil
            sourceDrawerId = nil
        }
    }
}

// MARK: - Request Models

struct CreateDrawerRequest: Codable {
    let name: String
    let description: String?
    let colorTag: DresserColorTag
}

struct UpdateDrawerRequest: Codable {
    let name: String
    let description: String?
    let colorTag: DresserColorTag
}

struct MoveItemRequest: Codable {
    let targetDrawerId: UUID
}

struct ReorderDrawersRequest: Codable {
    let drawerIds: [UUID]
}
