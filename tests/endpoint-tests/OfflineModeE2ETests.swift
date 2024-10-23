//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class OfflineModeEndpointTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
        try! persistenceContextProvider.mainQueueContext().deleteAllTasks()
        try! persistenceContextProvider.mainQueueContext().save()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func test01TrackPurchase() throws {
        let expectation1 = expectation(description: #function)
        let localStorage = MockLocalStorage()
        localStorage.offlineMode = true
        let api = InternalIterableAPI.initializeForE2E(apiKey: Self.apiKey,
                                                       localStorage: localStorage)
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
    
    func test02TrackPushOpen() throws {
        let expectation1 = expectation(description: #function)
        let localStorage = MockLocalStorage()
        localStorage.offlineMode = true
        let api = InternalIterableAPI.initializeForE2E(apiKey: Self.apiKey,
                                                       localStorage: localStorage)
        api.email = "user@example.com"
        
        api.trackPushOpen(Self.pushCampaignId,
                          templateId: Self.pushTemplateId,
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
    
    func test03TrackPushOpenWithPushPayload() throws {
        let expectation1 = expectation(description: #function)
        let localStorage = MockLocalStorage()
        localStorage.offlineMode = true
        let api = InternalIterableAPI.initializeForE2E(apiKey: Self.apiKey,
                                                       localStorage: localStorage)
        api.email = "user@example.com"
        
        let pushPayload = [
            "itbl": [
                "isGhostPush": false,
                "campaignId": Self.pushCampaignId,
                "templateId": Self.pushTemplateId,
                "messageId": "msg_1",
            ],
        ]
        api.trackPushOpen(
            pushPayload,
            dataFields: ["data_field1": "value1"],
            onSuccess: { _ in
                expectation1.fulfill()
            }
        ) { reason, _ in
            XCTFail(reason ?? "failed")
        }

        wait(for: [expectation1], timeout: 15)
    }

    func test04TrackEvent() throws {
        let expectation1 = expectation(description: #function)
        let localStorage = MockLocalStorage()
        localStorage.offlineMode = true
        let api = InternalIterableAPI.initializeForE2E(
            apiKey: Self.apiKey,
            localStorage: localStorage
        )
        api.email = "user@example.com"

        api.track(
            "event1",
            dataFields: ["data_field1": "value1"],
            onSuccess: { _ in
                expectation1.fulfill()
            }
        ) { reason, _ in
            XCTFail(reason ?? "failed")
        }

        wait(for: [expectation1], timeout: 15)
    }

    private static let apiKey = Environment.apiKey!
    private static let pushCampaignId = Environment.pushCampaignId!
    private static let pushTemplateId = Environment.pushTemplateId!
    private static let inAppCampaignId = Environment.inAppCampaignId!
    private lazy var persistenceContextProvider: IterablePersistenceContextProvider = CoreDataPersistenceContextProvider()
}
