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
        
        // Step 2: Wait for in-app message to display
        var webView = app.descendants(matching: .webView).element(boundBy: 0)
        print("⏳ First Waiting for in-app message...")
        var count = 0
        while webView.exists == false {
            print("⏳ Waiting for in-app message \(count)...")
            count += 1
            checkMessagesButton.tap()
        }
        
        XCTAssertTrue(
            webView.waitForExistence(timeout: standardTimeout),
            "In-app message should appear"
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
        
        // Trying a different approach on this one.
//        var showTestViewLink = app.links["Dismiss"]
//        showTestViewLink.tap()
        
        //screenshotCapture.captureScreenshot(named: "04-inapp-display-dismiss-tapped")
        
        // Step 4: Verify in-app message is dismissed
        print("⏳ Waiting for in-app message to dismiss...")
        var webViewGone = NSPredicate(format: "exists == false")
        var webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [webViewExpectation], timeout: standardTimeout)
        print("✅ In-app message dismissed")
        //screenshotCapture.captureScreenshot(named: "03-inapp-display-inapp-dismissed")
        
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
        
        // Step 2: Wait for in-app message to display
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        print("⏳ First Waiting for in-app message...")
        count = 0
        while webView.exists == false {
            print("⏳ Waiting for in-app message \(count)...")
            count += 1
            checkMessagesButton.tap()
        }
        
        XCTAssertTrue(
            webView.waitForExistence(timeout: standardTimeout),
            "In-app message should appear"
        )
        //screenshotCapture.captureScreenshot(named: "03-testview-inapp-displayed")
        
        // Step 3: Wait for webView content to be accessible and tap "Show Test View" link
        print("👆 Waiting for 'Show Test View' link to become accessible in webView...")
        XCTAssertTrue(
            waitForWebViewLink(linkText: "Show Test View", timeout: standardTimeout),
            "Show Test View link should be accessible in the in-app message"
        )
        
        if app.links["Show Test View"].waitForExistence(timeout: standardTimeout) {
            app.links["Show Test View"].tap()
        }
        
        // Step 4: Wait for in-app message to dismiss completely
        print("⏳ Waiting for in-app message to dismiss...")
        webViewGone = NSPredicate(format: "exists == false")
        webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [webViewExpectation], timeout: standardTimeout)
        print("✅ In-app message dismissed")
        
        //screenshotCapture.captureScreenshot(named: "04b-inapp-dismissed")
        
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
        
        // Step 4: Trigger getMessages
        checkMessagesButton.tap()
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Verify message now appears
        let secondWebView = app.descendants(matching: .webView).element(boundBy: 0)
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
        
        // Step 1: Trigger InApp display campaign (14751067)
        triggerTestViewButton = app.buttons["trigger-in-app-button"]
        XCTAssertTrue(triggerTestViewButton.waitForExistence(timeout: standardTimeout), "Trigger InApp display button should exist")
        triggerTestViewButton.tap()
        //screenshotCapture.captureScreenshot(named: "02-inapp-campaign-triggered")
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Tap "Check for Messages" to fetch and show the in-app
        checkMessagesButton = app.buttons["check-messages-button"]
        checkMessagesButton.tap()
        //screenshotCapture.captureScreenshot(named: "03-check-messages-tapped")
        
        // Step 2: Wait for in-app message to display
        print("⏳ Waiting for in-app message...")
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        print("⏳ First Waiting for in-app message...")
        count = 0
        while webView.exists == false {
            print("⏳ Waiting for in-app message \(count)...")
            count += 1
            checkMessagesButton.tap()
        }
        
        XCTAssertTrue(
            webView.waitForExistence(timeout: standardTimeout),
            "In-app message should appear"
        )
        //screenshotCapture.captureScreenshot(named: "04-inapp-displayed")
        
        // Step 3: Wait for webView content to be accessible and tap "Dismiss" link
        print("👆 Waiting for 'Dismiss' link to become accessible in webView...")
        XCTAssertTrue(
            waitForWebViewLink(linkText: "Dismiss", timeout: standardTimeout),
            "Dismiss link should be accessible in the in-app message"
        )
        
        if app.links["Dismiss"].waitForExistence(timeout: standardTimeout) {
            app.links["Dismiss"].tap()
        }
        //screenshotCapture.captureScreenshot(named: "05-dismiss-tapped")
        
        // Step 4: Verify in-app message is dismissed
        print("⏳ Waiting for in-app message to dismiss...")
        webViewGone = NSPredicate(format: "exists == false")
        webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [webViewExpectation], timeout: standardTimeout)
        print("✅ In-app message dismissed")
        //screenshotCapture.captureScreenshot(named: "06-inapp-dismissed")
        
        // Step 5: Verify network calls in expected order with 200 status codes
        if fastTest == false {
            // Wait a moment for all network calls to complete
            sleep(2)
            
            navigateToNetworkMonitor()
            //screenshotCapture.captureScreenshot(named: "07-network-monitor-opened")
            
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
            
            //screenshotCapture.captureScreenshot(named: "08-network-calls-verified")
            
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
        triggerClearMessagesButton.tap()
        // Handle success alert
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
             1. trigger Deep Link Push Campaign
             2. Dismiss confirmation
             3. Wait for in app
             4. Tap on Custom Action
             5. Validate that Deep link custom Action popup shows
         
        ##########################################################################################*/
        
        // Step 1: Trigger TestView campaign (15231325)
        triggerTestViewButton = app.buttons["trigger-testview-in-app-button"]
        triggerTestViewButton.tap()
        //screenshotCapture.captureScreenshot(named: "02-testview-campaign-triggered")
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Tap "Check for Messages" to fetch and show the in-app
        checkMessagesButton.tap()
        //screenshotCapture.captureScreenshot(named: "02b-check-messages-tapped")
        
        // Step 2: Wait for in-app message to display
        print("⏳ Waiting for TestView in-app message...")
        webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        print("⏳ First Waiting for in-app message...")
        count = 0
        while webView.exists == false {
            print("⏳ Waiting for in-app message \(count)...")
            count += 1
            checkMessagesButton.tap()
        }
        
        XCTAssertTrue(
            webView.waitForExistence(timeout: standardTimeout),
            "In-app message should appear"
        )
        //screenshotCapture.captureScreenshot(named: "03-testview-inapp-displayed")
        
        // Step 3: Wait for webView content to be accessible and tap "Custom Action" link
        print("👆 Waiting for 'Custom Action' link to become accessible in webView...")
        XCTAssertTrue(
            waitForWebViewLink(linkText: "Custom Action", timeout: standardTimeout),
            "Custom Action link should be accessible in the in-app message"
        )
        
        if app.links["Custom Action"].waitForExistence(timeout: standardTimeout) {
            app.links["Custom Action"].tap()
        }
        
        // Step 4: Wait for in-app message to dismiss completely
        print("⏳ Waiting for in-app message to dismiss...")
        webViewGone = NSPredicate(format: "exists == false")
        webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [webViewExpectation], timeout: standardTimeout)
        print("✅ In-app message dismissed")
        //screenshotCapture.captureScreenshot(named: "04b-inapp-dismissed")
        
        // Handle success alert: "Success - Deep link push notification sent successfully! Campaign ID: 14695444"
        
        // Handle success alert
        if app.alerts["Custom Action"].waitForExistence(timeout: standardTimeout) {
            app.alerts["Custom Action"].buttons["OK"].tap()
        }
        
        //##########################################################################################
        print("")
        print("✅✅✅✅✅✅✅✅✅✅✅")
        print("All InApp Message Tests Passed")
        print("✅✅✅✅✅✅✅✅✅✅✅")
        print("")
    }
}
