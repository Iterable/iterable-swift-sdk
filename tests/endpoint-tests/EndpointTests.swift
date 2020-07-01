//
//  Created by Tapash Majumder on 6/29/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class EndpointTests: XCTestCase {
    func test1UpdateUser() throws {
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
    
    func test2UpdateEmail() throws {
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
    
    func test3TrackPurchase() throws {
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
    
    func test4TrackPushOpen() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.trackPushOpen(EndpointTests.campaignId,
                          templateId: EndpointTests.templateId,
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
    
    func test5TrackPushOpenWithPushPayload() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        let pushPayload = [
            "itbl": [
                "isGhostPush": false,
                "campaignId": EndpointTests.campaignId,
                "templateId": EndpointTests.templateId,
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
    
    func test6TrackEvent() throws {
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
    
    func test7UpdateSubscriptions() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.updateSubscriptions([382],
                  unsubscribedChannelIds: [7845, 1048],
                  unsubscribedMessageTypeIds: [5671, 9087],
                  subscribedMessageTypeIds: [1234],
                  campaignId: EndpointTests.campaignId,
                  templateId: EndpointTests.templateId,
                  onSuccess: { _ in
                      expectation1.fulfill()
        }) { reason, _ in
            XCTFail(reason ?? "failed")
        }
        
        wait(for: [expectation1], timeout: 15)
    }
    
    func test8DisableDeviceForCurrentUserFail() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.disableDeviceForCurrentUser(
            withOnSuccess: { _ in
                XCTFail("device should have been disabled")
        }) { reason, _ in
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 15)
    }

    func test9DisableDeviceForAllUsersFail() throws {
        let expectation1 = expectation(description: #function)
        let api = IterableAPIInternal.initializeForTesting(apiKey: EndpointTests.apiKey,
                                                           networkSession: URLSession(configuration: .default),
                                                           notificationStateProvider: MockNotificationStateProvider(enabled: true))
        api.email = "user@example.com"
        
        api.disableDeviceForAllUsers(
            withOnSuccess: { _ in
                XCTFail("device should have been disabled")
        }) { reason, _ in
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 15)
    }

    private static let campaignId = NSNumber(1_328_538)
    private static let templateId = NSNumber(1_849_323)
    
    private static var apiKey: String {
        Environment.get(key: .apiKey)!
    }
}
