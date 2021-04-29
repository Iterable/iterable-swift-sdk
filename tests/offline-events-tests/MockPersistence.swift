//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockPersistenceContext: IterablePersistenceContext {
    struct Input {
        var createCallback: (() throws -> Void)? = nil
        var updateCallback: (() throws -> Void)? = nil
        var deleteCallback: (() throws -> Void)? = nil
        var findTaskCallback: (() throws -> Void)? = nil
        var deleteTaskWithIdCallback: (() throws -> Void)? = nil
        var nextTaskCallback: (() throws -> Void)? = nil
        var findAllTasksCallback: (() throws -> Void)? = nil
        var deleteAllTasksCallback: (() throws -> Void)? = nil
        var countTasksCallback: (() throws -> Void)? = nil
        var saveCallback: (() throws -> Void)? = nil
        var performCallback: (() -> Void)? = nil
        var performAndWaitCallback: (() -> Void)? = nil
    }
    
    init(input: Input = Input()) {
        self.input = input
    }
    
    func create(task: IterableTask) throws -> IterableTask {
        ITBInfo()
        try input.createCallback?()
        tasks.append(task)
        return task
    }
    
    func update(task: IterableTask) throws -> IterableTask {
        ITBInfo()
        try input.updateCallback?()
        if let index = tasks.firstIndex(where: { $0.id == task.id}) {
            tasks[index] = task
        }
        return task
    }
    
    func delete(task: IterableTask) throws {
        ITBInfo()
        try input.deleteCallback?()
        if let index = tasks.firstIndex(where: { $0.id == task.id}) {
            tasks.remove(at: index)
        }
    }
    
    func findTask(withId id: String) throws -> IterableTask? {
        ITBInfo()
        try input.findTaskCallback?()
        return tasks.first(where: {$0.id == id})
    }
    
    func deleteTask(withId id: String) throws {
        ITBInfo()
        try input.deleteTaskWithIdCallback?()
        if let index = tasks.firstIndex(where: { $0.id == id}) {
            tasks.remove(at: index)
        }
    }
    
    func nextTask() throws -> IterableTask? {
        ITBInfo()
        try input.nextTaskCallback?()
        return tasks.first
    }
    
    func findAllTasks() throws -> [IterableTask] {
        ITBInfo()
        try input.findAllTasksCallback?()
        return tasks
    }
    
    func deleteAllTasks() throws {
        ITBInfo()
        try input.deleteAllTasksCallback?()
        tasks.removeAll()
    }
    
    func countTasks() throws -> Int {
        ITBInfo()
        try input.countTasksCallback?()
        return tasks.count
    }
    
    func save() throws {
        ITBInfo()
        try input.saveCallback?()
    }
    
    func perform(_ block: @escaping () -> Void) {
        ITBInfo()
        input.performCallback?()
        block()
    }
    
    func performAndWait(_ block: () -> Void) {
        ITBInfo()
        input.performAndWaitCallback?()
        block()
    }
    
    private let input: Input
    private var tasks = [IterableTask]()
}

struct MockPersistenceContextProvider: IterablePersistenceContextProvider {
    
    init(context: IterablePersistenceContext = MockPersistenceContext()) {
        self.context = context
    }
    
    func newBackgroundContext() -> IterablePersistenceContext {
        context
    }
    
    func mainQueueContext() -> IterablePersistenceContext {
        context
    }
    
    private let context: IterablePersistenceContext
}
