//
//  Created by Tapash Majumder on 12/4/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxViewControllerViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        TestUtils.clearTestUserDefaults()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDescendingSorting() {
        let expectation1 = expectation(description: "testDescendingSorting")
        
        let model = InboxViewControllerViewModel()
        model.comparator = IterableInboxViewController.Comparator.descending
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.message(atRow: 0).iterableMessage.messageId, "message2")
            XCTAssertEqual(model.message(atRow: 1).iterableMessage.messageId, "message1")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testAscendingSorting() {
        let expectation1 = expectation(description: "testAscendingSorting")
        
        let model = InboxViewControllerViewModel()
        model.comparator = IterableInboxViewController.Comparator.ascending
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.message(atRow: 0).iterableMessage.messageId, "message1")
            XCTAssertEqual(model.message(atRow: 1).iterableMessage.messageId, "message2")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testNoSorting() {
        let expectation1 = expectation(description: "testNoSorting")
        
        let model = InboxViewControllerViewModel()
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.message(atRow: 0).iterableMessage.messageId, "message1")
            XCTAssertEqual(model.message(atRow: 1).iterableMessage.messageId, "message2")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
}
