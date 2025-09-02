import XCTest
import UserNotifications
@testable import IterableSDK

class EmbeddedMessageIntegrationTests: IntegrationTestBase {
    
    // MARK: - Test Properties
    
    var embeddedMessageDisplayed = false
    var userEligibilityChanged = false
    var profileUpdated = false
    var embeddedMessageInteracted = false
    
    // MARK: - Test Cases
    
    func testEmbeddedMessageEligibilityWorkflow() {
        // Complete workflow: User ineligible -> Eligible -> Message display -> Interaction
        
        // Step 1: Initialize SDK and embedded message system
        validateSDKInitialization()
        screenshotCapture.captureScreenshot(named: "01-sdk-initialized")
        
        // Step 2: Enable embedded messaging
        let enableEmbeddedButton = app.buttons["enable-embedded-messaging"]
        XCTAssertTrue(enableEmbeddedButton.waitForExistence(timeout: standardTimeout))
        enableEmbeddedButton.tap()
        
        screenshotCapture.captureScreenshot(named: "02-embedded-enabled")
        
        // Step 3: Set user as initially ineligible
        let setIneligibleButton = app.buttons["set-user-ineligible"]
        XCTAssertTrue(setIneligibleButton.waitForExistence(timeout: standardTimeout))
        setIneligibleButton.tap()
        
        // Verify user is ineligible
        let ineligibleStatusIndicator = app.staticTexts["user-ineligible-status"]
        XCTAssertTrue(ineligibleStatusIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "03-user-ineligible")
        
        // Step 4: Create embedded message campaign with eligibility rules
        let createEmbeddedCampaignButton = app.buttons["create-embedded-campaign"]
        XCTAssertTrue(createEmbeddedCampaignButton.waitForExistence(timeout: standardTimeout))
        createEmbeddedCampaignButton.tap()
        
        // Wait for campaign creation
        let campaignCreatedIndicator = app.staticTexts["embedded-campaign-created"]
        XCTAssertTrue(campaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "04-campaign-created")
        
        // Step 5: Verify no embedded message appears when ineligible
        let checkEmbeddedButton = app.buttons["check-embedded-messages"]
        XCTAssertTrue(checkEmbeddedButton.waitForExistence(timeout: standardTimeout))
        checkEmbeddedButton.tap()
        
        // No embedded message should be present
        let embeddedMessage = app.otherElements["iterable-embedded-message"]
        XCTAssertFalse(embeddedMessage.exists)
        
        let noEmbeddedIndicator = app.staticTexts["no-embedded-messages"]
        XCTAssertTrue(noEmbeddedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "05-no-embedded-ineligible")
        
        // Step 6: Make user eligible for embedded messages
        let makeEligibleButton = app.buttons["make-user-eligible"]
        XCTAssertTrue(makeEligibleButton.waitForExistence(timeout: standardTimeout))
        makeEligibleButton.tap()
        
        // Verify eligibility change
        let eligibleStatusIndicator = app.staticTexts["user-eligible-status"]
        XCTAssertTrue(eligibleStatusIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "06-user-eligible")
        
        // Step 7: Send silent push to trigger embedded message sync
        let sendSilentPushButton = app.buttons["send-silent-push-embedded"]
        XCTAssertTrue(sendSilentPushButton.waitForExistence(timeout: standardTimeout))
        sendSilentPushButton.tap()
        
        // Wait for silent push processing
        let silentPushProcessedIndicator = app.staticTexts["embedded-silent-push-processed"]
        XCTAssertTrue(silentPushProcessedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "07-silent-push-processed")
        
        // Step 8: Verify embedded message now appears
        checkEmbeddedButton.tap()
        
        validateEmbeddedMessageDisplayed()
        
        // Step 9: Test embedded message interaction
        let embeddedActionButton = app.buttons["embedded-message-action"]
        XCTAssertTrue(embeddedActionButton.waitForExistence(timeout: standardTimeout))
        embeddedActionButton.tap()
        
        screenshotCapture.captureScreenshot(named: "08-embedded-interaction")
        
        // Step 10: Verify embedded message metrics
        validateMetrics(eventType: "embeddedMessageReceived", expectedCount: 1)
        validateMetrics(eventType: "embeddedClick", expectedCount: 1)
        
        screenshotCapture.captureScreenshot(named: "09-metrics-validated")
    }
    
    func testUserProfileUpdatesAffectingEligibility() {
        // Test dynamic profile changes affecting embedded message eligibility
        
        validateSDKInitialization()
        
        // Enable embedded messaging
        let enableEmbeddedButton = app.buttons["enable-embedded-messaging"]
        XCTAssertTrue(enableEmbeddedButton.waitForExistence(timeout: standardTimeout))
        enableEmbeddedButton.tap()
        
        // Create embedded campaign based on profile field
        let createProfileBasedCampaignButton = app.buttons["create-profile-based-campaign"]
        XCTAssertTrue(createProfileBasedCampaignButton.waitForExistence(timeout: standardTimeout))
        createProfileBasedCampaignButton.tap()
        
        // Wait for campaign creation
        let profileCampaignCreatedIndicator = app.staticTexts["profile-based-campaign-created"]
        XCTAssertTrue(profileCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "profile-campaign-created")
        
        // Set profile field that makes user ineligible
        let setProfileIneligibleButton = app.buttons["set-profile-field-ineligible"]
        XCTAssertTrue(setProfileIneligibleButton.waitForExistence(timeout: standardTimeout))
        setProfileIneligibleButton.tap()
        
        // Verify no embedded message
        let checkEmbeddedButton = app.buttons["check-embedded-messages"]
        checkEmbeddedButton.tap()
        
        let embeddedMessage = app.otherElements["iterable-embedded-message"]
        XCTAssertFalse(embeddedMessage.exists)
        
        screenshotCapture.captureScreenshot(named: "profile-ineligible")
        
        // Update profile field to make user eligible
        let updateProfileButton = app.buttons["update-profile-field-eligible"]
        XCTAssertTrue(updateProfileButton.waitForExistence(timeout: standardTimeout))
        updateProfileButton.tap()
        
        // Trigger profile sync
        let syncProfileButton = app.buttons["sync-profile-changes"]
        XCTAssertTrue(syncProfileButton.waitForExistence(timeout: standardTimeout))
        syncProfileButton.tap()
        
        // Wait for profile update
        let profileUpdatedIndicator = app.staticTexts["profile-updated"]
        XCTAssertTrue(profileUpdatedIndicator.waitForExistence(timeout: networkTimeout))
        
        // Check for embedded message after profile update
        checkEmbeddedButton.tap()
        
        // Embedded message should now appear
        XCTAssertTrue(embeddedMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "profile-eligible-message-shown")
        
        // Verify profile update metrics
        validateMetrics(eventType: "profileUpdate", expectedCount: 1)
    }
    
    func testEmbeddedMessagePlacementAndDisplay() {
        // Test embedded message placement in different app views
        
        validateSDKInitialization()
        
        // Enable embedded messaging
        let enableEmbeddedButton = app.buttons["enable-embedded-messaging"]
        XCTAssertTrue(enableEmbeddedButton.waitForExistence(timeout: standardTimeout))
        enableEmbeddedButton.tap()
        
        // Make user eligible
        let makeEligibleButton = app.buttons["make-user-eligible"]
        XCTAssertTrue(makeEligibleButton.waitForExistence(timeout: standardTimeout))
        makeEligibleButton.tap()
        
        // Create embedded messages for different placements
        let createMultiplePlacementsButton = app.buttons["create-multiple-placements"]
        XCTAssertTrue(createMultiplePlacementsButton.waitForExistence(timeout: standardTimeout))
        createMultiplePlacementsButton.tap()
        
        // Wait for campaigns creation
        let multiplePlacementsCreatedIndicator = app.staticTexts["multiple-placements-created"]
        XCTAssertTrue(multiplePlacementsCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "multiple-placements-created")
        
        // Navigate to home view and check for embedded message
        let navigateHomeButton = app.buttons["navigate-to-home"]
        XCTAssertTrue(navigateHomeButton.waitForExistence(timeout: standardTimeout))
        navigateHomeButton.tap()
        
        let homeEmbeddedMessage = app.otherElements["home-embedded-message"]
        XCTAssertTrue(homeEmbeddedMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "home-embedded-displayed")
        
        // Navigate to product list view
        let navigateProductsButton = app.buttons["navigate-to-products"]
        XCTAssertTrue(navigateProductsButton.waitForExistence(timeout: standardTimeout))
        navigateProductsButton.tap()
        
        let productsEmbeddedMessage = app.otherElements["products-embedded-message"]
        XCTAssertTrue(productsEmbeddedMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "products-embedded-displayed")
        
        // Navigate to cart view
        let navigateCartButton = app.buttons["navigate-to-cart"]
        XCTAssertTrue(navigateCartButton.waitForExistence(timeout: standardTimeout))
        navigateCartButton.tap()
        
        let cartEmbeddedMessage = app.otherElements["cart-embedded-message"]
        XCTAssertTrue(cartEmbeddedMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "cart-embedded-displayed")
        
        // Verify placement-specific metrics
        validateMetrics(eventType: "embeddedMessageImpression", expectedCount: 3)
    }
    
    func testEmbeddedMessageDeepLinkHandling() {
        // Test deep links from embedded message content
        
        validateSDKInitialization()
        
        // Enable embedded messaging and make user eligible
        let enableEmbeddedButton = app.buttons["enable-embedded-messaging"]
        XCTAssertTrue(enableEmbeddedButton.waitForExistence(timeout: standardTimeout))
        enableEmbeddedButton.tap()
        
        let makeEligibleButton = app.buttons["make-user-eligible"]
        makeEligibleButton.tap()
        
        // Create embedded message with deep link
        let createDeepLinkEmbeddedButton = app.buttons["create-embedded-with-deeplink"]
        XCTAssertTrue(createDeepLinkEmbeddedButton.waitForExistence(timeout: standardTimeout))
        createDeepLinkEmbeddedButton.tap()
        
        // Wait for campaign creation
        let deepLinkCampaignCreatedIndicator = app.staticTexts["embedded-deeplink-campaign-created"]
        XCTAssertTrue(deepLinkCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        // Navigate to view with embedded message
        let navigateToEmbeddedViewButton = app.buttons["navigate-to-embedded-view"]
        XCTAssertTrue(navigateToEmbeddedViewButton.waitForExistence(timeout: standardTimeout))
        navigateToEmbeddedViewButton.tap()
        
        // Verify embedded message with deep link is displayed
        let embeddedWithDeepLinkMessage = app.otherElements["embedded-deeplink-message"]
        XCTAssertTrue(embeddedWithDeepLinkMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "embedded-deeplink-displayed")
        
        // Tap the deep link in embedded message
        let embeddedDeepLinkButton = app.buttons["embedded-deeplink-button"]
        XCTAssertTrue(embeddedDeepLinkButton.waitForExistence(timeout: standardTimeout))
        embeddedDeepLinkButton.tap()
        
        screenshotCapture.captureScreenshot(named: "embedded-deeplink-tapped")
        
        // Verify deep link navigation occurred
        validateDeepLinkHandled(expectedDestination: "offer-detail-view")
        
        // Verify deep link click metrics
        validateMetrics(eventType: "embeddedClick", expectedCount: 1)
    }
    
    func testEmbeddedMessageButtonInteractions() {
        // Test various button interactions and actions in embedded messages
        
        validateSDKInitialization()
        
        // Enable embedded messaging and make user eligible
        let enableEmbeddedButton = app.buttons["enable-embedded-messaging"]
        XCTAssertTrue(enableEmbeddedButton.waitForExistence(timeout: standardTimeout))
        enableEmbeddedButton.tap()
        
        let makeEligibleButton = app.buttons["make-user-eligible"]
        makeEligibleButton.tap()
        
        // Create embedded message with multiple buttons
        let createMultiButtonEmbeddedButton = app.buttons["create-multi-button-embedded"]
        XCTAssertTrue(createMultiButtonEmbeddedButton.waitForExistence(timeout: standardTimeout))
        createMultiButtonEmbeddedButton.tap()
        
        // Wait for campaign creation
        let multiButtonCampaignCreatedIndicator = app.staticTexts["multi-button-campaign-created"]
        XCTAssertTrue(multiButtonCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        // Navigate to view with embedded message
        let navigateToEmbeddedButton = app.buttons["navigate-to-embedded-view"]
        XCTAssertTrue(navigateToEmbeddedButton.waitForExistence(timeout: standardTimeout))
        navigateToEmbeddedButton.tap()
        
        // Verify embedded message with buttons is displayed
        let multiButtonEmbeddedMessage = app.otherElements["multi-button-embedded-message"]
        XCTAssertTrue(multiButtonEmbeddedMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "multi-button-embedded-displayed")
        
        // Test primary action button
        let primaryActionButton = app.buttons["embedded-primary-action"]
        XCTAssertTrue(primaryActionButton.waitForExistence(timeout: standardTimeout))
        primaryActionButton.tap()
        
        // Verify primary action handling
        let primaryActionHandledIndicator = app.staticTexts["primary-action-handled"]
        XCTAssertTrue(primaryActionHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "primary-action-handled")
        
        // Navigate back to embedded message
        navigateToEmbeddedButton.tap()
        
        // Test secondary action button
        let secondaryActionButton = app.buttons["embedded-secondary-action"]
        XCTAssertTrue(secondaryActionButton.waitForExistence(timeout: standardTimeout))
        secondaryActionButton.tap()
        
        // Verify secondary action handling
        let secondaryActionHandledIndicator = app.staticTexts["secondary-action-handled"]
        XCTAssertTrue(secondaryActionHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "secondary-action-handled")
        
        // Navigate back and test dismiss button
        navigateToEmbeddedButton.tap()
        
        let dismissButton = app.buttons["embedded-dismiss-button"]
        XCTAssertTrue(dismissButton.waitForExistence(timeout: standardTimeout))
        dismissButton.tap()
        
        // Verify message is dismissed
        XCTAssertFalse(multiButtonEmbeddedMessage.exists)
        
        // Verify button interaction metrics
        validateMetrics(eventType: "embeddedClick", expectedCount: 3) // Primary, secondary, dismiss
    }
    
    func testUserListSubscriptionToggle() {
        // Test user subscription to lists affecting embedded message eligibility
        
        validateSDKInitialization()
        
        // Enable embedded messaging
        let enableEmbeddedButton = app.buttons["enable-embedded-messaging"]
        XCTAssertTrue(enableEmbeddedButton.waitForExistence(timeout: standardTimeout))
        enableEmbeddedButton.tap()
        
        // Create embedded campaign based on list membership
        let createListBasedCampaignButton = app.buttons["create-list-based-campaign"]
        XCTAssertTrue(createListBasedCampaignButton.waitForExistence(timeout: standardTimeout))
        createListBasedCampaignButton.tap()
        
        // Wait for campaign creation
        let listCampaignCreatedIndicator = app.staticTexts["list-based-campaign-created"]
        XCTAssertTrue(listCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "list-campaign-created")
        
        // User initially not on list - no embedded message
        let checkEmbeddedButton = app.buttons["check-embedded-messages"]
        checkEmbeddedButton.tap()
        
        let embeddedMessage = app.otherElements["iterable-embedded-message"]
        XCTAssertFalse(embeddedMessage.exists)
        
        screenshotCapture.captureScreenshot(named: "not-on-list-no-message")
        
        // Subscribe user to list
        let subscribeToListButton = app.buttons["subscribe-to-embedded-list"]
        XCTAssertTrue(subscribeToListButton.waitForExistence(timeout: standardTimeout))
        subscribeToListButton.tap()
        
        // Wait for subscription confirmation
        let subscriptionConfirmedIndicator = app.staticTexts["list-subscription-confirmed"]
        XCTAssertTrue(subscriptionConfirmedIndicator.waitForExistence(timeout: networkTimeout))
        
        // Send silent push to sync eligibility change
        let sendSilentPushButton = app.buttons["send-silent-push-list-sync"]
        XCTAssertTrue(sendSilentPushButton.waitForExistence(timeout: standardTimeout))
        sendSilentPushButton.tap()
        
        // Wait for sync
        let listSyncCompleteIndicator = app.staticTexts["list-sync-complete"]
        XCTAssertTrue(listSyncCompleteIndicator.waitForExistence(timeout: networkTimeout))
        
        // Check for embedded message after subscription
        checkEmbeddedButton.tap()
        
        // Embedded message should now appear
        XCTAssertTrue(embeddedMessage.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "subscribed-message-shown")
        
        // Unsubscribe from list
        let unsubscribeFromListButton = app.buttons["unsubscribe-from-embedded-list"]
        XCTAssertTrue(unsubscribeFromListButton.waitForExistence(timeout: standardTimeout))
        unsubscribeFromListButton.tap()
        
        // Wait for unsubscription
        let unsubscriptionConfirmedIndicator = app.staticTexts["list-unsubscription-confirmed"]
        XCTAssertTrue(unsubscriptionConfirmedIndicator.waitForExistence(timeout: networkTimeout))
        
        // Send silent push to sync removal
        let sendRemovalSyncPushButton = app.buttons["send-silent-push-removal-sync"]
        sendRemovalSyncPushButton.tap()
        
        // Wait for removal sync
        let removalSyncCompleteIndicator = app.staticTexts["removal-sync-complete"]
        XCTAssertTrue(removalSyncCompleteIndicator.waitForExistence(timeout: networkTimeout))
        
        // Check embedded messages - should be removed
        checkEmbeddedButton.tap()
        
        // Message should no longer appear
        XCTAssertFalse(embeddedMessage.exists)
        
        screenshotCapture.captureScreenshot(named: "unsubscribed-message-removed")
        
        // Verify subscription toggle metrics
        validateMetrics(eventType: "listSubscribe", expectedCount: 1)
        validateMetrics(eventType: "listUnsubscribe", expectedCount: 1)
    }
    
    func testEmbeddedMessageContentUpdates() {
        // Test embedded message content updates and refresh
        
        validateSDKInitialization()
        
        // Enable embedded messaging and make user eligible
        let enableEmbeddedButton = app.buttons["enable-embedded-messaging"]
        XCTAssertTrue(enableEmbeddedButton.waitForExistence(timeout: standardTimeout))
        enableEmbeddedButton.tap()
        
        let makeEligibleButton = app.buttons["make-user-eligible"]
        makeEligibleButton.tap()
        
        // Create initial embedded message
        let createInitialEmbeddedButton = app.buttons["create-initial-embedded"]
        XCTAssertTrue(createInitialEmbeddedButton.waitForExistence(timeout: standardTimeout))
        createInitialEmbeddedButton.tap()
        
        // Wait for campaign creation
        let initialCampaignCreatedIndicator = app.staticTexts["initial-embedded-campaign-created"]
        XCTAssertTrue(initialCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        // Display initial message
        let navigateToEmbeddedButton = app.buttons["navigate-to-embedded-view"]
        XCTAssertTrue(navigateToEmbeddedButton.waitForExistence(timeout: standardTimeout))
        navigateToEmbeddedButton.tap()
        
        let initialEmbeddedMessage = app.otherElements["initial-embedded-message"]
        XCTAssertTrue(initialEmbeddedMessage.waitForExistence(timeout: standardTimeout))
        
        // Verify initial content
        let initialContentText = app.staticTexts["initial-embedded-content"]
        XCTAssertTrue(initialContentText.exists)
        
        screenshotCapture.captureScreenshot(named: "initial-embedded-content")
        
        // Update embedded message content
        let updateEmbeddedContentButton = app.buttons["update-embedded-content"]
        XCTAssertTrue(updateEmbeddedContentButton.waitForExistence(timeout: standardTimeout))
        updateEmbeddedContentButton.tap()
        
        // Send silent push to trigger content refresh
        let sendContentUpdatePushButton = app.buttons["send-content-update-push"]
        XCTAssertTrue(sendContentUpdatePushButton.waitForExistence(timeout: standardTimeout))
        sendContentUpdatePushButton.tap()
        
        // Wait for content update
        let contentUpdatedIndicator = app.staticTexts["embedded-content-updated"]
        XCTAssertTrue(contentUpdatedIndicator.waitForExistence(timeout: networkTimeout))
        
        // Refresh embedded message view
        let refreshEmbeddedButton = app.buttons["refresh-embedded-view"]
        XCTAssertTrue(refreshEmbeddedButton.waitForExistence(timeout: standardTimeout))
        refreshEmbeddedButton.tap()
        
        // Verify updated content
        let updatedContentText = app.staticTexts["updated-embedded-content"]
        XCTAssertTrue(updatedContentText.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "updated-embedded-content")
        
        // Verify content update metrics
        validateMetrics(eventType: "embeddedMessageUpdate", expectedCount: 1)
    }
    
    func testEmbeddedMessageNetworkHandling() {
        // Test embedded message behavior with network connectivity issues
        
        validateSDKInitialization()
        
        // Enable embedded messaging
        let enableEmbeddedButton = app.buttons["enable-embedded-messaging"]
        XCTAssertTrue(enableEmbeddedButton.waitForExistence(timeout: standardTimeout))
        enableEmbeddedButton.tap()
        
        // Make user eligible
        let makeEligibleButton = app.buttons["make-user-eligible"]
        makeEligibleButton.tap()
        
        // Enable network failure simulation
        let enableNetworkFailureButton = app.buttons["enable-network-failure-simulation"]
        XCTAssertTrue(enableNetworkFailureButton.waitForExistence(timeout: standardTimeout))
        enableNetworkFailureButton.tap()
        
        // Attempt to create embedded campaign while network is down
        let createEmbeddedOfflineButton = app.buttons["create-embedded-offline"]
        XCTAssertTrue(createEmbeddedOfflineButton.waitForExistence(timeout: standardTimeout))
        createEmbeddedOfflineButton.tap()
        
        // Verify offline handling
        let offlineHandledIndicator = app.staticTexts["embedded-offline-handled"]
        XCTAssertTrue(offlineHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "embedded-offline-handled")
        
        // Restore network
        let restoreNetworkButton = app.buttons["restore-network"]
        XCTAssertTrue(restoreNetworkButton.waitForExistence(timeout: standardTimeout))
        restoreNetworkButton.tap()
        
        // Retry embedded message creation
        let retryEmbeddedCreationButton = app.buttons["retry-embedded-creation"]
        XCTAssertTrue(retryEmbeddedCreationButton.waitForExistence(timeout: standardTimeout))
        retryEmbeddedCreationButton.tap()
        
        // Verify successful retry
        let retrySuccessIndicator = app.staticTexts["embedded-creation-retry-success"]
        XCTAssertTrue(retrySuccessIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "embedded-network-retry-success")
    }
}