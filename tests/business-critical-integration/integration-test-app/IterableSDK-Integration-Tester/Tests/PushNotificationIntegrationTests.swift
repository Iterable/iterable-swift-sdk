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
        
        // Give it 4 seconds to register and update status
        sleep(4)
        
        // Step 4.5: Navigate back to push notification screen if we ended up on home screen
        if !authStatusValue.exists && pushNotificationRow.exists {
            print("🔄 Navigating back to push notification screen after permission dialog")
            pushNotificationRow.tap()
            screenshotCapture.captureScreenshot(named: "04.5-back-to-push-screen")
        }
        
        // Step 5: Wait for status to update to authorized and token to be registered
        let authorizedPredicate = NSPredicate(format: "label == %@", "✓ Authorized")
        let authExpectation = XCTNSPredicateExpectation(predicate: authorizedPredicate, object: authStatusValue)
        XCTAssertEqual(XCTWaiter.wait(for: [authExpectation], timeout: 10.0), .completed, "Authorization should become 'Authorized'")
        
         let tokenRegisteredPredicate = NSPredicate(format: "label == %@", "✓ Registered")
         let tokenExpectation = XCTNSPredicateExpectation(predicate: tokenRegisteredPredicate, object: deviceTokenValue)
         XCTAssertEqual(XCTWaiter.wait(for: [tokenExpectation], timeout: 10.0), .completed, "Device token should become 'Registered'")
        screenshotCapture.captureScreenshot(named: "05-status-updated")
        
        // Step 6: Navigate to Network tab to verify register device token API call was made
        if fastTest == false {
            navigateToNetworkMonitor()
            screenshotCapture.captureScreenshot(named: "06-network-tab-opened")
            
            // Verify register device token call was made with 200 status
            verifyNetworkCallWithSuccess(endpoint: "registerDeviceToken", description: "Register device token API call should be made with 200 status")
            screenshotCapture.captureScreenshot(named: "07-register-token-call-verified")
            
            // Navigate back to home
            let closeNetworkButton = app.buttons["Close"]
            if closeNetworkButton.exists {
                closeNetworkButton.tap()
            }
        }
        
        sleep(2) // Wait a bit before navigating to backend
        
        navigateToBackendTab()
        screenshotCapture.captureScreenshot(named: "08-backend-tab-opened")

        if fastTest == false {
            
            // Step 8: Refresh backend status and verify device is registered
            let refreshButton = app.buttons["refresh-backend-status-button"]
            if refreshButton.waitForExistence(timeout: standardTimeout) {
                refreshButton.tap()
                sleep(2) // Wait for backend data to load
            }
            
            // Verify "This Device" appears in the backend device list
            // This is the key indicator that the current device is registered
            let thisDeviceIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'This Device'"))
            XCTAssertTrue(thisDeviceIndicator.firstMatch.waitForExistence(timeout: standardTimeout), "Backend should show 'This Device' indicating current device is registered")
            
            
            // Also verify there are enabled devices shown
            let enabledDevicesHeader = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Enabled Devices'"))
            XCTAssertTrue(enabledDevicesHeader.firstMatch.waitForExistence(timeout: standardTimeout), "Backend should show 'Enabled Devices' section")
            
            print("✅ Device registration validated - 'This Device' found in backend")
            screenshotCapture.captureScreenshot(named: "09-backend-device-verified")
            
            // Step 9: Test push notification from backend
            let testPushButton = app.buttons["test-push-notification-button"]
            XCTAssertTrue(testPushButton.waitForExistence(timeout: standardTimeout), "Test push notification button should exist")
            testPushButton.tap()
            screenshotCapture.captureScreenshot(named: "10-test-push-sent")
            
            // Step 9.5: Handle the "Success" popup by pressing OK
            let successAlert = app.alerts.firstMatch
            if successAlert.waitForExistence(timeout: 5.0) {
                let okButton = successAlert.buttons["OK"]
                if okButton.exists {
                    okButton.tap()
                    screenshotCapture.captureScreenshot(named: "10.5-success-popup-dismissed")
                }
            }
            
            // Step 10: Verify push notification was received
            // Actively wait for push notification instead of sleeping
            validateSpecificPushNotificationReceived(expectedTitle: "Integration Test", expectedBody: "This is an integration test simple push")
            screenshotCapture.captureScreenshot(named: "11-push-notification-received")
        }
        
        // Step 11: Test deep link push notification flow
        print("🔗 Starting deep link push notification test...")
        
        // Navigate back to backend tab (should already be there)
        screenshotCapture.captureScreenshot(named: "12-backend-tab-for-deep-link")
        
        // Send deep link push notification using campaign 14695444
        let deepLinkPushButton = app.buttons["test-deep-link-push-button"]
        XCTAssertTrue(deepLinkPushButton.waitForExistence(timeout: standardTimeout), "Deep link push button should exist")
        XCTAssertTrue(deepLinkPushButton.isEnabled, "Deep link push button should be enabled")
        deepLinkPushButton.tap()
        screenshotCapture.captureScreenshot(named: "13-deep-link-push-sent")
        
        // Handle success alert: "Success - Deep link push notification sent successfully! Campaign ID: 14695444"
        let deepLinkSuccessAlert = app.alerts["Success"]
        XCTAssertTrue(deepLinkSuccessAlert.waitForExistence(timeout: 5.0), "Success alert should appear")
        
        // Verify the alert message contains the campaign ID
        let deepLinkSuccessMessage = deepLinkSuccessAlert.staticTexts.element(boundBy: 1)
        XCTAssertTrue(deepLinkSuccessMessage.label.contains("14695444"), "Success message should contain campaign ID 14695444")
        
        let deepLinkSuccessOKButton = deepLinkSuccessAlert.buttons["OK"]
        XCTAssertTrue(deepLinkSuccessOKButton.exists, "Success alert OK button should exist")
        deepLinkSuccessOKButton.tap()
        screenshotCapture.captureScreenshot(named: "14-success-alert-dismissed")
        
        // Wait for deep link push notification to arrive and validate its content
        print("🔔 Waiting for deep link push notification to arrive...")
        
        // Validate the deep link push notification content and tap it
        validateSpecificPushNotificationReceived(expectedTitle: "Integration Test", expectedBody: "This is an enhanced push campaign")
        screenshotCapture.captureScreenshot(named: "14.5-deep-link-push-received")
        
        // The validateSpecificPushNotificationReceived method will automatically tap the push notification
        // This will trigger the deep link and open the app
        
        // Verify deep link alert appears: "Iterable Deep Link Opened"
        let deepLinkAlert = app.alerts["Iterable Deep Link Opened"]
        XCTAssertTrue(deepLinkAlert.waitForExistence(timeout: 10.0), "Iterable deep link alert should appear")
        
        let deepLinkMessage = deepLinkAlert.staticTexts.element(boundBy: 1)
        XCTAssertTrue(deepLinkMessage.label.contains("tester://"), "Deep link alert should contain tester:// URL")
        
        screenshotCapture.captureScreenshot(named: "15-deep-link-alert-shown")
        
        // Dismiss the deep link alert
        let deepLinkOKButton = deepLinkAlert.buttons["OK"]
        XCTAssertTrue(deepLinkOKButton.exists, "Deep link alert OK button should exist")
        deepLinkOKButton.tap()
        screenshotCapture.captureScreenshot(named: "16-deep-link-alert-dismissed")
        
        // Close the backend tab
        let closeButton = app.buttons["backend-close-button"]
        closeButton.tap()
        screenshotCapture.captureScreenshot(named: "17-backend-tab-closed")
        
        // Navigate to Network tab to verify trackPushOpen was called
        if fastTest == false {
            // Wait a moment for UI to settle after closing backend
            sleep(1)
            
            navigateToNetworkMonitor()
            screenshotCapture.captureScreenshot(named: "18-network-tab-opened")
            
            // Verify trackPushOpen call was made with 200 status for the deep link push
            verifyNetworkCallWithSuccess(endpoint: "trackPushOpen", description: "Track push open API call should be made for deep link push")
            screenshotCapture.captureScreenshot(named: "19-track-push-open-verified")
            
            // Close network monitor
            let closeNetworkButton = app.buttons["Close"]
            if closeNetworkButton.exists {
                closeNetworkButton.tap()
                screenshotCapture.captureScreenshot(named: "20-network-tab-closed")
            }
        }
        
        print("✅ Complete push notification workflow with deep link test completed successfully")
    }
    

    
}
