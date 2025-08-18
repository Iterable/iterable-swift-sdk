import XCTest
import UserNotifications

class PushNotificationIntegrationTests: IntegrationTestBase {
    
    // MARK: - Test Cases
    
    func testPushNotificationFullWorkflow() {
        // Test complete push notification workflow: status check → registration → token copy → backend validation
        
        // Step 1: Navigate to Push Notification tab
        let pushNotificationRow = app.otherElements["push-notification-test-row"]
        XCTAssertTrue(pushNotificationRow.waitForExistence(timeout: standardTimeout), "Push notification row should exist")
        pushNotificationRow.tap()
        screenshotCapture.captureScreenshot(named: "01-push-tab-opened")
        
        // Step 2: Verify initial push notification status (should be "Not Determined")
        let authStatusValue = app.staticTexts["push-authorization-value"]
        XCTAssertTrue(authStatusValue.waitForExistence(timeout: standardTimeout), "Authorization status should exist")
        XCTAssertEqual(authStatusValue.label, "? Not Determined", "Initial authorization should be 'Not Determined'")
        
        let deviceTokenValue = app.staticTexts["push-device-token-value"]
        XCTAssertTrue(deviceTokenValue.waitForExistence(timeout: standardTimeout), "Device token status should exist")
        XCTAssertEqual(deviceTokenValue.label, "✗ Not Registered", "Initial device token should be 'Not Registered'")
        screenshotCapture.captureScreenshot(named: "02-initial-status-verified")
        
        // Step 3: Register for push notifications
        let registerButton = app.buttons["register-push-notifications-button"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: standardTimeout), "Register button should exist")
        registerButton.tap()
        screenshotCapture.captureScreenshot(named: "03-register-button-tapped")
        
        // Step 4: Wait for system permission dialog to be automatically handled
        waitForNotificationPermission()
        screenshotCapture.captureScreenshot(named: "04-permission-handled")
        
        // Step 5: Wait for status to update to authorized and token to be registered
        let authorizedPredicate = NSPredicate(format: "label == %@", "✓ Authorized")
        let authExpectation = XCTNSPredicateExpectation(predicate: authorizedPredicate, object: authStatusValue)
        XCTAssertEqual(XCTWaiter.wait(for: [authExpectation], timeout: 10.0), .completed, "Authorization should become 'Authorized'")
        
        let tokenRegisteredPredicate = NSPredicate(format: "label == %@", "✓ Registered")
        let tokenExpectation = XCTNSPredicateExpectation(predicate: tokenRegisteredPredicate, object: deviceTokenValue)
        XCTAssertEqual(XCTWaiter.wait(for: [tokenExpectation], timeout: 10.0), .completed, "Device token should become 'Registered'")
        screenshotCapture.captureScreenshot(named: "05-status-updated")
        
//        // Step 6: Copy device token to clipboard
//        let deviceTokenDetail = app.staticTexts["push-device-token-detail-value"]
//        XCTAssertTrue(deviceTokenDetail.waitForExistence(timeout: standardTimeout), "Device token detail should exist")
//        deviceTokenDetail.tap()
//        screenshotCapture.captureScreenshot(named: "06-token-copy-initiated")
//        
//        // Dismiss the copy confirmation alert
//        let copyAlert = app.alerts["Token Copied"]
//        if copyAlert.waitForExistence(timeout: 5.0) {
//            copyAlert.buttons["OK"].tap()
//        }
//        
//        // Step 7: Navigate to Backend tab to verify device registration
//        let backToHomeButton = app.buttons["back-to-home-button"]
//        XCTAssertTrue(backToHomeButton.waitForExistence(timeout: standardTimeout), "Back to home button should exist")
//        backToHomeButton.tap()
//        
//        // Navigate to backend (assuming we need to add navigation to backend tab)
//        navigateToBackendTab()
//        screenshotCapture.captureScreenshot(named: "07-backend-tab-opened")
//        
//        // Step 8: Verify device is registered and enabled in backend
//        validateDeviceRegistrationInBackend()
//        screenshotCapture.captureScreenshot(named: "08-backend-validation-complete")
//        
//        // Step 9: Validate device token matches between UI and backend
//        validateTokenMatchBetweenUIAndBackend()
//        screenshotCapture.captureScreenshot(named: "09-token-match-validated")
    }
    
    /*func testPushPermissionHandling() {
        // Test push notification permission edge cases
        
        // Test permission denied scenario
        let permissionButton = app.buttons["request-notification-permission"]
        XCTAssertTrue(permissionButton.waitForExistence(timeout: standardTimeout))
        permissionButton.tap()
        
        // Simulate permission denial
        let denyButton = app.alerts.buttons["Don't Allow"]
        if denyButton.waitForExistence(timeout: 5.0) {
            denyButton.tap()
        }
        
        screenshotCapture.captureScreenshot(named: "permission-denied")
        
        // Verify app handles permission denial gracefully
        let permissionDeniedLabel = app.staticTexts["permission-denied-message"]
        XCTAssertTrue(permissionDeniedLabel.waitForExistence(timeout: standardTimeout))
    }
    
    func testPushNotificationButtons() {
        // Test push notification action buttons and deep links
        
        validateSDKInitialization()
        
        // Request permissions
        let permissionButton = app.buttons["request-notification-permission"]
        permissionButton.tap()
        waitForNotificationPermission()
        
        // Send push with action buttons
        let pushWithButtonsPayload: [String: Any] = [
            "messageId": "test-push-buttons-\(Date().timeIntervalSince1970)",
            "actionButton": [
                "identifier": "view-offer",
                "buttonText": "View Offer",
                "openApp": true,
                "action": [
                    "type": "openUrl",
                    "data": "https://links.iterable.com/u/click?_t=offer&_m=integration"
                ]
            ],
            "defaultAction": [
                "type": "openUrl",
                "data": "https://links.iterable.com/u/click?_t=default&_m=integration"
            ]
        ]
        
        sendTestPushNotification(payload: pushWithButtonsPayload)
        
        // Interact with action button
        let actionButton = app.buttons["View Offer"]
        if actionButton.waitForExistence(timeout: standardTimeout) {
            actionButton.tap()
            screenshotCapture.captureScreenshot(named: "action-button-tapped")
        }
        
        // Validate button click tracking
        validateMetrics(eventType: "pushOpen", expectedCount: 1)
    }
    
    func testBackgroundPushHandling() {
        // Test push notification handling when app is in background
        
        validateSDKInitialization()
        
        // Request permissions
        let permissionButton = app.buttons["request-notification-permission"]
        permissionButton.tap()
        waitForNotificationPermission()
        
        // Put app in background
        simulateAppBackground()
        screenshotCapture.captureScreenshot(named: "app-backgrounded")
        
        // Send background push
        let backgroundPushPayload: [String: Any] = [
            "messageId": "test-background-push-\(Date().timeIntervalSince1970)",
            "contentAvailable": true,
            "isGhostPush": false
        ]
        
        sendTestPushNotification(payload: backgroundPushPayload)
        
        // Wait for background processing
        sleep(3)
        
        // Bring app to foreground
        simulateAppForeground()
        screenshotCapture.captureScreenshot(named: "app-foregrounded")
        
        // Verify background push was processed
        let backgroundProcessedIndicator = app.staticTexts["background-push-processed"]
        XCTAssertTrue(backgroundProcessedIndicator.waitForExistence(timeout: standardTimeout))
    }
    
    func testSilentPushHandling() {
        // Test silent push notification processing
        
        validateSDKInitialization()
        
        // Send silent push (no user-visible notification)
        let silentPushPayload: [String: Any] = [
            "messageId": "test-silent-push-\(Date().timeIntervalSince1970)",
            "contentAvailable": true,
            "isGhostPush": true,
            "silentPush": true
        ]
        
        sendTestPushNotification(payload: silentPushPayload)
        
        // Verify silent push was processed without user notification
        let silentProcessedIndicator = app.staticTexts["silent-push-processed"]
        XCTAssertTrue(silentProcessedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "silent-push-processed")
        
        // Verify no visible notification appeared
        XCTAssertFalse(app.alerts.firstMatch.exists)
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }
    
    func testPushDeliveryMetrics() {
        // Test comprehensive push delivery and interaction metrics
        
        validateSDKInitialization()
        
        // Request permissions
        let permissionButton = app.buttons["request-notification-permission"]
        permissionButton.tap()
        waitForNotificationPermission()
        
        // Send tracked push notification
        let trackedPushPayload: [String: Any] = [
            "messageId": "test-metrics-push-\(Date().timeIntervalSince1970)",
            "campaignId": "123456",
            "templateId": "789012",
            "trackingEnabled": true
        ]
        
        sendTestPushNotification(payload: trackedPushPayload)
        
        // Validate push delivery metrics
        validateMetrics(eventType: "pushSend", expectedCount: 1)
        
        // Tap the notification to generate open event
        let notification = app.alerts.firstMatch
        if notification.waitForExistence(timeout: standardTimeout) {
            notification.tap()
        }
        
        // Validate push open metrics
        validateMetrics(eventType: "pushOpen", expectedCount: 1)
        
        screenshotCapture.captureScreenshot(named: "push-metrics-validated")
    }
    
    func testPushWithCustomData() {
        // Test push notifications with custom data payload
        
        validateSDKInitialization()
        
        // Request permissions
        let permissionButton = app.buttons["request-notification-permission"]
        permissionButton.tap()
        waitForNotificationPermission()
        
        // Send push with custom data
        let customDataPushPayload: [String: Any] = [
            "messageId": "test-custom-data-\(Date().timeIntervalSince1970)",
            "data": [
                "customField1": "value1",
                "customField2": "value2",
                "productId": "12345",
                "category": "electronics"
            ],
            "customPayload": [
                "userId": testUserEmail ?? "test@example.com",
                "action": "view_product",
                "metadata": [
                    "source": "integration_test",
                    "timestamp": Date().timeIntervalSince1970
                ]
            ]
        ]
        
        sendTestPushNotification(payload: customDataPushPayload)
        
        // Tap notification to process custom data
        let notification = app.alerts.firstMatch
        if notification.waitForExistence(timeout: standardTimeout) {
            notification.tap()
        }
        
        // Verify custom data was processed correctly
        let customDataProcessedIndicator = app.staticTexts["custom-data-processed"]
        XCTAssertTrue(customDataProcessedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "custom-data-processed")
    }*/
}
