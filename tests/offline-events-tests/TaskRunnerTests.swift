//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class TaskRunnerTests: XCTestCase {
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
    
    func testMultipleTasksInSequence() throws {
        let expectation1 = expectation(description: #function)
        expectation1.expectedFulfillmentCount = 3
        
        var scheduledTaskIds = [String]()
        var taskIds = [String]()
        let notificationCenter = MockNotificationCenter()
        notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { notification in
            let taskSendRequestValue = IterableNotificationUtil.notificationToTaskSendRequestValue(notification)!
            taskIds.append(taskSendRequestValue.taskId)
            expectation1.fulfill()
        }

        let taskRunner = IterableTaskRunner(networkSession: MockNetworkSession(),
                                            persistenceContextProvider: persistenceContextProvider,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5)
        taskRunner.start()

        scheduledTaskIds.append(try scheduleSampleTask(notificationCenter: notificationCenter))
        scheduledTaskIds.append(try scheduleSampleTask(notificationCenter: notificationCenter))
        scheduledTaskIds.append(try scheduleSampleTask(notificationCenter: notificationCenter))

        wait(for: [expectation1], timeout: 15.0)
        XCTAssertEqual(taskIds, scheduledTaskIds)

        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 0)
        taskRunner.stop()
    }

    func testFailureWithRetry() throws {
        let networkError = IterableError.general(description: "The Internet connection appears to be offline.")
        let networkSession = MockNetworkSession(statusCode: 0, data: nil, error: networkError)

        var scheduledTaskIds = [String]()
        var retryTaskIds = [String]()
        let notificationCenter = MockNotificationCenter()
        notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { notification in
            let taskSendRequestError = IterableNotificationUtil.notificationToTaskSendRequestError(notification)!
            if !retryTaskIds.contains(taskSendRequestError.taskId) {
                retryTaskIds.append(taskSendRequestError.taskId)
            }
        }

        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 1.0)
        taskRunner.start()

        scheduledTaskIds.append(try scheduleSampleTask(notificationCenter: notificationCenter))
        scheduledTaskIds.append(try scheduleSampleTask(notificationCenter: notificationCenter))
        scheduledTaskIds.append(try scheduleSampleTask(notificationCenter: notificationCenter))

        let predicate = NSPredicate { _, _ in
            return retryTaskIds.count == 1
        }
        let expectation2 = expectation(for: predicate, evaluatedWith: nil, handler: nil)
        wait(for: [expectation2], timeout: 5.0)
        XCTAssertEqual(scheduledTaskIds[0], retryTaskIds[0])
        
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 3)
        taskRunner.stop()
    }

    func testFailureWithNoRetry() throws {
        let networkSession = MockNetworkSession(statusCode: 401, data: nil, error: nil)

        let expectation1 = expectation(description: #function)
        expectation1.expectedFulfillmentCount = 3

        var scheduledTaskIds = [String]()
        var failedTaskIds = [String]()
        let notificationCenter = MockNotificationCenter()
        notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithNoRetry) { notification in
            let taskSendRequestError = IterableNotificationUtil.notificationToTaskSendRequestError(notification)!
            failedTaskIds.append(taskSendRequestError.taskId)
            expectation1.fulfill()
        }

        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5)
        taskRunner.start()

        scheduledTaskIds.append(try scheduleSampleTask(notificationCenter: notificationCenter))
        scheduledTaskIds.append(try scheduleSampleTask(notificationCenter: notificationCenter))
        scheduledTaskIds.append(try scheduleSampleTask(notificationCenter: notificationCenter))

        wait(for: [expectation1], timeout: 15.0)
        XCTAssertEqual(failedTaskIds, scheduledTaskIds)

        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 0)
        taskRunner.stop()
    }

    func testDoNotRunWhenNetworkIsOffline() throws {
        let networkSession = MockNetworkSession(statusCode: 401, data: nil, error: IterableError.general(description: "Mock error"))
        let checker = NetworkConnectivityChecker(networkSession: networkSession)
        let monitor = PollingNetworkMonitor(pollingInterval: 0.2)
        let notificationCenter = MockNotificationCenter()
        let manager = NetworkConnectivityManager(networkMonitor: monitor,
                                                 connectivityChecker: checker,
                                                 notificationCenter: notificationCenter)

        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            notificationCenter: notificationCenter,
                                            connectivityManager: manager)
        taskRunner.start()

        // Now schedule a task, giving it some time for task runner to be updated with
        // offliine network status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let _ = try! self.scheduleSampleTask(notificationCenter: notificationCenter)
        }

        verifyNoTaskIsExecuted(notificationCenter, forInterval: 1.0)

        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)
        taskRunner.stop()
    }

    func testResumeWhenNetworkIsBackOffline() throws {
        let networkSession = MockNetworkSession(statusCode: 401, json: [:], error: IterableError.general(description: "Mock error"))
        let checker = NetworkConnectivityChecker(networkSession: networkSession)
        let monitor = PollingNetworkMonitor(pollingInterval: 0.2)
        let notificationCenter = MockNotificationCenter()
        let manager = NetworkConnectivityManager(networkMonitor: monitor,
                                                 connectivityChecker: checker,
                                                 notificationCenter: notificationCenter)

        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            notificationCenter: notificationCenter,
                                            connectivityManager: manager)
        taskRunner.start()

        // Now schedule a task, giving it some time for task runner to be updated with
        // offliine network status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let _ = try! self.scheduleSampleTask(notificationCenter: notificationCenter)
        }

        verifyNoTaskIsExecuted(notificationCenter, forInterval: 1.0)
        
        // set network status back to normal
        networkSession.statusCode = 200
        networkSession.error = nil
        
        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)

        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 0)
        taskRunner.stop()
    }
    
    func testForegroundBackgroundChange() throws {
        let networkSession = MockNetworkSession()
        let checker = NetworkConnectivityChecker(networkSession: networkSession)
        let monitor = PollingNetworkMonitor(pollingInterval: 0.5)
        let notificationCenter = MockNotificationCenter()
        let manager = NetworkConnectivityManager(networkMonitor: monitor,
                                                 connectivityChecker: checker,
                                                 notificationCenter: notificationCenter)
        
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            connectivityManager: manager)
        taskRunner.start()
        
        let _ = try! self.scheduleSampleTask(notificationCenter: notificationCenter)
        verifyTaskIsExecuted(notificationCenter, withinInterval: 1.0)

        // Now move app to background
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        // Now schedule a task, giving it some time for task runner to be updated with
        // app background status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let _ = try! self.scheduleSampleTask(notificationCenter: notificationCenter)
        }

        verifyNoTaskIsExecuted(notificationCenter, forInterval: 1.0)

        // Now move app to foreground
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)
        taskRunner.stop()
    }
    
    private func scheduleSampleTask(notificationCenter: NotificationCenterProtocol) throws -> String {
        let apiKey = "zee-api-key"
        let eventName = "CustomEvent1"
        let dataFields = ["var1": "val1", "var2": "val2"]
        
        let requestCreator = RequestCreator(apiKey: apiKey, auth: auth, deviceMetadata: deviceMetadata)
        guard case let Result.success(trackEventRequest) = requestCreator.createTrackEventRequest(eventName, dataFields: dataFields) else {
            throw IterableError.general(description: "Could not create trackEvent request")
        }
        
        let apiCallRequest = IterableAPICallRequest(apiKey: apiKey,
                                                    endPoint: Endpoint.api,
                                                    auth: auth,
                                                    deviceMetadata: deviceMetadata,
                                                    iterableRequest: trackEventRequest)
        
        return try IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                         notificationCenter: notificationCenter,
                                         dateProvider: dateProvider).schedule(apiCallRequest: apiCallRequest).get()
    }

    private func verifyNoTaskIsExecuted(_ notificationCenter: MockNotificationCenter, forInterval interval: TimeInterval) {
        let expectation1 = expectation(description: "Wait for task complete notification.")
        expectation1.isInverted = true
        
        let id1 = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            XCTFail()
        }
        let id2 = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithNoRetry) { _ in
            XCTFail()
        }
        let id3 = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            XCTFail()
        }
        wait(for: [expectation1], timeout: interval)
        notificationCenter.removeCallbacks(withIds: id1, id2, id3)
    }

    private func verifyTaskIsExecuted(_ notificationCenter: MockNotificationCenter, withinInterval interval: TimeInterval) {
        let expectation1 = expectation(description: "Wait for task complete notification.")
        let id1 = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: interval)
        notificationCenter.removeCallbacks(withIds: id1)
    }

    private let deviceMetadata = DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                platform: JsonValue.iOS.jsonStringValue,
                                                appPackageName: Bundle.main.appPackageName ?? "")
    
    private lazy var persistenceContextProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider)!
        return provider
    }()

    private let dateProvider = MockDateProvider()
}

extension TaskRunnerTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: nil)
    }
}
