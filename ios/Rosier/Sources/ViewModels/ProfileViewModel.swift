import Foundation
import SwiftUI


/// ViewModel managing user profile and style DNA data.
@Observable final class ProfileViewModel {
    // MARK: - Published Properties

    var userProfile: UserProfile?
    var styleDNA: StyleDNA?
    var isLoading = false
    var error: String?

    var totalSwipes: Int {
        styleDNA?.stats.totalSwipes ?? 0
    }

    var totalSaves: Int {
        styleDNA?.stats.totalLikes ?? 0
    }

    var memberSinceDate: String {
        guard let profile = userProfile else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: profile.createdAt)
    }

    var mostSavedCategory: String {
        guard let dna = styleDNA else { return "" }
        let sortedCategories = dna.stats.favoriteCategories.sorted { $0.value > $1.value }
        if let topCategory = sortedCategories.first {
            let percentage = Int(Double(topCategory.value) / Double(dna.stats.totalLikes) * 100)
            return "\(topCategory.key.displayName) (\(percentage)%)"
        }
        return ""
    }

    var archetypeName: String {
        let archetype = styleDNA?.archetype ?? ""
        if let secondary = styleDNA?.secondaryArchetypes.first {
            return "\(archetype) with \(secondary)"
        }
        return archetype
    }

    var hasStyleDNA: Bool {
        styleDNA != nil && styleDNA?.stats.totalSwipes ?? 0 >= 100
    }

    // MARK: - Private Properties

    private let networkService = NetworkService.shared
    private let authService = AuthService.shared

    // MARK: - Public Methods

    func loadProfile() async {
        isLoading = true
        error = nil

        do {
            let profile: UserProfile = try await networkService.request("users/me")

            DispatchQueue.main.async {
                self.userProfile = profile
                self.isLoading = false
            }

            // Load style DNA if available
            await loadStyleDNA()
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func loadStyleDNA() async {
        do {
            let dna: StyleDNA? = try? await networkService.request("users/me/style-dna")

            DispatchQueue.main.async {
                self.styleDNA = dna
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }

    func generateStyleDNAImage() -> UIImage? {
        guard let dna = styleDNA else { return nil }

        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Background
            UIColor(Color.brandPrimary).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Title
            let titleFont = UIFont.systemFont(ofSize: 48, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor(Color.brandAccent)
            ]

            let title = "YOUR STYLE DNA"
            let titleSize = (title as NSString).size(withAttributes: titleAttributes)
            (title as NSString).draw(
                at: CGPoint(x: (size.width - titleSize.width) / 2, y: 80),
                withAttributes: titleAttributes
            )

            // Archetype
            let archetypeFont = UIFont.systemFont(ofSize: 32, weight: .semibold)
            let archetypeAttributes: [NSAttributedString.Key: Any] = [
                .font: archetypeFont,
                .foregroundColor: UIColor(Color.textPrimary)
            ]

            let archetyp = archetypeName
            let archetypeSize = (archetyp as NSString).size(withAttributes: archetypeAttributes)
            (archetyp as NSString).draw(
                at: CGPoint(x: (size.width - archetypeSize.width) / 2, y: 180),
                withAttributes: archetypeAttributes
            )

            // Top brands section
            let sectionFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: sectionFont,
                .foregroundColor: UIColor(Color.textPrimary)
            ]

            ("TOP BRANDS" as NSString).draw(
                at: CGPoint(x: 60, y: 320),
                withAttributes: sectionAttributes
            )

            // Brand placeholder boxes
            let brandBoxSize: CGFloat = 80
            let brandSpacing: CGFloat = 20
            var brandX: CGFloat = 60

            for _ in 0..<min(5, dna.topBrands.count) {
                UIColor(Color.surfaceCard).setFill()
                context.cgContext.fillEllipse(in: CGRect(x: brandX, y: 380, width: brandBoxSize, height: brandBoxSize))

                brandX += brandBoxSize + brandSpacing
            }

            // Color palette section
            ("YOUR PALETTE" as NSString).draw(
                at: CGPoint(x: 60, y: 520),
                withAttributes: sectionAttributes
            )

            // Color swatches
            let colorSwatchSize: CGFloat = 60
            let colorSpacing: CGFloat = 20
            var colorX: CGFloat = 60

            let colors: [UIColor] = [
                UIColor(Color.saleRed),
                UIColor(Color.brandAccent),
                UIColor(Color.successGreen),
                UIColor(Color.textSecondary),
                UIColor(Color.surfaceCard)
            ]

            for color in colors {
                color.setFill()
                context.cgContext.fillEllipse(in: CGRect(x: colorX, y: 580, width: colorSwatchSize, height: colorSwatchSize))

                colorX += colorSwatchSize + colorSpacing
            }

            // Price range section
            let priceText = "PRICE SWEET SPOT: \(dna.priceRange.estimatedRangeUSD.lowerBound) – $\(dna.priceRange.estimatedRangeUSD.upperBound)"
            let priceFont = UIFont.systemFont(ofSize: 20, weight: .regular)
            let priceAttributes: [NSAttributedString.Key: Any] = [
                .font: priceFont,
                .foregroundColor: UIColor(Color.textPrimary)
            ]

            (priceText as NSString).draw(
                at: CGPoint(x: 60, y: 720),
                withAttributes: priceAttributes
            )

            // Stats section
            let statsText = "STYLE STATS: \(dna.stats.totalSwipes) swipes · \(dna.stats.totalLikes) saves · Most saved: \(mostSavedCategory)"
            let statsFont = UIFont.systemFont(ofSize: 18, weight: .regular)
            let statsAttributes: [NSAttributedString.Key: Any] = [
                .font: statsFont,
                .foregroundColor: UIColor(Color.textSecondary)
            ]

            (statsText as NSString).draw(
                at: CGPoint(x: 60, y: 800),
                withAttributes: statsAttributes
            )

            // Footer
            let footerFont = UIFont.systemFont(ofSize: 16, weight: .regular)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor(Color.textSecondary)
            ]

            let footer = "Discover your style DNA at rosier.app"
            let footerSize = (footer as NSString).size(withAttributes: footerAttributes)
            (footer as NSString).draw(
                at: CGPoint(x: (size.width - footerSize.width) / 2, y: size.height - 80),
                withAttributes: footerAttributes
            )
        }

        return image
    }

    func shareStyleDNA() {
        guard let image = generateStyleDNAImage() else {
            self.error = "Failed to generate Style DNA image"
            return
        }

        DispatchQueue.main.async {
            let activityViewController = UIActivityViewController(
                activityItems: [image, "Check out my Style DNA on Rosier!"],
                applicationActivities: nil
            )

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(activityViewController, animated: true)
            }
        }
    }

    func signOut() {
        authService.signOut()
    }

    func deleteAccount() async {
        do {
            try await networkService.requestEmpty(
                "users/me",
                method: .delete
            )

            DispatchQueue.main.async {
                self.authService.signOut()
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }

    func clearStyleProfile() async {
        do {
            try await networkService.requestEmpty(
                "users/me/style-profile",
                method: .delete
            )

            DispatchQueue.main.async {
                self.styleDNA = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }
}
