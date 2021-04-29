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
        localStorage.offlineModeBeta = true
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage)

        internalAPI.track("myEvent")
        internalAPI.track("myEvent2")
        internalAPI.track("myEvent3")
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(processors, ["Offline", "Offline", "Offline"])
    }

    func testSwitchProcessorsWhenNumTasksExceedsMaxTasks() throws {
        let expectation1 = expectation(description: #function)
        expectation1.expectedFulfillmentCount = 3
        let networkSession = MockNetworkSession(statusCode: 200)
        var processorMap = [String: String]()
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.trackEvent) {
                let eventName = request.bodyDict["eventName"] as! String
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                processorMap[eventName] = processor!
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineModeBeta = true
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage,
                                                                   maxTasks: 1)

        internalAPI.track("myEvent")
        internalAPI.track("myEvent2").onSuccess { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                internalAPI.track("myEvent3")
            }
        }
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(processorMap["myEvent"], "Offline")
        XCTAssertEqual(processorMap["myEvent2"], "Online")
        XCTAssertEqual(processorMap["myEvent3"], "Offline")
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
        localStorage.offlineModeBeta = true
        var input = MockPersistenceContext.Input()
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
        localStorage.offlineModeBeta = true
        var input = MockPersistenceContext.Input()
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
        localStorage.offlineModeBeta = true
        var input = MockPersistenceContext.Input()
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
        localStorage.offlineModeBeta = true
        var input = MockPersistenceContext.Input()
        input.deleteAllTasksCallback = {
            throw IterableDBError.general("error deleting all tasks")
        }
        let context = MockPersistenceContext(input: input)
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage,
                                                                   persistenceContextProvider: MockPersistenceContextProvider(context: context))
        XCTAssertTrue(internalAPI.requestHandler.offlineMode)
        internalAPI.email = "user2@example.com"
        XCTAssertFalse(internalAPI.requestHandler.offlineMode)
    }

    private let dateProvider = MockDateProvider()
    
    private lazy var persistenceProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider,
                                                          fromBundle: Bundle(for: PersistentContainer.self))!
        try! provider.mainQueueContext().deleteAllTasks()
        try! provider.mainQueueContext().save()
        return provider
    }()
}

