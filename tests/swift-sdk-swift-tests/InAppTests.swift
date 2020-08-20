//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        TestUtils.clearTestUserDefaults()
    }
    
    func testInAppDelivery() {
        let expectation1 = expectation(description: "testInAppDelivery")
        expectation1.expectedFulfillmentCount = 2
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockNetworkSession = MockNetworkSession()
        mockNetworkSession.requestCallback = { urlRequest in
            guard urlRequest.url!.absoluteString.contains(Const.Path.trackInAppDelivery) else {
                return
            }
            expectation1.fulfill()
        }
        let internalApi = IterableAPIInternal.initializeForTesting(networkSession: mockNetworkSession, inAppFetcher: mockInAppFetcher)
        internalApi.email = "user@example.com"
        
        let payloadFromServer = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message1",
                "campaignId": 1,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message2",
                "campaignId": 2,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payloadFromServer)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testAutoShowInAppSingle() {
        let expectation1 = expectation(description: "testAutoShowInAppSingle")
        let expectation2 = expectation(description: "count decrements after showing")
        let expectation3 = expectation(description: "message count is not 0")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { message in
            print(message)
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: 1))
            expectation1.fulfill()
        }
        
        var internalApi: IterableAPIInternal!
        let config = IterableConfig()
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = { _, _ in
            XCTAssertEqual(internalApi.inAppManager.getMessages().count, 0)
            expectation2.fulfill()
        }
        config.urlDelegate = mockUrlDelegate
        
        internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)).onSuccess { _ in
            // first message has been processed by now
            XCTAssertEqual(internalApi.inAppManager.getMessages().count, 0)
            expectation3.fulfill()
        }
        
        wait(for: [expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
    }
    
    // skip the in-app in inAppDelegate
    func testAutoShowInAppSingleOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppSingleOverride")
        expectation1.isInverted = true
        
        let expectation2 = expectation(description: "message count is not 1 or did not process")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: 1))
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)).onSuccess { _ in
            XCTAssertEqual(internalApi.inAppManager.getMessages().count, 1)
            XCTAssertEqual(internalApi.inAppManager.getMessages()[0].didProcessTrigger, true)
            
            expectation2.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    func testAutoShowInAppMultipleWithOrdering() {
        let expectation0 = expectation(description: "testAutoShowInAppMultiple")
        expectation0.expectedFulfillmentCount = 3 // three times
        let expectation1 = expectation(description: "testAutoShowInAppMultiple, first")
        let expectation2 = expectation(description: "testAutoShowInAppMultiple, second")
        let expectation3 = expectation(description: "testAutoShowInAppMultiple, third")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { message in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: TestInAppPayloadGenerator.index(fromCampaignId: message.campaignId)))
            expectation0.fulfill()
        }
        
        var callOrder = [Int]()
        let urlDelegate = MockUrlDelegate(returnValue: true)
        urlDelegate.callback = { url, _ in
            if url == TestInAppPayloadGenerator.getClickedUrl(index: 1) {
                callOrder.append(1)
                expectation1.fulfill()
            }
            if url == TestInAppPayloadGenerator.getClickedUrl(index: 2) {
                callOrder.append(2)
                expectation2.fulfill()
            }
            if url == TestInAppPayloadGenerator.getClickedUrl(index: 3) {
                callOrder.append(3)
                expectation3.fulfill()
            }
        }
        
        let config = IterableConfig()
        config.urlDelegate = urlDelegate
        config.inAppDisplayInterval = 1.0
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        let indices = [1, 3, 2]
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(indices: indices)
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payload)
        
        wait(for: [expectation0, expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
        
        XCTAssertEqual(callOrder, indices)
    }
    
    func testAutoShowInAppMultipleOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppMultipleOverride")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "all messages processed")
        
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3)
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: URL(string: "https://somewhere.com")!)
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        config.inAppDisplayInterval = 0.5
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payload).onSuccess { _ in
            let messages = internalApi.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 3)
            XCTAssertEqual(Set(messages.map { $0.didProcessTrigger }), Set([true, true, true]))
            expectation2.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    // in-app is shown and url is opened when link is clicked
    func testAutoShowInAppOpenUrlByDefault() {
        let expectation1 = expectation(description: "testAutoShowInAppOpenUrlByDefault")
        
        var internalApi: IterableAPIInternal!
        let mockInAppFetcher = MockInAppFetcher()
        let mockUrlOpener = MockUrlOpener { url in
            XCTAssertEqual(url, TestInAppPayloadGenerator.getClickedUrl(index: 1))
            XCTAssertEqual(internalApi.inAppManager.getMessages().count, 0)
            expectation1.fulfill()
        }
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: 1))
        }
        
        internalApi = IterableAPIInternal.initializeForTesting(
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    // override in url delegate
    // in-app is shown but does not open external url
    func testAutoShowInAppUrlDelegateOverride() {
        let expectation1 = expectation(description: "testAutoShowInAppUrlDelegateOverride")
        expectation1.isInverted = true
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockUrlOpener = MockUrlOpener { _ in
            expectation1.fulfill()
        }
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: 1))
        }
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }
    
    func testAutoDisplayOff() {
        let expectation1 = expectation(description: "testAutoDisplayOff")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let internalAPI = IterableAPIInternal.initializeForTesting(
            config: IterableConfig(),
            inAppFetcher: mockInAppFetcher
        )
        
        // verify the default value of auto displaying
        XCTAssertFalse(internalAPI.inAppManager.isAutoDisplayPaused)
        
        internalAPI.inAppManager.isAutoDisplayPaused = true
        
        // verify that auto display has been set to true
        XCTAssertTrue(internalAPI.inAppManager.isAutoDisplayPaused)
        
        // the fetcher normally shows the first one, but here, it shouldn't with auto displaying off
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: [getEmptyInAppMessage()]).onSuccess { messageCount in
            XCTAssertEqual(messageCount, 1)
            
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }
    
    func testAutoDisplayResumed() {
        let expectation1 = expectation(description: "make sure auto display pausing works")
        let expectation2 = expectation(description: "resume auto display pausing, show next message")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let internalAPI = IterableAPIInternal.initializeForTesting(
            config: IterableConfig(),
            inAppFetcher: mockInAppFetcher
        )
        
        internalAPI.inAppManager.isAutoDisplayPaused = true
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: [getEmptyInAppMessage()]).onSuccess { messageCount in
            XCTAssertEqual(messageCount, 1)
            
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        
        internalAPI.inAppManager.isAutoDisplayPaused = false
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: [getEmptyInAppMessage()]).onSuccess { messageCount in
            XCTAssertEqual(messageCount, 0)
            
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: testExpectationTimeoutForInverted)
    }
    
    func testShowInAppWithConsume() {
        let expectation1 = expectation(description: "testShowInAppWithConsume")
        let expectation2 = expectation(description: "url opened")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: 1))
        }
        
        let mockUrlOpener = MockUrlOpener { url in
            XCTAssertEqual(url, TestInAppPayloadGenerator.getClickedUrl(index: 1))
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)).onSuccess { _ in
            let messages = internalApi.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 1)
            
            internalApi.inAppManager.show(message: messages[0], consume: true) { clickedUrl in
                XCTAssertEqual(clickedUrl, TestInAppPayloadGenerator.getClickedUrl(index: 1))
                expectation1.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }
    
    func testShowInAppWithNoConsume() {
        let expectation1 = expectation(description: "testShowInAppWithNoConsume")
        let expectation2 = expectation(description: "url opened")
        
        var internalApi: IterableAPIInternal!
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: 1))
        }
        
        let mockUrlOpener = MockUrlOpener { url in
            XCTAssertEqual(url, TestInAppPayloadGenerator.getClickedUrl(index: 1))
            
            let messages = internalApi.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0].didProcessTrigger, true)
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)).onSuccess { _ in
            let messages = internalApi.inAppManager.getMessages()
            // Now show the first message, but don't consume
            internalApi.inAppManager.show(message: messages[0], consume: false) { clickedUrl in
                XCTAssertEqual(clickedUrl, TestInAppPayloadGenerator.getClickedUrl(index: 1))
                expectation1.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }
    
    func testShowInAppWithCustomAction() {
        let expectation1 = expectation(description: "testShowInAppWithCustomAction")
        let expectation2 = expectation(description: "custom action called")
        let expectation3 = expectation(description: "count reduces")
        
        var internalApi: IterableAPIInternal!
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getCustomActionUrl(index: 1))
        }
        
        let mockCustomActionDelegate = MockCustomActionDelegate(returnValue: true) // returnValue is reserved, no effect
        mockCustomActionDelegate.callback = { customActionName, context in
            XCTAssertEqual(customActionName, TestInAppPayloadGenerator.getCustomActionName(index: 1))
            XCTAssertEqual(context.source, .inApp)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                XCTAssertEqual(internalApi.inAppManager.getMessages().count, 0)
                expectation3.fulfill()
            }
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        config.customActionDelegate = mockCustomActionDelegate
        
        internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)).onSuccess { _ in
            let messages = internalApi.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 1, "expected 1 messages here")
            
            internalApi.inAppManager.show(message: messages[0], consume: true) { customActionUrl in
                XCTAssertEqual(customActionUrl, TestInAppPayloadGenerator.getCustomActionUrl(index: 1))
                expectation1.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
    }
    
    func testShowInAppWithIterableCustomActionDelete() {
        var internalApi: IterableAPIInternal!
        let expectation1 = expectation(description: "correct number of messages")
        let predicate = NSPredicate { (_, _) -> Bool in
            internalApi.inAppManager.getMessages().count == 0
        }
        let expectation2 = expectation(for: predicate, evaluatedWith: nil, handler: nil)
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let iterableDeleteUrl = "iterable://delete"
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            let count = internalApi.inAppManager.getMessages().count
            XCTAssertEqual(count, 1)
            mockInAppDisplayer.click(url: URL(string: iterableDeleteUrl)!)
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .show)
        config.logDelegate = AllLogDelegate()
        
        internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'\(iterableDeleteUrl)'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message0",
                "campaignId": 1,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payload).onSuccess { _ in
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    func testShowInAppWithIterableCustomActionDismiss() {
        var internalApi: IterableAPIInternal!
        let expectation1 = expectation(description: "messages fetched")
        let expectation2 = expectation(description: "custom action dismiss called")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let iterableDismissUrl = "iterable://dismiss"
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: URL(string: iterableDismissUrl)!)
            XCTAssertEqual(internalApi.inAppManager.getMessages().count, 1)
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .show)
        
        internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'\(iterableDismissUrl)'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message0",
                "campaignId": 1,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payload).onSuccess { _ in
            let messages = internalApi.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 1)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }
    
    func testShowInAppWithCustomActionBackwardCompatibility() {
        let customActionScheme = "itbl"
        let customActionName = "my_custom_action"
        let expectation1 = expectation(description: "verify custom action is called, customActionScheme: \(customActionScheme), customActionName: \(customActionName)")
        verifyCustomActionIsCalled(expectation1: expectation1,
                                   customActionScheme: customActionScheme,
                                   customActionName: customActionName)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testShowInAppWithCustomAction1() {
        let customActionScheme = "action"
        let customActionName = "my_custom_action"
        let expectation1 = expectation(description: "verify custom action is called, customActionScheme: \(customActionScheme), customActionName: \(customActionName)")
        verifyCustomActionIsCalled(expectation1: expectation1,
                                   customActionScheme: customActionScheme,
                                   customActionName: customActionName)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    // Check that onNew is called just once if the messageId is same.
    func testOnNewNotCalledMultipleTimes() {
        let expectation1 = expectation(description: "testOnNewNotCalledMultipleTimes")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        mockInAppDelegate.onNewMessageCallback = { _ in
            // should only be called once
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        // Send second message with same id.
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1))
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDeleteInServerDeletesInClient() {
        let expectation1 = expectation(description: "testDeleteInServerDeletesInClient1")
        let expectation2 = expectation(description: "testDeleteInServerDeletesInClient2")
        let mockInAppFetcher = MockInAppFetcher()
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3)).onSuccess { _ in
            XCTAssertEqual(internalApi.inAppManager.getMessages().count, 3)
            expectation1.fulfill()
            mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 2)).onSuccess { _ in
                XCTAssertEqual(internalApi.inAppManager.getMessages().count, 2)
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }
    
    func testInAppDoNotShowInBackground() {
        let expectation1 = expectation(description: "testInAppDoNotShowInBackground")
        expectation1.isInverted = true
        
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 1.0
        
        let mockApplicationStateProvider = MockApplicationStateProvider(applicationState: .background)
        let mockNotificationCenter = MockNotificationCenter()
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payload)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }
    
    func testInAppShowWhenMovesToForeground() {
        let expectation1 = expectation(description: "do not show when in background")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "show when moves to foreground")
        
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockDateProvider = MockDateProvider()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            expectation1.fulfill() // expectation1 should not be fulfilled within timeout (inverted)
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 1.0
        
        let mockApplicationStateProvider = MockApplicationStateProvider(applicationState: .background)
        let mockNotificationCenter = MockNotificationCenter()
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payload)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(1000.0)
        mockApplicationStateProvider.applicationState = .active
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
    
    func testMoveToForegroundSyncInterval() {
        let expectation0 = expectation(description: "first time when messages are obtained")
        let expectation1 = expectation(description: "do not sync because app is not in foreground")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "sync first time when moving to foreground")
        let expectation3 = expectation(description: "do not sync second time")
        expectation3.isInverted = true
        let expectation4 = expectation(description: "sync third time after time has passed")
        
        let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 1)
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockDateProvider = MockDateProvider()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: 1)) // need to call so future is resolved
            expectation1.fulfill() // expectation1 should not be fulfilled within timeout (inverted)
            expectation2.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 1.0
        
        let mockApplicationStateProvider = MockApplicationStateProvider(applicationState: .background)
        let mockNotificationCenter = MockNotificationCenter()
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer,
            applicationStateProvider: mockApplicationStateProvider,
            notificationCenter: mockNotificationCenter
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payload).onSuccess { _ in
            expectation0.fulfill()
        }
        wait(for: [expectation0], timeout: testExpectationTimeout)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
        
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(1000.0)
        mockApplicationStateProvider.applicationState = .active
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        wait(for: [expectation2], timeout: testExpectationTimeout)
        
        // now move to foreground within interval
        mockInAppFetcher.syncCallback = {
            expectation3.fulfill()
        }
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        wait(for: [expectation3], timeout: testExpectationTimeoutForInverted)
        
        // now move to foreground outside of interval
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(1000.0)
        mockInAppFetcher.syncCallback = {
            expectation4.fulfill()
        }
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        wait(for: [expectation4], timeout: testExpectationTimeout)
    }
    
    func testDontShowNewlyArrivedMessageWithinRetryInterval() {
        let expectation1 = expectation(description: "show first message")
        let expectation2 = expectation(description: "don't show second message within interval")
        expectation2.isInverted = true
        let expectation3 = expectation(description: "show third message after retry interval")
        
        let retryInterval = 2.0
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockDateProvider = MockDateProvider()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        var messageNumber = -1
        mockInAppDisplayer.onShow.onSuccess { _ in
            if messageNumber == 1 {
                expectation1.fulfill()
                mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: messageNumber))
            } else if messageNumber == 2 {
                // it should never be true
                expectation2.fulfill()
                mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: messageNumber))
            } else if messageNumber == 3 {
                expectation3.fulfill()
                mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: messageNumber))
            } else {
                // unexpected message number
                XCTFail()
            }
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = retryInterval
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            dateProvider: mockDateProvider,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        // send first message payload
        messageNumber = 1
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(indices: 1 ... messageNumber))
        wait(for: [expectation1], timeout: testExpectationTimeout)
        
        // second message payload, should not be shown
        messageNumber = 2
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(retryInterval - 0.01)
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(indices: 1 ... messageNumber))
        wait(for: [expectation2], timeout: retryInterval)
        
        // After retryInternval, the second message should show
        messageNumber = 3
        mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(1000)
        wait(for: [expectation3], timeout: testExpectationTimeout)
    }
    
    func testRemoveMessages() {
        let expectation1 = expectation(description: "testRemoveMessages1")
        let expectation2 = expectation(description: "testRemoveMessages2")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            expectation2.fulfill()
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: 1))
        }
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3)).onSuccess { _ in
            expectation1.fulfill()
        }
        
        // First one will be shown automatically, so we have two left now
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
        XCTAssertEqual(internalApi.inAppManager.getMessages().count, 2)
        
        // now remove 1, there should be 1 left
        let expectation3 = expectation(description: "remove reduces count to 1")
        let expectation4 = expectation(description: "remove reduces count to 0")
        internalApi.inAppManager.remove(message: internalApi.inAppManager.getMessages()[0])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            XCTAssertEqual(internalApi.inAppManager.getMessages().count, 1)
            expectation3.fulfill()
            // now remove 1, there should be 0 left
            internalApi.inAppManager.remove(message: internalApi.inAppManager.getMessages()[0], location: .inApp)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                XCTAssertEqual(internalApi.inAppManager.getMessages().count, 0)
                expectation4.fulfill()
            }
        }
        wait(for: [expectation3, expectation4], timeout: testExpectationTimeout)
    }
    
    func testMultipleMesssagesInShortTime() {
        let expectation0 = expectation(description: "testMultipleMesssagesInShortTime")
        expectation0.expectedFulfillmentCount = 3 // three times
        let expectation1 = expectation(description: "testAutoShowInAppMultiple, first")
        let expectation2 = expectation(description: "testAutoShowInAppMultiple, second")
        let expectation3 = expectation(description: "testAutoShowInAppMultiple, third")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { message in
            mockInAppDisplayer.click(url: TestInAppPayloadGenerator.getClickedUrl(index: TestInAppPayloadGenerator.index(fromCampaignId: message.campaignId)))
            expectation0.fulfill()
        }
        
        var callOrder = [Int]()
        var callTimes = [Date]()
        let urlDelegate = MockUrlDelegate(returnValue: true)
        urlDelegate.callback = { url, _ in
            if url == TestInAppPayloadGenerator.getClickedUrl(index: 1) {
                callTimes.append(Date())
                callOrder.append(1)
                expectation1.fulfill()
            }
            if url == TestInAppPayloadGenerator.getClickedUrl(index: 2) {
                callTimes.append(Date())
                callOrder.append(2)
                expectation2.fulfill()
            }
            if url == TestInAppPayloadGenerator.getClickedUrl(index: 3) {
                callTimes.append(Date())
                callOrder.append(3)
                expectation3.fulfill()
            }
        }
        
        let config = IterableConfig()
        let interval = 0.5
        config.urlDelegate = urlDelegate
        config.inAppDisplayInterval = interval
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1]))
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1, 3]))
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1, 3, 2]))
        
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
        let createdAt = Date()
        let expiresAt = createdAt.addingTimeInterval(60 * 60 * 24)
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": false,
                "content": {"type": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site1.com\'>Click Here</a>", "payload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}},
                "trigger": {"type": "event", "details": "some event details"},
                "messageId": "message1",
                "createdAt": \(IterableUtil.int(fromDate: createdAt)),
                "expiresAt": \(IterableUtil.int(fromDate: expiresAt)),
                "campaignId": 1,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"type": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message2",
                "createdAt": 1550605745142,
                "expiresAt": 1657258509185,
                "campaignId": 2,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "content": {"inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site3.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message3",
                "campaignId": 3,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "content": {"inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site4.com\'>Click Here</a>"},
                "trigger": {"type": "newEventType", "nested": {"var1": "val1"}},
                "messageId": "message4",
                "createdAt": 1550605745142,
                "expiresAt": 1657258509185,
                "campaignId": 4,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            }
        ]
        }
        """.toJsonDict()
        
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        messages[0].read = true
        TestUtils.validateEqual(date1: messages[0].createdAt, date2: createdAt)
        TestUtils.validateEqual(date1: messages[0].expiresAt, date2: expiresAt)
        let persister = InAppFilePersister()
        persister.persist(messages)
        let obtained = persister.getMessages()
        XCTAssertEqual(messages.description, obtained.description)
        
        XCTAssertEqual(obtained[3].trigger.type, IterableInAppTriggerType.never)
        let dict = obtained[3].trigger.dict as! [String: Any]
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
        let expectation1 = expectation(description: "testPersistBetweenSessions1")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let internalApi1 = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppPersister: InAppFilePersister()
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi1, TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1, 3, 2])).onSuccess { _ in
            XCTAssertEqual(internalApi1.inAppManager.getMessages().count, 3)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        
        let internalApi2 = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppPersister: InAppFilePersister()
        )
        
        XCTAssertEqual(internalApi2.inAppManager.getMessages().count, 3)
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
        
        let notification = try! JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: []) as! [AnyHashable: Any]
        
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
                "messageId": "background_notification",
                "isGhostPush": true
            },
            "notificationType": "InAppRemove",
            "messageId": "messageId"
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
                "messageId": "background_notification",
                "isGhostPush": true
            },
            "notificationType": "InAppUpdate",
            "messageId": "messageId"
        }
        """.toJsonDict()
        
        let mockInAppFetcher = MockInAppFetcher()
        mockInAppFetcher.syncCallback = {
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher
        )
        
        let appIntegration = IterableAppIntegrationInternal(tracker: internalApi,
                                                            urlDelegate: config.urlDelegate,
                                                            customActionDelegate: config.customActionDelegate,
                                                            urlOpener: MockUrlOpener(),
                                                            inAppNotifiable: internalApi.inAppManager)
        
        appIntegration.application(UIApplication.shared, didReceiveRemoteNotification: notification, fetchCompletionHandler: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testRemoveIsCalled() {
        let expectation1 = expectation(description: "testRemoveIsCalled")
        
        let notification = """
        {
            "itbl": {
                "messageId": "background_notification",
                "isGhostPush": true
            },
            "notificationType": "InAppRemove",
            "messageId": "messageId"
        }
        """.toJsonDict()
        
        class MockInAppManager: EmptyInAppManager {
            let expectation: XCTestExpectation
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            
            override func onInAppRemoved(messageId: String) {
                XCTAssertEqual(messageId, "messageId")
                expectation.fulfill()
            }
        }
        
        let mockInAppManager = MockInAppManager(expectation: expectation1)
        
        let appIntegration = IterableAppIntegrationInternal(tracker: MockPushTracker(), inAppNotifiable: mockInAppManager)
        appIntegration.application(MockApplicationStateProvider(applicationState: .background), didReceiveRemoteNotification: notification, fetchCompletionHandler: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testInAppRemoveMessagePayload1() {
        checkInAppRemoveMessagePayload(location: .inApp, source: nil, removeFunction: { $0.inAppManager.remove(message: $1) })
    }
    
    func testInAppRemoveMessagePayload2() {
        checkInAppRemoveMessagePayload(location: .inbox, source: nil, removeFunction: { $0.inAppManager.remove(message: $1, location: .inbox) })
    }
    
    func testInAppRemoveMessagePayload3() {
        checkInAppRemoveMessagePayload(location: .inbox, source: .deleteButton, removeFunction: { $0.inAppManager.remove(message: $1, location: .inbox, source: .deleteButton) })
    }
    
    private func checkInAppRemoveMessagePayload(location: InAppLocation, source: InAppDeleteSource?, removeFunction: @escaping (IterableAPIInternal, IterableInAppMessage) -> Void) {
        let expectation1 = expectation(description: "checkInAppRemoveMessagePayload")
        let mockInAppFetcher = MockInAppFetcher()
        let mockNetworkSession = MockNetworkSession()
        mockNetworkSession.requestCallback = { urlRequest in
            guard urlRequest.url!.absoluteString.contains(Const.Path.inAppConsume) else {
                return
            }
            TestUtils.validate(request: urlRequest, requestType: .post, apiEndPoint: Endpoint.api, path: Const.Path.inAppConsume)
            let body = mockNetworkSession.getRequestBody() as! [String: Any]
            TestUtils.validateMessageContext(messageId: "message1", saveToInbox: true, silentInbox: true, location: location, inBody: body)
            if let deleteAction = source {
                TestUtils.validateMatch(keyPath: KeyPath(.deleteAction), value: deleteAction.jsonValue as! String, inDictionary: body, message: "deleteAction should be nil")
            } else {
                TestUtils.validateNil(keyPath: KeyPath(.deleteAction), inDictionary: body, message: "deleteAction should be nil")
            }
            expectation1.fulfill()
        }
        let internalApi = IterableAPIInternal.initializeForTesting(
            networkSession: mockNetworkSession,
            inAppFetcher: mockInAppFetcher
        )
        internalApi.email = "user@example.com"
        
        let payloadFromServer = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message1",
                "campaignId": 1,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message2",
                "campaignId": 2,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payloadFromServer).onSuccess { _ in
            let messages = internalApi.inAppManager.getInboxMessages()
            XCTAssertEqual(messages.count, 2)
            
            removeFunction(internalApi, messages[0])
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testInboxChangedIsCalledWhenInAppIsRemovedInServer() {
        let expectation1 = expectation(description: "testInboxChangedIsCalledWhenInAppIsRemovedInServer")
        
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
        
        let mockNotificationCenter = MockNotificationCenter()
        mockNotificationCenter.addCallback(forNotification: .iterableInboxChanged) {
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        let internalApi = IterableAPIInternal.initializeForTesting(config: config, notificationCenter: mockNotificationCenter)
        
        let appIntegrationInternal = IterableAppIntegrationInternal(tracker: internalApi,
                                                                    urlDelegate: config.urlDelegate,
                                                                    customActionDelegate: config.customActionDelegate,
                                                                    urlOpener: MockUrlOpener(),
                                                                    inAppNotifiable: internalApi.inAppManager)
        
        appIntegrationInternal.application(MockApplicationStateProvider(applicationState: .background), didReceiveRemoteNotification: notification, fetchCompletionHandler: nil)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testSyncIsCalledOnLogin() {
        let expectation1 = expectation(description: "testSyncIsCalledOnLogin")
        expectation1.expectedFulfillmentCount = 2 // once on initialization
        
        let mockInAppFetcher = MockInAppFetcher()
        mockInAppFetcher.syncCallback = {
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        TestUtils.clearTestUserDefaults()
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher
        )
        
        internalApi.userId = "newUserId"
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDoNoProcessNonImmediateTriggerTypes() {
        let expectation1 = expectation(description: "do not call event trigger")
        expectation1.isInverted = true
        let expectation2 = expectation(description: "call immediate trigger 1")
        let expectation3 = expectation(description: "do not call never trigger")
        expectation3.isInverted = true
        let expectation4 = expectation(description: "call immediate trigger 2")
        
        let payload = ["inAppMessages": [
            TestInAppPayloadGenerator.createOneInAppDictWithUrl(index: 1, triggerType: .event),
            TestInAppPayloadGenerator.createOneInAppDictWithUrl(index: 2, triggerType: .immediate),
            TestInAppPayloadGenerator.createOneInAppDictWithUrl(index: 3, triggerType: .never),
            TestInAppPayloadGenerator.createOneInAppDictWithUrl(index: 4, triggerType: .immediate),
        ]]
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        mockInAppDelegate.onNewMessageCallback = { message in
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
        
        let internalApi = IterableAPIInternal.initializeForTesting(config: config,
                                                                   inAppFetcher: mockInAppFetcher)
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payload)
        
        wait(for: [expectation1, expectation3], timeout: testExpectationTimeoutForInverted)
        wait(for: [expectation2, expectation4], timeout: testExpectationTimeout)
    }
    
    func testExpiration() {
        let expectation1 = expectation(description: "testExpiration")
        
        let mockDateProvider = MockDateProvider()
        let mockInAppFetcher = MockInAppFetcher()
        
        let config = IterableConfig()
        config.logDelegate = AllLogDelegate()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let internalApi = IterableAPIInternal.initializeForTesting(config: config,
                                                                   dateProvider: mockDateProvider,
                                                                   inAppFetcher: mockInAppFetcher)
        
        let message = IterableInAppMessage(messageId: "messageId-1",
                                           campaignId: 1,
                                           expiresAt: mockDateProvider.currentDate.addingTimeInterval(1.0 * 60.0), // one minute from now
                                           content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "<html></html>"))
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalApi, messages: [message]).onSuccess { _ in
            XCTAssertEqual(internalApi.inAppManager.getMessages().count, 1)
            
            mockDateProvider.currentDate = mockDateProvider.currentDate.addingTimeInterval(2.0 * 60) // two minutes from now
            
            XCTAssertEqual(internalApi.inAppManager.getMessages().count, 0)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testEmptyInAppManager() {
        let expectation1 = expectation(description: "scheduleSync() returns a true value")
        let expectation2 = expectation(description: "reset() returns a true value")
        
        let emptyManager = EmptyInAppManager()
        
        _ = emptyManager.start()
        
        XCTAssertNil(emptyManager.createInboxMessageViewController(for: getEmptyInAppMessage(), withInboxMode: .nav))
        
        XCTAssertEqual(emptyManager.getMessages(), [])
        
        XCTAssertEqual(emptyManager.getInboxMessages(), [])
        
        // maybe test with a constructed message and check for changes on that message?
        emptyManager.show(message: getEmptyInAppMessage())
        
        emptyManager.show(message: getEmptyInAppMessage(), consume: true, callback: nil)
        
        emptyManager.remove(message: getEmptyInAppMessage())
        
        emptyManager.remove(message: getEmptyInAppMessage(), location: .inApp)
        
        emptyManager.remove(message: getEmptyInAppMessage(), location: .inApp, source: .deleteButton)
        
        emptyManager.remove(message: getEmptyInAppMessage(), location: .inApp, source: .deleteButton, inboxSessionId: nil)
        
        emptyManager.set(read: true, forMessage: getEmptyInAppMessage())
        
        XCTAssertEqual(emptyManager.getUnreadInboxMessagesCount(), 0)
        
        emptyManager.scheduleSync().onSuccess(block: { value in
            XCTAssertTrue(value)
            expectation1.fulfill()
        })
        
        emptyManager.onInAppRemoved(messageId: "")
        
        XCTAssertTrue(emptyManager.isOkToShowNow(message: getEmptyInAppMessage()))
        
        emptyManager.reset().onSuccess { value in
            XCTAssertTrue(value)
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: testExpectationTimeout)
    }
    
    private func getEmptyInAppMessage() -> IterableInAppMessage {
        IterableInAppMessage(messageId: "", campaignId: 0, content: getEmptyInAppContent())
    }
    
    private func getEmptyInAppContent() -> IterableInAppContent {
        IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0, html: "")
    }
    
    fileprivate func verifyCustomActionIsCalled(expectation1: XCTestExpectation, customActionScheme: String, customActionName: String) {
        let expectation2 = expectation(description: "correct number of messages")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let customActionUrl = "\(customActionScheme)://\(customActionName)"
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            mockInAppDisplayer.click(url: URL(string: customActionUrl)!)
        }
        
        let mockCustomActionDelegate = MockCustomActionDelegate(returnValue: true)
        mockCustomActionDelegate.callback = { actionName, _ in
            XCTAssertEqual(actionName, customActionName)
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .show)
        config.customActionDelegate = mockCustomActionDelegate
        
        let internalApi = IterableAPIInternal.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        let payload = """
        {
            "inAppMessages":
            [{
            "saveToInbox": true,
            "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'\(customActionUrl)'>Click Here</a>"},
            "trigger": {"type": "immediate"},
            "messageId": "message0",
            "campaignId": 1,
            "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            }]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi, payload).onSuccess { _ in
            let messages = internalApi.inAppManager.getMessages()
            XCTAssertEqual(messages.count, 1)
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }
}

extension IterableInAppTrigger {
    override public var description: String {
        "type: \(type)"
    }
}

extension IterableHtmlInAppContent {
    override public var description: String {
        IterableUtil.describe("type", type,
                              "edgeInsets", edgeInsets,
                              "backgroundAlpha", backgroundAlpha,
                              "html", html, pairSeparator: " = ", separator: ", ")
    }
}

extension IterableInboxMetadata {
    override public var description: String {
        IterableUtil.describe("title", title ?? "nil",
                              "subtitle", subtitle ?? "nil",
                              "icon", icon ?? "nil",
                              pairSeparator: " = ", separator: ", ")
    }
}

extension IterableInAppMessage {
    override public var description: String {
        IterableUtil.describe("messageId", messageId,
                              "campaignId", campaignId ?? "nil",
                              "saveToInbox", saveToInbox,
                              "inboxMetadata", inboxMetadata ?? "nil",
                              "trigger", trigger,
                              "createdAt", createdAt ?? "nil",
                              "expiresAt", expiresAt ?? "nil",
                              "content", content,
                              "didProcessTrigger", didProcessTrigger,
                              "consumed", consumed,
                              "read", read,
                              pairSeparator: " = ", separator: "\n")
    }
}
