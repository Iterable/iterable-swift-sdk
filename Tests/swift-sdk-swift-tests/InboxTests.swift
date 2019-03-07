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

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInboxOrdering() {
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let config = IterableConfig()
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer
        )
       
        let payload = """
        {"inAppMessages":
        [
            {
                "inAppType": "default",
                "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site1.com\'>Click Here</a>", "payload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}},
                "trigger": {"type": "event", "details": "some event details"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "inAppType": "inbox",
                "content": {"contentType": "inboxHtml", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
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
                "inAppType": "inbox",
                "content": {"contentType": "inboxHtml", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message4",
                "campaignId": "campaign4",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()

        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)

        let messages = IterableAPI.inboxManager.getMessages();
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].messageId, "message2")
        XCTAssertEqual(messages[1].messageId, "message4")
    }

    func testSetRead() {
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let config = IterableConfig()
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer
        )
        
        let payload = """
        {"inAppMessages":
        [
            {
                "inAppType": "inbox",
                "content": {"contentType": "inboxHtml", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "inAppType": "inbox",
                "content": {"contentType": "inboxHtml", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message2",
                "campaignId": "campaign2",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        let messages = IterableAPI.inboxManager.getMessages();
        XCTAssertEqual(messages.count, 2)
        IterableAPI.inboxManager.set(read: true, forMessage: messages[1])
        XCTAssertEqual(messages[0].read, false)
        XCTAssertEqual(messages[1].read, true)
        
        let unreadMessages = IterableAPI.inboxManager.getUnreadMessages()
        XCTAssertEqual(IterableAPI.inboxManager.getUnreadCount(), 1)
        XCTAssertEqual(unreadMessages.count, 1)
        XCTAssertEqual(unreadMessages[0].read, false)
    }

    func testRemove() {
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let config = IterableConfig()
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer
        )
        
        let payload = """
        {"inAppMessages":
        [
            {
                "inAppType": "inbox",
                "content": {"contentType": "inboxHtml", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "inAppType": "inbox",
                "content": {"contentType": "inboxHtml", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message2",
                "campaignId": "campaign2",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        let messages = IterableAPI.inboxManager.getMessages();
        XCTAssertEqual(messages.count, 2)
        
        IterableAPI.inboxManager.remove(message: messages[0])
        let newMessages = IterableAPI.inboxManager.getMessages()
        XCTAssertEqual(newMessages.count, 1)
    }

    func testShowInboxMessage() {
        let expectation1 = expectation(description: "testShowInboxMessage")
        let expectation2 = expectation(description: "Unread count decrements after showing")
        let expectation3 = expectation(description: "Right url callback")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _) in
            expectation1.fulfill()
            // now click and url in the message
            mockInAppDisplayer.click(url: "https://someurl.com")
        }
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = {(url, _) in
            XCTAssertEqual(url.absoluteString, "https://someurl.com")
            expectation2.fulfill()
            XCTAssertEqual(IterableAPI.inboxManager.getUnreadCount(), 1)
        }
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        config.logDelegate = AllLogDelegate()
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            iterableMessageDisplayer: mockInAppDisplayer
        )

        let payload = """
        {"inAppMessages":
        [
            {
                "inAppType": "inbox",
                "content": {"contentType": "inboxHtml", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message1",
                "campaignId": "campaign1",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
            {
                "inAppType": "inbox",
                "content": {"contentType": "inboxHtml", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site2.com\'>Click Here</a>"},
                "trigger": {"type": "immediate"},
                "messageId": "message2",
                "campaignId": "campaign2",
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        XCTAssertEqual(IterableAPI.inboxManager.getUnreadCount(), 2)
        
        let messages = IterableAPI.inboxManager.getMessages()
        IterableAPI.inboxManager.show(message: messages[0]) { (clickedUrl) in
            XCTAssertEqual(clickedUrl, "https://someurl.com")
            expectation3.fulfill()
        }

        wait(for: [expectation1, expectation2, expectation3], timeout: testExpectationTimeout)
    }
}
