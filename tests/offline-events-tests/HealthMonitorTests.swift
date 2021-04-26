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

    func testCountTasks() throws {
        let context = persistenceProvider.newBackgroundContext()
        try context.deleteAllTasks()
        try context.save()
        
        let tasks = try context.findAllTasks()
        XCTAssertEqual(tasks.count, 0)
        
        try createTask(context: context, id: IterableUtil.generateUUID(), type: .apiCall)
        try createTask(context: context, id: IterableUtil.generateUUID(), type: .apiCall)
        try context.save()
        
        let count = try context.countTasks()
        XCTAssertEqual(count, 2)
        
        try context.deleteAllTasks()
        try context.save()
    }
    
    func testDoNotExceedNumTasks() throws {
        let expectation1 = expectation(description: #function)
        expectation1.expectedFulfillmentCount = 3
        let networkSession = MockNetworkSession(statusCode: 200, delay: 2.0)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.trackEvent) {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
//                XCTAssertEqual(processor, Const.ProcessorTypeName.online)
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
