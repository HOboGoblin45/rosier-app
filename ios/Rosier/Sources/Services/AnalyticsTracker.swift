import Foundation

/// Singleton analytics tracker that manages event tracking, user identity, and event batching.
/// Wraps the underlying AnalyticsService with type-safe event handling.
final class AnalyticsTracker {
    // MARK: - Singleton

    static let shared = AnalyticsTracker()

    // MARK: - Properties

    private let analyticsService = AnalyticsService.shared
    private var userId: String?
    private var superProperties: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.rosier.analytics", qos: .background)

    // MARK: - Initializers

    private init() {
        setupSuperProperties()
    }

    // MARK: - Public Methods

    /// Sets the current user ID for tracking.
    /// - Parameter userId: The unique user identifier
    func setUserId(_ userId: String?) {
        queue.async {
            self.userId = userId
        }
    }

    /// Tracks a type-safe analytics event.
    /// - Parameter event: The analytics event to track
    func track(_ event: AnalyticsEvent) {
        queue.async {
            var properties = event.properties
            properties.merge(self.superProperties) { original, _ in original }

            if let userId = self.userId {
                properties["user_id"] = userId
            }

            properties["timestamp"] = ISO8601DateFormatter().string(from: Date())
            properties["app_version"] = self.appVersion
            properties["os_version"] = self.osVersion
            properties["device_model"] = self.deviceModel

            self.analyticsService.trackEvent(event.eventName, properties: properties)
        }
    }

    /// Sets a super property that will be included in all future events.
    /// - Parameters:
    ///   - property: The property name
    ///   - value: The property value
    func setSuperProperty(_ property: String, value: Any) {
        queue.async {
            self.superProperties[property] = value
        }
    }

    /// Sets multiple super properties at once.
    /// - Parameter properties: Dictionary of super properties
    func setSuperProperties(_ properties: [String: Any]) {
        queue.async {
            self.superProperties.merge(properties) { _, new in new }
        }
    }

    /// Clears all super properties.
    func clearSuperProperties() {
        queue.async {
            self.superProperties.removeAll()
        }
    }

    /// Resets the tracker (typically on user logout).
    func reset() {
        queue.async {
            self.userId = nil
            self.superProperties.removeAll()
            self.analyticsService.flush()
        }
    }

    /// Flushes any buffered events to the server.
    func flush() {
        analyticsService.flush()
    }

    // MARK: - Private Methods

    private func setupSuperProperties() {
        let properties: [String: Any] = [
            "app_name": "Rosier",
            "platform": "iOS",
            "app_version": appVersion,
            "os_version": osVersion,
            "device_model": deviceModel
        ]

        setSuperProperties(properties)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    private var osVersion: String {
        UIDevice.current.systemVersion
    }

    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafeBytes(of: &systemInfo.machine) { buffer in
            buffer.compactMap { byte in
                byte > 0 ? String(UnicodeScalar(byte)) : nil
            }.joined()
        }
        return modelCode.isEmpty ? "unknown" : modelCode
    }
}
