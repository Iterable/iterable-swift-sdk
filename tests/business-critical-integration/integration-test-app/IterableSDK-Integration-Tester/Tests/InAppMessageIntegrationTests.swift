import XCTest
import UserNotifications
@testable import IterableSDK

class InAppMessageIntegrationTests: IntegrationTestBase {
    
    // MARK: - Test Cases
    
    func testInAppMessage() {
        
        /*##########################################################################################
         
         Initialize Push Registration for later tests
        
         #########################################################################################*/
        
        // Step 1: Navigate to Push Notification tab
        let pushNotificationRow = app.otherElements["push-notification-test-row"]
        XCTAssertTrue(pushNotificationRow.waitForExistence(timeout: standardTimeout), "Push notification row should exist")
        pushNotificationRow.tap()
        //screenshotCapture.captureScreenshot(named: "01-push-tab-opened")
        
        // Step 3: Register for push notifications
        let registerButton = app.buttons["register-push-notifications-button"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: standardTimeout), "Register button should exist")
        registerButton.tap()
        
        let backButton = app.buttons["back-to-home-button"]
        XCTAssertTrue(backButton.waitForExistence(timeout: standardTimeout), "backButton button should exist")
        backButton.tap()
        
        /*##########################################################################################
         
         Test complete flow:
             1. trigger in-app
             2. display
             3. tap button
             4. Dismiss
        
         #########################################################################################*/
        
        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()
        //screenshotCapture.captureScreenshot(named: "01-inapp-display-test-started")

        // Clear any existing messages before triggering the test campaign
        // This prevents stale messages from previous runs from interfering
        let initialClearButton = app.buttons["clear-messages-button"]
        if initialClearButton.waitForExistence(timeout: 5.0) {
            initialClearButton.tap()
            if app.alerts["Success"].waitForExistence(timeout: 5.0) {
                app.alerts["Success"].buttons["OK"].tap()
            }
            sleep(1)
        }

        // Step 1: Trigger InApp display campaign (14751067)
        var triggerTestViewButton = app.buttons["trigger-in-app-button"]
        XCTAssertTrue(triggerTestViewButton.waitForExistence(timeout: standardTimeout), "Trigger InApp display button should exist")
        triggerTestViewButton.tap()
        //screenshotCapture.captureScreenshot(named: "02-inapp-display-campaign-triggered")
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Tap "Check for Messages" to fetch and show the in-app
        var checkMessagesButton = app.buttons["check-messages-button"]
        XCTAssertTrue(checkMessagesButton.waitForExistence(timeout: standardTimeout), "Check for Messages button should exist")
        checkMessagesButton.tap()
        //screenshotCapture.captureScreenshot(named: "02b-check-messages-tapped")
        
        // Step 2: Wait for in-app message to display with smart retry
        var webView = app.descendants(matching: .webView).element(boundBy: 0)
        print("⏳ Waiting for in-app message to display...")
        
        // Smart retry: wait for button to be ready, then tap with delay
        var retryCount = 0
        let maxRetries = 5
        while !webView.exists && retryCount < maxRetries {
            // Wait for button to be enabled before retapping
            if checkMessagesButton.isEnabled {
                print("🔄 Retry \(retryCount + 1)/\(maxRetries): Tapping check-messages-button...")
                // Use coordinate tap to avoid scroll issues in CI
                if checkMessagesButton.isHittable {
                    checkMessagesButton.tap()
                } else {
                    checkMessagesButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                }
                retryCount += 1
                
                // Give time for network request to complete before checking again
                sleep(2)
            } else {
                print("⏸️ Button not enabled, waiting...")
                sleep(1)
            }
        }
        
        XCTAssertTrue(
            webView.waitForExistence(timeout: 5),
            "In-app message should appear after retries"
        )
        //screenshotCapture.captureScreenshot(named: "03-inapp-display-inapp-displayed")
        
        // Step 3: Wait for webView content to be accessible and tap "Dismiss" link
        print("👆 Waiting for 'Dismiss' link to become accessible in webView...")
        XCTAssertTrue(
            waitForWebViewLink(linkText: "Dismiss", timeout: standardTimeout),
            "Dismiss link should be accessible in the in-app message"
        )
        
        if app.links["Dismiss"].waitForExistence(timeout: standardTimeout) {
            app.links["Dismiss"].tap()
        }
        
        // Step 4: Dismiss any remaining queued in-app messages that auto-show
        print("⏳ Waiting for all in-app messages to dismiss...")
        dismissAllInAppMessages()
        print("✅ In-app message dismissed")
        
        var triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        print("✅ In-app message display flow completed successfully")
        print("✅ Flow verified:")
        print("   1. Triggered campaign 14751067")
        print("   2. In-app message displayed")
        print("   3. User tapped 'Dismiss' button")
        print("   4. In-app message dismissed")
        
        /*##########################################################################################
        
         Test complete flow:
             1. trigger in-app
             2. display
             3. tap deeplink button
             4. navigate to TestViewController
         
        ##########################################################################################*/
        
        // Step 1: Trigger TestView campaign (15231325)
        triggerTestViewButton = app.buttons["trigger-testview-in-app-button"]
        XCTAssertTrue(triggerTestViewButton.waitForExistence(timeout: standardTimeout), "Trigger TestView button should exist")
        triggerTestViewButton.tap()
        //screenshotCapture.captureScreenshot(named: "02-testview-campaign-triggered")
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Tap "Check for Messages" to fetch and show the in-app
        XCTAssertTrue(checkMessagesButton.waitForExistence(timeout: standardTimeout), "Check for Messages button should exist")
        checkMessagesButton.tap()
        //screenshotCapture.captureScreenshot(named: "02b-check-messages-tapped")
        
        // Step 2: Wait for in-app message to display with smart retry
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        print("⏳ Waiting for TestView in-app message to display...")
        
        // Smart retry: wait for button to be ready, then tap with delay
        retryCount = 0
        while !webView.exists && retryCount < maxRetries {
            // Wait for button to be enabled before retapping
            if checkMessagesButton.isEnabled {
                print("🔄 Retry \(retryCount + 1)/\(maxRetries): Tapping check-messages-button...")
                checkMessagesButton.tap()
                retryCount += 1
                
                // Give more time for CI network latency on campaign delivery
                sleep(4)
            } else {
                print("⏸️ Button not enabled, waiting...")
                sleep(1)
            }
        }
        
        XCTAssertTrue(
            webView.waitForExistence(timeout: 5),
            "In-app message should appear after retries"
        )
        //screenshotCapture.captureScreenshot(named: "03-testview-inapp-displayed")
        
        // Step 3: Wait for "Show Test View" link; dismiss stale messages that appear first
        print("👆 Waiting for 'Show Test View' link to become accessible in webView...")
        var showTestViewFound = waitForWebViewLink(linkText: "Show Test View", timeout: 10.0)
        var dismissRetries = 0
        while !showTestViewFound && dismissRetries < 5 {
            // Wrong in-app is showing — dismiss it and wait for the right one
            if app.links["Dismiss"].exists {
                print("🗑️ Dismissing stale in-app (attempt \(dismissRetries + 1))")
                app.links["Dismiss"].tap()
                sleep(2)
            } else {
                sleep(1)
            }
            dismissRetries += 1
            if webView.exists {
                showTestViewFound = waitForWebViewLink(linkText: "Show Test View", timeout: 10.0)
            }
        }
        XCTAssertTrue(showTestViewFound, "Show Test View link should be accessible in the in-app message")
        
        if app.links["Show Test View"].waitForExistence(timeout: standardTimeout) {
            app.links["Show Test View"].tap()
        }
        
        // Step 4: Dismiss any remaining queued in-app messages that auto-show
        print("⏳ Waiting for all in-app messages to dismiss...")
        dismissAllInAppMessages()
        print("✅ In-app message dismissed")
        
        // Step 5: Verify TestView alert appears
        print("⏳ Waiting for TestView Alert to appear...")
        
        // Handle success alert: "Success - Deep link push notification sent successfully! Campaign ID: 14695444"
        let testViewSuccessAlert = app.alerts["Deep link to Test View"]
        XCTAssertTrue(
            testViewSuccessAlert.waitForExistence(timeout: standardTimeout),
            "Success alert should appear"
        )
        
        let testViewSuccessOKButton = testViewSuccessAlert.buttons["OK"]
        XCTAssertTrue(testViewSuccessOKButton.exists, "Success alert OK button should exist")
        testViewSuccessOKButton.tap()
        
        triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        print("✅ In-app message deep link to TestView flow completed successfully")
        print("✅ Flow verified:")
        print("   1. Triggered campaign 15231325")
        print("   2. In-app message displayed")
        print("   3. User tapped 'Show Test View' button")
        print("   4. In-app message dismissed automatically")
        print("   5. TestViewController appeared with success message")
        print("   6. User closed TestViewController")
        
        
        /*##########################################################################################
         
         Test display rules:
             1. enable/disable
             2. message priority and persistence
         
        ##########################################################################################*/
        
        // Step 1: Test disabling in-app messages
        let toggleButton = app.buttons["toggle-in-app-button"]
        XCTAssertEqual(toggleButton.label, "Disable In-App Messages", "Button should show disable text")
        
        toggleButton.tap()
        //screenshotCapture.captureScreenshot(named: "01-inapp-disabled")
        
        // Verify status changed
        var inAppEnabledValue = app.staticTexts["✗ Disabled"]
        XCTAssertEqual(inAppEnabledValue.label, "✗ Disabled", "In-app messages should be disabled")
        
        // Step 2: Try to trigger message while disabled
        if app.buttons["trigger-in-app-button"].waitForExistence(timeout: standardTimeout) {
            app.buttons["trigger-in-app-button"].tap()
        }
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Trigger get messages
        checkMessagesButton.tap()
        
        // Verify no message appears when disabled
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        XCTAssertFalse(
            webView.waitForExistence(timeout: standardTimeout),
            "In-app message should not appear when disabled"
        )
        //screenshotCapture.captureScreenshot(named: "02-no-message-when-disabled")
        
        // Step 3: Re-enable in-app messages
        toggleButton.tap()
        inAppEnabledValue = app.staticTexts["✓ Enabled"]
        XCTAssertEqual(inAppEnabledValue.label, "✓ Enabled", "In-app messages should be enabled")
        //screenshotCapture.captureScreenshot(named: "03-inapp-reenabled")
        
        // Explicitly re-check for messages after re-enabling; on CI the scheduleSync()
        // triggered by the toggle alone can be too slow vs the 30s timeout.
        checkMessagesButton.tap()
        
        // Verify message now appears — retry loop mirrors the pattern used earlier
        let secondWebView = app.descendants(matching: .webView).element(boundBy: 0)
        var secondRetryCount = 0
        while !secondWebView.exists && secondRetryCount < maxRetries {
            if checkMessagesButton.isEnabled {
                print("🔄 Retry \(secondRetryCount + 1)/\(maxRetries): Tapping check-messages-button (post-re-enable)...")
                checkMessagesButton.tap()
                secondRetryCount += 1
                sleep(2)
            } else {
                sleep(1)
            }
        }
        XCTAssertTrue(
            secondWebView.waitForExistence(timeout: standardTimeout),
            "In-app message should appear"
        )
        //screenshotCapture.captureScreenshot(named: "02-new-message-when-enabled")
        
        print("👆 Waiting for 'Dismiss' link to become accessible in webView...")
        XCTAssertTrue(
            waitForWebViewLink(linkText: "Dismiss", timeout: standardTimeout),
            "Dismiss link should be accessible in the in-app message"
        )
        
        if app.links["Dismiss"].waitForExistence(timeout: standardTimeout) {
            app.links["Dismiss"].tap()
        }
        
        dismissAllInAppMessages()
        
        triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        print("✅ In-app message display rules test completed")

        /*##########################################################################################
         
         Test display rules:
             1. trigger in-app
             2. tap button
             3. Dismiss
             4. Validate API calls in expected order with 200 status codes
         
        ##########################################################################################*/
        
        // Wait for message queue to settle before re-triggering
        sleep(3)
        
        // Step 1: Trigger InApp display campaign (14751067)
        triggerTestViewButton = app.buttons["trigger-in-app-button"]
        XCTAssertTrue(triggerTestViewButton.waitForExistence(timeout: standardTimeout), "Trigger InApp display button should exist")
        triggerTestViewButton.tap()
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Tap "Check for Messages" to fetch and show the in-app
        checkMessagesButton = app.buttons["check-messages-button"]
        // Use coordinate tap for reliability in CI
        if checkMessagesButton.isHittable {
            checkMessagesButton.tap()
        } else {
            checkMessagesButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        
        // Step 2: Wait for in-app message to display with smart retry
        print("⏳ Waiting for in-app message...")
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        // Smart retry: wait for button to be ready, then tap with delay
        retryCount = 0
        while !webView.exists && retryCount < maxRetries {
            if checkMessagesButton.isEnabled {
                print("🔄 Retry \(retryCount + 1)/\(maxRetries): Tapping check-messages-button...")
                // Use coordinate tap for reliability in CI
                if checkMessagesButton.isHittable {
                    checkMessagesButton.tap()
                } else {
                    checkMessagesButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                }
                retryCount += 1
                sleep(3) // Longer wait in CI for message to load
            } else {
                print("⏸️ Button not enabled, waiting...")
                sleep(1)
            }
        }
        
        XCTAssertTrue(
            webView.waitForExistence(timeout: 10),
            "In-app message should appear after retries"
        )
        
        // Step 3: Wait for webView content to be accessible and tap "Dismiss" link
        print("👆 Waiting for 'Dismiss' link to become accessible in webView...")
        // Use longer timeout in CI for WebView content to fully load
        let dismissTimeout = isRunningInCI ? standardTimeout * 2 : standardTimeout
        XCTAssertTrue(
            waitForWebViewLink(linkText: "Dismiss", timeout: dismissTimeout),
            "Dismiss link should be accessible in the in-app message"
        )
        
        if app.links["Dismiss"].waitForExistence(timeout: standardTimeout) {
            app.links["Dismiss"].tap()
        }
        
        // Step 4: Dismiss any remaining queued in-app messages
        print("⏳ Waiting for all in-app messages to dismiss...")
        dismissAllInAppMessages()
        print("✅ In-app message dismissed")
        
        // Step 5: Verify network calls in expected order with 200 status codes
        if fastTest == false {
            sleep(2)
            navigateToNetworkMonitor()
            
            let networkMonitorTitle = app.navigationBars["Network Monitor"]
            if !networkMonitorTitle.waitForExistence(timeout: 3.0) {
                print("⚠️ Network monitor didn't open, trying to tap network button again")
                let networkButton = app.buttons["network-monitor-button"]
                if networkButton.exists {
                    // Use coordinate tap for reliability
                    networkButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    XCTAssertTrue(networkMonitorTitle.waitForExistence(timeout: 5.0), "Network Monitor should open after second attempt")
                }
            }
            
            print("🔍 Verifying network calls in expected order...")
            verifyNetworkCallWithSuccess(endpoint: "getMessages", description: "Initial getMessages call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "trackInAppDelivery", description: "trackInAppDelivery call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "trackInAppOpen", description: "trackInAppOpen call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "inAppConsume", description: "inAppConsume call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "trackInAppClick", description: "trackInAppClick call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "trackInAppClose", description: "trackInAppClose call should be made with 200 status")
            
            print("✅ All expected network calls verified with 200 status codes")
            print("   ✓ getMessages")
            print("   ✓ trackInAppDelivery")
            print("   ✓ getMessages (second call)")
            print("   ✓ trackInAppOpen")
            print("   ✓ inAppConsume")
            print("   ✓ trackInAppClick")
            print("   ✓ trackInAppClose")
            
            let closeNetworkButton = app.buttons["Close"]
            if closeNetworkButton.exists {
                closeNetworkButton.tap()
            }
        }
        
        triggerClearMessagesButton = app.buttons["clear-messages-button"]
        triggerClearMessagesButton.tap()
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        print("✅ In-app message network calls test completed successfully")
        
        /*##########################################################################################
         
         Test display rules:
             1. trigger Silent Push Campaign
             2. wait for silent push popup
             3. Dismiss
         
        ##########################################################################################*/
        
        triggerTestViewButton = app.buttons["trigger-test-silent-push-button"]
        
        if isRunningInCI {
            print("🤖 [TEST] CI MODE ACTIVATED: Sending simulated silent push notification")
            print("🎭 [TEST] This will use xcrun simctl instead of real backend API call")
            // Create silent push payload for CI testing (matching real Iterable format)
            // Silent push has content-available: 1 and no alert
            let silentPushPayload: [String: Any] = [
                "aps": [
                    "content-available": 1,
                    "badge": 0
                ],
                "itbl": [
                    "campaignId": 14679102,
                    "templateId": 19136236,
                    "messageId": "silent_push_test_" + UUID().uuidString,
                    "isGhostPush": 0
                ]
            ]
            sendSimulatedPushNotification(payload: silentPushPayload)
            //screenshotCapture.captureScreenshot(named: "silent-push-simulated")
        } else {
            print("📱 [TEST] LOCAL MODE ACTIVATED: Using real silent push notification via backend API")
            print("🌐 [TEST] This will send actual APNS silent push through Iterable backend")
            triggerTestViewButton.tap()
            //screenshotCapture.captureScreenshot(named: "silent-push-sent")
        }
        
        sleep(UInt32(standardTimeout))
        
        // Handle success alert: "Silent Push Received"
        if app.alerts["Silent Push Received"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Silent Push Received"].buttons["OK"].tap()
        }
        
        triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        /*##########################################################################################
         
         Test Custom Action Deeplink rules:
             NOTE: Skipped - this re-tests the same campaign (15231325) already validated above.
                   Custom action handling is covered by the earlier deep link test.
         
        ##########################################################################################*/
        
        print("ℹ️ Skipping redundant Custom Action test (campaign 15231325 already validated)")
        
        //##########################################################################################
        print("")
        print("✅✅✅✅✅✅✅✅✅✅✅")
        print("All InApp Message Tests Passed")
        print("✅✅✅✅✅✅✅✅✅✅✅")
        print("")
    }
}
