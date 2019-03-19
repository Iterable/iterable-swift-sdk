//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAutoShowInAppSingle() {
        let expectation1 = expectation(description: "testAutoShowInAppSingle")
        let expectation2 = expectation(description: "Count decrements after showing")

        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            // 1 message is present when showing
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            expectation1.fulfill()
            // now click the inApp
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = {(_, _) in
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
            expectation2.fulfill()
        }
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }

    // skip the inApp in inAppDelegate
    func testAutoShowInAppSingleOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppSingleOverride")
        expectation1.isInverted = true
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            XCTAssertEqual(IterableAPI.inAppManager.getMessages()[0].didProcessTrigger, true)
        }

        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }

    func testAutoShowInAppMultipleWithOrdering() {
        let expectation0 = expectation(description: "testAutoShowInAppMultiple")
        expectation0.expectedFulfillmentCount = 3 // three times
        let expectation1 = expectation(description: "testAutoShowInAppMultiple, first")
        let expectation2 = expectation(description: "testAutoShowInAppMultiple, second")
        let expectation3 = expectation(description: "testAutoShowInAppMultiple, third")

        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(message, _) in
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: TestInAppPayloadGenerator.index(fromCampaignId: message.campaignId)))
            expectation0.fulfill()
        }
        
        var callOrder = [Int]()
        let urlDelegate = MockUrlDelegate(returnValue: true)
        urlDelegate.callback = {(url, _) in
            if url.absoluteString == TestInAppPayloadGenerator.getClickUrl(index: 1) {
                callOrder.append(1)
                expectation1.fulfill()
            }
            if url.absoluteString == TestInAppPayloadGenerator.getClickUrl(index: 2) {
                callOrder.append(2)
                expectation2.fulfill()
            }
            if url.absoluteString == TestInAppPayloadGenerator.getClickUrl(index: 3) {
                callOrder.append(3)
                expectation3.fulfill()
            }
        }
        
        let config = IterableConfig()
        config.urlDelegate = urlDelegate
        config.inAppDisplayInterval = 1.0

        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer
        )
        
        let indices = [1, 3, 2]
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(indices: indices)
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)

        wait(for: [expectation0, expectation1, expectation2, expectation3], timeout: testExpectationTimeout)

        XCTAssertEqual(callOrder, indices)
    }

    func testAutoShowInAppMultipleOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppMultipleOverride")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "all messages processed")
        
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        config.inAppDisplayInterval = 0.5
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer
        )

        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let messages = IterableAPI.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 3)
            XCTAssertEqual(Set(messages.map { $0.didProcessTrigger }), Set([true, true, true]))
            expectation2.fulfill()
        }

        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)

        wait(for: [expectation2], timeout: testExpectationTimeout)
    }

    // inApp is shown and url is opened when link is clicked
    func testAutoShowInAppOpenUrlByDefault() {
        let expectation1 = expectation(description: "testAutoShowInAppOpenUrlByDefault")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, TestInAppPayloadGenerator.getClickUrl(index: 1))
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
            expectation1.fulfill()
        }
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        IterableAPI.initializeForTesting(
                                 inAppSynchronizer: mockInAppSynchronizer,
                                 iterableMessageDisplayer: mockIterableMessageDisplayer,
                                 urlOpener: mockUrlOpener
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    // override in url delegate
    // inApp is shown but does not open external url
    func testAutoShowInAppUrlDelegateOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppUrlDelegateOverride")
        expectation1.isInverted = true
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, TestInAppPayloadGenerator.getClickUrl(index: 1))
            let messages = IterableAPI.inAppManager.getMessages()
            // Message count is 0 because inApp is still being shown. It is just not opening external url on click.
            XCTAssertEqual(messages.count, 0)
            expectation1.fulfill()
        }
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))

        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }
    
    func testShowInAppWithConsume() {
        let expectation1 = expectation(description: "testShowInAppWithConsume")
        let expectation2 = expectation(description: "url opened")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, TestInAppPayloadGenerator.getClickUrl(index: 1))
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
            
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer,
            urlOpener: mockUrlOpener
        )

        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        let messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 1)
        
        IterableAPI.inAppManager.show(message: messages[0], consume: true) { (clickedUrl) in
            XCTAssertEqual(clickedUrl, TestInAppPayloadGenerator.getClickUrl(index: 1))
            expectation1.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }

    func testShowInAppWithNoConsume() {
        let expectation1 = expectation(description: "testShowInAppWithNoConsume")
        let expectation2 = expectation(description: "url opened")

        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, TestInAppPayloadGenerator.getClickUrl(index: 1))
            let messages = IterableAPI.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0].didProcessTrigger, true)
            
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        var messages = IterableAPI.inAppManager.getMessages()
        // Now show the first message, but don't consume
        IterableAPI.inAppManager.show(message: messages[0], consume: false) { (clickedUrl) in
            XCTAssertEqual(clickedUrl, TestInAppPayloadGenerator.getClickUrl(index: 1))
            expectation1.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }
    
    func testShowInAppWithCustomAction() {
        let expectation1 = expectation(description: "testShowInAppWithCustomAction")
        let expectation2 = expectation(description: "custom action called")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getCustomActionUrl(index: 1))
        }
        
        let mockCustomActionDelegate = MockCustomActionDelegate(returnValue: true) // returnValue is reserved, no effect
        mockCustomActionDelegate.callback = { customActionName, context in
            XCTAssertEqual(customActionName, TestInAppPayloadGenerator.getCustomActionName(index: 1))
            XCTAssertEqual(context.source, .inApp)
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        config.customActionDelegate = mockCustomActionDelegate
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        let messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 1)
        
        IterableAPI.inAppManager.show(message: messages[0], consume: true) { (customActionName) in
            XCTAssertEqual(customActionName, TestInAppPayloadGenerator.getCustomActionName(index: 1))
            expectation1.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }

    // Check that onNew is called just once if the messageId is same.
    func testOnNewNotCalledMultipleTimes() {
        let expectation1 = expectation(description: "testOnNewNotCalledMultipleTimes")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        mockInAppDelegate.onNewMessageCallback = {_ in
            // should only be called once
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        // Send second message with same id.
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDeleteInServerDeletesInClient() {
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate

        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3))
        
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 3)

        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 2))

        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 2)
    }
    
    func testInAppDoNotShowInBackground() {
        let expectation1 = expectation(description: "testInAppDoNotShowInBackground")
        expectation1.isInverted = true
        
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 1.0
        
        let mockApplicationStateProvider = MockApplicationStateProvider(applicationState: .background)
        let mockNotificationCenter = MockNotificationCenter()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)

    }

    func testInAppShowWhenMovesToForeground() {
        let expectation1 = expectation(description: "do not show when in background")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "show when moves to foreground")

        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockDateProvider = MockDateProvider()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill() // expectation1 should not be fulfilled within timeout (inverted)
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 1.0
        
        let mockApplicationStateProvider = MockApplicationStateProvider(applicationState: .background)
        let mockNotificationCenter = MockNotificationCenter()
        
        IterableAPI.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(1000.0)
        mockApplicationStateProvider.applicationState = .active
        mockNotificationCenter.fire(notification: UIApplication.didBecomeActiveNotification)
        
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }

    func testMoveToForegroundSyncInterval() {
        let expectation1 = expectation(description: "do not sync because app is not in foreground")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "sync first time when moving to foreground")
        let expectation3 = expectation(description: "do not sync second time")
        expectation3.isInverted = true
        let expectation4 = expectation(description: "sync third time after time has passed")
        
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockDateProvider = MockDateProvider()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill() // expectation1 should not be fulfilled within timeout (inverted)
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 1.0
        
        let mockApplicationStateProvider = MockApplicationStateProvider(applicationState: .background)
        let mockNotificationCenter = MockNotificationCenter()
        
        IterableAPI.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(1000.0)
        mockApplicationStateProvider.applicationState = .active
        mockNotificationCenter.fire(notification: UIApplication.didBecomeActiveNotification)
        
        wait(for: [expectation2], timeout: testExpectationTimeout)

        // now move to foreground within interval
        mockInAppSynchronizer.syncCallback = {
            expectation3.fulfill()
        }
        mockNotificationCenter.fire(notification: UIApplication.didBecomeActiveNotification)
        wait(for: [expectation3], timeout: testExpectationTimeoutForInverted)
        
        // now move to foreground outside of interval
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(1000.0)
        mockInAppSynchronizer.syncCallback = {
            expectation4.fulfill()
        }
        mockNotificationCenter.fire(notification: UIApplication.didBecomeActiveNotification)
        wait(for: [expectation4], timeout: testExpectationTimeout)
    }

    
    func testDontShowMessageWithinRetryInterval() {
        let expectation1 = expectation(description: "show first message")
        let expectation2 = expectation(description: "don't show second message within interval")
        expectation2.isInverted = true
        let expectation3 = expectation(description: "show second message after retry interval")

        let retryInterval = 2.0

        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        var messageNumber = -1
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            if messageNumber == 1 {
                expectation1.fulfill()
                mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: messageNumber))
            } else if messageNumber == 2 {
                expectation2.fulfill()
                mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: messageNumber))
            } else if messageNumber == 3 {
                expectation3.fulfill()
                mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: messageNumber))
            } else {
                // unexpected message number
                XCTFail()
            }
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = retryInterval
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer
        )
        
        // send first message payload
        messageNumber = 1
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(indices: messageNumber...messageNumber))
        wait(for: [expectation1], timeout: testExpectationTimeout)

        // second message payload, should not be shown
        messageNumber = 2
        let margin = 0.1 // give some time for execution
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(indices: messageNumber...messageNumber))
        wait(for: [expectation2], timeout: retryInterval - margin)

        // After retryInternval, the third should show
        messageNumber = 3
        wait(for: [expectation3], timeout: testExpectationTimeout)
    }
    
    func testRemoveMessages() {
        let expectation1 = expectation(description: "testRemoveMessages")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }

        IterableAPI.initializeForTesting(
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3))
        
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 3)

        // First one will be shown automatically, so we have two left now
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 2)

        // now remove 1, there should be 1 left
        IterableAPI.inAppManager.remove(message: IterableAPI.inAppManager.getMessages()[0])
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
        
        // now remove 1, there should be 0 left
        IterableAPI.inAppManager.remove(message: IterableAPI.inAppManager.getMessages()[0])
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
    }
    
    func testMultipleMesssagesInShortTime() {
        let expectation0 = expectation(description: "testMultipleMesssagesInShortTime")
        expectation0.expectedFulfillmentCount = 3 // three times
        let expectation1 = expectation(description: "testAutoShowInAppMultiple, first")
        let expectation2 = expectation(description: "testAutoShowInAppMultiple, second")
        let expectation3 = expectation(description: "testAutoShowInAppMultiple, third")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockIterableMessageDisplayer = MockIterableMessageDisplayer()
        mockIterableMessageDisplayer.onShowCallback = {(message, _) in
            mockIterableMessageDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: TestInAppPayloadGenerator.index(fromCampaignId: message.campaignId)))
            expectation0.fulfill()
        }
        
        var callOrder = [Int]()
        var callTimes = [Date]()
        let urlDelegate = MockUrlDelegate(returnValue: true)
        urlDelegate.callback = {(url, _) in
            if url.absoluteString == TestInAppPayloadGenerator.getClickUrl(index: 1) {
                callTimes.append(Date())
                callOrder.append(1)
                expectation1.fulfill()
            }
            if url.absoluteString == TestInAppPayloadGenerator.getClickUrl(index: 2) {
                callTimes.append(Date())
                callOrder.append(2)
                expectation2.fulfill()
            }
            if url.absoluteString == TestInAppPayloadGenerator.getClickUrl(index: 3) {
                callTimes.append(Date())
                callOrder.append(3)
                expectation3.fulfill()
            }
        }
        
        let config = IterableConfig()
        let interval = 0.5
        config.urlDelegate = urlDelegate
        config.inAppDisplayInterval = interval
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockIterableMessageDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1]))
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1, 3]))
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1, 3, 2]))

        wait(for: [expectation0, expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
        
        XCTAssertEqual(callOrder, [1, 3, 2])
        let t1 = callTimes[0].timeIntervalSince1970
        let t2 = callTimes[1].timeIntervalSince1970
        let t3 = callTimes[2].timeIntervalSince1970
        
        let g1 = abs(t1 - t2)
        let g2 = abs(t2 - t3)
        let g3 = abs(t1 - t3)
        
        XCTAssertGreaterThan(g1, interval)
        XCTAssertGreaterThan(g2, interval)
        XCTAssertGreaterThan(g3, interval)
    }

    
    func testFilePersistence() {
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": false,
                "content": {"type": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site1.com\'>Click Here</a>", "payload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}},
                "trigger": {"type": "event", "details": "some event details"},
                "messageId": "message1",
                "expiresAt": 1550605745142,
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"type": "inboxHtml", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message2",
                "expiresAt": 1550605745145,
                "campaignId": "campaign2",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "content": {"inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site3.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message3",
                "campaignId": "campaign3",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "content": {"inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site4.com\'>Click Here</a>"},
                "trigger": {"type": "newEventType", "nested": {"var1": "val1"}},
                "messageId": "message4",
                "expiresAt": 1550605745145,
                "campaignId": "campaign4",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            }
        ]
        }
        """.toJsonDict()
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        let persister = InAppFilePersister()
        persister.persist(messages)
        let obtained = persister.getMessages()
        XCTAssertEqual(messages.description, obtained.description)
        
        XCTAssertEqual((obtained[3]).trigger.type, IterableInAppTriggerType.never)
        let dict = (obtained[3]).trigger.dict as! [String : Any]
        TestUtils.validateMatch(keyPath: KeyPath("nested.var1"), value: "val1", inDictionary: dict, message: "Expected to find val1 in persisted dictionary")

        persister.clear()
    }
    
    func testFilePersisterInitial() {
        let persister = InAppFilePersister()
        persister.clear()

        let read = persister.getMessages()
        XCTAssertEqual(read.count, 0)
    }
    
    func testCorruptedData() {
        let persister = InAppFilePersister(filename: "test", ext: "json")
        
        let badData = "some junk data".data(using: .utf8)!
        
        FileHelper.write(filename: "test", ext: "json", data: badData)
        
        let badMessages = persister.getMessages()
        XCTAssertEqual(badMessages.count, 0)
        
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1, 3, 2])
        let goodMessages = InAppTestHelper.inAppMessages(fromPayload: payload)
        let goodData = try! JSONEncoder().encode(goodMessages)
        FileHelper.write(filename: "test", ext: "json", data: goodData)
        
        let obtainedMessages = persister.getMessages()
        XCTAssertEqual(obtainedMessages.count, 3)
        
        persister.clear()
    }
    
    func testPersistBetweenSessions() {
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppPersister: InAppFilePersister()
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1, 3, 2]))

        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 3)
        

        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppPersister: InAppFilePersister()
        )

        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 3)
    }
    
    func testParseSilentPushNotificationParsing() {
        let json = """
        {
            "itbl" : {
                "messageId" : "background_notification",
                "isGhostPush" : true
            },
            "notificationType" : "InAppUpdate",
            "messageId" : "messageId"
        }
        """

        let notification = try! JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: []) as! [AnyHashable : Any]
        
        if case let NotificationInfo.silentPush(silentPush) = NotificationHelper.inspect(notification: notification) {
            XCTAssertEqual(silentPush.notificationType, .update)
            XCTAssertEqual(silentPush.messageId, "messageId")
        } else {
            XCTFail()
        }
    }

    func testParseSilentPushNotificationParsing2() {
        let notification = """
        {
            "itbl" : {
                "messageId" : "background_notification",
                "isGhostPush" : true
            },
            "notificationType" : "InAppRemove",
            "messageId" : "messageId"
        }
        """.toJsonDict()
        
        if case let NotificationInfo.silentPush(silentPush) = NotificationHelper.inspect(notification: notification) {
            XCTAssertEqual(silentPush.notificationType, .remove)
            XCTAssertEqual(silentPush.messageId, "messageId")
        } else {
            XCTFail()
        }
    }
    
    func testSyncIsCalled() {
        let expectation1 = expectation(description: "testSyncIsCalled")
        expectation1.expectedFulfillmentCount = 2 // once on initialization
        
        let notification = """
        {
            "itbl" : {
                "messageId" : "background_notification",
                "isGhostPush" : true
            },
            "notificationType" : "InAppUpdate",
            "messageId" : "messageId"
        }
        """.toJsonDict()

        let mockInAppSynchronizer = MockInAppSynchronizer()
        mockInAppSynchronizer.syncCallback = {
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer
        )
        
        IterableAppIntegration.application(UIApplication.shared, didReceiveRemoteNotification: notification, fetchCompletionHandler: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testRemoveIsCalled() {
        let expectation1 = expectation(description: "testRemoveIsCalled")
        
        let notification = """
        {
            "itbl" : {
                "messageId" : "background_notification",
                "isGhostPush" : true
            },
            "notificationType" : "InAppRemove",
            "messageId" : "messageId"
        }
        """.toJsonDict()
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        mockInAppSynchronizer.removeCallback = {(messageId) in
            XCTAssertEqual(messageId, "messageId")
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer
        )
        
        IterableAppIntegration.application(UIApplication.shared, didReceiveRemoteNotification: notification, fetchCompletionHandler: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testSyncIsCalledOnLogin() {
        let expectation1 = expectation(description: "testSyncIsCalledOnLogin")
        expectation1.expectedFulfillmentCount = 2 // once on initialization
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        mockInAppSynchronizer.syncCallback = {
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        TestUtils.clearTestUserDefaults()
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer
        )
        
        IterableAPI.userId = "newUserId"
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDoNoProcessNonImmediateTriggerTypes() {
        let expectation1 = expectation(description: "do not call event trigger")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "call immediate trigger 1")
        let expectation3 = expectation(description: "do not call never trigger")
        expectation3.isInverted = true
        let expectation4 = expectation(description: "call immediate trigger 2")
        
        let payload = ["inAppMessages" : [
            TestInAppPayloadGenerator.createOneInAppDictWithUrl(index: 1, triggerType: .event),
            TestInAppPayloadGenerator.createOneInAppDictWithUrl(index: 2, triggerType: .immediate),
            TestInAppPayloadGenerator.createOneInAppDictWithUrl(index: 3, triggerType: .never),
            TestInAppPayloadGenerator.createOneInAppDictWithUrl(index: 4, triggerType: .immediate),
        ]]
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        mockInAppDelegate.onNewMessageCallback = {(message) in
            if message.messageId == TestInAppPayloadGenerator.getMessageId(index: 1) {
                expectation1.fulfill()
            } else if message.messageId == TestInAppPayloadGenerator.getMessageId(index: 2) {
                expectation2.fulfill()
            } else if message.messageId == TestInAppPayloadGenerator.getMessageId(index: 3) {
                expectation3.fulfill()
            } else if message.messageId == TestInAppPayloadGenerator.getMessageId(index: 4) {
                expectation4.fulfill()
            }
        }
        
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(config: config,
                                         inAppSynchronizer: mockInAppSynchronizer)
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        wait(for: [expectation1, expectation3], timeout: testExpectationTimeoutForInverted)
        wait(for: [expectation2, expectation4], timeout: testExpectationTimeout)
    }
    
    func testExpiration() {
        let mockDateProvider = MockDateProvider()
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let config = IterableConfig()
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(config: config,
                                         dateProvider: mockDateProvider,
                                         inAppSynchronizer: mockInAppSynchronizer)

        let message = IterableInAppMessage(messageId: "messageId",
                                           campaignId: "campaignId",
                                           expiresAt: mockDateProvider.currentDate.addingTimeInterval(1.0 * 60.0), // one minute from now
                                           content: IterableHtmlContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "<html></html>"))
        mockInAppSynchronizer.mockMessagesAvailableFromServer(messages: [message])

        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
        
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(2.0 * 60) // two minutes from now
        
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
    }
}

extension IterableInAppTrigger {
    public override var description: String {
        return "type: \(self.type)"
    }
}

extension IterableHtmlContent {
    public override var description: String {
        return IterableUtil.describe("type", type,
                        "edgeInsets", edgeInsets,
                        "backgroundAlpha", backgroundAlpha,
                        "html", html, pairSeparator: " = ", separator: ", ")
    }
}

extension IterableInboxMetadata {
    public override var description: String {
        return IterableUtil.describe("title", title ?? "nil",
                                     "subTitle", subTitle ?? "nil",
                                     "icon", icon ?? "nil",
                                     pairSeparator: " = ", separator: ", ")
    }
}

extension IterableInAppMessage {
    public override var description: String {
        return IterableUtil.describe("messageId", messageId,
                        "campaignId", campaignId,
                        "saveToInbox", saveToInbox,
                        "inboxMetadata", inboxMetadata ?? "nil",
                        "trigger", trigger,
                        "expiresAt", expiresAt ?? "nil",
                        "content", content,
                        "didProcessTrigger", didProcessTrigger,
                        "didProcessInbox", didProcessInbox,
                        "consumed", consumed, pairSeparator: " = ", separator: "\n")
    }
}
