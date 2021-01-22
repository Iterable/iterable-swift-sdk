//
//  Copyright © 2021 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppPriorityTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
    }
    
    func testDisplayingPriorityLevelsInOrder() {
        let condition1 = expectation(description: "not able to match message priority levels")
        condition1.expectedFulfillmentCount = 4
        
        let messages = [
            getMessageWithPriority("1", Const.PriorityLevel.low),
            getMessageWithPriority("2", Const.PriorityLevel.high),
            getMessageWithPriority("3", Const.PriorityLevel.medium),
            getMessageWithPriority("4", Const.PriorityLevel.critical)
        ]
        
        var expectedDisplayOrder = messages.sorted { (message1, message2) -> Bool in
            message1.priorityLevel < message2.priorityLevel
        }
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockInAppDisplayer = MockInAppDisplayer()
        
        mockInAppDisplayer.onShow.onSuccess { [weak mockInAppDisplayer = mockInAppDisplayer] message in
            mockInAppDisplayer?.click(url: URL(string: "https://iterable.com")!)
            
            guard let nextExpectedMessage = expectedDisplayOrder.first else {
                XCTFail("could not get the next expected message")
                return
            }
            
            if message.messageId == nextExpectedMessage.messageId {
                expectedDisplayOrder.removeFirst()
                condition1.fulfill()
            }
        }
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 1.0
        
        let internalAPI = InternalIterableAPI.initializeForTesting(config: config,
                                                                   inAppFetcher: mockInAppFetcher,
                                                                   inAppDisplayer: mockInAppDisplayer)
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI,
                                                         messages: messages)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testDisplayingCriticalPriorityLevel() {
        let condition1 = expectation(description: "in-app displayer didn't show or succeed")
        
        let messageIdWithCritical = "4"
        
        let messages = [
            getMessageWithPriority("1", Const.PriorityLevel.low),
            getMessageWithPriority("2", Const.PriorityLevel.high),
            getMessageWithPriority("3", Const.PriorityLevel.medium),
            getMessageWithPriority(messageIdWithCritical, Const.PriorityLevel.critical)
        ]
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockInAppDisplayer = MockInAppDisplayer()
        
        mockInAppDisplayer.onShow.onSuccess { [weak mockInAppDisplayer = mockInAppDisplayer] message in
            mockInAppDisplayer?.click(url: URL(string: "https://iterable.com")!)
            XCTAssertEqual(message.messageId, messageIdWithCritical)
            condition1.fulfill()
        }
        
        let internalAPI = InternalIterableAPI.initializeForTesting(inAppFetcher: mockInAppFetcher,
                                                                   inAppDisplayer: mockInAppDisplayer)
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: messages)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testGetMessagesWithOutOfOrderPriorityLevels() {
        let condition1 = expectation(description: "in-app messages never fetched")
        
        let messages = [
            getMessageWithPriority("0", Const.PriorityLevel.critical), // a decoy message that will get dropped by the fetcher
            getMessageWithPriority("1", Const.PriorityLevel.critical),
            getMessageWithPriority("2", Const.PriorityLevel.low),
            getMessageWithPriority("3", Const.PriorityLevel.high),
            getMessageWithPriority("4", Const.PriorityLevel.medium)
        ]
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let internalAPI = InternalIterableAPI.initializeForTesting(inAppFetcher: mockInAppFetcher)
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: messages).onSuccess { [weak internalAPI = internalAPI] _ in
            let originalMessages = messages.dropFirst()
            if let processedMessages = internalAPI?.inAppManager.getMessages() {
                XCTAssertEqual(originalMessages.map { $0.messageId }, processedMessages.map { $0.messageId })
                
                condition1.fulfill()
            }
        }
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testMessageWithNoPriorityTreatedAsDefaultLevel() {
        let condition1 = expectation(description: "In-App Displayer didn't get called")
        
        let messageIdForNoPriority = "2"
        
        let messages = [getMessageWithPriority("1", Const.PriorityLevel.low),
                        getEmptyMessage(messageIdForNoPriority)]
        
        let mockInAppFetcher = MockInAppFetcher(messages: messages)
        let mockInAppDisplayer = MockInAppDisplayer()
        
        mockInAppDisplayer.onShow.onSuccess { message in
            XCTAssertEqual(message.messageId, messageIdForNoPriority)
            
            condition1.fulfill()
        }
        
        // Test will fail without assigning to internalAPI because InAppManager will be deallocated
        let internalAPI = InternalIterableAPI.initializeForTesting(inAppFetcher: mockInAppFetcher,
                                                                   inAppDisplayer: mockInAppDisplayer)
        XCTAssertNotNil(internalAPI)
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testInAppMessagePriorityPersistence() {
        let messages = [
            getMessageWithPriority("1", Const.PriorityLevel.critical),
            getMessageWithPriority("2", Const.PriorityLevel.low),
            getMessageWithPriority("3", Const.PriorityLevel.high),
            getMessageWithPriority("4", Const.PriorityLevel.medium)
        ]
        
        let mockInAppFetcher = MockInAppFetcher(messages: messages)
        let mockInAppPersister = MockInAppPersister()
        
        _ = InternalIterableAPI.initializeForTesting(inAppFetcher: mockInAppFetcher,
                                                     inAppPersister: mockInAppPersister)
        
        XCTAssertEqual(messages.map { $0.priorityLevel }, mockInAppPersister.getMessages().map { $0.priorityLevel })
    }
    
    // MARK: - Private
    
    private let emptyInAppContent = IterableHtmlInAppContent(edgeInsets: .zero, html: "")
    
    private func getMessageWithPriority(_ id: String = "", _ level: Double = Const.PriorityLevel.unassigned) -> IterableInAppMessage {
        return IterableInAppMessage(messageId: id, campaignId: nil, content: emptyInAppContent, priorityLevel: level)
    }
    
    private func getEmptyMessage(_ id: String = "") -> IterableInAppMessage {
        return IterableInAppMessage(messageId: id, campaignId: nil, content: emptyInAppContent)
    }
}
