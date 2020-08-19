//
//  Created by Tapash Majumder on 7/22/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class TasksCRUDTests: XCTestCase {
    func testCreate() throws {
        let context = persistenceProvider.newBackgroundContext()
        let taskId = IterableUtil.generateUUID()
        let task = try context.createTask(id: taskId, type: .apiCall)
        try context.save()
        XCTAssertEqual(task.id, taskId)
        XCTAssertEqual(task.type, .apiCall)
        
        let newContext = persistenceProvider.mainQueueContext()
        let found = try newContext.findTask(withId: taskId)!
        XCTAssertEqual(found.id, taskId)
        XCTAssertEqual(found.type, .apiCall)
    }
    
    func testUpdate() throws {
        let context = persistenceProvider.newBackgroundContext()
        let taskId = IterableUtil.generateUUID()
        let task = try context.createTask(id: taskId, type: .apiCall)
        try context.save()
        
        let attempts = 2
        let lastAttemptedAt = Date()
        let processing = true
        let scheduledAt = Date()
        let data = Data(repeating: 1, count: 20)
        let failed = true
        let taskFailureData = Data(repeating: 2, count: 11)
        let updatedTask = task.updated(attempts: attempts,
                                       lastAttemptedAt: lastAttemptedAt,
                                       processing: processing,
                                       scheduledAt: scheduledAt,
                                       data: data,
                                       failed: failed,
                                       taskFailureData: taskFailureData)
        
        try context.update(task: updatedTask)
        try context.save()
        
        let newContext = persistenceProvider.mainQueueContext()
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
    
    func testDelete() throws {
        let context = persistenceProvider.newBackgroundContext()
        let taskId = IterableUtil.generateUUID()
        try context.createTask(id: taskId, type: .apiCall)
        try context.save()
        
        let newContext = persistenceProvider.mainQueueContext()
        let found = try newContext.findTask(withId: taskId)!
        XCTAssertEqual(found.id, taskId)
        XCTAssertEqual(found.type, .apiCall)
        
        try context.delete(task: found)
        try context.save()
        
        XCTAssertNil(try newContext.findTask(withId: taskId))
    }
    
    func testFindAll() throws {
        let context = persistenceProvider.newBackgroundContext()
        try context.deleteAllTasks()
        try context.save()
        
        let tasks = try context.findAllTasks()
        XCTAssertEqual(tasks.count, 0)
        
        try context.createTask(id: IterableUtil.generateUUID(), type: .apiCall)
        try context.createTask(id: IterableUtil.generateUUID(), type: .apiCall)
        try context.save()
        
        let newTasks = try context.findAllTasks()
        XCTAssertEqual(newTasks.count, 2)
        
        try context.deleteAllTasks()
        try context.save()
    }
    
    private lazy var persistenceProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider()
        try! provider.mainQueueContext().deleteAllTasks()
        try! provider.mainQueueContext().save()
        return provider
    }()
}
