import XCTest
import UserNotifications

class InAppMessageIntegrationTests: IntegrationTestBase {
    
    // MARK: - Test Cases
    
    func testSilentPushIntegrationWorkflow() {
        // Test silent push notification workflow: status check → registration → token copy → backend silent push → alert validation
        
        // Step 1: Navigate to Push Notification tab to ensure device is registered
        let pushNotificationRow = app.otherElements["push-notification-test-row"]
        XCTAssertTrue(pushNotificationRow.waitForExistence(timeout: standardTimeout), "Push notification row should exist")
        pushNotificationRow.tap()
        screenshotCapture.captureScreenshot(named: "01-push-tab-opened")
        
        // Step 2: Verify device is already registered (skip registration if already done)
        let deviceTokenValue = app.staticTexts["push-device-token-value"]
        XCTAssertTrue(deviceTokenValue.waitForExistence(timeout: standardTimeout), "Device token status should exist")
        
        // If not registered, register first
        if deviceTokenValue.label == "✗ Not Registered" {
            let registerButton = app.buttons["register-push-notifications-button"]
            XCTAssertTrue(registerButton.waitForExistence(timeout: standardTimeout), "Register button should exist")
            registerButton.tap()
            screenshotCapture.captureScreenshot(named: "02-register-button-tapped")
            
            // Wait for system permission dialog to be automatically handled
            waitForNotificationPermission()
            screenshotCapture.captureScreenshot(named: "03-permission-handled")
            
            // Give it 4 seconds to register and update status
            sleep(4)
            
            // Navigate back to push notification screen if we ended up on home screen
            if !deviceTokenValue.exists && pushNotificationRow.exists {
                print("🔄 Navigating back to push notification screen after permission dialog")
                pushNotificationRow.tap()
                screenshotCapture.captureScreenshot(named: "04-back-to-push-screen")
            }
            
            // Wait for status to update to registered
            let tokenRegisteredPredicate = NSPredicate(format: "label == %@", "✓ Registered")
            let tokenExpectation = XCTNSPredicateExpectation(predicate: tokenRegisteredPredicate, object: deviceTokenValue)
            XCTAssertEqual(XCTWaiter.wait(for: [tokenExpectation], timeout: 10.0), .completed, "Device token should become 'Registered'")
            screenshotCapture.captureScreenshot(named: "05-device-registered")
        } else {
            print("✅ Device already registered, skipping registration")
            screenshotCapture.captureScreenshot(named: "02-device-already-registered")
        }
        
        // Step 3: Navigate to Backend tab
        navigateToBackendTab()
        
        // Check if backend tab actually opened by looking for the navigation title
        let backendTitle = app.navigationBars["Backend Status"]
        if !backendTitle.waitForExistence(timeout: 3.0) {
            print("⚠️ Backend tab didn't open, trying to tap backend button again")
            let backendButton = app.buttons["backend-tab"]
            if backendButton.exists {
                backendButton.tap()
                // Wait for backend tab to appear
                XCTAssertTrue(backendTitle.waitForExistence(timeout: 5.0), "Backend Status should open after second attempt")
            }
        }
        
        screenshotCapture.captureScreenshot(named: "06-backend-tab-opened")
        
        // Step 4: Refresh backend status to ensure we have user data
        let refreshButton = app.buttons["refresh-backend-status-button"]
        if refreshButton.waitForExistence(timeout: standardTimeout) {
            refreshButton.tap()
            sleep(2) // Wait for backend data to load
        }
        screenshotCapture.captureScreenshot(named: "07-backend-refreshed")
        
        // Step 5: Send silent push notification using campaign 14750476
        let silentPushButton = app.buttons["test-silent-push-button"]
        XCTAssertTrue(silentPushButton.waitForExistence(timeout: standardTimeout), "Silent push button should exist")
        XCTAssertTrue(silentPushButton.isEnabled, "Silent push button should be enabled")
        silentPushButton.tap()
        screenshotCapture.captureScreenshot(named: "08-silent-push-sent")
        
        // Step 6: Handle the "Success" popup by pressing OK
        let successAlert = app.alerts["Success"]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 5.0), "Success alert should appear")
        
        // Verify the alert message contains the campaign ID
        let successMessage = successAlert.staticTexts.element(boundBy: 1)
        XCTAssertTrue(successMessage.label.contains("14750476"), "Success message should contain campaign ID 14750476")
        
        let okButton = successAlert.buttons["OK"]
        XCTAssertTrue(okButton.exists, "Success alert OK button should exist")
        okButton.tap()
        screenshotCapture.captureScreenshot(named: "09-success-alert-dismissed")
        
        // Step 7: Wait for silent push notification to arrive and validate its content
        print("🔕 Waiting for silent push notification alert to appear...")
        
        // Look for the "Silent Push Received" alert
        let silentPushAlert = app.alerts["Silent Push Received"]
        XCTAssertTrue(silentPushAlert.waitForExistence(timeout: 15.0), "Silent push alert should appear")
        
        // Verify the alert message contains badge count information
        let silentPushMessage = silentPushAlert.staticTexts.element(boundBy: 1)
        XCTAssertTrue(silentPushMessage.label.contains("Silent push has been received with a badge count of"), "Silent push message should contain badge count text")
        
        print("✅ Silent push alert received with message: \(silentPushMessage.label)")
        screenshotCapture.captureScreenshot(named: "10-silent-push-alert-shown")
        
        // Dismiss the silent push alert
        let silentPushOKButton = silentPushAlert.buttons["OK"]
        XCTAssertTrue(silentPushOKButton.exists, "Silent push alert OK button should exist")
        silentPushOKButton.tap()
        screenshotCapture.captureScreenshot(named: "11-silent-push-alert-dismissed")
        
        // Step 8: Close the backend tab
        let closeButton = app.buttons["backend-close-button"]
        closeButton.tap()
        screenshotCapture.captureScreenshot(named: "12-backend-tab-closed")
        
        print("✅ Silent push integration test completed successfully")
    }
}