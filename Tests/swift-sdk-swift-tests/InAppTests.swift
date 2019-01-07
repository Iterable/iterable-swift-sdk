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
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            // 1 message is present when showing
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            expectation1.fulfill()
            // now click the inApp
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
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
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }

    // skip the inApp in inAppDelegate
    func testAutoShowInAppSingleOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppSingleOverride")
        expectation1.isInverted = true
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            XCTAssertEqual(IterableAPI.inAppManager.getMessages()[0].processed, true)
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
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(message, _) in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: TestInAppPayloadGenerator.index(fromCampaignId: message.campaignId)))
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
            inAppDisplayer: mockInAppDisplayer
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
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        config.inAppDisplayInterval = 0.5
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )

        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let messages = IterableAPI.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 3)
            XCTAssertEqual(Set(messages.map { $0.processed }), Set([true, true, true]))
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
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        IterableAPI.initializeForTesting(
                                 inAppSynchronizer: mockInAppSynchronizer,
                                 inAppDisplayer: mockInAppDisplayer,
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
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))

        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }
    
    func testShowInAppWithConsume() {
        let expectation1 = expectation(description: "testShowInAppWithConsume")
        let expectation2 = expectation(description: "url opened")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
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
            inAppDisplayer: mockInAppDisplayer,
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
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }
        
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, TestInAppPayloadGenerator.getClickUrl(index: 1))
            let messages = IterableAPI.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0].processed, true)
            
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer,
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
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getCustomActionUrl(index: 1))
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
            inAppDisplayer: mockInAppDisplayer
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
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 1.0
        
        let mockApplicationStateProvider = MockApplicationStateProvider(applicationState: .background)
        let mockNotificationCenter = MockNotificationCenter()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)

    }

    func testInAppShowWhenMovesToForeground() {
        let expectation1 = expectation(description: "testInAppShowWhenMovesToForeground")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "testInAppShowWhenMovesToForeground")

        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill() // expectation1 should not be fulfilled (inverted)
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 1.0
        
        let mockApplicationStateProvider = MockApplicationStateProvider(applicationState: .background)
        let mockNotificationCenter = MockNotificationCenter()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        
        mockApplicationStateProvider.applicationState = .active
        mockNotificationCenter.fire(notification: .UIApplicationDidBecomeActive)
        
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    func testDontShowMessageWithinRetryInterval() {
        let expectation1 = expectation(description: "show first message")
        let expectation2 = expectation(description: "don't show second message within interval")
        expectation2.isInverted = true
        let expectation3 = expectation(description: "show second message after retry interval")

        let retryInterval = 2.0

        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        var messageNumber = -1
        mockInAppDisplayer.onShowCallback = {(_, _) in
            if messageNumber == 1 {
                expectation1.fulfill()
                mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: messageNumber))
            } else if messageNumber == 2 {
                expectation2.fulfill()
                mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: messageNumber))
            } else if messageNumber == 3 {
                expectation3.fulfill()
                mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: messageNumber))
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
            inAppDisplayer: mockInAppDisplayer
        )
        
        // send first message payload
        messageNumber = 1
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrlWithOneMessage(messageNumber: messageNumber))
        wait(for: [expectation1], timeout: testExpectationTimeout)

        // second message payload, should not be shown
        messageNumber = 2
        let margin = 0.1 // give some time for execution
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrlWithOneMessage(messageNumber: messageNumber))
        wait(for: [expectation2], timeout: retryInterval - margin)

        // After retryInternval, the third should show
        messageNumber = 3
        wait(for: [expectation3], timeout: testExpectationTimeout)
    }
    
    func testRemoveMessages() {
        let expectation1 = expectation(description: "show first message")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: 1))
        }

        IterableAPI.initializeForTesting(
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3))
        
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 3)

        // First one will be shown automatically, so we have two left now
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 2)

        // now remove 1, there should be 1 left
        IterableAPI.inAppManager.remove(message: IterableAPI.inAppManager.getMessages()[0])
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
    }
    
    func testMultipleMesssagesInShortTime() {
        let expectation0 = expectation(description: "testMultipleMesssagesInShortTime")
        expectation0.expectedFulfillmentCount = 3 // three times
        let expectation1 = expectation(description: "testAutoShowInAppMultiple, first")
        let expectation2 = expectation(description: "testAutoShowInAppMultiple, second")
        let expectation3 = expectation(description: "testAutoShowInAppMultiple, third")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(message, _) in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickUrl(index: TestInAppPayloadGenerator.index(fromCampaignId: message.campaignId)))
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
            inAppDisplayer: mockInAppDisplayer
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

}
