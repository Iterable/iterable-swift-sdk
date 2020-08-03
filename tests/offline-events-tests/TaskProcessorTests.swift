//
//  Created by Tapash Majumder on 7/30/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class TaskProcessorTests: XCTestCase {
    func testAPICallForTrackEventWithPersistence() throws {
        let apiKey = "test-api-key"
        let email = "user@example.com"
        let eventName = "CustomEvent1"
        let dataFields = ["var1": "val1", "var2": "val2"]
        
        let expectation1 = expectation(description: #function)
        let auth = Auth(userId: nil, email: email, authToken: nil)
        let config = IterableConfig()
        let networkSession = MockNetworkSession()
        let internalAPI = IterableAPIInternal.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession)
        
        let requestCreator = RequestCreator(apiKey: apiKey,
                                            auth: auth,
                                            deviceMetadata: internalAPI.deviceMetadata)
        guard case let Result.success(trackEventRequest) = requestCreator.createTrackEventRequest(eventName, dataFields: dataFields) else {
            XCTFail("Could not create trackEvent request")
            return
        }
        
        let apiCallRequest = IterableAPICallRequest(apiKey: apiKey,
                                                    endPoint: config.apiEndpoint,
                                                    auth: auth,
                                                    deviceMetadata: internalAPI.deviceMetadata,
                                                    iterableRequest: trackEventRequest)
        let data = try JSONEncoder().encode(apiCallRequest)
        
        // persist data
        let taskId = IterableUtil.generateUUID()
        let taskProcessor = "APICallTaskProcessor"
        try persistenceProvider.mainQueueContext().create(task: IterableTask(id: taskId, processor: taskProcessor, data: data))
        try persistenceProvider.mainQueueContext().save()
        
        // load data
        let found = try persistenceProvider.mainQueueContext().findTask(withId: taskId)!
        
        // process data
        let processor = IterableAPICallTaskProcessor(networkSession: internalAPI.networkSession)
        try processor.process(task: found).onSuccess { _ in
            let body = networkSession.getRequestBody() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(.email), value: email, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.dataFields), value: dataFields, inDictionary: body)
            expectation1.fulfill()
        }
        
        try persistenceProvider.mainQueueContext().delete(task: found)
        try persistenceProvider.mainQueueContext().save()
        
        wait(for: [expectation1], timeout: 15.0)
    }
    
    private lazy var persistenceProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider()
        try! provider.mainQueueContext().deleteAllTasks()
        try! provider.mainQueueContext().save()
        return provider
    }()
}
