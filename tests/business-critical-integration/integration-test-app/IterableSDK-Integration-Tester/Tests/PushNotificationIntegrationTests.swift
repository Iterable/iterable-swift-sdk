import XCTest
import UserNotifications
@testable import IterableSDK

class PushNotificationIntegrationTests: IntegrationTestBase {
    
    // MARK: - Test Cases
    
    func testPushNotificationFullWorkflow() {
        // Test complete push notification workflow from registration to tracking
        
        // Step 1: Launch app and verify automatic device registration
        validateSDKInitialization()
        screenshotCapture.captureScreenshot(named: "01-app-launched")
        
        // Step 2: Request notification permissions
        let permissionButton = app.buttons["request-notification-permission"]
        XCTAssertTrue(permissionButton.waitForExistence(timeout: standardTimeout))
        permissionButton.tap()
        
        waitForNotificationPermission()
        screenshotCapture.captureScreenshot(named: "02-permission-granted")
        
        // Step 3: Validate device token registration API call
        XCTAssertTrue(waitForAPICall(endpoint: "/api/users/registerDeviceToken", timeout: networkTimeout))
        
        // Step 4: Verify device token stored in Iterable backend
        let expectation = XCTestExpectation(description: "Verify device registration")
        apiClient.verifyDeviceRegistration(userEmail: testUserEmail) { success, deviceToken in
            XCTAssertTrue(success, "Device registration verification failed")
            XCTAssertNotNil(deviceToken, "Device token not found in backend")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: networkTimeout)
        
        // Step 5: Send test push notification using server key
        let pushPayload: [String: Any] = [
            "messageId": "test-push-\(Date().timeIntervalSince1970)",
            "campaignId": "integration-test-campaign",
            "templateId": "integration-test-template",
            "isGhostPush": false,
            "contentAvailable": true,
            "data": [
                "actionButton": [
                    "identifier": "test-action",
                    "buttonText": "Open App",
                    "openApp": true,
                    "action": [
                        "type": "openUrl",
                        "data": "https://links.iterable.com/u/click?_t=test&_m=integration"
                    ]
                ]
            ]
        ]
        
        sendTestPushNotification(payload: pushPayload)
        screenshotCapture.captureScreenshot(named: "03-push-sent")
        
        // Step 6: Validate push notification received and displayed
        validatePushNotificationReceived()
        
        // Step 7: Test push notification tap and deep link handling
        let notification = app.alerts.firstMatch
        if notification.exists {
            notification.tap()
        } else {
            // Handle alert-style notification
            let alert = app.alerts.firstMatch
            let openButton = alert.buttons["Open"]
            if openButton.exists {
                openButton.tap()
            }
        }
        
        screenshotCapture.captureScreenshot(named: "04-push-tapped")
        
        // Step 8: Verify push open tracking metrics in backend
        sleep(5) // Allow time for tracking to process
        validateMetrics(eventType: "pushOpen", expectedCount: 1)
        
        // Step 9: Test deep link handling from push
        validateDeepLinkHandled(expectedDestination: "deep-link-destination-view")
        
        screenshotCapture.captureScreenshot(named: "05-deep-link-handled")
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
