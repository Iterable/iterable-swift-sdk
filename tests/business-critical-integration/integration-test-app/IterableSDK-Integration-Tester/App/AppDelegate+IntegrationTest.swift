import UIKit
import IterableSDK

// MARK: - AppDelegate Integration Test Extensions

extension AppDelegate {

    func configureForIntegrationTesting() {
        // Check if we're running in integration test mode
        guard ProcessInfo.processInfo.environment["INTEGRATION_TEST"] == "1" else {
            return
        }

        print("🧪 Configuring app for integration testing...")

        // Set up test user automatically
        setupTestUser()

        // Add test mode indicators to the UI
        addTestModeIndicators()

        // Register for test notifications
        registerForTestNotifications()
    }

    private func setupTestUser() {
        // Get test user email from environment
        let testUserEmail = ProcessInfo.processInfo.environment["TEST_USER_EMAIL"] ?? "integration-test@example.com"

        // Set the user email for Iterable
        IterableAPI.email = testUserEmail

        print("🧪 Test user configured: \(testUserEmail)")

        // Update user profile with test data
        let testUserData: [String: Any] = [
            "testMode": true,
            "environment": "local",
            "platform": "iOS",
            "testStartTime": Date().timeIntervalSince1970
        ]

        IterableAPI.updateUser(testUserData, mergeNestedObjects: false)
    }

    private func addTestModeIndicators() {
        // Add visual indicators that we're in test mode
        DispatchQueue.main.async {
            if let window = self.window {
                // Add a test mode banner
                let testBanner = UIView()
                testBanner.backgroundColor = UIColor.systemYellow
                testBanner.translatesAutoresizingMaskIntoConstraints = false

                let testLabel = UILabel()
                testLabel.text = "🧪 INTEGRATION TEST MODE 🧪"
                testLabel.textAlignment = .center
                testLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                testLabel.translatesAutoresizingMaskIntoConstraints = false

                testBanner.addSubview(testLabel)
                window.addSubview(testBanner)

                NSLayoutConstraint.activate([
                    testBanner.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
                    testBanner.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                    testBanner.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                    testBanner.heightAnchor.constraint(equalToConstant: 30),

                    testLabel.centerXAnchor.constraint(equalTo: testBanner.centerXAnchor),
                    testLabel.centerYAnchor.constraint(equalTo: testBanner.centerYAnchor)
                ])

                // Bring banner to front
                window.bringSubviewToFront(testBanner)
            }
        }
    }

    private func registerForTestNotifications() {
        // Register for test-specific notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSDKReadyForTesting),
            name: .sdkReadyForTesting,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePushNotificationProcessed),
            name: .pushNotificationProcessed,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInAppMessageDisplayed),
            name: .inAppMessageDisplayed,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeepLinkProcessed),
            name: .deepLinkProcessed,
            object: nil
        )
    }

    @objc private func handleSDKReadyForTesting() {
        print("🧪 SDK is ready for testing")

        // Add accessibility identifier for automated testing
        window?.accessibilityIdentifier = "app-ready-indicator"

        // Post notification that app is ready for testing
        NotificationCenter.default.post(name: .appReadyForTesting, object: nil)
    }

    @objc private func handlePushNotificationProcessed(notification: Notification) {
        print("🧪 Push notification processed")

        if let payload = notification.object as? [AnyHashable: Any] {
            print("📧 Payload: \(payload)")
        }

        // Add test validation indicators
        addTestIndicator(text: "PUSH PROCESSED", color: .systemGreen)
    }

    @objc private func handleInAppMessageDisplayed(notification: Notification) {
        print("🧪 In-app message displayed")

        // Add test validation indicators
        addTestIndicator(text: "IN-APP DISPLAYED", color: .systemBlue)
    }

    @objc private func handleDeepLinkProcessed(notification: Notification) {
        print("🧪 Deep link processed")

        if let data = notification.object as? [String: Any],
           let url = data["url"] as? String,
           let handled = data["handled"] as? Bool {
            print("🔗 URL: \(url), Handled: \(handled)")
        }

        // Add test validation indicators
        addTestIndicator(text: "DEEP LINK PROCESSED", color: .systemOrange)
    }

    private func addTestIndicator(text: String, color: UIColor) {
        DispatchQueue.main.async {
            guard let window = self.window else { return }

            // Create floating indicator
            let indicator = UIView()
            indicator.backgroundColor = color
            indicator.layer.cornerRadius = 8
            indicator.alpha = 0.9
            indicator.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = text
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            indicator.addSubview(label)
            window.addSubview(indicator)

            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                indicator.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 40),
                indicator.widthAnchor.constraint(equalToConstant: 200),
                indicator.heightAnchor.constraint(equalToConstant: 30),

                label.centerXAnchor.constraint(equalTo: indicator.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: indicator.centerYAnchor)
            ])

            // Auto-remove after 3 seconds
            UIView.animate(withDuration: 0.3, animations: {
                indicator.alpha = 1.0
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 2.7, animations: {
                    indicator.alpha = 0.0
                }) { _ in
                    indicator.removeFromSuperview()
                }
            }
        }
    }
}

// MARK: - Enhanced Methods for Integration Testing

extension AppDelegate {

    func enhancedApplicationDidFinishLaunching(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // Configure for integration testing after normal setup
        configureForIntegrationTesting()
    }

    func enhancedApplicationDidBecomeActive(_ application: UIApplication) {
        // Check if we're in test mode and bypass normal validation
        if IntegrationTestHelper.shared.isInTestMode() {
            print("🧪 App became active in test mode")
            // Skip API key and login validation in test mode
            return
        }
    }

    // Enhanced push notification handling for testing
    func enhancedDidReceiveRemoteNotification(_ application: UIApplication, userInfo: [AnyHashable: Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        // Log for testing
        if IntegrationTestHelper.shared.isInTestMode() {
            print("🧪 Received remote notification: \(userInfo)")
        }

        // Call original implementation
        IterableAppIntegration.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: fetchCompletionHandler)

        // Notify test helper
        if IntegrationTestHelper.shared.isInTestMode() {
            NotificationCenter.default.post(name: .pushNotificationProcessed, object: userInfo)
        }
    }

    // Enhanced device token registration for testing
    func enhancedDidRegisterForRemoteNotifications(_ application: UIApplication, deviceToken: Data) {

        // Log for testing
        if IntegrationTestHelper.shared.isInTestMode() {
            let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("🧪 Device token registered: \(tokenString)")
        }

        // Call original implementation
        IterableAPI.register(token: deviceToken)

        // Add test indicator
        if IntegrationTestHelper.shared.isInTestMode() {
            addTestIndicator(text: "DEVICE TOKEN REGISTERED", color: .systemPurple)
        }
    }

    // Enhanced deep link handling for testing
    func enhancedContinueUserActivity(_ application: UIApplication, userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        guard let url = userActivity.webpageURL else {
            return false
        }

        // Log for testing
        if IntegrationTestHelper.shared.isInTestMode() {
            print("🧪 Processing universal link: \(url)")
        }

        // Handle through Iterable SDK (original implementation)
        let handled = IterableAPI.handle(universalLink: url)

        // Notify test helper
        if IntegrationTestHelper.shared.isInTestMode() {
            NotificationCenter.default.post(name: .deepLinkProcessed, object: ["url": url.absoluteString, "handled": handled])
        }

        return handled
    }
}

// MARK: - Notification Names Extension

extension Notification.Name {
    static let appReadyForTesting = Notification.Name("appReadyForTesting")
    static let sdkReadyForTesting = Notification.Name("sdkReadyForTesting")
    static let pushNotificationProcessed = Notification.Name("pushNotificationProcessed")
    static let inAppMessageDisplayed = Notification.Name("inAppMessageDisplayed")
    static let deepLinkProcessed = Notification.Name("deepLinkProcessed")
}