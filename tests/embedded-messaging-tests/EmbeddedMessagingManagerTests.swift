//
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

final class EmbeddedMessagingManagerTests: XCTestCase {
    func testManagerSingleDelegateUpdated() {
        let condition1 = expectation(description: #function)
        
        let mockApiClient = MockApiClient()
        
        let manager = EmbeddedMessagingManager(apiClient: mockApiClient)
        
        let view1 = ViewWithUpdateDelegate(
            onMessagesUpdatedCallback: {
                condition1.fulfill()
            },
            onInvalidApiKeyOrSyncStopCallback: nil
        )
        
        manager.addUpdateListener(view1)
        
        mockApiClient.haveNewEmbeddedMessages()
        manager.syncMessages {
            print("syncMessages completion")
        }
        
        wait(for: [condition1], timeout: 2)
    }
    
    func testManagerMultipleDelegatesUpdated() {
        
    }
    
    func testManagerRemoveSingleDelegate() {
        
    }
    
    private class ViewWithUpdateDelegate: UIView, IterableEmbeddedMessagingUpdateDelegate {
        init(onMessagesUpdatedCallback: (() -> Void)?, onInvalidApiKeyOrSyncStopCallback: (() -> Void)?) {
            super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            
            self.onMessagesUpdatedCallback = onMessagesUpdatedCallback
            self.onInvalidApiKeyOrSyncStopCallback = onInvalidApiKeyOrSyncStopCallback
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private var onMessagesUpdatedCallback: (() -> Void)?
        private var onInvalidApiKeyOrSyncStopCallback: (() -> Void)?
        
        func onMessagesUpdated() {
            onMessagesUpdatedCallback?()
        }
        
        func onInvalidApiKeyOrSyncStop() {
            onInvalidApiKeyOrSyncStopCallback?()
        }
    }
    
    private class MockApiClient: BlankApiClient {
        private var newMessages = false
        
        func haveNewEmbeddedMessages() {
            newMessages = true
        }
        
        private func makeBlankMessagesList(with ids: [String]) -> [IterableEmbeddedMessage] {
            return ids.map { IterableEmbeddedMessage(messageId: $0) }
        }
        
        override func getEmbeddedMessages() -> IterableSDK.Pending<IterableSDK.EmbeddedMessagesPayload, IterableSDK.SendRequestError> {
            if newMessages {
                let messages = EmbeddedMessagesPayload(embeddedMessages: makeBlankMessagesList(with: ["1"]))
                
                return Fulfill(value: messages)
            }
            
            return Pending()
        }
    }
}
