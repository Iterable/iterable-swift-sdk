//
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

final class EmbeddedMessagingManagerTests: XCTestCase {
    func testManagerSingleDelegateUpdated() {
        let condition1 = expectation(description: #function)
        
        let mockApiClient = MockApiClient()
        
        let manager = EmbeddedMessagingManager(autoFetchInterval: 1.0,
                                               apiClient: mockApiClient,
                                               dateProvider: MockDateProvider())
        
        manager.start()
        
        let view1 = ViewWithUpdateDelegate({
            condition1.fulfill()
        })
        
        manager.addUpdateListener(view1)
        
        mockApiClient.haveNewEmbeddedMessages()
        
        wait(for: [condition1], timeout: 2)
    }
    
    func testManagerMultipleDelegatesUpdated() {
        
    }
    
    func testManagerRemoveSingleDelegate() {
        
    }
    
    private class ViewWithUpdateDelegate: UIView, IterableEmbeddedMessagingUpdateDelegate {
        init(_ onMessagesUpdatedCallback: (() -> Void)?) {
            super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            
            self.onMessagesUpdatedCallback = onMessagesUpdatedCallback
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private var onMessagesUpdatedCallback: (() -> Void)?
        
        func onMessagesUpdated() {
            onMessagesUpdatedCallback?()
        }
    }
    
    private class MockApiClient: BlankApiClient {
        private var newMessages = false
        
        func haveNewEmbeddedMessages() {
            newMessages = true
        }
        
        private func makeBlankMessagesList(with ids: [Int]) -> [IterableEmbeddedMessage] {
            return ids.map { IterableEmbeddedMessage(id: $0) }
        }
        
        override func getEmbeddedMessages() -> IterableSDK.Pending<IterableSDK.EmbeddedMessagesPayload, IterableSDK.SendRequestError> {
            if newMessages {
                let messages = EmbeddedMessagesPayload(embeddedMessages: makeBlankMessagesList(with: [1]))
                
                return Fulfill(value: messages)
            }
            
            return Pending()
        }
    }
}
