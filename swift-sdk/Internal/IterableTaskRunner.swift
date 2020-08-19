//
//  Created by Tapash Majumder on 8/18/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
class IterableTaskRunner {
    // TODO: @tqm Move to `DependencyContainer` after we remove iOS 9 support
    init(networkSession: NetworkSessionProtocol = URLSession(configuration: .default),
         persistenceContextProvider: IterablePersistenceContextProvider = CoreDataPersistenceContextProvider()) {
        self.networkSession = networkSession
        self.persistenceContextProvider = persistenceContextProvider
    }
    
    func start() throws {
        ITBInfo()
        shouldExecute = true
        persistenceContext.perform {
            while self.shouldExecute {
                try? self.execute()
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
    }
    
    func stop() throws {
        ITBInfo()
        shouldExecute = false
    }
    
    func execute() throws {
        ITBInfo()
        let tasks = try persistenceContext.findAllTasks()
        ITBInfo("numTasks: \(tasks.count)")
        for task in tasks {
            try execute(task: task).wait()
        }
    }
    
    @discardableResult
    func execute(task: IterableTask) throws -> Future<Void, Never> {
        ITBInfo("executing taskId: \(task.id)")
        let result = Promise<Void, Never>()
        let processor = IterableAPICallTaskProcessor(networkSession: networkSession)
        try processor.process(task: task).onSuccess { taskResult in
            switch taskResult {
            case let .success(detail: detail):
                ITBInfo("task: \(task.id) succeeded")
                self.deleteTask(task: task)
                if let successDetail = detail as? SendRequestValue {
                    var userInfo = [AnyHashable: Any]()
                    userInfo["taskId"] = task.id
                    userInfo["sendRequestValue"] = successDetail
                    NotificationCenter.default.post(name: .iterableTaskFinishedWithSuccess, object: self, userInfo: userInfo)
                }
            case let .failureWithNoRetry(detail: detail):
                ITBInfo("task: \(task.id) failed with no retry.")
                self.deleteTask(task: task)
                if let failureDetail = detail as? SendRequestError {
                    var userInfo = [AnyHashable: Any]()
                    userInfo["taskId"] = task.id
                    userInfo["sendRequestError"] = failureDetail
                    NotificationCenter.default.post(name: .iterableTaskFinishedWithNoRetry, object: self, userInfo: userInfo)
                }
            case .failureWithRetry:
                ITBInfo("task: \(task.id) processed with retry")
                break
            }
            result.resolve(with: ())
        }
        return result
    }
    
    private func deleteTask(task: IterableTask) {
        do {
            try persistenceContext.delete(task: task)
            try persistenceContext.save()
        } catch let error {
            ITBError(error.localizedDescription)
        }
    }

    private var shouldExecute = true
    private let networkSession: NetworkSessionProtocol
    private let persistenceContextProvider: IterablePersistenceContextProvider
    private lazy var persistenceContext: IterablePersistenceContext = {
        return persistenceContextProvider.newBackgroundContext()
    }()
}
