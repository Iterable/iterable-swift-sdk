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
        
        // Step 5: Check network monitor for registerDeviceToken call BEFORE verifying token status
        if fastTest == false {
            navigateToNetworkMonitor()
            
            // Check if network monitor actually opened by looking for the navigation title
            let networkMonitorTitle = app.navigationBars["Network Monitor"]
            if !networkMonitorTitle.waitForExistence(timeout: 3.0) {
                print("⚠️ Network monitor didn't open, trying to tap network button again")
                let networkButton = app.buttons["network-monitor-button"]
                if networkButton.exists {
                    networkButton.tap()
                    // Wait for network monitor to appear
                    XCTAssertTrue(networkMonitorTitle.waitForExistence(timeout: 5.0), "Network Monitor should open after second attempt")
                }
            }
            
            screenshotCapture.captureScreenshot(named: "05-network-tab-opened")
            
            // Wait up to 10 seconds for the registerDeviceToken call to appear in network monitor
            print("⏳ Waiting for registerDeviceToken network call to appear...")
            
            // Poll for the registerDeviceToken call for up to 10 seconds
            let endpointPredicate = NSPredicate(format: "label CONTAINS[c] %@", "registerDeviceToken")
            let endpointCell = app.cells.containing(endpointPredicate).firstMatch
            let callFoundExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: endpointCell)
            let waitResult = XCTWaiter.wait(for: [callFoundExpectation], timeout: 10.0)
            
            if waitResult == .completed {
                print("✅ Found registerDeviceToken network call")
                // Now verify it has 200 status
                verifyNetworkCallWithSuccess(endpoint: "registerDeviceToken", description: "Register device token API call should be made with 200 status")
            } else {
                XCTFail("❌ registerDeviceToken network call did not appear within 10 seconds")
            }
            screenshotCapture.captureScreenshot(named: "06-register-token-call-verified")
            
            // Navigate back to push notification screen
            let closeNetworkButton = app.buttons["Close"]
            if closeNetworkButton.exists {
                closeNetworkButton.tap()
            }
            
            // Give UI a moment to settle after closing network monitor
            sleep(1)
            
            // Check which screen we're on and navigate intelligently
            let authStatusElement = app.staticTexts["push-authorization-value"]
            if authStatusElement.exists {
                // We're already on the push notification screen
                print("✅ Already on push notification screen")
                screenshotCapture.captureScreenshot(named: "07-already-on-push-screen")
            } else {
                // We're on the home screen, need to navigate to push notification tab
                print("🔄 On home screen, navigating to push notification tab")
                let pushNotificationRowRefresh = app.otherElements["push-notification-test-row"]
                XCTAssertTrue(pushNotificationRowRefresh.waitForExistence(timeout: 5.0), "Push notification row should exist on home screen")
                pushNotificationRowRefresh.tap()
                screenshotCapture.captureScreenshot(named: "07-back-to-push-screen")
            }
        }
        
        // Step 6: Wait for status to update to authorized and token to be registered
        // Re-find the status elements in case we navigated away and back
        let authStatusValueRefresh = app.staticTexts["push-authorization-value"]
        let deviceTokenValueRefresh = app.staticTexts["push-device-token-value"]
        
        let authorizedPredicate = NSPredicate(format: "label == %@", "✓ Authorized")
        let authExpectation = XCTNSPredicateExpectation(predicate: authorizedPredicate, object: authStatusValueRefresh)
        XCTAssertEqual(XCTWaiter.wait(for: [authExpectation], timeout: 10.0), .completed, "Authorization should become 'Authorized'")
        
         let tokenRegisteredPredicate = NSPredicate(format: "label == %@", "✓ Registered")
         let tokenExpectation = XCTNSPredicateExpectation(predicate: tokenRegisteredPredicate, object: deviceTokenValueRefresh)
         XCTAssertEqual(XCTWaiter.wait(for: [tokenExpectation], timeout: 10.0), .completed, "Device token should become 'Registered'")
        screenshotCapture.captureScreenshot(named: "08-status-updated")
        
        sleep(2) // Wait a bit before navigating to backend
        
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
        
        screenshotCapture.captureScreenshot(named: "09-backend-tab-opened")

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
            screenshotCapture.captureScreenshot(named: "10-backend-device-verified")
            
            // Step 9: Test push notification from backend
            let testPushButton = app.buttons["test-push-notification-button"]
            XCTAssertTrue(testPushButton.waitForExistence(timeout: standardTimeout), "Test push notification button should exist")
            
            if isRunningInCI {
                print("🤖 [TEST] CI MODE ACTIVATED: Sending simulated standard push notification")
                print("🎭 [TEST] This will use xcrun simctl instead of real backend API call")
                // Create standard push payload for CI testing (matching real Iterable format)
                let pushPayload: [String: Any] = [
                    "aps": [
                        "alert": [
                            "title": "Integration Test",
                            "body": "This is an integration test simple push"
                        ],
                        "badge": 10,
                        "interruption-level": "active",
                        "relevance-score": 1
                    ],
                    "itbl": [
                        "campaignId": 14679102,
                        "templateId": 19136236,
                        "messageId": "e9c8a7d8882a4df0b487a8e7f697bef8",
                        "isGhostPush": 0
                    ]
                ]
                sendSimulatedPushNotification(payload: pushPayload)
                screenshotCapture.captureScreenshot(named: "11-simulated-push-sent")
            } else {
                print("📱 [TEST] LOCAL MODE ACTIVATED: Using real push notification via backend API")
                print("🌐 [TEST] This will send actual APNS push through Iterable backend")
                testPushButton.tap()
                screenshotCapture.captureScreenshot(named: "11-test-push-sent")
                
                // Step 9.5: Handle the "Success" popup by pressing OK
                let successAlert = app.alerts.firstMatch
                if successAlert.waitForExistence(timeout: 5.0) {
                    let okButton = successAlert.buttons["OK"]
                    if okButton.exists {
                        okButton.tap()
                        screenshotCapture.captureScreenshot(named: "11.5-success-popup-dismissed")
                    }
                }
            }
            
            // Step 10: Verify push notification was received
            // Actively wait for push notification instead of sleeping
            validateSpecificPushNotificationReceived(expectedTitle: "Integration Test", expectedBody: "This is an integration test simple push")
            screenshotCapture.captureScreenshot(named: "12-push-notification-received")
        }
        
        // Step 11: Test deep link push notification flow
        print("🔗 Starting deep link push notification test...")
        
        // Navigate back to backend tab (should already be there, but verify)
        let backendTitleCheck = app.navigationBars["Backend Status"]
        if !backendTitleCheck.exists {
            print("🔄 Navigating back to backend tab for deep link test")
            navigateToBackendTab()
            
            // Check if backend tab opened
            if !backendTitleCheck.waitForExistence(timeout: 3.0) {
                print("⚠️ Backend tab didn't open, trying again")
                let backendButton = app.buttons["backend-tab"]
                if backendButton.exists {
                    backendButton.tap()
                    XCTAssertTrue(backendTitleCheck.waitForExistence(timeout: 5.0), "Backend Status should open for deep link test")
                }
            }
        }
        screenshotCapture.captureScreenshot(named: "13-backend-tab-for-deep-link")
        
        // Send deep link push notification
        let deepLinkPushButton = app.buttons["test-deep-link-push-button"]
        XCTAssertTrue(deepLinkPushButton.waitForExistence(timeout: standardTimeout), "Deep link push button should exist")
        XCTAssertTrue(deepLinkPushButton.isEnabled, "Deep link push button should be enabled")
        
        if isRunningInCI {
            print("🤖 [TEST] CI MODE ACTIVATED: Sending simulated deep link push notification")
            print("🔗 [TEST] This will use xcrun simctl with deep link payload instead of real backend API")
            // Use the deep link test URL
            let deepLinkUrl = "tester://product?itemId=12345&category=shoes"
            sendSimulatedDeepLinkPush(deepLinkUrl: deepLinkUrl)
            screenshotCapture.captureScreenshot(named: "14-simulated-deep-link-push-sent")
        } else {
            print("📱 [TEST] LOCAL MODE ACTIVATED: Using real deep link push notification via backend API")
            print("🌐 [TEST] This will send actual APNS deep link push through Iterable backend")
            deepLinkPushButton.tap()
            screenshotCapture.captureScreenshot(named: "14-deep-link-push-sent")
            
            // Handle success alert: "Success - Deep link push notification sent successfully! Campaign ID: 14695444"
            let deepLinkSuccessAlert = app.alerts["Success"]
            XCTAssertTrue(deepLinkSuccessAlert.waitForExistence(timeout: 5.0), "Success alert should appear")
            
            // Verify the alert message contains the campaign ID
            let deepLinkSuccessMessage = deepLinkSuccessAlert.staticTexts.element(boundBy: 1)
            XCTAssertTrue(deepLinkSuccessMessage.label.contains("14695444"), "Success message should contain campaign ID 14695444")
            
            let deepLinkSuccessOKButton = deepLinkSuccessAlert.buttons["OK"]
            XCTAssertTrue(deepLinkSuccessOKButton.exists, "Success alert OK button should exist")
            deepLinkSuccessOKButton.tap()
            screenshotCapture.captureScreenshot(named: "15-success-alert-dismissed")
        }
        
        // Wait for deep link push notification to arrive and validate its content
        print("🔔 Waiting for deep link push notification to arrive...")
        
        // Validate the deep link push notification content and tap it
        validateSpecificPushNotificationReceived(expectedTitle: "Integration Test", expectedBody: "This is an enhanced push campaign")
        screenshotCapture.captureScreenshot(named: "15.5-deep-link-push-received")
        
        // The validateSpecificPushNotificationReceived method will automatically tap the push notification
        // This will trigger the deep link and open the app
        
        // Verify deep link alert appears: "Iterable Deep Link Opened"
        let deepLinkAlert = app.alerts["Iterable Deep Link Opened"]
        XCTAssertTrue(deepLinkAlert.waitForExistence(timeout: 10.0), "Iterable deep link alert should appear")
        
        let deepLinkMessage = deepLinkAlert.staticTexts.element(boundBy: 1)
        XCTAssertTrue(deepLinkMessage.label.contains("tester://"), "Deep link alert should contain tester:// URL")
        
        screenshotCapture.captureScreenshot(named: "16-deep-link-alert-shown")
        
        // Dismiss the deep link alert
        let deepLinkOKButton = deepLinkAlert.buttons["OK"]
        XCTAssertTrue(deepLinkOKButton.exists, "Deep link alert OK button should exist")
        deepLinkOKButton.tap()
        screenshotCapture.captureScreenshot(named: "17-deep-link-alert-dismissed")
        
        // Close the backend tab
        let closeButton = app.buttons["backend-close-button"]
        closeButton.tap()
        screenshotCapture.captureScreenshot(named: "18-backend-tab-closed")
        
        // Navigate to Network tab to verify trackPushOpen was called
        if fastTest == false {
            // Wait a moment for UI to settle after closing backend
            sleep(1)
            
            navigateToNetworkMonitor()
            screenshotCapture.captureScreenshot(named: "19-network-tab-opened")
            
            // Verify trackPushOpen call was made with 200 status for the deep link push
            verifyNetworkCallWithSuccess(endpoint: "trackPushOpen", description: "Track push open API call should be made for deep link push")
            screenshotCapture.captureScreenshot(named: "20-track-push-open-verified")
            
            // Close network monitor
            let closeNetworkButton = app.buttons["Close"]
            if closeNetworkButton.exists {
                closeNetworkButton.tap()
                screenshotCapture.captureScreenshot(named: "21-network-tab-closed")
            }
        }
        
        print("✅ Complete push notification workflow with deep link test completed successfully")
    }
    

    
}
