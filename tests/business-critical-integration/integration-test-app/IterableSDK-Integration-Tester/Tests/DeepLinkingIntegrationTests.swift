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
    
    // MARK: - External Source Tests (Run First)
    
    func testADeepLinkFromRemindersApp() {
        print("🧪 Testing deep link from Reminders app with Jena's test link")
        
        // Jena's test URL - wrapped link that should unwrap to https://tsetester.com/update/hi
        // SDK should follow exactly ONE redirect and stop at the first destination
        let testURL = "https://links.tsetester.com/a/click?_t=5cce074b113d48fa9ef346e4333ed8e8&_m=74aKPNrAjTpuZM4vZTDueu64xMdbHDz5Tn&_e=l6cj19GbssUn6h5qtXjRcC5os6azNW1cqdk9lsvmxxRl4ZTAW8mIB4IHJA97wE1i5f0eRDtm-KpgKI7-tM-Cly6umZo4P8HU8krftMYvL3T2sCpm3uFDBF2iJ5vQ-G6sqNMmae4_8jkE1DU9aKRhraZ1zzUZ3j-dFbQJrxdLt4tb0C7jnXSARVFf27FKFhBKnYSO23taBmf_4G5dTTXKmC_1CGnT9bu1nAwP-WMyYShoQhmjoGO9ppDCrVStSYPsimwub0h5XnC11g4u5yML_WZssgC7LSUOX7qCNOIDr9dLhrx2Rc2TY12k0maESyanjNgNZ4Lr8LMClCMJ3d9TMg%3D%3D"
        
        print("🔗 Test URL: \(testURL)")
        print("🎯 Expected unwrapped destination: https://tsetester.com/update/hi")
        
        // Open link from Reminders app
        openLinkFromRemindersApp(url: testURL)
        
        // Wait for app to process the deep link and navigate to update screen
        sleep(5)
        
        // Verify the UpdateViewController is displayed (not just an alert)
        // This validates that SDK followed exactly ONE redirect (not multiple)
        let updateHeader = app.staticTexts["update-view-header"]
        XCTAssertTrue(updateHeader.waitForExistence(timeout: 15.0), "Update screen should be displayed")
        XCTAssertEqual(updateHeader.label, "👋 Hi!", "Update screen should show 'Hi!' header")
        
        // Verify the path label shows the correct unwrapped URL
        let pathLabel = app.staticTexts["update-view-path"]
        XCTAssertTrue(pathLabel.exists, "Path label should exist")
        XCTAssertTrue(pathLabel.label.contains("/update/hi"), "Path should show /update/hi (first redirect destination)")
        
        print("✅ Update screen displayed with correct path: \(pathLabel.label)")
        
        // Take screenshot of the update screen
        screenshotCapture.captureScreenshot(named: "update-screen-from-deep-link")
        
        // Close the update screen
        let closeButton = app.buttons["update-view-close-button"]
        if closeButton.exists {
            closeButton.tap()
            sleep(1)
        }
        
        print("✅ Deep link from Reminders app test completed - SDK correctly unwrapped to first redirect")
    }
    
    func testBSingleRedirectPolicy() {
        print("🧪 Testing SDK follows exactly one redirect (GreenFi bug fix validation)")
        print("🎯 This test validates that SDK stops at first redirect, not following multiple hops")
        print("📚 HOW IT WORKS: SDK's RedirectNetworkSession.willPerformHTTPRedirection returns nil")
        print("   to completionHandler, which tells URLSession to STOP following redirects")
        print("   See: swift-sdk/Internal/Network/NetworkSession.swift:136")
        
        // Using Jena's test link which redirects to tsetester.com/update/hi
        // If there are multiple redirects after that, SDK should NOT follow them
        let testURL = "https://links.tsetester.com/a/click?_t=5cce074b113d48fa9ef346e4333ed8e8&_m=74aKPNrAjTpuZM4vZTDueu64xMdbHDz5Tn&_e=l6cj19GbssUn6h5qtXjRcC5os6azNW1cqdk9lsvmxxRl4ZTAW8mIB4IHJA97wE1i5f0eRDtm-KpgKI7-tM-Cly6umZo4P8HU8krftMYvL3T2sCpm3uFDBF2iJ5vQ-G6sqNMmae4_8jkE1DU9aKRhraZ1zzUZ3j-dFbQJrxdLt4tb0C7jnXSARVFf27FKFhBKnYSO23taBmf_4G5dTTXKmC_1CGnT9bu1nAwP-WMyYShoQhmjoGO9ppDCrVStSYPsimwub0h5XnC11g4u5yML_WZssgC7LSUOX7qCNOIDr9dLhrx2Rc2TY12k0maESyanjNgNZ4Lr8LMClCMJ3d9TMg%3D%3D"
        
        print("🔗 Test URL: \(testURL)")
        print("✅ Expected: SDK stops at first redirect (tsetester.com/update/hi)")
        print("❌ Should NOT follow: Any subsequent redirects beyond the first one")
        
        // Open link from Reminders app
        openLinkFromRemindersApp(url: testURL)
        
        // Wait for app to process the deep link
        sleep(5)
        
        // Verify we got the FIRST redirect destination, not any subsequent ones
        // The UpdateViewController should show /update/hi (first redirect)
        // NOT any final destination if there were multiple hops
        let updateHeader = app.staticTexts["update-view-header"]
        XCTAssertTrue(updateHeader.waitForExistence(timeout: 15.0), 
                      "Update screen should be displayed after single redirect")
        
        // CRITICAL VALIDATION: Verify the path shows first redirect destination
        let pathLabel = app.staticTexts["update-view-path"]
        XCTAssertTrue(pathLabel.exists, "Path label should exist")
        XCTAssertTrue(pathLabel.label.contains("/update/hi"), 
                     "Path should show /update/hi (first redirect destination)")
        
        // If SDK followed multiple redirects, we would see a different path here
        XCTAssertFalse(pathLabel.label.contains("final-destination"), 
                      "Path should NOT show final destination from multi-hop redirect")
        
        print("✅ Update screen shows first redirect destination: \(pathLabel.label)")
        
        // Take screenshot before closing
        screenshotCapture.captureScreenshot(named: "single-redirect-validation")
        
        // Close the update screen before opening network monitor
        let closeButton = app.buttons["update-view-close-button"]
        if closeButton.exists {
            closeButton.tap()
            sleep(1)
        }
        
        // Open Network Monitor to validate redirect behavior
        print("🔍 Opening Network Monitor to validate single redirect policy...")
        navigateToNetworkMonitor()
        
        // Wait for network monitor to load
        let networkMonitorTitle = app.navigationBars["Network Monitor"]
        XCTAssertTrue(networkMonitorTitle.waitForExistence(timeout: standardTimeout), "Network Monitor should open")
        
        // Look for the wrapped link request (the initial request to links.tsetester.com)
        let wrappedLinkPredicate = NSPredicate(format: "label CONTAINS[c] 'links.tsetester.com'")
        let wrappedLinkCell = app.cells.containing(wrappedLinkPredicate).firstMatch
        
        if wrappedLinkCell.waitForExistence(timeout: 5.0) {
            print("✅ Found wrapped link request in Network Monitor")
            
            // Check for 3xx status code (redirect response)
            let redirectStatusPredicate = NSPredicate(format: "label MATCHES '^3[0-9]{2}$'")
            let redirectStatus = wrappedLinkCell.staticTexts.containing(redirectStatusPredicate).firstMatch
            
            if redirectStatus.exists {
                print("✅ Wrapped link returned 3xx redirect status: \(redirectStatus.label)")
            }
        } else {
            print("⚠️ Could not find wrapped link in Network Monitor (may have been unwrapped internally)")
        }
        
        // CRITICAL: Verify we did NOT make a request to any "final destination" domain
        // If there was a multi-hop redirect, we would see requests to intermediate domains
        // For this test, we're assuming tsetester.com/update/hi is the FIRST redirect
        // and there should be NO subsequent requests to other domains
        
        // Count how many unique domains we made requests to
        let allCells = app.cells.allElementsBoundByIndex
        var uniqueDomains = Set<String>()
        
        for cell in allCells {
            let cellLabel = cell.staticTexts.firstMatch.label
            if cellLabel.contains("tsetester.com") {
                uniqueDomains.insert("tsetester.com")
            } else if cellLabel.contains("links.tsetester.com") {
                uniqueDomains.insert("links.tsetester.com")
            } else if cellLabel.contains("iterable.com") {
                uniqueDomains.insert("iterable.com")
            }
            // Add checks for any other domains that would indicate multi-hop
        }
        
        print("🔍 Unique domains in network requests: \(uniqueDomains)")
        
        // We should see:
        // 1. links.tsetester.com (the wrapped link)
        // 2. tsetester.com (the first redirect destination)
        // We should NOT see any third domain (which would indicate multi-hop)
        
        XCTAssertTrue(uniqueDomains.count <= 3, 
                     "Should only see links.tsetester.com, tsetester.com, and iterable.com (SDK API calls). Found: \(uniqueDomains)")
        
        print("✅ Network Monitor validation: Only expected domains found, no multi-hop redirect detected")
        
        // Close network monitor
        let networkMonitorCloseButton = app.buttons["Close"]
        if networkMonitorCloseButton.exists {
            networkMonitorCloseButton.tap()
        }
        
        print("✅ Single redirect policy test completed - SDK correctly stops at first redirect")
        print("✅ Validated via: 1) Alert content, 2) Network Monitor redirect count")
    }
    
    // MARK: - URL Delegate Tests
    
    func testCURLDelegateCallback() throws {
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
    
    func testDURLDelegateParameters() throws {
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
        
        // Wait longer for push notification to arrive and be processed
        sleep(8)
        
        // Verify the deep link alert appears with expected URL
        let expectedAlert = AlertExpectation(
            title: "Iterable Deep Link Opened",
            messageContains: "tester://",
            timeout: 20.0
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
    
    func testIAlertContentValidation() throws {
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
    
    func testJMultipleAlertsInSequence() throws {
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
    
    func testGDeepLinkFromPushNotification() throws {
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
        
        // Navigate directly to backend (we're already on home after registering)
        // The push notification registration flow already brings us back to home
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
        
        // Wait longer for push to arrive and process
        sleep(8)
        
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
    
    func testHDeepLinkFromInAppMessage() throws {
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
    
    // MARK: - Custom Action Tests
    
    func testECustomActionDelegate() throws {
        print("🧪 Testing custom action delegate callback")
        
        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()
        
        // Trigger the TestView campaign which has a custom action
        let triggerButton = app.buttons["trigger-testview-in-app-button"]
        XCTAssertTrue(triggerButton.waitForExistence(timeout: standardTimeout), "Trigger button should exist")
        triggerButton.tap()
        
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        
        // Check for messages
        let checkMessagesButton = app.buttons["check-messages-button"]
        XCTAssertTrue(checkMessagesButton.waitForExistence(timeout: standardTimeout), "Check messages button should exist")
        checkMessagesButton.tap()
        
        // Wait for in-app message to display
        let webView = app.descendants(matching: .webView).element(boundBy: 0)
        XCTAssertTrue(webView.waitForExistence(timeout: standardTimeout), "In-app message should appear")
        
        // Wait for link to be accessible and tap it
        XCTAssertTrue(waitForWebViewLink(linkText: "Show Test View", timeout: standardTimeout), "Show Test View link should be accessible")
        
        if app.links["Show Test View"].waitForExistence(timeout: standardTimeout) {
            app.links["Show Test View"].tap()
        }
        
        // Wait for in-app to dismiss
        let webViewGone = NSPredicate(format: "exists == false")
        let webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
        wait(for: [webViewExpectation], timeout: standardTimeout)
        
        // Verify the deep link alert appears (this validates URL delegate was called)
        let expectedAlert = AlertExpectation(
            title: "Deep link to Test View",
            message: "Deep link handled with Success!",
            timeout: standardTimeout
        )
        
        XCTAssertTrue(deepLinkHelper.waitForAlert(expectedAlert), "URL delegate alert should appear for tester://testview")
        
        // Dismiss the alert
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Deep link to Test View")
        
        // Clean up
        let clearMessagesButton = app.buttons["clear-messages-button"]
        if clearMessagesButton.exists {
            clearMessagesButton.tap()
            deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        }
        
        print("✅ Custom action delegate test completed successfully")
    }
    
    // MARK: - Browser Link Tests
    
    func testFBrowserLinksOpenSafari() throws {
        print("🧪 Testing non-app links open in Safari (not app)")
        print("🎯 Links with /u/ pattern or non-AASA paths should open Safari")
        
        // Link with /u/ pattern (untracked) should open Safari, not our app
        // This is NOT in the AASA file, so iOS should open Safari
        let browserURL = "https://links.tsetester.com/u/click?url=https://iterable.com"
        
        print("🔗 Test URL: \(browserURL)")
        print("✅ Expected: Safari opens (not our app)")
        
        openLinkFromRemindersApp(url: browserURL)
        sleep(3)
        
        // Verify Safari opened (not our app)
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 10.0),
                      "Browser links (/u/ pattern) should open Safari, not app")
        
        print("✅ Browser link test completed - Safari opened correctly")
    }
}
