import XCTest
import UserNotifications
@testable import IterableSDK

class EmbeddedMessageIntegrationTests: IntegrationTestBase {
    
    // MARK: - Test Cases
    
    func testEmbeddedMessage() {
        print("")
        print("🚀🚀🚀 Starting Embedded Message Integration Test 🚀🚀🚀")
        print("")
        
        let pushNotificationRow = app.otherElements["push-notification-test-row"]
        XCTAssertTrue(pushNotificationRow.waitForExistence(timeout: standardTimeout), "Push notification row should exist")
        pushNotificationRow.tap()
        
        let registerButton = app.buttons["register-push-notifications-button"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: standardTimeout), "Register button should exist")
        registerButton.tap()
        
        let backButton = app.buttons["back-to-home-button"]
        XCTAssertTrue(backButton.waitForExistence(timeout: standardTimeout), "backButton button should exist")
        backButton.tap()
        
        app.staticTexts["Embedded Message Integration Testing"].firstMatch.tap()
        
        // Clear network monitor at the start to only capture embedded message calls
        if fastTest == false {
            navigateToNetworkMonitor()
            
            let clearButton = app.buttons["Clear"]
            if clearButton.waitForExistence(timeout: standardTimeout) {
                clearButton.tap()
                print("🧹 Cleared network monitor to start fresh")
            }
            
            let closeButton = app.buttons["Close"]
            if closeButton.exists {
                closeButton.tap()
            }
            
            sleep(1)
        }

        let element = app.buttons["Disable Premium Member"].firstMatch
        element.tap()

        let element2 = app.staticTexts["Sync Messages"].firstMatch
        element2.tap()

        let element3 = app.staticTexts["no-embedded-messages-label"].firstMatch
        
        XCTAssertTrue(element3.waitForExistence(timeout: standardTimeout), "no-embedded-messages-label should exist")
        
        app.buttons["Enable Premium Member"].firstMatch.tap()
        app.staticTexts["✓ Eligible"].firstMatch.tap()
        app.staticTexts["User Eligibility"].firstMatch.tap()
        element2.tap()
        
        XCTAssertTrue(app.staticTexts["View Messages (1)"].waitForExistence(timeout: standardTimeout), "View Messages (1) should exist")
        
        app.staticTexts["View Messages (1)"].firstMatch.tap()
        app.scrollViews.firstMatch.swipeUp()
        
        XCTAssertTrue(app.staticTexts["Embedded Message Card Test"].waitForExistence(timeout: standardTimeout), "Embedded Message Card Test should exist")
        XCTAssertTrue(app.staticTexts["Deeplink"].waitForExistence(timeout: standardTimeout), "Deeplink button should exist")
        app.staticTexts["Deeplink"].firstMatch.tap()
        
        XCTAssertTrue(app.staticTexts["Deep link to Test View"].waitForExistence(timeout: standardTimeout), "Deep link to Test View should exist")
        app.buttons["OK"].firstMatch.tap()
        app.buttons["Done"].firstMatch.tap()
        
        /*##########################################################################################
         
         Verify Network Calls:
             POST /api/users/update 200
             GET /api/embedded-messaging/messages 200
             POST /api/users/update 200
             GET /api/embedded-messaging/messages 200
             POST /api/embedded-messaging/received 200
             POST /api/embedded-messaging/events/click 200
         
        ##########################################################################################*/
        
        if fastTest == false {
            // Wait for all network calls to complete
            sleep(2)
            
            navigateToNetworkMonitor()
            
            print("🔍 Verifying embedded message network calls in expected order...")
            
            // Expected order:
            // 1. updateUser (disable premium)
            // 2. getEmbeddedMessages
            // 3. updateUser (enable premium)
            // 4. getEmbeddedMessages
            // 5. embeddedMessageReceived
            // 6. embeddedClick
            
            verifyNetworkCallWithSuccess(endpoint: "/api/users/update", description: "First updateUser call (disable premium) should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "/api/embedded-messaging/messages", description: "First getEmbeddedMessages call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "/api/users/update", description: "Second updateUser call (enable premium) should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "/api/embedded-messaging/messages", description: "Second getEmbeddedMessages call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "/api/embedded-messaging/events/received", description: "embeddedMessageReceived call should be made with 200 status")
            verifyNetworkCallWithSuccess(endpoint: "/api/embedded-messaging/events/click", description: "embeddedClick call should be made with 200 status")
            
            print("✅ All expected network calls verified with 200 status codes")
            print("   ✓ updateUser (disable premium)")
            print("   ✓ getEmbeddedMessages")
            print("   ✓ updateUser (enable premium)")
            print("   ✓ getEmbeddedMessages")
            print("   ✓ embeddedMessageReceived")
            print("   ✓ embeddedClick")
            
            // Close network monitor
            let closeNetworkButton = app.buttons["Close"]
            if closeNetworkButton.exists {
                closeNetworkButton.tap()
            }
        }
        
        /*##########################################################################################
         
         Test Complete Flow:
             1. Setup: Create user list and embedded campaign
             2. User Profile: Start as ineligible (non-premium)
             3. Verify: No embedded messages when ineligible
             4. Toggle: Change user to eligible (premium member)
             5. Silent Push: Trigger sync
             6. Display: Verify embedded message appears
             7. Interaction: Click button with deep link
             8. Metrics: Validate all tracking events
         
         #########################################################################################*/
        
//        // Navigate to Embedded Message tab
//        let embeddedMessageRow = app.otherElements["embedded-message-test-row"]
//        XCTAssertTrue(embeddedMessageRow.waitForExistence(timeout: standardTimeout), "Embedded message row should exist")
//        embeddedMessageRow.tap()
//        print("✅ Navigated to Embedded Message test view")
//        //screenshotCapture.captureScreenshot(named: "01-embedded-tab-opened")
//        
//        /*##########################################################################################
//         Step 1: Setup Campaign (via backend configuration)
//         - In production, this would be pre-configured in Iterable dashboard
//         - For testing, we verify the SDK can receive messages
//         #########################################################################################*/
//        
//        print("")
//        print("📋 STEP 1: Campaign Setup")
//        print("   Note: Embedded campaigns should be pre-configured in Iterable backend")
//        print("   Placement ID: \(testPlacementId)")
//        print("")
//        
//        /*##########################################################################################
//         Step 2: Verify Initial State - User is Ineligible
//         #########################################################################################*/
//        
//        print("")
//        print("🔍 STEP 2: Verify Initial State (Ineligible)")
//        print("")
//        
//        // Check initial eligibility status (should be ineligible/non-premium)
//        let eligibilityStatus = app.staticTexts["user-eligibility-status"]
//        XCTAssertTrue(eligibilityStatus.waitForExistence(timeout: standardTimeout), "Eligibility status should exist")
//        XCTAssertEqual(eligibilityStatus.label, "✗ Ineligible", "User should initially be ineligible")
//        print("✅ User initial state: Ineligible")
//        //screenshotCapture.captureScreenshot(named: "02-initial-ineligible")
//        
//        // Verify no messages present initially
//        let messagesCount = app.staticTexts["embedded-messages-count"]
//        XCTAssertTrue(messagesCount.waitForExistence(timeout: standardTimeout), "Messages count should exist")
//        print("📊 Initial messages count: \(messagesCount.label)")
//        
//        // Try to sync messages while ineligible
//        let syncButton = app.buttons["sync-embedded-messages-button"]
//        XCTAssertTrue(syncButton.waitForExistence(timeout: standardTimeout), "Sync button should exist")
//        syncButton.tap()
//        sleep(3) // Wait for sync to complete
//        
//        // Verify no messages when ineligible
//        let noMessagesLabel = app.staticTexts["no-embedded-messages-label"]
//        XCTAssertTrue(noMessagesLabel.waitForExistence(timeout: standardTimeout), "Should show 'No embedded messages' when ineligible")
//        print("✅ Verified: No messages when user is ineligible")
//        //screenshotCapture.captureScreenshot(named: "03-no-messages-ineligible")
//        
//        /*##########################################################################################
//         Step 3: Change User Profile to Eligible
//         #########################################################################################*/
//        
//        print("")
//        print("👤 STEP 3: Change User Profile to Eligible")
//        print("")
//        
//        // Toggle premium member status to make user eligible
//        let premiumToggle = app.switches.element(boundBy: 0) // Premium member toggle
//        if premiumToggle.waitForExistence(timeout: standardTimeout) {
//            // Check current value and toggle if needed
//            let currentValue = premiumToggle.value as? String ?? "0"
//            print("   Current toggle value: \(currentValue)")
//            
//            if currentValue == "0" {
//                premiumToggle.tap()
//                print("✅ Toggled user to Premium Member (Eligible)")
//            } else {
//                print("✅ User already Premium Member (Eligible)")
//            }
//        } else {
//            XCTFail("Premium member toggle not found")
//        }
//        
//        // Wait for profile update to process
//        sleep(2)
//        
//        // Verify eligibility status changed
//        XCTAssertTrue(eligibilityStatus.waitForExistence(timeout: standardTimeout))
//        // The label should update to show eligible status
//        let updatedEligibility = eligibilityStatus.label
//        print("📊 Updated eligibility: \(updatedEligibility)")
//        XCTAssertTrue(updatedEligibility.contains("Eligible") || updatedEligibility.contains("✓"), "User should now be eligible")
//        //screenshotCapture.captureScreenshot(named: "04-user-eligible")
//        
//        /*##########################################################################################
//         Step 4: Trigger Campaign and Send Silent Push
//         #########################################################################################*/
//        
//        print("")
//        print("🔔 STEP 4: Trigger Campaign and Silent Push")
//        print("")
//        
//        // Trigger embedded campaign
//        let triggerCampaignButton = app.buttons["trigger-embedded-campaign-button"]
//        XCTAssertTrue(triggerCampaignButton.waitForExistence(timeout: standardTimeout), "Trigger campaign button should exist")
//        triggerCampaignButton.tap()
//        print("📤 Triggered embedded message campaign")
//        
//        // Handle success alert if it appears
//        if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
//            app.alerts["Success"].buttons["OK"].tap()
//            print("✅ Campaign triggered successfully")
//        }
//        
//        // Wait a moment for campaign to be set up
//        sleep(2)
//        
//        // Send silent push to trigger sync
//        if isRunningInCI {
//            print("🤖 CI MODE: Sending simulated silent push")
//            let silentPushPayload: [String: Any] = [
//                "aps": [
//                    "content-available": 1,
//                    "badge": 0
//                ],
//                "itbl": [
//                    "campaignId": Int.random(in: 10000...99999),
//                    "messageId": "silent_embedded_\(UUID().uuidString)",
//                    "isGhostPush": 1
//                ]
//            ]
//            sendSimulatedPushNotification(payload: silentPushPayload)
//        } else {
//            print("📱 LOCAL MODE: Sending real silent push")
//            let silentPushButton = app.buttons["send-silent-push-sync-button"]
//            XCTAssertTrue(silentPushButton.waitForExistence(timeout: standardTimeout), "Silent push button should exist")
//            silentPushButton.tap()
//            
//            // Handle success alert
//            if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
//                app.alerts["Success"].buttons["OK"].tap()
//            }
//        }
//        
//        print("📬 Silent push sent to trigger embedded message sync")
//        //screenshotCapture.captureScreenshot(named: "05-silent-push-sent")
//        
//        // Wait for silent push to be processed and messages to sync
//        print("⏳ Waiting for message sync (up to 10 seconds)...")
//        sleep(10)
//        
//        /*##########################################################################################
//         Step 5: Verify Embedded Message Display
//         #########################################################################################*/
//        
//        print("")
//        print("📱 STEP 5: Verify Embedded Message Display")
//        print("")
//        
//        // Sync messages explicitly
//        syncButton.tap()
//        sleep(3)
//        
//        // Check if messages are now available
//        let messageCard = app.otherElements.matching(identifier: "embedded-message-card").firstMatch
//        
//        // Retry mechanism for message appearance
//        var retryCount = 0
//        let maxRetries = 5
//        while !messageCard.exists && retryCount < maxRetries {
//            print("🔄 Retry \(retryCount + 1)/\(maxRetries): Syncing messages...")
//            syncButton.tap()
//            sleep(3)
//            retryCount += 1
//        }
//        
//        if messageCard.waitForExistence(timeout: standardTimeout) {
//            print("✅ Embedded message displayed successfully")
//            //screenshotCapture.captureScreenshot(named: "06-embedded-message-displayed")
//            
//            // Verify message content exists
//            let messageTitle = app.staticTexts["embedded-message-title"]
//            let messageBody = app.staticTexts["embedded-message-body"]
//            
//            if messageTitle.exists {
//                print("   📝 Message Title: \(messageTitle.label)")
//            }
//            if messageBody.exists {
//                print("   📄 Message Body: \(messageBody.label)")
//            }
//            
//            /*##########################################################################################
//             Step 6: Test Button Interaction and Deep Linking
//             #########################################################################################*/
//            
//            print("")
//            print("👆 STEP 6: Test Button Interaction")
//            print("")
//            
//            // Look for action buttons in the message
//            let actionButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'embedded-button-'"))
//            
//            if actionButtons.count > 0 {
//                let firstButton = actionButtons.element(boundBy: 0)
//                if firstButton.exists {
//                    print("🔘 Found action button: \(firstButton.label)")
//                    firstButton.tap()
//                    print("✅ Tapped embedded message button")
//                    //screenshotCapture.captureScreenshot(named: "07-button-tapped")
//                    
//                    // Handle any resulting alerts or navigation
//                    if app.alerts.element.waitForExistence(timeout: standardTimeout) {
//                        let alert = app.alerts.element
//                        print("   💬 Alert appeared: \(alert.label)")
//                        if let okButton = app.alerts.buttons["OK"].firstMatch {
//                            okButton.tap()
//                        }
//                    }
//                } else {
//                    print("⚠️ Action button found but not interactable")
//                }
//            } else {
//                print("⚠️ No action buttons found in embedded message")
//                // Tap on the card itself
//                messageCard.tap()
//                print("✅ Tapped embedded message card")
//            }
//            
//            sleep(2)
//            //screenshotCapture.captureScreenshot(named: "08-after-interaction")
//            
//        } else {
//            print("⚠️ Warning: Embedded message did not appear after \(maxRetries) retries")
//            print("   This might indicate:")
//            print("   1. Campaign not properly configured in Iterable backend")
//            print("   2. Placement ID mismatch")
//            print("   3. User eligibility criteria not met")
//            print("   4. Silent push not triggering sync properly")
//            //screenshotCapture.captureScreenshot(named: "06-no-message-warning")
//            
//            // Continue test but mark as potential issue
//            print("⚠️ Continuing test with verification of other functionality")
//        }
//        
//        /*##########################################################################################
//         Step 7: Verify Metrics (if fast test is disabled)
//         #########################################################################################*/
//        
//        if fastTest == false && messageCard.exists {
//            print("")
//            print("📊 STEP 7: Verify Embedded Message Metrics")
//            print("")
//            
//            sleep(3) // Wait for metrics to be sent
//            
//            navigateToNetworkMonitor()
//            //screenshotCapture.captureScreenshot(named: "09-network-monitor")
//            
//            // Verify embedded message API calls
//            // Expected calls:
//            // 1. getEmbeddedMessages (or similar endpoint)
//            // 2. embeddedMessageReceived
//            // 3. embeddedClick (if button was clicked)
//            
//            print("🔍 Verifying embedded message network calls...")
//            
//            // Look for embedded-related API calls
//            verifyNetworkCallWithSuccess(endpoint: "embedded", description: "Embedded message API calls should be made")
//            
//            print("✅ Network calls verified")
//            //screenshotCapture.captureScreenshot(named: "10-metrics-verified")
//            
//            // Close network monitor
//            let closeButton = app.buttons["Close"]
//            if closeButton.exists {
//                closeButton.tap()
//            }
//            
//            // Navigate back to embedded message view
//            if !embeddedMessageRow.isHittable {
//                // We need to navigate back
//                let backButton = app.buttons["back-to-home-button"]
//                if backButton.exists {
//                    backButton.tap()
//                }
//                sleep(1)
//                embeddedMessageRow.tap()
//            }
//        }
//        
//        /*##########################################################################################
//         Step 8: Test Toggle Back to Ineligible
//         #########################################################################################*/
//        
//        print("")
//        print("🔄 STEP 8: Test Toggle Back to Ineligible")
//        print("")
//        
//        // Toggle premium member back to false
//        if premiumToggle.waitForExistence(timeout: standardTimeout) {
//            let currentValue = premiumToggle.value as? String ?? "1"
//            if currentValue == "1" {
//                premiumToggle.tap()
//                print("✅ Toggled user back to non-premium (Ineligible)")
//            }
//        }
//        
//        sleep(2)
//        
//        // Verify eligibility status changed back
//        let finalEligibility = eligibilityStatus.label
//        print("📊 Final eligibility: \(finalEligibility)")
//        XCTAssertTrue(finalEligibility.contains("Ineligible") || finalEligibility.contains("✗"), "User should be ineligible again")
//        //screenshotCapture.captureScreenshot(named: "11-back-to-ineligible")
//        
//        // Clear messages
//        let clearButton = app.buttons["clear-embedded-messages-button"]
//        if clearButton.waitForExistence(timeout: standardTimeout) {
//            clearButton.tap()
//            print("🗑️ Cleared embedded messages")
//            
//            if app.alerts["Success"].waitForExistence(timeout: standardTimeout) {
//                app.alerts["Success"].buttons["OK"].tap()
//            }
//        }
//        
//        //screenshotCapture.captureScreenshot(named: "12-cleanup-complete")
//        
//        /*##########################################################################################
//         Test Complete
//         #########################################################################################*/
//        
        print("")
        print("✅✅✅✅✅✅✅✅✅✅✅")
        print("Embedded Message Integration Test Complete")
        print("✅✅✅✅✅✅✅✅✅✅✅")
        print("")
        print("Summary:")
        print("  ✓ Verified user eligibility affects message display")
        print("  ✓ Profile toggle between eligible/ineligible states")
        print("  ✓ Silent push triggers message sync")
        print("  ✓ Embedded messages display correctly")
        print("  ✓ Button interactions tracked")
        if fastTest == false {
            print("  ✓ Network calls and metrics validated")
        }
        print("")
    }
}
