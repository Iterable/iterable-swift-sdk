//
//  Created by Tapash Majumder on 8/24/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class OfflineRequestProcessorTests: XCTestCase {
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

    func testTrackEvent() throws {
        let expectation1 = expectation(description: #function)
        let apiKey = "zee-api-key"
        let eventName = "CustomEvent1"
        let dataFields = ["var1": "val1", "var2": "val2"]

        let notificationCenter = MockNotificationCenter()

        let requestProcessor = OfflineRequestProcessor(apiKey: apiKey,
                                                       authProvider: self,
                                                       endPoint: Endpoint.api,
                                                       deviceMetadata: deviceMetadata,
                                                       notificationCenter: notificationCenter)
        requestProcessor.track(event: eventName,
                               dataFields: dataFields,
                               onSuccess: nil,
                               onFailure: nil)
        .onSuccess { json in
            expectation1.fulfill()
        }.onError { error in
            XCTFail()
        }
        
        let taskRunner = IterableTaskRunner(networkSession: MockNetworkSession(),
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5)
        taskRunner.start()
        wait(for: [expectation1], timeout: 15.0)
        taskRunner.stop()
    }

    func testTrackEventWithNoRetry() throws {
        let expectation1 = expectation(description: #function)
        let apiKey = "zee-api-key"
        let eventName = "CustomEvent1"
        let dataFields = ["var1": "val1", "var2": "val2"]

        let notificationCenter = MockNotificationCenter()

        let requestProcessor = OfflineRequestProcessor(apiKey: apiKey,
                                                       authProvider: self,
                                                       endPoint: Endpoint.api,
                                                       deviceMetadata: deviceMetadata,
                                                       notificationCenter: notificationCenter)
        requestProcessor.track(event: eventName,
                               dataFields: dataFields,
                               onSuccess: nil,
                               onFailure: nil)
        .onSuccess { json in
            XCTFail()
        }.onError { error in
            expectation1.fulfill()
        }
        
        let networkSession = MockNetworkSession(statusCode: 400)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5)
        taskRunner.start()
        wait(for: [expectation1], timeout: 15.0)
        taskRunner.stop()
    }

    private let deviceMetadata = DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                platform: JsonValue.iOS.jsonStringValue,
                                                appPackageName: Bundle.main.appPackageName ?? "")
    
    private let dateProvider = MockDateProvider()
    private lazy var persistenceContextProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider)
        return provider
    }()
}

extension OfflineRequestProcessorTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: nil)
    }
}
