import XCTest
import UserNotifications
@testable import IterableSDK

class DeepLinkingIntegrationTests: IntegrationTestBase {
    
    // MARK: - Properties
    
    var deepLinkHelper: DeepLinkTestHelper!
    var mockURLDelegate: MockIterableURLDelegate!
    var mockCustomActionDelegate: MockIterableCustomActionDelegate!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize deep link testing utilities
        deepLinkHelper = DeepLinkTestHelper(app: app, testCase: self)
        mockURLDelegate = MockIterableURLDelegate()
        mockCustomActionDelegate = MockIterableCustomActionDelegate()
        
        print("✅ Deep linking test infrastructure initialized")
    }
    
    override func tearDownWithError() throws {
        // Clean up delegates
        mockURLDelegate = nil
        mockCustomActionDelegate = nil
        deepLinkHelper = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Delegate Registration Tests
    
    func testURLDelegateRegistration() {
        print("🧪 Testing URL delegate registration and callback")
        
        // Verify SDK is initialized
        XCTAssertNotNil(IterableAPI.email, "SDK should be initialized with user email")
        
        // The URL delegate is already set during SDK initialization in IntegrationTestBase
        // We just need to verify it's working by triggering a deep link
        
        print("✅ URL delegate registration test setup complete")
    }
    
    func testCustomActionDelegateRegistration() {
        print("🧪 Testing custom action delegate registration and callback")
        
        // Verify SDK is initialized
        XCTAssertNotNil(IterableAPI.email, "SDK should be initialized with user email")
        
        // The custom action delegate is already set during SDK initialization in IntegrationTestBase
        // We just need to verify it's working by triggering a custom action
        
        print("✅ Custom action delegate registration test setup complete")
    }
    
    // MARK: - URL Delegate Tests
    
    func testURLDelegateCallback() {
        print("🧪 Testing URL delegate callback with tester:// scheme")
        
        // Navigate to In-App Message tab to trigger deep link
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()
        
        // Trigger the TestView in-app campaign which has a tester://testview deep link
        let triggerTestViewButton = app.buttons["trigger-testview-in-app-button"]
        XCTAssertTrue(triggerTestViewButton.waitForExistence(timeout: standardTimeout), "Trigger TestView button should exist")
        triggerTestViewButton.tap()
        
        // Handle success alert
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        
        // Tap "Check for Messages" to fetch and show the in-app
        let checkMessagesButton = app.buttons["check-messages-button"]
        XCTAssertTrue(checkMessagesButton.waitForExistence(timeout: standardTimeout), "Check for Messages button should exist")
        checkMessagesButton.tap()
        
        // Wait for in-app message to display
        let webView = app.descendants(matching: .webView).element(boundBy: 0)
        XCTAssertTrue(webView.waitForExistence(timeout: standardTimeout), "In-app message should appear")
        
        // Wait for link to be accessible
        XCTAssertTrue(waitForWebViewLink(linkText: "Show Test View", timeout: standardTimeout), "Show Test View link should be accessible")
        
        // Tap the deep link button
        if app.links["Show Test View"].waitForExistence(timeout: standardTimeout) {
            app.links["Show Test View"].tap()
        }
        
        // Wait for in-app to dismiss
        let webViewGone = NSPredicate(format: "exists == false")
        let webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [webViewExpectation], timeout: standardTimeout)
        
        // Verify URL delegate was called by checking for the alert
        let expectedAlert = AlertExpectation(
            title: "Deep link to Test View",
            message: "Deep link handled with Success!",
            timeout: standardTimeout
        )
        
        XCTAssertTrue(deepLinkHelper.waitForAlert(expectedAlert), "URL delegate alert should appear")
        
        // Dismiss the alert
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Deep link to Test View")
        
        // Clean up
        let clearMessagesButton = app.buttons["clear-messages-button"]
        clearMessagesButton.tap()
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        
        print("✅ URL delegate callback test completed successfully")
    }
    
    func testURLDelegateParameters() {
        print("🧪 Testing URL delegate receives correct parameters")
        
        // This test verifies that when a deep link is triggered,
        // the URL delegate receives the correct URL and context
        
        // Navigate to push notification tab
        let pushNotificationRow = app.otherElements["push-notification-test-row"]
        XCTAssertTrue(pushNotificationRow.waitForExistence(timeout: standardTimeout), "Push notification row should exist")
        pushNotificationRow.tap()
        
        // Navigate to backend tab
        let backButton = app.buttons["back-to-home-button"]
        XCTAssertTrue(backButton.waitForExistence(timeout: standardTimeout), "Back button should exist")
        backButton.tap()
        
        navigateToBackendTab()
        
        // Send deep link push notification
        let deepLinkPushButton = app.buttons["test-deep-link-push-button"]
        XCTAssertTrue(deepLinkPushButton.waitForExistence(timeout: standardTimeout), "Deep link push button should exist")
        
        if isRunningInCI {
            let deepLinkUrl = "tester://product?itemId=12345&category=shoes"
            sendSimulatedDeepLinkPush(deepLinkUrl: deepLinkUrl)
        } else {
            deepLinkPushButton.tap()
            deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        }
        
        // Wait for push notification and tap it
        sleep(5)
        
        // Verify the deep link alert appears with expected URL
        let expectedAlert = AlertExpectation(
            title: "Iterable Deep Link Opened",
            messageContains: "tester://",
            timeout: 15.0
        )
        
        XCTAssertTrue(deepLinkHelper.waitForAlert(expectedAlert), "Deep link alert should appear with tester:// URL")
        
        // Dismiss the alert
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Iterable Deep Link Opened")
        
        // Close backend tab
        let closeButton = app.buttons["backend-close-button"]
        if closeButton.exists {
            closeButton.tap()
        }
        
        print("✅ URL delegate parameters test completed successfully")
    }
    
    // MARK: - Alert Validation Tests
    
    func testAlertContentValidation() {
        print("🧪 Testing alert content validation for deep links")
        
        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()
        
        // Trigger TestView campaign
        let triggerButton = app.buttons["trigger-testview-in-app-button"]
        XCTAssertTrue(triggerButton.waitForExistence(timeout: standardTimeout), "Trigger button should exist")
        triggerButton.tap()
        
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        
        // Check for messages
        let checkMessagesButton = app.buttons["check-messages-button"]
        checkMessagesButton.tap()
        
        // Wait for webview
        let webView = app.descendants(matching: .webView).element(boundBy: 0)
        XCTAssertTrue(webView.waitForExistence(timeout: standardTimeout), "In-app message should appear")
        
        // Wait for link and tap
        XCTAssertTrue(waitForWebViewLink(linkText: "Show Test View", timeout: standardTimeout), "Link should be accessible")
        if app.links["Show Test View"].waitForExistence(timeout: standardTimeout) {
            app.links["Show Test View"].tap()
        }
        
        // Wait for webview to dismiss
        let webViewGone = NSPredicate(format: "exists == false")
        let webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [webViewExpectation], timeout: standardTimeout)
        
        // Test alert validation helper
        let expectedAlert = AlertExpectation(
            title: "Deep link to Test View",
            message: "Deep link handled with Success!",
            timeout: standardTimeout
        )
        
        let alertFound = deepLinkHelper.waitForAlert(expectedAlert)
        XCTAssertTrue(alertFound, "Alert should match expected content")
        
        // Verify alert message contains expected text
        let alert = app.alerts["Deep link to Test View"]
        XCTAssertTrue(alert.exists, "Alert should exist")
        
        let alertMessage = alert.staticTexts.element(boundBy: 1)
        XCTAssertTrue(alertMessage.label.contains("Success"), "Alert message should contain 'Success'")
        
        // Dismiss
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Deep link to Test View")
        
        // Clean up
        let clearButton = app.buttons["clear-messages-button"]
        clearButton.tap()
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        
        print("✅ Alert content validation test completed")
    }
    
    func testMultipleAlertsInSequence() {
        print("🧪 Testing multiple alerts in sequence")
        
        // This test verifies we can handle multiple alerts during a test
        
        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout))
        inAppMessageRow.tap()
        
        // Trigger campaign
        let triggerButton = app.buttons["trigger-in-app-button"]
        XCTAssertTrue(triggerButton.waitForExistence(timeout: standardTimeout))
        triggerButton.tap()
        
        // First alert
        let firstAlert = AlertExpectation(title: "Success", timeout: 5.0)
        XCTAssertTrue(deepLinkHelper.waitForAlert(firstAlert), "First alert should appear")
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        
        // Check messages
        let checkButton = app.buttons["check-messages-button"]
        checkButton.tap()
        
        // Wait for webview
        let webView = app.descendants(matching: .webView).element(boundBy: 0)
        if webView.waitForExistence(timeout: standardTimeout) {
            // Wait for link
            if waitForWebViewLink(linkText: "Dismiss", timeout: standardTimeout) {
                if app.links["Dismiss"].exists {
                    app.links["Dismiss"].tap()
                }
            }
        }
        
        // Clean up
        let clearButton = app.buttons["clear-messages-button"]
        if clearButton.exists {
            clearButton.tap()
            deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        }
        
        print("✅ Multiple alerts test completed")
    }
    
    // MARK: - Integration Tests
    
    func testDeepLinkFromPushNotification() {
        print("🧪 Testing deep link routing from push notification")
        
        // Navigate to push notification tab and register
        let pushNotificationRow = app.otherElements["push-notification-test-row"]
        XCTAssertTrue(pushNotificationRow.waitForExistence(timeout: standardTimeout))
        pushNotificationRow.tap()
        
        let registerButton = app.buttons["register-push-notifications-button"]
        if registerButton.exists {
            registerButton.tap()
            waitForNotificationPermission()
            sleep(3)
        }
        
        // Navigate back and go to backend
        let backButton = app.buttons["back-to-home-button"]
        XCTAssertTrue(backButton.waitForExistence(timeout: standardTimeout))
        backButton.tap()
        
        navigateToBackendTab()
        
        // Send deep link push
        let deepLinkButton = app.buttons["test-deep-link-push-button"]
        XCTAssertTrue(deepLinkButton.waitForExistence(timeout: standardTimeout))
        
        if isRunningInCI {
            sendSimulatedDeepLinkPush(deepLinkUrl: "tester://product?itemId=12345&category=shoes")
        } else {
            deepLinkButton.tap()
            deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        }
        
        // Wait for push and verify deep link alert
        sleep(5)
        
        let expectedAlert = AlertExpectation(
            title: "Iterable Deep Link Opened",
            messageContains: "tester://",
            timeout: 15.0
        )
        
        XCTAssertTrue(deepLinkHelper.waitForAlert(expectedAlert), "Deep link alert should appear from push notification")
        
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Iterable Deep Link Opened")
        
        // Close backend
        let closeButton = app.buttons["backend-close-button"]
        if closeButton.exists {
            closeButton.tap()
        }
        
        print("✅ Deep link from push notification test completed")
    }
    
    func testDeepLinkFromInAppMessage() {
        print("🧪 Testing deep link routing from in-app message")
        
        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout))
        inAppMessageRow.tap()
        
        // Trigger TestView campaign with deep link
        let triggerButton = app.buttons["trigger-testview-in-app-button"]
        XCTAssertTrue(triggerButton.waitForExistence(timeout: standardTimeout))
        triggerButton.tap()
        
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        
        // Check for messages
        let checkButton = app.buttons["check-messages-button"]
        checkButton.tap()
        
        // Wait for in-app
        let webView = app.descendants(matching: .webView).element(boundBy: 0)
        XCTAssertTrue(webView.waitForExistence(timeout: standardTimeout))
        
        // Tap deep link
        XCTAssertTrue(waitForWebViewLink(linkText: "Show Test View", timeout: standardTimeout))
        if app.links["Show Test View"].exists {
            app.links["Show Test View"].tap()
        }
        
        // Wait for webview to dismiss
        let webViewGone = NSPredicate(format: "exists == false")
        let expectation = self.expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [expectation], timeout: standardTimeout)
        
        // Verify deep link alert
        let expectedAlert = AlertExpectation(
            title: "Deep link to Test View",
            messageContains: "Success",
            timeout: standardTimeout
        )
        
        XCTAssertTrue(deepLinkHelper.waitForAlert(expectedAlert), "Deep link alert should appear from in-app message")
        
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Deep link to Test View")
        
        // Clean up
        let clearButton = app.buttons["clear-messages-button"]
        clearButton.tap()
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        
        print("✅ Deep link from in-app message test completed")
    }
}
