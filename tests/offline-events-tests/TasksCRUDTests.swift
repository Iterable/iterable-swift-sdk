//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class TasksCRUDTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testCreate() throws {
        let context = persistenceProvider.newBackgroundContext()
        let taskId = IterableUtil.generateUUID()
        let taskName = "zee task name"
        var task: IterableTask!
        try context.performAndWait {
            task = try createTask(context: context, id: taskId, name: taskName, type: .apiCall)
            try context.save()
        }
        XCTAssertEqual(task.id, taskId)
        XCTAssertEqual(task.type, .apiCall)
        XCTAssertEqual(task.name, taskName)
        
        let newContext = persistenceProvider.mainQueueContext()
        try newContext.performAndWait {
            let found = try newContext.findTask(withId: taskId)!
            XCTAssertEqual(found.id, taskId)
            XCTAssertEqual(found.type, .apiCall)
        }
    }
    
    func testUpdate() throws {
        let context = persistenceProvider.newBackgroundContext()
        var taskId: String!
        var task: IterableTask!
        let attempts = 2
        let lastAttemptedAt = Date()
        let processing = true
        let scheduledAt = Date()
        let data = Data(repeating: 1, count: 20)
        let failed = true
        let taskFailureData = Data(repeating: 2, count: 11)
        try context.performAndWait {
            taskId = IterableUtil.generateUUID()
            task = try createTask(context: context, id: taskId, type: .apiCall)
            try context.save()
        }

        try context.performAndWait {
            let updatedTask = task.updated(attempts: attempts,
                                           lastAttemptedAt: lastAttemptedAt,
                                           processing: processing,
                                           scheduledAt: scheduledAt,
                                           data: data,
                                           failed: failed,
                                           taskFailureData: taskFailureData)
            
            try context.update(task: updatedTask)
            try context.save()
        }

        let newContext = persistenceProvider.mainQueueContext()
        try newContext.performAndWait {
            let found = try newContext.findTask(withId: taskId)!
            XCTAssertEqual(found.id, taskId)
            XCTAssertEqual(found.version, task.version)
            XCTAssertEqual(found.type, .apiCall)
            XCTAssertNotNil(found.createdAt)
            XCTAssertNotNil(found.modifiedAt)
            XCTAssertEqual(found.attempts, attempts)
            XCTAssertEqual(found.lastAttemptedAt, lastAttemptedAt)
            XCTAssertEqual(found.processing, processing)
            XCTAssertEqual(found.scheduledAt, scheduledAt)
            XCTAssertEqual(found.data, data)
            XCTAssertEqual(found.failed, failed)
            XCTAssertEqual(found.blocking, task.blocking)
            XCTAssertEqual(found.requestedAt, task.requestedAt)
            XCTAssertEqual(found.taskFailureData, taskFailureData)
        }
    }
    
    func testDelete() throws {
        let context = persistenceProvider.newBackgroundContext()
        let taskId = IterableUtil.generateUUID()
        try context.performAndWait {
            try createTask(context: context, id: taskId, type: .apiCall)
            try context.save()
        }
        
        let newContext = persistenceProvider.mainQueueContext()
        var found: IterableTask!
        try newContext.performAndWait {
            found = try newContext.findTask(withId: taskId)!
            XCTAssertEqual(found.id, taskId)
            XCTAssertEqual(found.type, .apiCall)
        }
        
        try context.performAndWait {
            try context.delete(task: found)
            try context.save()
        }

        try newContext.performAndWait {
            XCTAssertNil(try newContext.findTask(withId: taskId))
        }
    }
    
    func testFindNextTask() throws {
        let context = persistenceProvider.newBackgroundContext()
        try context.performAndWait {
            try context.deleteAllTasks()
            try context.save()
            
            let tasks = try context.findAllTasks()
            XCTAssertEqual(tasks.count, 0)

            let date1 = Date()
            let date2 = date1.advanced(by: 100)
            let date3 = date2.advanced(by: 100)

            var dates = [date1, date2, date3]
            dates.shuffle()
            
            for date in dates {
                dateProvider.currentDate = date
                let task = IterableTask(id: IterableUtil.generateUUID(),
                                        type: .apiCall,
                                        scheduledAt: date,
                                        requestedAt: date)
                try context.create(task: task)
            }

            try context.save()
            
            var scheduledAtValues = [Date]()
            while let nextTask = try context.nextTask() {
                scheduledAtValues.append(nextTask.scheduledAt)
                try context.delete(task: nextTask)
                try context.save()
            }
            
            XCTAssertEqual(scheduledAtValues.count, 3)
            XCTAssertTrue(scheduledAtValues.isAscending())
            let allTasks = try context.findAllTasks()
            XCTAssertEqual(allTasks.count, 0)
        }
    }
    
    func testFindAll() throws {
        let context = persistenceProvider.newBackgroundContext()
        try context.performAndWait {
            try context.deleteAllTasks()
            try context.save()
            
            let tasks = try context.findAllTasks()
            XCTAssertEqual(tasks.count, 0)
            
            try createTask(context: context, id: IterableUtil.generateUUID(), type: .apiCall)
            try createTask(context: context, id: IterableUtil.generateUUID(), type: .apiCall)
            try context.save()
            
            let newTasks = try context.findAllTasks()
            XCTAssertEqual(newTasks.count, 2)
            
            try context.deleteAllTasks()
            try context.save()
        }
    }
    
    func testCountTasks() throws {
        let context = persistenceProvider.newBackgroundContext()
        try context.performAndWait {
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
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider)
        try! provider.mainQueueContext().deleteAllTasks()
        try! provider.mainQueueContext().save()
        return provider
    }()
}
