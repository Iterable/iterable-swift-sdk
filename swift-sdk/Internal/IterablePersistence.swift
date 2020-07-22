//
//  Created by Tapash Majumder on 7/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//
// This defines persistence contracts for Iterable.
// This should not be dependent on Coredata

import Foundation

enum IterableDBError: Error {
    case general(String)
}

extension IterableDBError: LocalizedError {
    var localizedDescription: String {
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

    @discardableResult
    func createTask(id: String, processor: String) throws -> IterableTask

    func findTask(withId id: String) throws -> IterableTask?

    func deleteTask(withId id: String) throws
    
    func findAllTasks() throws -> [IterableTask]
    
    func deleteAllTasks() throws

    func save() throws
}

protocol IterablePersistenceContextProvider {
    func newBackgroundContext() -> IterablePersistenceContext
    func mainQueueContext() -> IterablePersistenceContext
}
