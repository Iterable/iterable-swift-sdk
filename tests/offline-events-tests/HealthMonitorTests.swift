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
        let networkSession = MockNetworkSession(statusCode: 200, delay: 1.0)
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
        let networkSession = MockNetworkSession(statusCode: 200, delay: 1.0)
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
                                                                   localStorage: localStorage,
                                                                   maxTasks: 1)

        internalAPI.track("myEvent")
        internalAPI.track("myEvent2")
        internalAPI.track("myEvent3")
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(processors, ["Offline", "Online", "Offline"])
    }

    func testDBError() throws {
        let expectation1 = expectation(description: #function)
        expectation1.expectedFulfillmentCount = 2
        let networkSession = MockNetworkSession(statusCode: 200, delay: 1.0)
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
        var count = 0
        input.createCallback = {
            count += 1
            if count == 2 {
                throw IterableDBError.general("Create Error")
            }
        }
        let context = MockPersistenceContext(input: input)
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession,
                                                                   localStorage: localStorage,
                                                                   maxTasks: 1,
                                                                   persistenceContextProvider: MockPersistenceContextProvider(context: context))

        internalAPI.track("myEvent")
        internalAPI.track("myEvent2")
        internalAPI.track("myEvent3")
        wait(for: [expectation1], timeout: testExpectationTimeout)
        XCTAssertEqual(processors, ["Offline", "Offline"])
    }
    
    @discardableResult
    private func createTask(context: IterablePersistenceContext,
                            id: String,
                            name: String? = nil,
                            type: IterableTaskType = .apiCall) throws -> IterableTask {
        let template = IterableTask(id: id,
                                    name: name,
                                    type: type,
                                    scheduledAt: dateProvider.currentDate,
                                    requestedAt: dateProvider.currentDate)
        return try context.create(task: template)
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

