import XCTest
import UserNotifications
@testable import IterableSDK

class DeepLinkingIntegrationTests: IntegrationTestBase {
    
    // MARK: - Test Properties
    
    var deepLinkReceived = false
    var universalLinkHandled = false
    var deepLinkNavigationCompleted = false
    var attributionDataCaptured = false
    
    // MARK: - Test Cases
    
    func testUniversalLinkHandlingWorkflow() {
        // Complete workflow: Universal link -> App launch -> Parameter parsing -> Navigation
        
        // Step 1: Initialize SDK and configure deep link handling
        validateSDKInitialization()
        screenshotCapture.captureScreenshot(named: "01-sdk-initialized")
        
        // Step 2: Configure universal link domains
        let configureUniversalLinksButton = app.buttons["configure-universal-links"]
        XCTAssertTrue(configureUniversalLinksButton.waitForExistence(timeout: standardTimeout))
        configureUniversalLinksButton.tap()
        
        // Verify universal link configuration
        let universalLinksConfiguredIndicator = app.staticTexts["universal-links-configured"]
        XCTAssertTrue(universalLinksConfiguredIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "02-universal-links-configured")
        
        // Step 3: Create SMS campaign with deep link
        let createSMSCampaignButton = app.buttons["create-sms-deeplink-campaign"]
        XCTAssertTrue(createSMSCampaignButton.waitForExistence(timeout: standardTimeout))
        createSMSCampaignButton.tap()
        
        // Wait for campaign creation
        let smsCampaignCreatedIndicator = app.staticTexts["sms-deeplink-campaign-created"]
        XCTAssertTrue(smsCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "03-sms-campaign-created")
        
        // Step 4: Simulate SMS link tap (universal link)
        let simulateUniversalLinkButton = app.buttons["simulate-universal-link-tap"]
        XCTAssertTrue(simulateUniversalLinkButton.waitForExistence(timeout: standardTimeout))
        simulateUniversalLinkButton.tap()
        
        // Step 5: Verify app receives universal link
        let universalLinkReceivedIndicator = app.staticTexts["universal-link-received"]
        XCTAssertTrue(universalLinkReceivedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "04-universal-link-received")
        
        // Step 6: Verify URL parameter parsing
        let urlParametersParsedIndicator = app.staticTexts["url-parameters-parsed"]
        XCTAssertTrue(urlParametersParsedIndicator.waitForExistence(timeout: standardTimeout))
        
        // Step 7: Verify navigation to correct destination
        validateDeepLinkHandled(expectedDestination: "product-detail-view")
        
        // Step 8: Verify attribution tracking
        validateMetrics(eventType: "deepLinkClick", expectedCount: 1)
        
        screenshotCapture.captureScreenshot(named: "05-universal-link-complete")
    }
    
    func testDeepLinkFromPushNotification() {
        // Test deep link handling from push notification interactions
        
        validateSDKInitialization()
        
        // Configure push notifications
        let configurePushButton = app.buttons["configure-push-notifications"]
        XCTAssertTrue(configurePushButton.waitForExistence(timeout: standardTimeout))
        configurePushButton.tap()
        
        // Request notification permissions
        let requestPermissionsButton = app.buttons["request-notification-permission"]
        XCTAssertTrue(requestPermissionsButton.waitForExistence(timeout: standardTimeout))
        requestPermissionsButton.tap()
        
        waitForNotificationPermission()
        
        // Create push campaign with deep link
        let createPushDeepLinkButton = app.buttons["create-push-deeplink-campaign"]
        XCTAssertTrue(createPushDeepLinkButton.waitForExistence(timeout: standardTimeout))
        createPushDeepLinkButton.tap()
        
        // Wait for campaign creation
        let pushCampaignCreatedIndicator = app.staticTexts["push-deeplink-campaign-created"]
        XCTAssertTrue(pushCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "push-deeplink-campaign-created")
        
        // Send push notification with deep link
        let sendPushDeepLinkButton = app.buttons["send-push-with-deeplink"]
        XCTAssertTrue(sendPushDeepLinkButton.waitForExistence(timeout: standardTimeout))
        sendPushDeepLinkButton.tap()
        
        // Wait for push notification to arrive
        sleep(5)
        
        // Verify push notification received
        validatePushNotificationReceived()
        
        // Tap push notification to trigger deep link
        let notification = app.alerts.firstMatch
        if notification.exists {
            notification.tap()
        } else {
            let alert = app.alerts.firstMatch
            if alert.exists {
                alert.buttons["Open"].tap()
            }
        }
        
        screenshotCapture.captureScreenshot(named: "push-deeplink-tapped")
        
        // Verify deep link from push was handled
        let pushDeepLinkHandledIndicator = app.staticTexts["push-deeplink-handled"]
        XCTAssertTrue(pushDeepLinkHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        // Verify navigation to correct destination
        validateDeepLinkHandled(expectedDestination: "special-offer-view")
        
        // Verify both push open and deep link click metrics
        validateMetrics(eventType: "pushOpen", expectedCount: 1)
        validateMetrics(eventType: "deepLinkClick", expectedCount: 1)
    }
    
    func testDeepLinkFromInAppMessage() {
        // Test deep link handling from in-app message interactions
        
        validateSDKInitialization()
        
        // Enable in-app messaging
        let enableInAppButton = app.buttons["enable-inapp-messaging"]
        XCTAssertTrue(enableInAppButton.waitForExistence(timeout: standardTimeout))
        enableInAppButton.tap()
        
        // Create in-app message with deep link
        let createInAppDeepLinkButton = app.buttons["create-inapp-deeplink-campaign"]
        XCTAssertTrue(createInAppDeepLinkButton.waitForExistence(timeout: standardTimeout))
        createInAppDeepLinkButton.tap()
        
        // Wait for campaign creation
        let inAppCampaignCreatedIndicator = app.staticTexts["inapp-deeplink-campaign-created"]
        XCTAssertTrue(inAppCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "inapp-deeplink-campaign-created")
        
        // Trigger in-app message display
        let triggerInAppButton = app.buttons["trigger-inapp-with-deeplink"]
        XCTAssertTrue(triggerInAppButton.waitForExistence(timeout: standardTimeout))
        triggerInAppButton.tap()
        
        // Verify in-app message is displayed
        validateInAppMessageDisplayed()
        
        // Tap deep link button in in-app message
        let inAppDeepLinkButton = app.buttons["inapp-deeplink-action-button"]
        XCTAssertTrue(inAppDeepLinkButton.waitForExistence(timeout: standardTimeout))
        inAppDeepLinkButton.tap()
        
        screenshotCapture.captureScreenshot(named: "inapp-deeplink-tapped")
        
        // Verify deep link from in-app was handled
        let inAppDeepLinkHandledIndicator = app.staticTexts["inapp-deeplink-handled"]
        XCTAssertTrue(inAppDeepLinkHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        // Verify navigation to correct destination
        validateDeepLinkHandled(expectedDestination: "category-browse-view")
        
        // Verify both in-app click and deep link metrics
        validateMetrics(eventType: "inAppClick", expectedCount: 1)
        validateMetrics(eventType: "deepLinkClick", expectedCount: 1)
    }
    
    func testURLParameterParsingAndRouting() {
        // Test comprehensive URL parameter parsing and application routing
        
        validateSDKInitialization()
        
        // Configure deep link routing
        let configureRoutingButton = app.buttons["configure-deeplink-routing"]
        XCTAssertTrue(configureRoutingButton.waitForExistence(timeout: standardTimeout))
        configureRoutingButton.tap()
        
        screenshotCapture.captureScreenshot(named: "routing-configured")
        
        // Test product detail deep link with parameters
        let testProductDeepLinkButton = app.buttons["test-product-deeplink"]
        XCTAssertTrue(testProductDeepLinkButton.waitForExistence(timeout: standardTimeout))
        testProductDeepLinkButton.tap()
        
        // Verify product parameters parsed
        let productParamsParsedIndicator = app.staticTexts["product-params-parsed"]
        XCTAssertTrue(productParamsParsedIndicator.waitForExistence(timeout: standardTimeout))
        
        // Verify navigation to product detail with correct product ID
        let productDetailView = app.otherElements["product-detail-view"]
        XCTAssertTrue(productDetailView.waitForExistence(timeout: standardTimeout))
        
        let productIdLabel = app.staticTexts["product-id-12345"]
        XCTAssertTrue(productIdLabel.exists)
        
        screenshotCapture.captureScreenshot(named: "product-deeplink-handled")
        
        // Test category deep link with multiple parameters
        let testCategoryDeepLinkButton = app.buttons["test-category-deeplink"]
        XCTAssertTrue(testCategoryDeepLinkButton.waitForExistence(timeout: standardTimeout))
        testCategoryDeepLinkButton.tap()
        
        // Verify category parameters parsed
        let categoryParamsParsedIndicator = app.staticTexts["category-params-parsed"]
        XCTAssertTrue(categoryParamsParsedIndicator.waitForExistence(timeout: standardTimeout))
        
        // Verify navigation to category with filters applied
        let categoryView = app.otherElements["category-listing-view"]
        XCTAssertTrue(categoryView.waitForExistence(timeout: standardTimeout))
        
        let categoryLabel = app.staticTexts["category-electronics"]
        XCTAssertTrue(categoryLabel.exists)
        
        let filterLabel = app.staticTexts["filter-price-range"]
        XCTAssertTrue(filterLabel.exists)
        
        screenshotCapture.captureScreenshot(named: "category-deeplink-handled")
        
        // Test search deep link with query parameters
        let testSearchDeepLinkButton = app.buttons["test-search-deeplink"]
        XCTAssertTrue(testSearchDeepLinkButton.waitForExistence(timeout: standardTimeout))
        testSearchDeepLinkButton.tap()
        
        // Verify search parameters parsed
        let searchParamsParsedIndicator = app.staticTexts["search-params-parsed"]
        XCTAssertTrue(searchParamsParsedIndicator.waitForExistence(timeout: standardTimeout))
        
        // Verify navigation to search results
        let searchResultsView = app.otherElements["search-results-view"]
        XCTAssertTrue(searchResultsView.waitForExistence(timeout: standardTimeout))
        
        let searchQueryLabel = app.staticTexts["search-query-bluetooth-headphones"]
        XCTAssertTrue(searchQueryLabel.exists)
        
        screenshotCapture.captureScreenshot(named: "search-deeplink-handled")
        
        // Verify parameter parsing metrics
        validateMetrics(eventType: "deepLinkParametersParsed", expectedCount: 3)
    }
    
    func testCrossPlatformLinkCompatibility() {
        // Test deep links work across different platforms and scenarios
        
        validateSDKInitialization()
        
        // Test iOS universal link format
        let testIOSUniversalLinkButton = app.buttons["test-ios-universal-link"]
        XCTAssertTrue(testIOSUniversalLinkButton.waitForExistence(timeout: standardTimeout))
        testIOSUniversalLinkButton.tap()
        
        let iosLinkHandledIndicator = app.staticTexts["ios-universal-link-handled"]
        XCTAssertTrue(iosLinkHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "ios-universal-link-handled")
        
        // Test custom URL scheme fallback
        let testCustomSchemeButton = app.buttons["test-custom-url-scheme"]
        XCTAssertTrue(testCustomSchemeButton.waitForExistence(timeout: standardTimeout))
        testCustomSchemeButton.tap()
        
        let customSchemeHandledIndicator = app.staticTexts["custom-scheme-handled"]
        XCTAssertTrue(customSchemeHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "custom-scheme-handled")
        
        // Test link with encoded parameters
        let testEncodedLinkButton = app.buttons["test-encoded-parameters-link"]
        XCTAssertTrue(testEncodedLinkButton.waitForExistence(timeout: standardTimeout))
        testEncodedLinkButton.tap()
        
        let encodedParamsHandledIndicator = app.staticTexts["encoded-params-decoded"]
        XCTAssertTrue(encodedParamsHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "encoded-params-handled")
        
        // Test link with special characters
        let testSpecialCharsButton = app.buttons["test-special-characters-link"]
        XCTAssertTrue(testSpecialCharsButton.waitForExistence(timeout: standardTimeout))
        testSpecialCharsButton.tap()
        
        let specialCharsHandledIndicator = app.staticTexts["special-chars-handled"]
        XCTAssertTrue(specialCharsHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "special-chars-handled")
        
        // Verify cross-platform compatibility metrics
        validateMetrics(eventType: "crossPlatformLinkHandled", expectedCount: 4)
    }
    
    func testDeepLinkAttributionAndTracking() {
        // Test comprehensive attribution tracking for deep links
        
        validateSDKInitialization()
        
        // Create attributed campaign
        let createAttributedCampaignButton = app.buttons["create-attributed-deeplink-campaign"]
        XCTAssertTrue(createAttributedCampaignButton.waitForExistence(timeout: standardTimeout))
        createAttributedCampaignButton.tap()
        
        // Wait for campaign creation
        let attributedCampaignCreatedIndicator = app.staticTexts["attributed-campaign-created"]
        XCTAssertTrue(attributedCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "attributed-campaign-created")
        
        // Simulate deep link with attribution data
        let simulateAttributedLinkButton = app.buttons["simulate-attributed-deeplink"]
        XCTAssertTrue(simulateAttributedLinkButton.waitForExistence(timeout: standardTimeout))
        simulateAttributedLinkButton.tap()
        
        // Verify attribution data captured
        let attributionDataCapturedIndicator = app.staticTexts["attribution-data-captured"]
        XCTAssertTrue(attributionDataCapturedIndicator.waitForExistence(timeout: standardTimeout))
        
        // Verify campaign attribution
        let campaignAttributionIndicator = app.staticTexts["campaign-attribution-recorded"]
        XCTAssertTrue(campaignAttributionIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "attribution-captured")
        
        // Test conversion tracking after deep link
        let triggerConversionButton = app.buttons["trigger-conversion-event"]
        XCTAssertTrue(triggerConversionButton.waitForExistence(timeout: standardTimeout))
        triggerConversionButton.tap()
        
        // Verify conversion attributed to deep link
        let conversionAttributedIndicator = app.staticTexts["conversion-attributed-to-deeplink"]
        XCTAssertTrue(conversionAttributedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "conversion-attributed")
        
        // Test click-to-conversion attribution window
        let testAttributionWindowButton = app.buttons["test-attribution-window"]
        XCTAssertTrue(testAttributionWindowButton.waitForExistence(timeout: standardTimeout))
        testAttributionWindowButton.tap()
        
        let attributionWindowValidatedIndicator = app.staticTexts["attribution-window-validated"]
        XCTAssertTrue(attributionWindowValidatedIndicator.waitForExistence(timeout: standardTimeout))
        
        // Verify attribution tracking metrics
        validateMetrics(eventType: "deepLinkAttribution", expectedCount: 1)
        validateMetrics(eventType: "attributedConversion", expectedCount: 1)
    }
    
    func testAppNotInstalledFallbackBehavior() {
        // Test fallback behavior when app is not installed
        
        validateSDKInitialization()
        
        // Create campaign with fallback URL
        let createFallbackCampaignButton = app.buttons["create-fallback-deeplink-campaign"]
        XCTAssertTrue(createFallbackCampaignButton.waitForExistence(timeout: standardTimeout))
        createFallbackCampaignButton.tap()
        
        // Wait for campaign creation
        let fallbackCampaignCreatedIndicator = app.staticTexts["fallback-campaign-created"]
        XCTAssertTrue(fallbackCampaignCreatedIndicator.waitForExistence(timeout: networkTimeout))
        
        screenshotCapture.captureScreenshot(named: "fallback-campaign-created")
        
        // Simulate app-not-installed scenario
        let simulateAppNotInstalledButton = app.buttons["simulate-app-not-installed"]
        XCTAssertTrue(simulateAppNotInstalledButton.waitForExistence(timeout: standardTimeout))
        simulateAppNotInstalledButton.tap()
        
        // Verify fallback URL configuration
        let fallbackURLConfiguredIndicator = app.staticTexts["fallback-url-configured"]
        XCTAssertTrue(fallbackURLConfiguredIndicator.waitForExistence(timeout: standardTimeout))
        
        // Test fallback URL handling
        let testFallbackURLButton = app.buttons["test-fallback-url"]
        XCTAssertTrue(testFallbackURLButton.waitForExistence(timeout: standardTimeout))
        testFallbackURLButton.tap()
        
        // Verify fallback behavior triggered
        let fallbackTriggeredIndicator = app.staticTexts["fallback-behavior-triggered"]
        XCTAssertTrue(fallbackTriggeredIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "fallback-triggered")
        
        // Test App Store redirect
        let testAppStoreRedirectButton = app.buttons["test-appstore-redirect"]
        XCTAssertTrue(testAppStoreRedirectButton.waitForExistence(timeout: standardTimeout))
        testAppStoreRedirectButton.tap()
        
        let appStoreRedirectIndicator = app.staticTexts["appstore-redirect-configured"]
        XCTAssertTrue(appStoreRedirectIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "appstore-redirect-configured")
        
        // Test web fallback
        let testWebFallbackButton = app.buttons["test-web-fallback"]
        XCTAssertTrue(testWebFallbackButton.waitForExistence(timeout: standardTimeout))
        testWebFallbackButton.tap()
        
        let webFallbackIndicator = app.staticTexts["web-fallback-configured"]
        XCTAssertTrue(webFallbackIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "web-fallback-configured")
        
        // Verify fallback metrics
        validateMetrics(eventType: "deepLinkFallback", expectedCount: 3)
    }
    
    func testDeepLinkSecurityAndValidation() {
        // Test security measures and validation for deep links
        
        validateSDKInitialization()
        
        // Test malicious URL detection
        let testMaliciousURLButton = app.buttons["test-malicious-url-detection"]
        XCTAssertTrue(testMaliciousURLButton.waitForExistence(timeout: standardTimeout))
        testMaliciousURLButton.tap()
        
        // Verify malicious URL blocked
        let maliciousURLBlockedIndicator = app.staticTexts["malicious-url-blocked"]
        XCTAssertTrue(maliciousURLBlockedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "malicious-url-blocked")
        
        // Test domain whitelist validation
        let testDomainWhitelistButton = app.buttons["test-domain-whitelist"]
        XCTAssertTrue(testDomainWhitelistButton.waitForExistence(timeout: standardTimeout))
        testDomainWhitelistButton.tap()
        
        // Verify only whitelisted domains accepted
        let domainWhitelistValidatedIndicator = app.staticTexts["domain-whitelist-validated"]
        XCTAssertTrue(domainWhitelistValidatedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "domain-whitelist-validated")
        
        // Test parameter sanitization
        let testParameterSanitizationButton = app.buttons["test-parameter-sanitization"]
        XCTAssertTrue(testParameterSanitizationButton.waitForExistence(timeout: standardTimeout))
        testParameterSanitizationButton.tap()
        
        // Verify parameters sanitized
        let paramsSanitizedIndicator = app.staticTexts["parameters-sanitized"]
        XCTAssertTrue(paramsSanitizedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "parameters-sanitized")
        
        // Test rate limiting
        let testRateLimitingButton = app.buttons["test-deeplink-rate-limiting"]
        XCTAssertTrue(testRateLimitingButton.waitForExistence(timeout: standardTimeout))
        testRateLimitingButton.tap()
        
        // Verify rate limiting applied
        let rateLimitingAppliedIndicator = app.staticTexts["rate-limiting-applied"]
        XCTAssertTrue(rateLimitingAppliedIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "rate-limiting-applied")
        
        // Verify security validation metrics
        validateMetrics(eventType: "deepLinkSecurityValidation", expectedCount: 4)
    }
    
    func testDeepLinkErrorHandlingAndRecovery() {
        // Test error handling and recovery for deep link failures
        
        validateSDKInitialization()
        
        // Test invalid URL format
        let testInvalidURLButton = app.buttons["test-invalid-url-format"]
        XCTAssertTrue(testInvalidURLButton.waitForExistence(timeout: standardTimeout))
        testInvalidURLButton.tap()
        
        // Verify invalid URL handled gracefully
        let invalidURLHandledIndicator = app.staticTexts["invalid-url-handled"]
        XCTAssertTrue(invalidURLHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "invalid-url-handled")
        
        // Test missing required parameters
        let testMissingParamsButton = app.buttons["test-missing-parameters"]
        XCTAssertTrue(testMissingParamsButton.waitForExistence(timeout: standardTimeout))
        testMissingParamsButton.tap()
        
        // Verify missing parameters handled
        let missingParamsHandledIndicator = app.staticTexts["missing-params-handled"]
        XCTAssertTrue(missingParamsHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "missing-params-handled")
        
        // Test network failure during deep link processing
        let enableNetworkFailureButton = app.buttons["enable-network-failure-simulation"]
        XCTAssertTrue(enableNetworkFailureButton.waitForExistence(timeout: standardTimeout))
        enableNetworkFailureButton.tap()
        
        let testNetworkFailureDeepLinkButton = app.buttons["test-deeplink-network-failure"]
        XCTAssertTrue(testNetworkFailureDeepLinkButton.waitForExistence(timeout: standardTimeout))
        testNetworkFailureDeepLinkButton.tap()
        
        // Verify network failure handled
        let networkFailureHandledIndicator = app.staticTexts["deeplink-network-failure-handled"]
        XCTAssertTrue(networkFailureHandledIndicator.waitForExistence(timeout: standardTimeout))
        
        // Restore network and test recovery
        let restoreNetworkButton = app.buttons["restore-network"]
        XCTAssertTrue(restoreNetworkButton.waitForExistence(timeout: standardTimeout))
        restoreNetworkButton.tap()
        
        let retryDeepLinkButton = app.buttons["retry-deeplink-processing"]
        XCTAssertTrue(retryDeepLinkButton.waitForExistence(timeout: standardTimeout))
        retryDeepLinkButton.tap()
        
        // Verify successful recovery
        let deepLinkRecoveryIndicator = app.staticTexts["deeplink-processing-recovered"]
        XCTAssertTrue(deepLinkRecoveryIndicator.waitForExistence(timeout: standardTimeout))
        
        screenshotCapture.captureScreenshot(named: "deeplink-recovery-success")
        
        // Verify error handling metrics
        validateMetrics(eventType: "deepLinkError", expectedCount: 3)
        validateMetrics(eventType: "deepLinkRecovery", expectedCount: 1)
    }
}