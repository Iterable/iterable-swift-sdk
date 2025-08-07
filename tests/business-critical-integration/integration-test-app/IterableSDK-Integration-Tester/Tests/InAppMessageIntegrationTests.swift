import XCTest
import UserNotifications
@testable import IterableSDK

class InAppMessageIntegrationTests: IntegrationTestBase {
    
    // MARK: - Test Properties
    
    var silentPushReceived = false
    var inAppMessageDisplayed = false
    var inAppMessageInteracted = false
    var deepLinkHandled = false
    
    // MARK: - Test Cases
    
    func testInAppMessageSilentPushWorkflow() {
        // Complete workflow: Silent push -> Message fetch -> Display -> Interaction -> Metrics
        
        // Step 1: Initialize SDK and ensure in-app messaging is enabled
        validateSDKInitialization()
        screenshotCapture.captureScreenshot(named: "01-sdk-initialized")
        
        // Step 2: Enable in-app message delegate and listeners
        let enableInAppButton = app.buttons["enable-inapp-messaging"]
        XCTAssertTrue(enableInAppButton.waitForExistence(timeout: standardTimeout))
        enableInAppButton.tap()
        
        screenshotCapture.captureScreenshot(named: "02-inapp-enabled")
        
        // Step 3: Trigger in-app message campaign creation via backend
        let createCampaignButton = app.buttons["create-inapp-campaign"]
        XCTAssertTrue(createCampaignButton.waitForExistence(timeout: standardTimeout))
        createCampaignButton.tap()
        
        // Wait for campaign creation confirmation
        let campaignCreatedIndicator = app.staticTexts["inapp-campaign-created"]
        XCTAssertTrue(campaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "03-campaign-created")
        
        // Step 4: Send silent push to trigger message sync
        let sendSilentPushButton = app.buttons["send-silent-push-inapp"]
        XCTAssertTrue(sendSilentPushButton.waitForExistence(timeout: standardTimeout))
        sendSilentPushButton.tap()
        
        // Step 5: Verify silent push was processed (no visible notification)
        let silentPushProcessedIndicator = app.staticTexts["silent-push-processed"]
        XCTAssertTrue(silentPushProcessedIndicator.waitForExistence(timeout: networkTimeout))
        
        // Ensure no visible notification appeared (silent push should not show UI)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        
        screenshotCapture.captureScreenshot(named: "04-silent-push-processed")
        
        // Step 6: Verify in-app message fetch API call
        XCTAssertTrue(waitForAPICall(endpoint: "/api/inApp/getMessages", timeout: networkTimeout))
        
        // Step 7: Trigger in-app message display
        let triggerInAppButton = app.buttons["trigger-inapp-display"]
        XCTAssertTrue(triggerInAppButton.waitForExistence(timeout: standardTimeout))
        triggerInAppButton.tap()
        
        // Step 8: Validate in-app message is displayed
        validateInAppMessageDisplayed()
        
        // Step 9: Test message interaction (tap button)
        let inAppButton = app.buttons["inapp-learn-more-button"]
        XCTAssertTrue(inAppButton.waitForExistence(timeout: standardTimeout))
        inAppButton.tap()
        
        screenshotCapture.captureScreenshot(named: "05-inapp-button-tapped")
        
        // Step 10: Verify in-app open metrics tracking
        validateMetrics(eventType: "inAppOpen", expectedCount: 1)
        
        // Step 11: Verify in-app click metrics tracking  
        validateMetrics(eventType: "inAppClick", expectedCount: 1)
        
        screenshotCapture.captureScreenshot(named: "06-metrics-validated")
    }
    
    func testInAppMessageDeepLinkHandling() {
        // Test deep link navigation from in-app messages
        
        validateSDKInitialization()
        
        // Create in-app message with deep link
        let createDeepLinkInAppButton = app.buttons["create-inapp-with-deeplink"]
        XCTAssertTrue(createDeepLinkInAppButton.waitForExistence(timeout: standardTimeout))
        createDeepLinkInAppButton.tap()
        
        // Wait for campaign creation
        let campaignCreatedIndicator = app.staticTexts["inapp-deeplink-campaign-created"]
        XCTAssertTrue(campaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        // Trigger message display
        let triggerInAppButton = app.buttons["trigger-inapp-display"]
        XCTAssertTrue(triggerInAppButton.waitForExistence(timeout: standardTimeout))
        triggerInAppButton.tap()
        
        // Validate message is displayed
        validateInAppMessageDisplayed()
        
        // Tap deep link button in in-app message
        let deepLinkButton = app.buttons["inapp-deeplink-button"]
        XCTAssertTrue(deepLinkButton.waitForExistence(timeout: standardTimeout))
        deepLinkButton.tap()
        
        screenshotCapture.captureScreenshot(named: "inapp-deeplink-tapped")
        
        // Verify deep link handler was called and navigation occurred
        validateDeepLinkHandled(expectedDestination: "product-detail-view")
        
        // Verify deep link click metrics
        validateMetrics(eventType: "inAppClick", expectedCount: 1)
    }
    
    func testMultipleInAppMessagesQueue() {
        // Test handling of multiple in-app messages and queue management
        
        validateSDKInitialization()
        
        // Create multiple in-app message campaigns
        let createMultipleButton = app.buttons["create-multiple-inapp-campaigns"]
        XCTAssertTrue(createMultipleButton.waitForExistence(timeout: standardTimeout))
        createMultipleButton.tap()
        
        // Wait for campaigns creation
        let multipleCampaignsCreatedIndicator = app.staticTexts["multiple-campaigns-created"]
        XCTAssertTrue(multipleCampaignsCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "multiple-campaigns-created")
        
        // Send silent push to sync multiple messages
        let sendSilentPushButton = app.buttons["send-silent-push-multiple"]
        XCTAssertTrue(sendSilentPushButton.waitForExistence(timeout: standardTimeout))
        sendSilentPushButton.tap()
        
        // Wait for sync completion
        let multiSyncCompleteIndicator = app.staticTexts["multi-message-sync-complete"]
        XCTAssertTrue(multiSyncCompleteIndicator.waitForExistence(timeout: networkTimeout))
        
        // Trigger first message display
        let triggerFirstButton = app.buttons["trigger-first-inapp"]
        XCTAssertTrue(triggerFirstButton.waitForExistence(timeout: standardTimeout))
        triggerFirstButton.tap()
        
        // Validate first message appears
        let firstInAppMessage = app.otherElements["iterable-in-app-message-1"]
        XCTAssertTrue(firstInAppMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "first-inapp-displayed")
        
        // Dismiss first message
        let dismissFirstButton = app.buttons["dismiss-first-inapp"]
        dismissFirstButton.tap()
        
        // Trigger second message display
        let triggerSecondButton = app.buttons["trigger-second-inapp"]
        XCTAssertTrue(triggerSecondButton.waitForExistence(timeout: standardTimeout))
        triggerSecondButton.tap()
        
        // Validate second message appears
        let secondInAppMessage = app.otherElements["iterable-in-app-message-2"]
        XCTAssertTrue(secondInAppMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "second-inapp-displayed")
        
        // Verify queue management metrics
        validateMetrics(eventType: "inAppOpen", expectedCount: 2)
    }
    
    func testInAppMessageTriggerConditions() {
        // Test different trigger conditions: immediate, event-based, never
        
        validateSDKInitialization()
        
        // Test immediate trigger
        let createImmediateButton = app.buttons["create-immediate-inapp"]
        XCTAssertTrue(createImmediateButton.waitForExistence(timeout: standardTimeout))
        createImmediateButton.tap()
        
        // Immediate message should appear without explicit trigger
        let immediateMessage = app.otherElements["immediate-inapp-message"]
        XCTAssertTrue(immediateMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "immediate-inapp-displayed")
        
        // Dismiss immediate message
        let dismissImmediateButton = app.buttons["dismiss-immediate"]
        dismissImmediateButton.tap()
        
        // Test event-based trigger
        let createEventBasedButton = app.buttons["create-event-based-inapp"]
        XCTAssertTrue(createEventBasedButton.waitForExistence(timeout: standardTimeout))
        createEventBasedButton.tap()
        
        // Message should not appear until event is triggered
        let eventMessage = app.otherElements["event-based-inapp-message"]
        XCTAssertFalse(eventMessage.exists)
        
        // Trigger the required event
        let triggerEventButton = app.buttons["trigger-custom-event"]
        XCTAssertTrue(triggerEventButton.waitForExistence(timeout: standardTimeout))
        triggerEventButton.tap()
        
        // Now message should appear
        XCTAssertTrue(eventMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "event-based-inapp-displayed")
        
        // Test "never" trigger (message shouldn't display)
        let createNeverButton = app.buttons["create-never-inapp"]
        XCTAssertTrue(createNeverButton.waitForExistence(timeout: standardTimeout))
        createNeverButton.tap()
        
        // Wait reasonable amount of time
        sleep(5)
        
        // Message with "never" trigger should not appear
        let neverMessage = app.otherElements["never-trigger-inapp-message"]
        XCTAssertFalse(neverMessage.exists)
        
        screenshotCapture.captureScreenshot(named: "never-trigger-validated")
    }
    
    func testInAppMessageExpiration() {
        // Test message expiration and cleanup
        
        validateSDKInitialization()
        
        // Create in-app message with short expiration
        let createExpiringButton = app.buttons["create-expiring-inapp"]
        XCTAssertTrue(createExpiringButton.waitForExistence(timeout: standardTimeout))
        createExpiringButton.tap()
        
        // Verify message is initially available
        let triggerExpiringButton = app.buttons["trigger-expiring-inapp"]
        XCTAssertTrue(triggerExpiringButton.waitForExistence(timeout: standardTimeout))
        triggerExpiringButton.tap()
        
        let expiringMessage = app.otherElements["expiring-inapp-message"]
        XCTAssertTrue(expiringMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "expiring-message-displayed")
        
        // Dismiss message
        let dismissExpiringButton = app.buttons["dismiss-expiring"]
        dismissExpiringButton.tap()
        
        // Wait for expiration (simulate time passage)
        let simulateExpirationButton = app.buttons["simulate-message-expiration"]
        XCTAssertTrue(simulateExpirationButton.waitForExistence(timeout: standardTimeout))
        simulateExpirationButton.tap()
        
        // Try to trigger expired message - should not appear
        triggerExpiringButton.tap()
        
        // Wait reasonable time
        sleep(3)
        
        // Expired message should not appear
        XCTAssertFalse(expiringMessage.exists)
        
        // Verify expiration cleanup metrics
        let expirationCleanedIndicator = app.staticTexts["message-expiration-cleaned"]
        XCTAssertTrue(expirationCleanedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "expiration-validated")
    }
    
    func testInAppMessageCustomData() {
        // Test in-app messages with custom data fields
        
        validateSDKInitialization()
        
        // Create in-app message with custom data
        let createCustomDataButton = app.buttons["create-custom-data-inapp"]
        XCTAssertTrue(createCustomDataButton.waitForExistence(timeout: standardTimeout))
        createCustomDataButton.tap()
        
        // Wait for campaign creation
        let customDataCampaignCreated = app.staticTexts["custom-data-campaign-created"]
        XCTAssertTrue(customDataCampaignCreated.waitForExistence(timeout: networkTimeout))
        
        // Trigger message display
        let triggerCustomDataButton = app.buttons["trigger-custom-data-inapp"]
        XCTAssertTrue(triggerCustomDataButton.waitForExistence(timeout: standardTimeout))
        triggerCustomDataButton.tap()
        
        // Verify message with custom data is displayed
        let customDataMessage = app.otherElements["custom-data-inapp-message"]
        XCTAssertTrue(customDataMessage.waitForExistence(timeout: standardTimeout))
        
        // Verify custom data fields are processed correctly
        let customDataProcessedIndicator = app.staticTexts["custom-data-processed"]
        XCTAssertTrue(customDataProcessedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "custom-data-inapp-displayed")
        
        // Interact with message to test custom data handling
        let customDataButton = app.buttons["custom-data-action-button"]
        XCTAssertTrue(customDataButton.waitForExistence(timeout: standardTimeout))
        customDataButton.tap()
        
        // Verify custom data was handled correctly
        let customDataHandledIndicator = app.staticTexts["custom-data-handled"]
        XCTAssertTrue(customDataHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "custom-data-handled")
        
        // Validate metrics include custom data
        validateMetrics(eventType: "inAppClick", expectedCount: 1)
    }
    
    func testInAppMessageDismissalAndClose() {
        // Test different dismissal methods and close behaviors
        
        validateSDKInitialization()
        
        // Create in-app message with close button
        let createCloseableButton = app.buttons["create-closeable-inapp"]
        XCTAssertTrue(createCloseableButton.waitForExistence(timeout: standardTimeout))
        createCloseableButton.tap()
        
        // Trigger message display
        let triggerCloseableButton = app.buttons["trigger-closeable-inapp"]
        XCTAssertTrue(triggerCloseableButton.waitForExistence(timeout: standardTimeout))
        triggerCloseableButton.tap()
        
        // Verify message is displayed
        let closeableMessage = app.otherElements["closeable-inapp-message"]
        XCTAssertTrue(closeableMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "closeable-message-displayed")
        
        // Test close button
        let closeButton = app.buttons["inapp-close-button"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: standardTimeout))
        closeButton.tap()
        
        // Verify message is dismissed
        XCTAssertFalse(closeableMessage.exists)
        
        // Verify close metrics
        validateMetrics(eventType: "inAppClose", expectedCount: 1)
        
        screenshotCapture.captureScreenshot(named: "message-closed")
        
        // Test background dismissal
        let createBackgroundDismissButton = app.buttons["create-background-dismiss-inapp"]
        XCTAssertTrue(createBackgroundDismissButton.waitForExistence(timeout: standardTimeout))
        createBackgroundDismissButton.tap()
        
        let triggerBackgroundDismissButton = app.buttons["trigger-background-dismiss-inapp"]
        XCTAssertTrue(triggerBackgroundDismissButton.waitForExistence(timeout: standardTimeout))
        triggerBackgroundDismissButton.tap()
        
        let backgroundDismissMessage = app.otherElements["background-dismiss-inapp-message"]
        XCTAssertTrue(backgroundDismissMessage.waitForExistence(timeout: standardTimeout))
        
        // Tap outside message (background tap to dismiss)
        let backgroundArea = app.otherElements["inapp-background-overlay"]
        backgroundArea.tap()
        
        // Verify message is dismissed
        XCTAssertFalse(backgroundDismissMessage.exists)
        
        screenshotCapture.captureScreenshot(named: "background-dismiss-validated")
    }
    
    func testInAppMessageNetworkFailureHandling() {
        // Test in-app message behavior with network failures
        
        validateSDKInitialization()
        
        // Enable network failure simulation
        let enableNetworkFailureButton = app.buttons["enable-network-failure-simulation"]
        XCTAssertTrue(enableNetworkFailureButton.waitForExistence(timeout: standardTimeout))
        enableNetworkFailureButton.tap()
        
        // Attempt to send silent push while network is down
        let sendSilentPushFailureButton = app.buttons["send-silent-push-network-failure"]
        XCTAssertTrue(sendSilentPushFailureButton.waitForExistence(timeout: standardTimeout))
        sendSilentPushFailureButton.tap()
        
        // Verify failure handling
        let networkFailureHandledIndicator = app.staticTexts["network-failure-handled"]
        XCTAssertTrue(networkFailureHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "network-failure-handled")
        
        // Restore network and retry
        let restoreNetworkButton = app.buttons["restore-network"]
        XCTAssertTrue(restoreNetworkButton.waitForExistence(timeout: standardTimeout))
        restoreNetworkButton.tap()
        
        // Retry silent push
        let retrySilentPushButton = app.buttons["retry-silent-push"]
        XCTAssertTrue(retrySilentPushButton.waitForExistence(timeout: standardTimeout))
        retrySilentPushButton.tap()
        
        // Verify successful retry
        let retrySuccessIndicator = app.staticTexts["silent-push-retry-success"]
        XCTAssertTrue(retrySuccessIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "network-retry-success")
    }
}