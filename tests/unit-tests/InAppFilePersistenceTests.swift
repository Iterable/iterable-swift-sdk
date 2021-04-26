//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppFilePersistenceTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testColorAndShouldAnimatePersistence() {
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": false,
                "content": {"type": "html", "inAppDisplaySettings": {"shouldAnimate": true, "bgColor": {"hex": "#ababab", "alpha": 0.97}, "bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site1.com\'>Click Here</a>"},
                "trigger": {"type": "event", "details": "some event details"},
                "messageId": "message1",
                "campaignId": 1,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        let bgColor = (messages[0].content as? IterableHtmlInAppContent).flatMap { $0.backgroundColor }
        XCTAssertNotNil(bgColor)

        let persister = InAppFilePersister()
        persister.persist(messages)
        let obtained = persister.getMessages()
        let obtainedBgColor = (obtained[0].content as? IterableHtmlInAppContent).flatMap { $0.backgroundColor }
        XCTAssertEqual(obtainedBgColor, bgColor)
        XCTAssertEqual(messages.description, obtained.description)

        persister.clear()
    }

    func testShouldAnimateWithoutBGColorPersistence() {
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": false,
                "content": {"type": "html", "inAppDisplaySettings": {"shouldAnimate": true, "bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site1.com\'>Click Here</a>"},
                "trigger": {"type": "event", "details": "some event details"},
                "messageId": "message1",
                "campaignId": 1,
                "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
            },
        ]
        }
        """.toJsonDict()
        
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        let bgColor = (messages[0].content as? IterableHtmlInAppContent).flatMap { $0.backgroundColor }
        XCTAssertNil(bgColor)
        
        let persister = InAppFilePersister()
        persister.persist(messages)
        let obtained = persister.getMessages()
        let obtainedBgColor = (obtained[0].content as? IterableHtmlInAppContent).flatMap { $0.backgroundColor }
        XCTAssertNil(obtainedBgColor)
        XCTAssertEqual(messages.description, obtained.description)

        persister.clear()
    }

    func testFilePersistence() {
        let createdAt = Date()
        let expiresAt = createdAt.addingTimeInterval(60 * 60 * 24)
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": false,
                "content": {"type": "html", "inAppDisplaySettings": {"shouldAnimate": true, "bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site1.com\'>Click Here</a>", "payload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}},
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
        TestUtils.validateMatch(keyPath: KeyPath(string: "nested.var1"), value: "val1", inDictionary: dict, message: "Expected to find val1 in persisted dictionary")
        
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
        
        let internalApi1 = InternalIterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppPersister: InAppFilePersister()
        )
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: internalApi1, TestInAppPayloadGenerator.createPayloadWithUrl(indices: [1, 3, 2])).onSuccess { [weak internalApi1] _ in
            guard let internalApi1 = internalApi1 else {
                XCTFail("Expected internalApi to be not nil")
                return
            }
            XCTAssertEqual(internalApi1.inAppManager.getMessages().count, 3)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        
        let internalApi2 = InternalIterableAPI.initializeForTesting(
            config: config,
            inAppFetcher: mockInAppFetcher,
            inAppPersister: InAppFilePersister()
        )
        
        XCTAssertEqual(internalApi2.inAppManager.getMessages().count, 3)
    }
}

