//
//  Copyright © 2021 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppPriorityTests: XCTestCase {
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
    
    // MARK: - Private
    
    private let emptyInAppContent = IterableHtmlInAppContent(edgeInsets: .zero, html: "")
    
    private func getMessageWithPriority(_ id: String = "", _ level: Double?) -> IterableInAppMessage {
        return IterableInAppMessage(messageId: id, campaignId: nil, content: emptyInAppContent, priorityLevel: level)
    }
    
    private func getEmptyMessage(_ id: String = "") -> IterableInAppMessage {
        return IterableInAppMessage(messageId: id, campaignId: nil, content: emptyInAppContent)
    }
}