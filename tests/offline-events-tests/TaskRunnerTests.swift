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
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { notification in
            let taskSendRequestValue = IterableNotificationUtil.notificationToTaskSendRequestValue(notification)!
            taskIds.append(taskSendRequestValue.taskId)
            expectation1.fulfill()
        }
        XCTAssertNotNil(reference)
        let networkSession = MockNetworkSession()
        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5)
        taskRunner.start()
        
        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        
        try scheduleSampleTasks(scheduler: scheduler, times: 3, scheduledTaskIds: []).onSuccess(block: { values in
            scheduledTaskIds = values
        })
        
        wait(for: [expectation1], timeout: 15.0)
        XCTAssertEqual(taskIds, scheduledTaskIds)
        
        waitForZeroTasks()
        
        taskRunner.stop()
    }
    
    func testFailureWithRetry() throws {
        let networkError = IterableError.general(description: "The Internet connection appears to be offline.")
        let networkSession = MockNetworkSession(statusCode: 0, data: nil, error: networkError)

        var scheduledTaskIds = [String]()
        var retryTaskIds = [String]()
        let notificationCenter = MockNotificationCenter()
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { notification in
            let taskSendRequestError = IterableNotificationUtil.notificationToTaskSendRequestError(notification)!
            if !retryTaskIds.contains(taskSendRequestError.taskId) {
                retryTaskIds.append(taskSendRequestError.taskId)
            }
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 1.0)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        try scheduleSampleTasks(scheduler: scheduler, times: 3, scheduledTaskIds: []).onSuccess(block: { values in
            scheduledTaskIds = values
        })

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
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithNoRetry) { notification in
            let taskSendRequestError = IterableNotificationUtil.notificationToTaskSendRequestError(notification)!
            failedTaskIds.append(taskSendRequestError.taskId)
            expectation1.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        try scheduleSampleTasks(scheduler: scheduler, times: 3, scheduledTaskIds: []).onSuccess(block: { values in
            scheduledTaskIds = values
        })

        wait(for: [expectation1], timeout: 15.0)
        XCTAssertEqual(failedTaskIds, scheduledTaskIds)

        waitForZeroTasks()
        
        taskRunner.stop()
    }

    func testDoNotRunWhenNetworkIsOffline() throws {
        let networkSession = MockNetworkSession(statusCode: 401, data: nil, error: IterableError.general(description: "Mock error"))
        let checker = NetworkConnectivityChecker(networkSession: networkSession)
        let monitor = NetworkMonitor()
        let notificationCenter = MockNotificationCenter()
        let manager = NetworkConnectivityManager(networkMonitor: monitor,
                                                 connectivityChecker: checker,
                                                 notificationCenter: notificationCenter)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            connectivityManager: manager)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        // Now schedule a task, giving it some time for task runner to be updated with
        // offliine network status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let _ = try! self.scheduleSampleTask(scheduler: scheduler)
        }

        verifyNoTaskIsExecuted(notificationCenter, forInterval: 1.0)

        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)
        taskRunner.stop()
    }

    func testResumeWhenNetworkIsBackOnline() throws {
        let networkSession = MockNetworkSession(statusCode: 401, json: [:], error: IterableError.general(description: "Mock error"))
        let checker = NetworkConnectivityChecker(networkSession: networkSession)
        let monitor = MockNetworkMonitor()
        monitor.start()
        let notificationCenter = MockNotificationCenter()
        let manager = NetworkConnectivityManager(networkMonitor: monitor,
                                                 connectivityChecker: checker,
                                                 notificationCenter: notificationCenter,
                                                 offlineModePollingInterval: 0.5,
                                                 onlineModePollingInterval: 0.5)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            connectivityManager: manager)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)

        // Now schedule a task, giving it some time for task runner to be updated with
        // offliine network status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let _ = try! self.scheduleSampleTask(scheduler: scheduler)
        }

        verifyNoTaskIsExecuted(notificationCenter, forInterval: 1.0)
        
        // set network status back to normal
        networkSession.responseCallback = nil
        monitor.forceStatusUpdate() // Force immediate network status check
        
        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)

        waitForZeroTasks()

        taskRunner.stop()
    }
    
    func testForegroundBackgroundChange() throws {
        let networkSession = MockNetworkSession()
        let checker = NetworkConnectivityChecker(networkSession: networkSession)
        let monitor = NetworkMonitor()
        let notificationCenter = MockNotificationCenter()
        let manager = NetworkConnectivityManager(networkMonitor: monitor,
                                                 connectivityChecker: checker,
                                                 notificationCenter: notificationCenter)
        
        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            connectivityManager: manager)
        taskRunner.start()
        
        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)

        let _ = try! self.scheduleSampleTask(scheduler: scheduler)
        verifyTaskIsExecuted(notificationCenter, withinInterval: 1.0)

        // Now move app to background
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        // Now schedule a task, giving it some time for task runner to be updated with
        // app background status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let _ = try! self.scheduleSampleTask(scheduler: scheduler)
        }

        verifyNoTaskIsExecuted(notificationCenter, forInterval: 1.0)

        // Now move app to foreground
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)
        taskRunner.stop()
    }
    
    func testSentAtInHeader() throws {
        let date = Date()
        let sentAtTime = "\(Int(date.timeIntervalSince1970))"
        let dateProvider = MockDateProvider()
        dateProvider.currentDate = date
        let expectation1 = expectation(description: #function)
        let networkSession = MockNetworkSession()
        networkSession.requestCallback = { request in
            if request.allHTTPHeaderFields!.contains(where: { $0.key == "Sent-At" && $0.value == sentAtTime }) {
                expectation1.fulfill()
            }
        }
        let notificationCenter = MockNotificationCenter()
        
        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: dateProvider,
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                           persistenceContextProvider: persistenceContextProvider,
                           healthMonitor: healthMonitor,
                           notificationCenter: notificationCenter,
                           timeInterval: 0.5,
                           dateProvider: dateProvider)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try! self.scheduleSampleTask(scheduler: scheduler)
        verifyTaskIsExecuted(notificationCenter, withinInterval: 1.0)

        taskRunner.stop()
        wait(for: [expectation1], timeout: 5.0)
    }
    
    // MARK: - Auto Retry / 401 JWT Tests

    func testRetainTaskOn401WhenAutoRetryEnabled() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        wait(for: [retryExpectation], timeout: 5.0)

        // Task should be retained in the DB (not deleted)
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        taskRunner.stop()
    }

    func testDeleteTaskOn401WhenAutoRetryDisabled() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let noRetryExpectation = expectation(description: "no retry notification received")

        let notificationCenter = MockNotificationCenter()
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithNoRetry) { _ in
            noRetryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: false)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        wait(for: [noRetryExpectation], timeout: 5.0)

        // Task should be deleted (legacy behavior)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testResumeAfterAuthTokenRefreshed() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Wait for the 401 to be processed and runner to pause
        wait(for: [retryExpectation], timeout: 5.0)
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        // Now fix the network to return success
        networkSession.responseCallback = nil

        // Post auth token refreshed notification to resume the runner
        notificationCenter.post(name: .iterableAuthTokenRefreshed, object: nil, userInfo: nil)

        // Verify the task is now processed successfully
        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testRetainMultipleTasksOn401AndResumeAfterAuthRefresh() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)

        // Schedule 3 tasks before starting the runner so all are in DB
        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        try scheduleSampleTasks(scheduler: scheduler, times: 3, scheduledTaskIds: [])

        // Wait for all 3 tasks to be persisted
        let scheduledPredicate = NSPredicate { _, _ in
            (try? self.persistenceContextProvider.mainQueueContext().findAllTasks().count) == 3
        }
        let scheduledExpectation = expectation(for: scheduledPredicate, evaluatedWith: nil)
        wait(for: [scheduledExpectation], timeout: 5.0)

        let retryExpectation = expectation(description: "retry notification received")
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        // Wait for the first 401 to pause the runner
        wait(for: [retryExpectation], timeout: 5.0)

        // All 3 tasks should still be retained in DB
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 3)

        // Remove the retry callback before resuming
        notificationCenter.removeCallbacks(withIds: reference.callbackId)

        // Fix network and resume via auth token refresh
        networkSession.responseCallback = nil
        notificationCenter.post(name: .iterableAuthTokenRefreshed, object: nil, userInfo: nil)

        // All 3 tasks should now process successfully
        let successExpectation = expectation(description: "all tasks processed")
        successExpectation.expectedFulfillmentCount = 3
        let successRef = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            successExpectation.fulfill()
        }
        XCTAssertNotNil(successRef)

        wait(for: [successExpectation], timeout: 15.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testRetainTaskOn401WithBadAuthorizationHeader() throws {
        let jwtErrorData = ["code": "BadAuthorizationHeader"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        wait(for: [retryExpectation], timeout: 5.0)

        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        taskRunner.stop()
    }

    func testRetainTaskOn401WithJwtUserIdentifiersMismatched() throws {
        let jwtErrorData = ["code": "JwtUserIdentifiersMismatched"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        wait(for: [retryExpectation], timeout: 5.0)

        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        taskRunner.stop()
    }

    func test401WithNonJwtCodeDeletesTaskEvenWithAutoRetry() throws {
        let badApiKeyData = ["code": "BadApiKey"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: badApiKeyData)

        let notificationCenter = MockNotificationCenter()
        let noRetryExpectation = expectation(description: "no retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithNoRetry) { _ in
            noRetryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        wait(for: [noRetryExpectation], timeout: 5.0)

        // Task should be deleted - BadApiKey is not a JWT error
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testRetainTaskOn5xxWithAutoRetry() throws {
        let networkSession = MockNetworkSession(statusCode: 500, json: [:])

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        wait(for: [retryExpectation], timeout: 15.0)

        // Task should be retained - 5xx is a transient server error
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        taskRunner.stop()
    }

    // MARK: - SDK-349 Serial Execution & Deletion Semantics Tests

    func testRetainTaskOn5xxAndProcessAfterRecovery() throws {
        let networkSession = MockNetworkSession(statusCode: 500, json: [:])

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Wait for the 500 to trigger retry
        wait(for: [retryExpectation], timeout: 15.0)
        notificationCenter.removeCallbacks(withIds: reference.callbackId)

        // Task should be retained
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        // Fix the server — next retry should succeed
        networkSession.responseCallback = nil

        // Wait for the task to succeed on next cycle
        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testDeleteTaskOn4xxClientError() throws {
        let networkSession = MockNetworkSession(statusCode: 400, json: [:])

        let notificationCenter = MockNotificationCenter()
        let noRetryExpectation = expectation(description: "no retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithNoRetry) { _ in
            noRetryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        wait(for: [noRetryExpectation], timeout: 15.0)

        // 400 is a permanent client error — task should be deleted
        waitForZeroTasks()

        taskRunner.stop()
    }

    // MARK: - SDK-343 Auth Wait Strategy Tests

    func testNewTaskScheduledDuringAuthPauseNotProcessedUntilResume() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Wait for the 401 to pause the runner
        wait(for: [retryExpectation], timeout: 5.0)
        notificationCenter.removeCallbacks(withIds: reference.callbackId)

        // Now schedule a NEW task while auth is paused
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Verify the new task is NOT processed while auth is paused
        verifyNoTaskIsExecuted(notificationCenter, forInterval: 2.0)

        // Both tasks should be retained in DB
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 2)

        // Now fix network and resume via auth token refresh
        networkSession.responseCallback = nil
        notificationCenter.post(name: .iterableAuthTokenRefreshed, object: nil, userInfo: nil)

        // Both tasks should now process successfully
        let successExpectation = expectation(description: "both tasks processed")
        successExpectation.expectedFulfillmentCount = 2
        let successRef = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            successExpectation.fulfill()
        }
        XCTAssertNotNil(successRef)

        wait(for: [successExpectation], timeout: 15.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testMultipleTasksScheduledDuringAuthPauseAllProcessAfterResume() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)

        // Schedule first task to trigger auth pause
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Wait for the 401 to pause the runner
        wait(for: [retryExpectation], timeout: 5.0)
        notificationCenter.removeCallbacks(withIds: reference.callbackId)

        // Schedule 3 more tasks while auth is paused
        try scheduleSampleTasks(scheduler: scheduler, times: 3, scheduledTaskIds: [])

        // Wait for all new tasks to be persisted
        let scheduledPredicate = NSPredicate { _, _ in
            (try? self.persistenceContextProvider.mainQueueContext().findAllTasks().count) == 4
        }
        let scheduledExpectation = expectation(for: scheduledPredicate, evaluatedWith: nil)
        wait(for: [scheduledExpectation], timeout: 5.0)

        // Verify no tasks are processed while auth is paused
        verifyNoTaskIsExecuted(notificationCenter, forInterval: 2.0)

        // All 4 tasks should still be in DB
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 4)

        // Fix network and resume via single auth token refresh
        networkSession.responseCallback = nil
        notificationCenter.post(name: .iterableAuthTokenRefreshed, object: nil, userInfo: nil)

        // All 4 tasks should process successfully
        let successExpectation = expectation(description: "all tasks processed")
        successExpectation.expectedFulfillmentCount = 4
        let successRef = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            successExpectation.fulfill()
        }
        XCTAssertNotNil(successRef)

        wait(for: [successExpectation], timeout: 15.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    // MARK: - SDK-345 Unauthenticated API Bypass Tests

    func testUnauthenticatedTaskExecutesDuringAuthPause() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)

        // Schedule an auth-required task to trigger auth pause
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Wait for the 401 to pause the runner
        wait(for: [retryExpectation], timeout: 5.0)
        notificationCenter.removeCallbacks(withIds: reference.callbackId)

        // Now fix network to return success and schedule an unauthenticated task
        networkSession.responseCallback = nil
        let _ = try scheduleUnauthenticatedTask(scheduler: scheduler)

        // The unauthenticated task should execute even though auth is paused
        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)

        // Auth-required task still in DB (1 remaining), unauthenticated task was processed
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        taskRunner.stop()
    }

    func testAuthRequiredTaskStaysBlockedWhileUnauthenticatedExecutes() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        let retryExpectation = expectation(description: "retry notification received")

        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)

        // Schedule auth-required task to trigger auth pause
        let _ = try scheduleSampleTask(scheduler: scheduler)

        wait(for: [retryExpectation], timeout: 5.0)
        notificationCenter.removeCallbacks(withIds: reference.callbackId)

        // Fix network and schedule another auth-required task
        networkSession.responseCallback = nil
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // The second auth-required task should NOT execute while auth is paused
        verifyNoTaskIsExecuted(notificationCenter, forInterval: 2.0)

        // Both auth-required tasks should still be in DB
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 2)

        // Now refresh auth — both should process
        notificationCenter.post(name: .iterableAuthTokenRefreshed, object: nil, userInfo: nil)

        let successExpectation = expectation(description: "both tasks processed")
        successExpectation.expectedFulfillmentCount = 2
        let successRef = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            successExpectation.fulfill()
        }
        XCTAssertNotNil(successRef)

        wait(for: [successExpectation], timeout: 15.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testMixedQueueOnlyUnauthenticatedExecuteDuringAuthPause() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)

        // Schedule tasks BEFORE starting runner: 1 auth-required, then 2 unauthenticated
        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)
        let _ = try scheduleUnauthenticatedTask(scheduler: scheduler)
        let _ = try scheduleUnauthenticatedTask(scheduler: scheduler)

        // Wait for all 3 tasks to persist
        let scheduledPredicate = NSPredicate { _, _ in
            (try? self.persistenceContextProvider.mainQueueContext().findAllTasks().count) == 3
        }
        let scheduledExpectation = expectation(for: scheduledPredicate, evaluatedWith: nil)
        wait(for: [scheduledExpectation], timeout: 5.0)

        let retryExpectation = expectation(description: "retry notification received")
        let retryRef = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(retryRef)

        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        // Wait for the auth-required task to fail and pause the runner
        wait(for: [retryExpectation], timeout: 5.0)
        notificationCenter.removeCallbacks(withIds: retryRef.callbackId)

        // Fix network so unauthenticated tasks succeed
        networkSession.responseCallback = nil

        // Wait for the 2 unauthenticated tasks to be processed
        let unauthSuccessExpectation = expectation(description: "unauthenticated tasks processed")
        unauthSuccessExpectation.expectedFulfillmentCount = 2
        let successRef = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            unauthSuccessExpectation.fulfill()
        }
        XCTAssertNotNil(successRef)

        wait(for: [unauthSuccessExpectation], timeout: 10.0)
        notificationCenter.removeCallbacks(withIds: successRef.callbackId)

        // Only the auth-required task should remain
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        // Now refresh auth — the remaining auth task should process
        notificationCenter.post(name: .iterableAuthTokenRefreshed, object: nil, userInfo: nil)
        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testAuthTokenRefreshWithNoPendingTasksIsNoOp() throws {
        let networkSession = MockNetworkSession()

        let notificationCenter = MockNotificationCenter()

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            autoRetry: true)
        taskRunner.start()

        // Post auth refresh with no tasks in DB - should not crash or trigger anything
        notificationCenter.post(name: .iterableAuthTokenRefreshed, object: nil, userInfo: nil)

        // Give it a moment to process
        let noOpExpectation = expectation(description: "wait for potential processing")
        noOpExpectation.isInverted = true
        wait(for: [noOpExpectation], timeout: 1.0)

        // DB should still be empty
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 0)

        taskRunner.stop()
    }

    // MARK: - SDK-347 Unpause Processing Tests

    /// Creates a NetworkConnectivityManager suitable for testing, using the given
    /// notification center to simulate online/offline transitions.
    private func makeTestConnectivityManager(notificationCenter: MockNotificationCenter) -> NetworkConnectivityManager {
        let mockMonitor = MockNetworkMonitor()
        let mockChecker = NetworkConnectivityChecker(networkSession: MockNetworkSession())
        return NetworkConnectivityManager(
            networkMonitor: mockMonitor,
            connectivityChecker: mockChecker,
            notificationCenter: notificationCenter,
            offlineModePollingInterval: 600,
            onlineModePollingInterval: 600
        )
    }

    func testAuthRefreshDuringNetworkOutageDefersResume() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        // Separate notification center for connectivity to control it independently
        let connectivityNC = MockNotificationCenter()
        let connectivityManager = makeTestConnectivityManager(notificationCenter: connectivityNC)

        let retryExpectation = expectation(description: "retry notification received")
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            connectivityManager: connectivityManager,
                                            autoRetry: true,
                                            connectivityDebounceInterval: 0.5)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Wait for the 401 to trigger auth pause
        wait(for: [retryExpectation], timeout: 5.0)
        notificationCenter.removeCallbacks(withIds: reference.callbackId)

        // Simulate network going offline
        connectivityNC.post(name: .iterableNetworkOffline, object: nil, userInfo: nil)

        // Allow state transition to settle
        let settleExpectation = expectation(description: "settle")
        settleExpectation.isInverted = true
        wait(for: [settleExpectation], timeout: 1.0)

        // Fix the mock network but post auth refresh while "offline"
        networkSession.responseCallback = nil
        notificationCenter.post(name: .iterableAuthTokenRefreshed, object: nil, userInfo: nil)

        // Task should NOT process — network is still down
        verifyNoTaskIsExecuted(notificationCenter, forInterval: 2.0)

        // Task still in DB
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        // Bring network back online — task should now resume after debounce
        connectivityNC.post(name: .iterableNetworkOnline, object: nil, userInfo: nil)

        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testConnectivityFlapDoesNotCauseRapidProcessing() throws {
        let networkSession = MockNetworkSession()
        let notificationCenter = MockNotificationCenter()
        let connectivityNC = MockNotificationCenter()
        let connectivityManager = makeTestConnectivityManager(notificationCenter: connectivityNC)

        var processCount = 0
        let countExpectation = expectation(description: "track processing")
        countExpectation.isInverted = true

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            connectivityManager: connectivityManager,
                                            autoRetry: true,
                                            connectivityDebounceInterval: 2.0)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Wait for the initial task to process
        verifyTaskIsExecuted(notificationCenter, withinInterval: 5.0)
        waitForZeroTasks()

        // Now simulate rapid network flapping: offline → online → offline → online
        let successRef = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            processCount += 1
        }

        // Go offline BEFORE scheduling the task so that onTaskScheduled sees paused=true
        // and the task stays queued for the flap test
        connectivityNC.post(name: .iterableNetworkOffline, object: nil, userInfo: nil)

        // Wait for offline to take effect on persistence context queue
        let offlineDelay0 = expectation(description: "offline settle")
        offlineDelay0.isInverted = true
        wait(for: [offlineDelay0], timeout: 0.5)

        // Schedule task while offline — it stays in the queue
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Rapid flap: come back online briefly then go offline again
        let flapDelay = expectation(description: "flap delay")
        flapDelay.isInverted = true
        wait(for: [flapDelay], timeout: 0.3)
        connectivityNC.post(name: .iterableNetworkOnline, object: nil, userInfo: nil)

        let flapDelay2 = expectation(description: "flap delay 2")
        flapDelay2.isInverted = true
        wait(for: [flapDelay2], timeout: 0.3)
        connectivityNC.post(name: .iterableNetworkOffline, object: nil, userInfo: nil)

        // The debounce (2.0s) should have prevented processing during the brief online window
        wait(for: [countExpectation], timeout: 2.0)
        XCTAssertEqual(processCount, 0, "Task should not have been processed during brief online flap")

        // Task should still be in DB since debounced reconnect was cancelled by disconnect
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        notificationCenter.removeCallbacks(withIds: successRef.callbackId)

        // Now actually come back online for real
        connectivityNC.post(name: .iterableNetworkOnline, object: nil, userInfo: nil)

        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testResumeOnlyWhenBothAuthAndNetworkReady() throws {
        let jwtErrorData = ["code": "InvalidJwtPayload"].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let notificationCenter = MockNotificationCenter()
        let connectivityNC = MockNotificationCenter()
        let connectivityManager = makeTestConnectivityManager(notificationCenter: connectivityNC)

        let retryExpectation = expectation(description: "retry notification received")
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            retryExpectation.fulfill()
        }
        XCTAssertNotNil(reference)

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: SystemDateProvider(),
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            connectivityManager: connectivityManager,
                                            autoRetry: true,
                                            connectivityDebounceInterval: 0.5)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try scheduleSampleTask(scheduler: scheduler)

        // Wait for 401 to pause
        wait(for: [retryExpectation], timeout: 5.0)
        notificationCenter.removeCallbacks(withIds: reference.callbackId)

        // Both auth AND network are now problematic:
        // authPaused = true (from 401), and network goes offline
        connectivityNC.post(name: .iterableNetworkOffline, object: nil, userInfo: nil)

        let settleExpectation = expectation(description: "settle")
        settleExpectation.isInverted = true
        wait(for: [settleExpectation], timeout: 1.0)

        // Fix network response
        networkSession.responseCallback = nil

        // Step 1: Network comes back, but auth is still paused → should NOT process auth-required task
        connectivityNC.post(name: .iterableNetworkOnline, object: nil, userInfo: nil)
        verifyNoTaskIsExecuted(notificationCenter, forInterval: 3.0)
        XCTAssertEqual(try persistenceContextProvider.mainQueueContext().findAllTasks().count, 1)

        // Step 2: Auth refreshes → NOW both conditions are met → task should process
        notificationCenter.post(name: .iterableAuthTokenRefreshed, object: nil, userInfo: nil)

        verifyTaskIsExecuted(notificationCenter, withinInterval: 10.0)
        waitForZeroTasks()

        taskRunner.stop()
    }

    func testCreatedAtInBody() throws {
        let date = Date()
        let createdAtTime = Int(date.timeIntervalSince1970)
        let dateProvider = MockDateProvider()
        dateProvider.currentDate = date
        let expectation1 = expectation(description: #function)
        let networkSession = MockNetworkSession()
        networkSession.requestCallback = { request in
            if request.bodyDict.contains(where: { $0.key == "createdAt" && ($0.value as! Int) == createdAtTime }) {
                expectation1.fulfill()
            }
        }
        let notificationCenter = MockNotificationCenter()
        
        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: dateProvider,
                                          networkSession: networkSession)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                           persistenceContextProvider: persistenceContextProvider,
                           healthMonitor: healthMonitor,
                           notificationCenter: notificationCenter,
                           timeInterval: 0.5)
        taskRunner.start()

        let scheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                              notificationCenter: notificationCenter,
                                              healthMonitor: healthMonitor)
        let _ = try! self.scheduleSampleTask(scheduler: scheduler)
        verifyTaskIsExecuted(notificationCenter, withinInterval: 1.0)

        taskRunner.stop()
        wait(for: [expectation1], timeout: 5.0)
    }
    
    private func waitForZeroTasks() {
        let predicate = NSPredicate { (_, _) -> Bool in
            try! self.persistenceContextProvider.mainQueueContext().findAllTasks().count == 0
        }
        
        let expectation1 = expectation(for: predicate, evaluatedWith: nil, handler: nil)
        wait(for: [expectation1], timeout: 5.0)
    }

    private func scheduleSampleTasks(scheduler: IterableTaskScheduler,
                                     times: Int,
                                     scheduledTaskIds: [String]) throws -> Pending<[String], IterableTaskError> {
        guard times > 0 else {
            return Fulfill<[String], IterableTaskError>(value: scheduledTaskIds)
        }
        return try scheduleSampleTask(scheduler: scheduler).flatMap { [self] taskId -> Pending<[String], IterableTaskError> in
            var newTaskIds = scheduledTaskIds
            newTaskIds.append(taskId)
            return try! self.scheduleSampleTasks(scheduler: scheduler, times: times-1, scheduledTaskIds: newTaskIds)
        }
    }
    
    private func scheduleSampleTask(scheduler: IterableTaskScheduler) throws -> Pending<String, IterableTaskError> {
        let apiKey = "zee-api-key"
        let eventName = "CustomEvent1"
        let dataFields = ["var1": "val1", "var2": "val2"]

        let requestCreator = RequestCreator(auth: auth, deviceMetadata: deviceMetadata)
        guard case let Result.success(trackEventRequest) = requestCreator.createTrackEventRequest(eventName, dataFields: dataFields) else {
            throw IterableError.general(description: "Could not create trackEvent request")
        }

        let apiCallRequest = IterableAPICallRequest(apiKey: apiKey,
                                                    endpoint: Endpoint.api,
                                                    authToken: auth.authToken,
                                                    deviceMetadata: deviceMetadata,
                                                    iterableRequest: trackEventRequest)
        return scheduler.schedule(apiCallRequest: apiCallRequest)
    }

    /// Schedules a task with an unauthenticated API path (disableDevice) for bypass testing.
    private func scheduleUnauthenticatedTask(scheduler: IterableTaskScheduler) throws -> Pending<String, IterableTaskError> {
        let apiKey = "zee-api-key"
        let iterableRequest = IterableRequest.post(PostRequest(path: Const.Path.disableDevice,
                                                               args: nil,
                                                               body: ["token": "test-token"]))
        let apiCallRequest = IterableAPICallRequest(apiKey: apiKey,
                                                    endpoint: Endpoint.api,
                                                    authToken: nil,
                                                    deviceMetadata: deviceMetadata,
                                                    iterableRequest: iterableRequest)
        return scheduler.schedule(apiCallRequest: apiCallRequest)
    }

    private func verifyNoTaskIsExecuted(_ notificationCenter: MockNotificationCenter, forInterval interval: TimeInterval) {
        let expectation1 = expectation(description: "Wait for task complete notification.")
        expectation1.isInverted = true
        
        let reference1 = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithRetry) { _ in
            XCTFail()
        }
        let reference2 = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithNoRetry) { _ in
            XCTFail()
        }
        let reference3 = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            XCTFail()
        }
        wait(for: [expectation1], timeout: interval)
        notificationCenter.removeCallbacks(withIds: reference1.callbackId, reference2.callbackId, reference3.callbackId)
    }

    private func verifyTaskIsExecuted(_ notificationCenter: MockNotificationCenter, withinInterval interval: TimeInterval) {
        let expectation1 = expectation(description: "Wait for task complete notification.")
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { _ in
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: interval)
        notificationCenter.removeCallbacks(withIds: reference.callbackId)
    }

    private let deviceMetadata = DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                platform: JsonValue.iOS,
                                                appPackageName: Bundle.main.appPackageName ?? "")
    
    private lazy var persistenceContextProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider()!
        return provider
    }()
}

extension TaskRunnerTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: nil, userIdUnknownUser: nil)
    }
}
