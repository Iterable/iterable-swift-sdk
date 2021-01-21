//
//  Copyright © 2021 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppPriorityTests: XCTestCase {
    func testDisplayingCriticalPriorityLevel() {
        let condition1 = expectation(description: "in-app displayer didn't show or succeed")
        
        let messageIdWithCritical = "4"
        
        let messages = [
            getMessageWithPriority("1", Const.PriorityLevel.low),
            getMessageWithPriority("2", Const.PriorityLevel.high),
            getMessageWithPriority("3", Const.PriorityLevel.medium),
            getMessageWithPriority(messageIdWithCritical, Const.PriorityLevel.critical)
        ]
        
        let config = IterableConfig()
        config.inAppDisplayInterval = 0.1
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockInAppDisplayer = MockInAppDisplayer()

        mockInAppDisplayer.onShow.onSuccess { message in
            mockInAppDisplayer.click(url: URL(string: "https://iterable.com")!)
            
            XCTAssertEqual(message.messageId, messageIdWithCritical)
            
            condition1.fulfill()
        }
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config,
                                                                   inAppFetcher: mockInAppFetcher,
                                                                   inAppDisplayer: mockInAppDisplayer)
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: messages).onSuccess { _ in
            print("jay \(internalAPI.inAppManager.getMessages().map {$0.messageId})")
        }
        
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
        
        let internalAPI = IterableAPIInternal.initializeForTesting(inAppFetcher: mockInAppFetcher)
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: messages).onSuccess { _ in
            let originalMessages = messages.dropFirst()
            let processedMessages = internalAPI.inAppManager.getMessages()
            
            XCTAssertEqual(originalMessages.map { $0.messageId }, processedMessages.map { $0.messageId })
            
            condition1.fulfill()
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
        
        _ = IterableAPIInternal.initializeForTesting(inAppFetcher: mockInAppFetcher,
                                                     inAppDisplayer: mockInAppDisplayer)
        
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
        
        _ = IterableAPIInternal.initializeForTesting(inAppFetcher: mockInAppFetcher,
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
