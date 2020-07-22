//
//  Created by Tapash Majumder on 7/22/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class TasksCRUDTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreate() throws {
        let context = persistenceProvider.newBackgroundContext()
        let taskId = IterableUtil.generateUUID()
        let taskProcessor = "Processor1"
        let task = try context.createTask(id: taskId, processor: taskProcessor)
        try context.save()
        XCTAssertEqual(task.id, taskId)
        XCTAssertEqual(task.processor, taskProcessor)
        
        let newContext = persistenceProvider.mainQueueContext()
        let found = try newContext.findTask(withId: taskId)!
        XCTAssertEqual(found.id, taskId)
        XCTAssertEqual(found.processor, taskProcessor)
    }
    
    func testUpdate() throws {
        let context = persistenceProvider.newBackgroundContext()
        let taskId = IterableUtil.generateUUID()
        let taskProcessor = "Processor1"
        let task = try context.createTask(id: taskId, processor: taskProcessor)
        try context.save()
        
        let attempts = 2
        let lastAttempt = Date()
        let processing = true
        let scheduleTime = Date()
        let data = Data(repeating: 1, count: 20)
        let updatedTask = task.updated(attempts: attempts, lastAttempt: lastAttempt, processing: processing, scheduleTime: scheduleTime, data: data)

        try context.update(task: updatedTask)
        try context.save()
        
        let newContext = persistenceProvider.mainQueueContext()
        let found = try newContext.findTask(withId: taskId)!
        XCTAssertEqual(found.id, taskId)
        XCTAssertEqual(found.processor, taskProcessor)
        XCTAssertNotNil(found.created)
        XCTAssertNotNil(found.modified)
        XCTAssertEqual(found.attempts, attempts)
        XCTAssertEqual(found.lastAttempt, lastAttempt)
        XCTAssertEqual(found.scheduleTime, scheduleTime)
        XCTAssertEqual(found.data, data)
    }
    
    private lazy var persistenceProvider = {
        CoreDataPersistenceContextProvider()
    }()
}
