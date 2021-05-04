//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class TaskSchedulerTests: XCTestCase {
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
    
    func testScheduleTask() throws {
        let expectation1 = expectation(description: #function)
        let apiKey = "zee-api-key"
        let eventName = "CustomEvent1"
        let dataFields = ["var1": "val1", "var2": "val2"]
        
        let notificationCenter = MockNotificationCenter()
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskScheduled) { _ in
            expectation1.fulfill()
        }
        XCTAssertNotNil(reference)
        let requestCreator = RequestCreator(apiKey: apiKey, auth: auth, deviceMetadata: deviceMetadata)
        guard case let Result.success(trackEventRequest) = requestCreator.createTrackEventRequest(eventName, dataFields: dataFields) else {
            throw IterableError.general(description: "Could not create trackEvent request")
        }
        
        let apiCallRequest = IterableAPICallRequest(apiKey: apiKey,
                                                    endPoint: Endpoint.api,
                                                    auth: auth,
                                                    deviceMetadata: deviceMetadata,
                                                    iterableRequest: trackEventRequest)
        
        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: dateProvider,
                                          networkSession: MockNetworkSession())
        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor,
                                              dateProvider: dateProvider)
        let taskId = try scheduler.schedule(apiCallRequest: apiCallRequest).get()

        wait(for: [expectation1], timeout: 10.0)
        
        let found = try persistenceContextProvider.mainQueueContext().findTask(withId: taskId)!
        XCTAssertEqual(found.id, taskId)
        XCTAssertEqual(found.name, Const.Path.trackEvent)
    }
    
    private let deviceMetadata = DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                platform: JsonValue.iOS,
                                                appPackageName: Bundle.main.appPackageName ?? "")

    private lazy var persistenceContextProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider,
                                                          fromBundle: Bundle(for: PersistentContainer.self))!
        return provider
    }()

    private let dateProvider = MockDateProvider()
}

extension TaskSchedulerTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: nil)
    }
}
