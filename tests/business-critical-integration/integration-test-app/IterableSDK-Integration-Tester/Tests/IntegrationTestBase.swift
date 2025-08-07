import XCTest
import Foundation
@testable import IterableSDK

class IntegrationTestBase: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    var testConfig: TestConfiguration!
    var apiClient: IterableAPIClient!
    var metricsValidator: MetricsValidator!
    var screenshotCapture: ScreenshotCapture!
    
    // Test data
    var testUserEmail: String!
    var testProjectId: String!
    var apiKey: String!
    var serverKey: String!
    
    // Timeouts
    let standardTimeout: TimeInterval = 30.0
    let longTimeout: TimeInterval = 60.0
    let networkTimeout: TimeInterval = 45.0
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        // Initialize test configuration
        setupTestConfiguration()
        
        // Initialize app with test configuration
        setupTestApplication()
        
        // Initialize backend clients
        setupBackendClients()
        
        // Initialize utilities
        setupUtilities()
        
        // Start fresh for each test
        app.launch()
        
        // Wait for app to be ready
        waitForAppToBeReady()
        
        // Initialize SDK with test configuration
        initializeSDKForTesting()
    }
    
    override func tearDownWithError() throws {
        // Capture final screenshot
        screenshotCapture?.captureScreenshot(named: "final-\(name)")
        
        // Clean up test data
        cleanupTestData()
        
        // Terminate app
        app?.terminate()
        
        try super.tearDownWithError()
    }
    
    // MARK: - Setup Helpers
    
    private func setupTestConfiguration() {
        // Load configuration from test-config.json
        guard let configData = loadTestConfig() else {
            XCTFail("Failed to load test-config.json")
            return
        }
        
        testUserEmail = configData["testUserEmail"] as? String ?? "integration-test@iterable.com"
        testProjectId = configData["projectId"] as? String ?? "test-project"
        apiKey = configData["mobileApiKey"] as? String ?? ""
        serverKey = configData["serverApiKey"] as? String ?? ""
        
        XCTAssertFalse(apiKey.isEmpty, "mobileApiKey must be set in test-config.json")
        XCTAssertFalse(testProjectId.isEmpty, "projectId must be set in test-config.json")
        
        // Load test configuration
        testConfig = TestConfiguration(
            apiKey: apiKey,
            serverKey: serverKey,
            projectId: testProjectId,
            userEmail: testUserEmail
        )
    }
    
    private func setupTestApplication() {
        app = XCUIApplication()
        
        // Set launch arguments for test configuration
        app.launchArguments = [
            "-INTEGRATION_TEST_MODE", "YES",
            "-API_KEY", apiKey,
            "-TEST_USER_EMAIL", testUserEmail,
            "-TEST_PROJECT_ID", testProjectId
        ]
        
        // Set launch environment
        app.launchEnvironment = [
            "INTEGRATION_TEST": "1",
            "API_ENDPOINT": testConfig.apiEndpoint,
            "ENABLE_LOGGING": "1"
        ]
    }
    
    private func setupBackendClients() {
        apiClient = IterableAPIClient(
            apiKey: apiKey,
            serverKey: serverKey,
            projectId: testProjectId
        )
        
        metricsValidator = MetricsValidator(
            apiClient: apiClient,
            userEmail: testUserEmail
        )
    }
    
    private func setupUtilities() {
        screenshotCapture = ScreenshotCapture(testCase: self)
    }
    
    private func loadTestConfig() -> [String: Any]? {
        guard let path = Bundle(for: type(of: self)).path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Could not load test-config.json")
            return nil
        }
        print("✅ Loaded test configuration from test-config.json")
        return json
    }
    
    private func waitForAppToBeReady() {
        let readyIndicator = app.staticTexts["app-ready-indicator"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: readyIndicator, handler: nil)
        waitForExpectations(timeout: standardTimeout, handler: nil)
    }
    
    private func initializeSDKForTesting() {
        // Tap the initialize SDK button in test app
        let initializeButton = app.buttons["initialize-sdk-button"]
        XCTAssertTrue(initializeButton.waitForExistence(timeout: standardTimeout))
        initializeButton.tap()
        
        // Wait for SDK initialization to complete
        let sdkReadyIndicator = app.staticTexts["sdk-ready-indicator"]
        XCTAssertTrue(sdkReadyIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "sdk-initialized")
    }
    
    // MARK: - Test Helpers
    
    func waitForAPICall(endpoint: String, timeout: TimeInterval = 30.0) -> Bool {
        let predicate = NSPredicate { _, _ in
            return self.apiClient.hasReceivedCall(to: endpoint)
        }
        
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    func waitForNotificationPermission() {
        let allowButton = app.alerts.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 5.0) {
            allowButton.tap()
        }
    }
    
    func sendTestPushNotification(payload: [String: Any]) {
        let expectation = XCTestExpectation(description: "Send push notification")
        
        apiClient.sendPushNotification(
            to: testUserEmail,
            payload: payload
        ) { success, error in
            XCTAssertTrue(success, "Failed to send push notification: \(error?.localizedDescription ?? "Unknown error")")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: networkTimeout)
    }
    
    func validateMetrics(eventType: String, expectedCount: Int = 1) {
        let expectation = XCTestExpectation(description: "Validate metrics")
        
        metricsValidator.validateEventCount(
            eventType: eventType,
            expectedCount: expectedCount,
            timeout: networkTimeout
        ) { success, actualCount in
            XCTAssertTrue(success, "Metrics validation failed. Expected \(expectedCount) \(eventType) events, got \(actualCount)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: networkTimeout)
    }
    
    func simulateAppBackground() {
        XCUIDevice.shared.press(.home)
        sleep(2)
    }
    
    func simulateAppForeground() {
        app.activate()
        sleep(1)
    }
    
    func triggerDeepLink(url: String) {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()
        
        let urlTextField = safari.textFields["URL"]
        urlTextField.tap()
        urlTextField.typeText(url)
        safari.keyboards.buttons["Go"].tap()
        
        // Wait for redirect to our app
        sleep(3)
        
        // Verify our app is in foreground
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: standardTimeout))
    }
    
    // MARK: - Validation Helpers
    
    func validateSDKInitialization() {
        // Verify SDK is properly initialized
        XCTAssertTrue(app.staticTexts["sdk-ready-indicator"].exists)
        XCTAssertTrue(waitForAPICall(endpoint: "/api/users/registerDeviceToken"))
    }
    
    func validatePushNotificationReceived() {
        // For integration tests, we'll check for push notification indicators in the app
        // rather than system-level banners which are complex to test
        let pushIndicator = app.staticTexts["push-notification-processed"]
        XCTAssertTrue(pushIndicator.waitForExistence(timeout: standardTimeout), "No push notification received")
        
        screenshotCapture.captureScreenshot(named: "push-notification-received")
    }
    
    func validateInAppMessageDisplayed() {
        let inAppMessage = app.otherElements["iterable-in-app-message"]
        XCTAssertTrue(inAppMessage.waitForExistence(timeout: standardTimeout), "In-app message not displayed")
        
        screenshotCapture.captureScreenshot(named: "in-app-message-displayed")
    }
    
    func validateEmbeddedMessageDisplayed() {
        let embeddedMessage = app.otherElements["iterable-embedded-message"]
        XCTAssertTrue(embeddedMessage.waitForExistence(timeout: standardTimeout), "Embedded message not displayed")
        
        screenshotCapture.captureScreenshot(named: "embedded-message-displayed")
    }
    
    func validateDeepLinkHandled(expectedDestination: String) {
        let destinationView = app.otherElements[expectedDestination]
        XCTAssertTrue(destinationView.waitForExistence(timeout: standardTimeout), "Deep link destination not reached")
        
        screenshotCapture.captureScreenshot(named: "deep-link-handled")
    }
    
    // MARK: - Cleanup
    
    private func cleanupTestData() {
        // Remove test user from backend
        let expectation = XCTestExpectation(description: "Cleanup test data")
        
        apiClient.cleanupTestUser(email: testUserEmail) { success in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: networkTimeout)
    }
}

// MARK: - Test Configuration

struct TestConfiguration {
    let apiKey: String
    let serverKey: String
    let projectId: String
    let userEmail: String
    let apiEndpoint: String
    
    init(apiKey: String, serverKey: String, projectId: String, userEmail: String) {
        self.apiKey = apiKey
        self.serverKey = serverKey
        self.projectId = projectId
        self.userEmail = userEmail
        self.apiEndpoint = "https://api.iterable.com"
    }
}

// MARK: - Extensions

extension XCUIApplication {
    func wait(for state: XCUIApplication.State, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "state == %d", state.rawValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
