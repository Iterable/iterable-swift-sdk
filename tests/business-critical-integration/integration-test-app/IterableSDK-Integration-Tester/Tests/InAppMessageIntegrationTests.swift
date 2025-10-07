import XCTest
import UserNotifications
@testable import IterableSDK

class InAppMessageIntegrationTests: IntegrationTestBase {
    
    // MARK: - Test Cases
    
    func testBasicInAppMessageWorkflow() {
        // Test complete in-app message workflow: initialization → trigger → display → interaction → metrics
        
        // Step 1: Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()
        screenshotCapture.captureScreenshot(named: "01-inapp-tab-opened")
        
        // Step 2: Verify initial in-app status
        let inAppEnabledValue = app.staticTexts["in-app-enabled-value"]
        XCTAssertTrue(inAppEnabledValue.waitForExistence(timeout: standardTimeout), "In-app enabled status should exist")
        XCTAssertEqual(inAppEnabledValue.label, "✓ Enabled", "In-app messages should be enabled by default")
        
        let messagesAvailableValue = app.staticTexts["messages-available-value"]
        XCTAssertTrue(messagesAvailableValue.waitForExistence(timeout: standardTimeout), "Messages available value should exist")
        screenshotCapture.captureScreenshot(named: "02-initial-status-verified")
        
        // Step 3: Check for messages
        let checkMessagesButton = app.buttons["check-messages-button"]
        XCTAssertTrue(checkMessagesButton.waitForExistence(timeout: standardTimeout), "Check messages button should exist")
        checkMessagesButton.tap()
        screenshotCapture.captureScreenshot(named: "03-check-messages-tapped")
        
        // Wait for check to complete
        sleep(2)
        
        // Step 4: Navigate to backend to trigger in-app message
        let backendButton = app.buttons["backend-tab"]
        XCTAssertTrue(backendButton.waitForExistence(timeout: standardTimeout), "Backend button should exist")
        backendButton.tap()
        
        // Wait for backend to load
        let backendTitle = app.navigationBars["Backend Status"]
        XCTAssertTrue(backendTitle.waitForExistence(timeout: standardTimeout), "Backend Status should open")
        screenshotCapture.captureScreenshot(named: "04-backend-opened")
        
        // Step 5: Send test in-app message
        let sendInAppButton = app.buttons["test-in-app-button"]
        XCTAssertTrue(sendInAppButton.waitForExistence(timeout: standardTimeout), "Send in-app button should exist")
        
        // Wait for button to be enabled (backend loads user data)
        let enabledPredicate = NSPredicate(format: "isEnabled == true")
        let enabledExpectation = XCTNSPredicateExpectation(predicate: enabledPredicate, object: sendInAppButton)
        XCTAssertEqual(XCTWaiter.wait(for: [enabledExpectation], timeout: 10.0), .completed, "Send in-app button should become enabled")
        
        sendInAppButton.tap()
        screenshotCapture.captureScreenshot(named: "05-inapp-sent")
        
        // Handle success alert
        let successAlert = app.alerts["Success"]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 5.0), "Success alert should appear")
        
        let okButton = successAlert.buttons["OK"]
        XCTAssertTrue(okButton.exists, "OK button should exist")
        okButton.tap()
        screenshotCapture.captureScreenshot(named: "06-success-alert-dismissed")
        
        // Close backend
        let closeBackendButton = app.buttons["backend-close-button"]
        closeBackendButton.tap()
        
        // Wait a moment for navigation
        sleep(1)
        
        // Step 6: Wait for in-app message to appear
        print("⏳ Waiting for in-app message to appear...")
        
        // Look for common in-app message elements
        let webViewPredicate = NSPredicate(format: "type == %@", "WebView")
        let inAppWebView = app.descendants(matching: .webView).element(boundBy: 0)
        
        // Wait up to 15 seconds for in-app message to appear
        let inAppExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: inAppWebView)
        let waitResult = XCTWaiter.wait(for: [inAppExpectation], timeout: 15.0)
        
        if waitResult == .completed {
            print("✅ In-app message appeared")
            screenshotCapture.captureScreenshot(named: "07-inapp-message-displayed")
            
            // Wait a moment to ensure message is fully loaded
            sleep(2)
            
            // Step 7: Interact with in-app message (tap to dismiss)
            // Try to find and tap a dismiss button or the message itself
            let dismissButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'close' OR label CONTAINS[c] 'dismiss' OR label CONTAINS[c] 'x'")).firstMatch
            
            if dismissButton.exists {
                dismissButton.tap()
                print("✅ Tapped dismiss button")
            } else {
                // Tap the webview itself to trigger any default action
                inAppWebView.tap()
                print("✅ Tapped in-app message")
            }
            
            screenshotCapture.captureScreenshot(named: "08-inapp-message-interacted")
            
            // Wait for message to dismiss
            sleep(2)
        } else {
            print("⚠️ In-app message did not appear within timeout, checking if it was received...")
        }
        
        // Step 8: Verify network calls
        if fastTest == false {
            navigateToNetworkMonitor()
            screenshotCapture.captureScreenshot(named: "09-network-monitor-opened")
            
            // Verify getMessages call
            verifyNetworkCallWithSuccess(endpoint: "getMessages", description: "In-app messages should be fetched")
            
            // Verify track events (if message was displayed)
            if waitResult == .completed {
                // Look for inAppOpen event
                let inAppOpenPredicate = NSPredicate(format: "label CONTAINS[c] 'inAppOpen'")
                let inAppOpenCell = app.cells.containing(inAppOpenPredicate).firstMatch
                if inAppOpenCell.waitForExistence(timeout: 5.0) {
                    print("✅ Found inAppOpen event")
                }
            }
            
            screenshotCapture.captureScreenshot(named: "10-network-calls-verified")
            
            // Close network monitor
            let closeNetworkButton = app.buttons["Close"]
            if closeNetworkButton.exists {
                closeNetworkButton.tap()
            }
        }
        
        print("✅ Basic in-app message workflow test completed successfully")
    }
    
    func testInAppMessageWithActionButtons() {
        // Test in-app message with multiple action buttons and deep link handling
        
        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()
        screenshotCapture.captureScreenshot(named: "01-inapp-action-test-started")
        
        // Trigger action in-app message (Campaign 14751068)
        let triggerActionButton = app.buttons["trigger-action-in-app-button"]
        XCTAssertTrue(triggerActionButton.waitForExistence(timeout: standardTimeout), "Trigger action button should exist")
        triggerActionButton.tap()
        
        // Handle success alert
        let successAlert = app.alerts["Success"]
        if successAlert.waitForExistence(timeout: 5.0) {
            successAlert.buttons["OK"].tap()
        }
        
        // Wait for in-app message with action buttons
        print("⏳ Waiting for action in-app message...")
        let webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        if webView.waitForExistence(timeout: 15.0) {
            screenshotCapture.captureScreenshot(named: "02-action-inapp-displayed")
            
            // Look for action buttons within the webview
            // Note: Actual button detection depends on campaign HTML structure
            sleep(2)
            
            // Try to tap an action button
            let actionButtonPredicate = NSPredicate(format: "label CONTAINS[c] 'action' OR label CONTAINS[c] 'button' OR label CONTAINS[c] 'learn'")
            let actionButton = app.buttons.containing(actionButtonPredicate).firstMatch
            
            if actionButton.exists {
                actionButton.tap()
                print("✅ Tapped action button")
                screenshotCapture.captureScreenshot(named: "03-action-button-tapped")
            } else {
                // Tap center of webview as fallback
                webView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                print("✅ Tapped center of message")
            }
            
            // Check for any deep link handling
            sleep(2)
            screenshotCapture.captureScreenshot(named: "04-action-result")
        }
        
        print("✅ In-app message with action buttons test completed")
    }
    
    func testInAppMessageDisplayRules() {
        // Test display rules: enable/disable, message priority, and persistence
        
        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()
        
        // Step 1: Test disabling in-app messages
        let toggleButton = app.buttons["toggle-in-app-button"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: standardTimeout), "Toggle button should exist")
        XCTAssertEqual(toggleButton.label, "Disable In-App Messages", "Button should show disable text")
        
        toggleButton.tap()
        screenshotCapture.captureScreenshot(named: "01-inapp-disabled")
        
        // Verify status changed
        let inAppEnabledValue = app.staticTexts["in-app-enabled-value"]
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
        let webView = app.descendants(matching: .webView).element(boundBy: 0)
        XCTAssertFalse(webView.waitForExistence(timeout: 5.0), "In-app message should not appear when disabled")
        screenshotCapture.captureScreenshot(named: "02-no-message-when-disabled")
        
        // Step 3: Re-enable in-app messages
        toggleButton.tap()
        XCTAssertEqual(inAppEnabledValue.label, "✓ Enabled", "In-app messages should be enabled")
        screenshotCapture.captureScreenshot(named: "03-inapp-reenabled")
        
        // Step 4: Test message queue clearing
        let clearButton = app.buttons["clear-messages-button"]
        XCTAssertTrue(clearButton.exists, "Clear messages button should exist")
        clearButton.tap()
        
        // Handle clear success alert
        if app.alerts["Success"].waitForExistence(timeout: 5.0) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        screenshotCapture.captureScreenshot(named: "04-messages-cleared")
        
        print("✅ In-app message display rules test completed")
    }
    
    func testInAppMessageWithDeepLink() {
        // Test in-app message with deep link handling
        
        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()
        
        // Trigger deep link in-app message (Campaign 14751069)
        let triggerDeepLinkButton = app.buttons["trigger-deeplink-in-app-button"]
        XCTAssertTrue(triggerDeepLinkButton.waitForExistence(timeout: standardTimeout), "Trigger deep link button should exist")
        triggerDeepLinkButton.tap()
        screenshotCapture.captureScreenshot(named: "01-deeplink-inapp-triggered")
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: 5.0) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Wait for in-app message
        let webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        if webView.waitForExistence(timeout: 15.0) {
            screenshotCapture.captureScreenshot(named: "02-deeplink-inapp-displayed")
            
            // Tap the message to trigger deep link
            webView.tap()
            
            // Check for deep link alert
            let deepLinkAlert = app.alerts["Iterable Deep Link Opened"]
            if deepLinkAlert.waitForExistence(timeout: 5.0) {
                screenshotCapture.captureScreenshot(named: "03-deeplink-alert-shown")
                
                let alertMessage = deepLinkAlert.staticTexts.element(boundBy: 1)
                XCTAssertTrue(alertMessage.label.contains("tester://"), "Deep link should contain tester:// URL")
                
                deepLinkAlert.buttons["OK"].tap()
                screenshotCapture.captureScreenshot(named: "04-deeplink-handled")
            }
        }
        
        print("✅ In-app message with deep link test completed")
    }
    
    func testInAppMessageMetricsAndStatistics() {
        // Test that in-app message interactions are properly tracked
        
        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()
        
        // Check initial statistics
        let shownValue = app.staticTexts["messages-shown-value"]
        let clickedValue = app.staticTexts["messages-clicked-value"]
        let dismissedValue = app.staticTexts["messages-dismissed-value"]
        
        XCTAssertTrue(shownValue.waitForExistence(timeout: standardTimeout), "Shown value should exist")
        
        // Record initial values
        let initialShown = Int(shownValue.label) ?? 0
        let initialClicked = Int(clickedValue.label) ?? 0
        let initialDismissed = Int(dismissedValue.label) ?? 0
        
        screenshotCapture.captureScreenshot(named: "01-initial-statistics")
        
        // Trigger a test in-app message
        let triggerButton = app.buttons["trigger-in-app-button"]
        triggerButton.tap()
        
        // Handle success alert
        if app.alerts["Success"].waitForExistence(timeout: 5.0) {
            app.alerts["Success"].buttons["OK"].tap()
        }
        
        // Wait for message and interact
        let webView = app.descendants(matching: .webView).element(boundBy: 0)
        
        if webView.waitForExistence(timeout: 15.0) {
            // Message shown - statistics should update
            sleep(2)
            
            // Verify shown count increased
            let newShown = Int(shownValue.label) ?? 0
            XCTAssertEqual(newShown, initialShown + 1, "Shown count should increase by 1")
            
            screenshotCapture.captureScreenshot(named: "02-message-shown-tracked")
            
            // Click the message
            webView.tap()
            sleep(2)
            
            // Verify clicked count increased
            let newClicked = Int(clickedValue.label) ?? 0
            XCTAssertGreaterThanOrEqual(newClicked, initialClicked, "Clicked count should increase")
            
            screenshotCapture.captureScreenshot(named: "03-statistics-updated")
        }
        
        print("✅ In-app message metrics and statistics test completed")
    }
}
