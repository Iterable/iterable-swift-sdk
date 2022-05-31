//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockPersistenceContext: IterablePersistenceContext {
    class Input {
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
        var performAndWaitCallbackWithResult: (() -> Void)? = nil
    }
    
    init(input: Input = Input()) {
        self.input = input
    }
    
    func create(task: IterableTask) throws -> IterableTask {
        ITBInfo()
        tasks.append(task)
        try input.createCallback?()
        return task
    }
    
    func update(task: IterableTask) throws -> IterableTask {
        ITBInfo()
        if let index = tasks.firstIndex(where: { $0.id == task.id}) {
            tasks[index] = task
        }
        try input.updateCallback?()
        return task
    }
    
    func delete(task: IterableTask) throws {
        ITBInfo()
        if let index = tasks.firstIndex(where: { $0.id == task.id}) {
            tasks.remove(at: index)
        }
        try input.deleteCallback?()
    }
    
    func findTask(withId id: String) throws -> IterableTask? {
        ITBInfo()
        try input.findTaskCallback?()
        return tasks.first(where: {$0.id == id})
    }
    
    func deleteTask(withId id: String) throws {
        ITBInfo()
        if let index = tasks.firstIndex(where: { $0.id == id}) {
            tasks.remove(at: index)
        }
        try input.deleteTaskWithIdCallback?()
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
        tasks.removeAll()
        try input.deleteAllTasksCallback?()
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
        queue.async {[weak self] in
            block()
            self?.input.performCallback?()
        }
    }
    
    func performAndWait(_ block: () -> Void) {
        ITBInfo()
        input.performAndWaitCallback?()
        block()
    }
    
    func performAndWait<T>(_ block: () throws -> T) throws -> T {
        ITBInfo()
        input.performAndWaitCallbackWithResult?()
        return try block()
    }
    
    private let queue = DispatchQueue(label: "mockPersistence")
    
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
