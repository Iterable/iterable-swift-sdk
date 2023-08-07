//
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

final class EmbeddedManagerTests: XCTestCase {
    func testManagerSingleDelegateUpdated() {
        let condition1 = expectation(description: #function)
        
        let mockApiClient = MockApiClient()
        
        let manager = IterableEmbeddedManager(apiClient: mockApiClient)
        
        let view1 = ViewWithUpdateDelegate(
            onMessagesUpdatedCallback: {
                condition1.fulfill()
            },
            onEmbeddedMessagingDisabledCallback: nil
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
    
    private class ViewWithUpdateDelegate: UIView, IterableEmbeddedUpdateDelegate {
        init(onMessagesUpdatedCallback: (() -> Void)?, onEmbeddedMessagingDisabledCallback: (() -> Void)?) {
            super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            
            self.onMessagesUpdatedCallback = onMessagesUpdatedCallback
            self.onEmbeddedMessagingDisabledCallback = onEmbeddedMessagingDisabledCallback
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private var onMessagesUpdatedCallback: (() -> Void)?
        private var onEmbeddedMessagingDisabledCallback: (() -> Void)?
        
        func onMessagesUpdated() {
            onMessagesUpdatedCallback?()
        }
        
        func onEmbeddedMessagingDisabled() {
            onEmbeddedMessagingDisabledCallback?()
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
        
        override func getEmbeddedMessages() -> IterableSDK.Pending<IterableSDK.PlacementsPayload, IterableSDK.SendRequestError> {
            if newMessages {
                let messages = PlacementsPayload(placements: [Placement(placementId: 0, embeddedMessages: makeBlankMessagesList(with: ["1"]))])
                
                return Fulfill(value: messages)
            }
            
            return Pending()
        }
    }
}
