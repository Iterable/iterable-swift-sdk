import Foundation
import UIKit
import IterableSDK

// Integration Test Helper for Local Development Testing
// This class provides simple methods to trigger and validate integration test scenarios

class IntegrationTestHelper {
    
    // MARK: - Properties
    
    static let shared = IntegrationTestHelper()
    
    private var isTestMode: Bool = false
    private var testConfig: TestConfiguration?
    private var testResults: [TestResult] = []
    
    // MARK: - Configuration
    
    struct TestConfiguration {
        let apiKey: String
        let userEmail: String
        let enableDebugMode: Bool
        let testTimeout: TimeInterval
        
        init() {
            // Load from environment or use defaults
            self.apiKey = ProcessInfo.processInfo.environment["ITERABLE_API_KEY"] ?? ""
            self.userEmail = ProcessInfo.processInfo.environment["TEST_USER_EMAIL"] ?? "test@example.com"
            self.enableDebugMode = ProcessInfo.processInfo.environment["ENABLE_DEBUG_LOGGING"] == "1"
            self.testTimeout = TimeInterval(ProcessInfo.processInfo.environment["TEST_TIMEOUT"] ?? "60") ?? 60
        }
    }
    
    struct TestResult {
        let testName: String
        let success: Bool
        let message: String
        let timestamp: Date
    }
    
    // MARK: - Initialization
    
    private init() {
        setupTestMode()
    }
    
    private func setupTestMode() {
        // Check if we're running in integration test mode
        if ProcessInfo.processInfo.environment["INTEGRATION_TEST"] == "1" {
            isTestMode = true
            testConfig = TestConfiguration()
            
            print("🧪 Integration Test Mode Enabled")
            print("📧 Test User: \(testConfig?.userEmail ?? "not configured")")
            print("🔑 API Key Configured: \(!testConfig?.apiKey.isEmpty ?? false)")
        }
    }
    
    // MARK: - Test Mode Helpers
    
    func isInTestMode() -> Bool {
        return isTestMode
    }
    
    func configureIterableForTesting() {
        guard let config = testConfig, !config.apiKey.isEmpty else {
            recordTestResult("SDK Configuration", success: false, message: "API key not configured")
            return
        }
        
        // Configure Iterable SDK for testing
        let iterableConfig = IterableConfig()
        iterableConfig.pushIntegrationName = "integration-test"
        iterableConfig.debugLoggingEnabled = config.enableDebugMode
        
        // Initialize SDK
        IterableAPI.initialize(apiKey: config.apiKey, config: iterableConfig)
        
        // Set test user
        IterableAPI.email = config.userEmail
        
        recordTestResult("SDK Configuration", success: true, message: "SDK configured for testing")
        
        // Post notification that SDK is ready
        NotificationCenter.default.post(name: .sdkReadyForTesting, object: nil)
    }
    
    // MARK: - Push Notification Testing
    
    func testPushNotificationRegistration() {
        guard isTestMode else { return }
        
        print("🧪 Testing push notification registration...")
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.recordTestResult("Push Registration", success: true, message: "Permissions granted and registration initiated")
                } else {
                    self.recordTestResult("Push Registration", success: false, message: "Permissions denied: \(error?.localizedDescription ?? "unknown")")
                }
            }
        }
    }
    
    func simulatePushNotificationReceived() {
        guard isTestMode else { return }
        
        print("🧪 Simulating push notification received...")
        
        // Create a test push notification payload
        let testPayload: [AnyHashable: Any] = [
            "aps": [
                "alert": [
                    "title": "Integration Test Push",
                    "body": "This is a test push notification for integration testing"
                ],
                "badge": 1,
                "sound": "default"
            ],
            "itbl": [
                "campaignId": "12345",
                "templateId": "67890",
                "messageId": "test-message-\(Date().timeIntervalSince1970)"
            ]
        ]
        
        // Process the push notification through Iterable SDK
        IterableAppIntegration.application(UIApplication.shared, didReceiveRemoteNotification: testPayload) { result in
            self.recordTestResult("Push Processing", success: result == .newData, message: "Push notification processed")
        }
        
        // Post notification for test validation
        NotificationCenter.default.post(name: .pushNotificationProcessed, object: testPayload)
    }
    
    // MARK: - In-App Message Testing
    
    func testInAppMessageDisplay() {
        guard isTestMode else { return }
        
        print("🧪 Testing in-app message display...")
        
        // Trigger in-app message sync
        IterableAPI.inAppManager.syncInApp()
        
        // Get available messages
        let messages = IterableAPI.inAppManager.getMessages()
        
        if !messages.isEmpty {
            // Display the first available message
            if let message = messages.first {
                IterableAPI.inAppManager.show(message: message)
                recordTestResult("In-App Display", success: true, message: "Message displayed successfully")
            }
        } else {
            recordTestResult("In-App Display", success: false, message: "No in-app messages available")
        }
        
        // Post notification for test validation
        NotificationCenter.default.post(name: .inAppMessageDisplayed, object: messages.first)
    }
    
    func simulateInAppMessageInteraction() {
        guard isTestMode else { return }
        
        print("🧪 Simulating in-app message interaction...")
        
        // Post notification that user interacted with in-app message
        NotificationCenter.default.post(name: .inAppMessageInteracted, object: nil)
        
        recordTestResult("In-App Interaction", success: true, message: "In-app message interaction simulated")
    }
    
    // MARK: - Deep Link Testing
    
    func testDeepLinkHandling(url: String) {
        guard isTestMode else { return }
        
        print("🧪 Testing deep link handling: \(url)")
        
        if let deepLinkURL = URL(string: url) {
            // Process deep link through Iterable SDK
            let handled = IterableAPI.handle(universalLink: deepLinkURL)
            
            recordTestResult("Deep Link Handling", success: handled, message: "Deep link \(handled ? "handled" : "not handled"): \(url)")
            
            // Post notification for test validation
            NotificationCenter.default.post(name: .deepLinkProcessed, object: ["url": url, "handled": handled])
        } else {
            recordTestResult("Deep Link Handling", success: false, message: "Invalid URL: \(url)")
        }
    }
    
    // MARK: - Test Result Management
    
    private func recordTestResult(_ testName: String, success: Bool, message: String) {
        let result = TestResult(
            testName: testName,
            success: success,
            message: message,
            timestamp: Date()
        )
        
        testResults.append(result)
        
        // Print result
        let status = success ? "✅" : "❌"
        print("\(status) \(testName): \(message)")
    }
    
    func getTestResults() -> [TestResult] {
        return testResults
    }
    
    func clearTestResults() {
        testResults.removeAll()
    }
    
    // MARK: - UI Test Helpers
    
    func addTestButtons(to viewController: UIViewController) {
        guard isTestMode else { return }
        
        // Add test buttons to the UI for manual testing
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Push notification test button
        let pushButton = UIButton(type: .system)
        pushButton.setTitle("Test Push Registration", for: .normal)
        pushButton.backgroundColor = UIColor.systemBlue
        pushButton.setTitleColor(.white, for: .normal)
        pushButton.layer.cornerRadius = 8
        pushButton.addTarget(self, action: #selector(testPushButtonTapped), for: .touchUpInside)
        
        // In-app message test button
        let inAppButton = UIButton(type: .system)
        inAppButton.setTitle("Test In-App Message", for: .normal)
        inAppButton.backgroundColor = UIColor.systemGreen
        inAppButton.setTitleColor(.white, for: .normal)
        inAppButton.layer.cornerRadius = 8
        inAppButton.addTarget(self, action: #selector(testInAppButtonTapped), for: .touchUpInside)
        
        // Deep link test button
        let deepLinkButton = UIButton(type: .system)
        deepLinkButton.setTitle("Test Deep Link", for: .normal)
        deepLinkButton.backgroundColor = UIColor.systemOrange
        deepLinkButton.setTitleColor(.white, for: .normal)
        deepLinkButton.layer.cornerRadius = 8
        deepLinkButton.addTarget(self, action: #selector(testDeepLinkButtonTapped), for: .touchUpInside)
        
        // Results button
        let resultsButton = UIButton(type: .system)
        resultsButton.setTitle("View Test Results", for: .normal)
        resultsButton.backgroundColor = UIColor.systemPurple
        resultsButton.setTitleColor(.white, for: .normal)
        resultsButton.layer.cornerRadius = 8
        resultsButton.addTarget(self, action: #selector(showTestResultsButtonTapped), for: .touchUpInside)
        
        stackView.addArrangedSubview(pushButton)
        stackView.addArrangedSubview(inAppButton)
        stackView.addArrangedSubview(deepLinkButton)
        stackView.addArrangedSubview(resultsButton)
        
        viewController.view.addSubview(stackView)
        
        // Add constraints
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: viewController.view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: viewController.view.trailingAnchor, constant: -20),
            
            pushButton.heightAnchor.constraint(equalToConstant: 44),
            inAppButton.heightAnchor.constraint(equalToConstant: 44),
            deepLinkButton.heightAnchor.constraint(equalToConstant: 44),
            resultsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func testPushButtonTapped() {
        testPushNotificationRegistration()
    }
    
    @objc private func testInAppButtonTapped() {
        testInAppMessageDisplay()
    }
    
    @objc private func testDeepLinkButtonTapped() {
        testDeepLinkHandling(url: "https://links.iterable.com/u/click?_t=test&_m=integration")
    }
    
    @objc private func showTestResultsButtonTapped() {
        showTestResults()
    }
    
    private func showTestResults() {
        let results = getTestResults()
        
        let alert = UIAlertController(title: "Test Results", message: nil, preferredStyle: .alert)
        
        if results.isEmpty {
            alert.message = "No test results available"
        } else {
            let passed = results.filter { $0.success }.count
            let total = results.count
            alert.message = "Passed: \(passed)/\(total)\n\nLatest Results:\n" + 
                           results.suffix(3).map { "\($0.success ? "✅" : "❌") \($0.testName)" }.joined(separator: "\n")
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            topViewController.present(alert, animated: true)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let sdkReadyForTesting = Notification.Name("sdkReadyForTesting")
    static let pushNotificationProcessed = Notification.Name("pushNotificationProcessed")
    static let inAppMessageDisplayed = Notification.Name("inAppMessageDisplayed")
    static let inAppMessageInteracted = Notification.Name("inAppMessageInteracted")
    static let deepLinkProcessed = Notification.Name("deepLinkProcessed")
}

// MARK: - UIViewController Extension

extension UIViewController {
    
    func setupIntegrationTestMode() {
        if IntegrationTestHelper.shared.isInTestMode() {
            // Add test UI elements
            IntegrationTestHelper.shared.addTestButtons(to: self)
            
            // Add accessibility identifiers for automated testing
            view.accessibilityIdentifier = "main-view"
            
            // Add test mode indicator
            let testLabel = UILabel()
            testLabel.text = "🧪 Test Mode"
            testLabel.backgroundColor = UIColor.systemYellow
            testLabel.textAlignment = .center
            testLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            testLabel.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(testLabel)
            
            NSLayoutConstraint.activate([
                testLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                testLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                testLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                testLabel.heightAnchor.constraint(equalToConstant: 30)
            ])
        }
    }
}