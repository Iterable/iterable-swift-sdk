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
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            // 1 message is present when showing
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
            expectation1.fulfill()
        }
        
        IterableAPI.initializeForTesting(
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        // Zero messages should be left after showing
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    // skip the inApp in inAppDelegate
    func testAutoShowInAppSingleOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppSingleOverride")
        expectation1.isInverted = true
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 1)
        XCTAssertEqual(IterableAPI.inAppManager.getMessages()[0].processed, true)

        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }

    func testAutoShowInAppMultiple() {
        let expectation1 = expectation(description: "testAutoShowInAppMultiple")

        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 3)
            expectation1.fulfill()
        }
        
        IterableAPI.initializeForTesting(
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        let messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].processed, false)
        XCTAssertEqual(messages[1].processed, false)

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testAutoShowInAppMultipleOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppMultipleOverride")
        expectation1.isInverted = true
        
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )

        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        let messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(Set(messages.map { $0.processed }), Set([false, true, false]))

        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
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
        let messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 0)

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
        let messages = IterableAPI.inAppManager.getMessages()
        // Message count is 0 because inApp is still being shown. It is just not opening external url on click.
        XCTAssertEqual(messages.count, 0)

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
        
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
        
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
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].processed, true)

        // Now show the first message, but don't consume
        IterableAPI.inAppManager.show(message: messages[0], consume: false) { (clickedUrl) in
            XCTAssertEqual(clickedUrl, TestInAppPayloadGenerator.getClickUrl(index: 1))
            expectation1.fulfill()
        }
        
        messages = IterableAPI.inAppManager.getMessages()
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].processed, true)

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
        
        XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 0)
        
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
}
