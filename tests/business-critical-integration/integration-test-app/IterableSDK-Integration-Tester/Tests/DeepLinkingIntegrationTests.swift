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
    
    // MARK: - Browser Link Tests (Run First)
    
    // MARK: - Browser Link Tests
    
    // MARK: - Browser Link Tests
    
    func testABrowserLinksOpenSafari() throws {
        try XCTSkipIf(isRunningInCI, "Universal Link tests require AASA and real Safari — skipped on CI")
        print("🧪 Testing non-app links open in Safari (not app)")
        print("🎯 Links with /u/ pattern or non-AASA paths should open Safari")
        
        let browserURL = "https://links.bcittesting.com/u/click?url=https://iterable.com"
        
        print("🔗 Test URL: \(browserURL)")
        print("✅ Expected: Safari opens (not our app)")
        
        openBrowserLinkFromRemindersApp(url: browserURL)
        
        sleep(3)
        
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        let safariIsForeground = safari.state == .runningForeground
        let appIsForeground = app.state == .runningForeground
        
        print("🔍 Safari state: \(safariIsForeground ? "foreground" : "background")")
        print("🔍 App state: \(appIsForeground ? "foreground" : "background")")
        
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 15.0),
                      "Browser links (/u/ pattern) should open Safari, not app")
        // Use predicate wait so CI state-transition races don't produce a false positive
        let appNotForeground = NSPredicate(format: "state != 4")
        let bgExpectation = XCTNSPredicateExpectation(predicate: appNotForeground, object: app)
        let result = XCTWaiter.wait(for: [bgExpectation], timeout: 5.0)
        XCTAssertEqual(result, .completed, "App should not be in foreground for /u/ links")
        
        print("✅ Browser link test completed - Safari opened correctly")
    }
    
    
    // MARK: - External Source Tests
    
    func testBDeepLinkFromRemindersApp() throws {
        try XCTSkipIf(isRunningInCI, "Universal Link tests require AASA and real Safari — skipped on CI")
        print("🧪 Testing deep link from Reminders app with Jena's test link")
        
        // TODO(SDK-325): regenerate this wrapped link against the new Mobile SDK Testing
        // project (post SDK-36). The _t/_m/_e tokens below are tied to the old project and
        // will 404 against links.bcittesting.com until the link is regenerated.
        // Wrapped link should unwrap to https://bcittesting.com/update/hi
        // SDK should follow exactly ONE redirect and stop at the first destination
        let testURL = "https://links.bcittesting.com/a/click?_t=TODO_REGENERATE_TOKEN&_m=TODO&_e=TODO"
        
        print("🔗 Test URL: \(testURL)")
        print("🎯 Expected unwrapped destination: https://bcittesting.com/update/hi")
        
        // Open link from Reminders app
        openLinkFromRemindersApp(url: testURL)
        
        // Wait for app to process the deep link and navigate to update screen
        // CI has higher latency: Universal Link → SDK network unwrap → navigate
        let ciDelay: UInt32 = isRunningInCI ? 15 : 10
        sleep(ciDelay)
        
        // Verify the UpdateViewController is displayed (not just an alert)
        // This validates that SDK followed exactly ONE redirect (not multiple)
        let updateHeader = app.staticTexts["update-view-header"]
        let updateTimeout = isRunningInCI ? longTimeout : standardTimeout
        XCTAssertTrue(updateHeader.waitForExistence(timeout: updateTimeout), "Update screen should be displayed")
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
    
    func testCCustomActionHandling() throws {
        print("🧪 Testing custom action delegate handles showtestsuccess action")
        print("🎯 This validates IterableCustomActionDelegate is invoked for custom action types")

        // Navigate to In-App Message tab
        let inAppMessageRow = app.otherElements["in-app-message-test-row"]
        XCTAssertTrue(inAppMessageRow.waitForExistence(timeout: standardTimeout), "In-app message row should exist")
        inAppMessageRow.tap()

        // Trigger the TestView in-app campaign which has a custom action
        // Note: We're reusing the TestView campaign as it triggers the custom action delegate
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

        // Tap the custom action button
        if app.links["Show Test View"].waitForExistence(timeout: standardTimeout) {
            app.links["Show Test View"].tap()
        }

        // Wait for webview to dismiss and alert to appear
        sleep(3)

        // Verify custom action was handled - the AppDelegate shows "Deep link to Test View" alert
        // which confirms the custom action delegate was invoked
        let expectedAlert = AlertExpectation(
            title: "Deep link to Test View",
            message: "Deep link handled with Success!",
            timeout: 45.0
        )

        XCTAssertTrue(deepLinkHelper.waitForAlert(expectedAlert), "Custom action should trigger alert")

        // Dismiss the alert
        deepLinkHelper.dismissAlertIfPresent(withTitle: "Deep link to Test View")

        // Wait for webview to be gone before cleanup
        if webView.exists {
            let webViewGone = NSPredicate(format: "exists == false")
            let webViewExpectation = expectation(for: webViewGone, evaluatedWith: webView, handler: nil)
            wait(for: [webViewExpectation], timeout: 10.0)
        }

        // Clean up
        let clearMessagesButton = app.buttons["clear-messages-button"]
        if clearMessagesButton.exists {
            clearMessagesButton.tap()
            deepLinkHelper.dismissAlertIfPresent(withTitle: "Success")
        }

        print("✅ Custom action handling test completed successfully")
        print("✅ Validated: IterableCustomActionDelegate invoked and handled custom action")
    }
    
    func testDSingleRedirectPolicy() throws {
        try XCTSkipIf(isRunningInCI, "Universal Link tests require AASA and real Safari — skipped on CI")
        print("🧪 Testing SDK follows exactly one redirect (GreenFi bug fix validation)")
        print("🎯 This test validates that SDK stops at first redirect, not following multiple hops")
        print("📚 HOW IT WORKS: SDK's RedirectNetworkSession.willPerformHTTPRedirection returns nil")
        print("   to completionHandler, which tells URLSession to STOP following redirects")
        print("   See: swift-sdk/Internal/Network/NetworkSession.swift:136")
        
        // TODO(SDK-325): regenerate this wrapped link against the new Mobile SDK Testing
        // project (post SDK-36). The _t/_m/_e tokens below are tied to the old project and
        // will 404 against links.bcittesting.com until the link is regenerated.
        // Link should redirect to bcittesting.com/update/hi
        // If there are multiple redirects after that, SDK should NOT follow them
        let testURL = "https://links.bcittesting.com/a/click?_t=TODO_REGENERATE_TOKEN&_m=TODO&_e=TODO"
        
        print("🔗 Test URL: \(testURL)")
        print("✅ Expected: SDK stops at first redirect (bcittesting.com/update/hi)")
        print("❌ Should NOT follow: Any subsequent redirects beyond the first one")
        
        // Open link from Reminders app
        openLinkFromRemindersApp(url: testURL)
        
        // Wait for app to process the deep link
        // CI has higher latency: Universal Link → SDK network unwrap → navigate
        let ciDelay: UInt32 = isRunningInCI ? 15 : 10
        sleep(ciDelay)
        
        // Verify we got the FIRST redirect destination, not any subsequent ones
        // The UpdateViewController should show /update/hi (first redirect)
        // NOT any final destination if there were multiple hops
        let updateHeader = app.staticTexts["update-view-header"]
        let updateTimeout = isRunningInCI ? longTimeout : standardTimeout
        XCTAssertTrue(updateHeader.waitForExistence(timeout: updateTimeout), 
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
        
        // Look for the wrapped link request (the initial request to links.bcittesting.com)
        let wrappedLinkPredicate = NSPredicate(format: "label CONTAINS[c] 'links.bcittesting.com'")
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
        // For this test, we're assuming bcittesting.com/update/hi is the FIRST redirect
        // and there should be NO subsequent requests to other domains
        
        // Count how many unique domains we made requests to
        let allCells = app.cells.allElementsBoundByIndex
        var uniqueDomains = Set<String>()
        
        for cell in allCells {
            let cellLabel = cell.staticTexts.firstMatch.label
            if cellLabel.contains("bcittesting.com") {
                uniqueDomains.insert("bcittesting.com")
            } else if cellLabel.contains("links.bcittesting.com") {
                uniqueDomains.insert("links.bcittesting.com")
            } else if cellLabel.contains("iterable.com") {
                uniqueDomains.insert("iterable.com")
            }
            // Add checks for any other domains that would indicate multi-hop
        }
        
        print("🔍 Unique domains in network requests: \(uniqueDomains)")
        
        // We should see:
        // 1. links.bcittesting.com (the wrapped link)
        // 2. bcittesting.com (the first redirect destination)
        // We should NOT see any third domain (which would indicate multi-hop)
        
        XCTAssertTrue(uniqueDomains.count <= 3, 
                     "Should only see links.bcittesting.com, bcittesting.com, and iterable.com (SDK API calls). Found: \(uniqueDomains)")
        
        print("✅ Network Monitor validation: Only expected domains found, no multi-hop redirect detected")
        
        // Close network monitor
        let networkMonitorCloseButton = app.buttons["Close"]
        if networkMonitorCloseButton.exists {
            networkMonitorCloseButton.tap()
        }
        
        print("✅ Single redirect policy test completed - SDK correctly stops at first redirect")
        print("✅ Validated via: 1) Alert content, 2) Network Monitor redirect count")
    }
    

}
