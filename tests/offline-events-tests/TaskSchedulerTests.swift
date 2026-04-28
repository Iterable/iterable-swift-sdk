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
        let numTimes = 10
        expectation1.expectedFulfillmentCount = numTimes
        
        let notificationCenter = MockNotificationCenter()
        var taskIds: Set<String> = []
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskFinishedWithSuccess) { notification in
            if let taskId = IterableNotificationUtil.notificationToTaskSendRequestValue(notification)?.taskId {
                taskIds.insert(taskId)
            } else {
                XCTFail("Could not find taskId for notification")
            }

            expectation1.fulfill()
        }
        let networkSession = MockNetworkSession()
        networkSession.responseCallback = { url in
            if url.absoluteString.contains("track") {
                let response = MockNetworkSession.MockResponse(delay: 0.1, queue: DispatchQueue(label: UUID().uuidString))
                return response
            } else {
                return nil
            }
        }
        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: dateProvider,
                                          networkSession: networkSession)
        let scheduler = try createTaskScheduler(notificationCenter: notificationCenter, healthMonitor: healthMonitor)
        let taskRunner = try createTaskRunner(networkSession: networkSession, healthMonitor: healthMonitor, notificationCenter: notificationCenter)
        taskRunner.start()
        
        numTimes.times {
            DispatchQueue.global(qos: .background).async { [weak self] in
                do {
                    try self?.scheduleSampleTask(taskScheduler: scheduler)
                } catch let error {
                    ITBError(error.localizedDescription)
                    XCTFail()
                }
            }
        }
        
        wait(for: [expectation1], timeout: 10.0)
        taskRunner.stop()
        notificationCenter.removeCallbacks(withIds: reference.callbackId)
        XCTAssertEqual(numTimes, taskIds.count)
    }
    
    // Regression for SDK-297: logout purges the offline queue, but a queued
    // `disableDevice` task is the whole point of enabling offline retry for this
    // endpoint — it must survive the purge so it can replay after the current user
    // is cleared.
    func testDeleteAllTasksPreservingTasksWithNameKeepsMatchingTasks() throws {
        let preservedName = Const.Path.disableDevice
        let mainContext = persistenceContextProvider.mainQueueContext()
        try mainContext.create(task: IterableTask(id: "keep-1",
                                                  name: preservedName,
                                                  type: .apiCall,
                                                  scheduledAt: dateProvider.currentDate,
                                                  requestedAt: dateProvider.currentDate))
        try mainContext.create(task: IterableTask(id: "drop-1",
                                                  name: Const.Path.trackEvent,
                                                  type: .apiCall,
                                                  scheduledAt: dateProvider.currentDate,
                                                  requestedAt: dateProvider.currentDate))
        try mainContext.create(task: IterableTask(id: "drop-2",
                                                  name: Const.Path.updateCart,
                                                  type: .apiCall,
                                                  scheduledAt: dateProvider.currentDate,
                                                  requestedAt: dateProvider.currentDate))
        try mainContext.save()
        XCTAssertEqual(try mainContext.findAllTasks().count, 3, "sanity: seeded 3 tasks")

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: dateProvider,
                                          networkSession: MockNetworkSession())
        let scheduler = try createTaskScheduler(notificationCenter: MockNotificationCenter(),
                                                healthMonitor: healthMonitor)

        scheduler.deleteAllTasks(preservingTasksWithName: preservedName)

        // The scheduler dispatches deletion onto a background CoreData context via
        // `perform`. Poll the main context for the expected end-state instead of
        // sleeping a fixed interval — sturdier on slow CI runners and stops as soon
        // as the purge lands. `XCTNSPredicateExpectation` evaluates the predicate
        // on the main thread, so reading `mainContext` here is safe.
        let purgeSettled = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                ((try? mainContext.findAllTasks().count) ?? -1) == 1
            },
            object: nil
        )
        wait(for: [purgeSettled], timeout: 5.0)

        let remaining = try mainContext.findAllTasks()
        XCTAssertEqual(remaining.count, 1, "only the preserved task should remain")
        XCTAssertEqual(remaining.first?.id, "keep-1")
        XCTAssertEqual(remaining.first?.name, preservedName)
    }

    @discardableResult
    private func scheduleSampleTask(taskScheduler: IterableTaskScheduler) throws -> Pending<String, IterableTaskError> {
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
        
        return taskScheduler.schedule(apiCallRequest: apiCallRequest)
    }

    private func createTaskScheduler(notificationCenter: NotificationCenterProtocol,
                                     healthMonitor: HealthMonitor) throws -> IterableTaskScheduler {
        IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                              notificationCenter: notificationCenter,
                              healthMonitor: healthMonitor,
                              dateProvider: dateProvider)
    }
    
    private func createTaskRunner(networkSession: NetworkSessionProtocol,
                                  healthMonitor: HealthMonitor,
                                  notificationCenter: NotificationCenterProtocol) throws -> IterableTaskRunner {
        IterableTaskRunner(networkSession: networkSession,
                           persistenceContextProvider: persistenceContextProvider,
                           healthMonitor: healthMonitor,
                           notificationCenter: notificationCenter,
                           timeInterval: 0.5)
    }

    
    private let deviceMetadata = DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                platform: JsonValue.iOS,
                                                appPackageName: Bundle.main.appPackageName ?? "")

    private lazy var persistenceContextProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider)!
        return provider
    }()

    private let dateProvider = MockDateProvider()
}

extension TaskSchedulerTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: nil, userIdUnknownUser: nil)
    }
}
