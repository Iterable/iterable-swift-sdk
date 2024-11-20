//
//  Copyright © 2021 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class HealthMonitorTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
        try! persistenceProvider.mainQueueContext().deleteAllTasks()
        try! persistenceProvider.mainQueueContext().save()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testUseOfflineProcessorByDefault() throws {
        let expectation1 = expectation(description: #function)
        expectation1.expectedFulfillmentCount = 3
        let networkSession = MockNetworkSession(statusCode: 200)
        var processors = [String]()
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.trackEvent) {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                processors.append(processor!)
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineMode = true
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage)

        internalAPI.track("myEvent")
        internalAPI.track("myEvent2")
        internalAPI.track("myEvent3")
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(processors, ["Offline", "Offline", "Offline"])
    }

    // TODO:
    // Taskscheduler is now asynchronous. The following test will not work.
    func todo_testSwitchProcessorsWhenNumTasksExceedsMaxTasks() throws {
        let expectation1 = expectation(description: #function)
        let networkSession = MockNetworkSession(statusCode: 200)
        networkSession.queue = DispatchQueue.global(qos: .userInitiated)
        var processorMap = [String: String]()
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.trackEvent) {
                let eventName = request.bodyDict["eventName"] as! String
                let processor = (request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!)!
                processorMap[eventName] = processor
                
                if eventName == "myEvent", processor == "Offline" {
                    expectation1.fulfill()
                }
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineMode = true
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage,
                                                                   maxTasks: 1)

        internalAPI.track("myEvent")
        
        wait(for: [expectation1], timeout: testExpectationTimeout)

        // We have to try many tasks simultaneously so that we have more than 1 task in the DB
        let changedToOnline = TestUtils.tryUntil(attempts: 10) {
            internalAPI.track("myEvent2")
            internalAPI.track("myEvent2")
            internalAPI.track("myEvent2")
            internalAPI.track("myEvent2")
            internalAPI.track("myEvent2")
            internalAPI.track("myEvent2")
            internalAPI.track("myEvent2")
            internalAPI.track("myEvent2")
            internalAPI.track("myEvent2")
            internalAPI.track("myEvent2")
        } test: {
            if let value = processorMap["myEvent2"], value == "Online" {
                return true
            } else {
                return false
            }
        }
        XCTAssertTrue(changedToOnline)

        let changedBackToOffline = TestUtils.tryUntil(attempts: 10) {
            internalAPI.track("myEvent3")
        } test: {
            if let value = processorMap["myEvent3"], value == "Offline" {
                return true
            } else {
                return false
            }
        }
        XCTAssertTrue(changedBackToOffline)
    }

    func testCountTasksException() throws {
        let expectation1 = expectation(description: #function)
        expectation1.expectedFulfillmentCount = 3
        let networkSession = MockNetworkSession(statusCode: 200)
        var processors = [String]()
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.trackEvent) {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                processors.append(processor!)
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineMode = true
        let input = MockPersistenceContext.Input()
        input.countTasksCallback = {
            throw IterableDBError.general("Scheduler exception")
        }
        let context = MockPersistenceContext(input: input)
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage,
                                                                   persistenceContextProvider: MockPersistenceContextProvider(context: context))

        internalAPI.track("myEvent")
        internalAPI.track("myEvent2")
        internalAPI.track("myEvent3")
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(processors, ["Online", "Online", "Online"])
        XCTAssertFalse(internalAPI.requestHandler.offlineMode)
    }

    func testScheduleTaskException() throws {
        let expectation1 = expectation(description: #function)
        expectation1.expectedFulfillmentCount = 3
        let networkSession = MockNetworkSession(statusCode: 200)
        var processors = [String]()
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.trackEvent) {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                processors.append(processor!)
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineMode = true
        let input = MockPersistenceContext.Input()
        input.createCallback = {
            throw IterableDBError.general("error creating task")
        }
        let context = MockPersistenceContext(input: input)
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage,
                                                                   persistenceContextProvider: MockPersistenceContextProvider(context: context))

        XCTAssertTrue(internalAPI.requestHandler.offlineMode)
        internalAPI.track("myEvent")
        internalAPI.track("myEvent2")
        internalAPI.track("myEvent3")
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(processors, ["Online", "Online", "Online"])
        XCTAssertFalse(internalAPI.requestHandler.offlineMode)
    }

    func testNextTaskException() throws {
        let expectation1 = expectation(description: #function)
        expectation1.expectedFulfillmentCount = 3
        let networkSession = MockNetworkSession(statusCode: 200)
        var processors = [String]()
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.trackEvent) {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                processors.append(processor!)
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineMode = true
        let input = MockPersistenceContext.Input()
        input.nextTaskCallback = {
            throw IterableDBError.general("error getting next task")
        }
        let context = MockPersistenceContext(input: input)
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage,
                                                                   persistenceContextProvider: MockPersistenceContextProvider(context: context))
        internalAPI.track("myEvent")
        internalAPI.track("myEvent2")
        internalAPI.track("myEvent3")
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertFalse(internalAPI.requestHandler.offlineMode)
    }

    func testDeleteAllTasksException() throws {
        let networkSession = MockNetworkSession(statusCode: 200)
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineMode = true
        let input = MockPersistenceContext.Input()
        input.deleteAllTasksCallback = {
            throw IterableDBError.general("error deleting all tasks")
        }
        let context = MockPersistenceContext(input: input)
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage,
                                                                   persistenceContextProvider: MockPersistenceContextProvider(context: context))
        XCTAssertTrue(internalAPI.requestHandler.offlineMode)
        internalAPI.email = "user2@example.com"
        let result = TestUtils.tryUntil(attempts: 10) {
            internalAPI.requestHandler.offlineMode == false
        }
        XCTAssertTrue(result)
    }

    private let dateProvider = MockDateProvider()
    
    private lazy var persistenceProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider)
        try! provider.mainQueueContext().deleteAllTasks()
        try! provider.mainQueueContext().save()
        return provider
    }()
}

