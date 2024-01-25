//
//  Copyright © 2023 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

final class EmbeddedManagerTests: XCTestCase {
    func testManagerSingleDelegateUpdated() throws {
        throw XCTSkip("skipping this test - manager logic updated, needs to be revisited")
            
            let condition1 = expectation(description: #function)
            
            let mockApiClient = MockApiClient()
            
            let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                                  urlDelegate: nil,
                                                  customActionDelegate: nil,
                                                  urlOpener: MockUrlOpener(),
                                                  allowedProtocols: [],
                                                  enableEmbeddedMessaging: true)
            
            let view1 = ViewWithUpdateDelegate(
                onMessagesUpdatedCallback: {
                    condition1.fulfill()
                },
                onEmbeddedMessagingDisabledCallback: nil
            )
            
            manager.addUpdateListener(view1)
            
            mockApiClient.haveNewEmbeddedMessages()
            manager.syncMessages {}
            
            wait(for: [condition1], timeout: 2)
    }

    // getMessages
    func testGetMessagesWhenEmpty() {
        let mockApiClient = MockApiClient()
        let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                              urlDelegate: nil,
                                              customActionDelegate: nil,
                                              urlOpener: MockUrlOpener(),
                                              allowedProtocols: [],
                                              enableEmbeddedMessaging: true)
        XCTAssertEqual(manager.getMessages().count, 0)
    }
    func testGetMessagesForPlacement() {
        let mockApiClient = MockApiClient()
        mockApiClient.populateMessages([
            1: [IterableEmbeddedMessage(messageId: "1", placementId: 1)],
            2: [IterableEmbeddedMessage(messageId: "2", placementId: 2),
            IterableEmbeddedMessage(messageId: "3", placementId: 2)],
            3: [IterableEmbeddedMessage(messageId: "4", placementId: 3)],
        ])
        let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                              urlDelegate: nil,
                                              customActionDelegate: nil,
                                              urlOpener: MockUrlOpener(),
                                              allowedProtocols: [],
                                              enableEmbeddedMessaging: true)
        
        manager.syncMessages { }
        
        let messagesForPlacement2 = manager.getMessages(for: 2)
        
        XCTAssertEqual(messagesForPlacement2.count, 2, "Should have 2 messages for placementId 2")
        for message in messagesForPlacement2 {
            XCTAssertEqual(message.metadata.placementId, 2, "Fetched message should have placementId 2")
        }
    }

    // syncMessages
    func testSyncMessagesSuccessful() {
        let syncMessagesExpectation = expectation(description: "syncMessages should complete")
        let delegateExpectation = expectation(description: "delegate should be notified")
        
        let mockApiClient = MockApiClient()
        
        mockApiClient.populateMessages([
            1: [IterableEmbeddedMessage(messageId: "1", placementId: 1),
                IterableEmbeddedMessage(messageId: "2", placementId: 1)],
        ])
        
        let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                              urlDelegate: nil,
                                              customActionDelegate: nil,
                                              urlOpener: MockUrlOpener(),
                                              allowedProtocols: [],
                                              enableEmbeddedMessaging: true)
        
        let view = ViewWithUpdateDelegate(
            onMessagesUpdatedCallback: {
                delegateExpectation.fulfill()
            },
            onEmbeddedMessagingDisabledCallback: nil
        )
        
        manager.addUpdateListener(view)
        
        manager.syncMessages {
            syncMessagesExpectation.fulfill()
        }
        
        wait(for: [syncMessagesExpectation, delegateExpectation], timeout: 2)
    }
    
    func testManagerReset() {
        let syncMessagesExpectation = expectation(description: "syncMessages should complete")
        
        let mockApiClient = MockApiClient()
        
        mockApiClient.populateMessages([
            1: [IterableEmbeddedMessage(messageId: "1", placementId: 1),
                IterableEmbeddedMessage(messageId: "2", placementId: 1)],
        ])
        
        let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                              urlDelegate: nil,
                                              customActionDelegate: nil,
                                              urlOpener: MockUrlOpener(),
                                              allowedProtocols: [],
                                              enableEmbeddedMessaging: true)
        
        manager.syncMessages {
            syncMessagesExpectation.fulfill()
        }
        
        wait(for: [syncMessagesExpectation], timeout: 2)
        
        manager.reset()
        
        XCTAssertEqual(manager.getMessages().count, 0)
    }
    
    func testSyncMessagesFailedDueToInvalidAPIKey() {
        let condition = expectation(description: "syncMessages should notify of disabled messaging due to invalid API Key")
        
        let mockApiClient = MockApiClient()
        mockApiClient.setInvalidAPIKey()
        let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                              urlDelegate: nil,
                                              customActionDelegate: nil,
                                              urlOpener: MockUrlOpener(),
                                              allowedProtocols: [],
                                              enableEmbeddedMessaging: true)
        
        let view = ViewWithUpdateDelegate(
            onMessagesUpdatedCallback: nil,
            onEmbeddedMessagingDisabledCallback: {
                condition.fulfill()
            }
        )
        
        manager.addUpdateListener(view)
        
        manager.syncMessages { }
        
        wait(for: [condition], timeout: 2)
    }

    // notify multiple delegates
    func testManagerNotifiesMultipleDelegates() {
        let mockApiClient = MockApiClient()
        let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                              urlDelegate: nil,
                                              customActionDelegate: nil,
                                              urlOpener: MockUrlOpener(),
                                              allowedProtocols: [],
                                              enableEmbeddedMessaging: true)

        var delegate1Called = false
        var delegate2Called = false

        let delegate1 = ViewWithUpdateDelegate(onMessagesUpdatedCallback: {
            delegate1Called = true
        }, onEmbeddedMessagingDisabledCallback: nil)

        let delegate2 = ViewWithUpdateDelegate(onMessagesUpdatedCallback: {
            delegate2Called = true
        }, onEmbeddedMessagingDisabledCallback: nil)

        manager.addUpdateListener(delegate1)
        manager.addUpdateListener(delegate2)

        mockApiClient.populateMessages([
            1: [IterableEmbeddedMessage(messageId: "1", placementId: 1),
            IterableEmbeddedMessage(messageId: "2", placementId: 1)]
        ])
        manager.syncMessages { }

        XCTAssertTrue(delegate1Called, "Delegate 1 should have been notified.")
        XCTAssertTrue(delegate2Called, "Delegate 2 should have been notified.")
    }

    // add and remove listeners
    func testManagerCorrectlyAddsAndRemovesListeners() {
        let mockApiClient = MockApiClient()
        let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                              urlDelegate: nil,
                                              customActionDelegate: nil,
                                              urlOpener: MockUrlOpener(),
                                              allowedProtocols: [],
                                              enableEmbeddedMessaging: true)

        var delegateCalled = false

        let delegate = ViewWithUpdateDelegate(onMessagesUpdatedCallback: {
            delegateCalled = true
        }, onEmbeddedMessagingDisabledCallback: nil)
        
        manager.addUpdateListener(delegate)

        mockApiClient.populateMessages([
            1: [IterableEmbeddedMessage(messageId: "1", placementId: 1)]
        ])
        manager.syncMessages { }
        
        XCTAssertTrue(delegateCalled, "Delegate should have been notified.")

        delegateCalled = false

        manager.removeUpdateListener(delegate)

        mockApiClient.populateMessages([
            1: [IterableEmbeddedMessage(messageId: "2", placementId: 1)]
        ])
        manager.syncMessages { }
        
        XCTAssertFalse(delegateCalled, "Delegate should not have been notified after being removed.")
    }
    
    func testUpdateMessagesIsCalled() {
        let expectation = XCTestExpectation(description: "onMessagesUpdated called")

        let notification = """
        {
            "itbl": {
                "messageId": "background_notification",
                "isGhostPush": true
            },
            "notificationType": "UpdateEmbedded",
            "messageId": "messageId"
        }
        """.toJsonDict()

        let mockApiClient = MockApiClient()
        let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                              urlDelegate: nil,
                                              customActionDelegate: nil,
                                              urlOpener: MockUrlOpener(),
                                              allowedProtocols: [],
                                              enableEmbeddedMessaging: true)

        let updateDelegate = ViewWithUpdateDelegate(
            onMessagesUpdatedCallback: {
                expectation.fulfill()
            },
            onEmbeddedMessagingDisabledCallback: nil
        )

        manager.addUpdateListener(updateDelegate)
        mockApiClient.haveNewEmbeddedMessages()

        let appIntegration = InternalIterableAppIntegration(tracker: MockPushTracker(), inAppNotifiable: EmptyInAppManager(), embeddedNotifiable: manager)

        appIntegration.application(MockApplicationStateProvider(applicationState: .background), didReceiveRemoteNotification: notification, fetchCompletionHandler: nil)

        wait(for: [expectation], timeout: 5.0)
    }

    // init/deinit
    func testManagerInitializationAndDeinitialization() {
        let deinitExpectation = expectation(description: "Manager should deinitialize")
        let mockApiClient = MockApiClient()
        var manager: IterableEmbeddedManager? = IterableEmbeddedManager(apiClient: mockApiClient,
                                                                        urlDelegate: nil,
                                                                        customActionDelegate: nil,
                                                                        urlOpener: MockUrlOpener(),
                                                                        allowedProtocols: [],
                                                                        enableEmbeddedMessaging: true)
        manager?.onDeinit = {
            deinitExpectation.fulfill()
        }
        
        XCTAssertEqual(manager?.getMessages().count, 0)
        manager = nil
        waitForExpectations(timeout: 1, handler: nil)
    }

    //didBecomeActiveNotification
    func testManagerSyncsOnForeground() {
        let expectation = XCTestExpectation(description: "onMessagesUpdated called")
        
        let mockApiClient = MockApiClient()
        let manager = IterableEmbeddedManager(apiClient: mockApiClient,
                                              urlDelegate: nil,
                                              customActionDelegate: nil,
                                              urlOpener: MockUrlOpener(),
                                              allowedProtocols: [],
                                              enableEmbeddedMessaging: true)
        
        let mockDelegate = ViewWithUpdateDelegate(
            onMessagesUpdatedCallback: {
                expectation.fulfill()
            },
            onEmbeddedMessagingDisabledCallback: nil
        )
        
        manager.addUpdateListener(mockDelegate)
        mockApiClient.populateMessages([
            1: [IterableEmbeddedMessage(messageId: "1", placementId: 1),
            IterableEmbeddedMessage(messageId: "2", placementId: 1)]
        ])
        
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        wait(for: [expectation], timeout: 5.0)
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
    
    private class MockUrlOpener: NSObject, UrlOpenerProtocol {
        func open(url: URL) {
        }
    }
    
    private class MockApiClient: BlankApiClient {
        private var newMessages = false
        private var invalidApiKey = false
        private var mockMessages: [Int: [IterableEmbeddedMessage]] = [:]

        func haveNewEmbeddedMessages() {
            newMessages = true
        }
        
        func populateMessages(_ messages: [Int: [IterableEmbeddedMessage]]) {
            self.mockMessages = messages
            self.newMessages = true
        }
        
        func setInvalidAPIKey() {
            invalidApiKey = true
        }
        
        override func getEmbeddedMessages() -> IterableSDK.Pending<IterableSDK.PlacementsPayload, IterableSDK.SendRequestError> {
            if invalidApiKey {
                return FailPending(error: IterableSDK.SendRequestError(reason: "Invalid API Key"))
            }
            
            if newMessages {
                var placements: [Placement] = []
                for (placementId, messages) in mockMessages {
                    let placement = Placement(placementId: placementId, embeddedMessages: messages)
                    placements.append(placement)
                }
                
                let payload = PlacementsPayload(placements: placements)
                return Fulfill(value: payload)
            }
            
            return Pending()
        }
    }
}
