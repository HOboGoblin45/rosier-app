import Foundation
import SwiftUI
import RosierCore

/// ViewModel managing referral code, stats, and sharing functionality.
@Observable final class ReferralViewModel {
    // MARK: - Published Properties

    var referralStats: ReferralStats?
    var referralCode: String = ""
    var isLoading = false
    var error: String?
    var showShareSheet = false
    var celebrationTrigger = false
    var newTierUnlocked: ReferralTier?

    // MARK: - Computed Properties

    var progressToNextTier: Double {
        referralStats?.progressToNextTier ?? 0
    }

    var currentTierName: String {
        referralStats?.currentTier.displayName ?? "No Tier"
    }

    var currentTierDescription: String {
        referralStats?.currentTier.description ?? ""
    }

    var successfulReferrals: Int {
        referralStats?.successfulReferrals ?? 0
    }

    var referralsToNextTier: Int {
        referralStats?.referralsToNext ?? 0
    }

    var shareMessage: String {
        let code = referralCode
        return "Join me on Rosier! Use my code \(code) for exclusive access. Download: https://rosier.app/invite/\(code)"
    }

    var shareURL: URL? {
        guard !referralCode.isEmpty else { return nil }
        return URL(string: "https://rosier.app/invite/\(referralCode)")
    }

    // MARK: - Private Properties

    private let networkService = NetworkService.shared
    private var shareEventTask: Task<Void, Never>?

    // MARK: - Public Methods

    /// Loads user's referral code and current stats.
    func loadReferralData() async {
        isLoading = true
        error = nil

        do {
            // Fetch referral stats
            let stats: ReferralStats = try await networkService.request("referrals/stats")

            DispatchQueue.main.async {
                self.referralStats = stats
                self.referralCode = stats.code
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    /// Copies referral code to clipboard.
    func copyCodeToClipboard() {
        UIPasteboard.general.string = referralCode
    }

    /// Opens native iOS share sheet.
    func showNativeShareSheet() {
        guard let url = shareURL else { return }

        let activityViewController = UIActivityViewController(
            activityItems: [shareMessage, url],
            applicationActivities: nil
        )

        // Exclude certain activity types for referral sharing
        activityViewController.excludedActivityTypes = [
            .saveToPasteboard,
            .print,
            .assignToContact,
            .openInBooks
        ]

        // Track share event
        trackShareEvent(with: activityViewController)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }

    /// Applies a referral code during onboarding/account setup.
    func applyReferralCode(_ code: String, source: String = "link") async -> Bool {
        let request = ApplyReferralCodeRequest(code: code.uppercased(), source: source)

        do {
            try await networkService.requestEmpty(
                "referrals/apply",
                method: .post,
                body: request
            )
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
            return false
        }
    }

    /// Validates referral code format (ROSIE-XXXX).
    func validateReferralCodeFormat(_ code: String) -> Bool {
        let pattern = "^ROSIE-[A-Z0-9]{4}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: code.utf16.count)
        return regex?.firstMatch(in: code, options: [], range: range) != nil
    }

    /// Triggers celebration animation when new tier is unlocked.
    func triggerCelebration(for tier: ReferralTier) {
        newTierUnlocked = tier
        withAnimation(Animations.badgePulse) {
            celebrationTrigger = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                self.celebrationTrigger = false
            }
        }
    }

    /// Retries loading referral data after error.
    func retry() async {
        await loadReferralData()
    }

    // MARK: - Private Methods

    private func trackShareEvent(with controller: UIActivityViewController) {
        let delegate = ShareCompletionDelegate { [weak self] activity in
            guard let activity = activity else { return }

            let platform: ShareTrackingRequest.Platform = {
                switch activity {
                case UIActivity.ActivityType.message:
                    return .imessage
                case UIActivity.ActivityType.mail:
                    return .email
                case UIActivity.ActivityType.postToFacebook:
                    return .other
                case UIActivity.ActivityType.postToTwitter:
                    return .other
                default:
                    return .other
                }
            }()

            Task {
                await self?.trackShare(platform: platform.rawValue)
            }
        }

        controller.completionWithItemsHandler = { activity, completed, _, error in
            if completed {
                let platform = activity.map { String($0.rawValue) } ?? "other"
                Task {
                    await self.trackShare(platform: platform)
                }
            }
        }
    }

    private func trackShare(platform: String) async {
        let request = ShareTrackingRequest(platform: platform)

        do {
            try await networkService.requestEmpty(
                "referrals/track-share",
                method: .post,
                body: request
            )
        } catch {
            // Silently fail - don't disrupt user experience for tracking
            print("Failed to track share event: \(error)")
        }
    }
}

// MARK: - Share Completion Delegate

private class ShareCompletionDelegate: NSObject {
    let completionHandler: (UIActivity.ActivityType?) -> Void

    init(completionHandler: @escaping (UIActivity.ActivityType?) -> Void) {
        self.completionHandler = completionHandler
        super.init()
    }
}
