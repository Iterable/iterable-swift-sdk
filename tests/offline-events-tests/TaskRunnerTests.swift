//
//  Created by Tapash Majumder on 8/18/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class TaskRunnerTests: XCTestCase {
    override func setUpWithError() throws {
        super.setUp()
        
        try persistenceContext.deleteAllTasks()
        try persistenceContext.save()

        taskExecutor = IterableTaskRunner(networkSession: MockNetworkSession())
        try taskExecutor.start()
    }
    
    override func tearDownWithError() throws {
        try taskExecutor.stop()
        Thread.sleep(forTimeInterval: 2.0)
    }
    
    func testTrackEvent() throws {
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
        let expectation1 = expectation(description: #function)
        let apiKey = "zee-api-key"
        let eventName = "CustomEvent1"
        let dataFields = ["var1": "val1", "var2": "val2"]

        let requestCreator = RequestCreator(apiKey: apiKey, auth: auth, deviceMetadata: deviceMetadata)
        guard case let Result.success(trackEventRequest) = requestCreator.createTrackEventRequest(eventName, dataFields: dataFields) else {
            XCTFail("Could not create trackEvent request")
            return
        }
        
        let apiCallRequest = IterableAPICallRequest(apiKey: apiKey,
                                                    endPoint: Endpoint.api,
                                                    auth: auth,
                                                    deviceMetadata: deviceMetadata,
                                                    iterableRequest: trackEventRequest)

        do {
            let taskId = try IterableTaskScheduler().schedule(apiCallRequest: apiCallRequest,
                                                              context: IterableTaskContext(blocking: true))
            XCTAssertNotNil(taskId)
            expectation1.fulfill()
        } catch let error {
            ITBError(error.localizedDescription)
            XCTFail(error.localizedDescription)
        }

        Thread.sleep(forTimeInterval: 5.0)
        wait(for: [expectation1], timeout: 1000.0)
    }
    
    private let deviceMetadata = DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                platform: JsonValue.iOS.jsonStringValue,
                                                appPackageName: Bundle.main.appPackageName ?? "")
    
    private lazy var persistenceContext: IterablePersistenceContext = {
        let provider = CoreDataPersistenceContextProvider()
        return provider.mainQueueContext()
    } ()
    
    private var taskExecutor: IterableTaskRunner!
}

extension TaskRunnerTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: nil)
    }
}
