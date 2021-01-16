//
//  Copyright © 2021 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppPriorityTests: XCTestCase {
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
