import SwiftUI

/// Native iOS Share Sheet wrapper for referral code sharing.
/// Presents the system share sheet with pre-populated referral message and link.
struct ReferralShareSheet: UIViewControllerRepresentable {
    // MARK: - Properties

    let referralCode: String
    let shareMessage: String
    var onDismiss: (() -> Void)?

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let message = shareMessage
        let url = URL(string: "https://rosier.app/invite/\(referralCode)") ?? URL(string: "https://rosier.app")!

        let activityViewController = UIActivityViewController(
            activityItems: [message, url],
            applicationActivities: nil
        )

        // Exclude certain activity types
        activityViewController.excludedActivityTypes = [
            .copyToPasteboard,
            .print,
            .assignToContact,
            .openInIBooks,
            .addToReadingList
        ]

        // Set completion handler
        activityViewController.completionWithItemsHandler = { activity, completed, _, error in
            if completed {
                trackShareEvent(activity: activity)
            }
            onDismiss?()
        }

        return activityViewController
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}

    // MARK: - Private Methods

    private func trackShareEvent(activity: UIActivity.ActivityType?) {
        let platform: ShareTrackingRequest.Platform = {
            guard let activity = activity else { return .other }

            switch activity {
            case UIActivity.ActivityType.message:
                return .imessage
            case UIActivity.ActivityType.mail:
                return .email
            default:
                return .other
            }
        }()

        Task {
            let request = ShareTrackingRequest(platform: platform.rawValue)
            let networkService = NetworkService.shared

            do {
                try await networkService.requestEmpty(
                    "referrals/track-share",
                    method: .post,
                    body: request
                )
            } catch {
                print("Failed to track share event: \(error)")
            }
        }
    }
}

// MARK: - Share Sheet Presenter

/// Modifier to present the referral share sheet.
extension View {
    func referralShareSheet(
        isPresented: Binding<Bool>,
        referralCode: String,
        shareMessage: String,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        sheet(isPresented: isPresented) {
            ReferralShareSheet(
                referralCode: referralCode,
                shareMessage: shareMessage,
                onDismiss: {
                    isPresented.wrappedValue = false
                    onDismiss?()
                }
            )
        }
    }
}
