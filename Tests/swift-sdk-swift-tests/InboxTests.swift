//
//  InboxTests.swift
//  swift-sdk-swift-tests
//
//  Created by Tapash Majumder on 3/6/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxTests: XCTestCase {
    func testInboxOrdering() {
        let expectation1 = expectation(description: "testInboxOrdering")
        let mockInAppFetcher = MockInAppFetcher()
        let config = IterableConfig()
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher
        )
       
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": false,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site1.com\'>Click Here</a>", "payload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}},
                "trigger": {"type": "event", "details": "some event details"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message2",
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
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message4",
                "campaignId": "campaign4",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()

        mockInAppFetcher.mockInAppPayloadFromServer(payload) {
            let messages = IterableAPI.inAppManager.getInboxMessages()
            XCTAssertEqual(messages.count, 2)
            XCTAssertEqual(messages[0].messageId, "message2")
            XCTAssertEqual(messages[1].messageId, "message4")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testSetRead() {
        let expectation1 = expectation(description: "testSetRead")
        let mockInAppFetcher = MockInAppFetcher()
        let config = IterableConfig()
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher
        )
        
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message2",
                "campaignId": "campaign2",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload) {
            let messages = IterableAPI.inAppManager.getInboxMessages()
            XCTAssertEqual(messages.count, 2)
            IterableAPI.inAppManager.set(read: true, forMessage: messages[1])
            XCTAssertEqual(messages[0].read, false)
            XCTAssertEqual(messages[1].read, true)
            
            let unreadMessages = IterableAPI.inAppManager.getInboxMessages().filter { $0.read == false }
            XCTAssertEqual(IterableAPI.inAppManager.getUnreadInboxMessagesCount(), 1)
            XCTAssertEqual(unreadMessages.count, 1)
            XCTAssertEqual(unreadMessages[0].read, false)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testRemove() {
        let expectation1 = expectation(description: "testRemove")
        let mockInAppFetcher = MockInAppFetcher()
        let config = IterableConfig()
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher
        )
        
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message2",
                "campaignId": "campaign2",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload) {
            let messages = IterableAPI.inAppManager.getInboxMessages()
            XCTAssertEqual(messages.count, 2)
            
            IterableAPI.inAppManager.remove(message: messages[0])
            let newMessages = IterableAPI.inAppManager.getInboxMessages()
            XCTAssertEqual(newMessages.count, 1)
            expectation1.fulfill()
        }
       
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testShowInboxMessage() {
        let expectation1 = expectation(description: "testShowInboxMessage")
        let expectation2 = expectation(description: "Unread count decrements after showing")
        let expectation3 = expectation(description: "Right url callback")
        let expectation4 = expectation(description: "wait for messages")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            expectation1.fulfill()
            // now click and url in the message
            mockInAppDisplayer.click(url: URL(string: "https://someurl.com")!)
        }
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = {(url, _) in
            XCTAssertEqual(url.absoluteString, "https://someurl.com")
            expectation2.fulfill()
            XCTAssertEqual(IterableAPI.inAppManager.getUnreadInboxMessagesCount(), 1)
        }
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )

        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message2",
                "campaignId": "campaign2",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload) {
            expectation4.fulfill()
        }
        wait(for: [expectation4], timeout: testExpectationTimeout)
        XCTAssertEqual(IterableAPI.inAppManager.getUnreadInboxMessagesCount(), 2)
        
        let messages = IterableAPI.inAppManager.getInboxMessages()
        IterableAPI.inAppManager.show(message: messages[0], consume: false) { (clickedUrl) in
            XCTAssertEqual(clickedUrl!.absoluteString, "https://someurl.com")
            expectation3.fulfill()
        }

        wait(for: [expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
    }
    
    func testInboxNewMessagesCallback() {
        let expectation1 = expectation(description: "testInboxNewMessagesCallback")
        expectation1.expectedFulfillmentCount = 2
        let expectation2 = expectation(description: "testInboxNewMessagesCallback: finish payload processing")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        var callbackCount = 0
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        let mockNotificationCenter = MockNotificationCenter()
        mockNotificationCenter.addCallback(forNotification: .iterableInboxChanged) {
            let messages = IterableAPI.inAppManager.getInboxMessages()
            if callbackCount == 0 {
                XCTAssertEqual(messages.count, 1)
                XCTAssertEqual(messages[0].messageId, "message0", "inboxMessages: \(IterableAPI.inAppManager.getInboxMessages())")
            } else {
                XCTAssertEqual(messages.count, 2)
                XCTAssertEqual(messages[1].messageId, "message1", "inboxMessages: \(IterableAPI.inAppManager.getInboxMessages())")
            }
            expectation1.fulfill()
            callbackCount += 1
        }
        
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            notificationCenter: mockNotificationCenter
        )
        
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message0",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: testExpectationTimeout)

        let payload2 = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message0",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload2)

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testInboxChangedCalledOnInitialization() {
        let expectation1 = expectation(description: "verify on inbox changed is called")

        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message0",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        let persister = InAppFilePersister()
        persister.clear()
        persister.persist(messages)

        let config = IterableConfig()
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        let mockNotificationCenter = MockNotificationCenter()
        mockNotificationCenter.addCallback(forNotification: .iterableInboxChanged) {
            let messages = IterableAPI.inAppManager.getInboxMessages()
            XCTAssertEqual(messages.count, 1)
            expectation1.fulfill()
        }

        config.inAppDelegate = mockInAppDelegate
        config.logDelegate = AllLogDelegate()
        
        let mockInAppFetcher = MockInAppFetcher(messages: messages)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppPersister: persister,
            notificationCenter: mockNotificationCenter
        )

        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        persister.clear()
    }
    
    func testInboxAndInAppCallbacksTogether() {
        let expectation1 = expectation(description: "call inbox callback")
        expectation1.expectedFulfillmentCount = 2
        let expectation2 = expectation(description: "call inApp callback")
        expectation2.expectedFulfillmentCount = 2
        let expectation3 = expectation(description: "payload 1 processed")
        let expectation4 = expectation(description: "payload 2 processed")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        var inAppCallbackCount = 0
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        mockInAppDelegate.onNewMessageCallback = {(message) in
            if inAppCallbackCount == 0 {
                XCTAssertEqual(message.messageId, "inAppMessage0")
            } else {
                XCTAssertEqual(message.messageId, "inAppMessage1")
            }
            expectation2.fulfill()
            inAppCallbackCount += 1
        }
        
        var inboxCallbackCount = 0
        let mockNotificationCenter = MockNotificationCenter()
        mockNotificationCenter.addCallback(forNotification: .iterableInboxChanged) {
            let messages = IterableAPI.inAppManager.getInboxMessages()
            if inboxCallbackCount == 0 {
                XCTAssertEqual(messages.count, 1, "inboxMessages: \(IterableAPI.inAppManager.getInboxMessages())")
                XCTAssertEqual(messages[0].messageId, "message0")
            } else {
                XCTAssertEqual(messages.count, 2)
                XCTAssertEqual(messages[1].messageId, "message1")
            }
            expectation1.fulfill()
            inboxCallbackCount += 1
        }

        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            notificationCenter: mockNotificationCenter
        )
        
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message0",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": false,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "inAppMessage0",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload) {
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: testExpectationTimeout)

        let payload2 = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message0",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": false,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "inAppMessage0",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": false,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "inAppMessage1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload2) {
            expectation4.fulfill()
        }
        
        wait(for: [expectation4, expectation1, expectation2], timeout: testExpectationTimeout)
    }
    
    func testShowNowAndInboxMessage() {
        let expectation1 = expectation(description: "inbox message is displayed automatically")
        let expectation2 = expectation(description: "Unread count decrements after showing")
        let expectation3 = expectation(description: "testShowNowAndInboxMessage: wait for processing")
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShow.onSuccess { _ in
            expectation1.fulfill()
            // now click and url in the message
            mockInAppDisplayer.click(url: URL(string: "https://someurl.com")!)
        }
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = {(url, _) in
            XCTAssertEqual(url.absoluteString, "https://someurl.com")
            expectation2.fulfill()
            XCTAssertEqual(IterableAPI.inAppManager.getUnreadInboxMessagesCount(), 0)
            XCTAssertEqual(IterableAPI.inAppManager.getMessages().count, 2)
        }
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppDisplayer: mockInAppDisplayer
        )
        
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "saveToInbox": false,
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "never"},
                "messageId": "message2",
                "campaignId": "campaign2",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload) {
            expectation3.fulfill()
        }
        wait(for: [expectation3, expectation1, expectation2], timeout: testExpectationTimeout)
    }
}
