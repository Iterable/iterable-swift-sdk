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
        screenshotCapture.captureScreenshot(named: "01-push-tab-opened")
        
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
        screenshotCapture.captureScreenshot(named: "01-inapp-display-test-started")
        
        // Step 1: Trigger InApp display campaign (14751067)
        var triggerTestViewButton = app.buttons["trigger-in-app-button"]
        XCTAssertTrue(triggerTestViewButton.waitForExistence(timeout: standardTimeout), "Trigger InApp display button should exist")
        triggerTestViewButton.tap()
        screenshotCapture.captureScreenshot(named: "02-inapp-display-campaign-triggered")
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: 5.0) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Tap "Check for Messages" to fetch and show the in-app
        var checkMessagesButton = app.buttons["check-messages-button"]
        XCTAssertTrue(checkMessagesButton.waitForExistence(timeout: standardTimeout), "Check for Messages button should exist")
        checkMessagesButton.tap()
        screenshotCapture.captureScreenshot(named: "02b-check-messages-tapped")
        
        // Step 2: Wait for in-app message to display
        print("⏳ Waiting for in-app message...")
        var webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        XCTAssertTrue(webView.waitForExistence(timeout: 15.0), "In-app message should appear")
        screenshotCapture.captureScreenshot(named: "03-inapp-display-inapp-displayed")
        
        // Wait for message to fully load
        sleep(2)
        
        // Step 3: Tap the "Dismiss" link in the in-app message
        print("👆 Tapping 'Dismiss' link in in-app message")
        var showTestViewLink = app.links["Dismiss"]
        XCTAssertTrue(showTestViewLink.waitForExistence(timeout: 5.0), "Show Test View link should exist in the in-app message")
        showTestViewLink.tap()
        screenshotCapture.captureScreenshot(named: "04-inapp-display-dismiss-tapped")
        
        // Step 4: Verify in-app message is dismissed
        XCTAssertFalse(webView.waitForExistence(timeout: 15.0), "In-app message should not appear anymore")
        screenshotCapture.captureScreenshot(named: "03-inapp-display-inapp-dismissed")
        
        var triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
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
        screenshotCapture.captureScreenshot(named: "02-testview-campaign-triggered")
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: 5.0) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Tap "Check for Messages" to fetch and show the in-app
        XCTAssertTrue(checkMessagesButton.waitForExistence(timeout: standardTimeout), "Check for Messages button should exist")
        checkMessagesButton.tap()
        screenshotCapture.captureScreenshot(named: "02b-check-messages-tapped")
        
        // Step 2: Wait for in-app message to display
        print("⏳ Waiting for TestView in-app message...")
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        XCTAssertTrue(webView.waitForExistence(timeout: 15.0), "In-app message should appear")
        screenshotCapture.captureScreenshot(named: "03-testview-inapp-displayed")
        
        // Wait for message to fully load
        sleep(2)
        
        // Step 3: Tap the "Show Test View" link in the in-app message
        print("👆 Tapping 'Show Test View' link in in-app message")
        showTestViewLink = app.links["Show Test View"]
        XCTAssertTrue(showTestViewLink.waitForExistence(timeout: 5.0), "Show Test View link should exist in the in-app message")
        sleep(3)
        showTestViewLink.tap()
        
        // Step 4: Wait for in-app message to dismiss completely
        print("⏳ Waiting for in-app message to dismiss...")
        var webViewGone = NSPredicate(format: "exists == false")
        var webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [webViewExpectation], timeout: 5.0)
        print("✅ In-app message dismissed")
        screenshotCapture.captureScreenshot(named: "04b-inapp-dismissed")
        
        // Step 5: Verify TestView alert appears
        print("⏳ Waiting for TestView Alert to appear...")
        
        // Handle success alert: "Success - Deep link push notification sent successfully! Campaign ID: 14695444"
        let testViewSuccessAlert = app.alerts["Deep link to Test View"]
        XCTAssertTrue(testViewSuccessAlert.waitForExistence(timeout: 5.0), "Success alert should appear")
        
        let testViewSuccessOKButton = testViewSuccessAlert.buttons["OK"]
        XCTAssertTrue(testViewSuccessOKButton.exists, "Success alert OK button should exist")
        testViewSuccessOKButton.tap()
        
        // Verify we're back to the in-app message test screen
        sleep(1)
        XCTAssertTrue(triggerTestViewButton.exists, "Should be back at in-app test screen")
        
        triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
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
        XCTAssertTrue(toggleButton.waitForExistence(timeout: standardTimeout), "Toggle button should exist")
        XCTAssertEqual(toggleButton.label, "Disable In-App Messages", "Button should show disable text")
        
        toggleButton.tap()
        screenshotCapture.captureScreenshot(named: "01-inapp-disabled")
        
        // Verify status changed
        var inAppEnabledValue = app.staticTexts["✗ Disabled"]
        XCTAssertEqual(inAppEnabledValue.label, "✗ Disabled", "In-app messages should be disabled")
        
        // Step 2: Try to trigger message while disabled
        let triggerButton = app.buttons["trigger-in-app-button"]
        triggerButton.tap()
        
        // Handle success alert
        let successAlert = app.alerts["Success"]
        if successAlert.waitForExistence(timeout: 5.0) {
            successAlert.buttons["OK"].tap()
        }
        
        // Verify no message appears when disabled
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        XCTAssertFalse(webView.waitForExistence(timeout: 5.0), "In-app message should not appear when disabled")
        screenshotCapture.captureScreenshot(named: "02-no-message-when-disabled")
        
        // Step 3: Re-enable in-app messages
        toggleButton.tap()
        inAppEnabledValue = app.staticTexts["✓ Enabled"]
        XCTAssertEqual(inAppEnabledValue.label, "✓ Enabled", "In-app messages should be enabled")
        screenshotCapture.captureScreenshot(named: "03-inapp-reenabled")
        
        // Step 4: Trigger getMessages
        triggerButton.tap()
        
        // Handle success alert
        let secondSuccessAlert = app.alerts["Success"]
        if secondSuccessAlert.waitForExistence(timeout: 5.0) {
            secondSuccessAlert.buttons["OK"].tap()
        }
        
        // Verify message now appears
        let secondWebView = app.descendants(matching: .webView).element(boundBy: 0)
        XCTAssertTrue(secondWebView.waitForExistence(timeout: 5.0), "In-app message should appear")
        screenshotCapture.captureScreenshot(named: "02-new-message-when-enabled")
        
        print("👆 Tapping 'Dismiss' link in in-app message")
        showTestViewLink = app.links["Dismiss"]
        XCTAssertTrue(showTestViewLink.waitForExistence(timeout: 5.0), "Show Test View link should exist in the in-app message")
        showTestViewLink.tap()
        
        triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
        print("✅ In-app message display rules test completed")

        /*##########################################################################################
         
         Test display rules:
             1. trigger in-app
             2. tap button
             3. Dismiss
             4. Validate API calls in expected order with 200 status codes
         
        ##########################################################################################*/
        
        // Step 1: Trigger InApp display campaign (14751067)
        triggerTestViewButton = app.buttons["trigger-in-app-button"]
        XCTAssertTrue(triggerTestViewButton.waitForExistence(timeout: standardTimeout), "Trigger InApp display button should exist")
        triggerTestViewButton.tap()
        screenshotCapture.captureScreenshot(named: "02-inapp-campaign-triggered")
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: 5.0) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Tap "Check for Messages" to fetch and show the in-app
        checkMessagesButton = app.buttons["check-messages-button"]
        XCTAssertTrue(checkMessagesButton.waitForExistence(timeout: standardTimeout), "Check for Messages button should exist")
        checkMessagesButton.tap()
        screenshotCapture.captureScreenshot(named: "03-check-messages-tapped")
        
        // Step 2: Wait for in-app message to display
        print("⏳ Waiting for in-app message...")
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        XCTAssertTrue(webView.waitForExistence(timeout: 15.0), "In-app message should appear")
        screenshotCapture.captureScreenshot(named: "04-inapp-displayed")
        
        // Wait for message to fully load
        sleep(2)
        
        // Step 3: Tap the "Dismiss" link in the in-app message
        print("👆 Tapping 'Dismiss' link in in-app message")
        showTestViewLink = app.links["Dismiss"]
        XCTAssertTrue(showTestViewLink.waitForExistence(timeout: 5.0), "Show Test View link should exist in the in-app message")
        showTestViewLink.tap()
        screenshotCapture.captureScreenshot(named: "05-dismiss-tapped")
        
        sleep(2)
        
        showTestViewLink = app.links["Dismiss"]
        XCTAssertTrue(showTestViewLink.waitForExistence(timeout: 5.0), "Show Test View link should exist in the in-app message")
        showTestViewLink.tap()
        
        // Step 4: Verify in-app message is dismissed
        XCTAssertFalse(webView.waitForExistence(timeout: 15.0), "In-app message should not appear anymore")
        screenshotCapture.captureScreenshot(named: "06-inapp-dismissed")
        
        // Step 5: Verify network calls in expected order with 200 status codes
        if fastTest == false {
            // Wait a moment for all network calls to complete
            sleep(2)
            
            navigateToNetworkMonitor()
            screenshotCapture.captureScreenshot(named: "07-network-monitor-opened")
            
            print("🔍 Verifying network calls in expected order...")
            
            // Expected order (as they were made):
            // 1. get getMessages
            // 2. post trackInAppDelivery
            // 3. get getMessages
            // 4. post trackInAppOpen
            // 5. post inAppConsume
            // 6. post trackInAppClick
            // 7. post trackInAppClose
            
            // Verify each call exists with 200 status
            verifyNetworkCallWithSuccess(endpoint: "getMessages", description: "Initial getMessages call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "trackInAppDelivery", description: "trackInAppDelivery call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "trackInAppOpen", description: "trackInAppOpen call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "inAppConsume", description: "inAppConsume call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "trackInAppClick", description: "trackInAppClick call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "trackInAppClose", description: "trackInAppClose call should be made with 200 status")
            
            screenshotCapture.captureScreenshot(named: "08-network-calls-verified")
            
            print("✅ All expected network calls verified with 200 status codes")
            print("   ✓ getMessages")
            print("   ✓ trackInAppDelivery")
            print("   ✓ getMessages (second call)")
            print("   ✓ trackInAppOpen")
            print("   ✓ inAppConsume")
            print("   ✓ trackInAppClick")
            print("   ✓ trackInAppClose")
            
            // Close network monitor
            let closeNetworkButton = app.buttons["Close"]
            if closeNetworkButton.exists {
                closeNetworkButton.tap()
            }
        }
        
        triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
        print("✅ In-app message network calls test completed successfully")
        
        /*##########################################################################################
         
         Test display rules:
             1. trigger Silent Push Campaign
             2. wait for silent push popup
             3. Dismiss
         
        ##########################################################################################*/
        
        triggerTestViewButton = app.buttons["trigger-test-silent-push-button"]
        XCTAssertTrue(triggerTestViewButton.waitForExistence(timeout: standardTimeout), "Send Silent Push button should exist")
        
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
            screenshotCapture.captureScreenshot(named: "silent-push-simulated")
        } else {
            print("📱 [TEST] LOCAL MODE ACTIVATED: Using real silent push notification via backend API")
            print("🌐 [TEST] This will send actual APNS silent push through Iterable backend")
            triggerTestViewButton.tap()
            screenshotCapture.captureScreenshot(named: "silent-push-sent")
        }
        
        // Handle success alert: "Silent Push Received"
        let silentPushSuccessAlert = app.alerts["Silent Push Received"]
        XCTAssertTrue(silentPushSuccessAlert.waitForExistence(timeout: 5.0), "Success alert should appear")
        
        let silentPushSuccessOKButton = silentPushSuccessAlert.buttons["OK"]
        XCTAssertTrue(silentPushSuccessOKButton.exists, "Success alert OK button should exist")
        silentPushSuccessOKButton.tap()
        
        triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
        /*##########################################################################################
         
         Test Custom Action Deeplink rules:
             1. trigger Deep Link Push Campaign
             2. Dismiss confirmation
             3. Wait for in app
             4. Tap on Custom Action
             5. Validate that Deep link custom Action popup shows
         
        ##########################################################################################*/
        
        // Step 1: Trigger TestView campaign (15231325)
        triggerTestViewButton = app.buttons["trigger-testview-in-app-button"]
        XCTAssertTrue(triggerTestViewButton.waitForExistence(timeout: standardTimeout), "Trigger TestView button should exist")
        triggerTestViewButton.tap()
        screenshotCapture.captureScreenshot(named: "02-testview-campaign-triggered")
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: 5.0) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Tap "Check for Messages" to fetch and show the in-app
        XCTAssertTrue(checkMessagesButton.waitForExistence(timeout: standardTimeout), "Check for Messages button should exist")
        checkMessagesButton.tap()
        screenshotCapture.captureScreenshot(named: "02b-check-messages-tapped")
        
        // Step 2: Wait for in-app message to display
        print("⏳ Waiting for TestView in-app message...")
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        XCTAssertTrue(webView.waitForExistence(timeout: 15.0), "In-app message should appear")
        screenshotCapture.captureScreenshot(named: "03-testview-inapp-displayed")
        
        // Wait for message to fully load
        sleep(2)
        
        // Step 3: Tap the "Show Test View" link in the in-app message
        print("👆 Tapping 'Custom Action' link in in-app message")
        showTestViewLink = app.links["Custom Action"]
        XCTAssertTrue(showTestViewLink.waitForExistence(timeout: 5.0), "Custom Action link should exist in the in-app message")
        sleep(3)
        showTestViewLink.tap()
        
        // Step 4: Wait for in-app message to dismiss completely
        print("⏳ Waiting for in-app message to dismiss...")
        webViewGone = NSPredicate(format: "exists == false")
        webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [webViewExpectation], timeout: 5.0)
        print("✅ In-app message dismissed")
        screenshotCapture.captureScreenshot(named: "04b-inapp-dismissed")
        
        // Handle success alert: "Success - Deep link push notification sent successfully! Campaign ID: 14695444"
        let customActionSuccessAlert = app.alerts["Custom Action"]
        XCTAssertTrue(customActionSuccessAlert.waitForExistence(timeout: 5.0), "Success alert should appear")
        
        let customActionSuccessOKButton = customActionSuccessAlert.buttons["OK"]
        XCTAssertTrue(customActionSuccessOKButton.exists, "Success alert OK button should exist")
        customActionSuccessOKButton.tap()
        
        // Verify we're back to the in-app message test screen
        sleep(1)
        XCTAssertTrue(triggerTestViewButton.exists, "Should be back at in-app test screen")
        
        triggerClearMessagesButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(triggerClearMessagesButton.waitForExistence(timeout: standardTimeout), "Clear messages button should exist")
        triggerClearMessagesButton.tap()
        
        
        //##########################################################################################
        print("")
        print("✅✅✅✅✅✅✅✅✅✅✅")
        print("All InApp Message Tests Passed")
        print("✅✅✅✅✅✅✅✅✅✅✅")
        print("")
    }
}
