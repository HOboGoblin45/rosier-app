import SwiftUI


/// Settings screen with notification, feed, and account preferences.
struct SettingsView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showClearConfirmation = false
    @State private var showDeleteConfirmation = false

    // Notification preferences
    @State private var priceDropNotifications = true
    @State private var saleCalendarNotifications = true
    @State private var weeklyDigestNotifications = true

    // Feed preferences
    @State private var selectedCategories: [ProductCategory] = [.clothing, .shoes]
    @State private var priceRangeMax: Double = 500

    // Display preferences
    @State private var openLinksInApp = true
    @AppStorage("darkMode") var darkMode: String = "system"

    var body: some View {
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            Form {
                // MARK: - Account Section

                Section("Account") {
                    HStack {
                        Text("Email")
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Text(viewModel.userProfile?.email ?? "Not signed in")
                            .font(Typography.caption)
                            .foregroundColor(.textPrimary)
                    }

                    HStack {
                        Text("Name")
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Text(viewModel.userProfile?.displayName ?? "User")
                            .font(Typography.caption)
                            .foregroundColor(.textPrimary)
                    }

                    Button(role: .destructive, action: { viewModel.signOut() }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Sign Out")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Notification Preferences

                Section("Notifications") {
                    Toggle(isOn: $priceDropNotifications) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Price Drop Alerts")
                                .foregroundColor(.textPrimary)

                            Text("When items you saved go on sale")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Toggle(isOn: $saleCalendarNotifications) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sale Calendar")
                                .foregroundColor(.textPrimary)

                            Text("Upcoming sales and launches")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Toggle(isOn: $weeklyDigestNotifications) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Digest")
                                .foregroundColor(.textPrimary)

                            Text("Your curated picks every Sunday")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                // MARK: - Feed Preferences

                Section("Discovery Feed") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(Typography.bodyBold)
                            .foregroundColor(.textPrimary)

                        HStack(spacing: 8) {
                            ForEach(ProductCategory.allCases, id: \.self) { category in
                                Button(action: { toggleCategory(category) }) {
                                    Text(category.displayName)
                                        .font(Typography.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedCategories.contains(category) ?
                                            Color.brandAccent : Color.surfaceBackground
                                        )
                                        .foregroundColor(
                                            selectedCategories.contains(category) ?
                                            Color.brandPrimary : Color.textSecondary
                                        )
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Max Price")
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Text("$\(Int(priceRangeMax))")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }

                        Slider(value: $priceRangeMax, in: 50...2000, step: 50)
                            .tint(.brandAccent)
                    }
                }

                // MARK: - Display Preferences

                Section("Display") {
                    Picker("Open Links", selection: $openLinksInApp) {
                        Text("In App").tag(true)
                        Text("Safari").tag(false)
                    }

                    Picker("Appearance", selection: $darkMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                // MARK: - Danger Zone

                Section("Data") {
                    Button(role: .destructive, action: { showClearConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Clear Style Profile")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Account Deletion

                Section {
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Delete Account")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - About

                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Text("1.0.0")
                            .font(Typography.caption)
                            .foregroundColor(.textPrimary)
                    }

                    Link(destination: URL(string: "https://rosier.app/terms")!) {
                        HStack {
                            Text("Terms of Service")
                                .foregroundColor(.brandAccent)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.brandAccent)
                        }
                    }

                    Link(destination: URL(string: "https://rosier.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundColor(.brandAccent)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.brandAccent)
                        }
                    }

                    Link(destination: URL(string: "https://rosier.app/licenses")!) {
                        HStack {
                            Text("Licenses")
                                .foregroundColor(.brandAccent)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.brandAccent)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
        .confirmationDialog(
            "Clear Style Profile?",
            isPresented: $showClearConfirmation
        ) {
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearStyleProfile()
                }
            }
        } message: {
            Text("This will reset your style DNA and recommendation history. You'll need to swipe at least 100 items again to rebuild it.")
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                    dismiss()
                }
            }
        } message: {
            Text("This action cannot be undone. All your saved items and profile data will be permanently deleted.")
        }
    }

    // MARK: - Helper Methods

    private func toggleCategory(_ category: ProductCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.removeAll { $0 == category }
        } else {
            selectedCategories.append(category)
        }
    }
}

// MARK: - Preview

#Preview {
    @State var viewModel = ProfileViewModel()
    return NavigationStack {
        SettingsView(viewModel: viewModel)
    }
}
