//
//  Created by Tapash Majumder on 6/29/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class EndpointTests: XCTestCase {
    func test01UpdateUser() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.updateUser(["field1": "value1"],
                       mergeNestedObjects: true,
                       onSuccess: { _ in
                           expectation1.fulfill()
        }) { _, _ in
            XCTFail()
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test02UpdateEmail() throws {
        let expectation1 = expectation(description: #function)
        let expectation2 = expectation(description: "New email is deleted")
        
        let email = "user@example.com"
        let newEmail = IterableUtil.generateUUID() + "@example.com"
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = email
        
        api.updateEmail(newEmail, onSuccess: { _ in
            expectation1.fulfill()
            IterableAPISupport.sendDeleteUserRequest(email: newEmail).onSuccess { _ in
                expectation2.fulfill()
            }
        }) { _, _ in
            XCTFail()
        }
        wait(for: [expectation1, expectation2], timeout: 15)
    }
    
    func test03TrackPurchase() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        let items = [
            CommerceItem(id: "1", name: "Item1", price: 20.23, quantity: 1),
            CommerceItem(id: "2", name: "Item2", price: 100.54, quantity: 1),
        ]
        api.trackPurchase(120.77,
                          items: items,
                          onSuccess: { _ in
                              expectation1.fulfill()
        }) { _, _ in
            XCTFail()
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test04TrackPushOpen() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.trackPushOpen(EndpointTests.pushCampaignId,
                          templateId: EndpointTests.pushTemplateId,
                          messageId: "msg_1",
                          appAlreadyRunning: true,
                          dataFields: ["data_field1": "value1"],
                          onSuccess: { _ in
                              expectation1.fulfill()
        }) { reason, _ in
            XCTFail(reason ?? "failed")
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test05TrackPushOpenWithPushPayload() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        let pushPayload = [
            "itbl": [
                "isGhostPush": false,
                "campaignId": EndpointTests.pushCampaignId,
                "templateId": EndpointTests.pushTemplateId,
                "messageId": "msg_1",
            ],
        ]
        api.trackPushOpen(pushPayload,
                          dataFields: ["data_field1": "value1"],
                          onSuccess: { _ in
                              expectation1.fulfill()
        }) { reason, _ in
            XCTFail(reason ?? "failed")
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test06TrackEvent() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.track("event1",
                  dataFields: ["data_field1": "value1"],
                  onSuccess: { _ in
                      expectation1.fulfill()
        }) { reason, _ in
            XCTFail(reason ?? "failed")
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test07UpdateSubscriptions() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.updateSubscriptions([382],
                                unsubscribedChannelIds: [7845, 1048],
                                unsubscribedMessageTypeIds: [5671, 9087],
                                subscribedMessageTypeIds: [1234],
                                campaignId: EndpointTests.pushCampaignId,
                                templateId: EndpointTests.pushTemplateId,
                                onSuccess: { _ in
                                    expectation1.fulfill()
        }) { reason, _ in
            XCTFail(reason ?? "failed")
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test08DisableDeviceForCurrentUserFail() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.disableDeviceForCurrentUser(
            withOnSuccess: { _ in
                XCTFail("device should have been disabled")
        }) { _, _ in
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test09DisableDeviceForAllUsersFail() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.disableDeviceForAllUsers(
            withOnSuccess: { _ in
                XCTFail("device should have been disabled")
        }) { _, _ in
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test10GetInAppMessages() throws {
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        let api = IterableAPIInternal.initializeForE2E(apiKey: EndpointTests.apiKey, config: config)
        let email = "user@example.com"
        api.email = email
        
        ensureInAppMessages(api: api, email: email)
        
        clearAllInAppMessages(api: api)
    }
    
    func test11InAppConsume() throws {
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        let api = IterableAPIInternal.initializeForE2E(apiKey: EndpointTests.apiKey, config: config)
        let email = "user@example.com"
        api.email = email
        
        ensureInAppMessages(api: api, email: email)
        
        api.inAppManager.scheduleSync().wait()
        let initialCount = api.inAppManager.getMessages().count
        XCTAssert(initialCount > 0)
        
        api.inAppConsume(message: api.inAppManager.getMessages()[0])
        let predicate = NSPredicate { (_, _) -> Bool in
            api.inAppManager.scheduleSync().wait()
            return api.inAppManager.getMessages().count == initialCount - 1
        }
        let expectation1 = expectation(for: predicate, evaluatedWith: nil, handler: nil)
        wait(for: [expectation1], timeout: 60)
        
        clearAllInAppMessages(api: api)
    }
    
    func test12TrackInAppOpen() throws {
        verifyTrackInAppRequest(expectation: expectation(description: #function)) { api, message in
            api.trackInAppOpen(message, location: .inApp)
        }
    }
    
    func test13TrackInAppClick() throws {
        verifyTrackInAppRequest(expectation: expectation(description: #function)) { api, message in
            api.trackInAppClick(message, location: .inApp, inboxSessionId: nil, clickedUrl: "https://www.google.com")
        }
    }
    
    func test14TrackInAppClose() throws {
        verifyTrackInAppRequest(expectation: expectation(description: #function)) { api, message in
            api.trackInAppClose(message, location: .inApp, inboxSessionId: nil, source: .none, clickedUrl: "https://www.google.com")
        }
    }
    
    func test15TrackInboxSession() throws {
        let expectation1 = expectation(description: #function)
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        let api = IterableAPIInternal.initializeForE2E(apiKey: EndpointTests.apiKey, config: config)
        let email = "user@example.com"
        api.email = email
        
        ensureInAppMessages(api: api, email: email)
        
        api.inAppManager.scheduleSync().wait()
        let count = api.inAppManager.getMessages().count
        XCTAssert(count > 0)
        
        let message = api.inAppManager.getMessages()[0]
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(10.0)
        
        let impression = IterableInboxImpression(messageId: message.messageId,
                                                 silentInbox: false,
                                                 displayCount: 1,
                                                 displayDuration: 10.0)
        let inboxSession = IterableInboxSession(id: IterableUtil.generateUUID(),
                                                sessionStartTime: startTime,
                                                sessionEndTime: endTime,
                                                startTotalMessageCount: 0,
                                                startUnreadMessageCount: 0,
                                                endTotalMessageCount: 1,
                                                endUnreadMessageCount: 1,
                                                impressions: [impression])
        
        api.track(inboxSession: inboxSession)
            .onSuccess { _ in
                expectation1.fulfill()
            }.onError { error in
                XCTFail(error.localizedDescription)
            }
        
        wait(for: [expectation1], timeout: 15)
        
        clearAllInAppMessages(api: api)
    }
    
    private func verifyTrackInAppRequest(expectation: XCTestExpectation, method: (IterableAPIInternal, IterableInAppMessage) -> Future<SendRequestValue, SendRequestError>) {
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        let api = IterableAPIInternal.initializeForE2E(apiKey: EndpointTests.apiKey, config: config)
        let email = "user@example.com"
        api.email = email
        
        ensureInAppMessages(api: api, email: email)
        
        api.inAppManager.scheduleSync().wait()
        let count = api.inAppManager.getMessages().count
        XCTAssert(count > 0)
        
        method(api, api.inAppManager.getMessages()[0])
            .onSuccess { _ in
                expectation.fulfill()
            }
            .onError {
                XCTFail($0.localizedDescription)
            }
        
        wait(for: [expectation], timeout: 15)
        
        clearAllInAppMessages(api: api)
    }
    
    private static let apiKey = Environment.apiKey!
    private static let pushCampaignId = Environment.pushCampaignId!
    private static let pushTemplateId = Environment.pushTemplateId!
    private static let inAppCampaignId = Environment.inAppCampaignId!
    private static let inAppTemplateId = Environment.inAppTemplateId!
    
    fileprivate func ensureInAppMessages(api: IterableAPIInternal, email: String) {
        IterableAPISupport.sendInApp(to: email, withCampaignId: EndpointTests.inAppCampaignId.intValue).wait()
        
        let predicate = NSPredicate { (_, _) -> Bool in
            api.inAppManager.scheduleSync().wait()
            return api.inAppManager.getMessages().count > 0
        }
        
        let expectation1 = expectation(for: predicate, evaluatedWith: nil, handler: nil)
        wait(for: [expectation1], timeout: 60)
    }
    
    private func clearAllInAppMessages(api: IterableAPIInternal) {
        api.apiClient.getInAppMessages(100).flatMap {
            self.chainCallConsume(json: $0, apiClient: api.apiClient)
        }.wait()
        
        let predicate = NSPredicate { (_, _) -> Bool in
            var inAppMessages = [IterableInAppMessage]()
            api.apiClient.getInAppMessages(100).map { json -> [IterableInAppMessage] in
                InAppTestHelper.inAppMessages(fromPayload: json)
            }.onSuccess { messages in
                inAppMessages = messages
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.wait()
            
            return inAppMessages.count == 0
        }
        let expectation1 = expectation(for: predicate, evaluatedWith: nil, handler: nil)
        wait(for: [expectation1], timeout: 100) // wait a while for all in-apps to be deleted
    }
    
    private func chainCallConsume(json: SendRequestValue, apiClient: ApiClientProtocol) -> Future<SendRequestValue, SendRequestError> {
        let messages = InAppTestHelper.inAppMessages(fromPayload: json)
        
        guard messages.count > 0 else {
            return Promise<SendRequestValue, SendRequestError>(value: [:])
        }
        
        let result = Promise<SendRequestValue, SendRequestError>(value: [:])
        
        return messages.reduce(result) { (partialResult, message) -> Future<SendRequestValue, SendRequestError> in
            partialResult.flatMap { _ in
                apiClient.inAppConsume(messageId: message.messageId)
            }
        }
    }
}
