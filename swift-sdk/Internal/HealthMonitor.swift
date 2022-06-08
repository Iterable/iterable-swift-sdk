//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

protocol HealthMonitorDataProviderProtocol {
    var maxTasks: Int { get }
    func countTasks() throws -> Pending<Int, IterableTaskError>
}

struct HealthMonitorDataProvider: HealthMonitorDataProviderProtocol {
    init(maxTasks: Int,
         persistenceContextProvider: IterablePersistenceContextProvider) {
        self.maxTasks = maxTasks
        self.persistenceContextProvider = persistenceContextProvider
    }
    
    let maxTasks: Int

    func countTasks() throws -> Pending<Int, IterableTaskError> {
        let result = Fulfill<Int, IterableTaskError>()
        let context = persistenceContextProvider.newBackgroundContext()
        context.perform {
            do {
                let count = try context.countTasks()
                result.resolve(with: count)
            } catch let error {
                result.reject(with: IterableTaskError.general(error.localizedDescription))
            }
        }
        return result
    }
    
    private let persistenceContextProvider: IterablePersistenceContextProvider
}

protocol HealthMonitorDelegate: AnyObject {
    func onDBError()
}

class HealthMonitor {
    init(dataProvider: HealthMonitorDataProviderProtocol,
         dateProvider: DateProviderProtocol,
         networkSession: NetworkSessionProtocol) {
        ITBInfo()
        self.dataProvider = dataProvider
        self.dateProvider = dateProvider
        self.networkSession = networkSession
    }
    
    deinit {
        ITBInfo()
    }
    
    weak var delegate: HealthMonitorDelegate?
    
    func canSchedule() -> Pending<Bool, Never> {
        ITBInfo()
        // do not schedule further on error
        guard errored == false else {
            return Fulfill<Bool, Never>(value: false)
        }

        let fulfill = Fulfill<Bool, Never>()
        do {
            try dataProvider.countTasks().onCompletion { count in
                if count < self.dataProvider.maxTasks {
                    fulfill.resolve(with: true)
                } else {
                    fulfill.resolve(with: false)
                }
            } receiveError: { error in
                ITBError("DBError: " + error.localizedDescription)
                self.onError()
                fulfill.resolve(with: false)
            }
        } catch let error {
            ITBError("DBError: " + error.localizedDescription)
            onError()
            fulfill.resolve(with: false)
        }

        return fulfill
    }

    func canProcess() -> Bool {
        ITBInfo()
        return !errored
    }
    
    func onScheduleError(apiCallRequest: IterableAPICallRequest) {
        ITBInfo()
        let currentDate = dateProvider.currentDate
        let apiCallRequest = apiCallRequest.addingCreatedAt(currentDate)
        if let urlRequest = apiCallRequest.convertToURLRequest(sentAt: currentDate) {
            _ = RequestSender.sendRequest(urlRequest, usingSession: networkSession)
        }
        onError()
    }
    
    func onDeleteError(task: IterableTask) {
        ITBInfo()
        onError()
    }
    
    func onNextTaskError() {
        ITBInfo()
        onError()
    }
    
    func onDeleteAllTasksError() {
        ITBInfo()
        onError()
    }
    
    private func onError() {
        errored = true
        delegate?.onDBError()
    }
    
    private var errored = false
    private let dataProvider: HealthMonitorDataProviderProtocol
    private let dateProvider: DateProviderProtocol
    private let networkSession: NetworkSessionProtocol
}
