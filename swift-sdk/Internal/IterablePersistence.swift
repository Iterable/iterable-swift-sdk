//
//  Copyright © 2020 Iterable. All rights reserved.
//

// This defines persistence contracts for Iterable
// This should not be dependent on CoreData

import Foundation

enum IterableDBError: Error {
    case general(String)
}

extension IterableDBError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .general(description):
            return description
        }
    }
}

protocol IterablePersistenceContext {
    @discardableResult
    func create(task: IterableTask) throws -> IterableTask
    
    @discardableResult
    func update(task: IterableTask) throws -> IterableTask
    
    func delete(task: IterableTask) throws
    
    func findTask(withId id: String) throws -> IterableTask?
    
    func deleteTask(withId id: String) throws
    
    func nextTask() throws -> IterableTask?
    
    func findAllTasks() throws -> [IterableTask]
    
    func deleteAllTasks() throws
    
    func countTasks() throws -> Int
    
    func save() throws

    func perform(_ block: @escaping () -> Void)

    func performAndWait(_ block: () -> Void)
    
    func performAndWait<T>(_ block: () throws -> T) throws -> T
}

protocol IterablePersistenceContextProvider {
    func newBackgroundContext() -> IterablePersistenceContext
    func mainQueueContext() -> IterablePersistenceContext
}
